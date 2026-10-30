# ---- settings ----
X = "E_N"                 # x values
Y = "log_TOF"             # y values
GROUP = "family"          # colour by group, "" for one colour
FIT = "linear"            # "linear" or "none"
FIT_PER_GROUP = False     # one fit per group instead of one overall
XLABEL = "$E_N$ (eV)"
YLABEL = "log$_{10}$ TOF (s$^{-1}$)"
# ---- draw ----
ax = chart()
x, y = column(X, "number"), column(Y, "number")
g = column(GROUP) if GROUP else ["all"] * len(x)
grps = unique(g)
for j, k in enumerate(grps):
    idx = [i for i in range(len(x)) if g[i] == k]
    ax.scatter(x[idx], y[idx], s=18, color=PALETTE[j % len(PALETTE)], edgecolor=INK, linewidth=0.5,
               label=k if GROUP else None, zorder=3)


def fit_line(xs, ys, col, tag):
    ok = ~(np.isnan(xs) | np.isnan(ys))
    a, b = np.polyfit(xs[ok], ys[ok], 1)
    r2 = 1 - np.sum((ys[ok] - (a * xs[ok] + b)) ** 2) / np.sum((ys[ok] - ys[ok].mean()) ** 2)
    xx = np.linspace(np.nanmin(xs), np.nanmax(xs), 50)
    ax.plot(xx, a * xx + b, color=col, lw=1.0, zorder=2)
    return "%sy = %.3g x %s %.3g, R$^2$ = %.2f" % (tag, a, "+" if b >= 0 else "−", abs(b), r2)


if FIT == "linear":
    if FIT_PER_GROUP and GROUP:
        notes = [fit_line(x[[i for i in range(len(x)) if g[i] == k]], y[[i for i in range(len(x)) if g[i] == k]],
                          PALETTE[j % len(PALETTE)], k + ": ") for j, k in enumerate(grps)]
    else:
        notes = [fit_line(x, y, INK, "")]
    ax.text(0.03, 0.04, "\n".join(notes), transform=ax.transAxes, fontsize=SMALL, va="bottom", ha="left")
ax.set_xlabel(XLABEL)
ax.set_ylabel(YLABEL)
if GROUP:
    ax.legend(loc="upper right")
finish(ax)
