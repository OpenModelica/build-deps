# fmusim

[![CI][ci-badge]][ci] [![codecov][codecov-badge]][codecov] [![docs][docs-badge]][docs]

`fmusim` is a command-line tool for working with [Functional Mock-up Units
(FMUs)][fmi]. It can:

- **`info`** — print a summary of an FMU (FMI version, interfaces, variables, …)
- **`validate`** — check an FMU against the FMI schema and consistency rules
- **`simulate`** — run an FMU (FMI 2.0 / 3.0, Co-Simulation or Model Exchange)

It supports CSV inputs, CSV/plot outputs, fixed-step and CVODE solvers, and
reading a whole run from a TOML config file.

API documentation (rustdoc) is published to [GitHub Pages][docs].

## Installation

### Download a prebuilt binary (recommended)

Grab the archive for your platform from the [latest release][releases], extract
it, and put `fmusim` somewhere on your `PATH`. Each archive also contains a
`fmusim-debug` build and the `LICENSE`/`README.md`.

```bash
# Linux / macOS — set VERSION and the platform to match the asset you want
VERSION=v0.1.0
PLATFORM=linux-x86_64                 # or macos-aarch64
curl -L -o fmusim.tar.gz \
  "https://github.com/AnHeuermann/fmusim-rust/releases/download/${VERSION}/fmusim-${VERSION}-${PLATFORM}.tar.gz"
tar -xzf fmusim.tar.gz
sudo install "fmusim-${VERSION}-${PLATFORM}/fmusim" /usr/local/bin/
fmusim --help
```

On Windows download the `…-windows-x86_64.zip`, extract it, and add the folder to
your `PATH`.

### Install with `cargo`

```bash
cargo install --git https://github.com/AnHeuermann/fmusim-rust --locked fmusim
```

This compiles from source, so you need the [build prerequisites](#prerequisites)
(a C/C++ compiler, CMake and curl) — the first build downloads and builds libxml2
and SUNDIALS/CVODE.

### Build from source

See [Building](#building) below.

## Usage

```text
Usage: fmusim <COMMAND>

Commands:
  info             Display information about an FMU
  validate         Validate an FMU
  simulate         Simulate an FMU
  simulate-config  Simulate an FMU using a configuration file
  help             Print this message or the help of the given subcommand(s)
```

Run `fmusim help <command>` (or `fmusim <command> --help`) for the full list of
options.

### Examples

Inspect and validate an FMU:

```bash
fmusim info BouncingBall.fmu
fmusim validate BouncingBall.fmu
```

Simulate with a stop time and sample the outputs every 0.1 s, writing a CSV:

```bash
fmusim simulate BouncingBall.fmu \
  --stop-time 3 \
  --output-interval 0.1 \
  --output-file result.csv
```

Override start values and select which variables to record:

```bash
fmusim simulate BouncingBall.fmu \
  --start-value h=1.5 \
  --start-value e=0.7 \
  --output-variable h \
  --output-variable v
```

Drive the simulation from a CSV input file and show a plot of the results:

```bash
fmusim simulate Feedthrough.fmu --input-file input.csv --show-plot
```

Pick the interface and the Model Exchange solver explicitly:

```bash
# Co-Simulation
fmusim simulate model.fmu --interface-type cs

# Model Exchange with the fixed-step forward-Euler solver
fmusim simulate model.fmu --interface-type me --solver euler --fixed-step-size 1e-3
```

Reproduce a run from a TOML config (same options as `simulate`):

```bash
fmusim simulate-config run.toml
```

```toml
# run.toml
fmu_file = "BouncingBall.fmu"
stop_time = 3.0
output_interval = 0.1
start_values = [["h", "1.5"], ["e", "0.7"]]
```

### Shell completions

`fmusim` uses *dynamic* completion (the binary computes candidates on Tab; the
`fmu_file` argument completes only directories and `*.fmu` files). Register it in
your shell startup file — the line makes the shell call `fmusim` back:

```bash
source <(COMPLETE=zsh fmusim)    # zsh; use COMPLETE=bash / COMPLETE=fish likewise
```

It relies on `clap_complete`'s `unstable-dynamic` feature, so the `fmusim` on your
`PATH` must be the one that computes the candidates.

## Repository layout

A single Cargo workspace — see each crate's `README.md` for details:

| Crate          | Purpose                                                   |
|----------------|-----------------------------------------------------------|
| `fmusim`       | the command-line application (this binary)                |
| `fmi-rs`       | FMI model description, import and simulation library      |
| `fmi-rs-cvode` | SUNDIALS/CVODE solver bindings (builds CVODE from source) |
| `fmi-rs-xsd`   | libxml2-based XSD validation (builds libxml2 from source) |

## Building

The `fmi-rs-cvode` and `fmi-rs-xsd` build scripts **download and build
SUNDIALS/CVODE and libxml2 from source on the first build** into a per-target
`vendor/` directory, so the first build needs network access and takes a few
minutes; later builds reuse the cached static libraries.

### Prerequisites

A Rust toolchain (edition 2024, Rust 1.85+) via [rustup][rustup], plus a C/C++
compiler, **CMake** and **curl** (used by the build scripts). flex/bison are
*not* needed — the generated parser sources are checked in.

- **Linux:** `sudo apt-get install build-essential cmake curl` (or the dnf equivalent).
- **macOS:** `xcode-select --install` and `brew install cmake` (curl ships with macOS).
- **Windows:** Visual Studio Build Tools ("Desktop development with C++", giving
  MSVC, `cl.exe`, `nmake`) and [CMake][cmake-download]. Build from a *Developer
  Command Prompt for VS* so `cl`/`nmake` are on `PATH`.

### Build & run

```bash
cargo build --release            # binary at target/release/fmusim
./target/release/fmusim --help
```

## Testing

The `fmusim` integration tests run the binary against the `Feedthrough` Reference
FMU for FMI 2.0 and 3.0. Those `.fmu` files are not checked in; download the
prebuilt [Reference FMUs][ref-fmus-releases] and copy them into place:

```bash
REF_FMUS_VERSION=0.0.39
curl -L -o reference-fmus.zip \
  "https://github.com/modelica/Reference-FMUs/releases/download/v${REF_FMUS_VERSION}/Reference-FMUs-${REF_FMUS_VERSION}.zip"
cmake -E tar xf reference-fmus.zip
mkdir -p fmusim/tests/resources/Reference-FMUs/2.0 fmusim/tests/resources/Reference-FMUs/3.0
cp 2.0/Feedthrough.fmu fmusim/tests/resources/Reference-FMUs/2.0/
cp 3.0/Feedthrough.fmu fmusim/tests/resources/Reference-FMUs/3.0/

cargo test -p fmusim
```

### Coverage

Coverage uses [`cargo-llvm-cov`][cargo-llvm-cov]. With the Reference FMUs in place
(see above):

```bash
cargo install cargo-llvm-cov          # once
rustup component add llvm-tools-preview

cargo llvm-cov -p fmusim --html --open                 # HTML report in your browser
cargo llvm-cov -p fmusim --lcov --output-path lcov.info  # lcov for editors / CI
```

## CI & releases

- [`ci.yml`][ci-yml] builds and tests on Linux, macOS and Windows for every push
  and PR, and reports test coverage (via `cargo-llvm-cov`) to [Codecov][codecov].
- [`release.yml`][release-yml] runs on `v*` tags: it builds a release and a debug
  binary per platform, packages them (`.tar.gz` on Linux/macOS, `.zip` on Windows)
  with the `LICENSE` and `README.md`, and publishes a GitHub release.

## License

2-Clause BSD — see [LICENSE][license]. `fmusim` is a Rust port of FMUSim from the
[Reference FMUs][reference-fmus], released under the same license.

[ci-badge]: https://github.com/AnHeuermann/fmusim-rust/actions/workflows/ci.yml/badge.svg
[ci]: https://github.com/AnHeuermann/fmusim-rust/actions/workflows/ci.yml
[rustup]: https://rustup.rs
[cmake-download]: https://cmake.org/download/
[ref-fmus-releases]: https://github.com/modelica/Reference-FMUs/releases
[releases]: https://github.com/AnHeuermann/fmusim-rust/releases
[fmi]: https://fmi-standard.org
[ci-yml]: .github/workflows/ci.yml
[release-yml]: .github/workflows/release.yml
[license]: LICENSE
[reference-fmus]: https://github.com/t-sommer/Reference-FMUs/tree/rust-fmus
[cargo-llvm-cov]: https://github.com/taiki-e/cargo-llvm-cov
[codecov-badge]: https://codecov.io/gh/AnHeuermann/fmusim-rust/branch/main/graph/badge.svg
[codecov]: https://codecov.io/gh/AnHeuermann/fmusim-rust
[docs-badge]: https://img.shields.io/badge/docs-GitHub%20Pages-blue
[docs]: https://anheuermann.github.io/fmusim-rust/
