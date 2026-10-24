"""Demo Figure 1 (synthetic data): a response curve with a fitted line, and a ranked bar chart."""
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
from style import BLUE, GREEN, INK, ORANGE, Page  # noqa: E402

rng = np.random.default_rng(0)
pg = Page(160, 62)

a = pg.ax(14, 11, 62, 44)
T = np.linspace(300, 700, 13)
k = np.exp(-60e3 / 8.314 / T) * 1e6
for name, c, s in (("catalyst A", BLUE, 1.0), ("catalyst B", GREEN, 0.55)):
    y = k * s * (1 + 0.06 * rng.standard_normal(T.size))
    a.scatter(T, y, s=9, color=c, label=name, zorder=3)
    a.plot(T, k * s, color=c, lw=0.9)
a.set_yscale("log")
a.set_xlabel("temperature $T$ (K)")
a.set_ylabel("rate $r$ (mol s$^{-1}$ kg$^{-1}$)")
a.legend(loc="lower right")
a.text(320, k.max() * 0.4, "$E_a$ = 60 kJ mol$^{-1}$", fontsize=6, color=INK)
pg.letter("a", 2, 60)

b = pg.ax(98, 11, 58, 44)
names = ["Ru", "Fe", "Co", "Ni", "Mo"]
vals = np.array([4.2, 2.9, 2.1, 1.4, 0.8])
b.barh(names[::-1], vals[::-1], color=[ORANGE] + [BLUE] * 4, height=0.62)
b.set_xlabel("relative activity")
b.tick_params(axis="y", length=0)
for s in ("top", "right"):
    b.spines[s].set_visible(False)
pg.letter("b", 86, 60)

pg.save(HERE, "Fig1")
