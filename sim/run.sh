#!/usr/bin/env bash
# Build and run one testbench with Icarus Verilog.
# Usage (from the repository root):  ./sim/run.sh <test>
# Waveforms (.vcd) are written to sim/build/; open them with GTKWave.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
build="$root/sim/build"
mkdir -p "$build"

case "${1:-}" in
    fx_mul)       files="sim/tb_fx_mul_q15.v rtl/fx_mul_q15.v" ;;
    uart_tx)      files="sim/tb_uart_tx.v rtl/uart_tx.v" ;;
    stream_demo)  files="sim/top_sim.v rtl/streamer.v rtl/uart_tx.v rtl/clock_enable.v" ;;
    uart_rx)      files="sim/tb_uart_rx.v rtl/uart_rx.v" ;;
    uart_echo)    files="sim/tb_uart_echo.v rtl/uart_echo.v rtl/uart_rx.v rtl/uart_tx.v" ;;
    uart_cmd)     files="sim/tb_uart_cmd.v rtl/uart_cmd.v" ;;
    sample_ram)   files="sim/tb_sample_ram.v rtl/sample_ram.v" ;;
    sample_buffer) files="sim/tb_sample_buffer.v rtl/sample_buffer.v rtl/sample_ram.v" ;;
    *)
        echo "usage: $0 {fx_mul|uart_tx|stream_demo|uart_rx|uart_echo|uart_cmd|sample_ram|sample_buffer}" >&2
        exit 1 ;;
esac

cd "$root"
for f in $files; do
    if [ ! -f "$f" ]; then
        echo "missing source: $f (not yet committed to the repository)" >&2
        exit 1
    fi
done

iverilog -g2012 -o "$build/$1.vvp" $files
cd "$build" && vvp -n "$1.vvp"
