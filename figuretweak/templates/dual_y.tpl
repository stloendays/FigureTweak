# ---- settings ----
X = "temperature"         # x values
Y1 = "conversion"         # left axis
Y2 = "selectivity"        # right axis
XLABEL = "temperature (K)"
Y1LABEL = "conversion (%)"
Y2LABEL = "selectivity (%)"
Y1_BARS = False           # True: the left series as bars
MARKERS = True
# ---- draw ----
ax = chart(right=14.0)
x, a, b = column(X, "number"), column(Y1, "number"), column(Y2, "number")
o = np.argsort(x)
c1, c2 = PALETTE[0], PALETTE[1 % len(PALETTE)]
if Y1_BARS:
    step = np.min(np.diff(np.unique(x))) if len(np.unique(x)) > 1 else 1.0
    ax.bar(x[o], a[o], width=0.6 * step, color=c1, alpha=0.85, label=Y1LABEL, zorder=2)
else:
    ax.plot(x[o], a[o], color=c1, lw=1.2, marker="o" if MARKERS else None, ms=3.2, mec=INK, mew=0.4,
            label=Y1LABEL, zorder=3)
ax2 = ax.twinx()
ax2.plot(x[o], b[o], color=c2, lw=1.2, marker="s" if MARKERS else None, ms=3.0, mec=INK, mew=0.4, label=Y2LABEL,
         zorder=3)
ax.set_xlabel(XLABEL)
ax.set_ylabel(Y1LABEL, color=c1)
ax2.set_ylabel(Y2LABEL, color=c2)
ax.tick_params(axis="y", colors=c1)
ax2.tick_params(axis="y", colors=c2)
ax2.spines["left"].set_color(c1)
ax2.spines["right"].set_color(c2)
finish(ax)
