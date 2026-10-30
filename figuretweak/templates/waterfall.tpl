# ---- settings ----
STEP = "step"             # first row = starting total, then one row per change
CHANGE = "change"         # starting value, then signed changes
END_NAME = "total"        # name of the final total bar
XLABEL = "cost (USD t$^{-1}$)"
VALUE_FORMAT = "%+.3f"
# ---- draw ----
ax = chart(left=28.0, right=12.0)
s, d = column(STEP), column(CHANGE, "number")
start, n = d[0], len(d)
level = start
ax.barh(0, start, color=PALETTE[1], edgecolor=INK, linewidth=0.6, height=0.62, zorder=2)
ax.text(start, 0, "  %.3f" % start, va="center", ha="left", fontsize=SMALL, fontweight="bold")
for k in range(1, n):
    up = d[k] >= 0
    ax.barh(k, d[k], left=level, color=PALETTE[3] if up else PALETTE[1], edgecolor=INK, linewidth=0.5, height=0.62,
            alpha=0.8 if up else 0.55, zorder=2)
    ax.text(max(level, level + d[k]), k, "  " + VALUE_FORMAT % d[k], va="center", ha="left", fontsize=SMALL)
    level += d[k]
ax.barh(n, level, color=PALETTE[0], edgecolor=INK, linewidth=0.6, height=0.62, zorder=2)
ax.text(level, n, "  %.3f" % level, va="center", ha="left", fontsize=SMALL, fontweight="bold")
ax.axvline(start, color=PALETTE[1], lw=0.8, ls="--", zorder=1)
ax.set_yticks(range(n + 1), list(s) + [END_NAME])
ax.invert_yaxis()
levels = start + np.r_[0, np.cumsum(d[1:])]
lo, hi = levels.min(), levels.max()
ax.set_xlim(max(0, lo - 0.25 * (hi - lo + 1e-9)), hi + 0.25 * (hi - lo + 1e-9))
ax.set_xlabel(XLABEL)
for t in ax.get_yticklabels()[:1] + ax.get_yticklabels()[-1:]:
    t.set_fontweight("bold")
finish(ax)
