#!/bin/bash
set -e

# Create workspace directories if they don't exist
echo "Setting up workspace directories..."

# Create .ccache directory if it doesn't exist
if [ ! -d "/workspace/.ccache" ]; then
    echo "Creating /workspace/.ccache"
    mkdir -p /workspace/.ccache
else
    echo "/workspace/.ccache already exists, skipping"
fi

# Create .aws directory if it doesn't exist
if [ ! -d "/workspace/.aws" ]; then
    echo "Creating /workspace/.aws"
    mkdir -p /workspace/.aws
else
    echo "/workspace/.aws already exists, skipping"
fi

# Create .config/gh directory if it doesn't exist
if [ ! -d "/workspace/.config/gh" ]; then
    echo "Creating /workspace/.config/gh"
    mkdir -p /workspace/.config/gh
else
    echo "/workspace/.config/gh already exists, skipping"
fi

# Create .claude directory if it doesn't exist
if [ ! -d "/workspace/.claude" ]; then
    echo "Creating /workspace/.claude"
    mkdir -p /workspace/.claude
else
    echo "/workspace/.claude already exists, skipping"
fi

echo "Workspace preparation complete!"
echo ""
echo "You can now run the container with:"
echo "docker run -it --rm -v \$(pwd):/src -v /workspace:/workspace ghcr.io/your-repo/kernel-build-containers:latest"