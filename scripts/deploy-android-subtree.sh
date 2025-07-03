#!/bin/bash

# Deploy Android SDK to dedicated repository using git subtree
# Usage: ./scripts/deploy-android-subtree.sh

set -e

echo "🤖 Deploying Android SDK to teracrafts/huefy-sdk-android..."

# Check if we're in the project root
if [ ! -f "CLAUDE.md" ]; then
    echo "❌ This script must be run from the project root directory"
    exit 1
fi

# Check if Android SDK exists
if [ ! -d "sdks/android" ]; then
    echo "❌ Android SDK directory not found: sdks/android"
    exit 1
fi

# Repository URL
REPO_URL="git@github.com:teracrafts/huefy-sdk-android.git"
REMOTE_NAME="android-repo"

# Add remote if it doesn't exist
if ! git remote get-url $REMOTE_NAME > /dev/null 2>&1; then
    echo "📌 Adding remote: $REMOTE_NAME"
    git remote add $REMOTE_NAME $REPO_URL
else
    echo "📌 Updating remote: $REMOTE_NAME"
    git remote set-url $REMOTE_NAME $REPO_URL
fi

# Fetch the remote to ensure we have the latest
echo "📥 Fetching remote repository..."
git fetch $REMOTE_NAME || true

# Create subtree split
echo "🌳 Creating subtree split for Android SDK..."
SUBTREE_COMMIT=$(git subtree split --prefix=sdks/android HEAD)

if [ -z "$SUBTREE_COMMIT" ]; then
    echo "❌ Failed to create subtree split"
    exit 1
fi

echo "📤 Pushing to remote repository..."
git push $REMOTE_NAME $SUBTREE_COMMIT:refs/heads/main --force

echo "✅ Android SDK deployed successfully!"
echo "📦 Repository: https://github.com/teracrafts/huefy-sdk-android"
echo "🔗 Commit: $SUBTREE_COMMIT"

# Optional: Create a git tag for versioning
if [ -n "$1" ]; then
    VERSION="$1"
    echo "🏷️  Creating version tag: v$VERSION"
    git tag -a "android-v$VERSION" $SUBTREE_COMMIT -m "Android SDK version $VERSION"
    git push $REMOTE_NAME "android-v$VERSION"
    echo "✅ Version tag v$VERSION created and pushed"
fi

echo ""
echo "🎯 Next steps:"
echo "1. Visit https://github.com/teracrafts/huefy-sdk-android to verify the deployment"
echo "2. Create a release on GitHub if needed"
echo "3. Publish to Maven Central if ready for distribution"
echo "4. Update Android documentation and examples"