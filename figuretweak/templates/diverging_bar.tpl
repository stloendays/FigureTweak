# ---- settings ----
LABEL = "factor"          # one bar per row
VALUE = "change"          # positive and negative values
SORT = True               # largest at the top
POSITIVE_GOOD = True      # True: positive bars in the main colour, negative in the highlight colour
XLABEL = "change (%)"
SHOW_VALUES = True
VALUE_FORMAT = "%+.1f"
# ---- draw ----
ax = chart(left=22.0, right=8.0)
lab, v = column(LABEL), column(VALUE, "number")
o = sorted(range(len(v)), key=lambda i: v[i]) if SORT else list(range(len(v)))[::-1]
lab, v = [lab[i] for i in o], v[o]
y = np.arange(len(v))
good, bad = PALETTE[0], HIGHLIGHT
cols = [(good if (val >= 0) == POSITIVE_GOOD else bad) for val in v]
ax.barh(y, v, height=0.65, color=cols, zorder=2)
ax.axvline(0, color=INK, lw=0.7, zorder=3)
span = np.nanmax(np.abs(v)) or 1.0
if SHOW_VALUES:
    for i, val in enumerate(v):
        ax.text(val + (0.02 if val >= 0 else -0.02) * span, i, VALUE_FORMAT % val, va="center",
                ha="left" if val >= 0 else "right", fontsize=SMALL)
ax.set_xlim(-span * 1.25 if np.nanmin(v) < 0 else -span * 0.05, span * 1.25 if np.nanmax(v) > 0 else span * 0.05)
ax.set_yticks(y, lab)
ax.tick_params(axis="y", length=0)
ax.set_ylim(-0.6, len(v) - 0.4)
ax.set_xlabel(XLABEL)
finish(ax)
