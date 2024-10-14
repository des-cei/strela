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
        input  logic                    clk_i,
        input  logic                    rst_ni,
        input  logic                    clr_i,

        // Configuration
        input  logic                    conf_en_i,
        output logic                    conf_en_o,

        // Input data
        input  logic [DATA_WIDTH-1:0]   north_din_i,
        input  logic                    north_din_v_i,
        output logic                    north_din_r_o,
        input  logic [DATA_WIDTH-1:0]   east_din_i,
        input  logic                    east_din_v_i,
        output logic                    east_din_r_o,
        input  logic [DATA_WIDTH-1:0]   south_din_i,
        input  logic                    south_din_v_i,
        output logic                    south_din_r_o,
        input  logic [DATA_WIDTH-1:0]   west_din_i,
        input  logic                    west_din_v_i,
        output logic                    west_din_r_o,

        // Output data
        output logic [DATA_WIDTH-1:0]   north_dout_o,
        output logic                    north_dout_v_o,
        input  logic                    north_dout_r_i,
        output logic [DATA_WIDTH-1:0]   east_dout_o,
        output logic                    east_dout_v_o,
        input  logic                    east_dout_r_i,
        output logic [DATA_WIDTH-1:0]   south_dout_o,
        output logic                    south_dout_v_o,
        input  logic                    south_dout_r_i,
        output logic [DATA_WIDTH-1:0]   west_dout_o,
        output logic                    west_dout_v_o,
        input  logic                    west_dout_r_i
    );
    // synopsys sync_set_reset clr_i

    // Config signals
    logic [  2:0]   mux_sel_n, mux_sel_e, mux_sel_s, mux_sel_w;
    logic [  1:0]   data_mux_sel_n, data_mux_sel_e, data_mux_sel_s, data_mux_sel_w;
    logic [  5:0]   mask_fs_n, mask_fs_e, mask_fs_s, mask_fs_w;
    logic [  5:0]   eb_en;
    logic [159:0]   conf_wire, conf_reg;
    logic [  2:0]   conf_cnt;

    // Temporal signals
    logic [DATA_WIDTH-1:0]  tmp_south_dout;
    logic                   tmp_north_din_v;
    // Buffer
    logic [DATA_WIDTH-1:0]  north_buffer, east_buffer, south_buffer, west_buffer;
    logic                   north_buffer_v, east_buffer_v, south_buffer_v, west_buffer_v;
    logic                   temp_north_buffer_v, temp_east_buffer_v, temp_south_buffer_v, temp_west_buffer_v;
    logic                   north_buffer_r, east_buffer_r, south_buffer_r, west_buffer_r;
    // Processing cell
    logic                   din_1_r, din_2_r, cin_r;
    logic [DATA_WIDTH-1:0]  dout;
    logic                   dout_v, dout_d_v, dout_b1_v, dout_b2_v;

    // Configuration signals
    assign conf_wire = {north_din_i, conf_reg[159:DATA_WIDTH]};
    assign tmp_north_din_v = north_din_v_i && !conf_en_i;
    assign south_dout_o = conf_en_i ? conf_reg[DATA_WIDTH-1:0] : tmp_south_dout;

    // Configuration registers
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            conf_reg <= 0;
        end else begin
            if (conf_en_i) begin
                conf_reg <= conf_wire;
            end
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            conf_cnt <= 0;
        end else begin
            if (clr_i) begin
                conf_cnt <= 0;
            end else if (conf_en_i && conf_cnt < 5) begin
                conf_cnt <= conf_cnt + 1;
            end
        end
    end

    assign conf_en_o = conf_en_i && conf_cnt == 5;

    // Configuration decoding
    assign mask_fs_n = conf_reg[5:0];
    assign mask_fs_e = conf_reg[11:6];
    assign mask_fs_s = conf_reg[17:12];
    assign mask_fs_w = conf_reg[23:18];
    assign mux_sel_n = conf_reg[26:24];
    assign mux_sel_e = conf_reg[29:27];
    assign mux_sel_s = conf_reg[32:30];
    assign mux_sel_w = conf_reg[35:33];
    assign eb_en     = conf_reg[159:154];

    /* ------------------------------ NORTH NODE ------------------------------- */

    // Input
    elastic_buffer
    #(
        .DATA_WIDTH ( DATA_WIDTH            )
    )
    REG_N
    (
        .clk_i,
        .rst_ni,
        .clr_i,
        .en_i       ( eb_en[0]              ),
        .din_i      ( north_din_i           ),
        .din_v_i    ( tmp_north_din_v       ),
        .din_r_o    ( north_din_r_o         ),
        .dout_o     ( north_buffer          ),
        .dout_v_o   ( temp_north_buffer_v   ),
        .dout_r_i   ( north_buffer_r        )
    );

    assign north_buffer_v = temp_north_buffer_v && north_buffer_r;

    fork_sender
    #(
        .NUM_READYS     (   6                                                                           )
    )
    FS_N
    (
        .fork_mask_i    (   mask_fs_n                                                                   ),
        .ready_in_o     (   north_buffer_r                                                              ),
        .readys_out_i   ( { din_1_r, din_2_r, cin_r, east_dout_r_i, south_dout_r_i, west_dout_r_i }     )
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
        .sel_i      (   data_mux_sel_n                                  ),
        .mux_i      ( { dout, west_buffer, south_buffer, east_buffer }  ),
        .mux_o      (   north_dout_o                                    )
    );

    mux
    #(
        .NUM_INPUTS (   7                                                                                       ),
        .DATA_WIDTH (   1                                                                                       )
    )
    MUX_N_v
    (
        .sel_i      (   mux_sel_n                                                                               ),
        .mux_i      ( { dout_b2_v, dout_b1_v, dout_d_v, dout_v, west_buffer_v, south_buffer_v, east_buffer_v }  ),
        .mux_o      (   north_dout_v_o                                                                          )
    );

    /* ------------------------------ NORTH NODE ------------------------------- */

    /* ------------------------------ EAST  NODE ------------------------------- */

    // Input
    elastic_buffer
    #(
        .DATA_WIDTH ( DATA_WIDTH            )
    )
    REG_E
    (
        .clk_i,
        .rst_ni,
        .clr_i,
        .en_i       ( eb_en[1]              ),
        .din_i      ( east_din_i            ),
        .din_v_i    ( east_din_v_i          ),
        .din_r_o    ( east_din_r_o          ),
        .dout_o     ( east_buffer           ),
        .dout_v_o   ( temp_east_buffer_v    ),
        .dout_r_i   ( east_buffer_r         )
    );

    assign east_buffer_v = temp_east_buffer_v && east_buffer_r;

    fork_sender
    #(
        .NUM_READYS     (   6                                                                           )
    )
    FS_E
    (
        .fork_mask_i    (   mask_fs_e                                                                   ),
        .ready_in_o     (   east_buffer_r                                                               ),
        .readys_out_i   ( { din_1_r, din_2_r, cin_r, north_dout_r_i, south_dout_r_i, west_dout_r_i }    )
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
        .sel_i      (   data_mux_sel_e                                  ),
        .mux_i      ( { dout, west_buffer, south_buffer, north_buffer } ),
        .mux_o      (   east_dout_o                                     )
    );

    mux
    #(
        .NUM_INPUTS (   7                                                                                       ),
        .DATA_WIDTH (   1                                                                                       )
    )
    MUX_E_v
    (
        .sel_i      (   mux_sel_e                                                                               ),
        .mux_i      ( { dout_b2_v, dout_b1_v, dout_d_v, dout_v, west_buffer_v, south_buffer_v, north_buffer_v } ),
        .mux_o      (   east_dout_v_o                                                                           )
    );

    /* ------------------------------ EAST  NODE ------------------------------- */

    /* ------------------------------ SOUTH NODE ------------------------------- */

    // Input
    elastic_buffer
    #(
        .DATA_WIDTH ( DATA_WIDTH            )
    )
    REG_S
    (
        .clk_i,
        .rst_ni,
        .clr_i,
        .en_i       ( eb_en[2]              ),
        .din_i      ( south_din_i           ),
        .din_v_i    ( south_din_v_i         ),
        .din_r_o    ( south_din_r_o         ),
        .dout_o     ( south_buffer          ),
        .dout_v_o   ( temp_south_buffer_v   ),
        .dout_r_i   ( south_buffer_r        )
    );

    assign south_buffer_v = temp_south_buffer_v && south_buffer_r;

    fork_sender
    #(
        .NUM_READYS     (   6                                                                           )
    )
    FS_S
    (
        .fork_mask_i    (   mask_fs_s                                                                   ),
        .ready_in_o     (   south_buffer_r                                                              ),
        .readys_out_i   ( { din_1_r, din_2_r, cin_r, north_dout_r_i, east_dout_r_i, west_dout_r_i }     )
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
        .sel_i      (   data_mux_sel_s                                  ),
        .mux_i      ( { dout, west_buffer, east_buffer, north_buffer }  ),
        .mux_o      (   tmp_south_dout                                  )
    );

    mux
    #(
        .NUM_INPUTS (   7                                                                                       ),
        .DATA_WIDTH (   1                                                                                       )
    )
    MUX_S_v
    (
        .sel_i      (   mux_sel_s                                                                               ),
        .mux_i      ( { dout_b2_v, dout_b1_v, dout_d_v, dout_v, west_buffer_v, east_buffer_v, north_buffer_v }  ),
        .mux_o      (   south_dout_v_o                                                                          )
    );

    /* ------------------------------ SOUTH NODE ------------------------------- */

    /* ------------------------------ WEST  NODE ------------------------------- */

    // Input
    elastic_buffer
    #(
        .DATA_WIDTH ( DATA_WIDTH            )
    )
    REG_W
    (
        .clk_i,
        .rst_ni,
        .clr_i,
        .en_i       ( eb_en[3]              ),
        .din_i      ( west_din_i            ),
        .din_v_i    ( west_din_v_i          ),
        .din_r_o    ( west_din_r_o          ),
        .dout_o     ( west_buffer           ),
        .dout_v_o   ( temp_west_buffer_v    ),
        .dout_r_i   ( west_buffer_r         )
    );

    assign west_buffer_v = temp_west_buffer_v && west_buffer_r;

    fork_sender
    #(
        .NUM_READYS     (   6                                                                           )
    )
    FS_W
    (
        .fork_mask_i    (   mask_fs_w                                                                   ),
        .ready_in_o     (   west_buffer_r                                                               ),
        .readys_out_i   ( { din_1_r, din_2_r, cin_r, north_dout_r_i, east_dout_r_i, south_dout_r_i }    )
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
        .sel_i      (   data_mux_sel_w                                  ),
        .mux_i      ( { dout, south_buffer, east_buffer, north_buffer } ),
        .mux_o      (   west_dout_o                                     )
    );

    mux
    #(
        .NUM_INPUTS (   7                                                                                       ),
        .DATA_WIDTH (   1                                                                                       )
    )
    MUX_W_v
    (
        .sel_i      (   mux_sel_w                                                                               ),
        .mux_i      ( { dout_b2_v, dout_b1_v, dout_d_v, dout_v, south_buffer_v, east_buffer_v, north_buffer_v } ),
        .mux_o      (   west_dout_v_o                                                                           )
    );

    /* ------------------------------ WEST  NODE ------------------------------- */

    PC_superpolyvalent
    #(
        .DATA_WIDTH     ( DATA_WIDTH        )
    )
    cell_inst
    (
        .clk_i,
        .rst_ni,
        .clr_i,
        .north_din_i    ( north_buffer      ),
        .north_din_v_i  ( north_buffer_v    ),
        .east_din_i     ( east_buffer       ),
        .east_din_v_i   ( east_buffer_v     ),
        .south_din_i    ( south_buffer      ),
        .south_din_v_i  ( south_buffer_v    ),
        .west_din_i     ( west_buffer       ),
        .west_din_v_i   ( west_buffer_v     ),
        .din_1_r_o      ( din_1_r           ),
        .din_2_r_o      ( din_2_r           ),
        .cin_r_o        ( cin_r             ),
        .dout_o         ( dout              ),
        .dout_v_o       ( dout_v            ),
        .dout_d_v_o     ( dout_d_v          ),
        .dout_b1_v_o    ( dout_b1_v         ),
        .dout_b2_v_o    ( dout_b2_v         ),
        .north_dout_r_i ( north_dout_r_i    ),
        .east_dout_r_i  ( east_dout_r_i     ),
        .south_dout_r_i ( south_dout_r_i    ),
        .west_dout_r_i  ( west_dout_r_i     ),
        .conf_bits_i    ( conf_reg[143:36]  ),
        .eb_en_i        ( eb_en[5:4]        )
    );

endmodule
