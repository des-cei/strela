// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module PC_superpolyvalent
    #(
        parameter int DATA_WIDTH = 32
    )
    (
        // Clock and reset
        input  logic                    clk,
        input  logic                    rst_n,

        // Input data
        input  logic [DATA_WIDTH-1:0]   north_din,
        input  logic                    north_din_v,
        input  logic [DATA_WIDTH-1:0]   east_din,
        input  logic                    east_din_v,
        input  logic [DATA_WIDTH-1:0]   south_din,
        input  logic                    south_din_v,
        input  logic [DATA_WIDTH-1:0]   west_din,
        input  logic                    west_din_v,
        output logic                    din_1_r,
        output logic                    din_2_r,
        output logic                    cin_r,

        // Output data
        output logic [DATA_WIDTH-1:0]   dout,
        output logic                    dout_v,
        output logic                    dout_d_v,
        output logic                    dout_b1_v,
        output logic                    dout_b2_v,
        input  logic                    north_dout_r,
        input  logic                    east_dout_r,
        input  logic                    south_dout_r,
        input  logic                    west_dout_r,

        // Configuration
        input  logic [107:0]            config_bits,
        input  logic [  1:0]            enables
    );

    // Config signals
    logic [2:0]             mux_sel_1, mux_sel_2;
    logic [1:0]             mux_sel_c;
    logic                   feedback;
    logic [3:0]             alu_sel;
    logic                   cmp_sel;
    logic [1:0]             out_sel;
    logic [5:0]             mask_fs;
    logic [1:0]             jm_mode;
    logic                   initial_valid;
    logic [DATA_WIDTH-1:0]  I1_const;
    logic [DATA_WIDTH-1:0]  initial_data;    
    logic [15:0]            delay_value;

    // Interconnect signals
    logic [DATA_WIDTH-1:0] EB_din_1, EB_din_2, jm_din_1, jm_din_2, jm_dout_1, jm_dout_2;
    logic EB_din_1_v, EB_din_2_v;
    logic jm_din_1_v, jm_din_1_r, jm_din_2_v, jm_din_2_r, jm_dout_v;
    logic jm_cin, jm_cin_v, jm_cout;
    logic dout_r;

    // Configuration decoding
    assign mux_sel_1        = config_bits[2:0];
    assign mux_sel_2        = config_bits[5:3];
    assign mux_sel_c        = config_bits[7:6];
    assign feedback         = config_bits[8];
    assign alu_sel          = config_bits[12:9];
    assign cmp_sel          = config_bits[13];
    assign out_sel          = config_bits[15:14];
    assign mask_fs          = config_bits[21:16];
    assign jm_mode          = config_bits[23:22];
    assign initial_valid    = config_bits[24];
    assign initial_data     = DATA_WIDTH'(signed'(config_bits[59:28]));
    assign I1_const         = DATA_WIDTH'(signed'(config_bits[91:60]));
    assign delay_value      = config_bits[107:92];
    
    // Data path 1
    mux
    #(
        .NUM_INPUTS (   6                                                           ),
        .DATA_WIDTH (   DATA_WIDTH                                                  )
    )
    MUX_1
    (
        .sel        (   mux_sel_1                                                   ),
        .mux_in     ( { dout, I1_const, west_din, south_din, east_din, north_din }  ),
        .mux_out    (   EB_din_1                                                    )
    );

    mux
    #(
        .NUM_INPUTS (   6                                                                   ),
        .DATA_WIDTH (   1                                                                   )
    )
    MUX_1_v
    (
        .sel        (   mux_sel_1                                                           ),
        .mux_in     ( { dout_v, 1'b1, west_din_v, south_din_v, east_din_v, north_din_v }    ),
        .mux_out    (   EB_din_1_v                                                          )
    );

    FF_rv
    #(
        .DATA_WIDTH ( DATA_WIDTH    )
    )
    REG_1
    (
        .clk        ( clk           ),
        .rst_n      ( rst_n         ),
        .enable     ( enables[0]    ),
        .din        ( EB_din_1      ),
        .din_v      ( EB_din_1_v    ),
        .din_r      ( din_1_r       ),
        .dout       ( jm_din_1      ),
        .dout_v     ( jm_din_1_v    ),
        .dout_r     ( jm_din_1_r    )
    );

    // Data path 2
    mux
    #(
        .NUM_INPUTS (   6                                                           ),
        .DATA_WIDTH (   DATA_WIDTH                                                  )
    )
    MUX_2
    (
        .sel        (   mux_sel_2                                                   ),
        .mux_in     ( { dout, I1_const, west_din, south_din, east_din, north_din }  ),
        .mux_out    (   EB_din_2                                                    )
    );

    mux
    #(
        .NUM_INPUTS (   6                                                           ),
        .DATA_WIDTH (   1                                                           )
    )
    MUX_2_v
    (
        .sel        (   mux_sel_2                                                           ),
        .mux_in     ( { dout_v, 1'b1, west_din_v, south_din_v, east_din_v, north_din_v }    ),
        .mux_out    (   EB_din_2_v                                                          )
    );

    FF_rv
    #(
        .DATA_WIDTH ( DATA_WIDTH )
    )
    REG_2
    (
        .clk        ( clk           ),
        .rst_n      ( rst_n         ),
        .enable     ( enables[0]    ),
        .din        ( EB_din_2      ),
        .din_v      ( EB_din_2_v    ),
        .din_r      ( din_2_r       ),
        .dout       ( jm_din_2      ),
        .dout_v     ( jm_din_2_v    ),
        .dout_r     ( jm_din_2_r    )
    );

    // Control path
    mux
    #(
        .NUM_INPUTS (   4                                                       ),
        .DATA_WIDTH (   1                                                       )
    )
    MUX_C
    (
        .sel        (   mux_sel_c                                               ),
        .mux_in     ( { west_din[0], south_din[0], east_din[0], north_din[0] }  ),
        .mux_out    (   jm_cin                                                )
    );

    mux
    #(
        .NUM_INPUTS (   4                                                   ),
        .DATA_WIDTH (   1                                                   )
    )
    MUX_C_v
    (
        .sel        (   mux_sel_c                                           ),
        .mux_in     ( { west_din_v, south_din_v, east_din_v, north_din_v }  ),
        .mux_out    (   jm_cin_v                                            )
    );

    // Data path out    
    join_merge
    #(
        .DATA_WIDTH     ( DATA_WIDTH    )
    )
    join_merge_inst
    (
        .din_1          ( jm_din_1      ),
        .din_1_v        ( jm_din_1_v    ),
        .din_1_r        ( jm_din_1_r    ),
        .din_2          ( jm_din_2      ),
        .din_2_v        ( jm_din_2_v    ),
        .din_2_r        ( jm_din_2_r    ),
        .cin            ( jm_cin        ),
        .cin_v          ( jm_cin_v      ),
        .cin_r          ( cin_r         ),
        .dout_1         ( jm_dout_1     ),
        .dout_2         ( jm_dout_2     ),
        .cout           ( jm_cout       ),
        .dout_v         ( jm_dout_v     ),
        .dout_r         ( dout_r        ),
        .mode           ( jm_mode       )
    );

    // Data path
    FU_data_superpolyvalent
    #(
        .DATA_WIDTH     ( DATA_WIDTH    )
    )
    FU_data
    (
        .clk            ( clk           ),
        .rst_n          ( rst_n         ),
        .enable         ( jm_dout_v && dout_r ),
        .din_1          ( jm_dout_1     ),
        .din_2          ( jm_dout_2     ),
        .cin            ( jm_cout       ),
        .dout           ( dout          ),
        .initial_data   ( initial_data  ),
        .feedback       ( feedback      ),
        .alu_sel        ( alu_sel       ),
        .cmp_sel        ( cmp_sel       ),
        .out_sel        ( out_sel       )
    );

    // Control path
    FU_control_superpolyvalent FU_control
    (
        .clk            ( clk           ),
        .rst_n          ( rst_n         ),
        .cin            ( jm_cout       ),
        .in_v           ( jm_dout_v     ),
        .in_r           ( dout_r        ),
        .out_v          ( dout_v        ),
        .out_d_v        ( dout_d_v      ),
        .out_b1_v       ( dout_b1_v     ),
        .out_b2_v       ( dout_b2_v     ),
        .din_1_r        ( din_1_r       ),
        .din_2_r        ( din_2_r       ),
        .east_dout_r    ( east_dout_r   ),
        .west_dout_r    ( west_dout_r   ),
        .north_dout_r   ( north_dout_r  ),
        .south_dout_r   ( south_dout_r  ),
        .initial_valid  ( initial_valid ),
        .delay_value    ( delay_value   ),
        .fork_mask      ( mask_fs       )
    );

endmodule
