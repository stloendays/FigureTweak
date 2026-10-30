# ---- settings ----
X = "temperature"         # x of each point (a grid or scattered points)
Y = "pressure"            # y of each point
Z = "rate"                # the value at each point
LEVELS = 12               # number of colour steps
CMAP = "viridis"
SHOW_LINES = True         # contour lines on top of the colours
LABEL_LINES = False       # write the value on the lines
SHOW_POINTS = False       # mark the data points
MARK_MAX = True           # star at the highest value
XLABEL = "temperature (K)"
YLABEL = "pressure (bar)"
COLORBAR_LABEL = "rate (a.u.)"
# ---- draw ----
ax = chart(right=18.0)
x, y, z = column(X, "number"), column(Y, "number"), column(Z, "number")
ok = ~(np.isnan(x) | np.isnan(y) | np.isnan(z))
x, y, z = x[ok], y[ok], z[ok]
cs = ax.tricontourf(x, y, z, levels=LEVELS, cmap=CMAP, zorder=1)
if SHOW_LINES:
    cl = ax.tricontour(x, y, z, levels=LEVELS, colors=INK, linewidths=0.35, zorder=2)
    if LABEL_LINES:
        ax.clabel(cl, fontsize=SMALL * 0.85, fmt="%.3g")
if SHOW_POINTS:
    ax.scatter(x, y, s=3, color="white", edgecolor=INK, linewidths=0.3, zorder=3)
if MARK_MAX:
    i = int(np.argmax(z))
    ax.scatter([x[i]], [y[i]], marker="*", s=55, color=HIGHLIGHT, edgecolor="white", linewidths=0.5, zorder=4)
    ax.annotate("max %.3g" % z[i], (x[i], y[i]), xytext=(5, 4), textcoords="offset points", color="white",
                fontweight="bold", fontsize=SMALL)
ax.set_xlabel(XLABEL)
ax.set_ylabel(YLABEL)
pos = ax.get_position()
cax = pg.fig.add_axes([pos.x1 + 2.0 / PAGE_W, pos.y0, 2.2 / PAGE_W, pos.height])
cb = pg.fig.colorbar(cs, cax=cax)
cb.outline.set_linewidth(0.6)
cb.set_label(COLORBAR_LABEL)
finish(ax)
