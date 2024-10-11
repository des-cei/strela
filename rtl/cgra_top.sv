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
  output logic                  intr_o
);

  logic start, exec, clr_mn, clr_cgra;
  logic [31:0] conf_addr;
  logic [31:0] input_addr [INPUT_NODES-1:0];
  logic [15:0] input_size [INPUT_NODES-1:0];
  logic [15:0] input_stride [INPUT_NODES-1:0];
  logic [31:0] omn_addr [OUTPUT_NODES-1:0];
  logic [15:0] omn_size [OUTPUT_NODES-1:0];

  logic conf_needed, conf_change;
  logic [INPUT_NODES-1:0] conf_done;
  logic [NODES-1:0] mn_done;

  logic [32*INPUT_NODES-1:0] din;
  logic [INPUT_NODES-1:0] din_v, din_r;
  logic [32*OUTPUT_NODES-1:0] dout;
  logic [OUTPUT_NODES-1:0] dout_v, dout_r;
  logic [3:0] conf_en;

  genvar i;
  main_fsm_t state;

  // MMIO control registers
  mmio_interface mmio_interface_i
  (
    .clk_i,
    .rst_ni,
    .reg_rsp_o,
    .reg_req_i,
    .masters_resp_i,
    .masters_req_i  ( masters_req_o ),
    .start_o        ( start         ),
    .conf_change_o  ( conf_change   ),
    .conf_done_i    ( &conf_done    ),
    .exec_done_i    ( &mn_done      ),
    .state_i        ( state         ),
    .conf_addr_o    ( conf_addr     ),
    .imn_addr_o     ( input_addr    ),
    .imn_size_o     ( input_size    ),
    .imn_stride_o   ( input_stride  ),
    .omn_addr_o     ( omn_addr      ),
    .omn_size_o     ( omn_size      )
  );

  // Control unit
  control_unit control_unit_i
  (
    .clk_i,
    .rst_ni,
    .start_i        ( start       ),
    .conf_change_i  ( conf_change ),
    .conf_done_i    ( &conf_done  ),
    .mn_done_i      ( &mn_done    ),
    .clr_mn_o       ( clr_mn      ),
    .clr_cgra_o     ( clr_cgra    ),
    .conf_needed_o  ( conf_needed ),
    .exec_o         ( exec        ),
    .intr_o,
    .state_o        ( state       )
  );

  // Input Memory Nodes
  generate
    for(i = 0; i < INPUT_NODES; i++) begin : imn_gen
      input_memory_node input_memory_node_i
      (
        .clk_i,
        .rst_ni,
        .clr_i          ( clr_mn                      ),
        .masters_resp_i ( masters_resp_i[i]           ),
        .masters_req_o  ( masters_req_o[i]            ),
        .start_i        ( start                       ),
        .exec_i         ( exec                        ),
        .conf_needed_i  ( conf_needed                 ),
        .conf_addr_i    ( conf_addr + CONF_OFFSET[i]  ),
        .input_addr_i   ( input_addr[i]               ),
        .input_size_i   ( input_size[i]               ),
        .input_stride_i ( input_stride[i]             ),
        .conf_done_o    ( conf_done[i]                ),
        .done_o         ( mn_done[i]                  ),
        .conf_en_o      ( conf_en[i]                  ),
        .dout_o         ( din[32*(i+1)-1:32*i]        ),
        .dout_v_o       ( din_v[i]                    ),
        .dout_r_i       ( din_r[i]                    )
      );
    end
  endgenerate

  // Output Memory Nodes
  generate
    for(i = 0; i < INPUT_NODES; i++) begin : omn_gen
      output_memory_node output_memory_node_i
      (
        .clk_i,
        .rst_ni,
        .clr_i          ( clr_mn                          ),
        .masters_resp_i ( masters_resp_i[INPUT_NODES + i] ),
        .masters_req_o  ( masters_req_o[ INPUT_NODES + i] ),
        .omn_addr_i     ( omn_addr[i]                     ),
        .omn_size_i     ( omn_size[i]                     ),
        .exec_i         ( exec                            ),
        .done_o         ( mn_done[INPUT_NODES + i]        ),
        .din_i          ( dout[32*(i+1)-1:32*i]           ),
        .din_v_i        ( dout_v[i]                       ),
        .din_r_o        ( dout_r[i]                       )
      );
    end
  endgenerate

  // CGRA
  CGRA cgra_i
  (
    .clk_i,
    .rst_ni,
    .clr_i          ( clr_cgra  ),
    .conf_en_i      ( conf_en   ),
    .data_in        ( din       ),
    .data_in_valid  ( din_v     ),
    .data_in_ready  ( din_r     ),
    .data_out       ( dout      ),
    .data_out_valid ( dout_v    ),
    .data_out_ready ( dout_r    )
  );

endmodule
