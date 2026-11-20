# System Architecture

## High-Level Data Flow

The system processes an analog input signal and produces a frequency-domain
representation using FPGA-based digital signal processing.

The high-level data flow is:

Analog Input
→ ADC
→ Sample Buffer
→ FFT Processing
→ Magnitude Calculation
→ PC Interface (UART)
→ Frequency Spectrum Display (Python)

---------------------------------------------------------------

Fixed-Point Representation
All DSP computations use signed Q1.15 fixed-point format. Input samples are normalised to ±1.
Intermediate multiplications produce Q2.30 results, which are scaled back to Q1.15 by right-shifting 15 bits.
FFT stages include per-stage scaling to prevent overflow while maintaining numerical stability.

---------------------------------------------------------------

## Functional Blocks

### ADC Interface
Receives digitised samples from the ADC and presents them to the FPGA
processing pipeline. The ADC provides synchronous samples at a fixed
sampling frequency.

### Sample Buffer
Stores a block of N samples required for FFT processing. Once the buffer
is full, the data is passed to the FFT block.

### FFT Processing
Computes the discrete Fourier transform of the buffered samples using a
fixed-point FFT architecture. The output is complex-valued frequency data.

### Magnitude Calculation
Computes the magnitude of each FFT bin from its real and imaginary
components to produce a frequency spectrum.

### PC Interface
Streams the magnitude spectrum to a host PC via UART for visualisation
and further analysis.

### Control and Configuration
Handles configuration parameters such as sampling control, FFT size,
and start/stop commands via the PC interface.

------------------------------------------------------------------------------------------

## Initial Scope Decisions

- Single input channel
- Small FFT size (e.g. 64 or 128 points)
- Fixed-point arithmetic throughout
- No windowing or averaging in the first implementation
- PC-based plotting and analysis

------------------------------------------------------------------------------------------

