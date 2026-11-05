// Copyright 2026 CEIMM-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module elastic_buffer #(
  parameter int DATA_WIDTH = 32
) (
  // Clock and reset
  input logic clk_i,
  input logic rst_ni,
  input logic clr_i,

  // Control
  input logic en_i,

  // Input data
  input  logic [DATA_WIDTH-1:0] data_i,
  input  logic                  valid_i,
  output logic                  ready_o,

  // Output data
  output logic [DATA_WIDTH-1:0] data_o,
  output logic                  valid_o,
  input  logic                  ready_i
);
  // synopsys sync_set_reset clr_i

  logic [DATA_WIDTH-1 : 0] data_0, data_1;
  logic valid_0, valid_1;
  logic areg, vaux;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      data_0  <= '0;
      data_1  <= '0;
      valid_0 <= 1'b0;
      valid_1 <= 1'b0;
    end else begin
      if (clr_i) begin
        data_0  <= '0;
        data_1  <= '0;
        valid_0 <= 1'b0;
        valid_1 <= 1'b0;
      end else if (en_i && areg) begin
        data_0  <= data_i;
        data_1  <= data_0;
        valid_0 <= valid_i;
        valid_1 <= valid_0;
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      areg <= 1'b0;
    end else begin
      if (clr_i) begin
        areg <= 1'b0;
      end else if (en_i) begin
        areg <= ready_i || !vaux;
      end
    end
  end

  assign vaux = areg ? valid_0 : valid_1;
  assign data_o = areg ? data_0 : data_1;
  assign valid_o = vaux;
  assign ready_o = areg;

endmodule
