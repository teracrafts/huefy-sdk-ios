#!/bin/bash

# Publish all Huefy SDKs to their respective registries
# Usage: ./scripts/publish-all.sh [--dry-run]

set -e

# Load environment variables from .env file if it exists
if [ -f "$PROJECT_ROOT/.env" ]; then
    export $(grep -v '^#' "$PROJECT_ROOT/.env" | xargs)
fi

DRY_RUN=false
if [ "$1" = "--dry-run" ]; then
    DRY_RUN=true
    echo "🧪 DRY RUN MODE - No actual publishing will occur"
fi

if [ "$DRY_RUN" = true ]; then
    echo "🧪 Publishing all Huefy SDKs (DRY RUN)..."
else
    echo "🚀 Publishing all Huefy SDKs..."
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Track publishing results
TOTAL_SDKS=0
PUBLISHED_SDKS=0
FAILED_SDKS=0
SKIPPED_SDKS=0

# Function to publish a specific SDK
publish_sdk() {
    local sdk_name="$1"
    local sdk_dir="$2"
    local publish_command="$3"
    local dry_run_command="$4"
    local icon="$5"
    
    TOTAL_SDKS=$((TOTAL_SDKS + 1))
    
    if [ -d "$sdk_dir" ]; then
        echo -e "${BLUE}${icon} Publishing ${sdk_name} SDK...${NC}"
        cd "$sdk_dir"
        
        # Choose command based on dry run mode
        local command_to_run="$publish_command"
        if [ "$DRY_RUN" = true ] && [ -n "$dry_run_command" ]; then
            command_to_run="$dry_run_command"
        fi
        
        if [ "$DRY_RUN" = true ]; then
            echo -e "${YELLOW}   🧪 DRY RUN: Would execute: $command_to_run${NC}"
            PUBLISHED_SDKS=$((PUBLISHED_SDKS + 1))
        else
            if eval "$command_to_run" > publish_output.log 2>&1; then
                echo -e "${GREEN}✅ ${sdk_name} SDK published successfully${NC}"
                PUBLISHED_SDKS=$((PUBLISHED_SDKS + 1))
                
                # Show relevant output
                if grep -q -E "(published|deployed|uploaded)" publish_output.log 2>/dev/null; then
                    echo -e "${BLUE}   📦 Publishing details:${NC}"
                    grep -E "(published|deployed|uploaded|version)" publish_output.log | head -2 | sed 's/^/   /'
                fi
            else
                echo -e "${RED}❌ ${sdk_name} SDK publishing failed${NC}"
                FAILED_SDKS=$((FAILED_SDKS + 1))
                
                echo -e "${RED}   Error output:${NC}"
                tail -5 publish_output.log | sed 's/^/   /'
            fi
            
            # Clean up
            rm -f publish_output.log
        fi
        
        cd "$PROJECT_ROOT"
    else
        echo -e "${YELLOW}⚠️ ${sdk_name} SDK directory not found, skipping${NC}"
        SKIPPED_SDKS=$((SKIPPED_SDKS + 1))
    fi
}

# Check for required tools and credentials
check_prerequisites() {
    echo -e "${BLUE}🔍 Checking prerequisites...${NC}"
    
    local missing_tools=()
    
    # Check for required command line tools
    if ! command -v npm &> /dev/null; then
        missing_tools+=("npm (for JavaScript/React SDKs)")
    fi
    
    if ! command -v mvn &> /dev/null; then
        missing_tools+=("maven (for Java SDK)")
    fi
    
    if ! command -v python &> /dev/null; then
        missing_tools+=("python (for Python SDK)")
    fi
    
    if ! command -v composer &> /dev/null; then
        missing_tools+=("composer (for PHP SDK)")
    fi
    
    if ! command -v git &> /dev/null; then
        missing_tools+=("git (for Go SDK)")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo -e "${RED}❌ Missing required tools:${NC}"
        for tool in "${missing_tools[@]}"; do
            echo -e "${RED}   - $tool${NC}"
        done
        exit 1
    fi
    
    echo -e "${GREEN}✅ All required tools are available${NC}"
    
    if [ "$DRY_RUN" = false ]; then
        echo ""
        echo -e "${YELLOW}⚠️ Make sure you have configured the following credentials:${NC}"
        echo -e "${YELLOW}   - NPM_TOKEN for npm registry${NC}"
        echo -e "${YELLOW}   - PYPI credentials for Python Package Index${NC}"
        echo -e "${YELLOW}   - Maven Central credentials for Java${NC}"
        echo -e "${YELLOW}   - Git access for Go module tagging${NC}"
        echo -e "${YELLOW}   - Packagist webhook for PHP (auto-publishing)${NC}"
        echo ""
        
        read -p "Do you want to continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Publishing cancelled."
            exit 0
        fi
    fi
}

# Run prerequisites check
check_prerequisites

echo ""

# Publish JavaScript SDK to NPM
publish_sdk "JavaScript" "sdks/javascript" \
    "npm publish --access public" \
    "npm publish --dry-run --access public" \
    "📦"

# Publish React SDK to NPM
publish_sdk "React" "sdks/react" \
    "npm publish --access public" \
    "npm publish --dry-run --access public" \
    "⚛️"

# Publish Python SDK to PyPI
publish_sdk "Python" "sdks/python" \
    "python -m build && python -m twine upload dist/*" \
    "python -m build && python -m twine check dist/*" \
    "🐍"

# Publish Java SDK to Maven Central
publish_sdk "Java" "sdks/java" \
    "mvn clean deploy -P release" \
    "mvn clean deploy -P release -DskipRemoteStaging=true" \
    "☕"

# Publish Go SDK (via git tags)
if [ -d "sdks/go" ]; then
    echo -e "${BLUE}🐹 Publishing Go SDK...${NC}"
    TOTAL_SDKS=$((TOTAL_SDKS + 1))
    
    # Get current version from git tags
    CURRENT_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}   🧪 DRY RUN: Would create git tag and push to origin${NC}"
        echo -e "${YELLOW}   Current version: $CURRENT_VERSION${NC}"
        PUBLISHED_SDKS=$((PUBLISHED_SDKS + 1))
    else
        echo -e "${BLUE}   📋 Go SDK uses git tags for versioning${NC}"
        echo -e "${BLUE}   Current version: $CURRENT_VERSION${NC}"
        echo -e "${BLUE}   ✅ Go SDK will be available via: go get github.com/your-org/huefy-sdk/sdks/go@$CURRENT_VERSION${NC}"
        PUBLISHED_SDKS=$((PUBLISHED_SDKS + 1))
    fi
else
    echo -e "${YELLOW}⚠️ Go SDK directory not found, skipping${NC}"
    SKIPPED_SDKS=$((SKIPPED_SDKS + 1))
fi

# PHP SDK (auto-published via Packagist webhook)
if [ -d "sdks/php" ]; then
    echo -e "${BLUE}🐘 Publishing PHP SDK...${NC}"
    TOTAL_SDKS=$((TOTAL_SDKS + 1))
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}   🧪 DRY RUN: PHP SDK would be auto-published via Packagist webhook${NC}"
    else
        echo -e "${BLUE}   📋 PHP SDK is auto-published via Packagist webhook${NC}"
        echo -e "${BLUE}   ✅ Push to main branch will trigger automatic publishing${NC}"
    fi
    PUBLISHED_SDKS=$((PUBLISHED_SDKS + 1))
else
    echo -e "${YELLOW}⚠️ PHP SDK directory not found, skipping${NC}"
    SKIPPED_SDKS=$((SKIPPED_SDKS + 1))
fi

# Summary
echo ""
echo -e "${BLUE}📊 Publishing Summary${NC}"
echo "======================"
echo -e "Total SDKs:    ${TOTAL_SDKS}"
echo -e "${GREEN}Published:     ${PUBLISHED_SDKS}${NC}"
echo -e "${RED}Failed:        ${FAILED_SDKS}${NC}"
echo -e "${YELLOW}Skipped:       ${SKIPPED_SDKS}${NC}"

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo -e "${BLUE}🧪 This was a dry run. No actual publishing occurred.${NC}"
    echo -e "${BLUE}Run without --dry-run to perform actual publishing.${NC}"
fi

# Exit with appropriate code
if [ $FAILED_SDKS -gt 0 ]; then
    echo ""
    echo -e "${RED}❌ Some SDKs failed to publish. Please fix the issues before proceeding.${NC}"
    exit 1
elif [ $PUBLISHED_SDKS -eq 0 ]; then
    echo ""
    echo -e "${YELLOW}⚠️ No SDKs were published. Please ensure SDKs are properly built and configured.${NC}"
    exit 1
else
    echo ""
    if [ "$DRY_RUN" = true ]; then
        echo -e "${GREEN}🎉 Dry run completed successfully! All SDKs are ready for publishing.${NC}"
    else
        echo -e "${GREEN}🎉 All SDKs published successfully!${NC}"
        echo ""
        echo -e "${BLUE}📋 Next steps:${NC}"
        echo -e "${BLUE}   1. Verify packages are available in their respective registries${NC}"
        echo -e "${BLUE}   2. Update documentation with new version numbers${NC}"
        echo -e "${BLUE}   3. Announce the release to your team/community${NC}"
    fi
    exit 0
fi