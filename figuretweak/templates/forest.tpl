# ---- settings ----
LABEL = "variant"         # one row per estimate
EST = "estimate"          # point estimate
LOW = "low"               # interval lower end
HIGH = "high"             # interval upper end
REFERENCE = None          # vertical reference line (e.g. 0 or 1), None for none
FIRST_IS_MAIN = True      # first row drawn as the main result (filled, highlight colour)
XLABEL = "effect (%)"
SHOW_NUMBERS = True       # write "est (low-high)" at the right
# ---- draw ----
ax = chart(left=34.0, right=24.0 if SHOW_NUMBERS else 3.0)
lab, est, lo, hi = column(LABEL), column(EST, "number"), column(LOW, "number"), column(HIGH, "number")
for k in range(len(lab)):
    main = FIRST_IS_MAIN and k == 0
    col = HIGHLIGHT if main else PALETTE[0]
    ax.plot([lo[k], hi[k]], [k, k], color=col, lw=1.2, solid_capstyle="butt", zorder=2)
    ax.scatter([est[k]], [k], s=34 if main else 22, marker="D" if main else "s", color=col, edgecolor=INK,
               linewidth=0.5, zorder=3)
    if SHOW_NUMBERS:
        ax.text(1.03, k, "%.3g (%.3g–%.3g)" % (est[k], lo[k], hi[k]), transform=ax.get_yaxis_transform(),
                va="center", ha="left", fontsize=SMALL, fontweight="bold" if main else "normal")
if REFERENCE is not None:
    ax.axvline(REFERENCE, color=MUTED, lw=0.8, ls="--", zorder=1)
if FIRST_IS_MAIN:
    ax.axvline(est[0], color=HIGHLIGHT, lw=0.6, ls=":", zorder=1)
ax.set_yticks(range(len(lab)), lab)
ax.invert_yaxis()
ax.margins(y=0.08)
ax.set_xlabel(XLABEL)
finish(ax)
