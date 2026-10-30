# ---- settings ----
X = "process"             # one bar per category
PART = "item"             # the stacked parts (colour + legend)
Y = "cost"                # size of each part
PERCENT = False           # True: every bar scaled to 100 %
HORIZONTAL = False        # True: bars run left to right
XLABEL = ""
YLABEL = "cost (USD t$^{-1}$)"
SHOW_TOTAL = True         # print each bar's total at its end
# ---- draw ----
ax = chart(right=26.0)
x, p, y = column(X), column(PART), column(Y, "number")
cats, parts = unique(x), unique(p)
val = np.array([[np.nansum([y[i] for i in range(len(x)) if x[i] == c and p[i] == q]) for c in cats] for q in parts])
tot = val.sum(axis=0)
if PERCENT:
    val = val / tot * 100
base = np.zeros(len(cats))
for j, q in enumerate(parts):
    kw = dict(color=PALETTE[j % len(PALETTE)], edgecolor=INK, linewidth=0.5, label=q, zorder=2)
    if HORIZONTAL:
        ax.barh(range(len(cats)), val[j], left=base, height=0.62, **kw)
    else:
        ax.bar(range(len(cats)), val[j], bottom=base, width=0.62, **kw)
    base += val[j]
if SHOW_TOTAL and not PERCENT:
    for k, t in enumerate(tot):
        if HORIZONTAL:
            ax.text(t, k, "  %.3g" % t, va="center", ha="left", fontsize=SMALL)
        else:
            ax.text(k, t, "%.3g" % t, va="bottom", ha="center", fontsize=SMALL)
if HORIZONTAL:
    ax.set_yticks(range(len(cats)), cats)
    ax.invert_yaxis()
    ax.set_xlabel(YLABEL if not PERCENT else "share (%)")
    ax.set_ylabel(XLABEL)
    ax.margins(x=0.12)
else:
    ax.set_xticks(range(len(cats)), cats)
    ax.set_xlim(-0.6, len(cats) - 0.4)
    ax.set_ylabel(YLABEL if not PERCENT else "share (%)")
    ax.set_xlabel(XLABEL)
    ax.margins(y=0.1)
handles, labels = ax.get_legend_handles_labels()
ax.legend(handles[::-1], labels[::-1], loc="center left", bbox_to_anchor=(1.02, 0.5), handlelength=1.0)
finish(ax)
