// Copyright 2026 CEIMM-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module ash #(
  parameter int A_width  = 32,
  parameter int SH_width = 6
) (
  input  logic [ A_width-1:0] A,
  input  logic                DATA_TC,
  input  logic [SH_width-1:0] SH,
  input  logic                SH_TC,
  output logic [ A_width-1:0] B
);

  wire signed  [ A_width-1:0] A_s = A;
  wire         [ A_width-1:0] A_u = A;

  wire signed  [SH_width-1:0] SH_s = SH;
  wire         [SH_width-1:0] SH_u = SH;

  wire                        dir_right = (SH_TC && (SH_s < 0));

  int unsigned                sh_mag_raw;
  /* verilator lint_off WIDTHEXPAND */
  always_comb begin
    if (SH_TC) begin
      sh_mag_raw = (SH_s < 0) ? int'(-SH_s) : int'(SH_s);
    end else begin
      sh_mag_raw = int'(SH_u);
    end
  end
  /* verilator lint_on WIDTHEXPAND */

  // Clamp a [0, A_width]
  int unsigned sh_mag;
  always_comb begin
    if (sh_mag_raw >= A_width) sh_mag = A_width;
    else sh_mag = sh_mag_raw;
  end

  // Keep the arithmetic shift in a self-determined signed context: inside the
  // ternary below the unsigned replication branch would demote A_s to unsigned
  // and make >>> behave as a logical shift.
  logic signed [A_width-1:0] A_sra;
  assign A_sra = A_s >>> sh_mag;

  always_comb begin
    if (dir_right) begin
      if (DATA_TC) begin
        B = (sh_mag >= A_width) ? {A_width{A_s[A_width-1]}} : A_sra;
      end else begin
        B = (sh_mag >= A_width) ? '0 : (A_u >> sh_mag);
      end
    end else begin
      B = (sh_mag >= A_width) ? '0 : (A_u << sh_mag);
    end
  end

endmodule
