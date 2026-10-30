# ---- settings ----
LABEL = "item"            # one slice per row
VALUE = "share"
HOLE = 0.55               # size of the hole (0 = a full pie)
SHOW_PERCENT = True       # write each slice's percentage under its name
SORT = True               # largest slice first, clockwise from the top
CENTER_TEXT = ""          # text in the hole, "" for none
HIGHLIGHT_ITEM = ""       # one slice pulled out and drawn in the highlight colour
# ---- draw ----
ax = chart(left=4.0, bottom=3.0, right=4.0)
lab, v = column(LABEL), column(VALUE, "number")
order = sorted(range(len(v)), key=lambda i: -v[i]) if SORT else list(range(len(v)))
lab, v = [lab[i] for i in order], v[order]
cols = [HIGHLIGHT if lab[i] == HIGHLIGHT_ITEM else PALETTE[i % len(PALETTE)] for i in range(len(v))]
wedges, _ = ax.pie(v, colors=cols, startangle=90, counterclock=False,
                   explode=[0.06 if l == HIGHLIGHT_ITEM else 0 for l in lab],
                   wedgeprops=dict(width=1 - HOLE if HOLE > 0 else 1, edgecolor="white", linewidth=0.8))
tot = np.nansum(v)
spots = []
for w, l, val in zip(wedges, lab, v):
    a = np.deg2rad((w.theta1 + w.theta2) / 2)
    tip = (w.r * np.cos(a) + w.center[0], w.r * np.sin(a) + w.center[1])
    spots.append([tip, 1.0 if np.cos(a) >= 0 else -1.0, 1.18 * np.sin(a), l, val])
for side in (1.0, -1.0):                              # labels on one side at least 0.3 apart, top to bottom
    s = sorted([p for p in spots if p[1] == side], key=lambda p: -p[2])
    for k in range(1, len(s)):
        s[k][2] = min(s[k][2], s[k - 1][2] - 0.3)
for tip, side, y, l, val in spots:
    ax.annotate("%s\n%.0f%%" % (l, 100 * val / tot) if SHOW_PERCENT else l, tip, xytext=(1.3 * side, y),
                ha="left" if side > 0 else "right", va="center", fontsize=SMALL,
                arrowprops=dict(arrowstyle="-", color=INK, lw=0.4, shrinkA=0, shrinkB=0,
                                connectionstyle="angle,angleA=0,angleB=90,rad=0"))
if CENTER_TEXT and HOLE > 0:
    ax.text(0, 0, CENTER_TEXT, ha="center", va="center", fontweight="bold")
ax.set_aspect("equal")
ax.set_xlim(-2.2, 2.2)
ax.set_ylim(-1.4, 1.4)
ax.axis("off")
finish(ax)
