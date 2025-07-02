#!/bin/bash

# Clean build artifacts from all Huefy SDKs
set -e

echo "🧹 Cleaning build artifacts from all Huefy SDKs..."

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

# Track cleaning results
TOTAL_SDKS=0
CLEANED_SDKS=0
SKIPPED_SDKS=0

# Function to clean a specific SDK
clean_sdk() {
    local sdk_name="$1"
    local sdk_dir="$2"
    local clean_commands="$3"
    local icon="$4"
    
    TOTAL_SDKS=$((TOTAL_SDKS + 1))
    
    if [ -d "$sdk_dir" ]; then
        echo -e "${BLUE}${icon} Cleaning ${sdk_name} SDK...${NC}"
        cd "$sdk_dir"
        
        # Execute clean commands
        if eval "$clean_commands" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ ${sdk_name} SDK cleaned${NC}"
            CLEANED_SDKS=$((CLEANED_SDKS + 1))
        else
            echo -e "${YELLOW}⚠️ ${sdk_name} SDK cleaning completed with warnings${NC}"
            CLEANED_SDKS=$((CLEANED_SDKS + 1))
        fi
        
        cd "$PROJECT_ROOT"
    else
        echo -e "${YELLOW}⚠️ ${sdk_name} SDK directory not found, skipping${NC}"
        SKIPPED_SDKS=$((SKIPPED_SDKS + 1))
    fi
}

# Clean JavaScript SDK
clean_sdk "JavaScript" "sdks/javascript" \
    "rm -rf node_modules dist build .next coverage .nyc_output && npm cache clean --force" \
    "📦"

# Clean React SDK
clean_sdk "React" "sdks/react" \
    "rm -rf node_modules dist build .next coverage .nyc_output && npm cache clean --force" \
    "⚛️"

# Clean Go SDK
clean_sdk "Go" "sdks/go" \
    "go clean -cache -modcache -testcache && rm -rf bin/ vendor/" \
    "🐹"

# Clean Java SDK
clean_sdk "Java" "sdks/java" \
    "mvn clean && rm -rf target/ .m2/repository/com/huefy/ *.log" \
    "☕"

# Clean Python SDK
clean_sdk "Python" "sdks/python" \
    "rm -rf build/ dist/ *.egg-info/ __pycache__/ .pytest_cache/ .coverage .tox/ venv/ env/" \
    "🐍"

# Clean PHP SDK
clean_sdk "PHP" "sdks/php" \
    "rm -rf vendor/ composer.lock .phpunit.result.cache coverage/ build/" \
    "🐘"

# Clean project-wide artifacts
echo -e "${BLUE}🗂️ Cleaning project-wide artifacts...${NC}"

# Clean generated SDKs
if [ -d "generated" ]; then
    echo -e "${YELLOW}   Removing generated/ directory...${NC}"
    rm -rf generated/
fi

# Clean common build artifacts
echo -e "${YELLOW}   Removing common build artifacts...${NC}"
find . -name "*.log" -type f -delete 2>/dev/null || true
find . -name "*.tmp" -type f -delete 2>/dev/null || true
find . -name ".DS_Store" -type f -delete 2>/dev/null || true
find . -name "Thumbs.db" -type f -delete 2>/dev/null || true

# Clean backup files from version bumping
echo -e "${YELLOW}   Removing backup files...${NC}"
find . -name "*.backup" -type f -delete 2>/dev/null || true
find . -name "*~" -type f -delete 2>/dev/null || true

# Clean IDE and editor files
echo -e "${YELLOW}   Removing IDE artifacts...${NC}"
rm -rf .vscode/settings.json .idea/ *.swp *.swo 2>/dev/null || true

# Clean Docker artifacts if any
if [ -d ".docker" ]; then
    echo -e "${YELLOW}   Removing Docker artifacts...${NC}"
    rm -rf .docker/
fi

# Clean temporary directories
echo -e "${YELLOW}   Removing temporary directories...${NC}"
rm -rf tmp/ temp/ .tmp/ 2>/dev/null || true

# Summary
echo ""
echo -e "${BLUE}📊 Cleaning Summary${NC}"
echo "==================="
echo -e "Total SDKs:  ${TOTAL_SDKS}"
echo -e "${GREEN}Cleaned:     ${CLEANED_SDKS}${NC}"
echo -e "${YELLOW}Skipped:     ${SKIPPED_SDKS}${NC}"

# Calculate space saved (rough estimate)
echo ""
echo -e "${BLUE}💾 Estimated space saved:${NC}"
echo -e "${GREEN}   - Node modules and build artifacts${NC}"
echo -e "${GREEN}   - Maven/Gradle cache and targets${NC}"
echo -e "${GREEN}   - Python build/cache directories${NC}"
echo -e "${GREEN}   - Go module cache${NC}"
echo -e "${GREEN}   - Composer vendor directories${NC}"
echo -e "${GREEN}   - Generated OpenAPI artifacts${NC}"

echo ""
echo -e "${GREEN}🎉 Cleanup completed successfully!${NC}"
echo ""
echo -e "${BLUE}💡 Next steps:${NC}"
echo -e "${BLUE}   - Run 'task setup' to reinstall dependencies${NC}"
echo -e "${BLUE}   - Run 'task build' to rebuild all SDKs${NC}"
echo -e "${BLUE}   - Run 'task generate' to regenerate OpenAPI artifacts${NC}"

exit 0