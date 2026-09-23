
set_host_options -max_cores 4

open_lib   ../../synth/work/comp7485.dlib
open_block comp7485

if {[sizeof_collection [get_blocks -quiet comp7485_pnr]] > 0} {
    remove_blocks comp7485_pnr
}
copy_block -from comp7485 -to comp7485_pnr
open_block comp7485_pnr



initialize_floorplan -control_type core \
                     -shape R \
                     -side_length {8.36 8.36} \
                     -core_offset {2 2 2 2}


connect_pg_net

create_pg_ring_pattern ring_pattern \
    -horizontal_layer M3 -horizontal_width {0.5} \
    -vertical_layer   M2 -vertical_width   {0.5}

set_pg_strategy core_ring -core \
    -pattern {{name: ring_pattern} {nets: {VDD VSS}} {offset: {0.3 0.3}}}

create_pg_std_cell_conn_pattern std_cell_rail -layers {M1}

set_pg_strategy rail_strategy -core \
    -pattern {{name: std_cell_rail} {nets: {VDD VSS}}} \
    -extension {{stop: outermost_ring}}

compile_pg -strategies {core_ring rail_strategy}

place_opt

set_block_pin_constraints -self -allowed_layers {M2 M3} -sides {1 2 3 4}
place_pins -self

create_terminal -port [get_ports VDD] -layer M3 -boundary {{4.0 10.66} {8.0 11.16}}
create_terminal -port [get_ports VDD] -layer M3 -boundary {{4.0 1.20}  {8.0 1.70}}
create_terminal -port [get_ports VSS] -layer M3 -boundary {{4.0 11.28} {8.0 11.78}}
create_terminal -port [get_ports VSS] -layer M3 -boundary {{4.0 0.58}  {8.0 1.08}}

route_global
route_track
route_detail


create_stdcell_fillers -prefix FILLER \
    -lib_cells [get_lib_cells "*/SHFILL128_RVT */SHFILL64_RVT */SHFILL3_RVT */SHFILL2_RVT */SHFILL1_RVT"]

connect_pg_net

file mkdir ../reports
check_legality                                                    > ../reports/legality.rpt
check_routes                                                      > ../reports/check_routes.rpt
check_pg_connectivity -nets [get_nets -all {VDD VSS}] \
                      -check_std_cell_pins all                    > ../reports/pg_connectivity.rpt
check_pg_drc                                                      > ../reports/pg_drc.rpt

report_timing > ../reports/timing_post_route.rpt
report_qor    > ../reports/qor_post_route.rpt
report_area   > ../reports/area_post_route.rpt
report_power  > ../reports/power_post_route.rpt


file mkdir ../outputs 
write_gds        -units 1000 ../outputs/comp7485.gds
write_verilog    ../outputs/comp7485_pnr.v
write_def        ../outputs/comp7485_pnr.def
write_sdc        -output ../outputs/comp7485_pnr.sdc
write_parasitics -output ../outputs/comp7485_pnr.spef -format spef

save_lib
exit
