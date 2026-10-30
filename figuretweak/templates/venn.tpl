# ---- settings ----
SET = "method"            # which set the item is in (one row per item and set; two or three sets)
ITEM = "candidate"        # the item
SHOW_PERCENT = False      # write shares of all items as well as counts
# ---- draw ----
from matplotlib.patches import Circle  # noqa: E402
ax = chart(left=3.0, bottom=3.0, right=3.0)
s, it = column(SET), column(ITEM)
sets = unique(s)
if len(sets) not in (2, 3):
    raise SystemExit("a Venn diagram takes two or three sets (here %d); use the UpSet template for more" % len(sets))
mem = {k: {it[i] for i in range(len(s)) if s[i] == k} for k in sets}
allitems = set().union(*mem.values())
if len(sets) == 2:
    cen, names = [(-0.55, 0), (0.55, 0)], [(-0.9, 1.12), (0.9, 1.12)]
    regions = {(0,): (-0.9, 0), (1,): (0.9, 0), (0, 1): (0, 0)}
else:
    cen, names = [(-0.55, 0.32), (0.55, 0.32), (0, -0.62)], [(-1.25, 1.25), (1.25, 1.25), (0, -1.78)]
    regions = {(0,): (-0.95, 0.55), (1,): (0.95, 0.55), (2,): (0, -1.05), (0, 1): (0, 0.72), (0, 2): (-0.62, -0.32),
               (1, 2): (0.62, -0.32), (0, 1, 2): (0, 0.02)}
for j, (c, k) in enumerate(zip(cen, sets)):
    col = PALETTE[j % len(PALETTE)]
    ax.add_patch(Circle(c, 1.0, facecolor=col, alpha=0.35, edgecolor=col, linewidth=1.2, zorder=1))
    ax.text(names[j][0], names[j][1], "%s\n(%d)" % (k, len(mem[k])), ha="center", va="center", fontweight="bold",
            color=col)
for idx, (px, py) in regions.items():
    inside = set.intersection(*[mem[sets[i]] for i in idx])
    outside = set().union(*[mem[sets[i]] for i in range(len(sets)) if i not in idx])
    nreg = len(inside - outside)
    ax.text(px, py, "%d" % nreg + ("\n%.0f%%" % (100 * nreg / len(allitems)) if SHOW_PERCENT else ""),
            ha="center", va="center")
ax.set_aspect("equal")
ax.set_xlim(-2.0, 2.0)
ax.set_ylim(-2.0 if len(sets) == 3 else -1.2, 1.55)
ax.axis("off")
finish(ax)
