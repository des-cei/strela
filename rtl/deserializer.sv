// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module deserializer
  import cgra_pkg::*;
(
  // Clock and reset
  input  logic          clk_i,
  input  logic          rst_ni,
  // Input data and control
  input  logic [31:0]   data_i,
  input  logic          enable_i,
  // Output data
  output logic [159:0]  kernel_config_o
);

  logic [4:0][31:0] registers;
  logic [2:0] counter;

  // Counter and output
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if(~rst_ni) begin
      counter <= '0;
    end else if(enable_i) begin
      if(counter == 4) begin
        counter <= '0;
      end else begin
        counter <= counter + 1;
      end
    end
  end 

  // Shift registers
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if(~rst_ni) begin
      registers <= '{default: '0};
    end else if(enable_i) begin
      registers[4] <= data_i;
      registers[3] <= registers[4];
      registers[2] <= registers[3];
      registers[1] <= registers[2];
      registers[0] <= registers[1];
    end
  end

  assign kernel_config_o = (counter == 0) ? {registers} : '0;

endmodule
