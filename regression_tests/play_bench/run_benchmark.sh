#!/usr/bin/env bash
#
# Benchmark PLAY kernels on RI5CY vs CV32E40P via RTL (QuestaSim).
#
# Usage:
#   ./run_benchmark.sh -c CV32E40P [-o O3] [-k matrix_mul,vector_add] [-r 1] [--skip-hw-build]
#
# See ./run_benchmark.sh --help for all options.

set -euo pipefail

# --------------------------------------------------------------------------
# Fixed locations / known-good toolchains (see benchmark setup notes)
# --------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"                 # PULP_CLUSTER repo root
PLAY_DIR="$SCRIPT_DIR/PLAY"
PULP_SDK_DIR="$SCRIPT_DIR/pulp-sdk"
TB_FILE="$ROOT_DIR/tb/pulp_cluster_tb.sv"
RESULTS_DIR="$SCRIPT_DIR/results"

RI5CY_TOOLCHAIN=/opt/riscv/pulp-gcc-1.0.16
CV32E40P_TOOLCHAIN=/opt/riscv/corev-openhw-gcc-modded-v0.3
QUESTA_MODULE=questa/2025.3

DEFAULT_KERNELS="vector_add,vector_dot,matrix_mul,matrix_trans,linalg_gemv,linalg_lu_decomp"

# --------------------------------------------------------------------------
# Defaults
# --------------------------------------------------------------------------
CORE=""
OPT="O3"
KERNELS="$DEFAULT_KERNELS"
REPEAT=1
MAX_CYCLES=5000000
NUM_CORES=8
SKIP_HW_BUILD=0
OUT_FILE=""

usage() {
    cat <<EOF
Uso: $(basename "$0") -c CORE [opzioni]

Obbligatorio:
  -c, --core CORE          RI5CY oppure CV32E40P

Opzioni:
  -o, --opt LEVEL          Livello di ottimizzazione del compilatore: O0 O1 O2 O3 Os (default: O3)
  -k, --kernels LIST       Lista separata da virgole di kernel PLAY da testare
                            (default: $DEFAULT_KERNELS)
                            Usa "all" per testare tutti i kernel disponibili in PLAY/test/.
  -r, --repeat N            Ripeti ogni kernel N volte (default: 1) -- utile per fare
                            piu' run in automatico ("una decina") senza intervento manuale.
  --max-cycles N            Limite cicli simulazione RTL (default: $MAX_CYCLES)
  --num-cores N              Core del cluster da usare per USE_CLUSTER (default: $NUM_CORES)
  --skip-hw-build            Non ricompilare l'RTL (usa una build gia' fatta in precedenza
                            per lo stesso core)
  --questa MODULE            Modulo Questa da caricare (default: $QUESTA_MODULE)
  -h, --help                  Mostra questo messaggio

Output:
  Un file .txt (tab-separated, apribile in Excel) con le colonne:
  core  toolchain  kernel  opt  run  cycles
  salvato in $RESULTS_DIR/
EOF
}

# --------------------------------------------------------------------------
# Parse args
# --------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--core) CORE="$2"; shift 2 ;;
        -o|--opt) OPT="$2"; shift 2 ;;
        -k|--kernels) KERNELS="$2"; shift 2 ;;
        -r|--repeat) REPEAT="$2"; shift 2 ;;
        --max-cycles) MAX_CYCLES="$2"; shift 2 ;;
        --num-cores) NUM_CORES="$2"; shift 2 ;;
        --skip-hw-build) SKIP_HW_BUILD=1; shift ;;
        --questa) QUESTA_MODULE="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Opzione sconosciuta: $1"; usage; exit 1 ;;
    esac
done

if [[ -z "$CORE" ]]; then
    echo "Errore: specifica --core RI5CY oppure --core CV32E40P"
    usage
    exit 1
fi

case "$CORE" in
    RI5CY)
        TOOLCHAIN="$RI5CY_TOOLCHAIN"
        TOOLCHAIN_NAME="pulp-gcc-1.0.16"
        SDK_CONFIG="$PULP_SDK_DIR/configs/pulp_cluster.sh"
        SV_CORETYPE="RI5CY"
        ;;
    CV32E40P)
        TOOLCHAIN="$CV32E40P_TOOLCHAIN"
        TOOLCHAIN_NAME="corev-openhw-gcc-modded-v0.3"
        SDK_CONFIG="$PULP_SDK_DIR/configs/pulp_cluster_cv32e40p.sh"
        SV_CORETYPE="CV32"
        ;;
    *)
        echo "Errore: core '$CORE' non valido (usa RI5CY o CV32E40P)"
        exit 1
        ;;
esac

if [[ ! -x "$TOOLCHAIN/bin/riscv32-unknown-elf-gcc" && ! -x "$TOOLCHAIN/bin/riscv64-unknown-elf-gcc" ]]; then
    echo "Errore: toolchain non trovata in $TOOLCHAIN"
    exit 1
fi

if [[ ! -f "$SDK_CONFIG" ]]; then
    echo "Errore: config pulp-sdk non trovata: $SDK_CONFIG"
    echo "(il submodule regression_tests/play_bench/pulp-sdk e' inizializzato? git submodule update --init)"
    exit 1
fi

# RI5CY needs the 'riscv' RTL package vendored via Bender -- check before
# spending time on a build that will fail at elaboration.
if [[ "$CORE" == "RI5CY" ]] && ! grep -qi 'name: *"riscv"' "$ROOT_DIR/Bender.lock" 2>/dev/null; then
    echo "Errore: il pacchetto RTL 'riscv' (core RI5CY) non risulta in Bender.lock."
    echo "Va aggiunto come dipendenza in Bender.yml e poi 'make checkout' prima di poter"
    echo "buildare l'hardware per RI5CY su questo repo."
    exit 1
fi

mkdir -p "$RESULTS_DIR"
if [[ -z "$OUT_FILE" ]]; then
    OUT_FILE="$RESULTS_DIR/benchmark_${CORE}_${OPT}_$(date +%Y%m%d_%H%M%S).txt"
fi

echo "============================================================"
echo " Core:        $CORE"
echo " Toolchain:   $TOOLCHAIN_NAME ($TOOLCHAIN)"
echo " Ottimizz.:   -$OPT"
echo " Kernel:      $KERNELS"
echo " Ripetizioni: $REPEAT"
echo " Output:      $OUT_FILE"
echo "============================================================"

# --------------------------------------------------------------------------
# 1) Set the core type in the RTL testbench
# --------------------------------------------------------------------------
echo "==> Imposto CoreType=$SV_CORETYPE in $(basename "$TB_FILE")"
sed -i -E "s/CoreType: pulp_cluster_package::(RI5CY|CV32|IBEX)/CoreType: pulp_cluster_package::${SV_CORETYPE}/" "$TB_FILE"
grep -n "CoreType:" "$TB_FILE"

# --------------------------------------------------------------------------
# 2) Build the hardware (RTL) for the selected core
# --------------------------------------------------------------------------
if [[ "$SKIP_HW_BUILD" -eq 0 ]]; then
    echo "==> Build hardware (RTL) per $CORE via QuestaSim ($QUESTA_MODULE)..."
    cd "$ROOT_DIR"
    # shellcheck disable=SC1091
    source /usr/share/Modules/init/bash 2>/dev/null || true
    module load "$QUESTA_MODULE"
    make compile
    make build
else
    echo "==> Salto la build hardware (--skip-hw-build)"
    module load "$QUESTA_MODULE" 2>/dev/null || true
fi

# --------------------------------------------------------------------------
# 3) Build + run each PLAY kernel, extract cycle counts
# --------------------------------------------------------------------------
echo -e "core\ttoolchain\tkernel\topt\trun\tcycles" > "$OUT_FILE"

if [[ "$KERNELS" == "all" ]]; then
    mapfile -t KLIST < <(find "$PLAY_DIR/test" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)
else
    IFS=',' read -ra KLIST <<< "$KERNELS"
fi

for raw_kernel in "${KLIST[@]}"; do
    kernel="$(echo "$raw_kernel" | xargs)"
    KDIR="$PLAY_DIR/test/$kernel"

    if [[ ! -d "$KDIR/pulp-open" ]]; then
        echo "!! Kernel '$kernel' non trovato (atteso in $KDIR/pulp-open) -- salto."
        continue
    fi

    echo "==> Compilo $kernel per $CORE (opt=-$OPT)..."
    (
        set -e
        set +u   # pulp-sdk's config scripts reference optional unset env vars
        # shellcheck disable=SC1090
        source "$SDK_CONFIG"
        set -u
        export PULP_RISCV_GCC_TOOLCHAIN="$TOOLCHAIN"
        cd "$KDIR"
        make clean TARGET=PULP_OPEN >/dev/null
        make build TARGET=PULP_OPEN USE_CLUSTER=1 NUM_CORES="$NUM_CORES" STATS=1 \
            "COMMON_CFLAGS=-${OPT}" > "$RESULTS_DIR/build_${CORE}_${kernel}_${OPT}.log" 2>&1
    ) || { echo "!! Build fallita per $kernel, vedi $RESULTS_DIR/build_${CORE}_${kernel}_${OPT}.log -- salto."; continue; }

    APP_NAME=$(grep -m1 -E '^APP\s*=' "$KDIR/Makefile" | sed -E 's/^APP\s*=\s*//' | xargs)
    ELF="$KDIR/pulp-open/BUILD/PULP/GCC_RISCV/$APP_NAME/$APP_NAME"
    if [[ ! -f "$ELF" ]]; then
        echo "!! ELF non trovato per $kernel ($ELF) -- salto."
        continue
    fi

    for ((i = 1; i <= REPEAT; i++)); do
        echo "==> [$kernel] run $i/$REPEAT su RTL ($CORE)..."
        LOGFILE="$RESULTS_DIR/sim_${CORE}_${kernel}_${OPT}_run${i}.log"
        (
            cd "$ROOT_DIR"
            # The repo's own 'run' target launches vsim interactively (no -c, no
            # -do "run -all"), meant for GUI use. Force batch/auto-run here so it
            # actually simulates instead of exiting at <EOF> with 0 cycles.
            make run elf-bin="$ELF" max_cycles="$MAX_CYCLES" test_case="" \
                target-options="" cl-bin="" \
                VSIM='vsim -c -do "run -all; quit -f"'
        ) > "$LOGFILE" 2>&1 || echo "!! simulazione terminata con errore, controlla $LOGFILE"

        CYCLES=$(grep -m1 -E '^\[0\] cycles:' "$LOGFILE" | grep -oE '[0-9]+$' || true)
        CYCLES="${CYCLES:-NA}"

        echo -e "${CORE}\t${TOOLCHAIN_NAME}\t${kernel}\t${OPT}\t${i}\t${CYCLES}" >> "$OUT_FILE"
        echo "    -> cicli: $CYCLES"
    done
done

echo "============================================================"
echo "Fatto. Risultati salvati in: $OUT_FILE"
echo "============================================================"
column -t -s $'\t' "$OUT_FILE" 2>/dev/null || cat "$OUT_FILE"
