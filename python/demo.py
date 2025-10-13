from __future__ import annotations

import math
from sim.game import GameSim


def simple_policy(obs) -> int:
    # Glide when ascending (yvel < 0) to flatten trajectory a bit, release when falling
    x, y, xvel, yvel = obs
    return 1 if yvel < 0 and xvel > 0 else 0


def run_episode():
    sim = GameSim()

    # Reproduce a reasonable launch: Game.shoot computes force_like ~= 90 - f
    # We'll just pick an initial speed magnitude and angle.
    force_like = 60.0  # try 60 px/frame magnitude similar to original scale
    angle_deg = 45.0
    sim.shoot(force_like=force_like, angle_rad=math.radians(angle_deg))

    total_reward = 0.0
    steps = 0
    while True:
        obs, r, done, info = sim.step(simple_policy(sim._observe()))
        total_reward += r
        steps += 1
        if done or steps > 2000:
            break

    # Distance in feet approximation
    x, y, xvel, yvel = sim._observe()
    distance_ft = x / 100.0
    print(f"Episode done in {steps} steps. Distance ~ {distance_ft:.2f} ft, reward {total_reward:.2f}")


if __name__ == "__main__":
    run_episode()
