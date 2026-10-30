# ---- settings ----
VALUE = "value"           # the values (one row each)
GROUP = "group"           # one curve per group, "" for a single curve
FILL = True               # shade under each curve
BANDWIDTH = 0.0           # smoothing (0 = automatic)
SHOW_RUG = False          # a tick under the axis for every value
XLABEL = "value"
YLABEL = "density"
# ---- draw ----
ax = chart()
v = column(VALUE, "number")
g = column(GROUP) if GROUP else ["all"] * len(v)
lo, hi = np.nanmin(v), np.nanmax(v)
pad = (hi - lo) * 0.1 or 1.0
grid = np.linspace(lo - pad, hi + pad, 300)
for j, k in enumerate(unique(g)):
    d = v[[i for i in range(len(v)) if g[i] == k]]
    d = d[~np.isnan(d)]
    col = PALETTE[j % len(PALETTE)]
    y = kde(d, grid, BANDWIDTH)
    ax.plot(grid, y, color=col, lw=1.2, label=k if GROUP else None, zorder=3)
    if FILL:
        ax.fill_between(grid, 0, y, color=col, alpha=0.2, lw=0, zorder=2)
    if SHOW_RUG:
        ax.plot(d, np.zeros(len(d)), "|", color=col, ms=4, mew=0.6, zorder=4)
ax.set_xlim(grid[0], grid[-1])
ax.set_ylim(bottom=0)
ax.set_xlabel(XLABEL)
ax.set_ylabel(YLABEL)
if GROUP:
    ax.legend(loc="upper right")
finish(ax)
