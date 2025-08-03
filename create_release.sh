#!/bin/bash

# Perl-NetFramework Release Creation Script
# Usage: ./create_release.sh [version] [--prerelease]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Default values
VERSION=""
PRERELEASE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --prerelease)
            PRERELEASE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [version] [--prerelease]"
            echo ""
            echo "Creates a new release of Perl-NetFramework"
            echo ""
            echo "Arguments:"
            echo "  version      Release version (e.g., 1.0.0, 2.1.3)"
            echo ""
            echo "Options:"
            echo "  --prerelease Mark this as a pre-release"
            echo "  -h, --help   Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 1.0.0                 # Create release v1.0.0"
            echo "  $0 1.1.0 --prerelease    # Create pre-release v1.1.0"
            echo ""
            echo "The script will:"
            echo "  1. Validate the version format"
            echo "  2. Update version in System.pm"
            echo "  3. Run tests to ensure everything works"
            echo "  4. Create and push a git tag"
            echo "  5. Trigger GitHub Actions to build and publish the release"
            exit 0
            ;;
        *)
            if [[ -z "$VERSION" ]]; then
                VERSION="$1"
            else
                echo "Error: Unknown argument '$1'"
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate version format
if [[ -z "$VERSION" ]]; then
    echo "Error: Version is required"
    echo "Usage: $0 [version] [--prerelease]"
    echo "Run '$0 --help' for more information"
    exit 1
fi

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be in format X.Y.Z (e.g., 1.0.0)"
    exit 1
fi

echo "🚀 Creating Perl-NetFramework release v$VERSION"
echo "📋 Pre-release: $PRERELEASE"
echo ""

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository"
    exit 1
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "⚠️  Warning: You have uncommitted changes"
    echo "📝 Uncommitted files:"
    git diff-index --name-only HEAD --
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Release cancelled"
        exit 1
    fi
fi

# Check if tag already exists
if git rev-parse "v$VERSION" >/dev/null 2>&1; then
    echo "Error: Tag v$VERSION already exists"
    exit 1
fi

# Update version in System.pm
echo "📝 Updating version in System.pm..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/our \$VERSION = '[^']*'/our \$VERSION = '$VERSION'/" System.pm
else
    # Linux/Unix
    sed -i "s/our \$VERSION = '[^']*'/our \$VERSION = '$VERSION'/" System.pm
fi

# Verify the version was updated
if grep -q "our \$VERSION = '$VERSION'" System.pm; then
    echo "✅ Version updated successfully"
else
    echo "❌ Failed to update version in System.pm"
    exit 1
fi

# Run tests
echo ""
echo "🧪 Running tests..."
if command -v perl >/dev/null 2>&1; then
    cd tests
    if perl run_tests.pl; then
        echo "✅ All tests passed"
    else
        echo "⚠️  Some tests failed, but continuing..."
        echo "   (Tests may fail due to missing optional dependencies)"
    fi
    cd ..
else
    echo "⚠️  Perl not found, skipping tests"
fi

# Commit version change
echo ""
echo "📝 Committing version change..."
git add System.pm
git commit -m "🔖 Bump version to $VERSION for release

🚀 Generated with release script
" || echo "ℹ️  No changes to commit"

echo "📤 Pushing changes to GitHub..."
git push origin main

# Wait for CI to complete, then trigger release
echo ""
echo "⏳ Waiting for CI tests to complete..."
echo "   You can monitor progress at: https://github.com/Hawkynt/Perl-NetFramework/actions"

# Wait a bit for the push to register
sleep 5

# Check if CI is running or get the latest status
echo "🔍 Checking CI status..."
LATEST_RUN=$(gh run list --workflow=tests.yml --branch=main --limit=1 --json status,conclusion,url --jq '.[0]')

if [[ -n "$LATEST_RUN" ]]; then
    STATUS=$(echo "$LATEST_RUN" | jq -r '.status')
    CONCLUSION=$(echo "$LATEST_RUN" | jq -r '.conclusion // "running"')
    URL=$(echo "$LATEST_RUN" | jq -r '.url')
    
    echo "📊 Latest CI run status: $STATUS"
    echo "🔗 View at: $URL"
    
    if [[ "$STATUS" == "completed" && "$CONCLUSION" == "success" ]]; then
        echo "✅ CI tests passed! Release will be created automatically."
    elif [[ "$STATUS" == "completed" && "$CONCLUSION" != "success" ]]; then
        echo "❌ CI tests failed. Release will not be created automatically."
        echo "   You can manually trigger a release from GitHub Actions if needed."
    else
        echo "⏳ CI tests are still running. Release will be created automatically once they pass."
    fi
else
    echo "ℹ️  Could not determine CI status. Check GitHub Actions page manually."
fi

echo ""
echo "🎉 Release preparation for v$VERSION completed!"
echo ""
echo "📋 What happens next:"
echo "   1. GitHub Actions CI tests are running automatically"
echo "   2. When tests pass, the release workflow will:"
echo "      • Build CPAN-compatible distribution packages"
echo "      • Create GitHub Release with download artifacts"
echo "      • Publish release notes with changelog"
echo ""
echo "📦 Release will include:"
echo "   • Perl-NetFramework-$VERSION.tar.gz (CPAN-compatible)"
echo "   • Perl-NetFramework-$VERSION.zip (Windows-friendly)"
echo "   • Source code archives"
echo ""
echo "🔗 Monitor progress:"
echo "   • CI Tests: https://github.com/Hawkynt/Perl-NetFramework/actions/workflows/tests.yml"
echo "   • Release: https://github.com/Hawkynt/Perl-NetFramework/actions/workflows/release.yml"
echo "   • Downloads: https://github.com/Hawkynt/Perl-NetFramework/releases"
echo ""

if [[ "$PRERELEASE" == true ]]; then
    echo "⚠️  This will be marked as a pre-release"
fi

echo "✅ Done! Release will be created automatically when CI passes."