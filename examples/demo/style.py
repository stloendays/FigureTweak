"""House style for the demo figures: a Page laid out in millimetres, saved as svg/pdf/png.

This is the shape FigureTweak understands. "接入新论文" (onboarding) adds two lines to Page.save that call
tweak.apply, puts tweak.py next to this file, and re-renders every make_*.py.
"""
import os

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

RC = {"font.family": "Arial", "font.size": 7, "axes.linewidth": 0.6, "axes.labelsize": 7,
      "xtick.labelsize": 6.5, "ytick.labelsize": 6.5, "legend.fontsize": 6,
      "svg.fonttype": "none", "pdf.fonttype": 42, "legend.frameon": False}
BLUE, GREEN, ORANGE, INK = "#304c86", "#467238", "#d0843a", "#1b1b1b"


class Page:
    """A figure laid out in millimetres from its bottom-left corner."""

    def __init__(self, w_mm, h_mm):
        plt.rcParams.update(RC)
        self.W, self.H = w_mm, h_mm
        self.fig = plt.figure(figsize=(w_mm / 25.4, h_mm / 25.4))

    def ax(self, x, y, w, h, **kw):
        return self.fig.add_axes([x / self.W, y / self.H, w / self.W, h / self.H], **kw)

    def letter(self, ch, x, y):
        self.fig.text(x / self.W, y / self.H, ch, fontsize=9, fontweight="bold", va="top", ha="left")

    def save(self, here, stem):
        for ext in ("svg", "pdf", "png"):
            self.fig.savefig(os.path.join(here, "%s.%s" % (stem, ext)), dpi=300, facecolor="white")
        print("wrote %s.{svg,pdf,png}" % stem)
