# ---- settings ----
X = "year"                # x values (numbers)
SERIES = "route"          # one band per series
Y = "capacity"            # the value of each series at each x
PERCENT = False           # True: each x adds up to 100 %
STREAM = False            # True: a streamgraph centred on zero
XLABEL = "year"
YLABEL = "capacity (Mt a$^{-1}$)"
LABEL_INSIDE = True       # write each series' name inside its band instead of a legend
# ---- draw ----
ax = chart()
x, s, y = column(X, "number"), column(SERIES), column(Y, "number")
xs = sorted(set(x[~np.isnan(x)]))
names = unique(s)
M = np.zeros((len(names), len(xs)))
for i in range(len(x)):
    if not np.isnan(x[i]) and not np.isnan(y[i]):
        M[names.index(s[i]), xs.index(x[i])] += y[i]
if PERCENT:
    M = M / np.where(M.sum(0) == 0, 1, M.sum(0)) * 100
cols = [PALETTE[j % len(PALETTE)] for j in range(len(names))]
polys = ax.stackplot(xs, M, labels=names, colors=cols, baseline="wiggle" if STREAM else "zero",
                     edgecolor="white", linewidth=0.5, alpha=0.9)
ax.set_xlim(xs[0], xs[-1])
inner = range(1, len(xs) - 1) if len(xs) > 2 else range(len(xs))
peak = [max(inner, key=lambda k: M[j, k]) for j in range(len(names))]
if LABEL_INSIDE and all(M[j, peak[j]] > 0.1 * M.sum(0).max() for j in range(len(names))):
    for j, p in enumerate(polys):
        v = p.get_paths()[0].vertices
        ys = v[np.isclose(v[:, 0], xs[peak[j]]), 1]
        ax.text(xs[peak[j]], (ys.min() + ys.max()) / 2, names[j], ha="center", va="center", color="white",
                fontweight="bold", fontsize=SMALL)
else:
    ax.legend(loc="upper left")
if STREAM:
    ax.set_yticks([])
ax.set_xlabel(XLABEL)
ax.set_ylabel("share (%)" if PERCENT and not STREAM else YLABEL)
finish(ax)
