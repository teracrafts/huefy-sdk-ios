# Java SDK Publishing Guide

This document explains how to publish the Huefy Java SDK to Maven Central using the new Central Publishing Portal.

## Overview

The Java SDK is published to Maven Central under:
- **GroupId**: `com.teracrafts`
- **ArtifactId**: `huefy`
- **Repository**: https://github.com/teracrafts/teracrafts-huefy-sdk-java

## Prerequisites

### 1. Maven Central Portal Account
- ✅ Account created at https://central.sonatype.com/
- ✅ Namespace `com.teracrafts` verified via DNS TXT record
- ✅ Credentials: `k/XyzBcY` / `iAn5cQ3W0D4Qa8uJdQfvixrwmCQxJyMdjC7ElGwp4zbm`

### 2. GPG Key Setup
```bash
# Install GPG
brew install gnupg

# Generate key (if not already done)
gpg --gen-key

# List keys to get KEY_ID
gpg --list-secret-keys --keyid-format LONG

# Upload to keyserver
gpg --keyserver keyserver.ubuntu.com --send-keys YOUR_KEY_ID
```

### 3. Maven Settings
Copy `docs/maven-settings-template.xml` to `~/.m2/settings.xml` and update your GPG passphrase:

```xml
<gpg.passphrase>YOUR_ACTUAL_GPG_PASSPHRASE</gpg.passphrase>
```

## Publishing Methods

### Method 1: Automated Script (Recommended)
```bash
# Publish current version
./scripts/publish-maven-central.sh

# Publish specific version  
./scripts/publish-maven-central.sh 1.0.0-beta.10
```

### Method 2: Manual Maven Commands
```bash
cd sdks/java

# Clean and deploy with release profile
mvn clean deploy -P release
```

### Method 3: Deploy from Dedicated Repository
```bash
# Clone the Java-only repository
git clone git@github.com:teracrafts/teracrafts-huefy-sdk-java.git
cd teracrafts-huefy-sdk-java

# Deploy
mvn clean deploy -P release
```

## Release Process

### 1. Update Version
Update version in `sdks/java/pom.xml`:
```xml
<version>1.0.0-beta.10</version>
```

### 2. Deploy to Standalone Repository
```bash
# From monorepo root
./scripts/deploy-java-subtree.sh 1.0.0-beta.10
```

### 3. Publish to Maven Central
```bash
./scripts/publish-maven-central.sh 1.0.0-beta.10
```

### 4. Verify Publication
- Check https://central.sonatype.com/ for deployment status
- Search https://search.maven.org/ for the published artifact
- Test installation in a new project

## Usage by Developers

Once published, developers can use the SDK:

### Maven
```xml
<dependency>
    <groupId>com.teracrafts</groupId>
    <artifactId>huefy</artifactId>
    <version>1.0.0-beta.10</version>
</dependency>
```

### Gradle
```gradle
implementation 'com.teracrafts:huefy:1.0.0-beta.10'
```

## Troubleshooting

### Common Issues

**GPG Signing Fails**
```bash
# Check GPG keys
gpg --list-secret-keys

# Test signing
echo "test" | gpg --clearsign
```

**Authentication Fails**
- Verify credentials in `~/.m2/settings.xml`
- Ensure DNS TXT record is still active
- Check Central Portal account status

**Build Fails**
```bash
# Clean and retry
mvn clean
mvn compile
mvn test
```

**Plugin Version Issues**
- Ensure using latest Central Publishing plugin version
- Check Maven version compatibility

### Support Resources

- **Central Portal Docs**: https://central.sonatype.org/
- **Maven Central Search**: https://search.maven.org/
- **GPG Documentation**: https://gnupg.org/documentation/
- **Project Issues**: https://github.com/teracrafts/teracrafts-huefy-sdk-java/issues

## Security Notes

- Never commit `settings.xml` or GPG keys to version control
- Store credentials securely
- Rotate credentials regularly
- Use environment variables in CI/CD pipelines

## Automation

The publishing process can be automated via GitHub Actions:

```yaml
name: Publish to Maven Central
on:
  push:
    tags: ['java-v*']
  
jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up JDK 11
        uses: actions/setup-java@v3
        with:
          java-version: 11
          distribution: 'temurin'
      - name: Import GPG key
        uses: crazy-max/ghaction-import-gpg@v5
        with:
          gpg_private_key: ${{ secrets.GPG_PRIVATE_KEY }}
          passphrase: ${{ secrets.GPG_PASSPHRASE }}
      - name: Publish to Central Portal
        run: mvn clean deploy -P release
        env:
          MAVEN_CENTRAL_USERNAME: ${{ secrets.MAVEN_CENTRAL_USERNAME }}
          MAVEN_CENTRAL_PASSWORD: ${{ secrets.MAVEN_CENTRAL_PASSWORD }}
```