import math
import random
from dataclasses import dataclass, field
from typing import Optional, Tuple, Dict, Union, List

from .bullet import Bullet, DT, DEFAULT_GRAVITY


GROUND_Y = 950.0  # In AS, collision check happens when next y >= 950
FRICTION_F = 0.6
SLIDE_F = 0.99
TERMINATE_XVEL = 1.0


@dataclass
class GameSim:
    """
    Headless physics port of Game.as focused on the projectile and ground
    interaction, suitable for RL.

    Scope:
    - Launch via shoot(force_like, angle_rad) consistent with AS Game.shoot
    - Step with optional actions: glide_button (bool) to emulate gravity hold
    - Physics: gravity, ground collision responses (normal, bounce, superbounce,
      slide, rebound limited), basic falling detection for glide toggle
    - Terminate when bullet has hit the ground and x velocity is small

    Out-of-scope (can be added later):
    - Powerups spawning and collisions
    - Camera/UI/SFX
    - Multi-shot turn management
    """

    # state flags
    bounce: bool = False
    superbounce: bool = False
    slide: bool = False
    rebound: bool = False
    skidding: bool = False
    falling: bool = False
    glide: bool = False
    # transient flags set by powerups
    speed: bool = False
    wind: bool = False
    # glide hold prevention
    glide_locked: bool = False
    last_glide_button: bool = False
    # minimum grav points required to unlock glide after depletion
    glide_unlock_threshold: int = 10

    # glide/grav points reservoir from AS; optional for RL
    grav_points: int = 100
    grav_points_max: int = 100

    # powerups
    powerups: List[Dict] = field(default_factory=list)
    powerup_mark: float = 650.0
    powerup_count: int = 0

    # moving object
    bullet: Optional[Bullet] = None

    # counters
    blt_num: int = 0

    # outputs / bookkeeping
    time: float = 0.0
    done: bool = False
    faceplant: bool = False

    def reset(self):
        self.__dict__.update(GameSim().__dict__)  # reset to defaults

    # --- Launch API ---
    def shoot(self, force_like: float, angle_rad: float, start_pos: Tuple[float, float] = (148.0, 956.0)):
        """
        Mirrors Game.shoot() semantics simplifying UI-dependent pieces.

        In AS, velocity magnitude uses: vel = (90 - f) with adjustments for yvel
        around launch. We accept `force_like` as a precomputed magnitude (like the
        computed 90 - f in Game.shoot) for simplicity, and `angle_rad` as the
        launch angle in radians.
        """
        self.faceplant = False
        self.done = False
        self.blt_num += 1
        x, y = start_pos
        self.bullet = Bullet(x=x, y=y, vel=force_like, ang_rad=angle_rad, grav=DEFAULT_GRAVITY)
        self.grav_points = self.grav_points_max
        self.time = 0.0

    # --- Step loop ---
    def step(self, action: Optional[Union[Dict[str, float], Tuple[int], int]] = None, dt: float = DT) -> Tuple[Tuple[float, float, float, float], float, bool, Dict]:
        """
        Step the simulation by dt seconds.
        Action formats supported:
        - None or 0/1: treated as glide_button
        - {'glide': 0/1}

        Returns: (obs, reward, done, info)
        obs = (x, y, xvel, yvel)
        reward = dx/100 per AS 'distance' notion (x per 100 px == 1 ft)
        done = termination flag
        info: dict with flags
        """
        if self.done:
            return self._observe(), 0.0, True, {}

        assert self.bullet is not None, "Call shoot() before step()"

        glide_button = self._parse_action(action)

        # Apply gravity/glide points logic with lock and edge detection so user
        # can't just hold the glide indefinitely. When grav points reach zero
        # we lock glide until grav_points recharges above glide_unlock_threshold
        can_use_glide = not self.glide_locked
        # rising edge detection available in last_glide_button
        if glide_button and not self.falling and can_use_glide:
            # apply gravity-hold effect
            self.bullet.increase_gravity()
            self.glide = True
            self._decrease_grav_points()
            # if reservoir exhausted, immediately stop glide and lock
            if self.grav_points <= 0:
                self.grav_points = 0
                self.bullet.restore_gravity()
                self.glide = False
                self.glide_locked = True
        else:
            # when not holding or locked, restore normal gravity and recharge
            self.bullet.restore_gravity()
            self.glide = False
            self._recharge_grav_points()
            # auto-unlock once we've recovered enough grav points and the user
            # has released the button (prevent auto-relock without release)
            if self.glide_locked and self.grav_points >= self.glide_unlock_threshold and not glide_button:
                self.glide_locked = False

        # remember button state for next step
        self.last_glide_button = bool(glide_button)

        # Apply gravity to velocity (unless in 'freemode', which we don't model)
        self.bullet.yvel += self.bullet.grav * (dt / DT)

        # Apply transient powerup effects that are executed immediately upon pickup
        if self.speed:
            # AS: speed adds to xvel once
            self.bullet.xvel += 20
            self.speed = False
        if self.wind:
            # AS: wind nudges velocities and toggles some visuals; apply immediate effect
            self.bullet.yvel -= 8
            self.bullet.xvel += 2
            self.wind = False
        if self.rebound:
            # AS: rebound gives a fixed kick and then clears
            self.bullet.xvel = 40
            self.bullet.yvel = -40
            self.rebound = False
            self.bullet.do_rotation = True
            self.bullet.hit = False

        # friction to x: frame-rate independent
        self.bullet.xvel *= (0.99 ** (dt / DT))

        # falling detection used to auto-disable glide like AS
        if self.bullet.yvel > 50 and not (self.bounce or self.superbounce):
            if not self.falling:
                self.falling = True
        else:
            if self.falling:
                self.falling = False

        # Predict ground collision using next y
        next_y = self.bullet.y + self.bullet.yvel * (dt / DT)
        if next_y >= GROUND_Y and not self.rebound:
            self._handle_ground_collision()

        # Powerup generation (spawn ahead of camera/bullet)
        # Simple heuristic: when bullet is present and approaches the next mark
        if self.bullet is not None:
            # spawn when bullet.x + 600 reaches the mark (600 is screen width used in AS)
            if self.bullet.x + 600 >= self.powerup_mark:
                self._generate_powerup()

        # Check collisions between bullet and powerups
        if self.powerups:
            self._check_powerups_coll()

        # Integrate position
        prev_x = self.bullet.x
        self.bullet.update(dt)

        # Termination condition similar to Game.onUpdate
        if self.bullet.xvel < TERMINATE_XVEL and self.bullet.hit:
            self.done = True

        self.time += dt

        # Reward: delta distance in feet approximation (100 px ~ 1 ft in AS updateDistance)
        dx = max(0.0, self.bullet.x - prev_x)
        reward = dx / 100.0
        return self._observe(), reward, self.done, {
            "glide": self.glide,
            "falling": self.falling,
            "skidding": self.skidding,
            "ground": self.bullet.y >= GROUND_Y - 1e-6,
        }

    # --- Internals ---
    def _observe(self) -> Tuple[float, float, float, float]:
        b = self.bullet
        assert b is not None
        return (b.x, b.y, b.xvel, b.yvel)

    def _parse_action(self, action) -> bool:
        if action is None:
            return False
        if isinstance(action, int):
            return bool(action)
        if isinstance(action, tuple) or isinstance(action, list):
            return bool(action[0]) if action else False
        if isinstance(action, dict):
            return bool(action.get("glide", 0))
        return False

    # --- Powerups ---
    def _generate_powerup(self):
        """Spawn a powerup at the current powerup_mark x coordinate.

        Type distribution follows Game.as: random(11) with mapping
        0-1: bounce, 2-4: speed, 5-7: wind, 8: slide, 9: rebound, 10: superbounce
        """
        typ_idx = random.randrange(11)
        if typ_idx in (0, 1):
            typ = "bounce"
        elif typ_idx in (2, 3, 4):
            typ = "speed"
        elif typ_idx in (5, 6, 7):
            typ = "wind"
        elif typ_idx == 8:
            typ = "slide"
        elif typ_idx == 9:
            typ = "rebound"
        else:
            typ = "superbounce"

        x = float(self.powerup_mark)
        # y placement: rebound near ground, others can be high/varied
        if typ == "rebound":
            y = 930.0
        else:
            # emulate AS: 840 - random(1200)
            y = 840.0 - float(random.randrange(1200))

        pup = {"x": x, "y": y, "typ": typ, "id": self.powerup_count}
        self.powerups.append(pup)
        self.powerup_count += 1
        # advance mark similar to AS
        self.powerup_mark += 150

    def _check_powerups_coll(self):
        b = self.bullet
        assert b is not None
        # collision threshold (pixels)
        thr = 40.0
        remaining = []
        for p in self.powerups:
            if abs(b.x - p["x"]) < thr and abs(b.y - p["y"]) < thr:
                self._collect_powerup(p)
            else:
                remaining.append(p)
        self.powerups = remaining

    def _collect_powerup(self, p: Dict):
        t = p.get("typ")
        # Set simulation flags to be used by physics/logic
        if t == "bounce":
            self.bounce = True
            self.superbounce = False
        elif t == "speed":
            self.speed = True
        elif t == "wind":
            self.wind = True
        elif t == "slide":
            self.slide = True
        elif t == "rebound":
            self.rebound = True
        elif t == "superbounce":
            self.superbounce = True
        # Other bookkeeping (in AS visual/sound updates happen here) - omitted for headless sim

    def _decrease_grav_points(self):
        self.grav_points -= 10
        if self.grav_points <= 0:
            self.grav_points = 0
            # When exhausted, gravity reset in AS happens by caller not pressing; here we ensure no negative reservoir effect

    def _recharge_grav_points(self):
        self.grav_points += 1
        if self.grav_points > self.grav_points_max:
            self.grav_points = self.grav_points_max

    def _handle_ground_collision(self):
        b = self.bullet
        assert b is not None

        # Mark hit
        b.hit = True

        # Compute approach angle similar to Game.checkCollision
        dx = (b.x - b.ox) if b.ox or b.oy else b.xvel
        dy = (GROUND_Y - b.y) if b.ox or b.oy else b.yvel
        approach_rad = math.atan2(dy, dx)
        approach_deg = approach_rad * 180.0 / math.pi
        thresh = 70.0

        # Snap to ground
        b.y = GROUND_Y

        if approach_deg < thresh and not (self.bounce or self.superbounce or self.slide):
            # small angle impact -> normal bounce with friction
            b.xvel *= FRICTION_F
            b.yvel /= -2.0
            # start skidding if next step keeps on ground and velocities small-ish
            self.skidding = True
        elif self.bounce:
            b.xvel *= FRICTION_F
            b.yvel *= -0.6
            if b.yvel > -30:
                b.yvel = -30
            self.bounce = False
            b.hit = False
            self.skidding = False
        elif self.superbounce:
            b.xvel *= (1.0 + FRICTION_F)
            b.yvel *= -1.5
            if b.yvel > -50:
                b.yvel = -50
            self.superbounce = False
            b.hit = False
            self.skidding = False
        elif approach_deg > thresh:
            # faceplant/stop
            b.xvel = 0.0
            b.yvel = 0.0
            self.faceplant = True
            self.skidding = False
        elif self.slide and not self.skidding:
            b.xvel *= SLIDE_F
            b.yvel /= -2.0
            self.skidding = True
        elif self.slide and self.skidding:
            b.xvel *= SLIDE_F
            b.yvel /= -2.0
        else:
            b.xvel *= FRICTION_F
            b.yvel /= -2.0
            self.skidding = True
