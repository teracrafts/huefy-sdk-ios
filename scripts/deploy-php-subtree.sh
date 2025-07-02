#!/bin/bash

# Deploy PHP SDK to standalone repository using git subtree
# This maintains a clean PHP-only repository for Packagist

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if php-repo remote exists
check_remote() {
    if ! git remote | grep -q "^php-repo$"; then
        print_status "Adding php-repo remote..."
        git remote add php-repo git@github.com:teracrafts/teracrafts-huefy-sdk-php.git
    fi
}

# Deploy PHP SDK
deploy_php() {
    local version="${1:-}"
    
    print_status "Deploying PHP SDK to standalone repository..."
    
    # Ensure we're on main branch
    local current_branch=$(git branch --show-current)
    if [ "$current_branch" != "main" ]; then
        print_error "Must be on main branch to deploy. Currently on: $current_branch"
        exit 1
    fi
    
    # Check for uncommitted changes
    if [ -n "$(git status --porcelain)" ]; then
        print_error "Working directory has uncommitted changes. Please commit or stash them."
        exit 1
    fi
    
    # Create subtree and push
    print_status "Creating subtree from sdks/php..."
    local subtree_commit=$(git subtree split --prefix=sdks/php HEAD)
    
    print_status "Pushing to php-repo..."
    git push php-repo ${subtree_commit}:main --force
    
    # Push tags if version specified
    if [ -n "$version" ]; then
        print_status "Creating version tag v$version..."
        git push php-repo ${subtree_commit}:refs/tags/v${version} --force
        print_success "Tagged version v$version"
    fi
    
    print_success "PHP SDK deployed successfully!"
    echo
    echo "Repository: https://github.com/teracrafts/teracrafts-huefy-sdk-php"
    echo "Packagist: Submit at https://packagist.org/packages/submit"
    echo
}

# Main function
main() {
    cd "$PROJECT_ROOT"
    
    check_remote
    deploy_php "$@"
}

# Run main function with all arguments
main "$@"