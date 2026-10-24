---
name: figure-tweak
description: Make code-generated matplotlib paper figures hand-editable in the FigureTweak (论文调图) browser editor, and drive it — onboard a paper's figure folder, keep figures editable when writing or changing figure scripts, open a paper or a figure, label figures with the manuscript's numbers, and debug editor problems (text that will not edit, a figure missing from the list, a preview that looks wrong). Use for 调图, 图层编辑器, 手动微调论文图, 论文调图, FigureTweak, make this figure editable, tweaks.json, tweak_keys.json, figure_labels.json.
---

# FigureTweak (论文调图)

FigureTweak lets a person adjust finished matplotlib figures by hand in a browser (layers, properties, colours,
drag and drop; BioRender-like) while the figure script stays the single source. Hand edits are stored as data in
`<stem>.tweaks.json` next to the figure and re-applied on every render, so rerunning the script never loses them.

Program: `FigureTweak.exe` from the GitHub releases of this repository, or `pythonw figuretweak/figure_hub.py` from a
checkout. It opens a start page listing every paper on the machine whose figures are editable, with thumbnails.

## How a figure becomes editable

The editor understands figures drawn on a `Page` (a matplotlib figure laid out in millimetres) and saved with
`pg.save(HERE, stem)`, where `Page.save` calls `tweak.apply` just before `savefig`:

```python
def save(self, here, stem, rerun_args=None):
    import tweak                            # hand adjustments from <stem>.tweaks.json (figure editor)
    tweak.apply(self.fig, here, stem, rerun_args)
    for ext in ("svg", "pdf", "png"):       # figure facecolour: white unless the editor changed the background
        self.fig.savefig(os.path.join(here, "%s.%s" % (stem, ext)), dpi=600, facecolor=self.fig.get_facecolor())
```

`tweak.apply` reads `<stem>.tweaks.json`, applies it, tags every artist with an SVG id and writes
`<stem>.tweak_keys.json` (what can be edited, and the command that re-renders the figure). A figure is editable once
that file exists.

**Onboard a paper in one step**: start page → 接入新论文 → choose the folder holding `style.py` (the module with
`class Page`) and the figure scripts. Or drop that folder on `FigureTweak.exe`. Onboarding inserts the two lines
above, puts `tweak.py` next to `style.py`, reruns every script that saves through the Page with the chosen Python,
compares each PNG with the previous one pixel by pixel, and writes `figure_labels.json`. Expect "所有原有 PNG 逐像素一致".
A PNG that changed means the script is not deterministic or the old PNG was stale; look before committing.

Scripts that call `savefig` directly are listed, not changed. Convert them to a Page, or call
`tweak.apply(fig, HERE, stem)` right before their `savefig` and save with `facecolor=fig.get_facecolor()`.

## Rules for figure scripts

- **Text must stay text**: `svg.fonttype: none` (and `pdf.fonttype: 42`). With glyph paths the editor cannot reword.
- **Build what should be editable as real artists**: labels as `ax.text` / `ax.annotate` (leader lines as
  `annotate(..., arrowprops=...)` so the line follows the label), category labels as tick labels, keys as `legend`,
  markers as `scatter`. Give series a `label=`; the editor shows it as the layer name.
- **Keep text strings stable between runs.** A text's key is its string; a changed string orphans its edits (the
  render prints `tweaks: ... match no artist any more`).
- **One script drawing several figures** passes the arguments that redraw just one: `pg.save(HERE, stem,
  rerun_args=[str(n)])`, and the script must accept them.
- **Same base size for the same role** (panel letters, titles, axis titles, ticks, legends) across a paper's figures:
  the editor's consistency check (全稿一致性) compares them and can set one size for all outliers.
- **Commit `<stem>.tweaks.json` and `<stem>.tweak_keys.json`** with the figure; they are part of it.

## figure_labels.json

At the figures root, maps figures to the manuscript's numbers; its order is the order the editor lists them in.
Key a figure by its stem, or by its path below the root when two figures share a stem:

```json
{"main/fig1/Fig1": "Fig. 1", "FigField": "Fig. 2", "si/fig1/Fig1": "Supplementary Fig. 1"}
```

Labels drive the start page's grouping: "Fig. N" is main text, "Extended Data Fig. N" and "Supplementary Fig. N"
get their own sections.

## Where things live

- Start page registry: `%LOCALAPPDATA%\figure_hub\papers.json` (`scan_roots`, and `papers` display names keyed by a
  repository's main checkout). Folders added on the page and renamed papers go to `config.json` beside it.
- A paper is a git repository; each worktree is a version. Outside git, the folder holding `tweak.py` or
  `figure_labels.json` is the paper.
- Only paths with a figure-ish folder name (`fig`, `plot`, `graph`, `chart`, `图`) are searched more than two levels
  inside a repository, so keep figures under such a folder.

## Debugging

| Symptom | Cause and fix |
|---|---|
| Figure missing from the start page | No `*.tweak_keys.json` yet (render it once through `Page.save`), or the folder is outside the scan: 添加文件夹 |
| Two figures, one shown | Same stem under one root: both are listed by path; label them by path in `figure_labels.json` |
| Huge, letter-spaced text after an edit (editor before 1.0) | Mathtext (`$\tau$`) is one `<tspan>` per glyph; fixed in 1.0 |
| Edits vanished after a rerun | The text string changed in the script; re-key the entry in `<stem>.tweaks.json` |
| Background colour from the editor not kept | `savefig(facecolor="white")` literal; use `self.fig.get_facecolor()` |
| Re-render fails in the editor | The render log (出图日志) shows the script's last lines; the command is in `<stem>.tweak_keys.json` → `meta` |

Verify a change to a figure script by rerendering and comparing the PNG pixel by pixel with the previous one.
