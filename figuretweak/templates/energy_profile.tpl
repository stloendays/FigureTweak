# ---- settings ----
STATE = "state"           # states in reaction order
ENERGY = "energy"         # relative energy of each state
PATHWAY = "pathway"       # one profile per pathway, "" for one
YLABEL = "$\\Delta E$ (eV)"
SHOW_VALUES = True        # write each level's energy above it
LEVEL_WIDTH = 0.55        # length of each level (0-1 of a step)
# ---- draw ----
ax = chart(bottom=17.0)
st, en = column(STATE), column(ENERGY, "number")
pw = column(PATHWAY) if PATHWAY else ["all"] * len(st)
states = unique(st)
for j, k in enumerate(unique(pw)):
    idx = [i for i in range(len(st)) if pw[i] == k]
    col = PALETTE[j % len(PALETTE)]
    pos = [states.index(st[i]) for i in idx]
    for a in range(len(idx) - 1):
        ax.plot([pos[a] + LEVEL_WIDTH / 2, pos[a + 1] - LEVEL_WIDTH / 2], [en[idx[a]], en[idx[a + 1]]], color=col,
                lw=0.7, ls=(0, (2, 1.5)), zorder=1)
    for m, (p, i) in enumerate(zip(pos, idx)):
        ax.plot([p - LEVEL_WIDTH / 2, p + LEVEL_WIDTH / 2], [en[i], en[i]], color=col, lw=2.2,
                solid_capstyle="butt", zorder=2, label=k if (PATHWAY and m == 0) else None)
        if SHOW_VALUES:
            ax.text(p, en[i], "%.2f" % en[i], ha="center", va="bottom", fontsize=SMALL, color=col)
ax.set_xticks(range(len(states)), states, rotation=30, ha="right")
ax.tick_params(axis="x", length=0)
ax.axhline(0, color=MUTED, lw=0.5, ls=":", zorder=0)
ax.margins(x=0.06, y=0.15)
ax.set_ylabel(YLABEL)
if PATHWAY:
    ax.legend(loc="lower left")
finish(ax)
