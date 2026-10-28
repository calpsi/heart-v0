import fs from "node:fs/promises";
import path from "node:path";
import { FileBlob, PresentationFile } from "@oai/artifact-tool";

const ROOT = "/Users/phillicia/Desktop/School/Spatial/heart v3";
const SOURCE = path.join(ROOT, "Pitch Media", "HEARTV0-current-source-export.pptx");
const BUILD = path.join(ROOT, ".heartv0-current-three-minute-update-v3");
const OUTPUT = path.join(ROOT, "Pitch Media", "HEARTV0-3-minute-pitch-with-latest-build-v3.pptx");
const FONT = "Helvetica Neue";

const C = {
  ink: "#111318",
  muted: "#5F6672",
  line: "#DADDE3",
  soft: "#F5F6F8",
  rose: "#C43D64",
  roseDark: "#8E2948",
  violet: "#6850A5",
};

const assets = {
  home: path.join(ROOT, "Documentation/verification/retest-build2/home.png"),
  guided: path.join(ROOT, "Documentation/verification/retest-oct28/guided-aperture-2point5x.png"),
  free: path.join(ROOT, "Documentation/verification/retest-build2/final-timeline.png"),
};

async function bytes(file) {
  const data = await fs.readFile(file);
  return data.buffer.slice(data.byteOffset, data.byteOffset + data.byteLength);
}

function addText(slide, text, position, style = {}) {
  const shape = slide.shapes.add({
    geometry: "textbox",
    position,
    fill: "none",
    line: { style: "solid", fill: "none", width: 0 },
  });
  shape.text = text;
  shape.text.style = {
    typeface: FONT,
    fontSize: style.fontSize ?? 22,
    bold: style.bold ?? false,
    color: style.color ?? C.ink,
    alignment: style.alignment ?? "left",
    verticalAlignment: style.verticalAlignment ?? "middle",
    autoFit: "shrinkText",
  };
  return shape;
}

function addRule(slide, left, top, width, color = C.line, height = 1) {
  return slide.shapes.add({
    geometry: "rect",
    position: { left, top, width, height },
    fill: color,
    line: { style: "solid", fill: color, width: 0 },
  });
}

async function addImage(slide, file, position, alt) {
  return slide.images.add({
    blob: await bytes(file),
    contentType: "image/png",
    alt,
    fit: "cover",
    position,
    geometry: "roundRect",
    borderRadius: "rounded-xl",
  });
}

function replaceText(presentation, id, before, after) {
  presentation.resolve(id).text.replace(before, after);
}

const presentation = await PresentationFile.importPptx(await FileBlob.load(SOURCE));
const slides = presentation.slides.items;
if (slides.length !== 13) throw new Error(`Expected 13 slides, found ${slides.length}`);

// Slide 1: retain the title and current cover design. Tighten only the supporting line.
replaceText(
  presentation,
  "sh/7q1kfudo",
  "An immersive learning experience that makes embryonic heart development tangible in 3D space.",
  "An Apple Vision Pro learning experience that makes cardiac development tangible in 3D space.",
);

// Slide 5: replace the outdated product capture with the current spatial workspace.
await addImage(slides[4], assets.home, { left: 553, top: 183, width: 650, height: 390 }, "Current HeartV0 home screen in the Vision Pro workspace");

// Slide 6: keep the title and product structure, but make the mode descriptions current.
replaceText(
  presentation,
  "sh/psbmxgzi",
  "Understand how the heart develops through structured lessons, developmental stages and congenital anomaly examples.",
  "Follow structured lessons that connect developmental mechanisms to later anatomy and congenital differences.",
);
replaceText(
  presentation,
  "sh/1ormtgzm",
  "Investigate anatomy independently by navigating through the developmental timeline and manipulating individual structures.",
  "Move through the developmental timeline, inspect anatomy and compare normal and anomaly views independently.",
);
replaceText(presentation, "sh/2p0n2lg7", "Structured · Sequential · Explanatory", "Structured lessons with saved progress");
replaceText(presentation, "sh/twfmts36", "Interactive · Self-directed · Investigative", "Independent investigation and comparison");

// Slide 7: fill the existing Guided Learning slide without touching either title.
await addImage(slides[6], assets.guided, { left: 64, top: 170, width: 790, height: 430 }, "Latest HeartV0 Guided Learning interface");
addText(slides[6], "55", { left: 912, top: 192, width: 160, height: 52 }, { fontSize: 38, bold: true, color: C.rose });
addText(slides[6], "guided learning cards", { left: 912, top: 240, width: 250, height: 36 }, { fontSize: 15, color: C.muted });
addRule(slides[6], 912, 292, 242);
addText(slides[6], "16", { left: 912, top: 318, width: 160, height: 52 }, { fontSize: 38, bold: true, color: C.roseDark });
addText(slides[6], "development and anomaly lessons", { left: 912, top: 366, width: 260, height: 48 }, { fontSize: 15, color: C.muted });
addRule(slides[6], 912, 430, 242);
addText(slides[6], "One step at a time", { left: 912, top: 458, width: 250, height: 34 }, { fontSize: 19, bold: true, color: C.violet });
addText(slides[6], "The model, explanation and task stay visible together.", { left: 912, top: 500, width: 260, height: 74 }, { fontSize: 16, color: C.ink });

// Slide 8: fill the existing Free Exploration slide with the current morphing timeline.
await addImage(slides[7], assets.free, { left: 324, top: 170, width: 892, height: 430 }, "Latest HeartV0 Free Exploration morphing timeline");
addText(slides[7], "8", { left: 68, top: 192, width: 160, height: 52 }, { fontSize: 38, bold: true, color: C.violet });
addText(slides[7], "exploration timeline stops", { left: 68, top: 240, width: 220, height: 42 }, { fontSize: 15, color: C.muted });
addText(slides[7], "Morph", { left: 68, top: 326, width: 190, height: 48 }, { fontSize: 31, bold: true, color: C.rose });
addText(slides[7], "Play or scrub key developmental transitions.", { left: 68, top: 374, width: 220, height: 68 }, { fontSize: 16, color: C.ink });
addText(slides[7], "Compare", { left: 68, top: 468, width: 190, height: 42 }, { fontSize: 24, bold: true, color: C.roseDark });
addText(slides[7], "Inspect layers, later anatomy and related anomalies.", { left: 68, top: 510, width: 220, height: 70 }, { fontSize: 16, color: C.ink });

// Slide 9: retain MY EXPERIENCE / My Course Journey and update the reflection.
replaceText(presentation, "sh/adknedwr", "Pre-clinical medical students", "From question to working prototype");
replaceText(presentation, "sh/9cbml8fm", "Particularly Years 1-2, learning cardiac embryology during foundational anatomy modules.", "Learning by building, testing and refining.");
replaceText(presentation, "sh/x0b6psfi", "Experimentation", "Question");
replaceText(presentation, "sh/f6d4f2dg", "Conceptualisation", "Build");
replaceText(presentation, "sh/g7ml87u1", "Building", "Iterate");
replaceText(presentation, "sh/72t4bidk", "Struggle to imagine changes across 3D space and time", "Could spatial computing make cardiac development easier to understand?");
replaceText(presentation, "sh/6hk32dcz", "Memorise stages without understanding the process", "I learned visionOS while shaping the anatomy, interactions and lesson flow.");
replaceText(presentation, "sh/t4vmdsvq", "Forget concepts after assessments", "Every test exposed what to simplify, repair or explain more clearly.");
addRule(slides[8], 160, 500, 960, C.line, 1);
addText(slides[8], "Innovation became a cycle of making, questioning and improving.", { left: 150, top: 516, width: 980, height: 72 }, { fontSize: 25, bold: true, color: C.roseDark, alignment: "center" });

// Slide 10: update the limitations to reflect key-transition morphing and current validation needs.
replaceText(
  presentation,
  "sh/pw7e54f6",
  "Educational models lack clinical validation\nNo simulated flow or pressure\nDiscrete staged models rather than continuous morphing\nLearning effectiveness is untested",
  "Educational models still need expert anatomy review\nNo simulated blood flow or pressure\nOnly key transitions currently morph\nLearning effectiveness is untested",
);
replaceText(
  presentation,
  "sh/vqhojuxk",
  "Expert anatomy review\nProfessional 3D Rendering\nComprehension and retention testing with medical students",
  "Expert anatomy and teaching review\nHeadset usability with target learners\nComprehension and retention testing with medical students",
);

// A complete 3-minute script. Titles and slide order remain unchanged.
const notes = [
  "[0:00–0:12] Good afternoon. I’m Phillicia, and this is HeartV0. The name describes the idea: seeing how the heart takes shape from its earliest form through an Apple Vision Pro learning experience.",
  "[0:12–0:30] Cardiac embryology is usually taught as separate snapshots. Students have to imagine the movement between stages, then work backwards from a congenital defect to understand where development changed. HeartV0 makes that process visible.",
  "[0:30–0:48] The challenge combines space and time. Learners must understand folding, joining and remodelling in three dimensions. Congenital heart defects affect about one in one hundred births, which makes this more than a visualisation problem.\n\nSource: Centers for Disease Control and Prevention, About Congenital Heart Defects, https://www.cdc.gov/heart-defects/about/index.html",
  "[0:48–1:02] I designed first for pre-clinical medical students. They need to connect the developmental sequence to later anatomy, rather than memorising isolated outcomes. The app supports visualisation first, then understanding and later recall.",
  "[1:02–1:20] Vision Pro places the model in the learner’s space. They can inspect depth, rotate the anatomy, open layers and compare developmental states. Spatial interaction directly addresses the part that flat diagrams leave to imagination.",
  "[1:20–1:36] HeartV0 has two paths through the same anatomy. Guided Learning explains the sequence step by step. Free Exploration lets the learner investigate the timeline, normal development and related anomalies independently.",
  "[1:36–1:54] Guided Learning now contains fifty-five cards across sixteen development and anomaly lessons. The current layout keeps the model, explanation and task visible together, while progress is saved between visits.\n\nInternal source: Documentation/RESEARCH_ITERATION.md, verified 28 October 2026.",
  "[1:54–2:12] Free Exploration has eight timeline stops. Learners can play or scrub key transitions, inspect layers, switch to later anatomy and compare related anomalies. I describe this as key-transition morphing because the full timeline is not continuously animated.\n\nInternal source: Documentation/RESEARCH_ITERATION.md and Documentation/TESTING.md.",
  "[2:12–2:37] My course journey was iterative. I began with a question and had to learn visionOS while building the anatomy, interactions and lesson flow. Testing revealed clutter, unclear controls and weak connections between development and clinical anatomy. Each round changed what I built next. My main lesson was that innovation came from making, questioning and improving.",
  "[2:37–3:00] HeartV0 is a working prototype, but it still needs expert review and learner testing. The models are educational representations, only key transitions morph, and I have not measured learning outcomes yet. The next step is to test usability, comprehension and retention with medical students. The goal is to make cardiac development something learners can inspect, compare and explain. Thank you.",
];
for (let i = 0; i < notes.length; i++) slides[i].speakerNotes.text = notes[i];

await fs.mkdir(BUILD, { recursive: true });
await fs.mkdir(path.dirname(OUTPUT), { recursive: true });

for (const [index, slide] of slides.entries()) {
  const png = await presentation.export({ slide, format: "png", scale: 1 });
  await fs.writeFile(path.join(BUILD, `slide-${String(index + 1).padStart(2, "0")}.png`), new Uint8Array(await png.arrayBuffer()));
}
const montage = await presentation.export({ format: "webp", montage: true });
await fs.writeFile(path.join(BUILD, "montage.webp"), new Uint8Array(await montage.arrayBuffer()));

const candidate = path.join(BUILD, "candidate.pptx");
await (await PresentationFile.exportPptx(presentation)).save(candidate);

const SKILL_DIR = "/Users/phillicia/.codex/plugins/cache/openai-primary-runtime/presentations/26.1025.11240/skills/presentations";
const { finalizePresentation } = await import(path.join(SKILL_DIR, "container_tools/artifact_tool_utils.mjs"));
const result = await finalizePresentation({
  workspaceDir: ROOT,
  candidatePath: candidate,
  finalPath: OUTPUT,
  pythonExecutable: "/Users/phillicia/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3",
  integrityValidatorPath: path.join(SKILL_DIR, "container_tools/inspect_presentation_package_integrity.py"),
  layoutValidatorPath: path.join(SKILL_DIR, "container_tools/inspect_presentation_layout_geometry.py"),
  layoutArgs: ["--expected-slide-size-emu", "12192000,6858000", "--validate-heading-fit"],
  explicitTotalSlideCount: 13,
  requiredNativeTableOwnerSlides: [],
  requiredNativeChartOwnerSlides: [],
  fontPolicy: { basis: "design", families: [FONT] },
  verifyArtifactToolImport: true,
  receiptPath: path.join(BUILD, "validation.json"),
});

console.log(JSON.stringify({ output: OUTPUT, result }, null, 2));
