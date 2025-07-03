#!/bin/bash

# Huefy SDK Version Bump Script
# Usage: ./scripts/bump-version.sh <new-version>
# Example: ./scripts/bump-version.sh 1.2.0

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.2.0"
    exit 1
fi

NEW_VERSION="$1"

# Validate version format
if [[ ! "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+(\.[a-zA-Z0-9]+)*)?$ ]]; then
    echo "❌ Invalid version format: $NEW_VERSION"
    echo "Expected format: X.Y.Z or X.Y.Z-prerelease"
    exit 1
fi

echo "🚀 Bumping version to $NEW_VERSION across all SDKs..."

# Check if we're in the project root
if [ ! -f "CLAUDE.md" ]; then
    echo "❌ This script must be run from the project root directory"
    exit 1
fi

# Function to backup a file
backup_file() {
    cp "$1" "$1.backup"
}

# Function to restore a file from backup
restore_file() {
    if [ -f "$1.backup" ]; then
        mv "$1.backup" "$1"
    fi
}

# Function to clean up backups
cleanup_backups() {
    find . -name "*.backup" -delete
}

# Trap to clean up on error
trap cleanup_backups EXIT

echo "📦 Updating JavaScript SDK..."
cd sdks/javascript
backup_file package.json
npm version "$NEW_VERSION" --no-git-tag-version
cd ../..

echo "⚛️  Updating React SDK..."
cd sdks/react
backup_file package.json
npm version "$NEW_VERSION" --no-git-tag-version
cd ../..

echo "🐍 Updating Python SDK..."
cd sdks/python
backup_file pyproject.toml
sed -i.backup "s/version = \".*\"/version = \"$NEW_VERSION\"/" pyproject.toml
cd ../..

echo "☕ Updating Java SDK..."
cd sdks/java
backup_file pom.xml
mvn versions:set -DnewVersion="$NEW_VERSION" -DgenerateBackupPoms=false
cd ../..

echo "🐘 Updating PHP SDK..."
cd sdks/php
backup_file composer.json
if composer config version > /dev/null 2>&1; then
    composer config version "$NEW_VERSION"
fi
cd ../..

echo "🐹 Checking Go SDK..."
cd sdks/go
# Go doesn't need version update in go.mod, it uses git tags
echo "Go SDK uses git tags for versioning - no file changes needed"
cd ../..

echo "🔶 Updating Laravel SDK..."
cd sdks/laravel
backup_file composer.json
if composer config version > /dev/null 2>&1; then
    composer config version "$NEW_VERSION"
fi
cd ../..

echo "✅ Version bump completed successfully!"
echo ""
echo "📋 Summary of changes:"
echo "- JavaScript SDK: package.json updated to $NEW_VERSION"
echo "- React SDK: package.json updated to $NEW_VERSION"
echo "- Python SDK: pyproject.toml updated to $NEW_VERSION"
echo "- Java SDK: pom.xml updated to $NEW_VERSION"
echo "- PHP SDK: composer.json updated to $NEW_VERSION (if version field exists)"
echo "- Laravel SDK: composer.json updated to $NEW_VERSION (if version field exists)"
echo "- Go SDK: Uses git tags for versioning"
echo ""
echo "🔍 Next steps:"
echo "1. Review the changes: git diff"
echo "2. Commit the changes: git add -A && git commit -m 'chore: bump version to $NEW_VERSION'"
echo "3. Create a release: gh release create v$NEW_VERSION --generate-notes"
echo ""
echo "💡 Or use the automated release workflow:"
echo "   gh workflow run release.yml -f version=$NEW_VERSION"

# Clean up successful backups
cleanup_backups