#!/bin/bash

# Script to create a php-sdk branch containing only the PHP SDK files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Save current branch
CURRENT_BRANCH=$(git branch --show-current)
print_status "Current branch: $CURRENT_BRANCH"

# Create orphan branch for PHP SDK
print_status "Creating orphan php-sdk branch..."
git checkout --orphan php-sdk

# Remove all files from the new branch
print_status "Clearing branch..."
git rm -rf .

# Copy PHP SDK files to root
print_status "Copying PHP SDK files..."
git checkout "$CURRENT_BRANCH" -- sdks/php
cp -r sdks/php/* .
cp sdks/php/.php-cs-fixer.php . 2>/dev/null || true
cp sdks/php/.php-cs-fixer.cache . 2>/dev/null || true
rm -rf sdks/

# Add all files
print_status "Adding files to git..."
git add .

# Commit the PHP SDK files
print_status "Creating initial commit..."
git commit -m "PHP SDK v1.0.0-beta.2 - Packagist Ready

- Official PHP SDK for Huefy under teracrafts organization
- Package: teracrafts/huefy
- Complete SDK with quality tools and automation
- Ready for Packagist deployment

Features:
- PSR-4 autoloading (Huefy\\SDK namespace)
- Guzzle HTTP client with retry logic
- Multiple email provider support
- Comprehensive error handling
- Quality tools: PHPStan, PHPMD, PHP CS Fixer
- Task automation integration
- Full test suite"

# Push the branch to remote
print_status "Pushing php-sdk branch to remote..."
git push origin php-sdk

# Return to original branch
print_status "Returning to $CURRENT_BRANCH branch..."
git checkout "$CURRENT_BRANCH"

print_success "PHP SDK branch created successfully!"
echo
echo "📦 Packagist Deployment:"
echo "Repository URL: https://github.com/teracrafts/huefy-sdk"
echo "Branch: php-sdk"
echo "Package: teracrafts/huefy"
echo
echo "🚀 Submit to Packagist:"
echo "1. Visit: https://packagist.org/packages/submit"
echo "2. Enter: https://github.com/teracrafts/huefy-sdk"
echo "3. Select branch: php-sdk"
echo