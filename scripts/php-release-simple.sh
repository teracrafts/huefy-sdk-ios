#!/bin/bash

# Simplified PHP SDK Release Script (without PHP/Composer dependency)
# This script handles git operations and basic validations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PHP_SDK_DIR="$PROJECT_ROOT/sdks/php"

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

# Function to check if we're in the right directory
check_directory() {
    if [ ! -f "$PHP_SDK_DIR/composer.json" ]; then
        print_error "PHP SDK composer.json not found. Are you running from the correct directory?"
        exit 1
    fi
    print_success "PHP SDK directory found"
}

# Function to check git status
check_git_status() {
    print_status "Checking git status..."
    
    if [ -n "$(git status --porcelain)" ]; then
        print_error "Working directory is not clean. Please commit or stash changes."
        git status --short
        exit 1
    fi
    
    print_success "Working directory is clean"
}

# Function to validate composer.json syntax
validate_composer_syntax() {
    print_status "Validating composer.json syntax..."
    
    if ! python3 -m json.tool "$PHP_SDK_DIR/composer.json" > /dev/null 2>&1; then
        print_error "composer.json has invalid JSON syntax"
        exit 1
    fi
    
    # Check for required fields
    if ! grep -q '"name".*"teracrafts/huefy"' "$PHP_SDK_DIR/composer.json"; then
        print_error "composer.json missing or incorrect package name"
        exit 1
    fi
    
    print_success "composer.json syntax is valid"
}

# Function to validate package structure
validate_package_structure() {
    print_status "Validating package structure..."
    
    # Check for required directories
    if [ ! -d "$PHP_SDK_DIR/src" ]; then
        print_error "src/ directory not found"
        exit 1
    fi
    
    if [ ! -d "$PHP_SDK_DIR/tests" ]; then
        print_error "tests/ directory not found"
        exit 1
    fi
    
    if [ ! -f "$PHP_SDK_DIR/README.md" ]; then
        print_error "README.md not found"
        exit 1
    fi
    
    print_success "Package structure is valid"
}

# Function to create git tag
create_git_tag() {
    local version="$1"
    local tag_name="php-v$version"
    
    print_status "Creating git tag: $tag_name"
    
    # Check if tag already exists
    if git tag -l | grep -q "^$tag_name$"; then
        print_error "Tag $tag_name already exists"
        exit 1
    fi
    
    # Create tag
    git tag -a "$tag_name" -m "PHP SDK v$version

- Release of PHP SDK under teracrafts organization
- Package: teracrafts/huefy  
- Version: $version
- Comprehensive automation and quality tools
- Ready for Packagist publication"
    
    print_success "Created tag: $tag_name"
    
    # Ask if user wants to push the tag
    read -p "Do you want to push the tag to remote? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git push origin "$tag_name"
        print_success "Tag pushed to remote"
    else
        print_warning "Tag created locally but not pushed to remote"
    fi
}

# Function to display packagist instructions
display_packagist_instructions() {
    local version="$1"
    
    echo
    print_success "PHP SDK release preparation completed!"
    echo
    echo "📦 PACKAGIST PUBLICATION INSTRUCTIONS:"
    echo "======================================="
    echo
    echo "1. Visit: https://packagist.org/packages/submit"
    echo "2. Repository URL: https://github.com/teracrafts/huefy-sdk"
    echo "3. Packagist will detect: teracrafts/huefy"
    echo "4. Version: $version (from git tag)"
    echo
    echo "🚀 INSTALLATION (after Packagist publication):"
    echo "composer require teracrafts/huefy"
    echo
    echo "📋 PACKAGE DETAILS:"
    echo "- Name: teracrafts/huefy"
    echo "- Version: $version"
    echo "- Namespace: Huefy\\SDK\\"
    echo "- License: MIT"
    echo "- Repository: https://github.com/teracrafts/huefy-sdk"
    echo
    echo "⚡ AUTOMATION FEATURES:"
    echo "- composer quality (PHPStan, Psalm, tests)"
    echo "- composer pre-commit (validation)"
    echo "- composer security (audit)"
    echo "- Task automation (task php-*)"
    echo
}

# Function to display next steps
display_next_steps() {
    echo "🔧 DEVELOPMENT COMMANDS:"
    echo "composer install-dev     # Install dependencies"
    echo "composer quality         # Run quality checks"
    echo "composer pre-commit      # Pre-commit validation"
    echo "composer security        # Security audit"
    echo
    echo "📊 PROJECT AUTOMATION:"
    echo "task php-install         # Install dependencies"
    echo "task php-quality         # Quality checks"
    echo "task php-pre-commit      # Pre-commit checks"
    echo "./scripts/php-release.sh # Full release (with PHP/Composer)"
    echo
}

# Main function
main() {
    local version="${1:-}"
    
    if [ -z "$version" ]; then
        print_error "Usage: $0 <version>"
        print_error "Example: $0 1.0.0-beta.2"
        exit 1
    fi
    
    print_status "Starting PHP SDK release process for version: $version"
    echo
    
    # Run all checks
    check_directory
    check_git_status
    validate_composer_syntax
    validate_package_structure
    
    # Create git tag
    create_git_tag "$version"
    
    # Display instructions
    display_packagist_instructions "$version"
    display_next_steps
}

# Run main function with all arguments
main "$@"