# ---- settings ----
A = "Ru"                  # the three parts of each composition (any units; each row is scaled to 1)
B = "Co"
C = "Ni"
VALUE = "activity"        # colour of each point, "" for one colour
LABEL = ""                # write this column next to each point, "" for none
CMAP = "viridis"
COLORBAR_LABEL = "activity (a.u.)"
GRID = True               # lines every 20 %
# ---- draw ----
ax = chart(left=3.0, bottom=3.0, right=18.0 if VALUE else 3.0)
a, b, c = column(A, "number"), column(B, "number"), column(C, "number")
tot = a + b + c
a, b, c = a / tot, b / tot, c / tot
H3 = np.sqrt(3) / 2
xy = lambda p, q, r: (r + p / 2, p * H3)  # noqa: E731  (A at the top, B bottom left, C bottom right)
if GRID:
    for f in (0.2, 0.4, 0.6, 0.8):
        for p0, p1 in ((xy(f, 1 - f, 0), xy(f, 0, 1 - f)), (xy(1 - f, f, 0), xy(0, f, 1 - f)),
                       (xy(1 - f, 0, f), xy(0, 1 - f, f))):
            ax.plot([p0[0], p1[0]], [p0[1], p1[1]], color="#d5d8de", lw=0.5, zorder=1)
        ax.text(*np.add(xy(f, 0, 1 - f), (0.025, 0)), "%g" % f, ha="left", va="center", fontsize=SMALL * 0.9)
        ax.text(*np.add(xy(1 - f, f, 0), (-0.025, 0)), "%g" % f, ha="right", va="center", fontsize=SMALL * 0.9)
        ax.text(*np.add(xy(0, 1 - f, f), (0, -0.03)), "%g" % f, ha="center", va="top", fontsize=SMALL * 0.9)
ax.plot([0, 1, 0.5, 0], [0, 0, H3, 0], color=INK, lw=0.8, zorder=2)
ax.text(0.5, H3 + 0.04, A, ha="center", va="bottom", fontweight="bold")
ax.text(-0.04, -0.04, B, ha="right", va="top", fontweight="bold")
ax.text(1.04, -0.04, C, ha="left", va="top", fontweight="bold")
px, py = xy(a, b, c)
if VALUE:
    sc = ax.scatter(px, py, c=column(VALUE, "number"), cmap=CMAP, s=18, edgecolor=INK, linewidths=0.3, zorder=3)
else:
    ax.scatter(px, py, color=PALETTE[0], s=18, edgecolor=INK, linewidths=0.3, zorder=3)
if LABEL:
    for i, t in enumerate(column(LABEL)):
        ax.annotate(t, (px[i], py[i]), xytext=(3, 2), textcoords="offset points", fontsize=SMALL)
ax.set_aspect("equal")
ax.set_xlim(-0.14, 1.14)
ax.set_ylim(-0.13, H3 + 0.1)
ax.axis("off")
if VALUE:
    pos = ax.get_position()
    cax = pg.fig.add_axes([pos.x1 + 1.0 / PAGE_W, pos.y0 + pos.height * 0.15, 2.2 / PAGE_W, pos.height * 0.7])
    cb = pg.fig.colorbar(sc, cax=cax)
    cb.outline.set_linewidth(0.6)
    cb.set_label(COLORBAR_LABEL)
finish(ax)
