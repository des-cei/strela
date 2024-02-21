// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module FF_rv 
    #(
        parameter int   DATA_WIDTH  = 32
    )
    (
        // Clock and reset
        input  logic                    clk,
        input  logic                    rst_n,
        input  logic                    enable,

        // Input data
        input  logic [DATA_WIDTH-1:0]   din,
        input  logic                    din_v,
        output logic                    din_r,

        // Ouput data
        output logic [DATA_WIDTH-1:0]   dout,
        output logic                    dout_v,
        input  logic                    dout_r
    );

    logic [DATA_WIDTH-1 : 0]    data_0, data_1;
    logic                       valid_0, valid_1;
    logic                       areg, vaux;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_0  <= '0;
            data_1  <= '0;
            valid_0 <= 1'b0;
            valid_1 <= 1'b0;
        end else if (enable && areg) begin
            data_0  <= din;
            data_1  <= data_0;
            valid_0 <= din_v;
            valid_1 <= valid_0;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            areg    <= 1'b0;
        end else if(enable) begin
            areg <= dout_r || !vaux;
        end
    end

    assign vaux = areg ? valid_0 : valid_1;
    assign dout = areg ? data_0  : data_1;
    assign dout_v   = vaux;
    assign din_r    = areg;

endmodule
