"""Render every chart template with its sample data, check it, and write the gallery thumbnails (thumbs/<id>.png).

    python figuretweak/templates/make_thumbs.py [<python with matplotlib>] [template id ...]

Each template is assembled exactly as the start page assembles it, in a scratch folder with the fallback house style,
and must render and leave an editable figure (a <stem>.tweak_keys.json). Doubles as the template test.
"""
import os
import shutil
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
import chart_templates as ct  # noqa: E402


def main():
    python = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1].endswith(".exe") else sys.executable
    only = [a for a in sys.argv[1:] if not a.endswith(".exe")]
    from PIL import Image
    bad = 0
    for t in ct.catalog()["templates"]:
        if only and t["id"] not in only:
            continue
        d = tempfile.mkdtemp(prefix="ft_tpl_")
        try:
            shutil.copy(os.path.join(HERE, "ft_style.py"), os.path.join(d, "style.py"))
            shutil.copy(os.path.join(os.path.dirname(HERE), "tweak.py"), os.path.join(d, "tweak.py"))
            stem = "T_" + t["id"]
            ct.write_csv(ct.parse_table(ct.sample(t["id"])), os.path.join(d, stem + "_data.csv"))
            script = os.path.join(d, "make_%s.py" % stem.lower())
            open(script, "w", encoding="utf-8").write(ct.make_script(t["id"], stem, stem + "_data.csv", ".",
                                                                     t["size"][0], t["size"][1], "",
                                                                     ct.defaults(t["id"])))
            log = ct.render(script, python)
            ok = log.startswith("OK") and os.path.exists(os.path.join(d, stem + ".tweak_keys.json"))
            print("%-15s %s" % (t["id"], "ok" if ok else "FAILED\n" + log))
            if not ok:
                bad += 1
                continue
            with Image.open(os.path.join(d, stem + ".png")) as im:
                im = im.convert("RGB")
                im.thumbnail((520, 520))
                im.save(os.path.join(HERE, "thumbs", t["id"] + ".png"), optimize=True)
        finally:
            shutil.rmtree(d, ignore_errors=True)
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
