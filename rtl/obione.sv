// Copyright 2026 CEIMM-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module obione
  import xheep_obi_pkg::*;
#(
  parameter int unsigned DATA_WIDTH = 32,  // Data width
  parameter int unsigned ADDR_WIDTH = 32,  // Address width
  parameter int unsigned SIZE_WIDTH = 16,  // Size width
  parameter int unsigned STRD_WIDTH = 16,  // Stride width
  parameter int unsigned FIFO_DEPTH = 8,  // FIFO depth
  parameter bit WR_PORT_EN = 1'b1,  // Write port is enabled
  parameter bit RD_PORT_EN = 1'b1,  // Read port is enabled
  parameter bit BP_EN = 1'b1,  // Backpressure is enabled
  parameter bit PACK_EN = 1'b0,  // Sub-word packing is enabled
  parameter bit UNPACK_EN = 1'b0,  // Sub-word unpacking is enabled
  // DO NOT OVERWRITE THIS PARAMETER
  parameter int unsigned ADDR_DEPTH = (FIFO_DEPTH > 1) ? $clog2(FIFO_DEPTH) : 1
) (
  input logic clk_i,  // Clock
  input logic rst_ni,  // Asynchronous reset
  input logic clr_i,  // Synchronous reset
  // Control and status
  input logic start_i,  // Start DMA operation (can overlap done_o)
  input logic rw_i,  // Read [0] or write [1] operation (must be stable)
  output logic done_o,  // DMA operation finish
  // Parameters
  input logic [ADDR_WIDTH-1:0] addr_i,  // Initial transfer address (must be stable)
  input logic [SIZE_WIDTH-1:0] size_i,  // Transfer size (must be stable)
  input logic [STRD_WIDTH-1:0] stride_i,  // Transfer stride (must be stable)
  input logic [2:0] sew_i,  // Selected Element Width (must be stable)
  // OBI master interface
  output xheep_obi_req_t master_req_o,  // OBI master request
  input xheep_obi_rsp_t master_resp_i,  // OBI master response
  // Write port data
  input logic [DATA_WIDTH-1:0] data_i,  // Input data
  input logic valid_i,  // Input valid
  output logic ready_o,  // Ouptut ready
  // Read port data
  output logic [DATA_WIDTH-1:0] data_o,  // Output data
  output logic [3:0] byte_en_o,  // Valid bytes in the output word
  output logic valid_o,  // Output valid
  input logic ready_i  // Input ready
);
  // synopsys sync_set_reset clr_i

  typedef enum logic {
    S_IDLE = 1'b0,
    S_MREQ = 1'b1
  } state_t;

  state_t                  state;
  state_t                  n_state;

  logic   [ADDR_WIDTH-1:0] actual_addr;
  logic   [ADDR_WIDTH-1:0] n_actual_addr;
  logic   [ADDR_WIDTH-1:0] end_addr;
  logic   [SIZE_WIDTH-1:0] addr_offset;
  logic   [SIZE_WIDTH-1:0] n_addr_offset;
  logic   [           2:0] read_offset;
  logic   [           2:0] n_read_offset;
  logic                    transaction;
  logic                    req_dis;
  logic                    req_condition;
  logic   [           3:0] be;
  logic   [           3:0] last_be;
  logic   [           1:0] addr_lsb;
  logic   [ADDR_DEPTH-1:0] onthefly_count;

  logic   [SIZE_WIDTH-1:0] write_count;
  logic   [SIZE_WIDTH-1:0] n_write_count;
  logic   [DATA_WIDTH-9:0] write_reg;
  logic   [DATA_WIDTH-1:0] write_data;
  logic                    write_push;
  logic                    write_full;
  logic                    write_empty;

  logic   [ADDR_DEPTH-1:0] read_data_count;
  logic   [DATA_WIDTH-1:0] read_data;
  logic   [          15:0] read_data_16;
  logic   [           7:0] read_data_8;
  logic                    read_pop;
  logic                    read_empty;

  logic                    fifo_transaction;


  // Direct assignments
  assign transaction = master_req_o.req & master_resp_i.gnt;
  assign n_addr_offset = addr_offset + SIZE_WIDTH'(stride_i);
  assign n_write_count = write_count + SIZE_WIDTH'(stride_i);
  assign actual_addr = addr_i + ADDR_WIDTH'(addr_offset);
  assign n_actual_addr = addr_i + ADDR_WIDTH'(n_addr_offset);
  assign n_read_offset = read_offset + {1'b0, stride_i[1:0]};
  assign end_addr = addr_i + ADDR_WIDTH'(size_i);

  assign master_req_o.addr = {actual_addr[ADDR_WIDTH-1:2], 2'b00};
  assign master_req_o.we = rw_i;
  assign master_req_o.be = actual_addr[31:2] == end_addr[31:2] ? last_be & be : be;

  // Registers
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state <= S_IDLE;
      addr_offset <= '0;
      req_dis <= 1'b0;
      read_offset <= 3'd0;
      onthefly_count <= '0;
      write_count <= '0;
      write_reg <= 32'h0;
    end else begin
      if (clr_i) begin
        state <= S_IDLE;
        addr_offset <= '0;
        req_dis <= 1'b0;
        read_offset <= 3'd0;
        onthefly_count <= '0;
        write_count <= '0;
        write_reg <= 32'h0;
      end else begin
        // FSM
        state <= n_state;

        // Requests
        if (addr_offset != size_i & (transaction | req_dis)) begin
          addr_offset <= n_addr_offset;
          req_dis <= actual_addr[SIZE_WIDTH-1:2] == n_actual_addr[SIZE_WIDTH-1:2];
        end else if (done_o) begin
          addr_offset <= 16'h0;
          req_dis <= 1'b0;
        end

        // Monitor
        if (transaction & !master_resp_i.rvalid) begin
          onthefly_count <= onthefly_count + 1;
        end else if (!transaction & master_resp_i.rvalid) begin
          onthefly_count <= onthefly_count - 1;
        end

        // Read offset and write count
        if (state == S_IDLE & start_i) begin
          read_offset <= {1'b0, addr_i[1:0]};
          write_count <= '0;
        end else if (valid_o & ready_i) begin
          read_offset <= n_read_offset;
        end else if (valid_i & ready_o) begin
          read_offset <= n_read_offset;
          write_count <= n_write_count;
        end

        // Write packer
        if (valid_i & ready_o) begin
          if (sew_i == 3'd3) begin
            if (read_offset[1:0] == 2'b00) begin
              write_reg[7:0] <= data_i[7:0];
            end else if (read_offset[1:0] == 2'b01) begin
              write_reg[15:8] <= data_i[7:0];
            end else if (read_offset[1:0] == 2'b10) begin
              write_reg[23:16] <= data_i[7:0];
            end
          end else if (sew_i == 3'd4) begin
            if (read_offset[1:0] == 2'b00) begin
              write_reg[15:0] <= data_i[15:0];
            end
          end
        end
      end
    end
  end

  assign req_condition = (!rw_i & (ADDR_DEPTH)'(FIFO_DEPTH-1) > read_data_count + onthefly_count) |
                          (rw_i & !write_empty);

  // FSM evaluation
  always_comb begin
    n_state = S_IDLE;
    master_req_o.req = 1'b0;
    done_o = 1'b0;

    unique case (state)
      S_IDLE: begin
        if (start_i) begin
          n_state = S_MREQ;
        end else begin
          n_state = S_IDLE;
        end
      end
      S_MREQ: begin
        if (addr_offset == size_i) begin
          if (read_empty & onthefly_count == '0) begin
            n_state = S_IDLE;
            done_o  = 1'b1;
          end else begin
            n_state = S_MREQ;
          end
        end else begin
          n_state = S_MREQ;
          master_req_o.req = req_condition & !req_dis;
        end
      end
    endcase
  end

  // Byte enable generation
  assign addr_lsb = 2'(addr_i[1:0] + size_i[1:0]);

  always_comb begin
    be = 4'b0000;
    last_be = 4'b0000;

    case (sew_i)
      // SEW = 8 bits
      3'd3: begin
        if (stride_i == STRD_WIDTH'(1)) begin
          unique case (actual_addr[1:0])
            2'd0: be = 4'b1111;
            2'd1: be = 4'b1110;
            2'd2: be = 4'b1100;
            2'd3: be = 4'b1000;
          endcase

          unique case (addr_lsb)
            2'd0: last_be = 4'b1111;
            2'd1: last_be = 4'b0001;
            2'd2: last_be = 4'b0011;
            2'd3: last_be = 4'b0111;
          endcase

        end else if (stride_i == STRD_WIDTH'(2)) begin
          unique case (actual_addr[1:0])
            2'd0: be = 4'b0101;
            2'd1: be = 4'b1010;
            2'd2: be = 4'b0100;
            2'd3: be = 4'b1000;
          endcase

          if (addr_i[0] == 1'b0) begin
            last_be = (addr_lsb == 2'b00) ? 4'b0101 : 4'b0001;
          end else begin
            last_be = (addr_lsb == 2'b00) ? 4'b1010 : 4'b0010;
          end

        end else if (stride_i == STRD_WIDTH'(3)) begin
          unique case (actual_addr[1:0])
            2'd0: be = 4'b1001;
            2'd1: be = 4'b0010;
            2'd2: be = 4'b0100;
            2'd3: be = 4'b1000;
          endcase

          unique case (addr_lsb)
            2'd0: last_be = 4'b0010;
            2'd1: last_be = 4'b0100;
            2'd2: last_be = 4'b1001;
            2'd3: last_be = 4'b0001;
          endcase

        end else begin
          unique case (actual_addr[1:0])
            2'd0: be = 4'b0001;
            2'd1: be = 4'b0010;
            2'd2: be = 4'b0100;
            2'd3: be = 4'b1000;
          endcase

          last_be = be;
        end
      end

      // SEW = 16 bits
      3'd4: begin
        if (stride_i == STRD_WIDTH'(2)) begin
          unique case (actual_addr[1])
            1'b0: be = 4'b1111;
            1'b1: be = 4'b1100;
          endcase

          last_be = addr_lsb[1] == 1'b0 ? 4'b1111 : 4'b0011;

        end else begin
          unique case (actual_addr[1])
            1'b0: be = 4'b0011;
            1'b1: be = 4'b1100;
          endcase

          last_be = be;
        end
      end

      // SEW = 32 bits
      3'd5: begin
        be = 4'b1111;
        last_be = be;
      end

      // Invalid SEW
      default: begin
        be = 4'b0000;
        last_be = 4'b0000;
      end
    endcase
  end

  // Buffers
  assign fifo_transaction = stride_i > STRD_WIDTH'(3) | stride_i[1:0] == 2'b00 |
    read_offset[2] != n_read_offset[2];

  // Write buffer
  fifo_v3 #(
    .FALL_THROUGH(1'b0),
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(FIFO_DEPTH)
  ) write_fifo (
    .clk_i     (clk_i),
    .rst_ni    (rst_ni),
    .flush_i   (clr_i),
    .testmode_i(1'b0),
    .usage_o   (),
    .data_i    (write_data),
    .push_i    (write_push),
    .full_o    (write_full),
    .data_o    (master_req_o.wdata),
    .pop_i     (rw_i & transaction),
    .empty_o   (write_empty)
  );

  assign write_push = valid_i & ready_o & (fifo_transaction | n_write_count == size_i);

  always_comb begin
    write_data = data_i;

    if (sew_i == 3'd3) begin
      if (read_offset[1:0] == 2'b00) begin
        write_data = data_i;
      end else if (read_offset[1:0] == 2'b01) begin
        write_data = {'0, data_i[7:0], write_reg[7:0]};
      end else if (read_offset[1:0] == 2'b10) begin
        write_data = {'0, data_i[7:0], write_reg[15:0]};
      end else begin
        write_data = {data_i[7:0], write_reg};
      end
    end else if (sew_i == 3'd4) begin
      if (read_offset[1:0] == 2'b00) begin
        write_data = data_i;
      end else begin
        write_data = {data_i[15:0], write_reg[15:0]};
      end
    end
  end

  // Read buffer
  fifo_v3 #(
    .FALL_THROUGH(1'b0),
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(FIFO_DEPTH)
  ) read_fifo (
    .clk_i     (clk_i),
    .rst_ni    (rst_ni),
    .flush_i   (clr_i),
    .testmode_i(1'b0),
    .usage_o   (read_data_count),
    .data_i    (master_resp_i.rdata),
    .push_i    (master_resp_i.rvalid & !rw_i),
    .full_o    (),
    .data_o    (read_data),
    .pop_i     (read_pop),
    .empty_o   (read_empty)
  );

  assign read_pop = !read_empty & ready_i &
    (fifo_transaction | (addr_offset == size_i & read_data_count == 1 &
    onthefly_count == 0 & actual_addr[1:0] == n_read_offset[1:0]));

  // Data extraction
  always_comb begin
    // Byte selection
    unique case (read_offset[1:0])
      2'b00: read_data_8 = read_data[7:0];
      2'b01: read_data_8 = read_data[15:8];
      2'b10: read_data_8 = read_data[23:16];
      2'b11: read_data_8 = read_data[31:24];
    endcase

    // Halfword selection
    unique case (read_offset[1])
      1'b0: read_data_16 = read_data[15:0];
      1'b1: read_data_16 = read_data[31:16];
    endcase

    // Data expansion
    case (sew_i)
      3'd3:    data_o = {(DATA_WIDTH-8)'(0), read_data_8};
      3'd4:    data_o = {(DATA_WIDTH-16)'(0), read_data_16};
      default: data_o = read_data;
    endcase
  end

  // Output ports assignments
  assign valid_o   = !read_empty;
  assign ready_o   = rw_i & !write_full & state == S_MREQ;
  assign byte_en_o = 4'b1111;

`ifndef SYNTHESIS
  // -------------------------------------------------------------------
  // Input contracts
  // -------------------------------------------------------------------

  // Captured parameters must stay stable from the cycle after start is
  // sampled through the cycle done is asserted (state == S_MREQ window).
  a_params_stable :
  assert property (@(posedge clk_i) disable iff (!rst_ni || clr_i) (state == S_MREQ) |-> $stable(
      {rw_i, addr_i, size_i, stride_i, sew_i}
  ))
  else $error("obione: rw_i/addr_i/size_i/stride_i/sew_i changed mid-transfer");

  // size_i must be a multiple of stride_i; otherwise addr_offset never
  // reaches size_i and the FSM hangs in S_MREQ forever.
  a_size_multiple_of_stride :
  assert property (@(posedge clk_i) disable iff (!rst_ni || clr_i)
    (state == S_IDLE && start_i) |-> ((size_i % stride_i) == '0))
  else $error("obione: size_i (%0d) is not a multiple of stride_i (%0d)", size_i, stride_i);

  // sew_i must encode a recognised element width: 3 = byte, 4 = halfword,
  // 5 = word. Other values silently fall through the data-extraction
  // mux's `default` branch and are easy to miss.
  a_sew_valid :
  assert property (@(posedge clk_i) disable iff (!rst_ni || clr_i)
    (state == S_IDLE && start_i) |-> (sew_i inside {3'd3, 3'd4, 3'd5}))
  else $error("obione: sew_i (%0d) not in {3,4,5}", sew_i);

  // addr_i must be aligned to the element width selected by sew_i:
  //   sew=3 (byte)     -> any alignment
  //   sew=4 (halfword) -> addr_i[0]   == 0
  //   sew=5 (word)     -> addr_i[1:0] == 0
  a_addr_alignment :
  assert property (@(posedge clk_i) disable iff (!rst_ni || clr_i)
    (state == S_IDLE && start_i) |->
      (sew_i == 3'd3) ||
      ((sew_i == 3'd4) && (addr_i[0] == 1'b0)) ||
      ((sew_i != 3'd3) && (sew_i != 3'd4) && (addr_i[1:0] == 2'b00)))
  else $error("obione: addr_i (0x%08h) not aligned to sew_i (%0d)", addr_i, sew_i);

  // stride_i must be a multiple of the element width selected by sew_i:
  //   sew=3 (byte)     -> any value
  //   sew=4 (halfword) -> stride_i[0]   == 0
  //   sew=5 (word)     -> stride_i[1:0] == 0
  a_stride_alignment :
  assert property (@(posedge clk_i) disable iff (!rst_ni || clr_i)
    (state == S_IDLE && start_i) |->
      (sew_i == 3'd3) ||
      ((sew_i == 3'd4) && (stride_i[0] == 1'b0)) ||
      ((sew_i != 3'd3) && (sew_i != 3'd4) && (stride_i[1:0] == 2'b00)))
  else $error("obione: stride_i (%0d) not aligned to sew_i (%0d)", stride_i, sew_i);

  // stride_i must be non-zero. Otherwise size_i % stride_i is undefined and
  // addr_offset never advances, hanging the FSM in S_MREQ.
  a_stride_nonzero :
  assert property (@(posedge clk_i) disable iff (!rst_ni || clr_i)
    (state == S_IDLE && start_i) |-> (stride_i != '0))
  else $error("obione: stride_i is zero");

  // addr_i + size_i must not wrap past 32-bit space. The end_addr computation
  // and last-word BE selection assume no wrap; an overflowing transfer would
  // misalign the last_be window and also straddle the 0/2^32 boundary on OBI.
  a_addr_no_overflow :
  assert property (@(posedge clk_i) disable iff (!rst_ni || clr_i)
    (state == S_IDLE && start_i) |->
      (({1'b0, addr_i} + {17'b0, size_i}) <= 33'h0_FFFF_FFFF))
  else $error("obione: addr_i (0x%08h) + size_i (%0d) overflows 32-bit space", addr_i, size_i);

  // -------------------------------------------------------------------
  // Internal invariants
  // -------------------------------------------------------------------

  // addr_offset never overshoots the configured span. If this fires, either
  // size_i % stride_i != 0 or there is an off-by-one in the increment guard.
  a_addr_offset_in_range :
  assert property (@(posedge clk_i) disable iff (!rst_ni || clr_i) addr_offset <= size_i)
  else $error("obione: addr_offset (%0d) exceeded size_i (%0d)", addr_offset, size_i);

  // FIFO occupancy plus on-the-fly OBI requests must never exceed the
  // FIFO depth — otherwise an incoming rvalid would have nowhere to land.
  a_inflight_bound :
  assert property (@(posedge clk_i) disable iff (!rst_ni || clr_i)
    (read_data_count + onthefly_count) <= FIFO_DEPTH-1)
  else
    $error(
        "obione: read_data_count (%0d) + onthefly_count (%0d) exceeds FIFO_DEPTH (%0d)",
        read_data_count,
        onthefly_count,
        FIFO_DEPTH
    );

  // Both internal FIFOs must be drained when done_o pulses; otherwise the
  // next transfer would inherit stale beats from the previous one.
  a_done_read_fifo_empty :
  assert property (@(posedge clk_i) disable iff (!rst_ni || clr_i) done_o |-> read_empty)
  else $error("obione: done_o asserted with read FIFO non-empty");

  a_done_write_fifo_empty :
  assert property (@(posedge clk_i) disable iff (!rst_ni || clr_i) done_o |-> write_empty)
  else $error("obione: done_o asserted with write FIFO non-empty");

  // FSM-side sanity: done_o and OBI requests can only originate from S_MREQ.
  a_done_in_mreq :
  assert property (@(posedge clk_i) disable iff (!rst_ni || clr_i) done_o |-> (state == S_MREQ))
  else $error("obione: done_o asserted outside S_MREQ");

  a_req_in_mreq :
  assert property (@(posedge clk_i) disable iff (!rst_ni || clr_i)
    master_req_o.req |-> (state == S_MREQ))
  else $error("obione: master_req_o.req asserted outside S_MREQ");

  // A write request with all byte-enables low is a silent no-op on the bus.
  // It always indicates either a BE-generation bug or a request that should
  // have been suppressed.
  a_be_nonzero_on_write_req :
  assert property (@(posedge clk_i) disable iff (!rst_ni || clr_i)
    (master_req_o.req && rw_i) |-> (master_req_o.be != 4'b0000))
  else $error("obione: write request issued with be == 4'b0000 (silent no-op)");

  // -------------------------------------------------------------------
  // Output contracts
  // -------------------------------------------------------------------

  // done_o is a single-cycle pulse so consumers can use rising-edge
  // detection without ambiguity.
  a_done_pulse :
  assert property (@(posedge clk_i) disable iff (!rst_ni || clr_i) done_o |=> !done_o)
  else $error("obione: done_o stayed high for more than one cycle");

  // When done_o pulses, the read pipeline must be fully drained: read FIFO
  // empty, no requests in flight, and the address counter at end-of-span.
  a_done_drained :
  assert property (@(posedge clk_i) disable iff (!rst_ni || clr_i)
    done_o |-> (read_empty && (onthefly_count == '0) && (addr_offset == size_i)))
  else
    $error(
        "obione: done_o asserted with read FIFO non-empty, requests in flight, or addr_offset != size_i"
    );
`endif

endmodule
