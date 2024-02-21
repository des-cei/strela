// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module FU_data_superpolyvalent
    #(
        parameter int DATA_WIDTH = 32
    )
    (
        input  logic                        clk,
        input  logic                        rst_n,
        input  logic                        enable,
        input  logic [DATA_WIDTH-1:0]       din_1,
        input  logic [DATA_WIDTH-1:0]       din_2,
        input  logic                        cin,
        output logic [DATA_WIDTH-1:0]       dout,
        input  logic [DATA_WIDTH-1:0]       initial_data,
        input  logic                        feedback,
        input  logic [3:0]                  alu_sel,
        input  logic                        cmp_sel,
        input  logic [1:0]                  out_sel 
    );

    localparam logic [DATA_WIDTH-2:0] ZEROS = '0; 

    logic [DATA_WIDTH-1:0]  alu_din_2, alu_dout, mux_dout, cmp_dout, pre_dout;
    logic cmp_eq, cmp_gr, initial_load;

    // ALU
    always_comb begin
        if(!feedback) begin
            alu_din_2 = din_2;
        end else begin
            alu_din_2 = dout;
        end
    end

    always_comb begin
        case (alu_sel)
            0 : alu_dout = din_1 + alu_din_2;
            1 : alu_dout = din_1 * alu_din_2;
            2 : alu_dout = din_1 - alu_din_2;
            3 : alu_dout = din_1 << alu_din_2;
            4 : alu_dout = din_1 >> alu_din_2;
            5 : alu_dout = din_1 >>> alu_din_2;
            6 : alu_dout = din_1 & alu_din_2;
            7 : alu_dout = din_1 | alu_din_2;
            8 : alu_dout = din_1 ^ alu_din_2;
            default : alu_dout = din_1 + alu_din_2;
        endcase
    end

    // Comparator
    assign cmp_eq = (alu_dout == 0);
    assign cmp_gr = ($signed(alu_dout) > 0);

    always_comb begin
        case (cmp_sel)
            0: cmp_dout = { ZEROS, cmp_eq };
            1: cmp_dout = { ZEROS, cmp_gr };
            default : cmp_dout = { ZEROS, cmp_eq };          
        endcase
    end

    // Mux
    assign mux_dout = cin ? din_2 : din_1;

    // Output selection
    always_comb begin
        case (out_sel)
            0: pre_dout = alu_dout;
            1: pre_dout = cmp_dout;
            2: pre_dout = mux_dout;
            default : pre_dout = alu_dout;           
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            dout <= '0;
            initial_load <= 1'b0;
        end else  begin
            if(!initial_load) begin
                dout <= initial_data;
                initial_load <= 1'b1;
            end else if(enable) begin
                dout <= pre_dout;
            end
        end
    end

endmodule
