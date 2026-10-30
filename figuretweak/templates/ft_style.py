"""House style for figures made from FigureTweak templates in a paper that has no style.py of its own.

A Page is a matplotlib figure laid out in millimetres; Page.save re-applies the hand edits made in FigureTweak
(<stem>.tweaks.json, through tweak.apply) and writes svg, pdf and png. Copied next to a new figure as style.py.
"""
import os

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

INK, MID = "#1b1b1b", "#5f646c"
RU, FE, AMB, OS = "#5677b5", "#6e9f60", "#e0913a", "#97abd4"
DARK_B, DARK_G, AMB_D, OTHER, RED = "#304c86", "#467238", "#a85e24", "#b5b9c1", "#d9474f"

RC = {
    "font.family": "Arial", "font.size": 7, "axes.linewidth": 0.6,
    "axes.edgecolor": INK, "axes.labelcolor": INK, "text.color": INK,
    "xtick.color": INK, "ytick.color": INK, "xtick.labelsize": 6.5, "ytick.labelsize": 6.5,
    "xtick.direction": "in", "ytick.direction": "in",
    "xtick.major.size": 2.4, "ytick.major.size": 2.4, "xtick.minor.size": 1.3, "ytick.minor.size": 1.3,
    "xtick.major.width": 0.6, "ytick.major.width": 0.6, "xtick.minor.width": 0.5, "ytick.minor.width": 0.5,
    "axes.labelsize": 7, "axes.labelpad": 2.0, "legend.fontsize": 6, "legend.frameon": False,
    "mathtext.fontset": "custom", "mathtext.rm": "Arial", "mathtext.it": "Arial:italic",
    "mathtext.bf": "Arial:bold", "mathtext.default": "regular",
    "svg.fonttype": "none", "pdf.fonttype": 42,
}


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

    def save(self, here, stem, rerun_args=None):
        import tweak                            # hand adjustments from <stem>.tweaks.json (figure editor)
        tweak.apply(self.fig, here, stem, rerun_args)
        for ext in ("svg", "pdf", "png"):       # figure facecolour: white unless the editor changed the background
            self.fig.savefig(os.path.join(here, "%s.%s" % (stem, ext)), dpi=600, facecolor=self.fig.get_facecolor())
        print("wrote %s.{svg,pdf,png}  %.0f x %.0f mm" % (stem, self.W, self.H))
