# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the Huefy SDK repository - a multi-language SDK monorepo for sending emails via the Huefy email API. The project uses a hybrid approach combining OpenAPI generation with hand-crafted idiomatic wrappers for each target language.

**Target Languages**: JavaScript/TypeScript, React, Go, Java, Python, PHP
**API Endpoint**: `/api/v1/sdk/emails/send` 
**Approach**: MVP first, iterative enhancement

## Development Commands

### Project Setup
```bash
# Install OpenAPI Generator CLI (required for SDK generation)
npm install @openapitools/openapi-generator-cli -g

# Set up individual SDK dependencies
cd sdks/javascript && npm install
cd sdks/react && npm install
cd sdks/go && go mod tidy
cd sdks/java && mvn install
cd sdks/python && pip install -e .
cd sdks/php && composer install
```

### SDK Generation
```bash
# Generate all SDKs from OpenAPI spec
./scripts/generate-sdks.sh

# Generate specific language SDK
./scripts/generate-sdk.sh javascript
./scripts/generate-sdk.sh go
```

### Building & Testing
```bash
# Build all SDKs
./scripts/build-all.sh

# Test all SDKs
./scripts/test-all.sh

# Build/test specific SDK
cd sdks/javascript && npm run build && npm test
cd sdks/go && go build && go test
cd sdks/java && mvn package
cd sdks/python && python -m pytest
cd sdks/php && composer test
```

### Publishing
```bash
# Publish all SDKs to their respective registries
./scripts/publish-all.sh

# Publish specific SDK
cd sdks/javascript && npm publish
cd sdks/go && git tag v1.0.0 && git push --tags
cd sdks/java && mvn deploy
cd sdks/python && python -m build && twine upload dist/*
cd sdks/php && # Auto-published via Packagist webhook
```

### Task Automation (Recommended)

The project includes a [Taskfile](https://taskfile.dev) for modern task automation. Install Task CLI and use these convenient commands:

```bash
# Install Task (one-time setup)
go install github.com/go-task/task/v3/cmd/task@latest
# Or via package manager: brew install go-task/tap/go-task

# Development workflow
task setup           # Set up development environment
task build            # Build all SDKs
task test             # Run tests for all SDKs
task clean            # Clean build artifacts

# Release workflow
task validate                    # Validate release readiness
task bump-version VERSION=1.2.0 # Bump versions across all SDKs
task release VERSION=1.2.0      # Complete release workflow

# Individual SDK tasks
task build-js         # Build JavaScript SDK only
task test-python      # Test Python SDK only
task publish-dry-run  # Dry run publishing

# Utility tasks
task status           # Show project status
task security-scan    # Run security scans
task docs            # Generate documentation
```

### Release Options

The project supports both **automated** and **manual** release workflows:

#### Option 1: Automated Release (GitHub Actions)
```bash
# Trigger automated release via GitHub Actions
gh workflow run release.yml -f version=1.2.0
```

#### Option 2: Manual Release (Taskfile)
```bash
# Complete manual release workflow
task release VERSION=1.2.0
```

#### Option 3: Manual Release (Scripts Only)
```bash
# Step-by-step manual release
./scripts/validate-release.sh 1.2.0
./scripts/bump-version.sh 1.2.0
./scripts/build-all.sh
./scripts/test-all.sh
./scripts/publish-all.sh
```

## Architecture

### Monorepo Structure
```
huefy-sdk/
├── core/                   # Shared core logic and specifications
│   ├── openapi/           # OpenAPI specification and generator
│   └── config/            # Generator configurations per language
├── generated/             # Auto-generated base SDKs (git-ignored)
├── sdks/                  # Hand-crafted idiomatic wrappers
│   ├── javascript/        # Node.js/Browser SDK
│   ├── react/            # React hooks and providers
│   ├── go/               # Go SDK
│   ├── java/             # Java SDK
│   ├── python/           # Python SDK
│   └── php/              # PHP SDK
├── examples/             # Usage examples per language
├── docs/                 # Documentation
└── scripts/              # Build and generation scripts
```

### SDK Design Patterns

**Core API Pattern** (consistent across all languages):
```typescript
// Configuration
const client = new HuefyClient({ 
  apiKey: 'your-api-key',
  baseUrl?: 'custom-url' 
});

// Send email (SES default provider)
await client.sendEmail('template-key', { name: 'John' }, 'user@example.com');

// Send email (custom provider)
await client.sendEmail('template-key', data, email, { provider: 'sendgrid' });
```

**Error Handling**: All SDKs implement consistent error handling with:
- Network errors (timeouts, connection issues)
- API errors (4xx/5xx responses)
- Validation errors (invalid parameters)
- Retry logic (3 attempts with exponential backoff)

**Type Safety**: TypeScript, Go, and Java SDKs provide full type safety for:
- Request/response schemas
- Provider enum values
- Configuration options
- Error types

### Key Components

1. **OpenAPI Generator**: Generates base SDKs from `core/openapi/openapi.yaml`
2. **Idiomatic Wrappers**: Language-specific implementations in `sdks/` folders
3. **Configuration System**: Per-language generator configs in `core/config/`
4. **Testing Framework**: Unit and integration tests for each SDK
5. **Publishing Pipeline**: Automated publishing to package registries

### Integration Guidelines

**Adding New Languages**:
1. Add generator config in `core/config/generators/{language}.yaml`
2. Update `scripts/generate-sdks.sh` to include new language
3. Create SDK wrapper in `sdks/{language}/`
4. Add examples in `examples/{language}/`
5. Update publishing scripts

**API Changes**:
1. Update `core/openapi/openapi.yaml`
2. Run `./scripts/generate-sdks.sh` to regenerate base SDKs
3. Update idiomatic wrappers if needed
4. Update examples and documentation
5. Increment version numbers

**Testing Strategy**:
- Unit tests: Test SDK logic in isolation
- Integration tests: Test against live Huefy API
- Example tests: Ensure examples work correctly
- Cross-SDK tests: Verify consistent behavior

## Important Notes

- **Provider Default**: SES is the default email provider across all SDKs
- **Authentication**: All SDKs use `X-API-Key` header authentication
- **Versioning**: Follow semantic versioning for all packages
- **Documentation**: Update `IMPLEMENTATION.md` to track progress
- **Publishing**: Never publish to production registries from local development

## Troubleshooting

**OpenAPI Generation Issues**:
- Ensure `@openapitools/openapi-generator-cli` is installed
- Check `core/openapi/openapi.yaml` is valid
- Verify generator configs in `core/config/generators/`

**Build Failures**:
- Check language-specific dependencies are installed
- Verify API endpoint `/api/v1/sdk/emails/send` is accessible
- Review error logs in individual SDK directories

**Testing Issues**:
- Ensure valid API key is available in test environment
- Check that test email addresses are not blacklisted
- Verify all required test dependencies are installed

**Task Automation Issues**:
- Install Task CLI: `go install github.com/go-task/task/v3/cmd/task@latest`
- Verify Taskfile.yml syntax: `task --dry`
- Check script permissions: `chmod +x scripts/*.sh`
- For Windows: Use WSL, Git Bash, or PowerShell with Task

**Publishing Issues**:
- Verify credentials are configured (NPM_TOKEN, PYPI credentials, etc.)
- Check network connectivity to package registries
- Use `task publish-dry-run` to test before actual publishing
- Ensure version numbers follow semantic versioning

**Manual Release Issues**:
- Run `task validate` before attempting release
- Check git working directory is clean
- Verify you're on the main branch
- Ensure all tests pass with `task test`