# ---- settings ----
LABEL = "cause"           # one bar per row
VALUE = "count"
XLABEL = ""
YLABEL = "count"
SHOW_80 = True            # mark where the cumulative share passes 80 %
# ---- draw ----
from matplotlib.ticker import PercentFormatter  # noqa: E402
ax = chart(right=13.0, bottom=14.0)
lab, v = column(LABEL), column(VALUE, "number")
o = sorted(range(len(v)), key=lambda i: -v[i])
lab, v = [lab[i] for i in o], v[o]
x = np.arange(len(v))
ax.bar(x, v, width=0.7, color=PALETTE[0], zorder=2, label=YLABEL)
cum = np.cumsum(v) / np.nansum(v) * 100
ax2 = ax.twinx()
ax2.plot(x, cum, color=HIGHLIGHT, lw=1.2, marker="o", ms=3, mec=INK, mew=0.4, zorder=3, label="cumulative")
ax2.set_ylim(0, 105)
ax2.yaxis.set_major_formatter(PercentFormatter(decimals=0))
if SHOW_80:
    ax2.axhline(80, color=MUTED, lw=0.6, ls="--", zorder=1)
ax.set_xticks(x, lab, rotation=30 if len(v) > 5 else 0, ha="right" if len(v) > 5 else "center",
              rotation_mode="anchor")
ax.set_xlim(-0.6, len(v) - 0.4)
ax.set_xlabel(XLABEL)
ax.set_ylabel(YLABEL)
ax2.set_ylabel("cumulative share")
finish(ax)
