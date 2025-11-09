#!/bin/bash
set -e  # Exit on error
set -x  # Echo commands to console

echo "Installing Bun..."

# Ensure unzip is available (required for bun installation)
if ! command -v unzip &> /dev/null; then
    echo "Installing unzip..."
    sudo apt-get update && sudo apt-get install -y unzip
fi

# Install Bun
curl -fsSL https://bun.sh/install | bash

# Add Bun to PATH for current session
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Add Bun to PATH permanently
if ! grep -q "BUN_INSTALL" ~/.bashrc 2>/dev/null; then
    echo 'export BUN_INSTALL="$HOME/.bun"' >> ~/.bashrc
    echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> ~/.bashrc
fi

echo "Bun installation complete"

echo "Installing MoonBit..."

# Try the original installation script first
if curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash; then
    echo "MoonBit installed successfully using standard installer"
else
    echo "Standard installer failed, trying WASM-based installer..."
    curl -fsSL https://raw.githubusercontent.com/moonbitlang/moonbit-compiler/refs/heads/main/install.ts | node
    echo "MoonBit installed successfully using WASM-based installer"
fi

echo "MoonBit installation complete"

echo "Verifying/Installing GraalVM..."

# Check if GraalVM is already installed (from the feature)
if command -v java &> /dev/null && java -version 2>&1 | grep -qi "graalvm"; then
    echo "GraalVM is already installed via devcontainer feature"
    java -version
else
    echo "GraalVM not found via feature, installing manually..."
    
    # Install GraalVM Community Edition (latest JDK 21)
    GRAALVM_VERSION="23.1.0"
    GRAALVM_JDK_VERSION="21"
    
    # Detect architecture
    ARCH=$(uname -m)
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        GRAALVM_ARCH="aarch64"
    else
        GRAALVM_ARCH="amd64"
    fi
    
    # Download and install GraalVM
    cd /tmp
    GRAALVM_TAR="graalvm-ce-java${GRAALVM_JDK_VERSION}-linux-${GRAALVM_ARCH}-${GRAALVM_VERSION}.tar.gz"
    GRAALVM_URL="https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-${GRAALVM_VERSION}/${GRAALVM_TAR}"
    
    # Download using wget or curl
    if command -v wget &> /dev/null; then
        wget -q "${GRAALVM_URL}"
    elif command -v curl &> /dev/null; then
        curl -L -o "${GRAALVM_TAR}" "${GRAALVM_URL}"
    else
        echo "Error: Neither wget nor curl is available. Cannot download GraalVM."
        exit 1
    fi
    
    if [ -f "${GRAALVM_TAR}" ]; then
        tar -xzf "${GRAALVM_TAR}"
        sudo mv graalvm-ce-java${GRAALVM_JDK_VERSION}-${GRAALVM_VERSION} /usr/lib/graalvm
        
        # Set up environment variables
        export JAVA_HOME=/usr/lib/graalvm
        export PATH=$JAVA_HOME/bin:$PATH
        
        # Add to bashrc if not already present
        if ! grep -q "JAVA_HOME=/usr/lib/graalvm" ~/.bashrc 2>/dev/null; then
            echo 'export JAVA_HOME=/usr/lib/graalvm' >> ~/.bashrc
            echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
        fi
        
        # Create symlinks
        sudo update-alternatives --install /usr/bin/java java /usr/lib/graalvm/bin/java 1
        sudo update-alternatives --install /usr/bin/javac javac /usr/lib/graalvm/bin/javac 1
        
        echo "GraalVM installed successfully"
        java -version
    else
        echo "Warning: Could not download GraalVM. Please install manually."
    fi
fi

echo "Java/GraalVM setup complete"


