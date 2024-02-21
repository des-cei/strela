// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module fork_sender 
    #(
        parameter int NUM_READYS = 2
    )
    (
        output logic                    ready_in,
        input  logic [NUM_READYS-1:0]   ready_out,
        input  logic [NUM_READYS-1:0]   fork_mask
    );

    logic [NUM_READYS-1:0]  aux, temp/*verilator split_var*/;

    for (genvar i = 0; i < NUM_READYS; i++) begin
        assign aux[i] = !fork_mask[i] || ready_out[i];
    end

    assign temp[0] = aux[0];
    
    for (genvar i = 0; i < NUM_READYS-1; i++) begin
        assign temp[i+1] = temp[i] && aux[i+1];
    end

    assign ready_in = temp[NUM_READYS-1];

endmodule
