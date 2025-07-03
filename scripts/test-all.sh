#!/bin/bash

# Test all Huefy SDKs
set -e

echo "🧪 Running tests for all Huefy SDKs..."

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

# Track test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Function to run tests for a specific SDK
run_test() {
    local sdk_name="$1"
    local sdk_dir="$2"
    local test_command="$3"
    local icon="$4"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ -d "$sdk_dir" ]; then
        echo -e "${BLUE}${icon} Testing ${sdk_name} SDK...${NC}"
        cd "$sdk_dir"
        
        if eval "$test_command" > test_output.log 2>&1; then
            echo -e "${GREEN}✅ ${sdk_name} SDK tests passed${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            
            # Show test summary if available
            if grep -q "test" test_output.log 2>/dev/null; then
                echo -e "${BLUE}   📊 Test summary:${NC}"
                grep -E "(test|spec|Test|passed|failed)" test_output.log | head -3 | sed 's/^/   /'
            fi
        else
            echo -e "${RED}❌ ${sdk_name} SDK tests failed${NC}"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            
            echo -e "${RED}   Error output:${NC}"
            tail -10 test_output.log | sed 's/^/   /'
        fi
        
        # Clean up
        rm -f test_output.log
        cd "$PROJECT_ROOT"
    else
        echo -e "${YELLOW}⚠️ ${sdk_name} SDK directory not found, skipping tests${NC}"
        SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
    fi
}

# Test JavaScript SDK
run_test "JavaScript" "sdks/javascript" "npm test" "📦"

# Test React SDK
run_test "React" "sdks/react" "npm test" "⚛️"

# Test Go SDK
run_test "Go" "sdks/go" "go test -v ./..." "🐹"

# Test Java SDK
run_test "Java" "sdks/java" "mvn test -q" "☕"

# Test Python SDK
run_test "Python" "sdks/python" "python -m pytest -v" "🐍"

# Test PHP SDK
run_test "PHP" "sdks/php" "composer test" "🐘"

# Test Laravel SDK
run_test "Laravel" "sdks/laravel" "composer test" "🔶"

# Summary
echo ""
echo -e "${BLUE}📊 Test Summary${NC}"
echo "=================="
echo -e "Total SDKs:  ${TOTAL_TESTS}"
echo -e "${GREEN}Passed:      ${PASSED_TESTS}${NC}"
echo -e "${RED}Failed:      ${FAILED_TESTS}${NC}"
echo -e "${YELLOW}Skipped:     ${SKIPPED_TESTS}${NC}"

# Exit with appropriate code
if [ $FAILED_TESTS -gt 0 ]; then
    echo ""
    echo -e "${RED}❌ Some tests failed. Please fix the issues before proceeding.${NC}"
    exit 1
elif [ $PASSED_TESTS -eq 0 ]; then
    echo ""
    echo -e "${YELLOW}⚠️ No tests were run. Please ensure SDKs are properly set up.${NC}"
    exit 1
else
    echo ""
    echo -e "${GREEN}🎉 All tests passed successfully!${NC}"
    exit 0
fi