#!/bin/bash

CHART_DIR="webapp-chart"
REPO_DIR="helm-repo"

update_chart_version() {
    local version_type=$1
    local current_version=$(grep "^version:" $CHART_DIR/Chart.yaml | cut -d' ' -f2)

    echo "Current version: $current_version"

    IFS='.' read -ra VERSION_PARTS <<< "$current_version"
    major=${VERSION_PARTS[0]}
    minor=${VERSION_PARTS[1]}
    patch=${VERSION_PARTS[2]}

    case $version_type in
        "major")
            major=$((major + 1)); minor=0; patch=0
            ;;
        "minor")
            minor=$((minor + 1)); patch=0
            ;;
        "patch")
            patch=$((patch + 1))
            ;;
        *)
            echo "Invalid version type. Use: major, minor, or patch"
            exit 1
            ;;
    esac

    new_version="$major.$minor.$patch"
    echo "New version: $new_version"

    sed -i "s/^version:.*/version: $new_version/" $CHART_DIR/Chart.yaml
    sed -i "s/^appVersion:.*/appVersion: \"$new_version\"/" $CHART_DIR/Chart.yaml

    echo "Chart version updated to $new_version"
}

package_and_update_repo() {
    local version=$(grep "^version:" $CHART_DIR/Chart.yaml | cut -d' ' -f2)

    echo "Packaging version $version..."
    helm package $CHART_DIR/
    mv webapp-chart-$version.tgz $REPO_DIR/
    helm repo index $REPO_DIR/

    echo "Repository updated with version $version"
}

case $1 in
    "patch"|"minor"|"major")
        update_chart_version $1
        package_and_update_repo
        ;;
    "list")
        echo "Available versions:"
        ls -la $REPO_DIR/*.tgz 2>/dev/null || echo "No packages found"
        ;;
    *)
        echo "Usage: $0 {major|minor|patch|list}"
        exit 1
        ;;
esac
