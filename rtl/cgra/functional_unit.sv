// Copyright 2026 CEIMM-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

// Unified Functional Unit
//
// Operation encoding (alu_sel_i):
//   0 = ADD  (requires HAS_ADDSUB)
//   1 = SUB  (requires HAS_ADDSUB)
//   2 = MUL  (requires HAS_MUL)
//   3 = SHIFT, logical    (requires HAS_SHIFT)
//   4 = SHIFT, arithmetic (requires HAS_SHIFT)
//   5 = AND  (requires HAS_LOGICAL)
//   6 = OR   (requires HAS_LOGICAL)
//   7 = XOR  (requires HAS_LOGICAL)
//
// A shift's direction is the sign of its amount operand, not the opcode: the
// amount reaches ash.sv as a signed value and a negative one shifts right. So
// 3 vs 4 selects zero- over sign-fill on a right shift, and both shift left
// for a non-negative amount.
//
// out_sel_i encoding:
//   0 = ALU output
//   1 = Comparator output (requires HAS_CMP)
//   2 = MUX output        (requires HAS_MUX)
//
// PE type equivalences:
//   L         : HAS_LOGICAL=1
//   A         : HAS_ADDSUB=1
//   M         : HAS_MUL=1
//   AML       : HAS_ADDSUB=1, HAS_MUL=1, HAS_LOGICAL=1
//   AMLCBMI   : HAS_ADDSUB=1, HAS_MUL=1, HAS_LOGICAL=1, HAS_CMP=1, HAS_MUX=1

module functional_unit #(
  parameter int DATA_WIDTH     = 32,
  parameter int N_DESTINATIONS = 6,
  // Operation enables (at least one must be set)
  parameter bit HAS_ADDSUB     = 1,   // Add / Subtract       (alu_sel 0, 1)
  parameter bit HAS_MUL        = 0,   // Multiply             (alu_sel 2)
  parameter bit HAS_SHIFT      = 0,   // Shift log. / arith.  (alu_sel 3, 4)
  parameter bit HAS_LOGICAL    = 0,   // AND / OR / XOR       (alu_sel 5, 6, 7)
  // Feature enables
  parameter bit HAS_CMP        = 0,   // Comparator output    (out_sel 1)
  parameter bit HAS_MUX        = 0,   // MUX / Branch via cin (out_sel 2)
  // Output fork protocol: 0 = lazy (fork_sender: the token is offered only when
  // every enabled destination is ready, out_*_v_o carry the full handshake and
  // fork_v_o is all-ones), 1 = eager (eager_fork_cfg: each destination is served
  // as soon as it is ready; out_*_v_o become raw flavor valids and fork_v_o[i]
  // gates destination i)
  parameter bit EAGER_FORK     = 0
) (
  // Clock and reset
  input logic clk_i,
  input logic rst_ni,
  input logic clr_i,

  // Configuration
  input logic [    DATA_WIDTH-1:0] initial_data_i,
  input logic                      initial_valid_i,
  input logic                      feedback_i,
  input logic [               2:0] alu_sel_i,
  input logic                      cmp_sel_i,        // HAS_CMP
  input logic [               1:0] out_sel_i,
  input logic [              15:0] delay_value_i,
  input logic [N_DESTINATIONS-1:0] fork_mask_i,

  // Data ports
  input  logic [DATA_WIDTH-1:0] din_1_i,
  input  logic [DATA_WIDTH-1:0] din_2_i,
  input  logic                  cin_i,    // HAS_MUX
  output logic [DATA_WIDTH-1:0] dout_o,

  // Valid/Ready ports
  input  logic in_v_i,
  output logic in_r_o,

  output logic out_v_o,
  output logic out_d_v_o,
  output logic out_b1_v_o,  // HAS_MUX
  output logic out_b2_v_o,  // HAS_MUX

  // Per-destination token grant. Lazy: all-ones (out_*_v_o already carry the
  // complete handshake). Eager: bit i stays high while destination i has not
  // yet consumed the current output token; AND it with the flavor valid.
  output logic [N_DESTINATIONS-1:0] fork_v_o,

  input logic [N_DESTINATIONS-1:0] out_r_i
);
  // synopsys sync_set_reset clr_i

  // ---------------------------------------------- //
  //                 INTERNAL SIGNALS               //
  // ---------------------------------------------- //

  logic [DATA_WIDTH-1:0] din_2;  // din_2 after feedback mux
  logic [DATA_WIDTH-1:0] addsub_dout;  // Add/sub result
  logic [DATA_WIDTH-1:0] mul_dout;  // Multiply result
  logic [DATA_WIDTH-1:0] shift_dout;  // Shift result
  logic [DATA_WIDTH-1:0] logical_dout;  // Logical result
  logic [DATA_WIDTH-1:0] alu_dout;  // Selected arithmetic result
  logic [DATA_WIDTH-1:0] cmp_dout;  // Comparator result
  logic [DATA_WIDTH-1:0] mux_dout;  // MUX result
  logic [DATA_WIDTH-1:0] pre_dout;  // Result before output register

  logic                  fork_r;  // Raw ready from the output fork
  logic                  in_r;  // Ready towards the joiner
  logic                  fire;  // Output token completes this cycle
  logic                  fire_d;  // Completion of the delayed (decimated) token
  logic                  initial_load;
  logic                  v_reg;
  logic                  b1_v;
  logic                  b1_v_reg;
  logic                  b2_v;
  logic                  b2_v_reg;
  logic [          15:0] delay_count;
  // Registered terminal-count flag: mirrors (delay_count + 1 == delay_value_i)
  // for the current delay_count, updated in lockstep with the counter. Keeps the
  // 16-bit compare out of the fire_d -> din_2 -> ALU -> dout_o data path so the
  // accumulator loop is not gated by an incrementer+comparator at high frequency.
  logic                  at_last;

  // ---------------------------------------------- //
  //               FEEDBACK MUX (din_2)             //
  // ---------------------------------------------- //

  // Mid-group the accumulator loops its own output. On the group-boundary cycle
  // (out_d_v_o: the final sum is transferred downstream this cycle) and while a
  // reload is pending (!initial_load) the operand is re-seeded from
  // initial_data_i, so the next group's first token can be consumed in the same
  // cycle the sum leaves - the group rolls over without a ready bubble.
  assign din_2 = feedback_i ? ((initial_load && !fire_d) ? dout_o : initial_data_i) : din_2_i;

  // ---------------------------------------------- //
  //            OPERAND-ISOLATION ENABLES           //
  // ---------------------------------------------- //
  // Only the sub-unit selected by alu_sel_i / out_sel_i sees live operands; every
  // other unit's operands are masked to 0 so its datapath stops toggling (power).
  // The ALU result feeds both the ALU output (out_sel 0) and the comparator
  // (out_sel 1, which compares alu_dout), so the arithmetic units stay enabled for
  // both. These enables drive the per-unit operand masks inside the generate blocks.
  // The ALU units are further gated by in_v_i so a cycle with no valid input token
  // (including a control-gated ALU firing on the untaken polarity, where the joiner
  // holds out_v_o=0) keeps the datapath quiet. dout_o only latches when in_v_i is
  // high (see register block), so this is power-only and cannot corrupt results.
  logic use_alu;
  logic addsub_en;
  logic mul_en;
  logic shift_en;
  logic logical_en;
  logic cmp_en;
  logic mux_en;

  assign use_alu    = in_v_i && ((out_sel_i == 2'd0) || (out_sel_i == 2'd1));
  assign addsub_en  = use_alu && (alu_sel_i == 3'd0 || alu_sel_i == 3'd1);
  assign mul_en     = use_alu && (alu_sel_i == 3'd2);
  assign shift_en   = use_alu && (alu_sel_i == 3'd3 || alu_sel_i == 3'd4);
  assign logical_en = use_alu && (alu_sel_i == 3'd5 || alu_sel_i == 3'd6 || alu_sel_i == 3'd7);
  assign cmp_en     = (out_sel_i == 2'd1);
  assign mux_en     = (out_sel_i == 2'd2);

  // ---------------------------------------------- //
  //                  OPERATION UNITS               //
  // ---------------------------------------------- //

  // ---- Add / Subtract ----
  if (HAS_ADDSUB) begin : gen_addsub
    logic addsub_mode;
    logic [DATA_WIDTH-1:0] addsub_a_g, addsub_b_g;  // operand-isolated inputs
    // alu_sel 0 → ADD (bit[0]=0), alu_sel 1 → SUB (bit[0]=1)
    assign addsub_mode = alu_sel_i[0];
    assign addsub_a_g  = din_1_i & {DATA_WIDTH{addsub_en}};
    assign addsub_b_g  = din_2 & {DATA_WIDTH{addsub_en}};

    adder_substracter #(
      .DATA_WIDTH(DATA_WIDTH)
    ) addsub_i (
      .a_i          (addsub_a_g),
      .b_i          (addsub_b_g),
      .addsub_mode_i(addsub_mode),
      .res_o        (addsub_dout)
    );

`ifndef SYNTHESIS
    a_addsub_isolated :
    assert property (@(posedge clk_i) disable iff (!rst_ni)
                     (!addsub_en) |-> (addsub_a_g == '0 && addsub_b_g == '0));
`endif
  end else begin : gen_no_addsub
    assign addsub_dout = '0;
  end

  // ---- Multiply ----
  if (HAS_MUL) begin : gen_mul
    logic [DATA_WIDTH-1:0] mul_a_g, mul_b_g;  // operand-isolated inputs
    assign mul_a_g = din_1_i & {DATA_WIDTH{mul_en}};
    assign mul_b_g = din_2 & {DATA_WIDTH{mul_en}};

    multiplier #(
      .DATA_WIDTH(DATA_WIDTH)
    ) mul_i (
      .a_i  (mul_a_g),
      .b_i  (mul_b_g),
      .res_o(mul_dout)
    );

`ifndef SYNTHESIS
    a_mul_isolated :
    assert property (@(posedge clk_i) disable iff (!rst_ni)
                     (!mul_en) |-> (mul_a_g == '0 && mul_b_g == '0));
`endif
  end else begin : gen_no_mul
    assign mul_dout = '0;
  end

  // ---- Shift ----
  if (HAS_SHIFT) begin : gen_shift
    logic sr_mode;
    logic [DATA_WIDTH-1:0] shift_a_g, shift_b_g;  // operand-isolated inputs
    // alu_sel 3 → logical (sr_mode=0), alu_sel 4 → arithmetic (sr_mode=1).
    // sr_mode selects sign-fill, not the direction: din_2 is the shift amount
    // and its sign picks left (>=0) or right (<0) inside ash.sv.
    assign sr_mode   = (alu_sel_i == 3'd4);
    assign shift_a_g = din_1_i & {DATA_WIDTH{shift_en}};
    assign shift_b_g = din_2 & {DATA_WIDTH{shift_en}};

    shifter #(
      .DATA_WIDTH(DATA_WIDTH)
    ) shift_i (
      .a_i      (shift_a_g),
      .b_i      (shift_b_g),
      .sr_mode_i(sr_mode),
      .res_o    (shift_dout)
    );

`ifndef SYNTHESIS
    a_shift_isolated :
    assert property (@(posedge clk_i) disable iff (!rst_ni)
                     (!shift_en) |-> (shift_a_g == '0 && shift_b_g == '0));
`endif
  end else begin : gen_no_shift
    assign shift_dout = '0;
  end

  // ---- Logical (AND / OR / XOR) ----
  if (HAS_LOGICAL) begin : gen_logical
    logic [DATA_WIDTH-1:0] logical_a_g, logical_b_g;  // operand-isolated inputs
    assign logical_a_g = din_1_i & {DATA_WIDTH{logical_en}};
    assign logical_b_g = din_2 & {DATA_WIDTH{logical_en}};

    always_comb begin
      case (alu_sel_i)
        3'd5:    logical_dout = logical_a_g & logical_b_g;
        3'd6:    logical_dout = logical_a_g | logical_b_g;
        3'd7:    logical_dout = logical_a_g ^ logical_b_g;
        default: logical_dout = logical_a_g & logical_b_g;
      endcase
    end

`ifndef SYNTHESIS
    a_logical_isolated :
    assert property (@(posedge clk_i) disable iff (!rst_ni)
                     (!logical_en) |-> (logical_a_g == '0 && logical_b_g == '0));
`endif
  end else begin : gen_no_logical
    assign logical_dout = '0;
  end

  // ---- ALU output mux ----
  always_comb begin
    case (alu_sel_i)
      3'd0, 3'd1:       alu_dout = addsub_dout;
      3'd2:             alu_dout = mul_dout;
      3'd3, 3'd4:       alu_dout = shift_dout;
      3'd5, 3'd6, 3'd7: alu_dout = logical_dout;
      default:          alu_dout = addsub_dout;
    endcase
  end

  // ---------------------------------------------- //
  //                   COMPARATOR                   //
  // ---------------------------------------------- //

  if (HAS_CMP) begin : gen_cmp
    localparam logic [DATA_WIDTH-2:0] ZEROS = '0;
    logic [DATA_WIDTH-1:0] cmp_in_g;  // operand-isolated input (the ALU result)
    logic cmp_eq, cmp_gr;
    assign cmp_in_g = alu_dout & {DATA_WIDTH{cmp_en}};
    assign cmp_eq   = (cmp_in_g == '0);
    assign cmp_gr   = ($signed(cmp_in_g) > 0);

    always_comb begin
      case (cmp_sel_i)
        1'b0:    cmp_dout = {ZEROS, cmp_eq};
        default: cmp_dout = {ZEROS, cmp_gr};
      endcase
    end

`ifndef SYNTHESIS
    a_cmp_isolated :
    assert property (@(posedge clk_i) disable iff (!rst_ni) (!cmp_en) |-> (cmp_in_g == '0));
`endif
  end else begin : gen_no_cmp
    assign cmp_dout = '0;
  end

  // ---------------------------------------------- //
  //                      MUX                       //
  // ---------------------------------------------- //

  if (HAS_MUX) begin : gen_mux
    logic [DATA_WIDTH-1:0] mux_d1_g, mux_d2_g;  // operand-isolated inputs
    assign mux_d1_g = din_1_i & {DATA_WIDTH{mux_en}};
    assign mux_d2_g = din_2_i & {DATA_WIDTH{mux_en}};
    assign mux_dout = cin_i ? mux_d2_g : mux_d1_g;
    assign b1_v     = cin_i ? 1'b0 : in_v_i;
    assign b2_v     = cin_i ? in_v_i : 1'b0;

`ifndef SYNTHESIS
    a_mux_isolated :
    assert property (@(posedge clk_i) disable iff (!rst_ni)
                     (!mux_en) |-> (mux_d1_g == '0 && mux_d2_g == '0));
`endif
  end else begin : gen_no_mux
    assign mux_dout = '0;
    assign b1_v     = 1'b0;
    assign b2_v     = 1'b0;
  end

  // ---------------------------------------------- //
  //                 OUTPUT SELECTION               //
  // ---------------------------------------------- //

  always_comb begin
    case (out_sel_i)
      2'd0:    pre_dout = alu_dout;
      2'd1:    pre_dout = cmp_dout;
      default: pre_dout = mux_dout;
    endcase
  end

  // ---------------------------------------------- //
  //            REGISTERS & CONTROL                 //
  // ---------------------------------------------- //

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      dout_o       <= '0;
      initial_load <= 1'b0;
      delay_count  <= 16'd0;
      at_last      <= (delay_value_i == 16'd1);
      v_reg        <= 1'b0;
      b1_v_reg     <= 1'b0;
      b2_v_reg     <= 1'b0;
    end else begin
      if (clr_i) begin
        dout_o       <= '0;
        initial_load <= 1'b0;
        delay_count  <= 16'd0;
        at_last      <= (delay_value_i == 16'd1);
        v_reg        <= 1'b0;
        b1_v_reg     <= 1'b0;
        b2_v_reg     <= 1'b0;
      end else begin
        if (!initial_load) begin
          dout_o       <= initial_data_i;
          v_reg        <= initial_valid_i;
          initial_load <= 1'b1;
          // Reseed at delay_count == 0 with the now-stable configured value.
          at_last      <= (delay_value_i == 16'd1);
        end else begin
          if (in_r & in_v_i) begin
            dout_o <= pre_dout;
          end
          if (in_r) begin
            v_reg    <= in_v_i;
            b1_v_reg <= b1_v;
            b2_v_reg <= b2_v;
          end
        end

        if (initial_load && fire && delay_value_i != 16'd0) begin
          if (delay_count + 1 == delay_value_i) begin
            delay_count <= 16'd0;
            at_last     <= (delay_value_i == 16'd1);
            // Seamless feedback rollover: out_v_o implies in_r, so if the next
            // group's first token is consumed this same cycle (din_2 is already
            // re-seeded, see the feedback mux) stay loaded and skip the reload
            // bubble. Otherwise fall back to reloading on the next cycle.
            if (!(feedback_i && in_v_i)) begin
              initial_load <= 1'b0;
            end
          end else begin
            delay_count <= delay_count + 1;
            at_last     <= (delay_count + 16'd2 == delay_value_i);
          end
        end
      end
    end
  end

  // A fork holding no token must not apply backpressure. Both fork flavors
  // derive their ready from the destination readys alone, so an idle FU would
  // refuse a new token until every destination happens to be ready. That closes
  // a ready cycle whenever the FU output feeds one of its own operand buffers
  // (routing self-loop, mux_sel = dout): the operand buffer only frees its
  // registered ready once the joiner drains it, and the joiner only drains it
  // once the FU accepts - a deadlock the elastic protocol must not have.
  // Qualifying with v_reg breaks it and leaves fire (and therefore every output
  // valid) untouched, since fire is already gated on v_reg.
  assign in_r   = fork_r | ~v_reg;

  // Output token completion: every enabled destination has taken the token
  // (lazy: all ready in the same cycle; eager: the last pending branch is
  // ready). Internal state - delay counter, feedback reseed, input ready -
  // advances on completion regardless of the fork protocol.
  assign fire   = v_reg & in_r;
  assign fire_d = fire & at_last;

  generate
    if (EAGER_FORK) begin : gen_out_v_eager
      // Raw flavor valids; the PE ANDs them with fork_v_o per destination.
      assign out_v_o    = v_reg;
      assign out_d_v_o  = v_reg & at_last;
      assign out_b1_v_o = b1_v_reg;
      assign out_b2_v_o = b2_v_reg;
    end else begin : gen_out_v_lazy
      assign out_v_o    = fire;
      assign out_d_v_o  = fire_d;
      assign out_b1_v_o = b1_v_reg & in_r;
      assign out_b2_v_o = b2_v_reg & in_r;
    end
  endgenerate

  // Feedback PEs keep accepting through the group boundary (seamless rollover);
  // non-feedback decimators keep the legacy one-cycle hold while fire_d is high.
  assign in_r_o = in_r && initial_load && (feedback_i || !fire_d);

  // ---------------------------------------------- //
  //                  OUTPUT FORK                   //
  // ---------------------------------------------- //

  generate
    if (EAGER_FORK) begin : gen_fork_eager
      eager_fork_cfg #(
        .NUM_BRANCHES(N_DESTINATIONS),
        .DATA_WIDTH  (1)
      ) FS (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .clr_i      (clr_i),
        .fork_mask_i(fork_mask_i),
        .data_i     (1'b0),
        .valid_i    (v_reg),
        .ready_o    (fork_r),
        .data_o     (),
        .valid_o    (fork_v_o),
        .ready_i    (out_r_i)
      );
    end else begin : gen_fork_lazy
      fork_sender #(
        .NUM_READYS(N_DESTINATIONS)
      ) FS (
        .ready_in_o  (fork_r),
        .readys_out_i(out_r_i),
        .fork_mask_i (fork_mask_i)
      );
      assign fork_v_o = '1;
    end
  endgenerate

endmodule
