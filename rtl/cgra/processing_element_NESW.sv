// Copyright 2026 CEIMM-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

// Unified Processing Element
//
// PE routing [45:0]:
//   [3:0]    eb_{n,e,s,w}_en
//   [9:4]    mask_fs_n  {din_1_r, din_2_r, cin_r, E_r, S_r, W_r}
//   [15:10]  mask_fs_e  {din_1_r, din_2_r, cin_r, N_r, S_r, W_r}
//   [21:16]  mask_fs_s  {din_1_r, din_2_r, cin_r, N_r, E_r, W_r}
//   [27:22]  mask_fs_w  {din_1_r, din_2_r, cin_r, N_r, E_r, S_r}
//   [33:28]  (reserved)
//   [36:34]  mux_sel_n
//   [39:37]  mux_sel_e
//   [42:40]  mux_sel_s
//   [45:43]  mux_sel_w
//   [49:46]  (reserved)
//
// Data path [159:50]
//   [50]     eb_fu1_en
//   [51]     eb_fu2_en
//   [54:52]  mux_sel_1   0=N 1=E 2=S 3=W 4=constant 5=dout(fb)
//   [57:55]  mux_sel_2   same encoding
//   [59:58]  mux_sel_c   0=N 1=E 2=S 3=W  (HAS_MUX only)
//   [60]     (reserved)
//   [62:61]  jm_mode     0=join_wo_c 1=join_w_c 2=merge 3=merge_w_c
//   [63]     feedback
//   [66:64]  alu_sel     (see FU.sv encoding)
//   [67]     cmp_sel     (HAS_CMP only)
//   [69:68]  out_sel     0=ALU 1=CMP 2=MUX
//   [75:70]  mask_fs_fu  {din_2_r, din_1_r, N_r, E_r, S_r, W_r}
//   [77:76]  (reserved)
//   [78]     initial_valid
//   [79]     fu_gate_pol : control-gated ALU fires on cin==1 (1) vs cin==0 (0)
//            active when jm_mode==join_w_c && out_sel==ALU (HAS_MUX only)
//   [95:80]  delay_value
//   [127:96] initial_data
//   [159:128] constant
//
// The layout above is the DATA_WIDTH=32 word (160 bits, 5 x 32-bit shifts).
// The configuration word is generally ConfWidth = 96 + 2*DATA_WIDTH bits
// rounded up to a whole number of DATA_WIDTH shifts: [95:0] is the same for
// every width, initial_data and constant are DATA_WIDTH bits wide each and
// follow it. For DATA_WIDTH=64 (hjson `data_width: 64`) the word is 256 bits,
// 4 x 64-bit shifts:
//   [159:96]  initial_data
//   [223:160] constant
//   [255:224] (reserved)
//
// * When HAS_MUX=0, cin_r is tied to 1 and its mask bit must be set to 0.
//
// Output valid mux encoding (mux_sel_{n,e,s,w}), 7 options (3-bit sel):
//   0 = neighbor buffer 0    3 = dout_v    5 = dout_b1_v (HAS_MUX)
//   1 = neighbor buffer 1    4 = dout_d_v  6 = dout_b2_v (HAS_MUX)
//   2 = neighbor buffer 2
//
// Former PE type equivalences:
//   A       : HAS_ADDSUB=1
//   M       : HAS_MUL=1
//   L       : HAS_SHIFT=1, HAS_LOGICAL=1
//   AML     : HAS_ADDSUB=1, HAS_MUL=1, HAS_SHIFT=1, HAS_LOGICAL=1
//   AMLCBMI : HAS_ADDSUB=1, HAS_MUL=1, HAS_SHIFT=1, HAS_LOGICAL=1, HAS_CMP=1, HAS_MUX=1

module processing_element_NESW
  import cgra_pkg::*;
#(
  parameter int             DATA_WIDTH     = 32,
  parameter config_border_t CONFIG_BORDER  = NORTH,
  // FU operation enables
  parameter bit             HAS_ADDSUB     = 1,
  parameter bit             HAS_MUL        = 1,
  parameter bit             HAS_SHIFT      = 1,
  parameter bit             HAS_LOGICAL    = 1,
  // FU feature enables
  parameter bit             HAS_CMP        = 1,
  parameter bit             HAS_MUX        = 1,
  // Buffering depth of the PE direction-input buffers (REG_N/E/S/W).
  // <3: depth-2 elastic buffers (values 0/1/2 are equivalent). >=3: elastic_fifo
  //    of that depth, adding routing-path slack independently of the FU buffers.
  parameter int             DEEP_BUFFER_PE = 0,
  // FU-side buffering depth for REG_1, REG_2 and the control (cin) path.
  // <3: depth-2 elastic buffers on REG_1/REG_2 and the 1-bit control path
  //    (values 0/1/2 are equivalent; the control path is always buffered).
  // >=3: REG_1, REG_2 and the control path become elastic_fifo of depth
  //    DEEP_BUFFER_FU, trading flops for slack to absorb latency-imbalanced
  //    reconvergence (see tmp_fifo_exploration.md).
  parameter int             DEEP_BUFFER_FU = 0,
  // Fork protocol for the routing-node and FU output forks.
  // 0: lazy (fork_sender) - a token is offered to its consumers only in the
  //    cycle every enabled branch is ready, so one slow branch stalls all.
  // 1: eager (eager_fork_cfg) - each enabled branch is served as soon as it
  //    is ready; per-branch valids replace the shared broadcast valid.
  parameter bit             EAGER_FORK     = 0
) (
  // Clock and reset
  input logic clk_i,
  input logic rst_ni,
  input logic clr_i,

  // Configuration chain
  input  logic conf_en_i,
  output logic conf_en_o,

  // Input data - NESW
  input  logic [DATA_WIDTH-1:0] north_din_i,
  input  logic                  north_din_v_i,
  output logic                  north_din_r_o,
  input  logic [DATA_WIDTH-1:0] east_din_i,
  input  logic                  east_din_v_i,
  output logic                  east_din_r_o,
  input  logic [DATA_WIDTH-1:0] south_din_i,
  input  logic                  south_din_v_i,
  output logic                  south_din_r_o,
  input  logic [DATA_WIDTH-1:0] west_din_i,
  input  logic                  west_din_v_i,
  output logic                  west_din_r_o,

  // Output data - NESW
  output logic [DATA_WIDTH-1:0] north_dout_o,
  output logic                  north_dout_v_o,
  input  logic                  north_dout_r_i,
  output logic [DATA_WIDTH-1:0] east_dout_o,
  output logic                  east_dout_v_o,
  input  logic                  east_dout_r_i,
  output logic [DATA_WIDTH-1:0] south_dout_o,
  output logic                  south_dout_v_o,
  input  logic                  south_dout_r_i,
  output logic [DATA_WIDTH-1:0] west_dout_o,
  output logic                  west_dout_v_o,
  input  logic                  west_dout_r_i
);
  // synopsys sync_set_reset clr_i

  // A PE with no FU features is a routing-only (bypass) tile: the entire
  // functional-unit datapath is elided and only the N/E/S/W routing crossbar
  // remains. The FU outputs the crossbar would read are tied off (see gen_no_fu).
  localparam bit HasFU = HAS_ADDSUB | HAS_MUL | HAS_SHIFT | HAS_LOGICAL | HAS_CMP | HAS_MUX;

  // ---------------------------------------------- //
  //                 CONFIGURATION                  //
  // ---------------------------------------------- //

  // PE routing
  logic [           2:0] mux_sel_n;
  logic [           2:0] mux_sel_e;
  logic [           2:0] mux_sel_s;
  logic [           2:0] mux_sel_w;
  logic [           1:0] data_mux_sel_n;
  logic [           1:0] data_mux_sel_e;
  logic [           1:0] data_mux_sel_s;
  logic [           1:0] data_mux_sel_w;
  logic [           5:0] mask_fs_n;
  logic [           5:0] mask_fs_e;
  logic [           5:0] mask_fs_s;
  logic [           5:0] mask_fs_w;
  logic                  eb_n_en;
  logic                  eb_e_en;
  logic                  eb_s_en;
  logic                  eb_w_en;

  // Data path
  logic                  eb_fu1_en;
  logic                  eb_fu2_en;
  logic [           2:0] mux_sel_1;
  logic [           2:0] mux_sel_2;
  logic [           1:0] mux_sel_c;
  logic [           1:0] jm_mode;
  logic                  feedback;
  logic [           2:0] alu_sel;
  logic                  cmp_sel;
  logic [           1:0] out_sel;
  logic [           5:0] mask_fs_fu;
  logic                  gate_pol;
  logic                  gate_active;
  logic                  initial_valid;
  logic [          15:0] delay_value;
  logic [DATA_WIDTH-1:0] initial_data;
  logic [DATA_WIDTH-1:0] constant;

  // Config shift register: the 96 width-independent bits plus initial_data and
  // constant, rounded up to whole DATA_WIDTH shifts (160 bits at 32, 256 at 64).
  localparam int ConfWidth = ((96 + 2 * DATA_WIDTH + DATA_WIDTH - 1) / DATA_WIDTH) * DATA_WIDTH;
  logic [ ConfWidth-1:0] conf_wire;
  logic [ ConfWidth-1:0] conf_reg;

  // Temp wires for CONFIG_BORDER routing
  logic [DATA_WIDTH-1:0] tmp_north_dout;
  logic [DATA_WIDTH-1:0] tmp_east_dout;
  logic [DATA_WIDTH-1:0] tmp_south_dout;
  logic [DATA_WIDTH-1:0] tmp_west_dout;
  logic                  tmp_north_din_v;
  logic                  tmp_east_din_v;
  logic                  tmp_south_din_v;
  logic                  tmp_west_din_v;

  // ---------------------------------------------- //
  //               INTERCONNECT SIGNALS             //
  // ---------------------------------------------- //

  // NESW input elastic buffers
  logic [DATA_WIDTH-1:0] north_buffer;
  logic [DATA_WIDTH-1:0] east_buffer;
  logic [DATA_WIDTH-1:0] south_buffer;
  logic [DATA_WIDTH-1:0] west_buffer;
  // Per-branch valids from each routing-node fork. Bit order follows the
  // fork's ready vector: [5]=din_1, [4]=din_2, [3]=cin, [2:0]=the three
  // remaining direction outputs (see the mask_fs_* comment in the header).
  // Lazy mode replicates the shared broadcast valid on all six bits.
  logic [           5:0] fs_n_v;
  logic [           5:0] fs_e_v;
  logic [           5:0] fs_s_v;
  logic [           5:0] fs_w_v;
  // Per-destination grant from the FU output fork {din_2, din_1, N, E, S, W};
  // all-ones in lazy mode.
  logic [           5:0] fu_fork_v;
  logic                  temp_north_buffer_v;
  logic                  temp_east_buffer_v;
  logic                  temp_south_buffer_v;
  logic                  temp_west_buffer_v;
  logic                  north_buffer_r;
  logic                  east_buffer_r;
  logic                  south_buffer_r;
  logic                  west_buffer_r;

  // Cell input path
  logic [DATA_WIDTH-1:0] EB_din_1;
  logic [DATA_WIDTH-1:0] EB_din_2;
  logic                  EB_din_1_v;
  logic                  EB_din_2_v;
  logic [DATA_WIDTH-1:0] jm_din_1;
  logic [DATA_WIDTH-1:0] jm_din_2;
  logic                  jm_din_1_v;
  logic                  jm_din_1_r;
  logic                  jm_din_2_v;
  logic                  jm_din_2_r;
  logic                  jm_cin;
  logic                  jm_cin_v;
  logic                  jm_cin_r;
  logic                  jm_cout;
  logic [DATA_WIDTH-1:0] jm_dout_1;
  logic [DATA_WIDTH-1:0] jm_dout_2;
  logic                  jm_dout_v;

  // Cell readys
  logic                  din_1_r;
  logic                  din_2_r;
  logic                  cin_r;
  logic                  dout_r;

  // FU outputs
  logic [DATA_WIDTH-1:0] dout;
  logic                  dout_v;
  logic                  dout_d_v;
  logic                  dout_b1_v;
  logic                  dout_b2_v;

  // ---------------------------------------------- //
  //              CONFIG SHIFT REGISTER             //
  // ---------------------------------------------- //

  // The bitstream tooling (bitstream/CGRA.py) encodes 32- and 64-bit words only.
  if (DATA_WIDTH != 32 && DATA_WIDTH != 64) begin : gen_bad_data_width
    $error("DATA_WIDTH must be 32 or 64 (got %0d)", DATA_WIDTH);
  end

  generate
    if (CONFIG_BORDER == NORTH) begin : gen_north_conf
      assign conf_wire       = {north_din_i, conf_reg[ConfWidth-1:DATA_WIDTH]};
      assign tmp_north_din_v = north_din_v_i && !conf_en_i;
      assign tmp_east_din_v  = east_din_v_i;
      assign tmp_south_din_v = south_din_v_i;
      assign tmp_west_din_v  = west_din_v_i;
      assign north_dout_o    = tmp_north_dout;
      assign east_dout_o     = tmp_east_dout;
      assign south_dout_o    = conf_en_i ? conf_reg[DATA_WIDTH-1:0] : tmp_south_dout;
      assign west_dout_o     = tmp_west_dout;
    end else if (CONFIG_BORDER == EAST) begin : gen_east_conf
      assign conf_wire       = {east_din_i, conf_reg[ConfWidth-1:DATA_WIDTH]};
      assign tmp_north_din_v = north_din_v_i;
      assign tmp_east_din_v  = east_din_v_i && !conf_en_i;
      assign tmp_south_din_v = south_din_v_i;
      assign tmp_west_din_v  = west_din_v_i;
      assign north_dout_o    = tmp_north_dout;
      assign east_dout_o     = tmp_east_dout;
      assign south_dout_o    = tmp_south_dout;
      assign west_dout_o     = conf_en_i ? conf_reg[DATA_WIDTH-1:0] : tmp_west_dout;
    end else if (CONFIG_BORDER == SOUTH) begin : gen_south_conf
      assign conf_wire       = {south_din_i, conf_reg[ConfWidth-1:DATA_WIDTH]};
      assign tmp_north_din_v = north_din_v_i;
      assign tmp_east_din_v  = east_din_v_i;
      assign tmp_south_din_v = south_din_v_i && !conf_en_i;
      assign tmp_west_din_v  = west_din_v_i;
      assign north_dout_o    = conf_en_i ? conf_reg[DATA_WIDTH-1:0] : tmp_north_dout;
      assign east_dout_o     = tmp_east_dout;
      assign south_dout_o    = tmp_south_dout;
      assign west_dout_o     = tmp_west_dout;
    end else begin : gen_west_conf
      assign conf_wire       = {west_din_i, conf_reg[ConfWidth-1:DATA_WIDTH]};
      assign tmp_north_din_v = north_din_v_i;
      assign tmp_east_din_v  = east_din_v_i;
      assign tmp_south_din_v = south_din_v_i;
      assign tmp_west_din_v  = west_din_v_i && !conf_en_i;
      assign north_dout_o    = tmp_north_dout;
      assign east_dout_o     = conf_en_i ? conf_reg[DATA_WIDTH-1:0] : tmp_east_dout;
      assign south_dout_o    = tmp_south_dout;
      assign west_dout_o     = tmp_west_dout;
    end
  endgenerate

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      conf_reg <= '0;
    end else begin
      if (conf_en_i) begin
        conf_reg <= conf_wire;
      end
    end
  end

  assign conf_en_o      = conf_en_i;

  // ---------------------------------------------- //
  //               CONFIG DECODING                  //
  // ---------------------------------------------- //

  // PE routing
  assign eb_n_en        = conf_en_i ? 1'b0 : conf_reg[0];
  assign eb_e_en        = conf_en_i ? 1'b0 : conf_reg[1];
  assign eb_s_en        = conf_en_i ? 1'b0 : conf_reg[2];
  assign eb_w_en        = conf_en_i ? 1'b0 : conf_reg[3];
  assign mask_fs_n      = conf_reg[9:4];
  assign mask_fs_e      = conf_reg[15:10];
  assign mask_fs_s      = conf_reg[21:16];
  assign mask_fs_w      = conf_reg[27:22];
  // RESERVED [33:28]
  assign mux_sel_n      = conf_reg[36:34];
  assign mux_sel_e      = conf_reg[39:37];
  assign mux_sel_s      = conf_reg[42:40];
  assign mux_sel_w      = conf_reg[45:43];
  // RESERVED [49:46]

  // Data path
  assign eb_fu1_en      = conf_reg[50];
  assign eb_fu2_en      = conf_reg[51];
  assign mux_sel_1      = conf_reg[54:52];
  assign mux_sel_2      = conf_reg[57:55];
  assign mux_sel_c      = conf_reg[59:58];
  // RESERVED [60]
  assign jm_mode        = conf_reg[62:61];
  assign feedback       = conf_reg[63];
  assign alu_sel        = conf_reg[66:64];
  assign cmp_sel        = conf_reg[67];
  assign out_sel        = conf_reg[69:68];
  assign mask_fs_fu     = conf_reg[75:70];
  // RESERVED [77:76]
  assign initial_valid  = conf_reg[78];
  assign gate_pol       = conf_reg[79];
  // Control-gated ALU: inferred from join_w_c + ALU output (never emitted for
  // select/branch, which use join_w_c + MUX). Requires the control mux (P).
  assign gate_active    = HAS_MUX & (jm_mode == 2'b01) & (out_sel == 2'b00);
  assign delay_value    = conf_reg[95:80];
  assign initial_data   = conf_reg[96+:DATA_WIDTH];
  assign constant       = conf_reg[96+DATA_WIDTH+:DATA_WIDTH];

  // Data output mux sel: mux_sel[2]=1 => FU output (index 3), else use [1:0]
  assign data_mux_sel_n = mux_sel_n[2] ? 2'b11 : mux_sel_n[1:0];
  assign data_mux_sel_e = mux_sel_e[2] ? 2'b11 : mux_sel_e[1:0];
  assign data_mux_sel_s = mux_sel_s[2] ? 2'b11 : mux_sel_s[1:0];
  assign data_mux_sel_w = mux_sel_w[2] ? 2'b11 : mux_sel_w[1:0];

  /* ------------------------------ NORTH NODE ------------------------------- */

  if (DEEP_BUFFER_PE < 3) begin : gen_reg_n_baseline
    elastic_buffer #(
      .DATA_WIDTH(DATA_WIDTH)
    ) REG_N (
      .clk_i  (clk_i),
      .rst_ni (rst_ni),
      .clr_i  (clr_i),
      .en_i   (eb_n_en),
      .data_i (north_din_i),
      .valid_i(tmp_north_din_v),
      .ready_o(north_din_r_o),
      .data_o (north_buffer),
      .valid_o(temp_north_buffer_v),
      .ready_i(north_buffer_r)
    );
  end else begin : gen_reg_n_deep
    elastic_fifo #(
      .DATA_WIDTH(DATA_WIDTH),
      .DEPTH     (DEEP_BUFFER_PE)
    ) REG_N (
      .clk_i   (clk_i),
      .rst_ni  (rst_ni),
      .clr_i   (clr_i),
      .en_i    (eb_n_en),
      .din_i   (north_din_i),
      .din_v_i (tmp_north_din_v),
      .din_r_o (north_din_r_o),
      .dout_o  (north_buffer),
      .dout_v_o(temp_north_buffer_v),
      .dout_r_i(north_buffer_r)
    );
  end

  generate
    if (EAGER_FORK) begin : gen_fs_n_eager
      eager_fork_cfg #(
        .NUM_BRANCHES(6),
        .DATA_WIDTH  (1)
      ) FS_N (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .clr_i      (clr_i),
        .fork_mask_i(mask_fs_n),
        .data_i     (1'b0),
        .valid_i    (temp_north_buffer_v),
        .ready_o    (north_buffer_r),
        .data_o     (),
        .valid_o    (fs_n_v),
        .ready_i    ({din_1_r, din_2_r, cin_r, east_dout_r_i, south_dout_r_i, west_dout_r_i})
      );
    end else begin : gen_fs_n_lazy
      fork_sender #(
        .NUM_READYS(6)
      ) FS_N (
        .fork_mask_i (mask_fs_n),
        .ready_in_o  (north_buffer_r),
        .readys_out_i({din_1_r, din_2_r, cin_r, east_dout_r_i, south_dout_r_i, west_dout_r_i})
      );
      assign fs_n_v = {6{temp_north_buffer_v && north_buffer_r}};
    end
  endgenerate

  // Output - data mux
  mux #(
    .NUM_INPUTS(4),
    .DATA_WIDTH(DATA_WIDTH)
  ) MUX_N (
    .sel_i(data_mux_sel_n),
    .mux_i({dout, west_buffer, south_buffer, east_buffer}),
    .mux_o(tmp_north_dout)
  );

  // Output - valid mux (7 options: 3 neighbor buffers, dout_v, dout_d_v, dout_b1_v, dout_b2_v)
  mux #(
    .NUM_INPUTS(7),
    .DATA_WIDTH(1)
  ) MUX_N_v (
    .sel_i(mux_sel_n),
    .mux_i({
      dout_b2_v & fu_fork_v[3],
      dout_b1_v & fu_fork_v[3],
      dout_d_v & fu_fork_v[3],
      dout_v & fu_fork_v[3],
      fs_w_v[2],
      fs_s_v[2],
      fs_e_v[2]
    }),
    .mux_o(north_dout_v_o)
  );

  /* ------------------------------ EAST  NODE ------------------------------- */

  if (DEEP_BUFFER_PE < 3) begin : gen_reg_e_baseline
    elastic_buffer #(
      .DATA_WIDTH(DATA_WIDTH)
    ) REG_E (
      .clk_i  (clk_i),
      .rst_ni (rst_ni),
      .clr_i  (clr_i),
      .en_i   (eb_e_en),
      .data_i (east_din_i),
      .valid_i(tmp_east_din_v),
      .ready_o(east_din_r_o),
      .data_o (east_buffer),
      .valid_o(temp_east_buffer_v),
      .ready_i(east_buffer_r)
    );
  end else begin : gen_reg_e_deep
    elastic_fifo #(
      .DATA_WIDTH(DATA_WIDTH),
      .DEPTH     (DEEP_BUFFER_PE)
    ) REG_E (
      .clk_i   (clk_i),
      .rst_ni  (rst_ni),
      .clr_i   (clr_i),
      .en_i    (eb_e_en),
      .din_i   (east_din_i),
      .din_v_i (tmp_east_din_v),
      .din_r_o (east_din_r_o),
      .dout_o  (east_buffer),
      .dout_v_o(temp_east_buffer_v),
      .dout_r_i(east_buffer_r)
    );
  end

  generate
    if (EAGER_FORK) begin : gen_fs_e_eager
      eager_fork_cfg #(
        .NUM_BRANCHES(6),
        .DATA_WIDTH  (1)
      ) FS_E (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .clr_i      (clr_i),
        .fork_mask_i(mask_fs_e),
        .data_i     (1'b0),
        .valid_i    (temp_east_buffer_v),
        .ready_o    (east_buffer_r),
        .data_o     (),
        .valid_o    (fs_e_v),
        .ready_i    ({din_1_r, din_2_r, cin_r, north_dout_r_i, south_dout_r_i, west_dout_r_i})
      );
    end else begin : gen_fs_e_lazy
      fork_sender #(
        .NUM_READYS(6)
      ) FS_E (
        .fork_mask_i (mask_fs_e),
        .ready_in_o  (east_buffer_r),
        .readys_out_i({din_1_r, din_2_r, cin_r, north_dout_r_i, south_dout_r_i, west_dout_r_i})
      );
      assign fs_e_v = {6{temp_east_buffer_v && east_buffer_r}};
    end
  endgenerate

  // Output - data mux
  mux #(
    .NUM_INPUTS(4),
    .DATA_WIDTH(DATA_WIDTH)
  ) MUX_E (
    .sel_i(data_mux_sel_e),
    .mux_i({dout, west_buffer, south_buffer, north_buffer}),
    .mux_o(tmp_east_dout)
  );

  // Output - valid mux
  mux #(
    .NUM_INPUTS(7),
    .DATA_WIDTH(1)
  ) MUX_E_v (
    .sel_i(mux_sel_e),
    .mux_i({
      dout_b2_v & fu_fork_v[2],
      dout_b1_v & fu_fork_v[2],
      dout_d_v & fu_fork_v[2],
      dout_v & fu_fork_v[2],
      fs_w_v[1],
      fs_s_v[1],
      fs_n_v[2]
    }),
    .mux_o(east_dout_v_o)
  );

  /* ------------------------------ SOUTH NODE ------------------------------- */

  if (DEEP_BUFFER_PE < 3) begin : gen_reg_s_baseline
    elastic_buffer #(
      .DATA_WIDTH(DATA_WIDTH)
    ) REG_S (
      .clk_i  (clk_i),
      .rst_ni (rst_ni),
      .clr_i  (clr_i),
      .en_i   (eb_s_en),
      .data_i (south_din_i),
      .valid_i(tmp_south_din_v),
      .ready_o(south_din_r_o),
      .data_o (south_buffer),
      .valid_o(temp_south_buffer_v),
      .ready_i(south_buffer_r)
    );
  end else begin : gen_reg_s_deep
    elastic_fifo #(
      .DATA_WIDTH(DATA_WIDTH),
      .DEPTH     (DEEP_BUFFER_PE)
    ) REG_S (
      .clk_i   (clk_i),
      .rst_ni  (rst_ni),
      .clr_i   (clr_i),
      .en_i    (eb_s_en),
      .din_i   (south_din_i),
      .din_v_i (tmp_south_din_v),
      .din_r_o (south_din_r_o),
      .dout_o  (south_buffer),
      .dout_v_o(temp_south_buffer_v),
      .dout_r_i(south_buffer_r)
    );
  end

  generate
    if (EAGER_FORK) begin : gen_fs_s_eager
      eager_fork_cfg #(
        .NUM_BRANCHES(6),
        .DATA_WIDTH  (1)
      ) FS_S (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .clr_i      (clr_i),
        .fork_mask_i(mask_fs_s),
        .data_i     (1'b0),
        .valid_i    (temp_south_buffer_v),
        .ready_o    (south_buffer_r),
        .data_o     (),
        .valid_o    (fs_s_v),
        .ready_i    ({din_1_r, din_2_r, cin_r, north_dout_r_i, east_dout_r_i, west_dout_r_i})
      );
    end else begin : gen_fs_s_lazy
      fork_sender #(
        .NUM_READYS(6)
      ) FS_S (
        .fork_mask_i (mask_fs_s),
        .ready_in_o  (south_buffer_r),
        .readys_out_i({din_1_r, din_2_r, cin_r, north_dout_r_i, east_dout_r_i, west_dout_r_i})
      );
      assign fs_s_v = {6{temp_south_buffer_v && south_buffer_r}};
    end
  endgenerate

  // Output - data mux
  mux #(
    .NUM_INPUTS(4),
    .DATA_WIDTH(DATA_WIDTH)
  ) MUX_S (
    .sel_i(data_mux_sel_s),
    .mux_i({dout, west_buffer, east_buffer, north_buffer}),
    .mux_o(tmp_south_dout)
  );

  // Output - valid mux
  mux #(
    .NUM_INPUTS(7),
    .DATA_WIDTH(1)
  ) MUX_S_v (
    .sel_i(mux_sel_s),
    .mux_i({
      dout_b2_v & fu_fork_v[1],
      dout_b1_v & fu_fork_v[1],
      dout_d_v & fu_fork_v[1],
      dout_v & fu_fork_v[1],
      fs_w_v[0],
      fs_e_v[1],
      fs_n_v[1]
    }),
    .mux_o(south_dout_v_o)
  );

  /* ------------------------------ WEST  NODE ------------------------------- */

  if (DEEP_BUFFER_PE < 3) begin : gen_reg_w_baseline
    elastic_buffer #(
      .DATA_WIDTH(DATA_WIDTH)
    ) REG_W (
      .clk_i  (clk_i),
      .rst_ni (rst_ni),
      .clr_i  (clr_i),
      .en_i   (eb_w_en),
      .data_i (west_din_i),
      .valid_i(tmp_west_din_v),
      .ready_o(west_din_r_o),
      .data_o (west_buffer),
      .valid_o(temp_west_buffer_v),
      .ready_i(west_buffer_r)
    );
  end else begin : gen_reg_w_deep
    elastic_fifo #(
      .DATA_WIDTH(DATA_WIDTH),
      .DEPTH     (DEEP_BUFFER_PE)
    ) REG_W (
      .clk_i   (clk_i),
      .rst_ni  (rst_ni),
      .clr_i   (clr_i),
      .en_i    (eb_w_en),
      .din_i   (west_din_i),
      .din_v_i (tmp_west_din_v),
      .din_r_o (west_din_r_o),
      .dout_o  (west_buffer),
      .dout_v_o(temp_west_buffer_v),
      .dout_r_i(west_buffer_r)
    );
  end

  generate
    if (EAGER_FORK) begin : gen_fs_w_eager
      eager_fork_cfg #(
        .NUM_BRANCHES(6),
        .DATA_WIDTH  (1)
      ) FS_W (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .clr_i      (clr_i),
        .fork_mask_i(mask_fs_w),
        .data_i     (1'b0),
        .valid_i    (temp_west_buffer_v),
        .ready_o    (west_buffer_r),
        .data_o     (),
        .valid_o    (fs_w_v),
        .ready_i    ({din_1_r, din_2_r, cin_r, north_dout_r_i, east_dout_r_i, south_dout_r_i})
      );
    end else begin : gen_fs_w_lazy
      fork_sender #(
        .NUM_READYS(6)
      ) FS_W (
        .fork_mask_i (mask_fs_w),
        .ready_in_o  (west_buffer_r),
        .readys_out_i({din_1_r, din_2_r, cin_r, north_dout_r_i, east_dout_r_i, south_dout_r_i})
      );
      assign fs_w_v = {6{temp_west_buffer_v && west_buffer_r}};
    end
  endgenerate

  // Output - data mux
  mux #(
    .NUM_INPUTS(4),
    .DATA_WIDTH(DATA_WIDTH)
  ) MUX_W (
    .sel_i(data_mux_sel_w),
    .mux_i({dout, south_buffer, east_buffer, north_buffer}),
    .mux_o(tmp_west_dout)
  );

  // Output - valid mux
  mux #(
    .NUM_INPUTS(7),
    .DATA_WIDTH(1)
  ) MUX_W_v (
    .sel_i(mux_sel_w),
    .mux_i({
      dout_b2_v & fu_fork_v[0],
      dout_b1_v & fu_fork_v[0],
      dout_d_v & fu_fork_v[0],
      dout_v & fu_fork_v[0],
      fs_s_v[0],
      fs_e_v[0],
      fs_n_v[0]
    }),
    .mux_o(west_dout_v_o)
  );

  /* ------------------------------ DATA PATH -------------------------------- */

  generate
    if (HasFU) begin : gen_fu
      // ---- Input 1 ----
      // Source: 0=N 1=E 2=S 3=W 4=constant 5=dout(feedback)
      mux #(
        .NUM_INPUTS(6),
        .DATA_WIDTH(DATA_WIDTH)
      ) MUX_1 (
        .sel_i(mux_sel_1),
        .mux_i({dout, constant, west_buffer, south_buffer, east_buffer, north_buffer}),
        .mux_o(EB_din_1)
      );

      mux #(
        .NUM_INPUTS(6),
        .DATA_WIDTH(1)
      ) MUX_1_v (
        .sel_i(mux_sel_1),
        .mux_i({dout_v & fu_fork_v[4], 1'b1, fs_w_v[5], fs_s_v[5], fs_e_v[5], fs_n_v[5]}),
        .mux_o(EB_din_1_v)
      );

      if (DEEP_BUFFER_FU < 3) begin : gen_reg_1_baseline
        elastic_buffer #(
          .DATA_WIDTH(DATA_WIDTH)
        ) REG_1 (
          .clk_i  (clk_i),
          .rst_ni (rst_ni),
          .clr_i  (clr_i),
          .en_i   (eb_fu1_en),
          .data_i (EB_din_1),
          .valid_i(EB_din_1_v),
          .ready_o(din_1_r),
          .data_o (jm_din_1),
          .valid_o(jm_din_1_v),
          .ready_i(jm_din_1_r)
        );
      end else begin : gen_reg_1_deep
        elastic_fifo #(
          .DATA_WIDTH(DATA_WIDTH),
          .DEPTH     (DEEP_BUFFER_FU)
        ) REG_1 (
          .clk_i   (clk_i),
          .rst_ni  (rst_ni),
          .clr_i   (clr_i),
          .en_i    (eb_fu1_en),
          .din_i   (EB_din_1),
          .din_v_i (EB_din_1_v),
          .din_r_o (din_1_r),
          .dout_o  (jm_din_1),
          .dout_v_o(jm_din_1_v),
          .dout_r_i(jm_din_1_r)
        );
      end

      // ---- Input 2 ----
      mux #(
        .NUM_INPUTS(6),
        .DATA_WIDTH(DATA_WIDTH)
      ) MUX_2 (
        .sel_i(mux_sel_2),
        .mux_i({dout, constant, west_buffer, south_buffer, east_buffer, north_buffer}),
        .mux_o(EB_din_2)
      );

      mux #(
        .NUM_INPUTS(6),
        .DATA_WIDTH(1)
      ) MUX_2_v (
        .sel_i(mux_sel_2),
        .mux_i({dout_v & fu_fork_v[5], 1'b1, fs_w_v[4], fs_s_v[4], fs_e_v[4], fs_n_v[4]}),
        .mux_o(EB_din_2_v)
      );

      if (DEEP_BUFFER_FU < 3) begin : gen_reg_2_baseline
        elastic_buffer #(
          .DATA_WIDTH(DATA_WIDTH)
        ) REG_2 (
          .clk_i  (clk_i),
          .rst_ni (rst_ni),
          .clr_i  (clr_i),
          .en_i   (eb_fu2_en),
          .data_i (EB_din_2),
          .valid_i(EB_din_2_v),
          .ready_o(din_2_r),
          .data_o (jm_din_2),
          .valid_o(jm_din_2_v),
          .ready_i(jm_din_2_r)
        );
      end else begin : gen_reg_2_deep
        elastic_fifo #(
          .DATA_WIDTH(DATA_WIDTH),
          .DEPTH     (DEEP_BUFFER_FU)
        ) REG_2 (
          .clk_i   (clk_i),
          .rst_ni  (rst_ni),
          .clr_i   (clr_i),
          .en_i    (eb_fu2_en),
          .din_i   (EB_din_2),
          .din_v_i (EB_din_2_v),
          .din_r_o (din_2_r),
          .dout_o  (jm_din_2),
          .dout_v_o(jm_din_2_v),
          .dout_r_i(jm_din_2_r)
        );
      end

      // ---- Control (cin) - generate only this path ----
      if (HAS_MUX) begin : gen_cin
        logic mux_c_cin;
        logic mux_c_cin_v;

        // Source: 0=N 1=E 2=S 3=W (bit[0] of each direction's buffer)
        mux #(
          .NUM_INPUTS(4),
          .DATA_WIDTH(1)
        ) MUX_C (
          .sel_i(mux_sel_c),
          .mux_i({west_buffer[0], south_buffer[0], east_buffer[0], north_buffer[0]}),
          .mux_o(mux_c_cin)
        );

        mux #(
          .NUM_INPUTS(4),
          .DATA_WIDTH(1)
        ) MUX_C_v (
          .sel_i(mux_sel_c),
          .mux_i({fs_w_v[3], fs_s_v[3], fs_e_v[3], fs_n_v[3]}),
          .mux_o(mux_c_cin_v)
        );

        if (DEEP_BUFFER_FU < 3) begin : gen_cin_eb
          // The control path always carries at least an elastic buffer (matching
          // REG_1/REG_2): a depth-2 skid provides the same storage as a depth-2
          // FIFO but is cheaper, absorbing an early-arriving control token.
          elastic_buffer #(
            .DATA_WIDTH(1)
          ) CIN_EB (
            .clk_i  (clk_i),
            .rst_ni (rst_ni),
            .clr_i  (clr_i),
            .en_i   (1'b1),
            .data_i (mux_c_cin),
            .valid_i(mux_c_cin_v),
            .ready_o(cin_r),
            .data_o (jm_cin),
            .valid_o(jm_cin_v),
            .ready_i(jm_cin_r)
          );
        end else begin : gen_cin_deep
          // 1-bit control FIFO: decouples the fork senders (cin_r, eager
          // while not full) from the join's actual consume ready (jm_cin_r),
          // absorbing an early-arriving control token cheaply (see
          // tmp_fifo_exploration.md section 3c/3d).
          elastic_fifo #(
            .DATA_WIDTH(1),
            .DEPTH     (DEEP_BUFFER_FU)
          ) CIN_FIFO (
            .clk_i   (clk_i),
            .rst_ni  (rst_ni),
            .clr_i   (clr_i),
            .en_i    (1'b1),
            .din_i   (mux_c_cin),
            .din_v_i (mux_c_cin_v),
            .din_r_o (cin_r),
            .dout_o  (jm_cin),
            .dout_v_o(jm_cin_v),
            .dout_r_i(jm_cin_r)
          );
        end
      end else begin : gen_no_cin
        assign jm_cin   = 1'b0;
        assign jm_cin_v = 1'b1;
        assign cin_r    = jm_cin_r;
      end

      // ---- Join/Merge ----
      join_merge #(
        .DATA_WIDTH(DATA_WIDTH)
      ) join_merge_inst (
        .mode_i       (jm_mode),
        .gate_active_i(gate_active),
        .gate_pol_i   (gate_pol),
        .din_1_i      (jm_din_1),
        .din_1_v_i    (jm_din_1_v),
        .din_1_r_o    (jm_din_1_r),
        .din_2_i      (jm_din_2),
        .din_2_v_i    (jm_din_2_v),
        .din_2_r_o    (jm_din_2_r),
        .cin_i        (jm_cin),
        .cin_v_i      (jm_cin_v),
        .cin_r_o      (jm_cin_r),
        .dout_1_o     (jm_dout_1),
        .dout_2_o     (jm_dout_2),
        .cout_o       (jm_cout),
        .out_v_o      (jm_dout_v),
        .out_r_i      (dout_r)
      );

      /* ------------------------------ FUNCTIONAL UNIT -------------------------- */

      functional_unit #(
        .DATA_WIDTH    (DATA_WIDTH),
        .N_DESTINATIONS(6),
        .HAS_ADDSUB    (HAS_ADDSUB),
        .HAS_MUL       (HAS_MUL),
        .HAS_SHIFT     (HAS_SHIFT),
        .HAS_LOGICAL   (HAS_LOGICAL),
        .HAS_CMP       (HAS_CMP),
        .HAS_MUX       (HAS_MUX),
        .EAGER_FORK    (EAGER_FORK)
      ) FU_inst (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .clr_i(clr_i),
        .initial_data_i(initial_data),
        .initial_valid_i(initial_valid),
        .feedback_i(feedback),
        .alu_sel_i(alu_sel),
        .cmp_sel_i(cmp_sel),
        .out_sel_i(out_sel),
        .delay_value_i(delay_value),
        .fork_mask_i(mask_fs_fu),
        .din_1_i(jm_dout_1),
        .din_2_i(jm_dout_2),
        .cin_i(jm_cout),
        .dout_o(dout),
        .in_v_i(jm_dout_v),
        .in_r_o(dout_r),
        .out_v_o(dout_v),
        .out_d_v_o(dout_d_v),
        .out_b1_v_o(dout_b1_v),
        .out_b2_v_o(dout_b2_v),
        .fork_v_o(fu_fork_v),
        .out_r_i({din_2_r, din_1_r, north_dout_r_i, east_dout_r_i, south_dout_r_i, west_dout_r_i})
      );
    end else begin : gen_no_fu
      // Routing-only tile: tie off every FU output the routing crossbar reads so the
      // output muxes degrade to pure N/E/S/W bypass and the fork senders never stall.
      assign dout      = '0;
      assign dout_v    = 1'b0;
      assign dout_d_v  = 1'b0;
      assign dout_b1_v = 1'b0;
      assign dout_b2_v = 1'b0;
      assign fu_fork_v = '0;
      assign jm_cin_r  = 1'b1;
      assign din_1_r   = 1'b1;
      assign din_2_r   = 1'b1;
      assign cin_r     = 1'b1;
    end
  endgenerate

endmodule
