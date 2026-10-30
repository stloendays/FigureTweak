# ---- settings ----
ITEM = "catalyst"         # one polygon per item
AXIS = "metric"           # one spoke per metric
VALUE = "score"
FILL = True               # shade each polygon
MAX = 0                   # value of the outer ring (0 = a little above the largest value)
HIGHLIGHT_ITEM = ""       # one item drawn in the highlight colour, "" for none
# ---- draw ----
ax = polar_chart(left=10.0, right=26.0, bottom=7.0, top=7.0 if not TITLE else 11.0)
it, sp, v = column(ITEM), column(AXIS), column(VALUE, "number")
items, spokes = unique(it), unique(sp)
M = np.full((len(items), len(spokes)), np.nan)
for i in range(len(v)):
    M[items.index(it[i]), spokes.index(sp[i])] = v[i]
ang = np.linspace(0, 2 * np.pi, len(spokes), endpoint=False)
ax.set_theta_offset(np.pi / 2)
ax.set_theta_direction(-1)
for j, k in enumerate(items):
    col = HIGHLIGHT if k == HIGHLIGHT_ITEM else PALETTE[j % len(PALETTE)]
    a, r = np.r_[ang, ang[:1]], np.r_[M[j], M[j][:1]]
    ax.plot(a, r, color=col, lw=1.2, marker="o", ms=2.5, label=k, zorder=3)
    if FILL:
        ax.fill(a, r, color=col, alpha=0.15, lw=0, zorder=2)
ax.set_ylim(0, MAX or np.nanmax(M) * 1.08)
ax.set_xticks(ang, spokes)
ax.tick_params(axis="x", pad=3)
ax.tick_params(axis="y", labelsize=SMALL * 0.9)
ax.set_rlabel_position(180 / len(spokes))
ax.grid(color="#d5d8de", lw=0.5)
ax.spines["polar"].set_color(MUTED)
ax.spines["polar"].set_linewidth(0.6)
ax.legend(loc="upper left", bbox_to_anchor=(1.12, 1.0))
finish(ax)
