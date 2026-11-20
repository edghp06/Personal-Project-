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

def extract_frame(bytes_in, length=None):
    """Return the payload between SOF and EOF.

    With `length`, take exactly that many payload bytes and check that EOF
    follows. Without it, stop at the first EOF byte; that is only safe when
    the payload never contains 0xAA. The streamer's 0..255 ramp does, so
    pass length=256 for it.
    """
    # find SOF
    i = 0
    while i < len(bytes_in) and bytes_in[i] != SOF:
        i += 1
    if i >= len(bytes_in):
        raise ValueError("SOF not found")

    i += 1  # skip SOF
    if length is not None:
        payload = bytes_in[i:i + length]
        if len(payload) < length:
            raise ValueError(f"expected {length} payload bytes, got {len(payload)}")
        if i + length >= len(bytes_in) or bytes_in[i + length] != EOF:
            raise ValueError("EOF not found after payload")
        return payload

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
    ap.add_argument("--length", type=int, default=None,
                    help="Payload length in bytes (256 for the streamer); "
                         "without it, parsing stops at the first 0xAA")
    args = ap.parse_args()

    raw = load_hex_bytes(args.file)
    payload = extract_frame(raw, args.length)

    print(f"Received {len(payload)} payload bytes")

    if args.out:
        with open(args.out, "w") as f:
            f.write("index,value\n")
            for i, b in enumerate(payload):
                f.write(f"{i},{b}\n")
        print(f"Wrote CSV to {args.out}")

if __name__ == "__main__":
    main()
