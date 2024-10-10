// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module elastic_buffer 
    #(
        parameter int   DATA_WIDTH  = 32
    )
    (
        // Clock and reset
        input  logic                    clk_i,
        input  logic                    rst_ni,
        input  logic                    clr_i,

        // Control
        input  logic                    en_i,

        // Input data
        input  logic [DATA_WIDTH-1:0]   din_i,
        input  logic                    din_v_i,
        output logic                    din_r_o,

        // Output data
        output logic [DATA_WIDTH-1:0]   dout_o,
        output logic                    dout_v_o,
        input  logic                    dout_r_i
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
                data_0  <= din_i;
                data_1  <= data_0;
                valid_0 <= din_v_i;
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
                areg <= dout_r_i || !vaux;
            end
        end
    end

    assign vaux = areg ? valid_0 : valid_1;
    assign dout_o = areg ? data_0 : data_1;
    assign dout_v_o = vaux;
    assign din_r_o = areg;

endmodule
