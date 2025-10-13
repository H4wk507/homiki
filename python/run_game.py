"""Runner to start either headless demo or pygame UI.

Usage:
    python3 run_game.py --mode headless [--episodes N]
    python3 run_game.py --mode pygame
"""
from __future__ import annotations

import argparse
import sys


def main():
    p = argparse.ArgumentParser(description="Run homiki in headless or pygame mode")
    p.add_argument("--mode", choices=("headless", "pygame"), default="headless")
    p.add_argument("--episodes", type=int, default=1, help="Number of headless episodes to run")
    args = p.parse_args()

    if args.mode == "headless":
        # run demo.py episodes (local module)
        import demo as demo_mod
        for i in range(args.episodes):
            print(f"Running headless episode {i+1}/{args.episodes}")
            demo_mod.run_episode()
        return 0
    else:
        # run pygame UI
        try:
            from play import main as play_main
        except Exception as e:
            print("Failed to import pygame UI (is pygame installed and DISPLAY set?):", e)
            return 2
        return play_main()


if __name__ == "__main__":
    sys.exit(main())
