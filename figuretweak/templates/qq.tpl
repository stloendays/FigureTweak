# ---- settings ----
VALUE = "residual"        # the values (one row each)
GROUP = ""                # one set of points per group, "" for one
STANDARDISE = True        # compare (x - mean) / s.d. with the standard normal
SHOW_LINE = True          # reference line
XLABEL = "theoretical quantiles"
YLABEL = "sample quantiles"
# ---- draw ----
from statistics import NormalDist  # noqa: E402
ax = chart()
v = column(VALUE, "number")
g = column(GROUP) if GROUP else ["all"] * len(v)
for j, k in enumerate(unique(g)):
    d = np.sort(v[[i for i in range(len(v)) if g[i] == k]])
    d = d[~np.isnan(d)]
    if STANDARDISE:
        d = (d - d.mean()) / (d.std(ddof=1) or 1)
    th = np.array([NormalDist().inv_cdf((i + 0.5) / len(d)) for i in range(len(d))])
    col = PALETTE[j % len(PALETTE)]
    ax.scatter(th, d, s=9, color=col, edgecolor=INK, linewidths=0.3, zorder=3, label=k if GROUP else None)
    if SHOW_LINE:
        q1, q3 = np.percentile(d, [25, 75])
        t1, t3 = NormalDist().inv_cdf(0.25), NormalDist().inv_cdf(0.75)
        slope = (q3 - q1) / (t3 - t1)
        ax.plot(th[[0, -1]], q1 + slope * (th[[0, -1]] - t1), color=col if GROUP else HIGHLIGHT, lw=0.9, zorder=2)
ax.set_xlabel(XLABEL)
ax.set_ylabel(YLABEL)
if GROUP:
    ax.legend(loc="upper left")
finish(ax)
