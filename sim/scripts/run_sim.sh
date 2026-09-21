#!/usr/bin/env bash
# =============================================================================
# sim/scripts/run_sim.sh
# RTL simulation of comp7485 with GHDL.
#
# Usage (from anywhere inside the project):
#   bash sim/scripts/run_sim.sh          # run the simulation
#   bash sim/scripts/run_sim.sh wave     # run and open GTKWave
# =============================================================================
set -euo pipefail

# Find folders from this script's location, so it works from any directory
SIM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJ_ROOT="$(dirname "$SIM_DIR")"

RTL="$PROJ_ROOT/rtl/comp7485.vhd"
TB="$PROJ_ROOT/tb/tb_comp7485.vhd"
TOP_TB=tb_comp7485

WORK="$SIM_DIR/work"        # GHDL compiled library (temporary, not in git)
OUT="$SIM_DIR/outputs"      # waveform
REP="$SIM_DIR/reports"      # log

mkdir -p "$WORK" "$OUT" "$REP"
command -v ghdl >/dev/null || { echo "[ERROR] ghdl not found (sudo dnf install ghdl)"; exit 1; }

cd "$WORK"

echo ">>> 1/3 Analysing (compiling) the VHDL files"
ghdl -a --std=08 --workdir="$WORK" "$RTL"
ghdl -a --std=08 --workdir="$WORK" "$TB"

echo ">>> 2/3 Elaborating $TOP_TB"
# GHDL_ELAB_FLAGS: optional extra flags, set in setup/env.sh when a machine
# needs them (e.g. the glibc compatibility object on Rocky Linux 9)
ghdl -e --std=08 --workdir="$WORK" ${GHDL_ELAB_FLAGS:-} "$TOP_TB"

echo ">>> 3/3 Running the simulation"
ghdl -r --std=08 --workdir="$WORK" "$TOP_TB" \
     --wave="$OUT/$TOP_TB.ghw" 2>&1 | tee "$REP/rtl_sim.log"

echo
if grep -q "SIMULATION PASSED" "$REP/rtl_sim.log"; then
    echo "[PASS] All vectors matched.  Log: sim/reports/rtl_sim.log"
else
    echo "[FAIL] See sim/reports/rtl_sim.log"
    exit 1
fi

if [ "${1:-}" = "wave" ]; then
    command -v gtkwave >/dev/null && gtkwave "$OUT/$TOP_TB.ghw" &
fi
