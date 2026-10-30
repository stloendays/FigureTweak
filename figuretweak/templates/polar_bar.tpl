# ---- settings ----
LABEL = "month"           # one bar per row, clockwise from the top
VALUE = "output"
SORT = False              # True: largest first
INNER = 0.3               # radius of the empty centre, as a share of the largest bar (0 = a rose from the centre)
SHOW_VALUES = False
HIGHLIGHT_ITEM = ""       # one bar drawn in the highlight colour, "" for none
# ---- draw ----
ax = polar_chart(left=8.0, right=8.0, bottom=6.0)
lab, v = column(LABEL), column(VALUE, "number")
o = sorted(range(len(v)), key=lambda i: -v[i]) if SORT else list(range(len(v)))
lab, v = [lab[i] for i in o], v[o]
n = len(v)
th = np.linspace(0, 2 * np.pi, n, endpoint=False)
vmax = np.nanmax(v) or 1.0
base = INNER * vmax
ax.set_theta_offset(np.pi / 2)
ax.set_theta_direction(-1)
cols = [HIGHLIGHT if l == HIGHLIGHT_ITEM else PALETTE[0] for l in lab]
ax.bar(th, v, width=2 * np.pi / n * 0.85, bottom=base, color=cols, edgecolor="white", linewidth=0.5, zorder=2)
if SHOW_VALUES:
    for t, val in zip(th, v):
        ax.text(t, base + val + vmax * 0.06, "%g" % val, ha="center", va="center", fontsize=SMALL * 0.9)
ax.set_xticks(th, lab)
ax.set_yticks([])
ax.set_ylim(0, base + vmax * 1.12)
ax.grid(color="#d5d8de", lw=0.5)
ax.spines["polar"].set_visible(False)
finish(ax)
