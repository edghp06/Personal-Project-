# FPGA Signal Processing Unit

## Overview
This project implements an FPGA-based signal processing unit.
The initial goal is to design a single-channel spectrum analyser,
with a longer-term objective of extending the system to multichannel
processing and vector analysis (magnitude and phase).

## Motivation
The project focuses on practical FPGA-based digital signal processing,
including fixed-point arithmetic, buffering, and frequency-domain analysis.
It is intended as a learning and research-oriented project aligned with
telecommunications and measurement systems.

## Hardware
- FPGA board: Tang Nano
- ADC: To be selected (Analog Devices)
- PC interface: UART (USB serial)

## Project Structure
- rtl/     Verilog RTL modules
- sim/     Testbenches and simulations
- python/  Verification, modelling, and plotting scripts
- docs/    Notes, diagrams, and design decisions

## Current Status
Early development: architecture definition and foundational setup.
