// Copyright 2026 CEIMM-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

package cgra_pkg;

  typedef enum logic [2:0] {
    NORTH = 3'd0,
    EAST  = 3'd1,
    SOUTH = 3'd2,
    WEST  = 3'd3
  } config_border_t;

endpackage
