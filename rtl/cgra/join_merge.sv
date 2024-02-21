// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module join_merge
    #(
        parameter int DATA_WIDTH = 32
    )
    (
        input  logic [DATA_WIDTH-1:0]   din_1,
        input  logic                    din_1_v,
        output logic                    din_1_r,
        input  logic [DATA_WIDTH-1:0]   din_2,
        input  logic                    din_2_v,
        output logic                    din_2_r,
        input  logic                    cin,
        input  logic                    cin_v,
        output logic                    cin_r,
        output logic [DATA_WIDTH-1:0]   dout_1,
        output logic [DATA_WIDTH-1:0]   dout_2,
        output logic                    cout,
        output logic                    dout_v,
        input  logic                    dout_r,
        input  logic [1:0]              mode   
    );

    always_comb begin
        case (mode)
            2'b00: begin
                // Join mode without control
                dout_v = din_1_v & din_2_v;
                din_1_r = dout_r & din_2_v;
                din_2_r = dout_r & din_1_v;
                cin_r = 1'b0;
                cout = cin;
            end
            2'b01: begin
                // Join mode with control
                dout_v = din_1_v & din_2_v & cin_v;
                din_1_r = dout_r & din_2_v & cin_v;
                din_2_r = dout_r & din_1_v & cin_v;
                cin_r = dout_r & din_1_v & din_2_v;
                cout = cin;
            end

            2'b10: begin
                // Merge mode
                dout_v = din_1_v | din_2_v;
                din_1_r = dout_r;
                din_2_r = dout_r;
                cin_r = 1'b0;
                cout = !din_1_v;
            end
            default: begin
                // Join mode without control
                dout_v = din_1_v & din_2_v;
                din_1_r = dout_r & din_2_v;
                din_2_r = dout_r & din_1_v;
                cin_r = 1'b0;
                cout = cin;
            end
        endcase
    end

    assign dout_1 = din_1;
    assign dout_2 = din_2;

endmodule
