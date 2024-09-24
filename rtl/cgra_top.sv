// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module cgra_top
  import cgra_pkg::*;
  import obi_pkg::*;  
  import reg_pkg::*;
(
  // Clock and reset
  input  logic                  clk_i,
  input  logic                  rst_ni,

  // MMIO interface
  input  reg_req_t              reg_req_i,
  output reg_rsp_t              reg_rsp_o,

  // Master ports
  output obi_req_t  [NODES-1:0] masters_req_o,
  input  obi_resp_t [NODES-1:0] masters_resp_i,

  // Interrupt
  output logic                  int_o
);

  logic start, execute, clear_bs;
  logic [31:0] config_addr;
  logic [15:0] config_size;
  logic [31:0] input_addr [INPUT_NODES-1:0];
  logic [15:0] input_size [INPUT_NODES-1:0];
  logic [15:0] input_stride [INPUT_NODES-1:0];
  logic [31:0] output_addr [OUTPUT_NODES-1:0];
  logic [15:0] output_size [OUTPUT_NODES-1:0];

  logic clear, clear_core, bs_done, bs_needed, bs_enable;
  logic [OUTPUT_NODES-1:0]    omm_done;

  logic [32*INPUT_NODES-1:0]  din;
  logic [INPUT_NODES-1:0]     din_v, din_r;
  logic [32*OUTPUT_NODES-1:0] dout;
  logic [OUTPUT_NODES-1:0]    dout_v, dout_r;

  logic [159:0] kernel_config;
  genvar i;

  main_fsm_t state;

  assign int_o = &omm_done;

  // MMIO control registers
  mmio_interface mmio_interface_i
  (
    .clk_i,
    .rst_ni,
    .reg_rsp_o,
    .reg_req_i,
    .masters_resp_i,
    .masters_req_i  ( masters_req_o         ),
    .start_o        ( start                 ),
    .clr_conf_o     ( clear_bs              ),
    .exec_done_i    ( int_o                 ),
    .conf_done_i    ( bs_done               ),
    .state_i        ( state                 ),
    .conf_addr_o    ( config_addr           ),
    .conf_size_o    ( config_size           ),
    .imn_addr_o     ( input_addr            ),
    .imn_size_o     ( input_size            ),
    .imn_stride_o   ( input_stride          ),
    .omn_addr_o     ( output_addr           ),
    .omn_size_o     ( output_size           )
  );

  // Control unit
  control_unit control_unit_i
  (
    .clk_i          ( clk_i       ),
    .rst_ni         ( rst_ni      ),
    .clear_o        ( clear       ),
    .clear_core_o   ( clear_core  ),
    .start_i        ( start       ),
    .clear_bs_i     ( clear_bs    ),
    .change_bs_i    ( clear_bs    ),
    .bs_done_i      ( bs_done     ),
    .execute_done_i ( int_o       ),
    .execute_o      ( execute     ),
    .bs_needed_o    ( bs_needed   ),
    .state_o        ( state       )
  );

  // Config node
  config_memory_node config_memory_node_i
  (
    .clk_i           ( clk_i                    ),
    .rst_ni          ( rst_ni & clear           ),
    .masters_resp_i  ( masters_resp_i[NODES-1]  ),
    .masters_req_o   ( masters_req_o[NODES-1]   ),
    .execute_i       ( start                    ),
    .bs_needed_i     ( bs_needed                ),
    .bs_done_o       ( bs_done                  ),
    .config_addr_i   ( config_addr              ),
    .config_size_i   ( config_size              ),
    .kernel_config_o ( kernel_config            )
  );

  // Input nodes
  generate
    for(i = 0; i < INPUT_NODES; i++) begin : imm_gen
      input_memory_node input_memory_node_i
      (
        .clk_i          ( clk_i                 ),
        .rst_ni         ( rst_ni & clear        ),
        .execute_i      ( execute               ),
        .masters_resp_i ( masters_resp_i[i]     ),
        .masters_req_o  ( masters_req_o[i]      ),
        .input_addr_i   ( input_addr[i]         ),
        .input_size_i   ( input_size[i]         ),
        .input_stride_i ( input_stride[i]       ),
        .dout_o         ( din[32*(i+1)-1:32*i]  ),
        .dout_v_o       ( din_v[i]              ),
        .dout_r_i       ( din_r[i]              )
      );
    end
  endgenerate

  // Output nodes
  generate
    for(i = 0; i < INPUT_NODES; i++) begin : omm_gen
      output_memory_node output_memory_node_i
      (
        .clk_i          ( clk_i                           ),
        .rst_ni         ( rst_ni & clear                  ),
        .execute_i      ( execute                         ),
        .masters_resp_i ( masters_resp_i[INPUT_NODES + i] ),
        .masters_req_o  ( masters_req_o[INPUT_NODES + i]  ),
        .done_o         ( omm_done[i]                     ),
        .output_addr_i  ( output_addr[i]                  ),
        .output_size_i  ( output_size[i]                  ),
        .din_i          ( dout[32*(i+1)-1:32*i]           ),
        .din_v_i        ( dout_v[i]                       ),
        .din_r_o        ( dout_r[i]                       )
      );
    end
  endgenerate

  // CGRA
  assign bs_enable = (state == S_MAIN_WAIT);

  CGRA cgra_i
  (
    .clk                ( clk_i               ),
    .rst_n              ( rst_ni & clear_core ),
    .clk_bs             ( clk_i               ),
    .rst_n_bs           ( rst_ni & !clear_bs  ),
    .data_in            ( din                 ),
    .data_in_valid      ( din_v               ),
    .data_in_ready      ( din_r               ),
    .data_out           ( dout                ),
    .data_out_valid     ( dout_v              ),
    .data_out_ready     ( dout_r              ),
    .config_bitstream   ( kernel_config       ),
    .bitstream_enable_i ( bs_enable           ),
    .execute_i          ( execute             )
  );

endmodule
