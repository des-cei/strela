// Copyright 2026 CEIMM-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module fork_sender #(
  parameter int NUM_READYS = 2
) (
  // Configuration
  input logic [NUM_READYS-1:0] fork_mask_i,

  // Ready signals
  output logic                  ready_in_o,
  input  logic [NUM_READYS-1:0] readys_out_i
);

  logic [NUM_READYS-1:0] aux, temp  /*verilator split_var*/;

  for (genvar i = 0; i < NUM_READYS; i++) begin : gen_aux
    assign aux[i] = !fork_mask_i[i] || readys_out_i[i];
  end : gen_aux

  assign temp[0] = aux[0];

  for (genvar i = 0; i < NUM_READYS - 1; i++) begin : gen_temp
    assign temp[i+1] = temp[i] && aux[i+1];
  end : gen_temp

  assign ready_in_o = temp[NUM_READYS-1];

endmodule
