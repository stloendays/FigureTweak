# ---- settings ----
LABEL = "item"            # one row per item
LEFT = "rank_a"           # left column (rank or value)
RIGHT = "rank_b"          # right column
LEFT_NAME = "Rank by A"
RIGHT_NAME = "Rank by B"
RANKS = True              # True: 1 at the top; False: values, larger at the top
HIGHLIGHT_ITEM = "Cat B"  # one item drawn in the highlight colour, "" for none
# ---- draw ----
ax = chart(left=16.0, right=16.0, bottom=4.0, top=10.0)
lab, l, r = column(LABEL), column(LEFT, "number"), column(RIGHT, "number")
for i in range(len(lab)):
    hot = lab[i] == HIGHLIGHT_ITEM
    col = HIGHLIGHT if hot else (PALETTE[0] if (r[i] < l[i]) == RANKS else MUTED)
    ax.plot([0, 1], [l[i], r[i]], color=col, lw=1.4 if hot else 0.9, zorder=3 if hot else 2)
    ax.scatter([0, 1], [l[i], r[i]], s=14, color=col, zorder=4)
    ax.text(-0.06, l[i], lab[i], ha="right", va="center", fontweight="bold" if hot else "normal")
    ax.text(1.06, r[i], lab[i], ha="left", va="center", fontweight="bold" if hot else "normal")
ax.text(0, 1.04, LEFT_NAME, transform=ax.get_xaxis_transform(), ha="center", va="bottom", fontweight="bold")
ax.text(1, 1.04, RIGHT_NAME, transform=ax.get_xaxis_transform(), ha="center", va="bottom", fontweight="bold")
lo, hi = np.nanmin(np.r_[l, r]), np.nanmax(np.r_[l, r])
pad = (hi - lo) * 0.06 or 0.5
ax.set_ylim((hi + pad, lo - pad) if RANKS else (lo - pad, hi + pad))
ax.set_xlim(-0.08, 1.08)
ax.axis("off")
finish(ax)
