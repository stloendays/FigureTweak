# ---- settings ----
X = "catalyst"            # categories along the x axis
Y = "rate"                # value; several rows of one category -> mean +/- s.d. with the points shown
ERR = "sd"                # error bar half-width column; "" for none (or computed from repeated rows)
XLABEL = ""
YLABEL = "rate"
SORT = "none"             # "none", "ascending" or "descending"
HIGHLIGHT_ITEM = ""       # one category drawn in the highlight colour, "" for none
# ---- draw ----
ax = chart()
x, y = column(X), column(Y, "number")
e = column(ERR, "number")
cats = unique(x)
groups = {c: y[[i for i, v in enumerate(x) if v == c]] for c in cats}
means = np.array([np.nanmean(groups[c]) for c in cats])
repeated = any(len(groups[c]) > 1 for c in cats)
if e is not None and not repeated:
    errs = np.array([e[x.index(c)] for c in cats])
elif repeated:
    errs = np.array([np.nanstd(groups[c], ddof=1) if len(groups[c]) > 1 else 0 for c in cats])
else:
    errs = None
order = list(range(len(cats)))
if SORT in ("ascending", "descending"):
    order = sorted(order, key=lambda i: means[i], reverse=SORT == "descending")
for k, i in enumerate(order):
    col = HIGHLIGHT if cats[i] == HIGHLIGHT_ITEM else PALETTE[0]
    ax.bar(k, means[i], width=0.62, color=col, edgecolor=INK, linewidth=0.6, label=cats[i], zorder=2)
    if errs is not None:
        ax.errorbar(k, means[i], yerr=errs[i], color=INK, lw=0.8, capsize=2.5, capthick=0.8, zorder=3)
    if repeated:
        pts = groups[cats[i]]
        jit = (np.random.default_rng(k).random(len(pts)) - 0.5) * 0.28
        ax.scatter(k + jit, pts, s=9, facecolor="white", edgecolor=INK, linewidth=0.5, zorder=4)
ax.set_xticks(range(len(order)), [cats[i] for i in order])
ax.set_xlim(-0.6, len(order) - 0.4)
ax.set_ylim(bottom=0)
ax.set_xlabel(XLABEL)
ax.set_ylabel(YLABEL)
finish(ax)
