# python/fixed_point.py
# Q1.15 fixed-point reference model

Q15_SCALE = 1 << 15
Q15_MAX   = 0x7FFF
Q15_MIN   = -0x8000

def q15_from_float(x: float) -> int:
    """Convert float (-1.0 to +1.0) to signed Q1.15"""
    if x >= 1.0:
        return Q15_MAX
    if x < -1.0:
        return Q15_MIN
    return int(x * Q15_SCALE)

def q15_to_float(x: int) -> float:
    """Convert signed Q1.15 to float"""
    return float(x) / Q15_SCALE

def q15_mul(a: int, b: int) -> int:
    """
    Q1.15 × Q1.15 → Q1.15
    Matches RTL: truncate after >>15
    """
    prod = a * b              # Q2.30
    y = prod >> 15            # truncate
    # wrap to 16-bit signed
    y &= 0xFFFF
    if y & 0x8000:
        y -= 0x10000
    return y

# -----------------------------
# Self-test (matches Day 20 TB)
# -----------------------------
if __name__ == "__main__":
    tests = [
        (0.5,   0.5),
        (1.0,   0.5),
        (-0.5,  0.5),
        (-0.5, -0.5),
        (1.0,   1.0),
    ]

    for a_f, b_f in tests:
        a_q = q15_from_float(a_f)
        b_q = q15_from_float(b_f)
        y_q = q15_mul(a_q, b_q)
        print(
            f"{a_f:+.3f} * {b_f:+.3f} = "
            f"{q15_to_float(y_q):+.6f} "
            f"(0x{y_q & 0xFFFF:04X})"
        )
