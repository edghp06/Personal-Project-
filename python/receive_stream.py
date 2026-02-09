import argparse

SOF = 0x55
EOF = 0xAA

def load_hex_bytes(path):
    data = []
    with open(path, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            if line.lower().startswith("0x"):
                line = line[2:]
            data.append(int(line, 16) & 0xFF)
    return data

def extract_frame(bytes_in):
    # find SOF
    i = 0
    while i < len(bytes_in) and bytes_in[i] != SOF:
        i += 1
    if i >= len(bytes_in):
        raise ValueError("SOF not found")

    i += 1  # skip SOF
    payload = []
    while i < len(bytes_in) and bytes_in[i] != EOF:
        payload.append(bytes_in[i])
        i += 1

    if i >= len(bytes_in):
        raise ValueError("EOF not found")

    return payload

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--file", required=True, help="Hex byte log from simulation")
    ap.add_argument("--out", default=None, help="Optional CSV output")
    args = ap.parse_args()

    raw = load_hex_bytes(args.file)
    payload = extract_frame(raw)

    print(f"Received {len(payload)} payload bytes")

    if args.out:
        with open(args.out, "w") as f:
            f.write("index,value\n")
            for i, b in enumerate(payload):
                f.write(f"{i},{b}\n")
        print(f"Wrote CSV to {args.out}")

if __name__ == "__main__":
    main()
