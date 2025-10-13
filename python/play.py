from __future__ import annotations

import math
import sys
from typing import Tuple

import pygame

from sim.game import GameSim, GROUND_Y


WIDTH, HEIGHT = 900, 600
FPS = 60


def world_to_screen(x: float, y: float, cam_x: float, cam_y: float) -> Tuple[int, int]:
    # Flash-style y positive down; keep same in screen space.
    return int(x - cam_x), int(y - cam_y)


def main():
    pygame.init()
    screen = pygame.display.set_mode((WIDTH, HEIGHT))
    pygame.display.set_caption("Homiki Physics - Simple UI")
    clock = pygame.time.Clock()

    sim = GameSim()
    angle_deg = 45.0
    speed = 60.0
    launched = False
    glide_hold = False

    cam_x = 0.0
    # Keep ground near bottom of the screen (margin ~ 50 px)
    cam_y = GROUND_Y - (HEIGHT - 50)

    font = pygame.font.SysFont(None, 20)

    running = True
    while running:
        dt = clock.tick(FPS) / 1000.0
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    running = False
                if event.key == pygame.K_RETURN and not launched:
                    sim.shoot(force_like=speed, angle_rad=math.radians(angle_deg))
                    launched = True
                if event.key == pygame.K_SPACE:
                    glide_hold = True
            elif event.type == pygame.KEYUP:
                if event.key == pygame.K_SPACE:
                    glide_hold = False
            elif event.type == pygame.MOUSEBUTTONDOWN:
                glide_hold = True
            elif event.type == pygame.MOUSEBUTTONUP:
                glide_hold = False

        # Continuous controls for angle and speed before launch
        keys = pygame.key.get_pressed()
        if not launched:
            if keys[pygame.K_LEFT]:
                angle_deg = max(5.0, angle_deg - 60.0 * dt)
            if keys[pygame.K_RIGHT]:
                angle_deg = min(85.0, angle_deg + 60.0 * dt)
            if keys[pygame.K_UP]:
                speed = min(120.0, speed + 60.0 * dt)
            if keys[pygame.K_DOWN]:
                speed = max(10.0, speed - 60.0 * dt)

        # Step simulation
        if launched and not sim.done:
            obs, r, done, info = sim.step(1 if glide_hold else 0, dt=min(dt, 0.05))
            # camera follows x; keep y so ground is visible
            x, y, xvel, yvel = obs
            cam_x = max(0.0, x - WIDTH * 0.3)
            # keep cam_y fixed to show ground
            cam_y = min(y - HEIGHT / 2, GROUND_Y - (HEIGHT - 50))
        elif sim.done:
            # allow restart with Enter
            if keys[pygame.K_RETURN]:
                sim.reset()
                launched = False
                glide_hold = False
                cam_x = 0.0

        # Render
        screen.fill((220, 235, 255))

        # Ground
        ground_y = int(950 - cam_y)
        pygame.draw.rect(screen, (70, 120, 70), pygame.Rect(0, ground_y, WIDTH, HEIGHT - ground_y))

        # Start position marker
        start_x, start_y = 148, 956
        sx, sy = world_to_screen(start_x, start_y, cam_x, cam_y)
        pygame.draw.circle(screen, (120, 120, 120), (sx, sy), 4)


        # Aim line while not launched
        if not launched:
            # draw a line showing the current aim direction
            length = 80
            ang_rad = math.radians(angle_deg)
            # Bullet uses sin for x, -cos for y
            ax = sx + int(math.sin(ang_rad) * length)
            ay = sy + int(-math.cos(ang_rad) * length)
            pygame.draw.line(screen, (80, 80, 200), (sx, sy), (ax, ay), 2)

        # Bullet
        if sim.bullet is not None:
            bx, by = world_to_screen(sim.bullet.x, sim.bullet.y, cam_x, cam_y)
            pygame.draw.circle(screen, (200, 50, 50), (bx, by), 6)

        # Powerups
        if getattr(sim, "powerups", None):
            for p in sim.powerups:
                px, py = world_to_screen(p["x"], p["y"], cam_x, cam_y)
                color = (180, 180, 60)
                if p["typ"] == "bounce":
                    color = (200, 100, 200)
                elif p["typ"] == "speed":
                    color = (255, 160, 0)
                elif p["typ"] == "wind":
                    color = (100, 200, 255)
                elif p["typ"] == "slide":
                    color = (120, 120, 120)
                elif p["typ"] == "rebound":
                    color = (255, 80, 80)
                elif p["typ"] == "superbounce":
                    color = (255, 220, 80)
                pygame.draw.circle(screen, color, (px, py), 8)

        # HUD
        hud_lines = [
            f"Angle: {angle_deg:.1f} deg",
            f"Speed: {speed:.1f}",
            f"Launched: {launched}",
            f"Glide button: {glide_hold}",
            f"Glide locked: {getattr(sim, 'glide_locked', False)}",
            f"Grav points: {getattr(sim, 'grav_points', 0)}/{getattr(sim, 'grav_points_max', 0)}",
            f"Distance ~ { (sim.bullet.x/100.0) if sim.bullet else 0.0:.1f} ft",
            "Controls: LEFT/RIGHT angle, UP/DOWN speed, ENTER launch, SPACE glide",
        ]
        for i, line in enumerate(hud_lines):
            img = font.render(line, True, (20, 20, 20))
            screen.blit(img, (10, 10 + i * 18))

        # Show nearest powerup type
        if getattr(sim, "powerups", None):
            if sim.powerups:
                # find first ahead of bullet/cam
                info_txt = f"Powerups: {', '.join(p['typ'] for p in sim.powerups[:4])}"
            else:
                info_txt = "Powerups: none"
            img = font.render(info_txt, True, (20, 20, 20))
            screen.blit(img, (10, 10 + (len(hud_lines) + 1) * 18))

        # Gravity meter bar (top-right)
        if sim is not None:
            max_w = 200
            h = 12
            pad = 10
            x0 = WIDTH - max_w - pad
            y0 = pad
            # background
            pygame.draw.rect(screen, (200, 200, 200), pygame.Rect(x0, y0, max_w, h), border_radius=3)
            # fill
            frac = (sim.grav_points / sim.grav_points_max) if sim.grav_points_max > 0 else 0
            w = int(max(0, min(1, frac)) * max_w)
            color = (80, 180, 80) if w > max_w * 0.3 else (200, 80, 80)
            pygame.draw.rect(screen, color, pygame.Rect(x0, y0, w, h), border_radius=3)
            txt = font.render("Grav", True, (20, 20, 20))
            screen.blit(txt, (x0 - 45, y0 - 2))

        pygame.display.flip()

    pygame.quit()
    return 0


if __name__ == "__main__":
    sys.exit(main())
