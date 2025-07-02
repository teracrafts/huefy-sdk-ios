#!/bin/bash

# PHP SDK Release Automation Script
# This script automates the PHP SDK release process

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

# Function to validate composer.json
validate_composer() {
    print_status "Validating composer.json..."
    cd "$PHP_SDK_DIR"
    
    if ! composer validate --strict; then
        print_error "composer.json validation failed"
        exit 1
    fi
    
    print_success "composer.json is valid"
}

# Function to run quality checks
run_quality_checks() {
    print_status "Running quality checks..."
    cd "$PHP_SDK_DIR"
    
    # Install dependencies
    composer install --dev --no-progress
    
    # Run quality checks
    if ! composer quality; then
        print_error "Quality checks failed"
        exit 1
    fi
    
    print_success "All quality checks passed"
}

# Function to run security audit
run_security_audit() {
    print_status "Running security audit..."
    cd "$PHP_SDK_DIR"
    
    if ! composer audit; then
        print_error "Security audit failed"
        exit 1
    fi
    
    print_success "Security audit passed"
}

# Function to check for outdated dependencies
check_outdated_deps() {
    print_status "Checking for outdated dependencies..."
    cd "$PHP_SDK_DIR"
    
    print_warning "Outdated dependencies (if any):"
    composer outdated --direct || true
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
- Version: $version"
    
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

# Function to display next steps
display_next_steps() {
    local version="$1"
    
    echo
    print_success "PHP SDK release preparation completed!"
    echo
    echo "Next steps:"
    echo "1. Submit to Packagist: https://packagist.org/packages/submit"
    echo "2. Repository URL: https://github.com/teracrafts/huefy-sdk"
    echo "3. Package will be available as: teracrafts/huefy"
    echo "4. Version: $version"
    echo "5. Installation: composer require teracrafts/huefy"
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
    
    # Run all checks
    check_directory
    check_git_status
    validate_composer
    run_quality_checks
    run_security_audit
    check_outdated_deps
    
    # Create git tag
    create_git_tag "$version"
    
    # Display next steps
    display_next_steps "$version"
}

# Run main function with all arguments
main "$@"