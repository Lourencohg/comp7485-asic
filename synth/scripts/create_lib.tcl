
# Loading the environment
if {![info exists ::env(PDK_ROOT)]} {
    error "PDK_ROOT not set. Run 'source setup/env.sh' before fc_shell."
}

#  paths to SAED32
set PDK_ROOT $::env(PDK_ROOT)

# Technology file metal layers and design rules (1 poly, 9 metals)
set TECH_FILE   "$PDK_ROOT/tech/saed32nm_1p9m.tf"

# Parasitic models (TLU+): wire resistance/capacitance, worst and best case
set TLUPLUS_MAX "$PDK_ROOT/tech/saed32nm_1p9m_Cmax.lv.tluplus"
set TLUPLUS_MIN "$PDK_ROOT/tech/saed32nm_1p9m_Cmin.lv.tluplus"



# Layer map: links layer names in the .tf to the names in the TLU+ files
set MAP_FILE    "$PDK_ROOT/tech/saed32nm_tf_itf_tluplus.map"



# Reference library: RVT cells (logic, timing and physical views in one .ndm)
set REF_LIBS [list "$PDK_ROOT/CLIBs/saed32_rvt.ndm"]


# create the design library
set DESIGN_LIB comp7485.dlib


if {[file exists $DESIGN_LIB]} {
    file delete -force $DESIGN_LIB
}

create_lib $DESIGN_LIB \
    -technology $TECH_FILE \
    -ref_libs   $REF_LIBS

# parasitic tech
read_parasitic_tech -tlup $TLUPLUS_MAX -layermap $MAP_FILE -name tlup_max
read_parasitic_tech -tlup $TLUPLUS_MIN -layermap $MAP_FILE -name tlup_min


