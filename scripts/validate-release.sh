#!/bin/bash

# Huefy SDK Release Validation Script
# Usage: ./scripts/validate-release.sh [version]
# Example: ./scripts/validate-release.sh 1.2.0

set -e

VERSION="$1"

echo "🔍 Validating release readiness for Huefy SDK..."

# Check if we're in the project root
if [ ! -f "CLAUDE.md" ]; then
    echo "❌ This script must be run from the project root directory"
    exit 1
fi

# If version is provided, validate it
if [ -n "$VERSION" ]; then
    if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+(\.[a-zA-Z0-9]+)*)?$ ]]; then
        echo "❌ Invalid version format: $VERSION"
        echo "Expected format: X.Y.Z or X.Y.Z-prerelease"
        exit 1
    fi
    echo "✅ Version format is valid: $VERSION"
fi

# Check Git status
echo "📋 Checking Git status..."
if [ -n "$(git status --porcelain)" ]; then
    echo "⚠️  There are uncommitted changes:"
    git status --short
    echo "💡 Consider committing changes before release"
else
    echo "✅ Working directory is clean"
fi

# Check if on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "⚠️  Currently on branch: $CURRENT_BRANCH"
    echo "💡 Consider switching to main branch for release"
else
    echo "✅ On main branch"
fi

# Check for required secrets (simulation - actual secrets won't be visible)
echo "🔐 Checking required deployment secrets..."
REQUIRED_SECRETS=(
    "NPM_TOKEN"
    "PYPI_TOKEN"
    "MAVEN_USERNAME"
    "MAVEN_PASSWORD"
    "MAVEN_GPG_PRIVATE_KEY"
    "MAVEN_GPG_PASSPHRASE"
)

echo "📝 Required secrets for deployment:"
for secret in "${REQUIRED_SECRETS[@]}"; do
    echo "   - $secret"
done
echo "💡 Ensure these are configured in GitHub repository secrets"

# Validate package.json files
echo "📦 Validating package configurations..."

# JavaScript SDK
if [ -f "sdks/javascript/package.json" ]; then
    cd sdks/javascript
    if npm run build > /dev/null 2>&1; then
        echo "✅ JavaScript SDK builds successfully"
    else
        echo "❌ JavaScript SDK build failed"
        exit 1
    fi
    cd ../..
else
    echo "❌ JavaScript SDK package.json not found"
    exit 1
fi

# React SDK
if [ -f "sdks/react/package.json" ]; then
    cd sdks/react
    if npm run build > /dev/null 2>&1; then
        echo "✅ React SDK builds successfully"
    else
        echo "❌ React SDK build failed"
        exit 1
    fi
    cd ../..
else
    echo "❌ React SDK package.json not found"
    exit 1
fi

# Python SDK
if [ -f "sdks/python/pyproject.toml" ]; then
    cd sdks/python
    if python -c "import huefy" > /dev/null 2>&1; then
        echo "✅ Python SDK imports successfully"
    else
        echo "❌ Python SDK import failed"
        exit 1
    fi
    cd ../..
else
    echo "❌ Python SDK pyproject.toml not found"
    exit 1
fi

# Java SDK
if [ -f "sdks/java/pom.xml" ]; then
    cd sdks/java
    if mvn compile -q > /dev/null 2>&1; then
        echo "✅ Java SDK compiles successfully"
    else
        echo "❌ Java SDK compilation failed"
        exit 1
    fi
    cd ../..
else
    echo "❌ Java SDK pom.xml not found"
    exit 1
fi

# PHP SDK
if [ -f "sdks/php/composer.json" ]; then
    cd sdks/php
    if composer validate --strict > /dev/null 2>&1; then
        echo "✅ PHP SDK composer.json is valid"
    else
        echo "❌ PHP SDK composer.json validation failed"
        exit 1
    fi
    cd ../..
else
    echo "❌ PHP SDK composer.json not found"
    exit 1
fi

# Go SDK
if [ -f "sdks/go/go.mod" ]; then
    cd sdks/go
    if go build . > /dev/null 2>&1; then
        echo "✅ Go SDK builds successfully"
    else
        echo "❌ Go SDK build failed"
        exit 1
    fi
    cd ../..
else
    echo "❌ Go SDK go.mod not found"
    exit 1
fi

# Check OpenAPI spec
echo "📄 Validating OpenAPI specification..."
if [ -f "core/openapi/openapi.yaml" ]; then
    # Basic YAML syntax check
    if python -c "import yaml; yaml.safe_load(open('core/openapi/openapi.yaml'))" > /dev/null 2>&1; then
        echo "✅ OpenAPI specification is valid YAML"
    else
        echo "❌ OpenAPI specification has YAML syntax errors"
        exit 1
    fi
else
    echo "❌ OpenAPI specification not found"
    exit 1
fi

# Check documentation
echo "📚 Checking documentation..."
REQUIRED_DOCS=(
    "README.md"
    "CLAUDE.md"
    "IMPLEMENTATION.md"
    "sdks/javascript/README.md"
    "sdks/react/README.md"
    "sdks/go/README.md"
    "sdks/java/README.md"
    "sdks/python/README.md"
    "sdks/php/README.md"
)

for doc in "${REQUIRED_DOCS[@]}"; do
    if [ -f "$doc" ]; then
        echo "✅ $doc exists"
    else
        echo "❌ $doc missing"
        exit 1
    fi
done

# Check examples
echo "🚀 Checking examples..."
EXAMPLE_DIRS=(
    "sdks/javascript/examples"
    "sdks/react/examples"
    "sdks/go/examples"
    "sdks/java/examples"
    "sdks/python/examples"
    "sdks/php/examples"
)

for example_dir in "${EXAMPLE_DIRS[@]}"; do
    if [ -d "$example_dir" ] && [ "$(ls -A $example_dir)" ]; then
        echo "✅ $example_dir has examples"
    else
        echo "❌ $example_dir missing or empty"
        exit 1
    fi
done

# Check workflows
echo "⚙️  Checking GitHub workflows..."
WORKFLOW_FILES=(
    ".github/workflows/deploy-npm.yml"
    ".github/workflows/deploy-python.yml"
    ".github/workflows/deploy-java.yml"
    ".github/workflows/deploy-php.yml"
    ".github/workflows/deploy-go.yml"
    ".github/workflows/release.yml"
    ".github/workflows/security-scan.yml"
)

for workflow in "${WORKFLOW_FILES[@]}"; do
    if [ -f "$workflow" ]; then
        echo "✅ $workflow exists"
    else
        echo "❌ $workflow missing"
        exit 1
    fi
done

echo ""
echo "🎉 Release validation completed!"
echo ""
echo "✅ All checks passed - ready for release!"
echo ""
if [ -n "$VERSION" ]; then
    echo "🚀 To create release $VERSION:"
    echo "   gh workflow run release.yml -f version=$VERSION"
else
    echo "🚀 To create a release:"
    echo "   ./scripts/bump-version.sh <version>"
    echo "   gh workflow run release.yml -f version=<version>"
fi
echo ""
echo "📋 Pre-release checklist:"
echo "   □ All tests passing"
echo "   □ Documentation updated"
echo "   □ Version numbers consistent"
echo "   □ Secrets configured in GitHub"
echo "   □ Release notes prepared"