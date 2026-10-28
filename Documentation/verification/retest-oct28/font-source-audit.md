# Font declarations after repair

Source expressions, not resolved Dynamic Type point sizes. No caption/caption2 or fixed text size below 14 remains.

| Location | Expression |
|---|---|
| DevelopmentConnectionView.swift:19 | `Text(connection.timing.uppercased()).font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| DevelopmentConnectionView.swift:21 | `Text(connection.lesson).font(.title2.bold())` |
| DevelopmentConnectionView.swift:35 | `Text(connection.id == "ductus" ? "Matched authored regional models; closure is gradual after birth." : "Different specimens; compare connections and shape, not size.").font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| DevelopmentConnectionView.swift:41 | `Text("Observe → explain").font(.headline)` |
| DevelopmentConnectionView.swift:47 | `Text("What changes?").font(.headline)` |
| DevelopmentConnectionView.swift:49 | `Text("Why does it matter?").font(.headline)` |
| DevelopmentConnectionView.swift:52 | `Text("Normal process").font(.headline)` |
| DevelopmentConnectionView.swift:58 | `Text("Find the difference").font(.headline)` |
| DevelopmentConnectionView.swift:63 | `Text("Processes overlap; the developmental window above is not an exact onset date.").font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| HeartProjectView.swift:268 | `Text("Still showing \(previous.title)").font(.subheadline)` |
| HeartProjectView.swift:276 | `Text("Still showing \(previous.title)").font(.subheadline)` |
| HeartProjectView.swift:297 | `}.font(.subheadline).disabled(!scene.ready  /  /  presentation.loading  /  /  presentation.displayedID != model.id)` |
| HeartProjectView.swift:300 | `Text("Cut direction").font(.subheadline)` |
| HeartProjectView.swift:307 | `if scene.preparingSection { ProgressView("Preparing section…").font(.subheadline).accessibilityIdentifier("reference.preparingSection") }` |
| HeartProjectView.swift:308 | `if let error = scene.sectionError { Text(error).font(.subheadline).accessibilityIdentifier("reference.sectionError") }` |
| HeartProjectView.swift:310 | `Text("Geometric section: existing surfaces only. Missing walls and tissue layers are not reconstructed.").font(.footnote).foregroundStyle(HeartDesign.secondary)` |
| HeartProjectView.swift:354 | `HStack { Text("Inspect parts").font(.headline); Spacer(); Button("Done") { showingParts = false } }` |
| HeartProjectView.swift:358 | `Text("Move the selected component. The line marks its assembled position.").font(.subheadline)` |
| HeartProjectView.swift:371 | `Text(scene.parts.count < 2 ? "This source is not anatomically segmented. Its material fragments stay together." : "Source components are not necessarily individual organs or histological layers.").font(.subheadline)` |
| HeartProjectView.swift:396 | `Text("HEART ANATOMY").font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| HeartProjectView.swift:397 | `Text("See the anatomy you are learning to explain").font(.title2.bold())` |
| HeartProjectView.swift:403 | `Text(model.title).font(.headline).accessibilityIdentifier("reference.currentModel")` |
| HeartProjectView.swift:409 | `HStack { Text("Choose a heart model").font(.title2.bold()); Spacer(); Button("Done") { choosingModel = false } }` |
| HeartProjectView.swift:414 | `Text(candidate.title).font(.headline).fixedSize(horizontal: false, vertical: true)` |
| HeartProjectView.swift:426 | `HStack { Text(model.title).font(.title2.bold()); Spacer(); Button("Done") { showingModelInfo = false } }` |
| HeartProjectView.swift:427 | `Text(model.note).font(.body).accessibilityIdentifier("reference.note.\(model.id)")` |
| HeartProjectView.swift:501 | `Text("Matched regional models · compare the connection after birth").font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| HeartProjectView.swift:519 | `Text("Drag to rotate · Pinch to resize · later anatomy").font(.subheadline)` |
| HeartProjectView.swift:550 | `Text("Later anatomy · \(model.title)").font(.headline)` |
| HeartProjectView.swift:580 | `.font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| SpatialControls.swift:36 | `.font(.subheadline.weight(.semibold))` |
| SpatialControls.swift:61 | `Image(systemName: symbol).font(.system(size: 20, weight: .medium))` |
| SpatialControls.swift:62 | `if selected { Image(systemName: "checkmark").font(.subheadline.bold()) }` |
| SpatialControls.swift:64 | `Text(title).font(.subheadline.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.9)` |
| SpatialControls.swift:84 | `.font(.headline)` |
| SpatialControls.swift:119 | `Text(axes[index].0).font(.footnote.bold())` |
| SpatialControls.swift:141 | `Text("Size").font(.subheadline)` |
| SpatialControls.swift:147 | `.font(.subheadline.monospacedDigit()).frame(minWidth: 50)` |
| DesignSystem.swift:48 | `configuration.label.font(.subheadline.weight(.semibold))` |
| DesignSystem.swift:59 | `configuration.label.font(.subheadline.weight(.medium)).foregroundStyle(HeartDesign.text)` |
| DesignSystem.swift:70 | `configuration.label.font(.subheadline).foregroundStyle(enabled ? HeartDesign.accent : HeartDesign.secondary)` |
| FreeExplorationView.swift:56 | `Text("FREE EXPLORATION").font(.subheadline.weight(.semibold)).tracking(2).foregroundStyle(HeartDesign.secondary)` |
| FreeExplorationView.swift:57 | `Text(showingHeartAnatomy ? "Heart anatomy" : showingAnomalies ? currentAsset?.lesson ?? "Anomalies" : currentStage.name).font(.title2.bold()).lineLimit(2)` |
| FreeExplorationView.swift:67 | `Text("Optional investigation").font(.headline)` |
| FreeExplorationView.swift:72 | `Text("What did you notice? Explain the relationship in your own words, then check it by rotating or reassembling the model.").font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| FreeExplorationView.swift:192 | `Text(asset.shortName ?? asset.lesson).font(.headline)` |
| FreeExplorationView.swift:194 | `.font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| FreeExplorationView.swift:212 | `Text("All anomalies").font(.title2.bold())` |
| FreeExplorationView.swift:226 | `Text(asset.shortName ?? asset.lesson).font(.headline).multilineTextAlignment(.leading)` |
| FreeExplorationView.swift:253 | `Text("\(currentStage.day) · \(currentStage.name)").font(.headline).accessibilityIdentifier("development.stageTitle")` |
| FreeExplorationView.swift:288 | `Text("Developmental stages").font(.title2.bold())` |
| FreeExplorationView.swift:300 | `Text(stage.day).font(.headline).frame(width: 110, alignment: .leading)` |
| HeartLoopingMorphView.swift:95 | `.font(.title2.bold()).frame(maxWidth: .infinity, alignment: .leading)` |
| HeartLoopingMorphView.swift:103 | `.font(.subheadline).multilineTextAlignment(.leading).lineLimit(2)` |
| HeartLoopingMorphView.swift:113 | `.font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| HeartLoopingMorphView.swift:120 | `Text("Tissue layers").font(.subheadline.bold())` |
| HeartLoopingMorphView.swift:134 | `Text("Only \(isolated.title)").font(.subheadline)` |
| HeartLoopingMorphView.swift:171 | `HStack { Text("Model size").font(.headline); Spacer(); Button("Done") { showingSize = false }.accessibilityIdentifier("morph.sizeDone") }` |
| HeartLoopingMorphView.swift:172 | `Label("Drag the model to rotate · Pinch to resize", systemImage: "hand.draw").font(.subheadline)` |
| HeartLoopingMorphView.swift:176 | `.font(.subheadline)` |
| HeartLoopingMorphView.swift:193 | `HStack { Text("About this animation").font(.headline); Spacer(); Button("Done") { showingLayerInfo = false } }` |
| HeartLoopingMorphView.swift:202 | `.font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| HeartLoopingMorphView.swift:263 | `HStack { Text("Inspect one layer").font(.headline); Spacer(); Button("Done") { showingLayerControls = false } }` |
| HeartLoopingMorphView.swift:267 | `Text(session.selectedLayer.explanation).font(.subheadline)` |
| HeartLoopingMorphView.swift:281 | `.font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| HeartLoopingMorphView.swift:294 | `Text("Predict before you replay").font(.title2.bold())` |
| HeartLoopingMorphView.swift:295 | `Text(prediction.question).font(.headline)` |
| HeartLoopingMorphView.swift:302 | `Text("Prediction saved — now observe").font(.title2.bold())` |
| HeartLoopingMorphView.swift:307 | `Text("Then choose Explain what changed. Moving through the animation is a practice step, not a score.").font(.subheadline)` |
| HeartLoopingMorphView.swift:309 | `Text("Explain what you observed").font(.title2.bold())` |
| HeartLoopingMorphView.swift:310 | `Text(explanation.question).font(.headline)` |
| HeartLoopingMorphView.swift:319 | `: "Compare your explanation with the model").font(.headline)` |
| HeartLoopingMorphView.swift:322 | `Text(explanation.observation).font(.subheadline)` |
| HeartLoopingMorphView.swift:324 | `.font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| HeartLoopingMorphView.swift:350 | `}.font(.subheadline).accessibilityIdentifier("morph.regionLegend")` |
| HeartLoopingMorphView.swift:356 | `.font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| HeartModelView.swift:377 | `Text("Regional teaching illustration").font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| HeartModelView.swift:383 | `.font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| HeartModelView.swift:386 | `.font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| HeartModelView.swift:398 | `.buttonStyle(.bordered).font(.subheadline)` |
| HeartModelView.swift:499 | `.font(.headline)` |
| HeartModelView.swift:509 | `.font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| HeartModelView.swift:523 | `Label { Text(title).font(.subheadline.bold()) } icon: {` |
| HeartModelView.swift:526 | `Text(detail).font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| HeartModelView.swift:559 | `.font(.subheadline)` |
| HeartModelView.swift:596 | `.font(.subheadline.weight(.medium))` |
| HeartModelView.swift:601 | `.font(.subheadline.monospacedDigit())` |
| HeartModelView.swift:620 | `Image(systemName: "exclamationmark.triangle").font(.largeTitle)` |
| HeartModelView.swift:769 | `Image(systemName: "square.split.2x1").font(.title3)` |
| HeartModelView.swift:770 | `Text(preparingSection ? "Loading" : "Slice").font(.subheadline).lineLimit(1)` |
| HeartModelView.swift:836 | `Text("About this model").font(.title2.bold())` |
| HeartModelView.swift:840 | `Text(asset.lesson).font(.headline)` |
| HeartModelView.swift:841 | `Text("School prototype · educational model").font(.subheadline)` |
| HeartModelView.swift:846 | `if let note = asset.presentationNote { Text(note).font(.body) }` |
| HeartModelView.swift:851 | `Text(review.scope).font(.headline)` |
| HeartModelView.swift:853 | `Text("What this model leaves out").font(.subheadline.bold())` |
| HeartModelView.swift:864 | `.font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| HeartModelView.swift:874 | `Text("Anatomy").font(.title2.bold())` |
| HeartModelView.swift:889 | `Text("No parts match “\(partSearch)”.").font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| HeartModelView.swift:905 | `Text(label).font(.subheadline).multilineTextAlignment(.leading)` |
| HeartModelView.swift:919 | `Text("View controls").font(.title2.bold())` |
| HeartModelView.swift:925 | `Text("Model size").font(.headline)` |
| HeartModelView.swift:935 | `Text("Separation").font(.headline)` |
| HeartModelView.swift:959 | `.font(.subheadline).fixedSize(horizontal: false, vertical: true)` |
| HeartModelView.swift:1302 | `Text("Model coming soon").font(.title2.bold())` |
| HeartModelView.swift:1304 | `.font(.body).foregroundStyle(HeartDesign.secondary).multilineTextAlignment(.center)` |
| HeartModelView.swift:1318 | `Text("Human embryonic heart atlas").font(.title2.bold())` |
| HeartModelView.swift:1332 | `.font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| ReferencesView.swift:13 | `Text("Explore the science").font(.title2.bold())` |
| ReferencesView.swift:57 | `.font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| ReferencesView.swift:74 | `Text(title).font(.headline).foregroundStyle(.primary)` |
| ReferencesView.swift:75 | `Text(source).font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| GuidedLearningView.swift:354 | `Text("Guided Learning").font(.largeTitle.bold())` |
| GuidedLearningView.swift:363 | `Text("\(completed) of \(total) lessons viewed").font(.subheadline.weight(.semibold))` |
| GuidedLearningView.swift:375 | `.font(.headline)` |
| GuidedLearningView.swift:385 | `Text("Next review: \(due, style: .date)").font(.subheadline)` |
| GuidedLearningView.swift:401 | `.font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| GuidedLearningView.swift:424 | `Text(topic.timing).font(.subheadline.weight(.semibold)).foregroundStyle(Color.accentColor)` |
| GuidedLearningView.swift:433 | `Text(topic.name).font(.headline).fixedSize(horizontal: false, vertical: true)` |
| GuidedLearningView.swift:435 | `Text(topic.summary).font(.subheadline).foregroundStyle(HeartDesign.secondary).lineLimit(3)` |
| GuidedLearningView.swift:456 | `}.font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| GuidedLearningView.swift:467 | `Text("Timings use post-fertilization age.").font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| GuidedLearningView.swift:634 | `Text("GUIDED LEARNING").font(.subheadline.weight(.semibold)).tracking(2).foregroundStyle(HeartDesign.secondary)` |
| GuidedLearningView.swift:635 | `Text(topic.name).font(.title2.bold()).lineLimit(2)` |
| GuidedLearningView.swift:637 | `Text(concealsAnswer  /  /  hidesCheckAnswer ? "Knowledge check" : currentCard.title).font(.subheadline).foregroundStyle(HeartDesign.secondary).lineLimit(1)` |
| GuidedLearningView.swift:664 | `Text("Phase \(currentCardIndex + 1) of \(topic.cards.count)").font(.headline.monospacedDigit())` |
| GuidedLearningView.swift:668 | `Text("Predict → observe the change → explain it").font(.subheadline)` |
| GuidedLearningView.swift:671 | `.font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| GuidedLearningView.swift:795 | `.font(.headline).accessibilityIdentifier("learning.normalProcess")` |
| GuidedLearningView.swift:823 | `Text("Scrub backwards to check your explanation.").font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| GuidedLearningView.swift:836 | `Text("\(index + 1)").font(.subheadline.monospacedDigit().bold())` |
| GuidedLearningView.swift:839 | `Text(concealsAnswer  /  /  hidesCheckAnswer ? "Step \(index + 1)" : topic.cards[index].title).font(.subheadline)` |
| GuidedLearningView.swift:871 | `Text(topic.timing).font(.subheadline.weight(.medium)).foregroundStyle(HeartDesign.secondary)` |
| GuidedLearningView.swift:874 | `.font(.subheadline.monospacedDigit()).fixedSize()` |
| GuidedLearningView.swift:889 | `Text(HeartLearningPilot.reviewNotice).font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| GuidedLearningView.swift:891 | `Text(currentCard.title).font(.title2.bold()).fixedSize(horizontal: false, vertical: true)` |
| GuidedLearningView.swift:894 | `Text(currentCard.visualFocus).font(.body).foregroundStyle(HeartDesign.secondary)` |
| GuidedLearningView.swift:896 | `Label("Try this", systemImage: "hand.point.up.left").font(.subheadline.weight(.semibold))` |
| GuidedLearningView.swift:897 | `Text(currentCard.interaction).font(.subheadline).fixedSize(horizontal: false, vertical: true)` |
| GuidedLearningView.swift:931 | `Text("Where development can differ").font(.headline)` |
| GuidedLearningView.swift:932 | `Text(connection.timing).font(.subheadline)` |
| GuidedLearningView.swift:949 | `Text(String(format: "%02d", index + 1)).font(.subheadline.monospacedDigit()).foregroundStyle(Color.accentColor).padding(.top, 4)` |
| GuidedLearningView.swift:950 | `Text(concept).font(.subheadline).fixedSize(horizontal: false, vertical: true)` |
| GuidedLearningView.swift:975 | `Text(currentCard.title).font(.title2.bold())` |
| GuidedLearningView.swift:976 | `Text("Optional knowledge check").font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| GuidedLearningView.swift:979 | `Text(check.question).font(.headline)` |
| GuidedLearningView.swift:983 | `Text(HeartLearningPilot.reviewNotice).font(.subheadline)` |
| GuidedLearningView.swift:998 | `Text("Answers and lesson views are recorded separately on this device.").font(.subheadline)` |
| GuidedLearningView.swift:1017 | `Text(currentCardIndex == 4 ? "Recognise again" : "Find the narrowing").font(.title2.bold())` |
| GuidedLearningView.swift:1019 | `.font(.headline).fixedSize(horizontal: false, vertical: true)` |
| GuidedLearningView.swift:1027 | `}.font(.subheadline).frame(maxWidth: .infinity, alignment: .leading)` |
| GuidedLearningView.swift:1044 | `Text("Which segment has an abnormal channel width?").font(.headline)` |
| GuidedLearningView.swift:1052 | `Text(recognition.outcome).font(.headline)` |
| GuidedLearningView.swift:1055 | `.font(.subheadline)` |
| GuidedLearningView.swift:1067 | `.font(.subheadline)` |
| GuidedLearningView.swift:1069 | `.font(.subheadline)` |
| GuidedLearningView.swift:1102 | `Text("Step \(currentCardIndex + 1) / \(topic.cards.count)").font(.subheadline.monospacedDigit())` |
| GuidedLearningView.swift:1125 | `Text("NARRATION").font(.headline)` |
| GuidedLearningView.swift:1129 | `ScrollView { Text(attributedScript).font(.body).frame(maxWidth: .infinity, alignment: .leading) }` |
| GuidedLearningView.swift:1166 | `Text(topic.cards[currentCardIndex + 1].title).font(.subheadline).lineLimit(2)` |
| GuidedLearningView.swift:1182 | `Text(study.process).font(.title2.bold())` |
| GuidedLearningView.swift:1183 | `Text("Observe a second representation").font(.headline)` |
| GuidedLearningView.swift:1185 | `Text("Connect it to development").font(.headline)` |
| GuidedLearningView.swift:1208 | `.font(.subheadline).foregroundStyle(HeartDesign.secondary)` |
| HeartLocationView.swift:51 | `Text("Location guide").font(.title2.bold())` |
| HeartLocationView.swift:55 | `Text(guide.title).font(.headline)` |
| HeartLocationView.swift:62 | `.font(.subheadline).foregroundStyle(Color.accentColor)` |
| HeartLocationView.swift:64 | `.font(.subheadline).foregroundStyle(.secondary)` |
| HeartLocationView.swift:67 | `Text(asset.lesson).font(.subheadline).foregroundStyle(.secondary)` |
| HeartLocationView.swift:79 | `return Text(name).font(.subheadline.weight(.semibold)).multilineTextAlignment(.center)` |
| ContentView.swift:73 | `Text("Welcome to HeartV0").font(.largeTitle.bold())` |
| ContentView.swift:75 | `.font(.title3).foregroundStyle(HeartDesign.secondary)` |
| Components.swift:31 | `.font(.title2.bold())` |
| Components.swift:35 | `.font(.body)` |
