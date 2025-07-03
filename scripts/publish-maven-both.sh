#!/bin/bash

# Publish both Java and Android SDKs to Maven Central Portal
# Usage: ./scripts/publish-maven-both.sh [version]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Maven is installed
    if ! command -v mvn &> /dev/null; then
        print_error "Maven is not installed. Please install Maven first."
        exit 1
    fi
    
    # Check if Gradle is installed (for Android)
    if ! command -v gradle &> /dev/null && ! command -v ./gradlew &> /dev/null; then
        print_error "Gradle is not installed. Please install Gradle first."
        exit 1
    fi
    
    # Check if GPG is installed
    if ! command -v gpg &> /dev/null; then
        print_error "GPG is not installed. Please install GPG first: brew install gnupg"
        exit 1
    fi
    
    # Check if Maven settings.xml exists
    if [ ! -f "$HOME/.m2/settings.xml" ]; then
        print_error "Maven settings.xml not found at ~/.m2/settings.xml"
        print_warning "Please configure Maven settings with OSSRH credentials"
        exit 1
    fi
    
    # Check if GPG key exists
    if ! gpg --list-secret-keys &> /dev/null; then
        print_error "No GPG keys found. Please generate a GPG key first:"
        echo "  gpg --gen-key"
        echo "  gpg --keyserver keyserver.ubuntu.com --send-keys YOUR_KEY_ID"
        exit 1
    fi
    
    print_success "All prerequisites met"
}

# Function to publish Java SDK
publish_java_sdk() {
    local version="${1:-}"
    
    print_status "Publishing Java SDK to Maven Central..."
    
    cd "$PROJECT_ROOT/sdks/java"
    
    # Clean and deploy using the release profile
    print_status "Building and signing Java SDK artifacts..."
    if ! mvn clean deploy -P release -Dmaven.test.skip=true; then
        print_error "Java SDK publishing failed"
        exit 1
    fi
    
    print_success "Java SDK published successfully!"
    echo
    echo "📦 Java SDK Maven dependency:"
    echo "<dependency>"
    echo "    <groupId>com.teracrafts</groupId>"
    echo "    <artifactId>huefy</artifactId>"
    if [ -n "$version" ]; then
        echo "    <version>$version</version>"
    else
        echo "    <version>LATEST</version>"
    fi
    echo "</dependency>"
    echo
}

# Function to publish Android SDK
publish_android_sdk() {
    local version="${1:-}"
    
    print_status "Publishing Android SDK to Maven Central..."
    
    cd "$PROJECT_ROOT/sdks/android"
    
    # Create a temporary POM file for Maven publishing
    print_status "Creating POM file for Android SDK..."
    cat > pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>com.teracrafts</groupId>
    <artifactId>huefy-android</artifactId>
    <version>1.0.1</version>
    <packaging>jar</packaging>
    
    <name>Huefy Android SDK</name>
    <description>Official Android SDK for Huefy email API</description>
    <url>https://github.com/teracrafts/huefy-sdk-android</url>
    
    <licenses>
        <license>
            <name>MIT License</name>
            <url>https://opensource.org/licenses/MIT</url>
        </license>
    </licenses>
    
    <developers>
        <developer>
            <id>teracrafts</id>
            <name>Teracrafts</name>
            <email>support@teracrafts.com</email>
        </developer>
    </developers>
    
    <scm>
        <connection>scm:git:git://github.com/teracrafts/huefy-sdk-android.git</connection>
        <developerConnection>scm:git:ssh://github.com/teracrafts/huefy-sdk-android.git</developerConnection>
        <url>https://github.com/teracrafts/huefy-sdk-android</url>
    </scm>
    
    <distributionManagement>
        <repository>
            <id>central</id>
            <url>https://central.sonatype.com/api/v1/publisher/deployments</url>
        </repository>
    </distributionManagement>
    
    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <kotlin.version>1.9.21</kotlin.version>
    </properties>
    
    <dependencies>
        <dependency>
            <groupId>org.jetbrains.kotlin</groupId>
            <artifactId>kotlin-stdlib</artifactId>
            <version>${kotlin.version}</version>
        </dependency>
        <dependency>
            <groupId>org.jetbrains.kotlinx</groupId>
            <artifactId>kotlinx-coroutines-core</artifactId>
            <version>1.7.3</version>
        </dependency>
        <dependency>
            <groupId>com.squareup.okhttp3</groupId>
            <artifactId>okhttp</artifactId>
            <version>4.12.0</version>
        </dependency>
        <dependency>
            <groupId>com.squareup.moshi</groupId>
            <artifactId>moshi</artifactId>
            <version>1.15.0</version>
        </dependency>
        <dependency>
            <groupId>com.squareup.moshi</groupId>
            <artifactId>moshi-kotlin</artifactId>
            <version>1.15.0</version>
        </dependency>
    </dependencies>
    
    <build>
        <sourceDirectory>src/main/java</sourceDirectory>
        <testSourceDirectory>src/test/java</testSourceDirectory>
        
        <plugins>
            <plugin>
                <groupId>org.jetbrains.kotlin</groupId>
                <artifactId>kotlin-maven-plugin</artifactId>
                <version>${kotlin.version}</version>
                <executions>
                    <execution>
                        <id>compile</id>
                        <phase>compile</phase>
                        <goals>
                            <goal>compile</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
            
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-source-plugin</artifactId>
                <version>3.3.0</version>
                <executions>
                    <execution>
                        <id>attach-sources</id>
                        <goals>
                            <goal>jar-no-fork</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
            
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-javadoc-plugin</artifactId>
                <version>3.5.0</version>
                <configuration>
                    <doclint>none</doclint>
                    <source>11</source>
                    <javadocExecutable>\${java.home}/bin/javadoc</javadocExecutable>
                    <additionalJOptions>
                        <additionalJOption>-Xdoclint:none</additionalJOption>
                        <additionalJOption>-quiet</additionalJOption>
                    </additionalJOptions>
                </configuration>
                <executions>
                    <execution>
                        <id>attach-javadocs</id>
                        <goals>
                            <goal>jar</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
    
    <profiles>
        <profile>
            <id>release</id>
            <build>
                <plugins>
                    <plugin>
                        <groupId>org.apache.maven.plugins</groupId>
                        <artifactId>maven-gpg-plugin</artifactId>
                        <version>3.1.0</version>
                        <executions>
                            <execution>
                                <id>sign-artifacts</id>
                                <phase>verify</phase>
                                <goals>
                                    <goal>sign</goal>
                                </goals>
                            </execution>
                        </executions>
                    </plugin>
                    
                    <plugin>
                        <groupId>org.sonatype.central</groupId>
                        <artifactId>central-publishing-maven-plugin</artifactId>
                        <version>0.4.0</version>
                        <extensions>true</extensions>
                        <configuration>
                            <publishingServerId>central</publishingServerId>
                            <tokenAuth>true</tokenAuth>
                            <autoPublish>true</autoPublish>
                            <waitUntil>uploaded</waitUntil>
                        </configuration>
                    </plugin>
                </plugins>
            </build>
        </profile>
    </profiles>
</project>
EOF
    
    # Build and publish using Maven (same as Java SDK)
    print_status "Building and signing Android SDK artifacts..."
    if ! mvn clean deploy -P release -Dmaven.test.skip=true; then
        print_error "Android SDK publishing failed"
        exit 1
    fi
    
    print_success "Android SDK published successfully!"
    echo
    echo "📦 Android SDK Gradle dependency:"
    echo "implementation(\"com.teracrafts:huefy-android:${version:-LATEST}\")"
    echo
    echo "📦 Android SDK Maven dependency:"
    echo "<dependency>"
    echo "    <groupId>com.teracrafts</groupId>"
    echo "    <artifactId>huefy-android</artifactId>"
    if [ -n "$version" ]; then
        echo "    <version>$version</version>"
    else
        echo "    <version>LATEST</version>"
    fi
    echo "</dependency>"
    echo
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [version]"
    echo
    echo "This script publishes both Java and Android SDKs to Maven Central."
    echo
    echo "Examples:"
    echo "  $0                    # Publish current version"
    echo "  $0 1.0.0              # Publish specific version"
    echo
    echo "Prerequisites:"
    echo "  1. Maven installed"
    echo "  2. Gradle installed"
    echo "  3. GPG installed and key generated"
    echo "  4. ~/.m2/settings.xml configured with OSSRH credentials"
    echo "  5. DNS TXT record verified for com.teracrafts namespace"
    echo
    echo "Published artifacts:"
    echo "  - Java SDK: com.teracrafts:huefy"
    echo "  - Android SDK: com.teracrafts:huefy-android"
    echo
}

# Main function
main() {
    local version="${1:-}"
    
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        show_usage
        exit 0
    fi
    
    print_status "Starting Maven Central publishing process for both Java and Android SDKs..."
    echo
    
    # Run all checks
    check_prerequisites
    
    # Publish both SDKs
    publish_java_sdk "$version"
    publish_android_sdk "$version"
    
    # Final status
    print_success "Both Java and Android SDKs published successfully!"
    echo
    echo "🔍 Check publishing status at: https://central.sonatype.com/"
    echo "📖 Java SDK repository: https://github.com/teracrafts/huefy-sdk-java"
    echo "📖 Android SDK repository: https://github.com/teracrafts/huefy-sdk-android"
    echo
    echo "🎯 Next steps:"
    echo "1. Wait for artifacts to appear in Maven Central (usually 10-30 minutes)"
    echo "2. Update documentation with the new version"
    echo "3. Create GitHub releases for both repositories"
    echo
}

# Run main function with all arguments
main "$@"