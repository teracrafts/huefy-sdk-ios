#!/bin/bash

# Deploy iOS SDK to dedicated repository using git subtree
# Usage: ./scripts/deploy-ios-subtree.sh

set -e

echo "🍎 Deploying iOS SDK to teracrafts/huefy-sdk-ios..."

# Check if we're in the project root
if [ ! -f "CLAUDE.md" ]; then
    echo "❌ This script must be run from the project root directory"
    exit 1
fi

# Check if iOS SDK exists
if [ ! -d "sdks/ios" ]; then
    echo "❌ iOS SDK directory not found: sdks/ios"
    exit 1
fi

# Repository URL
REPO_URL="git@github.com:teracrafts/huefy-sdk-ios.git"
REMOTE_NAME="ios-repo"

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
echo "🌳 Creating subtree split for iOS SDK..."
SUBTREE_COMMIT=$(git subtree split --prefix=sdks/ios HEAD)

if [ -z "$SUBTREE_COMMIT" ]; then
    echo "❌ Failed to create subtree split"
    exit 1
fi

echo "📤 Pushing to remote repository..."
git push $REMOTE_NAME $SUBTREE_COMMIT:refs/heads/main --force

echo "✅ iOS SDK deployed successfully!"
echo "📦 Repository: https://github.com/teracrafts/huefy-sdk-ios"
echo "🔗 Commit: $SUBTREE_COMMIT"

# Optional: Create a git tag for versioning
if [ -n "$1" ]; then
    VERSION="$1"
    echo "🏷️  Creating version tag: v$VERSION"
    git tag -a "ios-v$VERSION" $SUBTREE_COMMIT -m "iOS SDK version $VERSION"
    git push $REMOTE_NAME "ios-v$VERSION"
    echo "✅ Version tag v$VERSION created and pushed"
fi

echo ""
echo "🎯 Next steps:"
echo "1. Visit https://github.com/teracrafts/huefy-sdk-ios to verify the deployment"
echo "2. Create a release on GitHub if needed"
echo "3. Update Swift Package Manager registry if applicable"