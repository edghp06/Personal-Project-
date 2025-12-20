# Project Overview

## Spectrum Analyser

A spectrum analyser represents a signal in the frequency domain, showing
signal magnitude as a function of frequency. It is typically implemented
by sampling a time-domain signal and applying an FFT to obtain frequency
components.

In this project, the spectrum analyser will be implemented on an FPGA
using fixed-point arithmetic. The initial implementation will focus on a
single input channel and a small FFT size to validate the architecture.

## FFT-Based Spectrum Estimation

The FFT converts a block of N time-domain samples into N frequency bins.
The frequency resolution is determined by the sampling frequency and the
FFT size. The FFT output is complex-valued, and the magnitude is computed
from the real and imaginary components.

Windowing and averaging are common techniques used to improve spectral
estimation but will be considered after a basic working system is achieved.

## Vector Analysis and Coherent Sampling

A vector analyser measures both magnitude and phase of a signal relative
to a reference. Phase information is obtained from the complex FFT output.

For stable magnitude and phase measurements, coherent sampling is required.
This means that an integer number of signal periods fits exactly within the
FFT window, preventing spectral leakage and phase instability.

Vector analysis will be considered as a second stage of the project after
the spectrum analyser is operational.

## ADC Considerations

The ADC is responsible for sampling the analog input signal and providing
digital data to the FPGA. Important parameters include resolution, sampling
rate, number of channels, and output interface.

Multichannel ADCs with simultaneous sampling are preferred for phase and
vector measurements. Common digital interfaces include SPI, parallel CMOS,
and LVDS, each with different trade-offs in complexity and performance.

At this stage, no specific ADC is selected; the focus is on understanding
system-level requirements.
