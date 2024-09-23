echo "Generating RTL"
${PYTHON} ../../esl_epfl_x_heep/hw/vendor/pulp_platform_register_interface/vendor/lowrisc_opentitan/util/regtool.py -r -t ../rtl ./strela_regs.hjson
echo "Generating SW"
${PYTHON} ../../esl_epfl_x_heep/hw/vendor/pulp_platform_register_interface/vendor/lowrisc_opentitan/util/regtool.py --cdefines -o ../sw/strela_regs.h ./strela_regs.hjson
