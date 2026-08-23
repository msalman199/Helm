#!/bin/bash

RELEASE_VERSION=$1
RELEASE_DATE=$(date +%Y-%m-%d)

if [ -z "$RELEASE_VERSION" ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

echo "Generating release notes for version $RELEASE_VERSION"

cat > release-notes-$RELEASE_VERSION.md << EOL
# Release Notes - Version $RELEASE_VERSION

**Release Date**: $RELEASE_DATE

## Overview
This release includes the following changes and improvements to the webapp-chart.

## What's New

### Features
- [Add new features here]

### Improvements
- [Add improvements here]

### Bug Fixes
- [Add bug fixes here]

## Breaking Changes
- [List any breaking changes here]

## Upgrade Instructions

\`\`\`bash
helm upgrade <release-name> helm-repo/webapp-chart-$RELEASE_VERSION.tgz
\`\`\`

To rollback if needed:

\`\`\`bash
helm rollback <release-name> <previous-revision>
\`\`\`

## Compatibility
- Kubernetes: 1.20+
- Helm: 3.0+
EOL

echo "Release notes generated: release-notes-$RELEASE_VERSION.md"
