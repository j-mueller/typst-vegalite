"""Exercise the assembled Typst package with an isolated package directory."""

import argparse
import json
import os
import shutil
import subprocess
import tempfile
import tomllib
import xml.etree.ElementTree as ET
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--package", required=True, type=Path)
    parser.add_argument("--ctxjs", required=True, type=Path)
    parser.add_argument("--examples", required=True, type=Path)
    parser.add_argument("--spec", required=True, type=Path)
    parser.add_argument("--golden", required=True, type=Path)
    args = parser.parse_args()
    manifest = tomllib.loads((args.package / "typst.toml").read_text())["package"]
    runtime = tomllib.loads((args.ctxjs / "typst.toml").read_text())["package"]
    version = subprocess.check_output(["typst", "--version"], text=True).strip()
    assert manifest["compiler"] == "0.13.0", (
        "Update the minimum-version test with the manifest"
    )

    with tempfile.TemporaryDirectory(prefix="nulite-test-") as temporary:
        root = Path(temporary)
        cache = root / "packages"
        for package, source in [(manifest, args.package), (runtime, args.ctxjs)]:
            target = cache / "preview" / package["name"] / package["version"]
            target.parent.mkdir(parents=True, exist_ok=True)
            target.symlink_to(source)
        env = dict(
            os.environ,
            TYPST_PACKAGE_PATH=str(cache),
            TYPST_PACKAGE_CACHE_PATH=str(cache),
        )
        shutil.copytree(args.examples, root / "examples")
        (root / "spec.json").write_text(args.spec.read_text())
        prefix = f"""#import "@preview/nulite:{manifest["version"]}": render
#set page(width: 400pt, height: 400pt, margin: 10pt)
#let spec = json("spec.json")
"""

        def compile_document(name, success=True):
            result = subprocess.run(
                [
                    "typst",
                    "compile",
                    "--root",
                    str(root),
                    str(root / name),
                    str(root / (Path(name).stem + ".pdf")),
                ],
                env=env,
                capture_output=True,
                text=True,
                check=False,
            )
            if success and result.returncode:
                raise AssertionError(f"{version}: {name} failed:\n{result.stderr}")
            if not success and not result.returncode:
                raise AssertionError(f"{version}: {name} unexpectedly succeeded")
            return result

        (root / "charts.typ").write_text(
            prefix
            + """
#show image: it => {
  [#metadata((
    svg: str(it.source),
    width: it.width.length.pt(),
    height: it.height.length.pt(),
  )) <chart>]
  it
}
#render(width: 200pt, height: 150pt, spec)
#pagebreak()
#render(spec)
#pagebreak()
#block(width: 300pt, height: 200pt)[
  #render(width: 50% + 10pt, height: 50%, spec)
]
#pagebreak()
#render(width: 200pt, height: 150pt, zoom: 2, spec)
#pagebreak()
#render(width: 200pt, height: 150pt, spec + (title: "Second chart", mark: "line"))
#pagebreak()
#render(width: 200pt, height: 150pt, spec)
#pagebreak()
#let layered = {
  let base = spec
  let _ = base.remove("mark")
  base + (layer: ((mark: "line"), (mark: "point")))
}
#render(width: 200pt, height: 150pt, layered)
"""
        )
        compile_document("charts.typ")
        query = subprocess.run(
            [
                "typst",
                "query",
                "--root",
                str(root),
                str(root / "charts.typ"),
                "<chart>",
                "--field",
                "value",
            ],
            env=env,
            capture_output=True,
            text=True,
            check=True,
        )
        charts = json.loads(query.stdout)
        assert len(charts) == 7, charts
        assert charts[0]["svg"] == args.golden.read_text().rstrip(), (
            "WASM output differs from Node golden"
        )
        assert charts[5]["svg"] == charts[0]["svg"], "Chart state leaks between calls"
        assert (
            "Second chart" in charts[4]["svg"]
            and "Second chart" not in charts[0]["svg"]
        )
        for chart, (width, height) in zip(
            charts,
            [
                (200, 150),
                (300, 200),
                (160, 100),
                (200, 150),
                (200, 150),
                (200, 150),
                (200, 150),
            ],
        ):
            assert chart["width"] == width, chart["width"]
            assert chart["height"] == height, chart["height"]
        normal = ET.fromstring(charts[0]["svg"])
        zoomed = ET.fromstring(charts[3]["svg"])
        for dimension in ["width", "height"]:
            assert float(zoomed.attrib[dimension]) < float(normal.attrib[dimension])
        assert "mark-line" in charts[6]["svg"] and "mark-symbol" in charts[6]["svg"]

        (root / "unbounded.typ").write_text(
            prefix
            + """
#set page(width: auto, height: auto)
#render(spec)
#render(width: 0% + 100pt, height: 100pt, spec)
"""
        )
        compile_document("unbounded.typ")
        compile_document("examples/bar-chart.typ")
        failures = [
            ("zoom-zero", "#render(zoom: 0, spec)", "zoom must be positive and finite"),
            (
                "zoom-negative",
                "#render(zoom: -1, spec)",
                "zoom must be positive and finite",
            ),
            (
                "zoom-infinite",
                "#render(zoom: calc.inf, spec)",
                "zoom must be positive and finite",
            ),
            (
                "width-zero",
                "#render(width: 0pt, spec)",
                "width must be positive and finite",
            ),
            (
                "height-negative",
                "#render(height: -1pt, spec)",
                "height must be positive and finite",
            ),
            (
                "unbounded-relative",
                "#set page(height: auto)\n#render(height: 100%, spec)",
                "relative height requires a bounded container",
            ),
            ("invalid-spec", "#render((:))", "plugin errored"),
        ]
        for name, body, error in failures:
            filename = name + ".typ"
            (root / filename).write_text(prefix + body)
            result = compile_document(filename, success=False)
            assert error in result.stderr, result.stderr
        print(
            f"{version}: golden SVG, repeated charts, sizing, zoom, unbounded layout, "
            f"and {len(failures)} error cases passed"
        )


if __name__ == "__main__":
    main()
