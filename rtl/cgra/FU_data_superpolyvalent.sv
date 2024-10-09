// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module FU_data_superpolyvalent
    #(
        parameter int DATA_WIDTH = 32
    )
    (
        // Clock and reset
        input  logic                        clk_i,
        input  logic                        rst_ni,

        // Control
        input  logic                        en_i,

        // Configuration
        input  logic [DATA_WIDTH-1:0]       initial_data_i,
        input  logic                        feedback_i,
        input  logic [3:0]                  alu_sel_i,
        input  logic                        cmp_sel_i,
        input  logic [1:0]                  out_sel_i,

        // Data and control inputs
        input  logic [DATA_WIDTH-1:0]       din_1_i,
        input  logic [DATA_WIDTH-1:0]       din_2_i,
        input  logic                        cin_i,

        // Data and control output
        output logic [DATA_WIDTH-1:0]       dout_o
    );

    localparam logic [DATA_WIDTH-2:0] ZEROS = '0; 

    logic [DATA_WIDTH-1:0]  alu_din_2, alu_dout, mux_dout, cmp_dout, pre_dout;
    logic cmp_eq, cmp_gr, initial_load;

    // ALU
    assign alu_din_2 = feedback_i ? dout_o : din_2_i;

    always_comb begin
        case (alu_sel_i)
            0 : alu_dout = din_1_i + alu_din_2;
            1 : alu_dout = din_1_i * alu_din_2;
            2 : alu_dout = din_1_i - alu_din_2;
            3 : alu_dout = din_1_i << alu_din_2;
            4 : alu_dout = din_1_i >> alu_din_2;
            5 : alu_dout = din_1_i >>> alu_din_2;
            6 : alu_dout = din_1_i & alu_din_2;
            7 : alu_dout = din_1_i | alu_din_2;
            8 : alu_dout = din_1_i ^ alu_din_2;
            default : alu_dout = din_1_i + alu_din_2;
        endcase
    end

    // Comparator
    assign cmp_eq = (alu_dout == 0);
    assign cmp_gr = ($signed(alu_dout) > 0);

    always_comb begin
        case (cmp_sel_i)
            0: cmp_dout = { ZEROS, cmp_eq };
            1: cmp_dout = { ZEROS, cmp_gr };
            default : cmp_dout = { ZEROS, cmp_eq };          
        endcase
    end

    // Mux
    assign mux_dout = cin_i ? din_2_i : din_1_i;

    // Output selection
    always_comb begin
        case (out_sel_i)
            0: pre_dout = alu_dout;
            1: pre_dout = cmp_dout;
            2: pre_dout = mux_dout;
            default : pre_dout = alu_dout;           
        endcase
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if(!rst_ni) begin
            dout_o <= '0;
            initial_load <= 1'b0;
        end else begin
            if(!initial_load) begin
                dout_o <= initial_data_i;
                initial_load <= 1'b1;
            end else if(en_i) begin
                dout_o <= pre_dout;
            end
        end
    end

endmodule
