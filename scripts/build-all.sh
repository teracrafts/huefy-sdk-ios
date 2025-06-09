#!/bin/bash

# Build all Huefy SDKs
set -e

echo "🔨 Building all Huefy SDKs..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Build JavaScript/TypeScript SDK
if [ -d "sdks/javascript" ]; then
    echo -e "${YELLOW}📦 Building JavaScript SDK...${NC}"
    cd sdks/javascript
    if [ -f "package.json" ]; then
        npm install && npm run build
        echo -e "${GREEN}✅ JavaScript SDK built${NC}"
    else
        echo -e "${YELLOW}⚠️ JavaScript SDK not yet implemented${NC}"
    fi
    cd "$PROJECT_ROOT"
fi

# Build React SDK
if [ -d "sdks/react" ]; then
    echo -e "${YELLOW}⚛️ Building React SDK...${NC}"
    cd sdks/react
    if [ -f "package.json" ]; then
        npm install && npm run build
        echo -e "${GREEN}✅ React SDK built${NC}"
    else
        echo -e "${YELLOW}⚠️ React SDK not yet implemented${NC}"
    fi
    cd "$PROJECT_ROOT"
fi

# Build Go SDK
if [ -d "sdks/go" ]; then
    echo -e "${YELLOW}🐹 Building Go SDK...${NC}"
    cd sdks/go
    if [ -f "go.mod" ]; then
        go mod tidy && go build
        echo -e "${GREEN}✅ Go SDK built${NC}"
    else
        echo -e "${YELLOW}⚠️ Go SDK not yet implemented${NC}"
    fi
    cd "$PROJECT_ROOT"
fi

# Build Java SDK
if [ -d "sdks/java" ]; then
    echo -e "${YELLOW}☕ Building Java SDK...${NC}"
    cd sdks/java
    if [ -f "pom.xml" ]; then
        mvn clean compile package
        echo -e "${GREEN}✅ Java SDK built${NC}"
    elif [ -f "build.gradle" ]; then
        ./gradlew build
        echo -e "${GREEN}✅ Java SDK built${NC}"
    else
        echo -e "${YELLOW}⚠️ Java SDK not yet implemented${NC}"
    fi
    cd "$PROJECT_ROOT"
fi

# Build Python SDK
if [ -d "sdks/python" ]; then
    echo -e "${YELLOW}🐍 Building Python SDK...${NC}"
    cd sdks/python
    if [ -f "setup.py" ] || [ -f "pyproject.toml" ]; then
        python -m pip install -e .
        echo -e "${GREEN}✅ Python SDK built${NC}"
    else
        echo -e "${YELLOW}⚠️ Python SDK not yet implemented${NC}"
    fi
    cd "$PROJECT_ROOT"
fi

# Build PHP SDK
if [ -d "sdks/php" ]; then
    echo -e "${YELLOW}🐘 Building PHP SDK...${NC}"
    cd sdks/php
    if [ -f "composer.json" ]; then
        composer install
        echo -e "${GREEN}✅ PHP SDK built${NC}"
    else
        echo -e "${YELLOW}⚠️ PHP SDK not yet implemented${NC}"
    fi
    cd "$PROJECT_ROOT"
fi

echo -e "${GREEN}🎉 Build process completed!${NC}"