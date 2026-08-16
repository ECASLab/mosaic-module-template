# Repository structure

## Design goal

Each module repository must be independently understandable, verifiable, and
releasable before system integration. The hierarchy separates design-owned
intent from the independently versioned shared methodology.

```text
module-repository/
|-- .github/workflows/       Portable module CI
|-- config/                  Cross-flow module configuration
|-- docs/                    Design contract and engineering records
|-- filelists/               Ordered source manifests
|-- flows/                   Module-owned inputs for shared flow adapters
|-- mosaic-flow/             Pinned methodology Git submodule
|-- reports/                 Generated reviewable results
|-- rtl/                     Synthesizable SystemVerilog
|-- verif/                   Simulation, assertions, formal, models, coverage
|-- work/                    Disposable tool databases and generated artifacts
|-- Dockerfile               Reproducible portable-tool environment
|-- Makefile                 Thin importer of the shared Make API
`-- README.md                Repository overview and common commands
```

## Source hierarchy

### `rtl/`

Contains only synthesizable module RTL and public packages. Keep generated
netlists and tool output under `work/`. If a source is generated, commit its
generator and document whether the generated RTL is also authoritative.

### `verif/`

Organize verification by purpose:

```text
verif/
|-- assertions/             Bound SystemVerilog assertions
|-- formal/                 Formal harnesses and assumptions
|-- tb/                     Unit-level simulation testbench and tests
|-- models/                 Optional reference models
`-- coverage/               Optional coverage models and plans
```

Shared verification libraries may be dependencies, but this repository remains
responsible for proving its module without relying on a full MOSAIC integration.

### `filelists/`

File lists are ordered source manifests and form part of the build contract:

- `rtl.f` contains synthesizable sources and include directories.
- `tb.f` contains or imports RTL plus simulation and assertion sources.
- `formal.f` may support formal tools or local utilities even when a specific
  `.sby` file lists its own sources.

Use paths that resolve from the repository root. Keep tool-specific command-line
options out of shared file lists unless every consuming adapter supports them.

## Configuration hierarchy

### `config/design.mk`

Defines module identity and the paths exported to all shared adapters. It also
provides optional technology and activity inputs for licensed implementation
flows.

### `config/flows.mk`

Defines project policy. Every canonical flow is explicitly enabled or disabled,
and project-specific dependencies may replace shared defaults.

### `flows/`

Contains module-owned inputs grouped by the shared adapter that consumes them:

| Directory | Module-owned intent |
| --- | --- |
| `cdc/` | Clocks, resets, synchronizers, and intentional crossings |
| `eqy/` | Golden and gate setup plus equivalence strategies |
| `openroad/` | PDK-backed design configuration and timing constraints |
| `sg_dft/` | Test clocks, modes, resets, and exclusions |
| `symbiyosys/` | Proof mode, engines, sources, and formal top |
| `synthesis/` | Synthesis timing constraints |
| `vc_lp/` | UPF power domains, supplies, states, isolation, and retention |
| `verible/` | Style policy and reviewed style waivers |
| `verilator_lint/` | Reviewed Verilator control-file waivers |

The matching directory under `mosaic-flow/flows/` contains invocation logic.
This repository's directory contains design intent. A methodology update can
therefore improve a tool adapter without silently replacing module constraints.

## Shared methodology

`mosaic-flow/` is a Git submodule pinned by the parent repository gitlink. The
root Makefile imports:

```make
include config/design.mk
include $(FLOW_ROOT)/config/tools.mk
include $(FLOW_ROOT)/mk/module.mk
```

Keep this Makefile thin. New reusable targets belong in `mosaic-flow`. New
module inputs belong in `config/design.mk` or the matching module-owned flow
directory.

The complete shared hierarchy is documented in
[`mosaic-flow/docs/architecture.md`](../mosaic-flow/docs/architecture.md).

## Generated data

### `reports/`

Contains statuses, logs, and compact summaries intended for review or CI
retention. The first file to inspect is usually
`reports/<canonical-flow-id>/status.txt`.

### `work/`

Contains disposable executables, netlists, proof databases, and tool state. It
must never be treated as source.

Both directories are ignored by Git. `make clean` removes generated work and
flow reports while preserving the report root placeholder.

## Container and CI ownership

The GitHub workflow validates the module with the exact `mosaic-flow` revision
recorded by the gitlink. It runs both native and containerized portable checks.

The Dockerfile copies only the executable shared methodology into the image.
The module repository is mounted at runtime, which keeps RTL and generated
reports outside the image and lets local and CI execution use the same source
tree.

Commercial tools, licenses, PDKs, and proprietary libraries remain outside the
container and GitHub-hosted runners. They are supplied only by the authorized
local or self-hosted environment.

## Source of truth

When artifacts disagree, use this order:

1. RTL and design-owned configuration in the module revision
2. The pinned `mosaic-flow` implementation for execution semantics
3. Machine-readable status and reports for a specific run
4. Documentation describing the intended contract

Correct any disagreement before release. A passing tool result does not excuse
stale interface or verification documentation.
