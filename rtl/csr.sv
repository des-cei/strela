// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module csr
  import cgra_pkg::*;
  import reg_pkg::*;
(
  // Clock and reset
  input  logic        clk_i,
  input  logic        rst_ni,

  // MMIO interface
  input  reg_req_t    reg_req_i,
  output reg_rsp_t    reg_rsp_o,

  // Control
  input logic         execute_i,

  // Configuration outputs
  output logic        start_o,
  output logic        clear_bs_o,
  output logic        change_bs_o,
  output logic [31:0] config_addr_o,
  output logic [15:0] config_size_o,
  output logic [31:0] input_addr_o   [ INPUT_NODES-1:0],
  output logic [15:0] input_size_o   [ INPUT_NODES-1:0],
  output logic [15:0] input_stride_o [ INPUT_NODES-1:0],
  output logic [31:0] output_addr_o  [OUTPUT_NODES-1:0],
  output logic [15:0] output_size_o  [OUTPUT_NODES-1:0],

  // Performance counters
  input  logic [31:0] bs_cycles_i,
  input  logic [31:0] exec_cycles_i,
  input  logic [31:0] stall_cycles_i
);

  logic [31:0] data;
  logic [ 7:0] addr;
  logic        we;

  assign data = reg_req_i.wdata;
  assign addr = reg_req_i.addr[7:0];
  assign we   = reg_req_i.valid & reg_req_i.write & !execute_i;

  assign reg_rsp_o.ready = 1'b1;
  assign reg_rsp_o.error = 1'b0;
//  assign reg_rsp_o.rdata = '0;

  always_comb
  begin
    reg_rsp_o.rdata = '0;
    if(addr == CTR_BS_REG_ADDR) begin
      reg_rsp_o.rdata = bs_cycles_i;
    end else if(addr == CTR_EXEC_REG_ADDR) begin
      reg_rsp_o.rdata = exec_cycles_i;
    end else if(addr == CTR_STALL_REG_ADDR) begin
      reg_rsp_o.rdata = stall_cycles_i;
    end
  end

  logic [31:0] registers [CONFIG_REG_N-1:0];

  // Control and configuration registers
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if(~rst_ni) begin
      registers[0] <= '0;
      registers[1] <= '0;
      registers[2] <= '0;
      registers[3] <= 32'h2;
    end else begin
      registers[0] <= '0;

      if(we) begin
        if(addr == CONTROL_REG_ADDR) begin
          registers[0] <= data; 
        end
        if(addr == CONFIG_ADDR_ADDR) begin
          registers[1] <= data; 
        end
        if(addr == CONFIG_SIZE_ADDR) begin
          registers[2] <= data; 
        end
        if(addr == SEW_ADDR) begin
          registers[3] <= data; 
        end
      end
    end
  end

  assign start_o        = registers[0][0];
  assign clear_bs_o     = registers[0][1];
  assign change_bs_o    = registers[0][2];
  assign config_addr_o  = registers[1];
  assign config_size_o  = registers[2][15:0];

  // Input registers
  generate
    for(genvar i = 0; i < 2 * INPUT_NODES; i++) begin : input_reg_gen
      always_ff @(posedge clk_i or negedge rst_ni) begin
        if(~rst_ni) begin
          registers[4 + i] <= '0;
        end else begin
          if(we) begin
            if(addr == INPUT_REGS_BASE_ADDR + (4 * i)) begin
              registers[4 + i] <= data; 
            end
          end
        end
      end
    end

    for(genvar m = 0; m < INPUT_NODES; m++) begin : input_reg_assign_gen
      assign input_addr_o[m]    = registers[4 + (2 * m)];
      assign input_size_o[m]    = registers[5 + (2 * m)][ 15:0];
      assign input_stride_o[m]  = registers[5 + (2 * m)][31:16];
    end
  endgenerate

  // Output registers
  generate
    for(genvar j = 0; j < 2 * OUTPUT_NODES; j++) begin : output_reg_gen
      always_ff @(posedge clk_i or negedge rst_ni) begin
        if(~rst_ni) begin
          registers[4 + 2 * INPUT_NODES + j] <= '0;
        end else begin
          if(we) begin
            if(addr == OUTPUT_REGS_BASE_ADDR + (4 * j)) begin
              registers[4 + 2 * INPUT_NODES + j] <= data; 
            end
          end
        end
      end
    end

    for(genvar n = 0; n < INPUT_NODES; n++) begin : output_reg_assign_gen
      assign output_addr_o[n]    = registers[4 + 2 * INPUT_NODES + (2 * n)];
      assign output_size_o[n]    = registers[5 + 2 * INPUT_NODES + (2 * n)][15:0];
    end
  endgenerate

endmodule
