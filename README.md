# FPGA Signal Processing Unit

An FPGA-based signal processing unit for a Tang Nano 4K. The first goal is a
single-channel spectrum analyser; the longer-term aim is multichannel
processing and vector analysis (magnitude and phase).

The project focuses on practical FPGA digital signal processing: fixed-point
arithmetic, buffering and frequency-domain analysis, with a UART link to a PC
for control and plotting.

## Hardware

- FPGA board: Tang Nano 4K (Gowin GW1NSR-4C)
- ADC: to be selected (Analog Devices)
- PC interface: UART over an external USB-UART adapter

The Tang Nano 4K has no onboard USB-UART bridge, so UART is verified in
simulation; hardware output needs an adapter wired to a GPIO pin.

## Repository layout

| Folder | Contents |
| --- | --- |
| `rtl/` | Verilog design modules |
| `sim/` | Testbenches and `run.sh` |
| `python/` | Q1.15 reference model, stream parser, plotting and serial scripts |
| `python/examples/` | Example simulation output for the Python scripts |
| `docs/` | Architecture, overview, UART protocol and a waveform screenshot |

## RTL modules

| Module | Purpose |
| --- | --- |
| `clock_enable` | One-cycle enable pulse every `DIVIDER` clocks (baud tick) |
| `uart_tx` | 8N1 UART transmitter, advanced by `clk_en` |
| `streamer` | Sends a test frame: `0x55`, a 0–255 ramp, `0xAA` |
| `fx_mul_q15` | Signed Q1.15 × Q1.15 multiplier with truncation |
| `uart_echo` | Echoes received bytes back (needs `uart_rx`) |
| `top` (`top_fpga_dsp`) | Work-in-progress integration of UART, command parser and sample buffer |

## Running the simulations

Needs [Icarus Verilog](https://steveicarus.github.io/iverilog/) and, to view
waveforms, [GTKWave](https://gtkwave.sourceforge.net/). From the repository root:

```bash
./sim/run.sh fx_mul        # Q1.15 multiplier
./sim/run.sh uart_tx       # UART transmitter
./sim/run.sh stream_demo   # streamer + UART: 258 bytes at 115,200 baud
gtkwave sim/build/top_sim.vcd
```

Builds and waveforms go to `sim/build/`, which Git ignores.

The `uart_rx`, `uart_echo`, `uart_cmd`, `sample_ram` and `sample_buffer`
testbenches need `rtl/uart_rx.v`, `rtl/uart_cmd.v`, `rtl/sample_ram.v` and
`rtl/sample_buffer.v`, which are not committed yet.

## Python tools

```bash
pip install -r python/requirements.txt
python python/fixed_point.py                      # Q1.15 golden-model self-test
python python/receive_stream.py --file python/examples/stream_bytes.hex --length 16 --out samples.csv
python python/plot_samples.py --csv samples.csv
python python/uart_serial.py --port COM3          # echo test on hardware
```

The Python Q1.15 model is the golden reference for checking fixed-point DSP
blocks before RTL integration.

## Docs

- [Architecture](docs/architecture.md): data flow, fixed-point format, block roles, initial scope
- [Overview](docs/overview.md): spectrum and vector analysis, coherent sampling, ADC choices
- [UART interface](docs/uart.md): frame format, commands, status codes, register map
