# ---- settings ----
LABEL = "id"              # name of each point (used for the top labels), "" for none
FC = "log2fc"             # effect size (e.g. log2 fold change)
P = "p"                   # p value
FC_CUT = 1.0              # |effect| threshold
P_CUT = 0.05              # p threshold
TOP_N = 6                 # label this many of the most significant points
XLABEL = "log$_2$ fold change"
YLABEL = "−log$_{10}$ p"
# ---- draw ----
ax = chart()
fc, p = column(FC, "number"), column(P, "number")
lab = column(LABEL) if LABEL else None
y = -np.log10(np.clip(p, 1e-300, 1))
up = (fc >= FC_CUT) & (p < P_CUT)
down = (fc <= -FC_CUT) & (p < P_CUT)
rest = ~(up | down)
ax.scatter(fc[rest], y[rest], s=5, color="#b5b9c1", linewidths=0, zorder=2, label="n.s.")
ax.scatter(fc[up], y[up], s=7, color=HIGHLIGHT, linewidths=0, zorder=3, label="up (%d)" % up.sum())
ax.scatter(fc[down], y[down], s=7, color=PALETTE[0], linewidths=0, zorder=3, label="down (%d)" % down.sum())
for v in (-FC_CUT, FC_CUT):
    ax.axvline(v, color=MUTED, lw=0.6, ls="--", zorder=1)
ax.axhline(-np.log10(P_CUT), color=MUTED, lw=0.6, ls="--", zorder=1)
if lab and TOP_N:
    sig = np.where(up | down)[0]
    for i in sig[np.argsort(-y[sig])][:TOP_N]:
        ax.annotate(lab[i], (fc[i], y[i]), xytext=(6 if fc[i] > 0 else -6, 4), textcoords="offset points",
                    ha="left" if fc[i] > 0 else "right", fontsize=SMALL,
                    arrowprops=dict(arrowstyle="-", color=INK, lw=0.4, shrinkA=0, shrinkB=1))
span = np.nanmax(np.abs(fc)) * 1.4
ax.set_xlim(-span, span)
ax.set_ylim(0, np.nanmax(y) * 1.15)
ax.set_xlabel(XLABEL)
ax.set_ylabel(YLABEL)
ax.legend(loc="upper center")
finish(ax)
