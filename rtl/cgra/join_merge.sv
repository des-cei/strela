// Copyright 2026 CEIMM-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module join_merge #(
  parameter int DATA_WIDTH = 32
) (
  // Configuration
  input logic [1:0] mode_i,
  // Control-gated FU (predicated ALU). When gate_active_i is set, the joiner
  // consumes the two data operands and the control token together, but only
  // fires (asserts out_v_o and forwards the operands to the FU) when the
  // control matches gate_pol_i. Non-firing tokens are dropped without waiting
  // on the downstream ready, so the FU sees out_v_o=0 and stays idle. Derived
  // in the PE from (mode_i==join_w_c && out_sel==ALU); it overrides mode_i.
  input logic gate_active_i,
  input logic gate_pol_i,

  // Input data and control
  input  logic [DATA_WIDTH-1:0] din_1_i,
  input  logic                  din_1_v_i,
  output logic                  din_1_r_o,
  input  logic [DATA_WIDTH-1:0] din_2_i,
  input  logic                  din_2_v_i,
  output logic                  din_2_r_o,
  input  logic                  cin_i,
  input  logic                  cin_v_i,
  output logic                  cin_r_o,

  // Output data and control
  output logic [DATA_WIDTH-1:0] dout_1_o,
  output logic [DATA_WIDTH-1:0] dout_2_o,
  output logic                  cout_o,
  output logic                  out_v_o,
  input  logic                  out_r_i
);

  logic fire;
  assign fire = (cin_i == gate_pol_i);

  always_comb begin
    if (gate_active_i) begin
      // Control-gated ALU: consume din_1, din_2 and cin together whenever all
      // three are valid; assert output valid only on a firing (cin==pol) token.
      // A non-firing token is still consumed (dropped) regardless of out_r_i.
      out_v_o   = din_1_v_i & din_2_v_i & cin_v_i & fire;
      din_1_r_o = din_2_v_i & cin_v_i & (fire ? out_r_i : 1'b1);
      din_2_r_o = din_1_v_i & cin_v_i & (fire ? out_r_i : 1'b1);
      cin_r_o   = din_1_v_i & din_2_v_i & (fire ? out_r_i : 1'b1);
      cout_o    = cin_i;
    end else begin
      case (mode_i)
        2'b00: begin
          // Join mode without control
          out_v_o = din_1_v_i & din_2_v_i;
          din_1_r_o = out_r_i & din_2_v_i;
          din_2_r_o = out_r_i & din_1_v_i;
          cin_r_o = 1'b0;
          cout_o = cin_i;
        end
        2'b01: begin
          // Join mode with control
          out_v_o = din_1_v_i & din_2_v_i & cin_v_i;
          din_1_r_o = out_r_i & din_2_v_i & cin_v_i;
          din_2_r_o = out_r_i & din_1_v_i & cin_v_i;
          cin_r_o = out_r_i & din_1_v_i & din_2_v_i;
          cout_o = cin_i;
        end

        2'b10: begin
          // Merge mode without control. din_1 has priority: when both inputs are
          // valid in the same cycle, din_2 is not acknowledged and its token is
          // held in the upstream elastic buffer for a later cycle. The control
          // input is ignored, so the output order is the arrival order.
          out_v_o = din_1_v_i | din_2_v_i;
          din_1_r_o = out_r_i;
          din_2_r_o = out_r_i & !din_1_v_i;
          cin_r_o = 1'b0;
          cout_o = !din_1_v_i;
        end
        2'b11: begin
          // Merge mode with control. cin selects the single input to consume and
          // forward (cin=0 -> din_1 / false side, cin=1 -> din_2 / true side);
          // the unselected input is not acknowledged. A valid control token is
          // required. cout drives the FU mux (cin ? din_2 : din_1) so the chosen
          // side is forwarded, and consuming the control stream in order makes
          // the output program-ordered.
          out_v_o = cin_v_i & (cin_i ? din_2_v_i : din_1_v_i);
          din_1_r_o = out_r_i & cin_v_i & ~cin_i;
          din_2_r_o = out_r_i & cin_v_i & cin_i;
          cin_r_o = out_r_i & (cin_i ? din_2_v_i : din_1_v_i);
          cout_o = cin_i;
        end
        default: begin
          // Join mode without control
          out_v_o = din_1_v_i & din_2_v_i;
          din_1_r_o = out_r_i & din_2_v_i;
          din_2_r_o = out_r_i & din_1_v_i;
          cin_r_o = 1'b0;
          cout_o = cin_i;
        end
      endcase
    end
  end

  assign dout_1_o = din_1_i;
  assign dout_2_o = din_2_i;

endmodule
