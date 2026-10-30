# ---- settings ----
VALUE = "value"           # the values (one row each)
GROUP = "group"           # overlay one histogram per group, "" for a single one
BINS = 30
DENSITY = False           # True: probability density instead of counts
XLABEL = "value"
YLABEL = "count"
SHOW_MEDIAN = True
# ---- draw ----
ax = chart()
v = column(VALUE, "number")
g = column(GROUP) if GROUP else ["all"] * len(v)
grps = unique(g)
edges = np.histogram_bin_edges(v[~np.isnan(v)], bins=BINS)
for j, k in enumerate(grps):
    d = v[[i for i in range(len(v)) if g[i] == k]]
    d = d[~np.isnan(d)]
    col = PALETTE[j % len(PALETTE)]
    ax.hist(d, bins=edges, density=DENSITY, color=col, alpha=0.6 if len(grps) > 1 else 0.9, edgecolor=INK,
            linewidth=0.4, label=k if GROUP else None, zorder=2)
    if SHOW_MEDIAN:
        ax.axvline(np.median(d), color=col, lw=1.0, ls="--", zorder=3)
ax.set_xlabel(XLABEL)
ax.set_ylabel("density" if DENSITY and YLABEL == "count" else YLABEL)
if GROUP:
    ax.legend(loc="upper right")
finish(ax)
