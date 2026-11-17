#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p .build/checks
swiftc Sources/Pomo/FocusState.swift Sources/Pomo/CompanionReaction.swift Tests/PomoTests/FocusStateTests.swift -o .build/checks/PomoChecks
.build/checks/PomoChecks
