// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module join_merge
    #(
        parameter int DATA_WIDTH = 32
    )
    (
        // Configuration
        input  logic [1:0]              mode_i,   

        // Input data and control
        input  logic [DATA_WIDTH-1:0]   din_1_i,
        input  logic                    din_1_v_i,
        output logic                    din_1_r_o,
        input  logic [DATA_WIDTH-1:0]   din_2_i,
        input  logic                    din_2_v_i,
        output logic                    din_2_r_o,
        input  logic                    cin_i,
        input  logic                    cin_v_i,
        output logic                    cin_r_o,

        // Output data and control
        output logic [DATA_WIDTH-1:0]   dout_1_o,
        output logic [DATA_WIDTH-1:0]   dout_2_o,
        output logic                    cout_o,
        output logic                    out_v_o,
        input  logic                    out_r_i
    );

    always_comb begin
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
                // Merge mode
                out_v_o = din_1_v_i | din_2_v_i;
                din_1_r_o = out_r_i;
                din_2_r_o = out_r_i;
                cin_r_o = 1'b0;
                cout_o = !din_1_v_i;
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

    assign dout_1_o = din_1_i;
    assign dout_2_o = din_2_i;

endmodule
