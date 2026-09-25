import sys
import pandas as pd


def main():
    print("=== DataOps Analytics ===")
    print(f"Python: {sys.version.split()[0]}")
    print(f"Pandas: {pd.__version__}")
    print("Ambiente configurado com sucesso!")


if __name__ == "__main__":
    main()