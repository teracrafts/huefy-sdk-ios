# Huefy SDK CI/CD Documentation

This document describes the GitHub Actions workflows and automation for the Huefy SDK monorepo.

## Workflows Overview

### 🏗️ Main CI Pipeline (`ci.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`
- Manual dispatch

**Features:**
- **Smart Change Detection**: Only tests SDKs that have changed using path filters
- **Parallel Testing**: Runs tests for all SDKs simultaneously
- **Multi-Platform Support**: Tests on different language versions
- **Quality Gates**: Lint, typecheck, security scanning, coverage reporting
- **Integration Tests**: End-to-end testing against live API (when secrets available)

**Matrix Testing:**
- **JavaScript/TypeScript**: Node.js 18
- **Python**: Python 3.8, 3.9, 3.10, 3.11, 3.12
- **Java**: Java 11, 17, 21
- **Go**: Go 1.21
- **PHP**: PHP 8.0, 8.1, 8.2, 8.3

### 🚀 Release Pipeline (`release.yml`)

**Triggers:**
- GitHub releases (publishes all SDKs)
- Manual dispatch (selective SDK publishing)

**Publishing Targets:**
- **JavaScript**: NPM Registry (`@huefy/sdk`)
- **React**: NPM Registry (`@huefy/react`)
- **Python**: PyPI (`huefy`)
- **Go**: GitHub releases + Go proxy via git tags
- **Java**: Maven Central (`dev.huefy:huefy-java-sdk`)
- **PHP**: Packagist (`huefy/huefy-sdk`) via git tags

**Features:**
- **Dry Run Support**: Test publishing without actual deployment
- **Version Synchronization**: Ensures consistent versions across SDKs
- **Dependency Updates**: React SDK automatically updates JavaScript SDK dependency
- **Release Notes**: Automated changelog generation

### 🔒 Security Scanning (`security.yml`)

**Triggers:**
- Daily at 2 AM UTC
- Push to `main`
- Pull requests
- Manual dispatch

**Scans:**
- **Dependency Vulnerabilities**: Trivy scanner for all SDKs
- **NPM Audit**: JavaScript and React packages
- **Python Safety**: Safety and Bandit security analysis
- **Go Security**: gosec and govulncheck
- **Java OWASP**: Dependency vulnerability scanning
- **PHP Security**: Security advisories checking
- **Secret Scanning**: TruffleHog for leaked credentials
- **License Compliance**: Ensures only approved licenses are used

### 📝 Version Management (`version-bump.yml`)

**Triggers:**
- Manual dispatch with version type selection

**Features:**
- **Semantic Versioning**: major, minor, patch, prerelease bumps
- **Custom Versions**: Override with specific version numbers
- **Cross-SDK Sync**: Updates all SDK versions simultaneously
- **Automated Tagging**: Creates git tags and GitHub releases
- **Changelog Generation**: Updates CHANGELOG.md with release notes

### 📋 Changelog Automation (`changelog.yml`)

**Triggers:**
- Push to `main` (excluding changelog commits)
- Manual dispatch

**Features:**
- **Conventional Commits**: Categorizes changes by type (feat, fix, docs, etc.)
- **Automated Sections**: Features, Bug Fixes, Breaking Changes, Documentation
- **Unreleased Changes**: Tracks commits since last release
- **Keep a Changelog Format**: Follows standard changelog format

## Required Secrets

### NPM Publishing
```
NPM_TOKEN - NPM registry authentication token
```

### PyPI Publishing
```
PYPI_TOKEN - PyPI production token
PYPI_TEST_TOKEN - PyPI test repository token
```

### Maven Central Publishing
```
OSSRH_USERNAME - Sonatype OSSRH username
OSSRH_TOKEN - Sonatype OSSRH token
MAVEN_GPG_PRIVATE_KEY - GPG private key for signing
MAVEN_GPG_PASSPHRASE - GPG key passphrase
```

### Integration Testing
```
HUEFY_TEST_API_KEY - Test API key for integration tests
HUEFY_TEST_BASE_URL - Test environment URL
```

## Dependency Management

### Dependabot Configuration
- **Weekly Updates**: Automated dependency updates
- **Staggered Schedule**: Different days for each SDK to avoid conflicts
- **Review Assignment**: Automatic assignment to SDK team
- **Conventional Commits**: Consistent commit message format

### Update Schedule
- **Monday**: JavaScript and React SDKs
- **Tuesday**: Python and Go SDKs
- **Wednesday**: Java and PHP SDKs
- **Thursday**: GitHub Actions

## Best Practices

### Branch Protection
Set up branch protection rules for `main`:
- Require status checks to pass
- Require branches to be up to date
- Require review from code owners
- Restrict pushes to specific teams

### Release Process
1. **Development**: Work on feature branches
2. **Testing**: CI runs on all PRs
3. **Version Bump**: Use version-bump workflow
4. **Release**: Automatic publishing via release workflow
5. **Distribution**: Packages available on all platforms

### Security
- All workflows use pinned action versions
- Secrets are properly scoped and rotated
- Security scans run daily and on all changes
- License compliance is enforced

### Monitoring
- **Coverage Reports**: Uploaded to Codecov
- **Security Reports**: Uploaded to GitHub Security tab
- **Artifacts**: Build artifacts and reports stored
- **Notifications**: Failed builds notify via GitHub

## Troubleshooting

### Common Issues

**Build Failures:**
1. Check if dependencies are up to date
2. Verify environment matrix compatibility
3. Review security scan results
4. Check for breaking changes in dependencies

**Publishing Failures:**
1. Verify all required secrets are set
2. Check package version conflicts
3. Ensure proper authentication tokens
4. Review platform-specific requirements

**Security Scan Failures:**
1. Review vulnerability reports
2. Update affected dependencies
3. Add suppressions for false positives
4. Consider alternative packages

### Debug Mode
Enable debug logging by adding to workflow environment:
```yaml
env:
  ACTIONS_RUNNER_DEBUG: true
  ACTIONS_STEP_DEBUG: true
```

## Contributing

When adding new SDKs or modifying workflows:

1. Update path filters in `ci.yml`
2. Add new SDK to release matrix
3. Configure appropriate dependency scanning
4. Update this documentation
5. Test with dry-run releases

For questions or issues, please contact the Huefy SDK team.