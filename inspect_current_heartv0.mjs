import fs from "node:fs/promises";
import path from "node:path";
import { FileBlob, PresentationFile } from "@oai/artifact-tool";

const root = "/Users/phillicia/Desktop/School/Spatial/heart v3";
const input = path.join(root, "Pitch Media", "HEARTV0-current-source-export.pptx");
const output = path.join(root, ".heartv0-current-inspect");
await fs.mkdir(output, { recursive: true });

const presentation = await PresentationFile.importPptx(await FileBlob.load(input));
for (const [index, slide] of presentation.slides.items.entries()) {
  const png = await presentation.export({ slide, format: "png", scale: 1 });
  await fs.writeFile(path.join(output, `slide-${String(index + 1).padStart(2, "0")}.png`), new Uint8Array(await png.arrayBuffer()));
}
const montage = await presentation.export({ format: "webp", montage: true });
await fs.writeFile(path.join(output, "montage.webp"), new Uint8Array(await montage.arrayBuffer()));
const inspected = await presentation.inspect({
  kind: "slide,textbox,image,notes,layout",
  maxChars: 100000,
});
await fs.writeFile(path.join(output, "inspect.ndjson"), inspected.ndjson);
console.log(JSON.stringify({ slideCount: presentation.slides.items.length, output }, null, 2));
