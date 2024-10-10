// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module FU_control_superpolyvalent
    (
        // Clock and reset
        input  logic        clk_i,
        input  logic        rst_ni,
        input  logic        clr_i,

        // Configuration
        input  logic        initial_valid_i,
        input  logic [15:0] delay_value_i,
        input  logic [ 5:0] fork_mask_i,

        // Inputs from Join/Merge
        input  logic        cin_i,
        input  logic        in_v_i,
        output logic        in_r_o,

        // Valid signals
        output logic        out_v_o,
        output logic        out_d_v_o,
        output logic        out_b1_v_o,
        output logic        out_b2_v_o,

        // Ready signals
        input  logic        north_dout_r_i,
        input  logic        east_dout_r_i,
        input  logic        south_dout_r_i,
        input  logic        west_dout_r_i,
        input  logic        din_1_r_i,
        input  logic        din_2_r_i
    );
    // synopsys sync_set_reset clr_i

    logic v_reg, b1_v, b1_v_reg, b2_v, b2_v_reg, initial_load;
    logic [15:0] delay_count;

    // Valid path
    assign b1_v = cin_i ? 1'b0 : in_v_i;
    assign b2_v = cin_i ? in_v_i : 1'b0;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            v_reg <= 1'b0;
            b1_v_reg <= 1'b0;
            b2_v_reg <= 1'b0;
            initial_load <= 1'b0;
        end else begin
            if (clr_i) begin
                v_reg <= 1'b0;
                b1_v_reg <= 1'b0;
                b2_v_reg <= 1'b0;
                initial_load <= 1'b0;
            end else begin
                if (!initial_load) begin
                    v_reg <= initial_valid_i;
                    initial_load <= 1'b1;
                end else if (in_r_o) begin
                    v_reg <= in_v_i;
                    b1_v_reg <= b1_v;
                    b2_v_reg <= b2_v;
                end
            end
        end
    end

    assign out_v_o = v_reg & in_r_o;
    assign out_b1_v_o = b1_v_reg & in_r_o;
    assign out_b2_v_o = b2_v_reg & in_r_o;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            delay_count <= '0;
        end else begin
            if (clr_i) begin
                delay_count <= '0;
            end else begin
                if (out_v_o) begin
                    if (delay_count + 1 == delay_value_i) begin
                        delay_count <= '0;
                    end else begin
                        delay_count <= delay_count + 1;
                    end
                end
            end
        end
    end

    assign out_d_v_o = out_v_o & delay_count + 1 == delay_value_i;

    // Ready path
    fork_sender
    #(
        .NUM_READYS   (   6                                                                                     )
    )
    FS
    (
        .ready_in_o   (   in_r_o                                                                                ),
        .readys_out_i ( { din_2_r_i, din_1_r_i, north_dout_r_i, east_dout_r_i, south_dout_r_i, west_dout_r_i }  ),
        .fork_mask_i  (   fork_mask_i                                                                           )
    );

endmodule
