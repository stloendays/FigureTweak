# ---- settings ----
GROUP = "temperature"     # one ridge per group, the first at the top
VALUE = "rate"            # the measurements (one row each)
OVERLAP = 0.6             # how far each ridge reaches into the one above (0 = not at all)
BANDWIDTH = 0.0           # smoothing of the curves (0 = automatic)
XLABEL = "rate (a.u.)"
SHOW_MEDIAN = True
# ---- draw ----
ax = chart(left=16.0)
g, v = column(GROUP), column(VALUE, "number")
grps = unique(g)
lo, hi = np.nanmin(v), np.nanmax(v)
pad = (hi - lo) * 0.08 or 1.0
grid = np.linspace(lo - pad, hi + pad, 300)
data = [v[[i for i in range(len(g)) if g[i] == k]] for k in grps]
dens = [kde(d, grid, BANDWIDTH) for d in data]
peak = max(d.max() for d in dens) or 1.0
for j, (k, d) in enumerate(zip(grps, dens)):
    base, col = len(grps) - 1 - j, PALETTE[j % len(PALETTE)]
    top = base + d / peak * (1 + OVERLAP)
    ax.fill_between(grid, base, top, color=col, alpha=0.85, lw=0, zorder=2 + j)
    ax.plot(grid, top, color=INK, lw=0.6, zorder=2 + j)
    ax.plot([grid[0], grid[-1]], [base, base], color=INK, lw=0.4, zorder=2 + j)
    if SHOW_MEDIAN:
        m = np.nanmedian(data[j])
        ax.plot([m, m], [base, base + np.interp(m, grid, d) / peak * (1 + OVERLAP)], color=INK, lw=0.8, ls="--",
                zorder=2 + j)
ax.set_yticks([len(grps) - 1 - j for j in range(len(grps))], grps)
ax.tick_params(axis="y", length=0)
for s in ("left", "right", "top"):
    ax.spines[s].set_visible(False)
ax.set_xlim(grid[0], grid[-1])
ax.set_ylim(-0.1, len(grps) - 1 + (1 + OVERLAP) * 1.02)
ax.set_xlabel(XLABEL)
finish(ax)
