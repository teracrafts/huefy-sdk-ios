#!/bin/bash

# Huefy SDK Generation Script
# Generates all SDKs from OpenAPI specification

set -e  # Exit on any error

echo "🚀 Generating Huefy SDKs for all platforms..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if OpenAPI Generator CLI is installed
if ! command -v openapi-generator-cli &> /dev/null; then
    echo -e "${RED}❌ OpenAPI Generator CLI not found!${NC}"
    echo "Please install it with: npm install @openapitools/openapi-generator-cli -g"
    exit 1
fi

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Change to project root
cd "$PROJECT_ROOT"

# Validate OpenAPI spec first
echo -e "${YELLOW}📝 Validating OpenAPI specification...${NC}"
if ! openapi-generator-cli validate -i core/openapi/openapi.yaml; then
    echo -e "${RED}❌ OpenAPI specification is invalid!${NC}"
    exit 1
fi
echo -e "${GREEN}✅ OpenAPI specification is valid${NC}"

# Clean previous generated files
echo -e "${YELLOW}🧹 Cleaning previous generated files...${NC}"
rm -rf generated/
mkdir -p generated

# List of supported languages
languages=("javascript" "go" "java" "python" "php")

# Generate SDKs for each language
for lang in "${languages[@]}"; do
    echo -e "${YELLOW}🔧 Generating $lang SDK...${NC}"
    
    config_file="core/config/generators/$lang.yaml"
    
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}❌ Configuration file not found: $config_file${NC}"
        continue
    fi
    
    # Create language-specific output directory
    mkdir -p "generated/$lang"
    
    # Generate SDK using OpenAPI Generator
    if openapi-generator-cli generate \
        -i core/openapi/openapi.yaml \
        -c "$config_file" \
        --skip-validate-spec \
        --enable-post-process-file; then
        echo -e "${GREEN}✅ $lang SDK generated successfully${NC}"
    else
        echo -e "${RED}❌ Failed to generate $lang SDK${NC}"
        exit 1
    fi
done

echo -e "${GREEN}🎉 All SDKs generated successfully!${NC}"
echo ""
echo "Generated SDKs:"
for lang in "${languages[@]}"; do
    echo "  📦 $lang: generated/$lang/"
done

echo ""
echo "Next steps:"
echo "  1. Review generated SDKs in the generated/ directory"
echo "  2. Create idiomatic wrappers in sdks/ directories"
echo "  3. Build and test the SDKs"
echo "  4. Create examples for each language"

echo ""
echo -e "${YELLOW}💡 Tip: Use './scripts/build-all.sh' to build all SDKs${NC}"