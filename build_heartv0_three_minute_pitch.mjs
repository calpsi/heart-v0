import fs from "node:fs/promises";
import path from "node:path";
import { Presentation, PresentationFile } from "@oai/artifact-tool";

const ROOT = "/Users/phillicia/Desktop/School/Spatial/heart v3";
const BUILD = path.join(ROOT, ".heartv0-three-minute-build");
const OUTPUT = path.join(ROOT, "Pitch Media", "HEARTV0-3-minute-pitch-refined.pptx");
const FONT = "Helvetica Neue";

const C = {
  white: "#FFFFFF",
  ink: "#111318",
  muted: "#5F6672",
  line: "#DADDE3",
  soft: "#F5F6F8",
  softRose: "#FCEFF3",
  softViolet: "#F2F0FA",
  rose: "#C43D64",
  roseDark: "#8E2948",
  violet: "#6850A5",
  nusBlue: "#003D7C",
};

const A = (...parts) => path.join(ROOT, ...parts);
const assets = {
  early: A("HeartAssets/previews/Heart_01_CardiogenicRegion_assembled.png"),
  looping: A("HeartAssets/previews/Heart_04_CardiacLooping_assembled.png"),
  developed: A("HeartAssets/previews/Heart_10_CirculatoryTransition_layers.png"),
  developedAssembled: A("HeartAssets/previews/Heart_10_CirculatoryTransition_assembled.png"),
  guided: A("Documentation/verification/retest-oct28/guided-final.png"),
  morph: A("Documentation/verification/retest-oct28/morph-final.png"),
  explore: A("Documentation/verification/retest-oct28/free-static-layout-repaired.png"),
  firstRender: A("Documentation/verification/heart-project-first-render.png"),
  inProgress: A("Documentation/verification/guided-integrated-in-progress.png"),
  finalBuild: A("Documentation/verification/retest-oct28/guided-layout-repaired.png"),
  nusLogo: A("Pitch Media/official-template-assets/nus-logo-crop-2.jpg"),
};

async function bytes(file) {
  const data = await fs.readFile(file);
  return data.buffer.slice(data.byteOffset, data.byteOffset + data.byteLength);
}

function textBox(slide, text, position, style = {}) {
  const shape = slide.shapes.add({
    geometry: "textbox",
    position,
    fill: "none",
    line: { style: "solid", fill: "none", width: 0 },
  });
  shape.text = text;
  shape.text.style = {
    typeface: FONT,
    fontSize: style.fontSize ?? 24,
    bold: style.bold ?? false,
    color: style.color ?? C.ink,
    alignment: style.alignment ?? "left",
    verticalAlignment: style.verticalAlignment ?? "middle",
    autoFit: "shrinkText",
  };
  return shape;
}

function rect(slide, position, fill, line = fill, radius = null) {
  return slide.shapes.add({
    geometry: radius ? "roundRect" : "rect",
    position,
    fill,
    line: { style: "solid", fill: line, width: line === fill ? 0 : 1 },
    borderRadius: radius ?? undefined,
  });
}

function rule(slide, left, top, width, color = C.rose, height = 3) {
  return rect(slide, { left, top, width, height }, color);
}

async function image(slide, file, position, opts = {}) {
  const ext = path.extname(file).toLowerCase();
  const contentType = ext === ".jpg" || ext === ".jpeg" ? "image/jpeg" : "image/png";
  return slide.images.add({
    blob: await bytes(file),
    contentType,
    alt: opts.alt ?? path.basename(file),
    fit: opts.fit ?? "contain",
    position,
    geometry: opts.geometry,
    borderRadius: opts.borderRadius,
  });
}

async function footer(slide) {
  slide.background.fill = C.white;
  rule(slide, 32, 638, 1216, C.line, 1);
  rule(slide, 32, 638, 160, C.nusBlue, 3);
  textBox(slide, "Spatial Computing and AI\nSemester 1 AY 2026/2027", { left: 32, top: 652, width: 275, height: 44 }, {
    fontSize: 11,
    bold: true,
  });
  await image(slide, assets.nusLogo, { left: 1128, top: 650, width: 118, height: 55 }, {
    fit: "contain",
    alt: "National University of Singapore logo",
  });
}

function title(slide, kicker, heading, options = {}) {
  textBox(slide, kicker.toUpperCase(), { left: 64, top: 42, width: 440, height: 24 }, {
    fontSize: 12,
    bold: true,
    color: C.rose,
  });
  textBox(slide, heading, { left: 64, top: 68, width: options.width ?? 1110, height: options.height ?? 64 }, {
    fontSize: options.fontSize ?? 39,
    bold: true,
    color: C.ink,
  });
  rule(slide, 64, 138, 84, C.rose, 4);
}

function metric(slide, value, label, left, top, color) {
  textBox(slide, value, { left, top, width: 155, height: 48 }, { fontSize: 37, bold: true, color });
  textBox(slide, label, { left, top: top + 45, width: 190, height: 40 }, { fontSize: 14, color: C.muted });
}

const presentation = Presentation.create({ slideSize: { width: 1280, height: 720 } });

// Slide 1 — 15 seconds
{
  const slide = presentation.slides.add();
  await footer(slide);
  textBox(slide, "APPLE VISION PRO LEARNING APP", { left: 64, top: 142, width: 390, height: 25 }, {
    fontSize: 12,
    bold: true,
    color: C.rose,
  });
  textBox(slide, "HeartV0", { left: 64, top: 177, width: 560, height: 88 }, {
    fontSize: 62,
    bold: true,
  });
  textBox(slide, "See the heart take shape from zero", { left: 64, top: 273, width: 530, height: 90 }, {
    fontSize: 30,
    color: C.roseDark,
  });
  textBox(slide, "Cardiac development through spatial computing", { left: 64, top: 398, width: 510, height: 52 }, {
    fontSize: 19,
    color: C.muted,
  });
  textBox(slide, "Phillicia Lim Pei Xian\nA0324165J", { left: 64, top: 535, width: 300, height: 48 }, {
    fontSize: 14,
    bold: true,
  });
  rect(slide, { left: 660, top: 78, width: 520, height: 510 }, C.soft, C.line, "rounded-2xl");
  await image(slide, assets.developed, { left: 700, top: 106, width: 440, height: 454 }, {
    alt: "Layered developed heart model used in HeartV0",
  });
  slide.speakerNotes.text = "[0:00–0:15] Good afternoon. I’m Phillicia, and this is HeartV0. The name describes the idea: seeing how the heart takes shape from its earliest developmental form. I built it as an Apple Vision Pro learning experience for cardiac embryology.";
}

// Slide 2 — 30 seconds
{
  const slide = presentation.slides.add();
  await footer(slide);
  title(slide, "The learning problem", "A 3D process taught in snapshots");
  textBox(slide, "Students must mentally reconstruct how the heart changes across space and time.", { left: 64, top: 158, width: 850, height: 46 }, {
    fontSize: 20,
    color: C.muted,
  });

  const stages = [
    [assets.early, "DAYS 18–19", "Cardiogenic field"],
    [assets.looping, "DAYS 23–28", "Cardiac looping"],
    [assets.developedAssembled, "WEEK 8", "Four-chamber heart"],
  ];
  for (let i = 0; i < stages.length; i++) {
    const [file, timing, label] = stages[i];
    const left = 64 + i * 292;
    rect(slide, { left, top: 225, width: 264, height: 318 }, C.soft, C.line, "rounded-xl");
    await image(slide, file, { left: left + 20, top: 240, width: 224, height: 218 }, { alt: label });
    textBox(slide, timing, { left: left + 20, top: 470, width: 220, height: 22 }, { fontSize: 11, bold: true, color: C.rose });
    textBox(slide, label, { left: left + 20, top: 498, width: 230, height: 28 }, { fontSize: 17, bold: true });
  }
  rect(slide, { left: 962, top: 225, width: 254, height: 318 }, C.softRose, C.softRose, "rounded-xl");
  textBox(slide, "1 IN 100", { left: 992, top: 292, width: 194, height: 58 }, { fontSize: 42, bold: true, color: C.roseDark, alignment: "center" });
  textBox(slide, "births are affected by congenital heart defects", { left: 992, top: 370, width: 194, height: 92 }, { fontSize: 17, alignment: "center" });
  slide.speakerNotes.text = "[0:15–0:45] Cardiac development is difficult because students usually see separate textbook stages. They must imagine the movement between them, then connect a developmental change to the congenital anatomy that appears later. Congenital heart defects affect about one in one hundred births, so understanding that process matters. HeartV0 makes the sequence visible and manipulable.\n\nSource: Centers for Disease Control and Prevention, About Congenital Heart Defects, https://www.cdc.gov/heart-defects/about/index.html";
}

// Slide 3 — 30 seconds
{
  const slide = presentation.slides.add();
  await footer(slide);
  title(slide, "The product", "Two paths through the same anatomy");
  textBox(slide, "GUIDED LEARNING", { left: 64, top: 182, width: 310, height: 25 }, { fontSize: 13, bold: true, color: C.roseDark });
  textBox(slide, "A structured explanation links each concept to the model and remembers progress.", { left: 64, top: 220, width: 365, height: 100 }, { fontSize: 22, bold: true });
  textBox(slide, "FREE EXPLORATION", { left: 64, top: 374, width: 310, height: 25 }, { fontSize: 13, bold: true, color: C.violet });
  textBox(slide, "Learners move through development, inspect anatomy and open related anomalies.", { left: 64, top: 412, width: 365, height: 100 }, { fontSize: 22, bold: true });
  textBox(slide, "The headset lets learners rotate, resize, separate and inspect the heart in their own space.", { left: 64, top: 548, width: 385, height: 56 }, { fontSize: 15, color: C.muted });
  rect(slide, { left: 482, top: 168, width: 734, height: 438 }, C.soft, C.line, "rounded-xl");
  await image(slide, assets.guided, { left: 494, top: 180, width: 710, height: 414 }, {
    fit: "cover",
    alt: "Current HeartV0 Guided Learning interface",
    geometry: "roundRect",
    borderRadius: "rounded-xl",
  });
  slide.speakerNotes.text = "[0:45–1:15] HeartV0 has two learning paths. Guided Learning explains the sequence in short steps while keeping the model interactive. Free Exploration lets the learner follow development, investigate structures and branch into congenital differences. Vision Pro supports the learning goal because the student can physically inspect depth and layers instead of reconstructing them from a flat page.";
}

// Slide 4 — 40 seconds
{
  const slide = presentation.slides.add();
  await footer(slide);
  title(slide, "Current build", "Development, interaction and clinical context", { width: 1120, fontSize: 37 });

  rect(slide, { left: 64, top: 172, width: 552, height: 280 }, C.soft, C.line, "rounded-xl");
  await image(slide, assets.morph, { left: 76, top: 184, width: 528, height: 256 }, {
    fit: "cover",
    alt: "HeartV0 interactive heart tube morphing view",
    geometry: "roundRect",
    borderRadius: "rounded-xl",
  });
  textBox(slide, "MORPHING", { left: 76, top: 462, width: 180, height: 22 }, { fontSize: 12, bold: true, color: C.rose });
  textBox(slide, "Key transitions can be played, scrubbed and opened for inspection.", { left: 76, top: 487, width: 520, height: 38 }, { fontSize: 16 });

  rect(slide, { left: 642, top: 172, width: 574, height: 280 }, C.soft, C.line, "rounded-xl");
  await image(slide, assets.explore, { left: 654, top: 184, width: 550, height: 256 }, {
    fit: "cover",
    alt: "Current HeartV0 Free Exploration interface",
    geometry: "roundRect",
    borderRadius: "rounded-xl",
  });
  textBox(slide, "CLINICAL CONNECTIONS", { left: 654, top: 462, width: 260, height: 22 }, { fontSize: 12, bold: true, color: C.violet });
  textBox(slide, "Developmental processes connect to related anatomy and anomalies.", { left: 654, top: 487, width: 540, height: 38 }, { fontSize: 16 });

  metric(slide, "52", "guided learning cards", 84, 545, C.rose);
  metric(slide, "16", "development and anomaly lessons", 352, 545, C.roseDark);
  metric(slide, "8", "exploration timeline stops", 708, 545, C.violet);
  metric(slide, "16", "3D teaching assets", 1000, 545, C.rose);
  slide.speakerNotes.text = "[1:15–1:55] The current build is much more complete than my earlier prototype. It now contains fifty-two guided cards across ten developmental and six anomaly lessons, plus eight exploration stops and sixteen teaching assets. Important transitions can now morph rather than only switching between static stages. Learners can inspect layers, compare later anatomy and follow links between normal development and related anomalies. Some intervals still use stage snapshots, so I describe this as key transition morphing rather than one continuous animation.\n\nInternal source: Documentation/RESEARCH_ITERATION.md and current October 28 build verification.";
}

// Slide 5 — 35 seconds
{
  const slide = presentation.slides.add();
  await footer(slide);
  title(slide, "Course journey", "Learning through repeated testing and refinement");
  const journey = [
    [assets.firstRender, "01  EXPERIMENT", "Turn an unfamiliar platform into a working spatial prototype."],
    [assets.inProgress, "02  BUILD", "Combine interaction design, anatomy content and a usable lesson flow."],
    [assets.finalBuild, "03  REFINE", "Use testing evidence to simplify the interface and strengthen the learning sequence."],
  ];
  for (let i = 0; i < journey.length; i++) {
    const [file, heading, copy] = journey[i];
    const left = 64 + i * 394;
    rect(slide, { left, top: 178, width: 366, height: 254 }, C.soft, C.line, "rounded-xl");
    await image(slide, file, { left: left + 10, top: 188, width: 346, height: 234 }, {
      fit: "cover",
      alt: heading,
      geometry: "roundRect",
      borderRadius: "rounded-xl",
    });
    textBox(slide, heading, { left, top: 452, width: 350, height: 26 }, { fontSize: 13, bold: true, color: i === 1 ? C.violet : C.roseDark });
    textBox(slide, copy, { left, top: 486, width: 350, height: 76 }, { fontSize: 17 });
  }
  textBox(slide, "Each test changed what I built next.", { left: 160, top: 578, width: 960, height: 38 }, { fontSize: 24, bold: true, color: C.roseDark, alignment: "center" });
  slide.speakerNotes.text = "[1:55–2:30] My course journey was iterative rather than linear. I started by learning an unfamiliar spatial platform and proving that I could place and manipulate the anatomy. Then I had to connect the technical build to an actual learning sequence. Testing exposed clutter, unclear controls and gaps between development and clinical anatomy. Each round of evidence changed the next design decision. The main lesson was that innovation came from repeated making, questioning and improving.";
}

// Slide 6 — 30 seconds
{
  const slide = presentation.slides.add();
  await footer(slide);
  title(slide, "Validation", "The next question is whether it improves learning");
  rect(slide, { left: 64, top: 190, width: 540, height: 282 }, C.soft, C.line, "rounded-xl");
  textBox(slide, "CURRENT LIMITS", { left: 96, top: 222, width: 230, height: 24 }, { fontSize: 12, bold: true, color: C.rose });
  textBox(slide, "The models are educational representations\n\nSome transitions remain staged snapshots\n\nLearning effectiveness has not been measured", { left: 96, top: 264, width: 456, height: 164 }, { fontSize: 19 });

  rect(slide, { left: 630, top: 190, width: 586, height: 282 }, C.softViolet, "#E0DBEF", "rounded-xl");
  textBox(slide, "NEXT STUDY", { left: 662, top: 222, width: 230, height: 24 }, { fontSize: 12, bold: true, color: C.violet });
  textBox(slide, "Expert anatomy and teaching review\n\nHeadset usability with target learners\n\nComprehension and retention testing", { left: 662, top: 264, width: 500, height: 164 }, { fontSize: 19 });

  rule(slide, 64, 512, 1152, C.line, 1);
  textBox(slide, "HeartV0 makes cardiac development something learners can inspect, compare and explain.", { left: 126, top: 532, width: 1028, height: 72 }, { fontSize: 26, bold: true, color: C.roseDark, alignment: "center" });
  slide.speakerNotes.text = "[2:30–3:00] HeartV0 is a working prototype, but I am careful about what it proves. The models still need expert review, some transitions remain staged, and I have not yet measured learning outcomes. My next step is testing with pre-clinical medical students, first for usability and then for comprehension and retention. The goal is simple: make a process students usually imagine into something they can inspect, compare and explain. Thank you.";
}

await fs.mkdir(BUILD, { recursive: true });
await fs.mkdir(path.dirname(OUTPUT), { recursive: true });

for (const [index, slide] of presentation.slides.items.entries()) {
  const png = await presentation.export({ slide, format: "png", scale: 1 });
  await fs.writeFile(path.join(BUILD, `slide-${String(index + 1).padStart(2, "0")}.png`), new Uint8Array(await png.arrayBuffer()));
}
const montage = await presentation.export({ format: "webp", montage: true });
await fs.writeFile(path.join(BUILD, "montage.webp"), new Uint8Array(await montage.arrayBuffer()));

const draft = path.join(BUILD, "candidate.pptx");
await (await PresentationFile.exportPptx(presentation)).save(draft);

const SKILL_DIR = "/Users/phillicia/.codex/plugins/cache/openai-primary-runtime/presentations/26.1025.11240/skills/presentations";
const { finalizePresentation } = await import(path.join(SKILL_DIR, "container_tools/artifact_tool_utils.mjs"));
const result = await finalizePresentation({
  workspaceDir: ROOT,
  candidatePath: draft,
  finalPath: OUTPUT,
  pythonExecutable: "/Users/phillicia/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3",
  integrityValidatorPath: path.join(SKILL_DIR, "container_tools/inspect_presentation_package_integrity.py"),
  layoutValidatorPath: path.join(SKILL_DIR, "container_tools/inspect_presentation_layout_geometry.py"),
  layoutArgs: ["--expected-slide-size-emu", "12192000,6858000", "--validate-heading-fit"],
  explicitTotalSlideCount: 6,
  requiredNativeTableOwnerSlides: [],
  requiredNativeChartOwnerSlides: [],
  fontPolicy: { basis: "design", families: [FONT] },
  verifyArtifactToolImport: true,
  receiptPath: path.join(BUILD, "validation.json"),
});

console.log(JSON.stringify({ output: OUTPUT, result }, null, 2));
