#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
build_dir=$(mktemp -d /tmp/heartv3-policy.XXXXXX)
trap 'rm -rf "$build_dir"' EXIT
swiftc -module-cache-path "$build_dir/cache" 'heart v3/DesignSystem.swift' 'heart v3/HeartSectionGeometry.swift' 'heart v3/HeartSpecimenParts.swift' 'heart v3/HeartModelZoom.swift' 'heart v3/HeartManipulationSession.swift' 'heart v3/HeartRecognition.swift' 'heart v3/HeartLearningPilot.swift' 'heart v3/HeartMorphTiming.swift' 'heart v3/HeartLoopingGeometry.swift' 'heart v3/HeartTubeFusionGeometry.swift' 'heart v3/HeartTubeLayers.swift' 'heart v3/HeartOutflowGeometry.swift' 'heart v3/HeartDevelopmentTimeline.swift' 'heart v3/HeartDevelopmentConnections.swift' 'heart v3/HeartMorphLearning.swift' 'heart v3/HeartMorphSession.swift' 'heart v3/HeartGuidedAnatomy.swift' 'heart v3/HeartModelStyle.swift' 'heart v3/HeartAnatomyPalette.swift' Tests/SpatialPolicy/main.swift -o "$build_dir/tests"
"$build_dir/tests"
