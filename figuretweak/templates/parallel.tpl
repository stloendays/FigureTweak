# ---- settings ----
COLUMNS = ""              # the axes, comma-separated, in order; "" = every numeric column
GROUP = "family"          # colour by group, "" for one colour
LINE_ALPHA = 0.6
# ---- draw ----
ax = chart(left=6.0, bottom=12.0, right=6.0, top=10.0 if TITLE else 7.0)
cols = numeric_columns(COLUMNS)
D = np.column_stack([column(c, "number") for c in cols])
lo, hi = np.nanmin(D, 0), np.nanmax(D, 0)
N = (D - lo) / np.where(hi - lo == 0, 1, hi - lo)
g = column(GROUP) if GROUP else ["all"] * len(D)
grps = unique(g)
seen = set()
for i in range(len(D)):
    j = grps.index(g[i])
    ax.plot(range(len(cols)), N[i], color=PALETTE[j % len(PALETTE)], lw=0.8, alpha=LINE_ALPHA, zorder=2,
            label=g[i] if GROUP and g[i] not in seen else None)
    seen.add(g[i])
for k in range(len(cols)):
    ax.axvline(k, color=INK, lw=0.7, zorder=3)
    ax.text(k, 1.03, "%.3g" % hi[k], ha="center", va="bottom", fontsize=SMALL * 0.9)
    ax.text(k, -0.03, "%.3g" % lo[k], ha="center", va="top", fontsize=SMALL * 0.9)
ax.set_xticks(range(len(cols)), cols)
ax.tick_params(axis="x", length=0, pad=9)
ax.set_yticks([])
for sp in ax.spines.values():
    sp.set_visible(False)
ax.set_xlim(-0.15, len(cols) - 0.85)
ax.set_ylim(-0.02, 1.02)
if GROUP:
    ax.legend(loc="lower center", bbox_to_anchor=(0.5, 1.07), ncol=len(grps))
finish(ax)
