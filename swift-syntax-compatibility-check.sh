#!/bin/bash

# Swift Syntax Compatibility Check Script
# Usage:
# ./swift-syntax-compatibility-check.sh [--run-tests] [--major-versions-only] [--include-prereleases] [--from-version <version>] [--verbose]

# Default input values
RUN_TESTS=false
MAJOR_VERSIONS_ONLY=false
INCLUDE_PRERELEASES=false
FROM_VERSION=""
VERBOSE=false
FAILURE_OCCURRED=false

# Validate version format (e.g. 510.0.0 or 604.0.0-prerelease-2026-03-31)
function is_valid_version() {
  local v="$1"
  [[ "$v" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-prerelease-[0-9]{4}-[0-9]{2}-[0-9]{2})?$ ]]
}

function is_prerelease_version() {
  [[ "$1" == *-prerelease-* ]]
}

function version_core() {
  printf '%s\n' "${1%%-prerelease-*}"
}

function version_major() {
  local core
  core="$(version_core "$1")"
  printf '%s\n' "${core%%.*}"
}

function prerelease_date_key() {
  if ! is_prerelease_version "$1"; then
    printf '\n'
    return
  fi

  local date="${1##*-prerelease-}"
  printf '%s\n' "${date//-/}"
}

# Returns success if $1 >= $2 for stable and prerelease swift-syntax tags.
function version_ge() {
  local a="$1"
  local b="$2"

  local a_core b_core
  a_core="$(version_core "$a")"
  b_core="$(version_core "$b")"

  local a1 a2 a3 b1 b2 b3
  IFS='.' read -r a1 a2 a3 <<< "$a_core"
  IFS='.' read -r b1 b2 b3 <<< "$b_core"

  if (( a1 != b1 )); then
    (( a1 > b1 ))
    return
  fi
  if (( a2 != b2 )); then
    (( a2 > b2 ))
    return
  fi
  if (( a3 != b3 )); then
    (( a3 > b3 ))
    return
  fi

  local a_is_prerelease=false
  local b_is_prerelease=false
  if is_prerelease_version "$a"; then
    a_is_prerelease=true
  fi
  if is_prerelease_version "$b"; then
    b_is_prerelease=true
  fi

  if [ "$a_is_prerelease" = "$b_is_prerelease" ]; then
    if [ "$a_is_prerelease" = false ]; then
      return 0
    fi

    local a_date b_date
    a_date="$(prerelease_date_key "$a")"
    b_date="$(prerelease_date_key "$b")"
    [[ "$a_date" > "$b_date" || "$a_date" = "$b_date" ]]
    return
  fi

  if [ "$a_is_prerelease" = false ]; then
    return 0
  fi

  return 1
}

function build_major_stable_versions() {
  MAJOR_STABLE_VERSIONS=()

  local current_major=""
  local version major
  for version in "${STABLE_VERSIONS[@]}"; do
    major="$(version_major "$version")"
    if [ "$major" != "$current_major" ]; then
      MAJOR_STABLE_VERSIONS+=("$version")
      current_major="$major"
    fi
  done
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --run-tests) RUN_TESTS=true ;;
        --major-versions-only) MAJOR_VERSIONS_ONLY=true ;;
        --include-prereleases) INCLUDE_PRERELEASES=true ;;
        --from-version)
          shift
          if [ -z "${1:-}" ]; then
            echo "Missing value for --from-version (expected e.g. 510.0.0 or 604.0.0-prerelease-2026-03-31)" >&2
            exit 2
          fi
          FROM_VERSION="$1"
          ;;
        --verbose) VERBOSE=true ;;
        *) echo "Unknown parameter: $1" ;;
    esac
    shift
done

# Stable swift-syntax versions to check.
STABLE_VERSIONS=(
  "509.0.0"
  "509.0.1"
  "509.0.2"
  "509.1.0"
  "509.1.1"
  "510.0.0"
  "510.0.1"
  "510.0.2"
  "510.0.3"
  "600.0.0"
  "600.0.1"
  "601.0.1"
  "602.0.0"
  "603.0.0"
)

# Latest prerelease head for each unreleased major. These are opt-in because
# most packages' normal dependency ranges do not admit prerelease versions.
PRERELEASE_VERSIONS=(
  "604.0.0-prerelease-2026-03-31"
)

build_major_stable_versions

# Choose which versions to use based on input.
if [ "$MAJOR_VERSIONS_ONLY" = true ]; then
  VERSIONS=("${MAJOR_STABLE_VERSIONS[@]}")
else
  VERSIONS=("${STABLE_VERSIONS[@]}")
fi

if [ "$INCLUDE_PRERELEASES" = true ]; then
  VERSIONS=("${VERSIONS[@]}" "${PRERELEASE_VERSIONS[@]}")
fi

if [ -n "$FROM_VERSION" ]; then
  if ! is_valid_version "$FROM_VERSION"; then
    echo "Invalid --from-version '$FROM_VERSION' (expected format: 510.0.0 or 604.0.0-prerelease-2026-03-31)" >&2
    exit 2
  fi

  if is_prerelease_version "$FROM_VERSION" && [ "$INCLUDE_PRERELEASES" != true ]; then
    echo "Prerelease from-version '$FROM_VERSION' requires --include-prereleases" >&2
    exit 2
  fi

  FILTERED_VERSIONS=()
  for version in "${VERSIONS[@]}"; do
    if version_ge "$version" "$FROM_VERSION"; then
      FILTERED_VERSIONS+=("$version")
    fi
  done

  if [ ${#FILTERED_VERSIONS[@]} -eq 0 ]; then
    echo "No swift-syntax versions to check (from-version '$FROM_VERSION' is newer than all selected versions)" >&2
    exit 2
  fi
  VERSIONS=("${FILTERED_VERSIONS[@]}")
fi

# Set verbosity flag
VERBOSE_FLAG=""
if [ "$VERBOSE" = true ]; then
  VERBOSE_FLAG="-v"
fi

# Resolve package dependencies
swift package resolve

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Arrays to store results
SUCCEEDED_VERSIONS=()
FAILED_VERSIONS=()

# Function to create a box around text
function print_boxed_text() {
  local text="$1"
  local text_length=${#text}
  local border=$(printf '%*s' "$((text_length + 4))" | tr ' ' '-')

  echo -e "${BLUE}$border${NC}"
  echo -e "${BLUE}| ${NC}${BLUE}$text${NC} ${BLUE}|${NC}"
  echo -e "${BLUE}$border${NC}"
}

# Loop over each SwiftSyntax version and check compatibility
for version in "${VERSIONS[@]}"; do
  VERSION_SUCCEEDED=false
  print_boxed_text "Checking compatibility with swift-syntax version $version"
  
  # Explain the resolve process
  echo -e "${BLUE}Resolving swift-syntax version $version and updating dependencies...${NC}"
  if swift package resolve swift-syntax --version "$version"; then
    echo -e "${GREEN}Resolved swift-syntax version $version successfully${NC}"
  else
    echo -e "${RED}Failed to resolve swift-syntax version $version${NC}"
    FAILED_VERSIONS+=("$version (Resolve Failed)")
    FAILURE_OCCURRED=true
    continue
  fi

  # Build the package
  echo -e "${BLUE}Building package with swift-syntax $version${NC}"
  if swift build $VERBOSE_FLAG; then
    echo -e "${GREEN}Build succeeded for swift-syntax $version${NC}"
    
    # Run tests if specified
    if [ "$RUN_TESTS" = true ]; then
      echo -e "${BLUE}Running tests with swift-syntax $version${NC}"
      if swift test $VERBOSE_FLAG; then
        echo -e "${GREEN}Tests passed for swift-syntax $version${NC}"
        SUCCEEDED_VERSIONS+=("$version")
        VERSION_SUCCEEDED=true
      else
        echo -e "${RED}Tests failed for swift-syntax $version${NC}"
        FAILED_VERSIONS+=("$version (Tests Failed)")
        FAILURE_OCCURRED=true
      fi
    else
      echo -e "${YELLOW}Skipping tests as per configuration${NC}"
      SUCCEEDED_VERSIONS+=("$version")
      VERSION_SUCCEEDED=true
    fi
  else
    echo -e "${RED}Build failed for swift-syntax $version${NC}"
    FAILED_VERSIONS+=("$version (Build Failed)")
    FAILURE_OCCURRED=true
  fi

  # Conditional success/failure message
  if [ "$VERSION_SUCCEEDED" = true ]; then
    echo -e "${GREEN}Compatibility check complete for swift-syntax $version${NC}"
  else
    echo -e "${RED}Compatibility check failed for swift-syntax $version${NC}"
  fi
done

# Summary of results
print_boxed_text "Compatibility Check Summary"

if [ ${#SUCCEEDED_VERSIONS[@]} -ne 0 ]; then
  echo -e "${GREEN}Succeeded for versions:${NC}"
  for v in "${SUCCEEDED_VERSIONS[@]}"; do
    echo -e "${GREEN}  - $v${NC}"
  done
else
  echo -e "${RED}No versions succeeded${NC}"
fi

if [ ${#FAILED_VERSIONS[@]} -ne 0 ]; then
  echo -e "${RED}Failed for versions:${NC}"
  for v in "${FAILED_VERSIONS[@]}"; do
    echo -e "${RED}  - $v${NC}"
  done
else
  echo -e "${GREEN}No versions failed${NC}"
fi

# Fail the script if any check failed
if [ "$FAILURE_OCCURRED" = true ]; then
  exit 1
fi
