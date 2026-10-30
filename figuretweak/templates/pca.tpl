# ---- settings ----
COLUMNS = ""              # descriptor columns, comma-separated; "" = every numeric column
GROUP = "family"          # colour by group, "" for one colour
LABEL = ""                # write this column next to each point, "" for none
STANDARDISE = True        # scale every column to unit variance first
SHOW_LOADINGS = True      # an arrow per column
ELLIPSES = True           # a 95 % ellipse per group
# ---- draw ----
from matplotlib.patches import Ellipse  # noqa: E402
ax = chart(left=15.0)
cols = numeric_columns(COLUMNS)
D = np.column_stack([column(c, "number") for c in cols])
ok = ~np.isnan(D).any(1)
D = D[ok]
D = D - D.mean(0)
if STANDARDISE:
    D = D / np.where(D.std(0, ddof=1) == 0, 1, D.std(0, ddof=1))
U, S, Vt = np.linalg.svd(D, full_matrices=False)
sc = U[:, :2] * S[:2]
var = S ** 2 / np.sum(S ** 2) * 100
g = [x for x, k in zip(column(GROUP), ok) if k] if GROUP else ["all"] * len(sc)
for j, k in enumerate(unique(g)):
    idx = [i for i in range(len(g)) if g[i] == k]
    col = PALETTE[j % len(PALETTE)]
    ax.scatter(sc[idx, 0], sc[idx, 1], s=16, color=col, edgecolor=INK, linewidths=0.3, label=k if GROUP else None,
               zorder=3)
    if ELLIPSES and len(idx) > 2:
        cv = np.cov(sc[idx].T)
        w, vec = np.linalg.eigh(cv)
        ang = np.degrees(np.arctan2(vec[1, 1], vec[0, 1]))
        ax.add_patch(Ellipse(sc[idx].mean(0), 2 * np.sqrt(5.991 * w[1]), 2 * np.sqrt(5.991 * w[0]), angle=ang,
                             facecolor=col, alpha=0.12, edgecolor=col, linewidth=0.8, zorder=2))
if LABEL:
    for t, (px, py) in zip([x for x, k in zip(column(LABEL), ok) if k], sc):
        ax.annotate(t, (px, py), xytext=(3, 2), textcoords="offset points", fontsize=SMALL)
ax.axhline(0, color="#d5d8de", lw=0.5, zorder=1)
ax.axvline(0, color="#d5d8de", lw=0.5, zorder=1)
if SHOW_LOADINGS:
    ld = Vt[:2].T
    f = np.abs(sc).max() / (np.abs(ld).max() or 1) * 0.8
    for name, (lx, ly) in zip(cols, ld * f):
        ax.annotate("", xy=(lx, ly), xytext=(0, 0), arrowprops=dict(arrowstyle="-|>", color=HIGHLIGHT, lw=0.7,
                                                                     shrinkA=0, shrinkB=0, mutation_scale=6))
        ax.text(lx * 1.1, ly * 1.1, name, color=HIGHLIGHT, ha="center", va="center", fontsize=SMALL)
ax.margins(0.08)
ax.set_xlabel("PC1 (%.1f %%)" % var[0])
ax.set_ylabel("PC2 (%.1f %%)" % var[1])
if GROUP:
    ax.legend(loc="best")
finish(ax)
