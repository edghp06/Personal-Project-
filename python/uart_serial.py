import serial
import time

# -----------------------------
# Serial configuration
# -----------------------------
PORT = "COM3"        # Change later (e.g. COM4, /dev/ttyUSB0)
BAUDRATE = 115200
TIMEOUT = 1          # seconds

# -----------------------------
# Open serial port
# -----------------------------
ser = serial.Serial(
    port=PORT,
    baudrate=BAUDRATE,
    timeout=TIMEOUT
)

time.sleep(2)  # Allow device reset (important for many boards)

print(f"Connected to {PORT} at {BAUDRATE} baud")

# -----------------------------
# Send and receive bytes
# -----------------------------
def send_byte(value):
    ser.write(bytes([value]))
    print(f"Sent: 0x{value:02X}")

def read_byte():
    data = ser.read(1)
    if data:
        value = data[0]
        print(f"Received: 0x{value:02X}")
        return value
    return None

# -----------------------------
# Echo test loop
# -----------------------------
try:
    test_bytes = [0x3C, 0xA5, 0x55]

    for b in test_bytes:
        send_byte(b)
        time.sleep(0.1)
        read_byte()

finally:
    ser.close()
    print("Serial port closed")
