# =============================================================================
# synth/scripts/run_synth.tcl - Logic synthesis of comp7485 (Fusion Compiler)
#
# Run from synth/work (after "source setup/env.sh"):
#   cd synth/work
#   fc_shell -f ../scripts/run_synth.tcl | tee ../reports/run_synth.log
#
# To use another clock period (default 20 ns, set in timing.tcl):
#   fc_shell -x "set T 2" -f ../scripts/run_synth.tcl
# =============================================================================

set_host_options -max_cores 4

# Design library and parasitic technology
source ../scripts/create_lib.tcl

#Read elaborate and link the RT
analyze -format vhdl ../../rtl/comp7485.vhd
elaborate      comp7485
set_top_module comp7485

#Constraints, routing directions and corner setup
source ../../constraints/timing.tcl
source ../../constraints/floorplan.tcl

set_parasitic_parameters -corner default \
                         -early_spec tlup_min \
                         -late_spec  tlup_max

# Match the process label of the SAED32 slow corner (avoids PVT-030)
set_process_label slow

# Synthesis: mapping &  logic optimization
compile_fusion -to logic_opto

# Reports
report_qor    > ../reports/qor.$T.rpt
report_area   > ../reports/area.$T.rpt
report_timing > ../reports/timing.$T.rpt
report_pvt    > ../reports/pvt.$T.rpt


# Outputs  Gate-level netlist (for gate-level simulation) and constraints (for P&R)
write_verilog ../outputs/comp7485.$T.v
write_sdc -output ../outputs/comp7485.$T.sdc

# Save the design library to disk (the "save game" we were missing yesterday)
save_lib

exit
