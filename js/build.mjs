import { build } from "esbuild";
import { readFile, readdir, writeFile } from "node:fs/promises";

await build({
  entryPoints: ["src/index.js"],
  bundle: true,
  format: "esm",
  outdir: "dist",
  minify: true,
  platform: "browser",
  // QuickJS does not provide the structuredClone web API.
  inject: ["src/structured-clone-shim.js"],
  legalComments: "linked",
});

const lock = JSON.parse(await readFile("package-lock.json", "utf8"));
const notices = [];
for (const [directory, dependency] of Object.entries(lock.packages)) {
  if (!directory || dependency.dev) continue;
  const files = (await readdir(directory)).filter(name => /^(licen[cs]e|copying)([.-]|$)/i.test(name));
  if (!files.length) throw new Error(`Missing license file for ${directory}`);
  notices.push(`${directory} ${dependency.version} (${dependency.license})`);
  for (const file of files.sort()) {
    notices.push(await readFile(`${directory}/${file}`, "utf8"));
  }
}
await writeFile("dist/THIRD-PARTY-NOTICES.txt", notices.join("\n\n"));
