"""Demo Supplementary Figure 1 (synthetic data): a distribution with a threshold."""
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
from style import BLUE, ORANGE, Page  # noqa: E402

x = np.random.default_rng(1).lognormal(-7, 1.1, 400)
pg = Page(88, 60)
a = pg.ax(14, 11, 70, 44)
a.hist(np.log10(x), bins=28, color=BLUE, alpha=0.85)
a.axvline(-3, color=ORANGE, lw=1.0)
a.annotate("threshold $10^{-3}$", xy=(-3, 30), xytext=(-2.4, 40), fontsize=6,
           arrowprops=dict(arrowstyle="-", lw=0.6))
a.set_xlabel("$\\log_{10}$ error")
a.set_ylabel("count")
pg.save(HERE, "FigS1")
