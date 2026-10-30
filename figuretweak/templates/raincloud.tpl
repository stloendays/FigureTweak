# ---- settings ----
GROUP = "support"         # one cloud per group, the first at the top
VALUE = "TOF"             # the measurements (one row each)
XLABEL = "TOF (s$^{-1}$)"
BANDWIDTH = 0.0           # smoothing of the clouds (0 = automatic)
# ---- draw ----
ax = chart(left=16.0)
g, v = column(GROUP), column(VALUE, "number")
grps = unique(g)
rng = np.random.default_rng(1)
lo, hi = np.nanmin(v), np.nanmax(v)
pad = (hi - lo) * 0.06 or 1.0
grid = np.linspace(lo - pad, hi + pad, 300)
for j, k in enumerate(grps):
    d = v[[i for i in range(len(g)) if g[i] == k]]
    d = d[~np.isnan(d)]
    pos, col = len(grps) - 1 - j, PALETTE[j % len(PALETTE)]
    dens = kde(d, grid, BANDWIDTH)
    dens = dens / dens.max() * 0.42
    ax.fill_between(grid, pos + 0.08, pos + 0.08 + dens, color=col, alpha=0.75, lw=0, zorder=2)
    ax.plot(grid, pos + 0.08 + dens, color=INK, lw=0.5, zorder=3)
    q1, med, q3 = np.percentile(d, [25, 50, 75])
    w0, w1 = d[d >= q1 - 1.5 * (q3 - q1)].min(), d[d <= q3 + 1.5 * (q3 - q1)].max()
    ax.plot([w0, q1], [pos, pos], color=INK, lw=0.7, zorder=3)
    ax.plot([q3, w1], [pos, pos], color=INK, lw=0.7, zorder=3)
    ax.fill_between([q1, q3], pos - 0.05, pos + 0.05, facecolor="white", edgecolor=INK, lw=0.7, zorder=4)
    ax.plot([med, med], [pos - 0.05, pos + 0.05], color=INK, lw=1.3, zorder=5)
    ax.scatter(d, pos - 0.13 - rng.uniform(0, 0.17, len(d)), s=5, color=col, alpha=0.85, linewidths=0, zorder=3)
ax.set_yticks([len(grps) - 1 - j for j in range(len(grps))], grps)
ax.tick_params(axis="y", length=0)
ax.set_ylim(-0.45, len(grps) - 1 + 0.6)
ax.set_xlim(grid[0], grid[-1])
ax.set_xlabel(XLABEL)
finish(ax)
