// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module FU_control_superpolyvalent
    (
        input  logic        clk,
        input  logic        rst_n,
        input  logic        cin,
        input  logic        in_v,
        output logic        in_r,
        output logic        out_v,
        output logic        out_d_v,
        output logic        out_b1_v,
        output logic        out_b2_v,
        input  logic        north_dout_r,
        input  logic        east_dout_r,
        input  logic        south_dout_r,
        input  logic        west_dout_r,
        input  logic        din_1_r,
        input  logic        din_2_r,
        input  logic        initial_valid,
        input  logic [15:0] delay_value,
        input  logic [5:0]  fork_mask
    );

    logic v_reg, b1_v, b1_v_reg, b2_v, b2_v_reg, initial_load;
    logic [15:0] delay_count;

    // Valid path
    always_comb begin
        if(!cin) begin
            b1_v = in_v;
            b2_v = 1'b0;
        end else begin
            b1_v = 1'b0;
            b2_v = in_v;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            v_reg <= 1'b0;
            b1_v_reg <= 1'b0;
            b2_v_reg <= 1'b0;
            initial_load <= 1'b0;
        end else begin
            if(!initial_load) begin
                v_reg <= initial_valid;
                initial_load <= 1'b1;
            end else if(in_r) begin
                v_reg <= in_v;
                b1_v_reg <= b1_v;
                b2_v_reg <= b2_v;
            end
        end
    end

    assign out_v = v_reg & in_r;
    assign out_b1_v = b1_v_reg & in_r;
    assign out_b2_v = b2_v_reg & in_r;

    always_ff @(posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            delay_count <= '0;
        end else if(out_v) begin
            if (delay_count + 1 == delay_value) begin
                delay_count <= '0;
            end else begin
                delay_count <= delay_count + 1;
            end
        end
    end

    assign out_d_v = out_v & delay_count + 1 == delay_value;

    // Ready path
    fork_sender
    #(
        .NUM_READYS (   6                                                                           )
    )
    FS
    (
        .ready_in   (   in_r                                                                    ),
        .ready_out  ( { din_2_r, din_1_r, north_dout_r, east_dout_r, south_dout_r, west_dout_r }    ),
        .fork_mask  (   fork_mask                                                                   )
    );

endmodule
