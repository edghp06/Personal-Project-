"""Echo test over a USB-UART adapter: send a few bytes, print what comes back.

Usage: python uart_serial.py --port COM3        (or /dev/ttyUSB0)
"""
import argparse
import time

import serial


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", default="COM3", help="Serial port, e.g. COM3 or /dev/ttyUSB0")
    ap.add_argument("--baud", type=int, default=115200)
    args = ap.parse_args()

    with serial.Serial(port=args.port, baudrate=args.baud, timeout=1) as ser:
        time.sleep(2)  # allow the board to reset after the port opens
        print(f"Connected to {args.port} at {args.baud} baud")

        for b in [0x3C, 0xA5, 0x55]:
            ser.write(bytes([b]))
            print(f"Sent: 0x{b:02X}")
            time.sleep(0.1)
            data = ser.read(1)
            print(f"Received: 0x{data[0]:02X}" if data else "Received: nothing (timeout)")


if __name__ == "__main__":
    main()
