import { parse, View } from "vega";
import { compile } from "vega-lite";

export async function render(spec) {
  const view = new View(parse(compile(spec).spec), { renderer: "none" });
  try {
    return await view.toSVG();
  } finally {
    view.finalize();
  }
}
