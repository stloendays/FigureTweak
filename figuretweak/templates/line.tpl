# ---- settings ----
X = "temperature"         # x values
Y = "conversion"          # y values
SERIES = "catalyst"       # one line per series, "" for a single line
ERR = "sd"                # shaded +/- band, "" for none
MARKERS = True
LOG_X = False
LOG_Y = False
XLABEL = "temperature (K)"
YLABEL = "conversion (%)"
LABEL_ENDS = True         # write each series' name at its last point instead of a legend
# ---- draw ----
ax = chart(right=12.0 if LABEL_ENDS and SERIES else 3.0)
x, y = column(X, "number"), column(Y, "number")
e = column(ERR, "number")
s = column(SERIES) if SERIES else ["all"] * len(x)
marks = "osD^v<>"
for j, k in enumerate(unique(s)):
    idx = sorted([i for i in range(len(x)) if s[i] == k], key=lambda i: x[i])
    col = PALETTE[j % len(PALETTE)]
    if e is not None:
        ax.fill_between(x[idx], y[idx] - e[idx], y[idx] + e[idx], color=col, alpha=0.18, lw=0, zorder=1)
    ax.plot(x[idx], y[idx], color=col, lw=1.2, marker=marks[j % len(marks)] if MARKERS else None, ms=3.2,
            mec=INK, mew=0.4, label=k if SERIES else None, zorder=2)
    if LABEL_ENDS and SERIES:
        ax.annotate(k, (x[idx[-1]], y[idx[-1]]), xytext=(4, 0), textcoords="offset points", va="center",
                    color=col, fontweight="bold", annotation_clip=False)
if LOG_X:
    ax.set_xscale("log")
if LOG_Y:
    ax.set_yscale("log")
ax.set_xlabel(XLABEL)
ax.set_ylabel(YLABEL)
if SERIES and not LABEL_ENDS:
    ax.legend(loc="best")
finish(ax)
