# ---- settings ----
COLUMNS = ""              # columns to correlate, comma-separated; "" = every numeric column
METHOD = "pearson"        # "pearson" (linear) or "spearman" (rank)
LOWER_ONLY = True         # show each pair once (lower triangle)
SHOW_VALUES = True        # write r in each cell
CMAP = "RdBu_r"           # colour map from -1 to 1
COLORBAR_LABEL = "r"
# ---- draw ----
ax = chart(left=20.0, bottom=18.0, right=17.0)
cols = numeric_columns(COLUMNS)
D = np.column_stack([column(c, "number") for c in cols])
D = D[~np.isnan(D).any(1)]
if METHOD == "spearman":
    D = np.argsort(np.argsort(D, 0), 0).astype(float)
R = np.corrcoef(D, rowvar=False)
n = len(cols)
M = R.copy()
if LOWER_ONLY:
    M[np.triu_indices(n, 1)] = np.nan
im = ax.imshow(M, cmap=CMAP, vmin=-1, vmax=1, aspect="auto", interpolation="nearest")
if SHOW_VALUES:
    for i in range(n):
        for j in range(n):
            if not np.isnan(M[i, j]):
                ax.text(j, i, "%.2f" % M[i, j], ha="center", va="center", fontsize=SMALL * 0.9,
                        color="white" if abs(M[i, j]) > 0.6 else INK)
ax.set_xticks(range(n), cols, rotation=40, ha="right", rotation_mode="anchor")
ax.set_yticks(range(n), cols)
ax.tick_params(length=0)
if LOWER_ONLY:
    for s in ("top", "right"):
        ax.spines[s].set_visible(False)
pos = ax.get_position()
cax = pg.fig.add_axes([pos.x1 + 2.0 / PAGE_W, pos.y0, 2.2 / PAGE_W, pos.height])
cb = pg.fig.colorbar(im, cax=cax)
cb.outline.set_linewidth(0.6)
cb.set_label(COLORBAR_LABEL)
finish(ax)
