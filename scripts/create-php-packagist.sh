#!/bin/bash

# PHP SDK Packagist Deployment Script
# This script prepares and submits the PHP SDK to Packagist

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

# Function to validate repository is public
check_repository_public() {
    print_status "Checking if repository is public..."
    
    # Try to access the repository without authentication
    if curl -s -f "https://api.github.com/repos/teracrafts/huefy-sdk" > /dev/null; then
        print_success "Repository is publicly accessible"
    else
        print_error "Repository is private. Please make it public for Packagist to access it."
        print_warning "Go to: https://github.com/teracrafts/huefy-sdk/settings"
        print_warning "Under 'Danger Zone', click 'Change repository visibility'"
        exit 1
    fi
}

# Function to validate composer.json
validate_composer() {
    print_status "Validating composer.json..."
    cd "$PHP_SDK_DIR"
    
    if ! composer validate --strict --quiet; then
        print_error "composer.json validation failed"
        exit 1
    fi
    
    # Check required fields for Packagist
    local required_fields=("name" "description" "type" "license")
    for field in "${required_fields[@]}"; do
        if ! grep -q "\"$field\"" composer.json; then
            print_error "Required field '$field' missing from composer.json"
            exit 1
        fi
    done
    
    print_success "composer.json is valid and ready for Packagist"
}

# Function to check version tag exists
check_version_tag() {
    local version="$1"
    local tag_name="php-v$version"
    
    print_status "Checking if git tag exists for version: $version"
    
    if ! git tag -l | grep -q "^$tag_name$"; then
        print_error "Git tag '$tag_name' does not exist"
        print_warning "Create a tag first: git tag -a $tag_name -m 'PHP SDK v$version'"
        exit 1
    fi
    
    print_success "Tag '$tag_name' exists"
}

# Function to run basic quality checks
run_basic_checks() {
    print_status "Running basic quality checks..."
    cd "$PHP_SDK_DIR"
    
    # Check if dependencies can be installed
    print_status "Testing dependency installation..."
    if ! composer install --dry-run --quiet; then
        print_error "Composer dependencies cannot be installed"
        exit 1
    fi
    
    print_success "Basic quality checks passed"
}

# Function to display Packagist submission instructions
display_packagist_instructions() {
    local version="${1:-}"
    
    echo
    print_success "PHP SDK is ready for Packagist submission!"
    echo
    echo "📦 Package Information:"
    echo "   Name: teracrafts/huefy"
    echo "   Repository: https://github.com/teracrafts/huefy-sdk"
    echo "   Composer Path: sdks/php/"
    if [ -n "$version" ]; then
        echo "   Version: $version (git tag: php-v$version)"
    fi
    echo
    echo "🚀 Submission Steps:"
    echo "1. Go to: https://packagist.org/packages/submit"
    echo "2. Enter repository URL: https://github.com/teracrafts/huefy-sdk"
    echo "3. Packagist will automatically detect the composer.json in sdks/php/"
    echo "4. Click 'Check' to validate the package"
    echo "5. Click 'Submit' to publish"
    echo
    echo "📝 Post-Submission:"
    echo "1. Set up GitHub webhook for automatic updates:"
    echo "   - Go to: https://github.com/teracrafts/huefy-sdk/settings/hooks"
    echo "   - Add webhook URL from Packagist package page"
    echo "2. Package will be available as: composer require teracrafts/huefy"
    echo
    print_warning "Note: Packagist may take a few minutes to index the package"
}

# Function to auto-submit to Packagist (if token is provided)
submit_to_packagist() {
    local token="${1:-}"
    
    if [ -z "$token" ]; then
        print_warning "No Packagist token provided, skipping automatic submission"
        return 0
    fi
    
    print_status "Attempting automatic submission to Packagist..."
    
    # Submit package to Packagist
    local response
    response=$(curl -s -X POST \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d '{"repository": {"url": "https://github.com/teracrafts/huefy-sdk"}}' \
        "https://packagist.org/api/create-package")
    
    if echo "$response" | grep -q '"status":"success"'; then
        print_success "Package successfully submitted to Packagist!"
        
        # Extract package URL if available
        local package_url
        package_url=$(echo "$response" | grep -o '"url":"[^"]*"' | cut -d'"' -f4)
        if [ -n "$package_url" ]; then
            echo "Package URL: $package_url"
        fi
    else
        print_warning "Automatic submission failed or package already exists"
        echo "Response: $response"
        print_status "Please submit manually using the instructions above"
    fi
}

# Main function
main() {
    local version="${1:-}"
    local packagist_token="${2:-}"
    
    if [ -z "$version" ]; then
        print_warning "Version not specified. Skipping version tag check."
        print_warning "Usage: $0 <version> [packagist_token]"
        print_warning "Example: $0 1.0.0-beta.2 your-packagist-token"
    fi
    
    print_status "Starting PHP SDK Packagist deployment..."
    
    # Run all checks
    check_directory
    check_repository_public
    validate_composer
    
    if [ -n "$version" ]; then
        check_version_tag "$version"
    fi
    
    run_basic_checks
    
    # Submit to Packagist
    if [ -n "$packagist_token" ]; then
        submit_to_packagist "$packagist_token"
    fi
    
    # Display instructions
    display_packagist_instructions "$version"
}

# Run main function with all arguments
main "$@"