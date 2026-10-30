# ---- settings ----
PERIOD = "year"           # x: the periods, in order of appearance
ITEM = "catalyst"         # one line per item
VALUE = "score"           # value (ranked per period) or rank
RANK_BY_VALUE = True      # True: rank 1 = largest value; False: VALUE is already the rank
HIGHLIGHT_ITEM = ""       # one item drawn in the highlight colour, "" for none
XLABEL = ""
# ---- draw ----
ax = chart(left=18.0, right=18.0)
p, it, v = column(PERIOD), column(ITEM), column(VALUE, "number")
periods, items = unique(p), unique(it)
R = np.full((len(items), len(periods)), np.nan)
for j, per in enumerate(periods):
    idx = [i for i in range(len(p)) if p[i] == per and not np.isnan(v[i])]
    if RANK_BY_VALUE:
        for r, i in enumerate(sorted(idx, key=lambda i: -v[i])):
            R[items.index(it[i]), j] = r + 1
    else:
        for i in idx:
            R[items.index(it[i]), j] = v[i]
x = np.arange(len(periods))
for k, name in enumerate(items):
    hot = name == HIGHLIGHT_ITEM
    col = HIGHLIGHT if hot else PALETTE[k % len(PALETTE)]
    ax.plot(x, R[k], color=col, lw=2.0 if hot else 1.2, marker="o", ms=4, mec="white", mew=0.6,
            zorder=4 if hot else 3)
    ok = np.where(~np.isnan(R[k]))[0]
    if len(ok):
        ax.text(x[ok[0]] - 0.12, R[k, ok[0]], name, ha="right", va="center", color=col, fontsize=SMALL,
                fontweight="bold" if hot else "normal")
        ax.text(x[ok[-1]] + 0.12, R[k, ok[-1]], name, ha="left", va="center", color=col, fontsize=SMALL,
                fontweight="bold" if hot else "normal")
ax.set_xticks(x, periods)
ax.set_yticks([])
ax.set_ylim(np.nanmax(R) + 0.6, 0.4)
ax.set_xlim(-0.15, len(periods) - 0.85)
for sp in ("left", "right", "top"):
    ax.spines[sp].set_visible(False)
ax.set_xlabel(XLABEL)
finish(ax)
