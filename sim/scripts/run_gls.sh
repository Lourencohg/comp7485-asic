#!/usr/bin/env bash
# =============================================================================
# sim/scripts/run_gls.sh
# Gate-level simulation of the synthesized netlist with Icarus Verilog.
#
# Prerequisites:
#   1. source setup/env.sh            (puts iverilog on PATH)
#   2. synthesis already run          (synth/outputs/comp7485.<T>.v exists)
#   3. cell functions already dumped  (sim/work/cell_functions.txt exists):
#        cd synth/work
#        fc_shell -f ../../sim/scripts/dump_cell_functions.tcl
#
# Usage (from anywhere inside the project):
#   bash sim/scripts/run_gls.sh          # uses T = 20
#   bash sim/scripts/run_gls.sh 2        # uses the netlist synthesized with T = 2
# =============================================================================
set -euo pipefail

SIM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJ_ROOT="$(dirname "$SIM_DIR")"

T="${1:-20}"                                   # clock period used in synthesis
NETLIST="$PROJ_ROOT/synth/outputs/comp7485.$T.v"
TB="$PROJ_ROOT/tb/tb_comp7485_gate.v"
FUNCS="$SIM_DIR/work/cell_functions.txt"
MODELS="$SIM_DIR/work/saed32_rvt_cells.v"      # generated: licensed data, not in git
WORK="$SIM_DIR/work"
OUT="$SIM_DIR/outputs"
REP="$SIM_DIR/reports"

mkdir -p "$WORK" "$OUT" "$REP"

# --- Checks -----------------------------------------------------------------
command -v iverilog >/dev/null || { echo "[ERROR] iverilog not found. Did you run: source setup/env.sh ?"; exit 1; }
[ -f "$NETLIST" ] || { echo "[ERROR] Netlist not found: $NETLIST"; echo "        Run the synthesis first."; exit 1; }
[ -f "$FUNCS" ]   || { echo "[ERROR] Cell functions not found: $FUNCS"; echo "        Run dump_cell_functions.tcl in fc_shell first."; exit 1; }

# --- 1. Generate the Verilog cell models from the library functions ---------
echo ">>> 1/3 Generating cell models from $(basename "$FUNCS")"
python3 "$SIM_DIR/scripts/gen_cell_models.py" "$FUNCS" "$MODELS"

# --- 2. Compile netlist + models + testbench --------------------------------
echo ">>> 2/3 Compiling the gate-level simulation"
iverilog -g2012 -o "$WORK/simv_gate" "$TB" "$NETLIST" "$MODELS"

# --- 3. Run ------------------------------------------------------------------
echo ">>> 3/3 Running the simulation"
cd "$OUT"                                      # the VCD is written here
vvp "$WORK/simv_gate" 2>&1 | tee "$REP/gate_sim.$T.log"

echo
if grep -q "GATE-LEVEL SIMULATION PASSED" "$REP/gate_sim.$T.log"; then
    echo "[PASS] The netlist matches the RTL on all 2048 input combinations."
    echo "       Log: sim/reports/gate_sim.$T.log"
else
    echo "[FAIL] See sim/reports/gate_sim.$T.log"
    exit 1
fi
