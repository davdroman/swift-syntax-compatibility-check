# Swift Syntax Compatibility Check

This GitHub Action verifies compatibility of a Swift package that depends on `swift-syntax` against multiple `swift-syntax` versions.

## Motivation

As pointed out by Point-Free in their article [Being a good citizen in the land of SwiftSyntax](https://www.pointfree.co/blog/posts/116-being-a-good-citizen-in-the-land-of-swiftsyntax), adopting `swift-syntax` comes with a few recurring challenges:

1. **Versioning Complexity**: `swift-syntax` uses a versioning scheme where major versions correspond to minor versions of Swift (e.g., SwiftSyntax 509.0 corresponds to Swift 5.9). This complicates dependency management.

1. **Breaking Changes**: `swift-syntax` has had breaking changes in minor releases, which causes compatibility issues.

1. **Dependency Resolution**: With more libraries depending on `swift-syntax`, there's an increased likelihood of unresolvable dependency graphs due to multiple libraries needing different major versions of the package.

This action aims to address these challenges by:

- Ensuring your package stays compatible with multiple versions of `swift-syntax`.
- Allowing you to easily test against both major versions and all minor versions.
- Helping you catch potential compatibility issues early in your development process.

Macros are the most common use case, but the action itself is not macro-specific. Any SwiftPM package with a `swift-syntax` dependency can use it.

By using this action, you're taking a step towards being a **good citizen in the Swift ecosystem**, helping to prevent dependency conflicts and ensuring your library works across a range of `swift-syntax` versions.

## Usage

To use this action in your workflow, add the following step:

```yaml
- name: Run Swift Syntax Compatibility Check
  uses: davdroman/swift-syntax-compatibility-check@main
```

> [!IMPORTANT]
> Make sure to run this action on a macOS runner:

```yaml
jobs:
  check-swift-syntax-compatibility:
    runs-on: macos-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      - name: Run Swift Syntax Compatibility Check
        uses: davdroman/swift-syntax-compatibility-check@main
```

## Inputs

| Input                 | Description                                                   | Required | Default |
|-----------------------|---------------------------------------------------------------|----------|---------|
| `run-tests`           | Whether to run tests (true/false)                             | false    | false   |
| `major-versions-only` | Whether to test only against major versions (true/false)      | false    | false   |
| `from-version`        | Check starting from this `swift-syntax` version (e.g. 510.0.0) | false    |         |
| `verbose`             | Whether to use verbose output for Swift commands (true/false) | false    | false   |

## `swift-syntax` Versions

The action tests against the following `swift-syntax` versions:

- `509.0.0`
- `509.0.1`
- `509.0.2`
- `509.1.0`
- `509.1.1`
- `510.0.0`
- `510.0.1`
- `510.0.2`
- `510.0.3`
- `600.0.0`
- `600.0.1`
<!--- `601.0.0`-->
- `601.0.1`
- `602.0.0`
- `603.0.0`

When `major-versions-only` is set to `true`, only versions `509.0.0`, `510.0.0`, `600.0.0`, `601.0.1`, `602.0.0`, and `603.0.0` are tested.

When `from-version` is set, versions older than it are skipped (after applying `major-versions-only`, if enabled).

## Running the Script Locally

If you'd like to run the compatibility check script locally without GitHub Actions, you can do so by executing the provided bash script [`swift-syntax-compatibility-check.sh`](swift-syntax-compatibility-check.sh) in your terminal.

### Usage

```bash
./swift-syntax-compatibility-check.sh [--run-tests] [--major-versions-only] [--from-version <version>] [--verbose]
```

### Script Overview

The script checks the compatibility of a Swift package with multiple versions of `swift-syntax`. It can be configured to run tests and provide verbose output. The script performs the following steps for each version of `swift-syntax`:

1. Resolves package dependencies for the specific `swift-syntax` version.
2. Builds the Swift package.
3. Optionally runs tests.
4. Outputs a summary indicating which versions succeeded and which failed.

## Examples

### Basic Usage in GitHub Actions

```yaml
name: Swift Syntax Compatibility

on: [push, pull_request]

jobs:
  check-compatibility:
    runs-on: macos-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      - name: Run Swift Syntax Compatibility Check
        uses: davdroman/swift-syntax-compatibility-check@main
```

### With All Options

```yaml
name: Swift Syntax Compatibility

on: [push, pull_request]

jobs:
  check-compatibility:
    runs-on: macos-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      - name: Run Swift Syntax Compatibility Check
        uses: davdroman/swift-syntax-compatibility-check@main
        with:
          run-tests: 'true'
          major-versions-only: 'false'
          from-version: '510.0.0'
          verbose: 'true'
```

## Contributing

Contributions to improve the action or script are welcome. Please feel free to submit issues or pull requests.

## License

This GitHub Action and the associated script are released under the [MIT License](LICENSE).
