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

## Frames and Origin-style axis tools (FigureTweak 1.1, tweak.py `TWEAK_VERSION = "1.1"`)

All stored in `<stem>.tweaks.json`, so the script stays the source and every setting can be switched back:

- **Frame** per chart (`frame`: `full` 有框线, `open` 无框线 = only the two sides carrying tick labels, `none` 无轴线), or
  for the whole figure on `fig/figure` together with `textbox: "none"` (boxed annotations lose the border, and a white
  fill left without a border goes too; an item's own `border: false` keeps its white fill) and `tickdir`. A chart's own setting wins. The canvas panel's 「把这三项用到全稿所有图」 writes the
  figure-level setting into every figure of the paper and re-renders them.
- **Axis dialog** per chart: `xlim`/`ylim`, `xscale`/`yscale`, `xstep`/`ystep`, `xminor`/`yminor`, `grid`,
  `tickdir`; applied before the figure is keyed, so the new tick labels are editable too.
- **Reference lines**: `refs` `[{axis, v, label, color, ls, lw}]` in data coordinates; the view keeps its limits.
- **Legend**: `frame`, `loc`. **Text**: `border: false`.
- The editor's data reader shows data coordinates under the pointer (log axes included).

A paper whose `tweak.py` predates 1.1 shows none of this; re-run 接入新论文 on its figures folder: onboarding upgrades
`tweak.py` and re-renders with the pixel comparison.

## New figures from chart templates (FigureTweak 1.2)

The start page's 「新建图表」 (on a paper's page) makes a new editable figure from one of 43 chart templates
(1.3; the gallery follows hiplot.cn's): bar + error bars, grouped / stacked bar, waterfall, lollipop, slope, bump
(multi-period ranks), dumbbell, pyramid (back to back), diverging bar, range bar, Pareto, polar bar / rose, dot
matrix; box + points, violin, raincloud, ridgeline, density, histogram, Q-Q; scatter + fit, parity, bubble, contour,
volcano; correlation heatmap, PCA (loadings, group ellipses), parallel coordinates, radar; area / streamgraph,
dual y axis, multi-line, heatmap; donut / pie, treemap, waffle, Sankey; Venn (2-3 sets), UpSet; forest; ternary,
reaction energy profile. The user filters by purpose, loads a CSV/TSV or pastes from Excel, maps columns (guessed by type), previews
with the paper's own `style.py`, names the figure (and optionally its manuscript number), and it opens in the editor.

What it writes, in a new folder `<figures home>/<stem lower>/` beside the paper's other figure folders:
`make_<stem>.py` (settings block at the top, then shared helpers, then the drawing code; `STYLE_DIR = ".."` points
at the folder with the paper's `style.py` and `tweak.py`) and `<stem>_data.csv`. If the paper has no hooked Page,
the folder also gets the bundled house style as `style.py` plus `tweak.py`. The script is an ordinary figure script
from then on: change data, settings or drawing code and rerun it.

- Templates live in `figuretweak/templates/`: `<id>.tpl` (settings + drawing), `common.tpl` (table reading, palette
  from the paper's style constants `RU FE AMB OS DARK_B DARK_G RED INK MID`, CJK font fallback set after `Page()`),
  `catalog.json` (Chinese name, purpose, when to use, fields), `samples/<id>.csv`, `thumbs/<id>.png`.
- Field kinds in `catalog.json`: `text`/`number` (a column; `?` = optional), `label`, `bool`, `int`, `float`,
  `choice:val=名,...`, `value:FIELD` (one value of another field's column, e.g. the item to highlight).
- Adding a template: write `<id>.tpl` and `samples/<id>.csv`, add it to `catalog.json`, then run
  `python figuretweak/templates/make_thumbs.py <python with matplotlib>`: it renders every template from its sample
  data exactly as the start page would, fails on any template that does not render or is not editable, and writes
  the thumbnails.
- The repository is public: sample data must be synthetic, never numbers from an unpublished paper.


## Data, added series and template sources (FigureTweak 1.3, tweak.py `TWEAK_VERSION = "1.3"`)

The editor's 「数据」 button (or a chart's 「数据与系列」 panel) opens the data dialog:

- **Plotted values of any chart.** `tweak.apply` lists each chart's series in the keys file (`ids[<axes>].series`:
  `sid` `bars/i`, `errorbar/i`, `line/i`, `scatter/i`, `image/i`; columns, rows, which columns may change). Edits are
  stored on the chart, `"<axes key>": {"data": {"bars/0": {"y": [...]}, "line/1": {"x": [...], "y": [...]}}}`, and
  applied before the figure is keyed; the view refits where the script left autoscaling on. The script and its data
  files are not touched. Values the script computed from the data (fit lines, numbers written in cells, bar-top
  labels) do not follow; for those change the source.
- **Added series.** `"series": [{"id": "s1", "type": "bar"|"line"|"scatter"|"area", "x": [...], "y": [...],
  "err": [...], "label", "color", "dodge", "band", "marker", "legend"}]` on the chart's entry. x may be category or
  tick-label names. Added bars with `dodge` share the width of the script's bar group: the script's bars (and their
  error bars) move aside; on a horizontal bar chart they lie down too. Labelled series are appended to the chart's
  legend. Their parts are keyed `<axes>/series/<id>/<part>` (bar, err, line, band, points, area) and edit like any
  other artist.
- **Template figures** (scripts with `# ---- chart settings ----` and `chart template "<id>"` in the docstring): the
  dialog edits `<stem>_data.csv` (rows, columns, names) and the settings block (column mapping, options, size, title),
  or switches the figure to another template (rewrites the drawing code; hand edits keyed to the old chart may orphan).
  `chart_templates.script_info / update_script` do the rewriting.
- **Other figures** list the data files their script names in quotes; 「打开」 opens one in its program and
  「按现在的数据重新出图」 reruns the script.

A paper whose `tweak.py` predates 1.3 shows no plotted data: re-run 接入新论文 on its figures folder.

## Inserted charts, colour scope, grid (FigureTweak 1.4, tweak.py `TWEAK_VERSION = "1.4"`)

- **Insert a chart into an existing figure**: 插入 → 图表. The editor writes `<stem>_charts/<id>.py` (a chart template
  script) and `<id>.csv` beside the figure and records `"fig/added/<id>": {"add": {"type": "chart", "script": ...,
  "x_mm", "y_mm", "w_mm", "h_mm"}}`. `tweak.apply` runs that script first, with `FIG` and `BOX` given (templates
  draw through `box_ax`, `PAGE_W`/`PAGE_H` and offsets `OX`/`OY` in `common.tpl`), so its axes are keyed
  `fig/added/<id>/ax<n>/...` wherever the box moves and edit like any chart. Endpoints `/chart_insert`,
  `/chart_source`, `/chart_save` (data, settings, title, chart type).
- **Colour scope** for lines, bands, points, patches: 只改这一个 (the item), 本图表同色一起改 (the mapping goes on the
  chart's `axes` entry: line, band, markers and legend key change together; the default), 全图同色一起改 (`fig/figure`).
- **Several selected**: colour, line width, opacity, line style for all of them.
- **Grid**: gridlines carry ids `<axes gid>_gx<n>` / `_gy<n>`, so switching them off previews at once; `fig/figure`
  `grid` sets every chart that has no own setting, and 「把这几项用到全稿所有图」 includes it.
- A paper whose tweak.py is older than the editor's gets a note with an upgrade button on the canvas panel
  (`/tweak_home`; the button opens the hub's onboarding for that folder, which re-renders with the pixel check).

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
