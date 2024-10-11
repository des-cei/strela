// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module control_unit 
  import cgra_pkg::*;
(
  // Clock and reset
  input  logic  clk_i,
  input  logic  rst_ni,

  // Control input
  input  logic  start_i,
  input  logic  conf_change_i,
  input  logic  conf_done_i,
  input  logic  mn_done_i,

  // Control output
  output logic  clr_mn_o,
  output logic  clr_cgra_o,
  output logic  conf_needed_o,
  output logic  exec_o,
  output logic  intr_o,

  // State
  output main_fsm_t state_o
);

  main_fsm_t state, n_state;
  logic conf_done_reg;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      conf_done_reg <= 1'b0;
    end else begin
      if (conf_change_i) begin
        conf_done_reg <= 1'b0;
      end else if (conf_done_i) begin
        conf_done_reg <= 1'b1;
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state <= S_MAIN_IDLE;
    end else begin
      if (start_i || state != S_MAIN_IDLE) begin
        state <= n_state;
      end
    end
  end

  always_comb
  begin
    n_state    = S_MAIN_IDLE;

    unique case (state)
      S_MAIN_IDLE:
      begin
        if (start_i) begin
          if (conf_done_reg) begin
            n_state = S_MAIN_EXEC;
          end else begin
            n_state = S_MAIN_WAIT;
          end
        end else begin
          n_state = S_MAIN_IDLE;
        end
      end
      S_MAIN_WAIT: 
      begin
        if (conf_done_i) begin // conf_done_reg??
          n_state = S_MAIN_EXEC;
        end else begin
          n_state = S_MAIN_WAIT;
        end
      end
      S_MAIN_EXEC:
      begin
        if (mn_done_i) begin
          n_state = S_MAIN_DONE;
        end else begin
          n_state = S_MAIN_EXEC;
        end
      end
      S_MAIN_DONE:
      begin
        n_state = S_MAIN_IDLE;
      end
      default: n_state = S_MAIN_IDLE;
    endcase
  end

  assign exec_o = state == S_MAIN_EXEC;
  assign intr_o = state == S_MAIN_DONE;
  assign clr_mn_o = state == S_MAIN_DONE;
  assign clr_cgra_o = (conf_done_i & !conf_done_reg) || state == S_MAIN_DONE;
  assign conf_needed_o = !conf_done_reg;
  assign state_o = state;

endmodule
