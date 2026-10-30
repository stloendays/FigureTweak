# ---- settings ----
ROW = "promoter"          # rows of the grid
COL = "support"           # columns of the grid
VALUE = "yield"           # the cell value
CMAP = "Blues"            # colour map (any matplotlib name); it can be changed in the editor too
SHOW_VALUES = True        # write each value in its cell
VALUE_FORMAT = "%.0f"
COLORBAR_LABEL = "yield (%)"
XLABEL = ""
YLABEL = ""
# ---- draw ----
ax = chart(left=16.0, right=17.0)
r, c, v = column(ROW), column(COL), column(VALUE, "number")
rows, cols = unique(r), unique(c)
M = np.full((len(rows), len(cols)), np.nan)
for i in range(len(v)):
    M[rows.index(r[i]), cols.index(c[i])] = v[i]
im = ax.imshow(M, cmap=CMAP, aspect="auto", interpolation="nearest")
if SHOW_VALUES:
    lo, hi = np.nanmin(M), np.nanmax(M)
    for i in range(len(rows)):
        for j in range(len(cols)):
            if not np.isnan(M[i, j]):
                dark = (M[i, j] - lo) / ((hi - lo) or 1) > 0.6
                ax.text(j, i, VALUE_FORMAT % M[i, j], ha="center", va="center", fontsize=SMALL,
                        color="white" if dark else INK)
ax.set_xticks(range(len(cols)), cols)
ax.set_yticks(range(len(rows)), rows)
ax.tick_params(length=0)
ax.set_xlabel(XLABEL)
ax.set_ylabel(YLABEL)
pos = ax.get_position()
cax = pg.fig.add_axes([pos.x1 + 2.0 / PAGE_W, pos.y0, 2.2 / PAGE_W, pos.height])
cb = pg.fig.colorbar(im, cax=cax)
cb.outline.set_linewidth(0.6)
cb.set_label(COLORBAR_LABEL)
finish(ax)
