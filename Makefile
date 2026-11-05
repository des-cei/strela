# Copyright 2026 CEIMM-UPM
# Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# Daniel Vazquez (daniel.vazquez@upm.es)

# Hand-written sources. The register block is formatted by
# data/gen_strela_regs.sh when it is regenerated, so that regeneration
# stays byte-identical to what is committed.
GENERATED_RTL := rtl/strela_reg_pkg.sv rtl/strela_reg_top.sv
RTL_FILES := $(filter-out $(GENERATED_RTL), \
               $(wildcard rtl/*.sv) $(wildcard sim/*.sv) \
               $(wildcard fpga/*.sv) $(wildcard wrapper/*.sv))

VERIBLE_FORMAT_FLAGS := --formal_parameters_indentation indent --named_parameter_indentation indent \
                        --named_port_indentation indent --port_declarations_indentation indent

.PHONY: all
all: help

## Regenerate the register block from data/strela_regs.hjson
.PHONY: regs
regs:
	cd data && bash gen_strela_regs.sh

## Format and lint the hand-written RTL
.PHONY: verible
verible:
	@for file in $(RTL_FILES); do \
		verible-verilog-format $$file --inplace $(VERIBLE_FORMAT_FLAGS) 2> /dev/null; \
		verible-verilog-lint $$file --lint_fatal=false --parse_fatal=false; \
	done

.PHONY: help
help:
	@echo "STRELA v1 - targets"
	@echo "  regs      = regenerate rtl/strela_reg_{pkg,top}.sv and sw/strela_regs.h"
	@echo "              from data/strela_regs.hjson"
	@echo "  verible   = format + lint rtl/, sim/, fpga/ and wrapper/"
	@echo ""
	@echo "This IP has no standalone simulation; it is verified from GR-HEEP."
