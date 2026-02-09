import argparse
import csv
import matplotlib.pyplot as plt

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", required=True, help="CSV file with samples")
    args = ap.parse_args()

    x = []
    y = []

    with open(args.csv, newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            x.append(int(row["index"]))
            y.append(int(row["value"]))

    plt.figure()
    plt.plot(x, y)
    plt.title("Raw Streamed Samples")
    plt.xlabel("Sample index")
    plt.ylabel("Value")
    plt.grid(True)
    plt.show()

if __name__ == "__main__":
    main()
