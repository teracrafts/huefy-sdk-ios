#!/bin/bash

# Publish JavaScript and React SDKs to NPM
# This script will be used once NPM authentication is configured

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Publishing Huefy SDKs to NPM${NC}"
echo ""

# Check if logged in to NPM
if ! npm whoami >/dev/null 2>&1; then
    echo -e "${RED}❌ Not logged in to NPM. Please configure authentication first.${NC}"
    echo -e "${YELLOW}Options:${NC}"
    echo -e "${YELLOW}1. Set NPM_TOKEN: export NPM_TOKEN='your_token'${NC}"
    echo -e "${YELLOW}2. Create ~/.npmrc: echo '//registry.npmjs.org/:_authToken=your_token' > ~/.npmrc${NC}"
    echo -e "${YELLOW}3. Run: npm login${NC}"
    exit 1
fi

echo -e "${GREEN}✅ NPM authentication verified${NC}"
echo ""

# Publish JavaScript SDK
echo -e "${YELLOW}📦 Publishing JavaScript SDK (@teracrafts/huefy@1.0.0-beta.10)...${NC}"
pushd sdks/javascript
npm publish --tag beta
popd
echo -e "${GREEN}✅ JavaScript SDK published successfully!${NC}"
echo ""

# Publish React SDK  
echo -e "${YELLOW}⚛️  Publishing React SDK (@teracrafts/huefy-react@1.0.0-beta.10)...${NC}"
pushd sdks/react
npm publish --tag beta
popd
echo -e "${GREEN}✅ React SDK published successfully!${NC}"
echo ""

echo -e "${GREEN}🎉 Both SDKs published to NPM successfully!${NC}"
echo ""
echo -e "${BLUE}📦 Published Packages:${NC}"
echo -e "${BLUE}   • @teracrafts/huefy@1.0.0-beta.10${NC}"
echo -e "${BLUE}   • @teracrafts/huefy-react@1.0.0-beta.10${NC}"
echo ""
echo -e "${BLUE}📋 Installation:${NC}"
echo -e "${BLUE}   npm install @teracrafts/huefy@beta${NC}"
echo -e "${BLUE}   npm install @teracrafts/huefy-react@beta${NC}"