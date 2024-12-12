# Copyright 2024 CEI-UPM
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
# Daniel Vazquez (daniel.vazquez@upm.es)

import yaml

# Configuration
with open("PE_config.yaml", "r") as yamlfile:
    c = yaml.load(yamlfile, Loader=yaml.FullLoader)

# Processing Element
# PE Input Port: Fork Senders
word_1_2 = c["fs_n"] + (c["fs_e"] << 6) + (c["fs_s"] << 12) + (c["fs_w"] << 18)
# PE Output Port: Multiplexers
word_1_2 += (c["sel_n"] << 24) + (c["sel_e"] << 27) + (c["sel_s"] << 30) + (c["sel_w"] << 33)
# FU
word_1_2 += (c["sel_pc_1"] << 36) + (c["sel_pc_2"] << 39) + (c["sel_pc_c"] << 42) + (c["feedback"] << 44)
word_1_2 += (c["alu_sel"] << 45) + (c["cmp_sel"] << 49) + (c["out_sel"] << 50)  + (c["fs_pc"] << 52)
word_1_2 += (c["jm_mode"] << 58) + (c["initial_valid"] << 60)

word_1 = word_1_2 & 0xFFFFFFFF
word_2 = word_1_2 >> 32

# FU: Initial data
word_3 = c["initial_data"]
# FU: constant operand
word_4 = c["const"]
# FU: delay value
word_5 = c["delay_value"]

# Elastic Buffer clock gates
word_5 += (c["ff_cgen_n"] << 26) + (c["ff_cgen_e"] << 27) + (c["ff_cgen_s"] << 28) + (c["ff_cgen_w"] << 29)
word_5 += (c["ff_cgen_pc_1"] << 30) + (c["ff_cgen_pc_2"] << 31)

print("\n")
print("PE configuration words:")
print("0x{:08X}, 0x{:08X}, 0x{:08X}, 0x{:08X}, 0x{:08X}".format(word_1, word_2, word_3, word_4, word_5))
print("\n")