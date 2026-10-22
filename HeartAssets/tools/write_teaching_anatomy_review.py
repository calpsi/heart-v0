from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[2]
# Each entry distinguishes the narrow concept from anatomy the model cannot establish.
rows=[
("Cardiogenic field diagram","Shows bilateral cardiac precursors and a crescent relationship.","The thick crescent and isolated cords omit the early vascular plexus and tissue folding. They are not measured fields or a complete embryo.","Rebuild the vascular network and tissue interfaces from early human sections."),
("Paired-channel layer diagram","Distinguishes endocardial lining, cardiac jelly and myocardial tissue.","Two smooth independent tubes exaggerate regularity. The early human primordium includes vascular networks and a shared developing myocardial environment; the embryo and connecting vessels are omitted.","Replace the two-cylinder interpretation with stage-matched networks and folding context."),
("Unfolded regional map","Teaches the ordering of named inflow-to-outflow regions.","The stacked regions are not one embryonic snapshot. The dorsal opening/attachments and paired vascular poles are missing; region labels span different developmental events.","Use a continuous stage-specific lumen and myocardial cloak. The CS10 draft failed shape/junction review and must not be installed."),
("Looping schematic","Shows broad bending and relative chamber regions.","Generic swellings and an elongated outflow differ from the source-stage reconstruction. This geometry cannot establish wall thickness or chamber topology.","Use CS11 N662 for the primary lesson; rebuild tissue layers only against registered boundaries."),
("Regional atrial septation comparison","Shows the primary septum, mesenchymal cap, dorsal contribution and later atrial-wall fold.","The recent additions correct missing contributors, but chamber shape and venous entrances remain generic. The later fold is a separate fetal reference, not the early-stage anatomy.","Register wall/venous geometry and separate exact developmental snapshots."),
("AV canal division diagram","Shows opposing major cushions and division into two AV openings.","Isolated rounded cushions lack the atrial/ventricular junction context. They must not be interpreted as the muscular ventricular septum or mature valve leaflets.","Reconstruct their connections to the primary septum, dorsal mesenchyme and AV myocardium."),
("Ventricular septation diagram","Compares a superior communication with a closure contribution.","Symmetric chamber shells and a large closure patch obscure ventricular asymmetry and inlet/outlet relationships. The patch is not a measured membranous septum.","Rebuild chamber topology, outlet alignment and the small fibrous closure region."),
("Outflow division schematic","Illustrates a shared outlet and separated arterial pathways.","A fixed twisting partition does not reproduce conal/truncal remodeling. Rounded cusp primordia do not establish valve-root anatomy.","Use CS18 N1645 in the lesson; reconstruct cushion and root boundaries before adding detail."),
('Valve component comparison', 'Later-reference mitral and tricuspid leaflets have unequal shapes and branching chordal attachments. The tricuspid example includes unequal leaflets and two direct cords between the septal leaflet and a selectable regional septal support. Semilunar cusps retain pockets, sinus walls and removable aortic tissue layers.', 'Isolated partly open teaching stations, not measured stage-specific anatomy. Dimensions, chordal counts and a three-scallop posterior example are illustrative; leaflet variants occur. Planar annular support, aortomitral continuity, coronary ostia and early cushions remain incomplete. The regional septal support does not reconstruct the whole interventricular septum.', 'Reconstruct intact stage-matched annular, ventricular and root anatomy; regional direct septal support, unequal AV leaflets, chordal trees and semilunar pockets are implemented.'),
("Birth-transition diagram","Shows flap apposition and a narrowing ductal lumen.","No pressure or complete circulation is modeled. Functional closure is not immediate anatomical fusion; a PFO may persist.","Keep physiological explanation separate from later anatomical remodeling."),
("Intended perimembranous VSD example","Shows a superior septal opening with limited nearby valve landmarks.","The simplified borders cannot establish the full perimembranous subtype or all valve relationships. It is not representative of every VSD.","Reconstruct fibrous borders, tricuspid attachment and aortic continuity."),
("Secundum ASD concept example","Shows missing fossa-floor tissue rather than a persisting flap tunnel.","A round hole and generic rims do not represent all ASD types or their relationships to venous entrances.","Keep ASD distinct from PFO; reconstruct venous context and variable rims."),
('Regional Fallot comparison', 'Shows the regional Fallot features, including an illustrative outlet-septal component displaced anteriorly and cranially. The VSD and subpulmonary lumen have clear sampled paths.', 'Generic chambers, exaggerated dimensions and missing septoparietal trabeculations remain. This is a regional comparison, not a complete reconstruction of conal malalignment or a dated embryo. RV hypertrophy is pressure-related.', 'Reconstruct septoparietal trabeculations and ventricular morphology; the outlet component and sampled passage checks are now implemented.'),
("Ventriculoarterial connection diagram","Shows aorta connected to the intended RV and pulmonary trunk to the intended LV.","Two ellipsoid half-chambers lack enough morphology to identify RV versus LV independently. Vessel parallelism alone does not diagnose TGA.","Rebuild ventricular morphology and AV valve offsets before claiming complete segmental anatomy."),
("Regional coarctation example","Shows actual lumen narrowing near the isthmus and ductal attachment.","Arch geometry, narrowing severity and wall thickness are illustrative. Diffuse arch hypoplasia and collateral networks are omitted.","Retain the limited regional concept and specify age and variant before extending it."),
("Ductal patency comparison","Shows an open ductal connection versus a solid remnant.","A patent fetal duct is normal; PDA concerns persistence after birth. The comparison is not a real-time closure process.","Add stage/age context and preserve the distinction between functional and anatomical closure.")
]
sources=[
'https://doi.org/10.1038/s42003-022-03153-x',
'https://hdbratlas.org/hikspoors-pdf/JH_CS9.html',
'https://hdbratlas.org/hikspoors-pdf/JH_CS10_new_description.html',
'https://pmc.ncbi.nlm.nih.gov/articles/PMC6588001/',
'https://pubmed.ncbi.nlm.nih.gov/11230106/',
'https://pubmed.ncbi.nlm.nih.gov/6721204/',
'https://pubmed.ncbi.nlm.nih.gov/9764545/',
'https://pmc.ncbi.nlm.nih.gov/articles/PMC11050351/',
'https://pmc.ncbi.nlm.nih.gov/articles/PMC2651859/',
'https://pmc.ncbi.nlm.nih.gov/articles/PMC6865365/'
]
out=ROOT/'HeartAssets/anatomy-review/professor-review';out.mkdir(exist_ok=True)
report=['# Teaching anatomy critique — 19 October 2026','',
'Review standard: anatomical topology, developmental appropriateness, tissue identity, vessel connections, and suitability for the stated teaching claim. Reviewed installed previews, catalogues, construction scripts, prior local geometry checks and cited literature. This is an evidence-based AI critique, not clinical certification or histological validation.','',
'## Overall verdict','',
'The 16 original models are regional teaching illustrations. Several support useful narrow concepts, but none should be presented as a fully validated, anatomically complete stage-specific heart. The seven HDBR reconstructions preserve stronger source-stage geometry but are region segmentations, not complete tissue-layer reconstructions. Texture cannot compensate for incorrect connections or invented wall thickness.','',
'## Original models','']
p=ROOT/'heart v3/Resources/HeartModels.json';items=json.loads(p.read_text())
for e,(scope,concept,limits,action) in zip(items,rows):
 e['anatomyReview']={'scope':scope,'supports':concept,'limitations':limits}
 report += [f"### {e['id']} — {e['lesson']}",f"**Teaching scope:** {scope}. {concept}",f"**Critique:** {limits}",f"**Required improvement:** {action}",'']
p.write_text(json.dumps(items,indent=2)+'\n')
extras=[
'No separately segmented AV canal wall; do not teach its thickness from this model.',
'Venous channels are not a separate region in this dataset; their omission is not biological absence.',
'Surrounding tissue may hide cardiac regions. Atrial labels do not establish complete septal wall anatomy.',
'An epicardial source region is present, but complete myocardial/endocardial wall layers are not.',
'Separate ductal and pulmonary regions are present; valve leaflets and fine septal interfaces remain unsegmented.',
'Useful for outflow/arterial relationships; it does not separately demonstrate all conal cushions or valve primordia.',
'Later-stage geometry is not an adult-sized heart. Missing fine structures and source segmentation limits still apply.'
]
p=ROOT/'heart v3/Resources/HeartReferenceModels.json';refs=json.loads(p.read_text());report+=['## Source-stage reconstructions','']
for e,extra in zip(refs,extras):
 e['anatomyReview']={'scope':'Source-stage regional reconstruction','supports':'Preserves the labelled specimen regions and their spatial relationships.','limitations':extra+' Region colours are identifiers, not histological tissue layers. Physical display scale is enlarged; source axes are not independently registered.'}
 report += [f"### {e['id']}",e['anatomyReview']['supports'],e['anatomyReview']['limitations'],'Required improvement: register axes and compare tissue boundaries to source sections before creating new wall layers.','']
p.write_text(json.dumps(refs,indent=2)+'\n')
report+=['## References','']+[f'- {s}' for s in sources]
report_path = out/'critique.md'
if report_path.exists():
 existing = report_path.read_text()
 marker = '## Implemented after this critique'
 if marker in existing:
  report += ['', marker + existing.split(marker, 1)[1].rstrip()]
report_path.write_text('\n'.join(report)+'\n')
(out/'coverage.json').write_text(json.dumps({'originalAssets':len(items),'referenceAssets':len(refs),'reviewedIDs':[e['id'] for e in items+refs],'completeAnatomicalValidation':False},indent=2)+'\n')
print('Reviewed and annotated',len(items)+len(refs),'assets')
