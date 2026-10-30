# ---- settings ----
REF = "reference"         # reference / measured value (x)
PRED = "model"            # predicted / model value (y)
GROUP = "source"          # colour by group, "" for one colour
BAND = 5.0                # shaded band of +/- this many percent around y = x, 0 for none
XLABEL = "reference cost (EUR t$^{-1}$)"
YLABEL = "model cost (EUR t$^{-1}$)"
# ---- draw ----
ax = chart()
x, y = column(REF, "number"), column(PRED, "number")
g = column(GROUP) if GROUP else ["all"] * len(x)
lo, hi = np.nanmin(np.r_[x, y]), np.nanmax(np.r_[x, y])
pad = (hi - lo) * 0.06
lo, hi = lo - pad, hi + pad
xx = np.array([lo, hi])
if BAND:
    ax.fill_between(xx, xx * (1 - BAND / 100), xx * (1 + BAND / 100), color=PALETTE[1], alpha=0.25, lw=0, zorder=1,
                    label="±%g %%" % BAND)
ax.plot(xx, xx, color=INK, lw=0.8, zorder=2)
for j, k in enumerate(unique(g)):
    idx = [i for i in range(len(x)) if g[i] == k]
    ax.scatter(x[idx], y[idx], s=18, color=PALETTE[j % len(PALETTE)], edgecolor=INK, linewidth=0.5,
               label=k if GROUP else None, zorder=3)
ok = ~(np.isnan(x) | np.isnan(y))
mape = np.mean(np.abs(y[ok] - x[ok]) / np.abs(x[ok])) * 100
r2 = 1 - np.sum((y[ok] - x[ok]) ** 2) / np.sum((x[ok] - x[ok].mean()) ** 2)
ax.text(0.04, 0.96, "n = %d\nMAPE = %.1f %%\nR$^2$ = %.3f" % (ok.sum(), mape, r2), transform=ax.transAxes,
        va="top", ha="left", fontsize=SMALL)
ax.set_xlim(lo, hi)
ax.set_ylim(lo, hi)
ax.set_xlabel(XLABEL)
ax.set_ylabel(YLABEL)
ax.legend(loc="lower right")
finish(ax)
