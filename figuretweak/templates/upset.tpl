# ---- settings ----
SET = "method"            # which set the item is in (one row per item and set)
ITEM = "candidate"        # the item
TOP_N = 12                # how many intersections to show, largest first
YLABEL = "intersection size"
SET_LABEL = "set size"
# ---- draw ----
from matplotlib.ticker import MaxNLocator  # noqa: E402
s, it = column(SET), column(ITEM)
sets = unique(s)
mem = {}
for i in range(len(s)):
    mem.setdefault(it[i], set()).add(sets.index(s[i]))
combos = {}
for m in mem.values():
    k = tuple(sorted(m))
    combos[k] = combos.get(k, 0) + 1
top = sorted(combos.items(), key=lambda kv: (-kv[1], len(kv[0]), kv[0]))[:TOP_N]
n, ncol = len(sets), len(top)
row = 4.2
L, mh = 38.0, row * n
mtop = 7.0 if TITLE else 3.0
am = box_ax(L, 10.0, WIDTH_MM - L - 3.0, mh)
ab = box_ax(L, 10.0 + mh + 1.5, WIDTH_MM - L - 3.0, HEIGHT_MM - (10.0 + mh + 1.5) - mtop)
asz = box_ax(3.0, 10.0, 17.0, mh)
for j, (k, c) in enumerate(top):
    on = [i for i in range(n) if i in k]
    am.scatter([j] * n, range(n), s=16, color=["#d5d8de"] * n, zorder=2, linewidths=0)
    am.scatter([j] * len(on), on, s=16, color=INK, zorder=3, linewidths=0)
    if len(on) > 1:
        am.plot([j, j], [min(on), max(on)], color=INK, lw=1.2, zorder=2)
am.set_yticks(range(n), sets)
am.set_xticks([])
am.tick_params(length=0)
am.set_ylim(n - 0.5, -0.5)
am.set_xlim(-0.6, ncol - 0.4)
for sp in am.spines.values():
    sp.set_visible(False)
counts = [c for _, c in top]
ab.bar(range(ncol), counts, width=0.6, color=PALETTE[0], zorder=2)
for j, c in enumerate(counts):
    ab.text(j, c, "%d" % c, ha="center", va="bottom", fontsize=SMALL)
ab.set_xlim(-0.6, ncol - 0.4)
ab.set_ylim(0, max(counts) * 1.18)
ab.set_xticks([])
ab.yaxis.set_major_locator(MaxNLocator(integer=True))
ab.set_ylabel(YLABEL)
for sp in ("top", "right"):
    ab.spines[sp].set_visible(False)
asz.barh(range(n), [sum(1 for m in mem.values() if i in m) for i in range(n)], height=0.55, color=MUTED, zorder=2)
asz.set_ylim(n - 0.5, -0.5)
asz.invert_xaxis()
asz.set_yticks([])
asz.set_xlabel(SET_LABEL)
for sp in ("top", "left"):
    asz.spines[sp].set_visible(False)
finish(ab)
