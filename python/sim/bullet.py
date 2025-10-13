import math
from dataclasses import dataclass


DEFAULT_GRAVITY = 0.99  # Flash coordinate system: +y is downward
DT = 0.05  # 50 ms per step to mirror setInterval(..., 50)


@dataclass
class Bullet:
    """
    Minimal port of default/Bullet.as for physics.

    Coordinate system is Flash-like:
    - x grows to the right
    - y grows downward
    - gravity > 0 pulls downward
    """

    x: float
    y: float
    vel: float
    ang_rad: float
    grav: float = DEFAULT_GRAVITY
    do_rotation: bool = True

    # runtime state
    xvel: float = 0.0
    yvel: float = 0.0
    ox: float = 0.0
    oy: float = 0.0
    hit: bool = False

    def __post_init__(self):
        # Match AS init(): xvel = sin(ang)*vel; yvel = (-cos(ang)) * vel
        self.xvel = math.sin(self.ang_rad) * self.vel
        self.yvel = (-math.cos(self.ang_rad)) * self.vel

    def update(self, dt: float = DT):
        """Integrate position with current velocities.

        AS code adds xvel/yvel per frame. To keep values consistent if dt != 0.05,
        scale by dt / 0.05.
        """
        scale = dt / DT
        self.ox, self.oy = self.x, self.y
        self.x += self.xvel * scale
        self.y += self.yvel * scale

    def increase_gravity(self):
        """
        AS: grav = -0.17 * xvel (applied when glide/grav button held)
        We expose it as a method; callers may invoke each step while held
        to reflect dependency on current xvel.
        """
        self.grav = -0.17 * self.xvel

    def restore_gravity(self):
        self.grav = DEFAULT_GRAVITY

    @staticmethod
    def radians_to_degrees(radians: float) -> float:
        return radians * 180.0 / math.pi
