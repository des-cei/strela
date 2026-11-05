#!/usr/bin/env bash
# Copyright 2026 CEIMM-UPM
# Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# Daniel Vazquez (daniel.vazquez@upm.es)

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PYTHON="${PYTHON:-python3}"

# Layouts seen in X-HEEP's vendored tree, newest first. The register-interface
# vendor directory was flattened at some point, so both spellings are tried.
REGTOOL_CANDIDATES=(
  "hw/vendor/pulp_platform/register_interface/vendor/lowrisc_opentitan/util/regtool.py"
  "hw/vendor/pulp_platform_register_interface/vendor/lowrisc_opentitan/util/regtool.py"
  "hw/vendor/lowrisc/opentitan/util/regtool.py"
)

# Roots to search, relative to this script: vendored inside GR-HEEP
# (hw/vendor/strela-v1 next to hw/vendor/x-heep), or a sibling checkout.
REGTOOL_ROOTS=("../../x-heep" "../../..")

if [ -z "${REGTOOL:-}" ]; then
  for root in "${REGTOOL_ROOTS[@]}"; do
    for rel in "${REGTOOL_CANDIDATES[@]}"; do
      if [ -f "$root/$rel" ]; then
        REGTOOL="$root/$rel"
        break 2
      fi
    done
  done
fi

if [ -z "${REGTOOL:-}" ] || [ ! -f "$REGTOOL" ]; then
  echo "error: regtool.py not found. Looked under:" >&2
  for root in "${REGTOOL_ROOTS[@]}"; do
    echo "  $root/{$(printf '%s,' "${REGTOOL_CANDIDATES[@]}" | sed 's/,$//')}" >&2
  done
  echo "Set REGTOOL=/path/to/regtool.py and re-run." >&2
  exit 1
fi

echo "Generating RTL"
"$PYTHON" "$REGTOOL" -r -t ../rtl ./strela_regs.hjson

echo "Generating SW"
"$PYTHON" "$REGTOOL" --cdefines -o ../sw/strela_regs.h ./strela_regs.hjson

# Format the generated RTL so that regenerating stays byte-identical to what is
# committed (the top-level `make verible` deliberately skips these files).
if command -v verible-verilog-format > /dev/null 2>&1; then
  echo "Formatting generated RTL"
  for file in ../rtl/strela_reg_pkg.sv ../rtl/strela_reg_top.sv; do
    verible-verilog-format "$file" --inplace \
      --formal_parameters_indentation indent --named_parameter_indentation indent \
      --named_port_indentation indent --port_declarations_indentation indent 2> /dev/null
  done
else
  echo "warning: verible-verilog-format not found, generated RTL left unformatted" >&2
fi
