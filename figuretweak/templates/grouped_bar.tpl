# ---- settings ----
X = "catalyst"            # categories along the x axis
GROUP = "condition"       # one bar per group inside each category (colour + legend)
Y = "yield"               # value; repeated rows -> mean +/- s.d.
ERR = "sd"                # error bar column; "" for none
XLABEL = ""
YLABEL = "yield (%)"
LEGEND_TITLE = ""
# ---- draw ----
ax = chart()
x, g, y = column(X), column(GROUP), column(Y, "number")
e = column(ERR, "number")
cats, grps = unique(x), unique(g)
width = 0.8 / len(grps)
for j, gr in enumerate(grps):
    vals, errs = [], []
    for c in cats:
        idx = [i for i in range(len(x)) if x[i] == c and g[i] == gr]
        v = y[idx]
        vals.append(np.nanmean(v) if len(v) else np.nan)
        if e is not None and len(idx) == 1:
            errs.append(e[idx[0]])
        else:
            errs.append(np.nanstd(v, ddof=1) if len(v) > 1 else 0)
    pos = np.arange(len(cats)) - 0.4 + width * (j + 0.5)
    ax.bar(pos, vals, width=width * 0.92, color=PALETTE[j % len(PALETTE)], edgecolor=INK, linewidth=0.5,
           label=gr, zorder=2)
    if e is not None or any(errs):
        ax.errorbar(pos, vals, yerr=errs, fmt="none", ecolor=INK, elinewidth=0.7, capsize=1.8, capthick=0.7, zorder=3)
ax.set_xticks(range(len(cats)), cats)
ax.set_xlim(-0.6, len(cats) - 0.4)
ax.set_ylim(bottom=0)
ax.set_xlabel(XLABEL)
ax.set_ylabel(YLABEL)
ax.margins(y=0.2)
ax.legend(title=LEGEND_TITLE or None, loc="upper left", ncol=len(grps), handlelength=1.0, columnspacing=1.0)
finish(ax)
