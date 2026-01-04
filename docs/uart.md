# UART Interface

## Purpose
The UART interface provides a simple control and observability channel between a PC and the FPGA.
It is used to read internal state during development and to control future subsystems such as
sample capture and FFT processing.

All functionality is verified in simulation before hardware use.

---

## Frame Format

### Request frame (PC → FPGA)
Each request is a fixed-length 6-byte frame:

| Byte | Name | Description |
|-----:|------|-------------|
| 0 | SOF | Start of frame (`0xA5`) |
| 1 | CMD | Command |
| 2 | ADDR | Register address |
| 3 | D0 | Data low byte |
| 4 | D1 | Data high byte |
| 5 | CHK | XOR checksum of bytes 0–4 |

---

### Response frame (FPGA → PC)
Each response is also a fixed-length 6-byte frame:

| Byte | Name | Description |
|-----:|------|-------------|
| 0 | SOF | Start of response (`0x5A`) |
| 1 | STATUS | Response status |
| 2 | ADDR | Address echo |
| 3 | D0 | Data low byte |
| 4 | D1 | Data high byte |
| 5 | CHK | XOR checksum of bytes 0–4 |

---

## Commands

| Command | Value | Description |
|--------:|-------|-------------|
| PING | `0x03` | Check link and return VERSION |
| READ | `0x02` | Read register at ADDR |

---

## Status Codes

| Status | Meaning |
|-------:|---------|
| `0x00` | OK |
| `0xE1` | Bad start-of-frame |
| `0xE2` | Bad checksum |
| `0xE3` | Invalid command |
| `0xE4` | Invalid address |

---

## Register Map

All registers are 16-bit and read-only unless stated otherwise.

| Address | Name | Access | Description |
|--------:|------|--------|-------------|
| `0x00` | ID | RO | Design identifier |
| `0x01` | VERSION | RO | Design version |
| `0x02` | STATUS | RO | Bit0 = error seen, Bit1 = last command valid |
| `0x03` | COUNTER_LO | RO | Cycle counter bits `[15:0]` |
| `0x04` | COUNTER_HI | RO | Cycle counter bits `[31:16]` |

The cycle counter is a free-running 32-bit counter that increments every clock cycle.

---

## Verification
The UART interface and register readback were verified in simulation using GTKWave.
Simulation confirmed:
- correct frame parsing
- correct response formatting
- correct error detection
- correct counter readback with increasing values between reads

## Notes
The UART interface is intended as the primary control and debug mechanism for future subsystems,
including sample buffers, FFT control, and multichannel expansion.
