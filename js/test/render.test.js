import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { render } from "../dist/index.js";

const spec = JSON.parse(await readFile(new URL("bar.json", import.meta.url)));

test("bar chart matches the reviewed SVG", async () => {
  const expected = await readFile(new URL("bar.svg", import.meta.url), "utf8");
  assert.equal(await render(spec), expected.trimEnd());
});

test("different charts do not share state", async () => {
  const first = await render({ ...spec, title: "First chart" });
  const second = await render({ ...spec, mark: "line", title: "Second chart" });
  assert.match(first, /First chart/);
  assert.doesNotMatch(first, /Second chart/);
  assert.match(second, /Second chart/);
  assert.doesNotMatch(second, /First chart/);
  assert.equal(await render({ ...spec, title: "First chart" }), first);
});

test("layered specifications render", async () => {
  const { mark, ...base } = spec;
  const svg = await render({ ...base, layer: [{ mark: "line" }, { mark: "point" }] });
  assert.match(svg, /mark-line/);
  assert.match(svg, /mark-symbol/);
});

test("invalid specifications fail", async () => {
  await assert.rejects(render({}), /Invalid specification/);
});
