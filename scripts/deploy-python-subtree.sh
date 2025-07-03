#!/bin/bash

# Deploy Python SDK to standalone repository using git subtree
# Usage: ./scripts/deploy-python-subtree.sh [version]

set -e

# Configuration
REMOTE_REPO="git@github.com:teracrafts/huefy-sdk-py.git"
SUBDIRECTORY="sdks/python"
VERSION=${1:-"v1.0.0"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Deploying Python SDK to standalone repository${NC}"
echo -e "${BLUE}Repository: ${REMOTE_REPO}${NC}"
echo -e "${BLUE}Version: ${VERSION}${NC}"
echo ""

# Check if we're in the right directory
if [[ ! -d "sdks/python" ]]; then
    echo -e "${RED}❌ Error: Must be run from project root directory${NC}"
    echo -e "${RED}   Current directory should contain 'sdks/python'${NC}"
    exit 1
fi

# Check if git working directory is clean
if [[ -n $(git status --porcelain) ]]; then
    echo -e "${RED}❌ Error: Git working directory is not clean${NC}"
    echo -e "${RED}   Please commit or stash your changes first${NC}"
    exit 1
fi

# Check if subdirectory exists
if [[ ! -d "$SUBDIRECTORY" ]]; then
    echo -e "${RED}❌ Error: Directory '$SUBDIRECTORY' does not exist${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Pre-deployment checks passed${NC}"

# Add remote if it doesn't exist
if ! git remote get-url python-repo >/dev/null 2>&1; then
    echo -e "${YELLOW}🔗 Adding remote repository...${NC}"
    git remote add python-repo "$REMOTE_REPO"
else
    echo -e "${YELLOW}🔗 Updating remote repository URL...${NC}"
    git remote set-url python-repo "$REMOTE_REPO"
fi

# Create subtree split
echo -e "${YELLOW}🌳 Creating subtree split for '$SUBDIRECTORY'...${NC}"
SUBTREE_COMMIT=$(git subtree split --prefix="$SUBDIRECTORY" HEAD)

if [[ -z "$SUBTREE_COMMIT" ]]; then
    echo -e "${RED}❌ Error: Failed to create subtree split${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Subtree split created: $SUBTREE_COMMIT${NC}"

# Push to remote repository
echo -e "${YELLOW}🚀 Pushing to remote repository...${NC}"
if git push python-repo "${SUBTREE_COMMIT}:refs/heads/main" --force; then
    echo -e "${GREEN}✅ Successfully pushed to main branch${NC}"
else
    echo -e "${RED}❌ Error: Failed to push to remote repository${NC}"
    exit 1
fi

# Create and push version tag
echo -e "${YELLOW}🏷️  Creating and pushing version tag: $VERSION${NC}"
if git push python-repo "${SUBTREE_COMMIT}:refs/tags/$VERSION" --force; then
    echo -e "${GREEN}✅ Successfully created and pushed tag: $VERSION${NC}"
else
    echo -e "${RED}❌ Error: Failed to create/push version tag${NC}"
    exit 1
fi

# Verify deployment
echo -e "${YELLOW}🔍 Verifying deployment...${NC}"
if git ls-remote python-repo | grep -q "refs/tags/$VERSION"; then
    echo -e "${GREEN}✅ Tag verification successful${NC}"
else
    echo -e "${RED}❌ Warning: Tag verification failed${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Python SDK deployment completed successfully!${NC}"
echo ""
echo -e "${BLUE}📦 Package Information:${NC}"
echo -e "${BLUE}   Package: teracrafts-huefy${NC}"
echo -e "${BLUE}   Version: $VERSION${NC}"
echo -e "${BLUE}   Repository: $REMOTE_REPO${NC}"
echo ""
echo -e "${BLUE}📋 Usage Instructions:${NC}"
echo -e "${BLUE}   pip install teracrafts-huefy==$VERSION${NC}"
echo ""
echo -e "${BLUE}🔗 Repository URL:${NC}"
echo -e "${BLUE}   https://github.com/teracrafts/huefy-sdk-py${NC}"

# Cleanup
git remote remove python-repo >/dev/null 2>&1 || true

echo -e "${GREEN}✨ Deployment script completed successfully!${NC}"