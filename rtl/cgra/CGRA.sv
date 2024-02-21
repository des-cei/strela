// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module CGRA
    #(
        parameter int DATA_WIDTH = 32
    )
    (
        // Clock and reset
        input  logic                        clk,
        input  logic                        clk_bs,
        input  logic                        rst_n,
        input  logic                        rst_n_bs,

        // Input data
        input  logic [4*DATA_WIDTH-1:0]     data_in,
        input  logic [3:0]                  data_in_valid,
        output logic [3:0]                  data_in_ready,

        // Output data
        output logic [4*DATA_WIDTH-1:0]     data_out,
        output logic [3:0]                  data_out_valid,
        input  logic [3:0]                  data_out_ready,

        // Configuration
        input  logic [159:0]                config_bitstream,
        input  logic                        bitstream_enable_i,
        input  logic                        execute_i
    );

    // Config signals
    logic [143:0]   config_wire;
    logic [5:0]     enables_wire;
    logic [15:0]    catch_config, clk_gate_en, clk_pe;
    logic           clk_bs_cg;

    // Internal data signals
    logic [3:0][2:0][DATA_WIDTH-1:0] hor_we, hor_ew;
    logic [3:0][2:0]                 hor_we_v, hor_we_r, hor_ew_v, hor_ew_r;
    logic [2:0][3:0][DATA_WIDTH-1:0] ver_ns, ver_sn;
    logic [2:0][3:0]                 ver_ns_v, ver_ns_r, ver_sn_v, ver_sn_r;

    // External data signals
    logic [3:0][DATA_WIDTH-1:0] wire_din;
    logic [3:0]                 wire_din_v, wire_din_r;
    logic [3:0][DATA_WIDTH-1:0] wire_dout;
    logic [3:0]                 wire_dout_v, wire_dout_r;

    // Bitstream decoding
    assign config_wire = config_bitstream[143:0];
    assign enables_wire = config_bitstream[159:154];

    always_comb begin
        for (int unsigned i = 0; i < 16; i++) begin
            if (config_bitstream[151:144] == i[11:0] && config_bitstream[152])  catch_config[i] = 1'b1;
            else                                                                catch_config[i] = 1'b0;
        end
    end

    // Bitstream clockgate
    cgra_clock_gate clk_gate_pe_i
    (
        .clk_i     ( clk_bs ),
        .test_en_i ( 1'b0 ),
        .en_i      ( bitstream_enable_i ),
        .clk_o     ( clk_bs_cg )
    );

    // PE clock gates
    generate
        for(genvar i = 0; i < 16; i++) begin
            always_ff @(posedge clk or negedge rst_n_bs) begin : clk_gate_reg
                if(~rst_n_bs) begin
                    clk_gate_en[i] <= 1'b0;
                end else if(catch_config[i]) begin
                    clk_gate_en[i] <= 1'b1;
                end
            end

            cgra_clock_gate clk_gate_pe_i
            (
                .clk_i     ( clk            ),
                .test_en_i ( 1'b0           ),
                .en_i      ( clk_gate_en[i] && execute_i ),
                .clk_o     ( clk_pe[i]      )
            );
        end
    endgenerate

    // Split inputs
    for (genvar i = 0; i < 4; i++) begin
        assign wire_din[i]     = data_in[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH];
        assign wire_din_v[i]   = data_in_valid[i];
        assign data_in_ready[i] = wire_din_r[i];
    end

    // Split outputs
    for (genvar i = 0; i < 4; i++) begin
        assign data_out[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] = wire_dout[i];
        assign data_out_valid[i] = wire_dout_v[i];
        assign wire_dout_r[i] = data_out_ready[i];
    end

    // Processing element instances
    PE_superpolyvalent
    #(
        .DATA_WIDTH     ( DATA_WIDTH )
    )
    PE_0
    (
        .clk            ( clk_pe[0] ),
        .clk_bs         ( clk_bs_cg ),
        .rst_n          ( rst_n ),
        .rst_n_bs       ( rst_n_bs ),
        .config_bits    ( config_wire ),
        .config_enables ( enables_wire ),
        .catch_config   ( catch_config[0] ),
        .north_din      ( wire_din[0] ),
        .north_din_v    ( wire_din_v[0] ),
        .north_din_r    ( wire_din_r[0] ),
        .east_din       ( hor_we[0][0] ),
        .east_din_v     ( hor_we_v[0][0] ),
        .east_din_r     ( hor_we_r[0][0] ),
        .south_din      ( ver_ns[0][0] ),
        .south_din_v    ( ver_ns_v[0][0] ),
        .south_din_r    ( ver_ns_r[0][0] ),
        .west_din       ( '0 ),
        .west_din_v     ( 1'b0 ),
        .west_din_r     (  ),
        .north_dout     (  ),
        .north_dout_v   (  ),
        .north_dout_r   ( 1'b0 ),
        .east_dout      ( hor_ew[0][0] ),
        .east_dout_v    ( hor_ew_v[0][0] ),
        .east_dout_r    ( hor_ew_r[0][0] ),
        .south_dout     ( ver_sn[0][0] ),
        .south_dout_v   ( ver_sn_v[0][0] ),
        .south_dout_r   ( ver_sn_r[0][0] ),
        .west_dout      (  ),
        .west_dout_v    (  ),
        .west_dout_r    ( 1'b0 )
    );

    PE_superpolyvalent
    #(
        .DATA_WIDTH     ( DATA_WIDTH )
    )
    PE_1
    (
        .clk            ( clk_pe[1] ),
        .clk_bs         ( clk_bs_cg ),
        .rst_n          ( rst_n ),
        .rst_n_bs       ( rst_n_bs ),
        .config_bits    ( config_wire ),
        .config_enables ( enables_wire ),
        .catch_config   ( catch_config[1] ),
        .north_din      ( wire_din[1] ),
        .north_din_v    ( wire_din_v[1] ),
        .north_din_r    ( wire_din_r[1] ),
        .east_din       ( hor_we[0][1] ),
        .east_din_v     ( hor_we_v[0][1] ),
        .east_din_r     ( hor_we_r[0][1] ),
        .south_din      ( ver_ns[0][1] ),
        .south_din_v    ( ver_ns_v[0][1] ),
        .south_din_r    ( ver_ns_r[0][1] ),
        .west_din       ( hor_ew[0][0] ),
        .west_din_v     ( hor_ew_v[0][0] ),
        .west_din_r     ( hor_ew_r[0][0] ),
        .north_dout     (  ),
        .north_dout_v   (  ),
        .north_dout_r   ( 1'b0 ),
        .east_dout      ( hor_ew[0][1] ),
        .east_dout_v    ( hor_ew_v[0][1] ),
        .east_dout_r    ( hor_ew_r[0][1] ),
        .south_dout     ( ver_sn[0][1] ),
        .south_dout_v   ( ver_sn_v[0][1] ),
        .south_dout_r   ( ver_sn_r[0][1] ),
        .west_dout      ( hor_we[0][0] ),
        .west_dout_v    ( hor_we_v[0][0] ),
        .west_dout_r    ( hor_we_r[0][0] )
    );

    PE_superpolyvalent
    #(
        .DATA_WIDTH     ( DATA_WIDTH )
    )
    PE_2
    (
        .clk            ( clk_pe[2] ),
        .clk_bs         ( clk_bs_cg ),
        .rst_n          ( rst_n ),
        .rst_n_bs       ( rst_n_bs ),
        .config_bits    ( config_wire ),
        .config_enables ( enables_wire ),
        .catch_config   ( catch_config[2] ),
        .north_din      ( wire_din[2] ),
        .north_din_v    ( wire_din_v[2] ),
        .north_din_r    ( wire_din_r[2] ),
        .east_din       ( hor_we[0][2] ),
        .east_din_v     ( hor_we_v[0][2] ),
        .east_din_r     ( hor_we_r[0][2] ),
        .south_din      ( ver_ns[0][2] ),
        .south_din_v    ( ver_ns_v[0][2] ),
        .south_din_r    ( ver_ns_r[0][2] ),
        .west_din       ( hor_ew[0][1] ),
        .west_din_v     ( hor_ew_v[0][1] ),
        .west_din_r     ( hor_ew_r[0][1] ),
        .north_dout     (  ),
        .north_dout_v   (  ),
        .north_dout_r   ( 1'b0 ),
        .east_dout      ( hor_ew[0][2] ),
        .east_dout_v    ( hor_ew_v[0][2] ),
        .east_dout_r    ( hor_ew_r[0][2] ),
        .south_dout     ( ver_sn[0][2] ),
        .south_dout_v   ( ver_sn_v[0][2] ),
        .south_dout_r   ( ver_sn_r[0][2] ),
        .west_dout      ( hor_we[0][1] ),
        .west_dout_v    ( hor_we_v[0][1] ),
        .west_dout_r    ( hor_we_r[0][1] )
    );

    PE_superpolyvalent
    #(
        .DATA_WIDTH     ( DATA_WIDTH )
    )
    PE_3
    (
        .clk            ( clk_pe[3] ),
        .clk_bs         ( clk_bs_cg ),
        .rst_n          ( rst_n ),
        .rst_n_bs       ( rst_n_bs ),
        .config_bits    ( config_wire ),
        .config_enables ( enables_wire ),
        .catch_config   ( catch_config[3] ),
        .north_din      ( wire_din[3] ),
        .north_din_v    ( wire_din_v[3] ),
        .north_din_r    ( wire_din_r[3] ),
        .east_din       ( '0 ),
        .east_din_v     ( 1'b0 ),
        .east_din_r     (  ),
        .south_din      ( ver_ns[0][3] ),
        .south_din_v    ( ver_ns_v[0][3] ),
        .south_din_r    ( ver_ns_r[0][3] ),
        .west_din       ( hor_ew[0][2] ),
        .west_din_v     ( hor_ew_v[0][2] ),
        .west_din_r     ( hor_ew_r[0][2] ),
        .north_dout     (  ),
        .north_dout_v   (  ),
        .north_dout_r   ( 1'b0 ),
        .east_dout      (  ),
        .east_dout_v    (  ),
        .east_dout_r    ( 1'b0 ),
        .south_dout     ( ver_sn[0][3] ),
        .south_dout_v   ( ver_sn_v[0][3] ),
        .south_dout_r   ( ver_sn_r[0][3] ),
        .west_dout      ( hor_we[0][2] ),
        .west_dout_v    ( hor_we_v[0][2] ),
        .west_dout_r    ( hor_we_r[0][2] )
    );

    PE_superpolyvalent
    #(
        .DATA_WIDTH     ( DATA_WIDTH )
    )
    PE_4
    (
        .clk            ( clk_pe[4] ),
        .clk_bs         ( clk_bs_cg ),
        .rst_n          ( rst_n ),
        .rst_n_bs       ( rst_n_bs ),
        .config_bits    ( config_wire ),
        .config_enables ( enables_wire ),
        .catch_config   ( catch_config[4] ),
        .north_din      ( ver_sn[0][0] ),
        .north_din_v    ( ver_sn_v[0][0] ),
        .north_din_r    ( ver_sn_r[0][0] ),
        .east_din       ( hor_we[1][0] ),
        .east_din_v     ( hor_we_v[1][0] ),
        .east_din_r     ( hor_we_r[1][0] ),
        .south_din      ( ver_ns[1][0] ),
        .south_din_v    ( ver_ns_v[1][0] ),
        .south_din_r    ( ver_ns_r[1][0] ),
        .west_din       ( '0 ),
        .west_din_v     ( 1'b0 ),
        .west_din_r     (  ),
        .north_dout     ( ver_ns[0][0] ),
        .north_dout_v   ( ver_ns_v[0][0] ),
        .north_dout_r   ( ver_ns_r[0][0] ),
        .east_dout      ( hor_ew[1][0] ),
        .east_dout_v    ( hor_ew_v[1][0] ),
        .east_dout_r    ( hor_ew_r[1][0] ),
        .south_dout     ( ver_sn[1][0] ),
        .south_dout_v   ( ver_sn_v[1][0] ),
        .south_dout_r   ( ver_sn_r[1][0] ),
        .west_dout      (  ),
        .west_dout_v    (  ),
        .west_dout_r    ( 1'b0 )
    );

    PE_superpolyvalent
    #(
        .DATA_WIDTH     ( DATA_WIDTH )
    )
    PE_5
    (
        .clk            ( clk_pe[5] ),
        .clk_bs         ( clk_bs_cg ),
        .rst_n          ( rst_n ),
        .rst_n_bs       ( rst_n_bs ),
        .config_bits    ( config_wire ),
        .config_enables ( enables_wire ),
        .catch_config   ( catch_config[5] ),
        .north_din      ( ver_sn[0][1] ),
        .north_din_v    ( ver_sn_v[0][1] ),
        .north_din_r    ( ver_sn_r[0][1] ),
        .east_din       ( hor_we[1][1] ),
        .east_din_v     ( hor_we_v[1][1] ),
        .east_din_r     ( hor_we_r[1][1] ),
        .south_din      ( ver_ns[1][1] ),
        .south_din_v    ( ver_ns_v[1][1] ),
        .south_din_r    ( ver_ns_r[1][1] ),
        .west_din       ( hor_ew[1][0] ),
        .west_din_v     ( hor_ew_v[1][0] ),
        .west_din_r     ( hor_ew_r[1][0] ),
        .north_dout     ( ver_ns[0][1] ),
        .north_dout_v   ( ver_ns_v[0][1] ),
        .north_dout_r   ( ver_ns_r[0][1] ),
        .east_dout      ( hor_ew[1][1] ),
        .east_dout_v    ( hor_ew_v[1][1] ),
        .east_dout_r    ( hor_ew_r[1][1] ),
        .south_dout     ( ver_sn[1][1] ),
        .south_dout_v   ( ver_sn_v[1][1] ),
        .south_dout_r   ( ver_sn_r[1][1] ),
        .west_dout      ( hor_we[1][0] ),
        .west_dout_v    ( hor_we_v[1][0] ),
        .west_dout_r    ( hor_we_r[1][0] )
    );

    PE_superpolyvalent
    #(
        .DATA_WIDTH     ( DATA_WIDTH )
    )
    PE_6
    (
        .clk            ( clk_pe[6] ),
        .clk_bs         ( clk_bs_cg ),
        .rst_n          ( rst_n ),
        .rst_n_bs       ( rst_n_bs ),
        .config_bits    ( config_wire ),
        .config_enables ( enables_wire ),
        .catch_config   ( catch_config[6] ),
        .north_din      ( ver_sn[0][2] ),
        .north_din_v    ( ver_sn_v[0][2] ),
        .north_din_r    ( ver_sn_r[0][2] ),
        .east_din       ( hor_we[1][2] ),
        .east_din_v     ( hor_we_v[1][2] ),
        .east_din_r     ( hor_we_r[1][2] ),
        .south_din      ( ver_ns[1][2] ),
        .south_din_v    ( ver_ns_v[1][2] ),
        .south_din_r    ( ver_ns_r[1][2] ),
        .west_din       ( hor_ew[1][1] ),
        .west_din_v     ( hor_ew_v[1][1] ),
        .west_din_r     ( hor_ew_r[1][1] ),
        .north_dout     ( ver_ns[0][2] ),
        .north_dout_v   ( ver_ns_v[0][2] ),
        .north_dout_r   ( ver_ns_r[0][2] ),
        .east_dout      ( hor_ew[1][2] ),
        .east_dout_v    ( hor_ew_v[1][2] ),
        .east_dout_r    ( hor_ew_r[1][2] ),
        .south_dout     ( ver_sn[1][2] ),
        .south_dout_v   ( ver_sn_v[1][2] ),
        .south_dout_r   ( ver_sn_r[1][2] ),
        .west_dout      ( hor_we[1][1] ),
        .west_dout_v    ( hor_we_v[1][1] ),
        .west_dout_r    ( hor_we_r[1][1] )
    );

    PE_superpolyvalent
    #(
        .DATA_WIDTH     ( DATA_WIDTH )
    )
    PE_7
    (
        .clk            ( clk_pe[7] ),
        .clk_bs         ( clk_bs_cg ),
        .rst_n          ( rst_n ),
        .rst_n_bs       ( rst_n_bs ),
        .config_bits    ( config_wire ),
        .config_enables ( enables_wire ),
        .catch_config   ( catch_config[7] ),
        .north_din      ( ver_sn[0][3] ),
        .north_din_v    ( ver_sn_v[0][3] ),
        .north_din_r    ( ver_sn_r[0][3] ),
        .east_din       ( '0 ),
        .east_din_v     ( 1'b0 ),
        .east_din_r     (  ),
        .south_din      ( ver_ns[1][3] ),
        .south_din_v    ( ver_ns_v[1][3] ),
        .south_din_r    ( ver_ns_r[1][3] ),
        .west_din       ( hor_ew[1][2] ),
        .west_din_v     ( hor_ew_v[1][2] ),
        .west_din_r     ( hor_ew_r[1][2] ),
        .north_dout     ( ver_ns[0][3] ),
        .north_dout_v   ( ver_ns_v[0][3] ),
        .north_dout_r   ( ver_ns_r[0][3] ),
        .east_dout      (  ),
        .east_dout_v    (  ),
        .east_dout_r    ( 1'b0 ),
        .south_dout     ( ver_sn[1][3] ),
        .south_dout_v   ( ver_sn_v[1][3] ),
        .south_dout_r   ( ver_sn_r[1][3] ),
        .west_dout      ( hor_we[1][2] ),
        .west_dout_v    ( hor_we_v[1][2] ),
        .west_dout_r    ( hor_we_r[1][2] )
    );

    PE_superpolyvalent
    #(
        .DATA_WIDTH     ( DATA_WIDTH )
    )
    PE_8
    (
        .clk            ( clk_pe[8] ),
        .clk_bs         ( clk_bs_cg ),
        .rst_n          ( rst_n ),
        .rst_n_bs       ( rst_n_bs ),
        .config_bits    ( config_wire ),
        .config_enables ( enables_wire ),
        .catch_config   ( catch_config[8] ),
        .north_din      ( ver_sn[1][0] ),
        .north_din_v    ( ver_sn_v[1][0] ),
        .north_din_r    ( ver_sn_r[1][0] ),
        .east_din       ( hor_we[2][0] ),
        .east_din_v     ( hor_we_v[2][0] ),
        .east_din_r     ( hor_we_r[2][0] ),
        .south_din      ( ver_ns[2][0] ),
        .south_din_v    ( ver_ns_v[2][0] ),
        .south_din_r    ( ver_ns_r[2][0] ),
        .west_din       ( '0 ),
        .west_din_v     ( 1'b0 ),
        .west_din_r     (  ),
        .north_dout     ( ver_ns[1][0] ),
        .north_dout_v   ( ver_ns_v[1][0] ),
        .north_dout_r   ( ver_ns_r[1][0] ),
        .east_dout      ( hor_ew[2][0] ),
        .east_dout_v    ( hor_ew_v[2][0] ),
        .east_dout_r    ( hor_ew_r[2][0] ),
        .south_dout     ( ver_sn[2][0] ),
        .south_dout_v   ( ver_sn_v[2][0] ),
        .south_dout_r   ( ver_sn_r[2][0] ),
        .west_dout      (  ),
        .west_dout_v    (  ),
        .west_dout_r    ( 1'b0 )
    );

    PE_superpolyvalent
    #(
        .DATA_WIDTH     ( DATA_WIDTH )
    )
    PE_9
    (
        .clk            ( clk_pe[9] ),
        .clk_bs         ( clk_bs_cg ),
        .rst_n          ( rst_n ),
        .rst_n_bs       ( rst_n_bs ),
        .config_bits    ( config_wire ),
        .config_enables ( enables_wire ),
        .catch_config   ( catch_config[9] ),
        .north_din      ( ver_sn[1][1] ),
        .north_din_v    ( ver_sn_v[1][1] ),
        .north_din_r    ( ver_sn_r[1][1] ),
        .east_din       ( hor_we[2][1] ),
        .east_din_v     ( hor_we_v[2][1] ),
        .east_din_r     ( hor_we_r[2][1] ),
        .south_din      ( ver_ns[2][1] ),
        .south_din_v    ( ver_ns_v[2][1] ),
        .south_din_r    ( ver_ns_r[2][1] ),
        .west_din       ( hor_ew[2][0] ),
        .west_din_v     ( hor_ew_v[2][0] ),
        .west_din_r     ( hor_ew_r[2][0] ),
        .north_dout     ( ver_ns[1][1] ),
        .north_dout_v   ( ver_ns_v[1][1] ),
        .north_dout_r   ( ver_ns_r[1][1] ),
        .east_dout      ( hor_ew[2][1] ),
        .east_dout_v    ( hor_ew_v[2][1] ),
        .east_dout_r    ( hor_ew_r[2][1] ),
        .south_dout     ( ver_sn[2][1] ),
        .south_dout_v   ( ver_sn_v[2][1] ),
        .south_dout_r   ( ver_sn_r[2][1] ),
        .west_dout      ( hor_we[2][0] ),
        .west_dout_v    ( hor_we_v[2][0] ),
        .west_dout_r    ( hor_we_r[2][0] )
    );

    PE_superpolyvalent
    #(
        .DATA_WIDTH     ( DATA_WIDTH )
    )
    PE_10
    (
        .clk            ( clk_pe[10] ),
        .clk_bs         ( clk_bs_cg ),
        .rst_n          ( rst_n ),
        .rst_n_bs       ( rst_n_bs ),
        .config_bits    ( config_wire ),
        .config_enables ( enables_wire ),
        .catch_config   ( catch_config[10] ),
        .north_din      ( ver_sn[1][2] ),
        .north_din_v    ( ver_sn_v[1][2] ),
        .north_din_r    ( ver_sn_r[1][2] ),
        .east_din       ( hor_we[2][2] ),
        .east_din_v     ( hor_we_v[2][2] ),
        .east_din_r     ( hor_we_r[2][2] ),
        .south_din      ( ver_ns[2][2] ),
        .south_din_v    ( ver_ns_v[2][2] ),
        .south_din_r    ( ver_ns_r[2][2] ),
        .west_din       ( hor_ew[2][1] ),
        .west_din_v     ( hor_ew_v[2][1] ),
        .west_din_r     ( hor_ew_r[2][1] ),
        .north_dout     ( ver_ns[1][2] ),
        .north_dout_v   ( ver_ns_v[1][2] ),
        .north_dout_r   ( ver_ns_r[1][2] ),
        .east_dout      ( hor_ew[2][2] ),
        .east_dout_v    ( hor_ew_v[2][2] ),
        .east_dout_r    ( hor_ew_r[2][2] ),
        .south_dout     ( ver_sn[2][2] ),
        .south_dout_v   ( ver_sn_v[2][2] ),
        .south_dout_r   ( ver_sn_r[2][2] ),
        .west_dout      ( hor_we[2][1] ),
        .west_dout_v    ( hor_we_v[2][1] ),
        .west_dout_r    ( hor_we_r[2][1] )
    );

    PE_superpolyvalent
    #(
        .DATA_WIDTH     ( DATA_WIDTH )
    )
    PE_11
    (
        .clk            ( clk_pe[11] ),
        .clk_bs         ( clk_bs_cg ),
        .rst_n          ( rst_n ),
        .rst_n_bs       ( rst_n_bs ),
        .config_bits    ( config_wire ),
        .config_enables ( enables_wire ),
        .catch_config   ( catch_config[11] ),
        .north_din      ( ver_sn[1][3] ),
        .north_din_v    ( ver_sn_v[1][3] ),
        .north_din_r    ( ver_sn_r[1][3] ),
        .east_din       ( '0 ),
        .east_din_v     ( 1'b0 ),
        .east_din_r     (  ),
        .south_din      ( ver_ns[2][3] ),
        .south_din_v    ( ver_ns_v[2][3] ),
        .south_din_r    ( ver_ns_r[2][3] ),
        .west_din       ( hor_ew[2][2] ),
        .west_din_v     ( hor_ew_v[2][2] ),
        .west_din_r     ( hor_ew_r[2][2] ),
        .north_dout     ( ver_ns[1][3] ),
        .north_dout_v   ( ver_ns_v[1][3] ),
        .north_dout_r   ( ver_ns_r[1][3] ),
        .east_dout      (  ),
        .east_dout_v    (  ),
        .east_dout_r    ( 1'b0 ),
        .south_dout     ( ver_sn[2][3] ),
        .south_dout_v   ( ver_sn_v[2][3] ),
        .south_dout_r   ( ver_sn_r[2][3] ),
        .west_dout      ( hor_we[2][2] ),
        .west_dout_v    ( hor_we_v[2][2] ),
        .west_dout_r    ( hor_we_r[2][2] )
    );

    PE_superpolyvalent
    #(
        .DATA_WIDTH     ( DATA_WIDTH )
    )
    PE_12
    (
        .clk            ( clk_pe[12] ),
        .clk_bs         ( clk_bs_cg ),
        .rst_n          ( rst_n ),
        .rst_n_bs       ( rst_n_bs ),
        .config_bits    ( config_wire ),
        .config_enables ( enables_wire ),
        .catch_config   ( catch_config[12] ),
        .north_din      ( ver_sn[2][0] ),
        .north_din_v    ( ver_sn_v[2][0] ),
        .north_din_r    ( ver_sn_r[2][0] ),
        .east_din       ( hor_we[3][0] ),
        .east_din_v     ( hor_we_v[3][0] ),
        .east_din_r     ( hor_we_r[3][0] ),
        .south_din      ( '0 ),
        .south_din_v    ( 1'b0 ),
        .south_din_r    (  ),
        .west_din       ( '0 ),
        .west_din_v     ( 1'b0 ),
        .west_din_r     (  ),
        .north_dout     ( ver_ns[2][0] ),
        .north_dout_v   ( ver_ns_v[2][0] ),
        .north_dout_r   ( ver_ns_r[2][0] ),
        .east_dout      ( hor_ew[3][0] ),
        .east_dout_v    ( hor_ew_v[3][0] ),
        .east_dout_r    ( hor_ew_r[3][0] ),
        .south_dout     ( wire_dout[0] ),
        .south_dout_v   ( wire_dout_v[0] ),
        .south_dout_r   ( wire_dout_r[0] ),
        .west_dout      (  ),
        .west_dout_v    (  ),
        .west_dout_r    ( 1'b0 )
    );

    PE_superpolyvalent
    #(
        .DATA_WIDTH     ( DATA_WIDTH )
    )
    PE_13
    (
        .clk            ( clk_pe[13] ),
        .clk_bs         ( clk_bs_cg ),
        .rst_n          ( rst_n ),
        .rst_n_bs       ( rst_n_bs ),
        .config_bits    ( config_wire ),
        .config_enables ( enables_wire ),
        .catch_config   ( catch_config[13] ),
        .north_din      ( ver_sn[2][1] ),
        .north_din_v    ( ver_sn_v[2][1] ),
        .north_din_r    ( ver_sn_r[2][1] ),
        .east_din       ( hor_we[3][1] ),
        .east_din_v     ( hor_we_v[3][1] ),
        .east_din_r     ( hor_we_r[3][1] ),
        .south_din      ( '0 ),
        .south_din_v    ( 1'b0 ),
        .south_din_r    (  ),
        .west_din       ( hor_ew[3][0] ),
        .west_din_v     ( hor_ew_v[3][0] ),
        .west_din_r     ( hor_ew_r[3][0] ),
        .north_dout     ( ver_ns[2][1] ),
        .north_dout_v   ( ver_ns_v[2][1] ),
        .north_dout_r   ( ver_ns_r[2][1] ),
        .east_dout      ( hor_ew[3][1] ),
        .east_dout_v    ( hor_ew_v[3][1] ),
        .east_dout_r    ( hor_ew_r[3][1] ),
        .south_dout     ( wire_dout[1] ),
        .south_dout_v   ( wire_dout_v[1] ),
        .south_dout_r   ( wire_dout_r[1] ),
        .west_dout      ( hor_we[3][0] ),
        .west_dout_v    ( hor_we_v[3][0] ),
        .west_dout_r    ( hor_we_r[3][0] )
    );

    PE_superpolyvalent
    #(
        .DATA_WIDTH     ( DATA_WIDTH )
    )
    PE_14
    (
        .clk            ( clk_pe[14] ),
        .clk_bs         ( clk_bs_cg ),
        .rst_n          ( rst_n ),
        .rst_n_bs       ( rst_n_bs ),
        .config_bits    ( config_wire ),
        .config_enables ( enables_wire ),
        .catch_config   ( catch_config[14] ),
        .north_din      ( ver_sn[2][2] ),
        .north_din_v    ( ver_sn_v[2][2] ),
        .north_din_r    ( ver_sn_r[2][2] ),
        .east_din       ( hor_we[3][2] ),
        .east_din_v     ( hor_we_v[3][2] ),
        .east_din_r     ( hor_we_r[3][2] ),
        .south_din      ( '0 ),
        .south_din_v    ( 1'b0 ),
        .south_din_r    (  ),
        .west_din       ( hor_ew[3][1] ),
        .west_din_v     ( hor_ew_v[3][1] ),
        .west_din_r     ( hor_ew_r[3][1] ),
        .north_dout     ( ver_ns[2][2] ),
        .north_dout_v   ( ver_ns_v[2][2] ),
        .north_dout_r   ( ver_ns_r[2][2] ),
        .east_dout      ( hor_ew[3][2] ),
        .east_dout_v    ( hor_ew_v[3][2] ),
        .east_dout_r    ( hor_ew_r[3][2] ),
        .south_dout     ( wire_dout[2] ),
        .south_dout_v   ( wire_dout_v[2] ),
        .south_dout_r   ( wire_dout_r[2] ),
        .west_dout      ( hor_we[3][1] ),
        .west_dout_v    ( hor_we_v[3][1] ),
        .west_dout_r    ( hor_we_r[3][1] )
    );

    PE_superpolyvalent
    #(
        .DATA_WIDTH     ( DATA_WIDTH )
    )
    PE_15
    (
        .clk            ( clk_pe[15] ),
        .clk_bs         ( clk_bs_cg ),
        .rst_n          ( rst_n ),
        .rst_n_bs       ( rst_n_bs ),
        .config_bits    ( config_wire ),
        .config_enables ( enables_wire ),
        .catch_config   ( catch_config[15] ),
        .north_din      ( ver_sn[2][3] ),
        .north_din_v    ( ver_sn_v[2][3] ),
        .north_din_r    ( ver_sn_r[2][3] ),
        .east_din       ( '0 ),
        .east_din_v     ( 1'b0 ),
        .east_din_r     (  ),
        .south_din      ( '0 ),
        .south_din_v    ( 1'b0 ),
        .south_din_r    (  ),
        .west_din       ( hor_ew[3][2] ),
        .west_din_v     ( hor_ew_v[3][2] ),
        .west_din_r     ( hor_ew_r[3][2] ),
        .north_dout     ( ver_ns[2][3] ),
        .north_dout_v   ( ver_ns_v[2][3] ),
        .north_dout_r   ( ver_ns_r[2][3] ),
        .east_dout      (  ),
        .east_dout_v    (  ),
        .east_dout_r    ( 1'b0 ),
        .south_dout     ( wire_dout[3] ),
        .south_dout_v   ( wire_dout_v[3] ),
        .south_dout_r   ( wire_dout_r[3] ),
        .west_dout      ( hor_we[3][2] ),
        .west_dout_v    ( hor_we_v[3][2] ),
        .west_dout_r    ( hor_we_r[3][2] )
    );

endmodule
