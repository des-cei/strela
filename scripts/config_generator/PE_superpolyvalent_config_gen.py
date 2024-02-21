# Copyright 2024 CEI-UPM
# Daniel Vazquez (daniel.vazquez@upm.es)


import yaml


# Configuration
with open("PE_superpolyvalent_config.yaml", "r") as yamlfile:
    c = yaml.load(yamlfile, Loader=yaml.FullLoader)

# Processing Element
word_1_2 = c["fs_n"] + (c["fs_e"] << 6) + (c["fs_s"] << 12) + (c["fs_w"] << 18)
word_1_2 += (c["sel_n"] << 24) + (c["sel_e"] << 27) + (c["sel_s"] << 30) + (c["sel_w"] << 33)

word_1_2 += (c["sel_pc_1"] << 36) + (c["sel_pc_2"] << 39) + (c["sel_pc_c"] << 42) + (c["feedback"] << 44)
word_1_2 += (c["alu_sel"] << 45) + (c["cmp_sel"] << 49) + (c["out_sel"] << 50)  + (c["fs_pc"] << 52)
word_1_2 += (c["jm_mode"] << 58) + (c["initial_valid"] << 60)

word_1 = word_1_2 & 0xFFFFFFFF

word_2 = word_1_2 >> 32

word_3 = c["initial_data"]

word_4 = c["const"]

word_5 = c["delay_value"] + (c["position"] << 16) + (1 << 24)
word_5 += (c["ff_cgen_n"] << 26) + (c["ff_cgen_e"] << 27) + (c["ff_cgen_s"] << 28) + (c["ff_cgen_w"] << 29)
word_5 += (c["ff_cgen_pc_1"] << 30) + (c["ff_cgen_pc_2"] << 31)

print("\n")
print("Superpolivalent PE bitstream, position {}:".format(c["position"]))
print("0x{:08X}, 0x{:08X}, 0x{:08X}, 0x{:08X}, 0x{:08X}".format(word_1, word_2, word_3, word_4, word_5))
print("\n")