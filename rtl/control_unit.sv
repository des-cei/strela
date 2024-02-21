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
  input  logic  clear_bs_i,
  input  logic  change_bs_i,
  input  logic  bs_done_i,
  input  logic  execute_done_i,

  // Control output
  output logic  clear_o,
  output logic  clear_core_o,
  output logic  execute_o,
  output logic  bs_needed_o,

  // State
  output main_fsm_t state_o
);

  main_fsm_t state, n_state;

  assign state_o = state;

  logic bs_done_reg;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if(~rst_ni) begin
      bs_done_reg <= 1'b0;
      state <= S_MAIN_IDLE;
    end else begin
      state <= n_state;
      if(clear_bs_i || change_bs_i) begin
        bs_done_reg <= 1'b0;
      end else if(bs_done_i) begin
        bs_done_reg <= 1'b1;
      end
    end
  end

  always_comb
  begin
    n_state    = S_MAIN_IDLE;
    clear_o       = 1'b1;
    execute_o     = 1'b0; 

    unique case (state)
      S_MAIN_IDLE:
      begin
        if(start_i) begin
          if(bs_done_reg) begin
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
        if(bs_done_i) begin // bs_done_reg??
          n_state = S_MAIN_EXEC;
        end else begin
          n_state = S_MAIN_WAIT;
        end
      end
      S_MAIN_EXEC:
      begin
        if(execute_done_i) begin
          n_state = S_MAIN_DONE;
        end else begin
          n_state = S_MAIN_EXEC;
        end
        execute_o = 1'b1;
      end
      S_MAIN_DONE:
      begin
        n_state = S_MAIN_IDLE;
        clear_o = 1'b0;
      end
      default: n_state = S_MAIN_IDLE;
    endcase
  end

  assign clear_core_o = !(bs_done_i & !bs_done_reg) & clear_o;
  assign bs_needed_o = !bs_done_reg;

endmodule
