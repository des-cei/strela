// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module PE_superpolyvalent
    #(
        parameter int DATA_WIDTH = 32
    )
    (
        // Clock and reset
        input  logic                    clk,
        input  logic                    clk_bs,
        input  logic                    rst_n,
        input  logic                    rst_n_bs,

        // Input data
        input  logic [DATA_WIDTH-1:0]   north_din,
        input  logic                    north_din_v,
        output logic                    north_din_r,
        input  logic [DATA_WIDTH-1:0]   east_din,
        input  logic                    east_din_v,
        output logic                    east_din_r,
        input  logic [DATA_WIDTH-1:0]   south_din,
        input  logic                    south_din_v,
        output logic                    south_din_r,
        input  logic [DATA_WIDTH-1:0]   west_din,
        input  logic                    west_din_v,
        output logic                    west_din_r,

        // Output data
        output logic [DATA_WIDTH-1:0]   north_dout,
        output logic                    north_dout_v,
        input  logic                    north_dout_r,
        output logic [DATA_WIDTH-1:0]   east_dout,
        output logic                    east_dout_v,
        input  logic                    east_dout_r,
        output logic [DATA_WIDTH-1:0]   south_dout,
        output logic                    south_dout_v,
        input  logic                    south_dout_r,
        output logic [DATA_WIDTH-1:0]   west_dout,
        output logic                    west_dout_v,
        input  logic                    west_dout_r,

        // Configuration
        input  logic [143:0]            config_bits,
        input  logic [5:0]              config_enables,
        input  logic                    catch_config
    );

    // Config signals
    logic [2:0]     mux_sel_n, mux_sel_e, mux_sel_s, mux_sel_w;
    logic [1:0]     data_mux_sel_n, data_mux_sel_e, data_mux_sel_s, data_mux_sel_w;
    logic [5:0]     mask_fs_n, mask_fs_e, mask_fs_s, mask_fs_w;
    logic [143:0]   config_reg;
    logic [5:0]     enables_reg;

    // Interconnect signals
    // Buffer
    logic [DATA_WIDTH-1:0]  north_buffer, east_buffer, south_buffer, west_buffer;
    logic                   north_buffer_v, east_buffer_v, south_buffer_v, west_buffer_v;
    logic                   temp_north_buffer_v, temp_east_buffer_v, temp_south_buffer_v, temp_west_buffer_v;
    logic                   north_buffer_r, east_buffer_r, south_buffer_r, west_buffer_r;
    // Processing cell
    logic                   din_1_r, din_2_r, cin_r;
    logic [DATA_WIDTH-1:0]  dout;
    logic                   dout_v, dout_d_v, dout_b1_v, dout_b2_v;

    // Configuration register
    always_ff @(posedge clk_bs or negedge rst_n_bs) begin
        if(!rst_n_bs) begin
            config_reg <= 0;
            enables_reg <= 0;
        end else if(catch_config) begin
            config_reg <= config_bits;
            enables_reg <= config_enables;
        end
    end

    // Configuration decoding
    assign mask_fs_n = config_reg[5:0];
    assign mask_fs_e = config_reg[11:6];
    assign mask_fs_s = config_reg[17:12];
    assign mask_fs_w = config_reg[23:18];
    assign mux_sel_n = config_reg[26:24];
    assign mux_sel_e = config_reg[29:27];
    assign mux_sel_s = config_reg[32:30];
    assign mux_sel_w = config_reg[35:33];

    /* ------------------------------ NORTH NODE ------------------------------- */

    // Input
    FF_rv
    #(
        .DATA_WIDTH ( DATA_WIDTH            )
    )
    REG_N
    (
        .clk        ( clk                   ),
        .rst_n      ( rst_n                 ),
        .enable     ( enables_reg[0]        ),
        .din        ( north_din             ),
        .din_v      ( north_din_v           ),
        .din_r      ( north_din_r           ),
        .dout       ( north_buffer          ),
        .dout_v     ( temp_north_buffer_v   ),
        .dout_r     ( north_buffer_r        )
    );

    assign north_buffer_v = temp_north_buffer_v && north_buffer_r;

    fork_sender
    #(
        .NUM_READYS (   6                                                                   )
    )
    FS_N
    (
        .ready_in   (   north_buffer_r                                                      ),
        .ready_out  ( { din_1_r, din_2_r, cin_r, east_dout_r, south_dout_r, west_dout_r }   ),
        .fork_mask  (   mask_fs_n                                                           )
    );

    // Output
    assign data_mux_sel_n = mux_sel_n[2] == 1'b0 ? mux_sel_n[1:0] : 2'b11;

    mux
    #(
        .NUM_INPUTS (   4                                               ),
        .DATA_WIDTH (   DATA_WIDTH                                      )
    )
    MUX_N
    (
        .sel        (   data_mux_sel_n                                  ),
        .mux_in     ( { dout, west_buffer, south_buffer, east_buffer }  ),
        .mux_out    (   north_dout                                      )
    );

    mux
    #(
        .NUM_INPUTS (   7                                                                                       ),
        .DATA_WIDTH (   1                                                                                       )
    )
    MUX_N_v
    (
        .sel        (   mux_sel_n                                                                               ),
        .mux_in     ( { dout_b2_v, dout_b1_v, dout_d_v, dout_v, west_buffer_v, south_buffer_v, east_buffer_v }  ),
        .mux_out    (   north_dout_v                                                                            )
    );

    /* ------------------------------ NORTH NODE ------------------------------- */

    /* ------------------------------ EAST  NODE ------------------------------- */

    // Input
    FF_rv
    #(
        .DATA_WIDTH ( DATA_WIDTH            )
    )
    REG_E
    (
        .clk        ( clk                   ),
        .rst_n      ( rst_n                 ),
        .enable     ( enables_reg[1]        ),
        .din        ( east_din              ),
        .din_v      ( east_din_v            ),
        .din_r      ( east_din_r            ),
        .dout       ( east_buffer           ),
        .dout_v     ( temp_east_buffer_v    ),
        .dout_r     ( east_buffer_r         )
    );

    assign east_buffer_v = temp_east_buffer_v && east_buffer_r;

    fork_sender
    #(
        .NUM_READYS (   6                                                                   )
    )
    FS_E
    (
        .ready_in   (   east_buffer_r                                                       ),
        .ready_out  ( { din_1_r, din_2_r, cin_r, north_dout_r, south_dout_r, west_dout_r }  ),
        .fork_mask  (   mask_fs_e                                                           )
    );

    // Output
    assign data_mux_sel_e = mux_sel_e[2] == 1'b0 ? mux_sel_e[1:0] : 2'b11;

    mux
    #(
        .NUM_INPUTS (   4                                               ),
        .DATA_WIDTH (   DATA_WIDTH                                      )
    )
    MUX_E
    (
        .sel        (   data_mux_sel_e                                  ),
        .mux_in     ( { dout, west_buffer, south_buffer, north_buffer } ),
        .mux_out    (   east_dout                                       )
    );

    mux
    #(
        .NUM_INPUTS (   7                                                                                       ),
        .DATA_WIDTH (   1                                                                                       )
    )
    MUX_E_v
    (
        .sel        (   mux_sel_e                                                                               ),
        .mux_in     ( { dout_b2_v, dout_b1_v, dout_d_v, dout_v, west_buffer_v, south_buffer_v, north_buffer_v } ),
        .mux_out    (   east_dout_v                                                                             )
    );

    /* ------------------------------ EAST  NODE ------------------------------- */

    /* ------------------------------ SOUTH NODE ------------------------------- */

    // Input
    FF_rv
    #(
        .DATA_WIDTH ( DATA_WIDTH            )
    )
    REG_S
    (
        .clk        ( clk                   ),
        .rst_n      ( rst_n                 ),
        .enable     ( enables_reg[2]        ),
        .din        ( south_din             ),
        .din_v      ( south_din_v           ),
        .din_r      ( south_din_r           ),
        .dout       ( south_buffer          ),
        .dout_v     ( temp_south_buffer_v   ),
        .dout_r     ( south_buffer_r        )
    );

    assign south_buffer_v = temp_south_buffer_v && south_buffer_r;

    fork_sender
    #(
        .NUM_READYS (   6                                                                   )
    )
    FS_S
    (
        .ready_in   (   south_buffer_r                                                      ),
        .ready_out  ( { din_1_r, din_2_r, cin_r, north_dout_r, east_dout_r, west_dout_r }   ),
        .fork_mask  (   mask_fs_s                                                           )
    );

    // Output
    assign data_mux_sel_s = mux_sel_s[2] == 1'b0 ? mux_sel_s[1:0] : 2'b11;

    mux
    #(
        .NUM_INPUTS (   4                                               ),
        .DATA_WIDTH (   DATA_WIDTH                                      )
    )
    MUX_S
    (
        .sel        (   data_mux_sel_s                                  ),
        .mux_in     ( { dout, west_buffer, east_buffer, north_buffer }  ),
        .mux_out    (   south_dout                                      )
    );

    mux
    #(
        .NUM_INPUTS (   7                                                                                       ),
        .DATA_WIDTH (   1                                                                                       )
    )
    MUX_S_v
    (
        .sel        (   mux_sel_s                                                                               ),
        .mux_in     ( { dout_b2_v, dout_b1_v, dout_d_v, dout_v, west_buffer_v, east_buffer_v, north_buffer_v }  ),
        .mux_out    (   south_dout_v                                                                            )
    );

    /* ------------------------------ SOUTH NODE ------------------------------- */

    /* ------------------------------ WEST  NODE ------------------------------- */

    // Input
    FF_rv
    #(
        .DATA_WIDTH ( DATA_WIDTH    )
    )
    REG_W
    (
        .clk        ( clk                   ),
        .rst_n      ( rst_n                 ),
        .enable     ( enables_reg[3]        ),
        .din        ( west_din              ),
        .din_v      ( west_din_v            ),
        .din_r      ( west_din_r            ),
        .dout       ( west_buffer           ),
        .dout_v     ( temp_west_buffer_v    ),
        .dout_r     ( west_buffer_r         )
    );

    assign west_buffer_v = temp_west_buffer_v && west_buffer_r;

    fork_sender
    #(
        .NUM_READYS (   6                                                                   )
    )
    FS_W
    (
        .ready_in   (   west_buffer_r                                                       ),
        .ready_out  ( { din_1_r, din_2_r, cin_r, north_dout_r, east_dout_r, south_dout_r }  ),
        .fork_mask  (   mask_fs_w                                                           )
    );

    // Output
    assign data_mux_sel_w = mux_sel_w[2] == 1'b0 ? mux_sel_w[1:0] : 2'b11;

    mux
    #(
        .NUM_INPUTS (   4                                               ),
        .DATA_WIDTH (   DATA_WIDTH                                      )
    )
    MUX_W
    (
        .sel        (   data_mux_sel_w                                  ),
        .mux_in     ( { dout, south_buffer, east_buffer, north_buffer } ),
        .mux_out    (   west_dout                                       )
    );

    mux
    #(
        .NUM_INPUTS (   7                                                                                       ),
        .DATA_WIDTH (   1                                                                                       )
    )
    MUX_W_v
    (
        .sel        (   mux_sel_w                                                                               ),
        .mux_in     ( { dout_b2_v, dout_b1_v, dout_d_v, dout_v, south_buffer_v, east_buffer_v, north_buffer_v } ),
        .mux_out    (   west_dout_v                                                                             )
    );

    /* ------------------------------ WEST  NODE ------------------------------- */

    PC_superpolyvalent
    #(
        .DATA_WIDTH     ( DATA_WIDTH            )
    )
    cell_inst
    (
        .clk            ( clk                   ),
        .rst_n          ( rst_n                 ),
        .north_din      ( north_buffer          ),
        .north_din_v    ( north_buffer_v        ),
        .east_din       ( east_buffer           ),
        .east_din_v     ( east_buffer_v         ),
        .south_din      ( south_buffer          ),
        .south_din_v    ( south_buffer_v        ),
        .west_din       ( west_buffer           ),
        .west_din_v     ( west_buffer_v         ),
        .din_1_r        ( din_1_r               ),
        .din_2_r        ( din_2_r               ),
        .cin_r          ( cin_r                 ),
        .dout           ( dout                  ),
        .dout_v         ( dout_v                ),
        .dout_d_v       ( dout_d_v              ),
        .dout_b1_v      ( dout_b1_v             ),
        .dout_b2_v      ( dout_b2_v             ),
        .north_dout_r   ( north_dout_r          ),
        .east_dout_r    ( east_dout_r           ),
        .south_dout_r   ( south_dout_r          ),
        .west_dout_r    ( west_dout_r           ),
        .config_bits    ( config_reg[143:36]    ),
        .enables        ( enables_reg[5:4]      )
    );

endmodule
