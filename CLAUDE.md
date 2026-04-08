# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a GitHub Action that tests Swift packages that depend on `swift-syntax` for compatibility across multiple `swift-syntax` versions. Macro packages are the most common use case, but the action is not limited to macros.

## Architecture

- `action.yml`: GitHub Action definition with inputs for run-tests, major-versions-only, and verbose flags
- `swift-syntax-compatibility-check.sh`: Core bash script that tests against multiple `swift-syntax` versions
- The script tracks stable releases from 509 onward, plus the latest prerelease head for each unreleased major
- Major versions only mode derives one stable representative per major line and still includes prerelease heads

## Development Commands

### Testing the Script Locally
```bash
./swift-syntax-compatibility-check.sh [--run-tests] [--major-versions-only] [--verbose]
```

### Script Workflow
The script performs these steps for each `swift-syntax` version:
1. `swift package resolve swift-syntax --version <version>` - Resolves dependencies for specific version
2. `swift build` - Builds the package
3. `swift test` (if --run-tests flag is used) - Runs tests

### Making the Script Executable
```bash
chmod +x swift-syntax-compatibility-check.sh
```

## Key Implementation Details

- The action requires macOS runners due to Swift toolchain requirements
- Uses Swift 6.1 via swift-actions/setup-swift@v2
- Color-coded output: RED for failures, GREEN for success, BLUE for info, YELLOW for warnings
- Exit code 1 if any compatibility check fails
- Stores results in SUCCEEDED_VERSIONS and FAILED_VERSIONS arrays for final summary
