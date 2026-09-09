# Multi-module repositories

## Scope

The base template represents one independently releasable RTL module. A
repository that intentionally owns several closely related or commonly reused
modules can still use the same methodology by treating each module directory as
an independent `MODULE_ROOT`.

The shared `mosaic-flow` contract remains unchanged:

- One design top per module root
- One simulation top per module root
- One formal top per module root
- One set of flow states, constraints, waivers, reports, and work products per
  module root

Do not combine unrelated design tops into one `config/design.mk`. Isolation is
what allows failures, waivers, constraints, and release evidence to remain
attributable to one module.

## When to use this mode

Use a multi-module repository when the modules share ownership, release cadence,
and a meaningful common purpose. Examples include a library of small primitive
blocks or a tightly coupled protocol subsystem.

Keep independently evolving specialized units in separate repositories. A
repository boundary is preferable when a unit has its own release schedule,
technology requirements, access policy, or verification environment.

## Converting the template

Convert the stock single-module layout deliberately:

1. Create `modules/<name>/` for the example module.
2. Move its `rtl/`, `verif/`, `filelists/`, `config/`, and `flows/` directories
   below that module root.
3. Give the module its own thin Makefile and design-owned documentation.
4. Keep `.github/`, `Dockerfile`, and `mosaic-flow/` at the repository root.
5. Change the generated-artifact entries in `.gitignore` to recursive patterns
   so every module's `work/`, `reports/`, and `ci-artifacts/` trees remain
   untracked.
6. Add every verification target to `.github/modules.json`.
7. Replace the stock single-module jobs in
   `.github/workflows/rtl-simulation.yml` with the matrix jobs.
8. Add integration roots only after the corresponding unit targets pass
   independently.
9. Run every manifest entry locally before enabling the new workflow.

Do not leave the original single-module workflow active beside the matrix
unless duplicate execution is intentional. The matrix becomes the
repository-level open-source acceptance gate.

## Repository hierarchy

Keep the methodology submodule and repository-level automation at the root.
Place a complete project instance under `modules/` for every verification
target:

```text
rtl-library/
|-- .github/
|   |-- modules.json
|   `-- workflows/
|       `-- rtl-quality.yml
|-- modules/
|   |-- fifo/
|   |   |-- config/
|   |   |-- docs/
|   |   |-- filelists/
|   |   |-- flows/
|   |   |-- rtl/
|   |   |-- verif/
|   |   `-- Makefile
|   |-- alu/
|   `-- multiplier/
|-- integration/
|   `-- datapath/
|-- mosaic-flow/
|-- Dockerfile
`-- README.md
```

Each directory under `modules/` follows the normal module hierarchy documented
in [Repository structure](repository-structure.md). An integration target uses
the same hierarchy but may compile several released module sources together.

## Generated-artifact policy

The stock single-module ignore patterns must also cover nested module roots. Use
recursive patterns in the repository-level `.gitignore`:

```gitignore
**/work/
**/reports/
**/ci-artifacts/
```

Do not add separate ignore entries every time a module is created. Confirm the
policy before review:

```sh
git check-ignore modules/<name>/work/probe
git check-ignore modules/<name>/reports/probe
git check-ignore modules/<name>/ci-artifacts/probe
```

Every command must print the tested path. A missing result means the nested
artifact tree is not ignored.

## Per-module Makefile

Every module keeps a thin Makefile. `MODULE_ROOT` resolves to that module
directory, while CI supplies the repository-level `mosaic-flow` path:

```make
SHELL := /usr/bin/env bash

export MODULE_ROOT := $(CURDIR)
export FLOW_ROOT ?= $(abspath $(MODULE_ROOT)/../../mosaic-flow)

include config/design.mk
include $(FLOW_ROOT)/config/tools.mk
include $(FLOW_ROOT)/mk/module.mk
```

Do not add module-specific orchestration to this Makefile. Put module identity
and paths in `config/design.mk`, policy in `config/flows.mk`, and tool intent
under `flows/`.

## Module manifest

Use `.github/modules.json` as the repository-level source of truth for CI
discovery. Keep names stable because they become job labels and artifact names:

```json
{
  "include": [
    {
      "name": "fifo",
      "path": "modules/fifo"
    },
    {
      "name": "alu",
      "path": "modules/alu"
    },
    {
      "name": "multiplier",
      "path": "modules/multiplier"
    }
  ]
}
```

Every entry must satisfy these rules:

- `name` is unique and contains only lowercase letters, numbers, `_`, or `-`.
- `path` is a unique repository-relative directory.
- The directory contains a Makefile and complete module configuration.
- Report and work roots remain below that directory.
- The entry represents a verification target, not merely one SystemVerilog
  source file.

Validate the manifest during review:

```sh
python3 -m json.tool .github/modules.json >/dev/null
```

## GitHub Actions matrix

The workflow first reads the committed manifest. Every matrix child then checks
out the same module revision and exact methodology gitlink, but runs the flow
from its own module root. The stock workflow does not discover module roots, so
replace its single-module jobs or create a new matrix workflow and disable the
old one.

```yaml
jobs:
  module-matrix:
    name: Read module matrix
    runs-on: ubuntu-24.04
    outputs:
      matrix: ${{ steps.modules.outputs.matrix }}
    steps:
      - name: Check out repository
        uses: actions/checkout@v7

      - name: Read module manifest
        id: modules
        run: |
          matrix="$(python3 -c \
            $'import json\nprint(json.dumps(json.load(open(".github/modules.json")))))')"
          echo "matrix=${matrix}" >> "${GITHUB_OUTPUT}"

  module-checks:
    name: ${{ matrix.name }} RTL checks
    needs: module-matrix
    runs-on: ubuntu-24.04
    strategy:
      fail-fast: false
      matrix: ${{ fromJSON(needs.module-matrix.outputs.matrix) }}

    steps:
      - name: Check out repository
        uses: actions/checkout@v7
        with:
          persist-credentials: false

      - name: Read methodology revision
        id: flow-revision
        run: |
          revision="$(git ls-files --stage mosaic-flow |
            awk '$1 == "160000" {print $2}')"
          if [[ ! "${revision}" =~ ^[0-9a-f]{40}$ ]]
          then
            echo "mosaic-flow must be a pinned Git submodule" >&2
            exit 1
          fi
          echo "revision=${revision}" >> "${GITHUB_OUTPUT}"

      - name: Check out pinned methodology
        uses: actions/checkout@v7
        with:
          repository: ECASLab/mosaic-flow
          ref: ${{ steps.flow-revision.outputs.revision }}
          path: mosaic-flow
          persist-credentials: false

      - name: Cache open-source tools
        uses: actions/cache@v5
        with:
          path: ~/.cache/mosaic
          key: mosaic-tools-${{ runner.os }}-${{ runner.arch }}-${{ hashFiles('mosaic-flow/config/tool-versions.env', 'mosaic-flow/config/pyuvm-requirements.txt') }}

      - name: Validate module policy
        run: |
          make -C "${{ matrix.path }}" \
            FLOW_ROOT="${GITHUB_WORKSPACE}/mosaic-flow" \
            flow-config-check

      - name: Run module quality gate
        run: |
          make -C "${{ matrix.path }}" \
            FLOW_ROOT="${GITHUB_WORKSPACE}/mosaic-flow" \
            clean open-source

      - name: Validate module PyUVM evidence
        run: |
          ./.github/scripts/check-pyuvm-evidence.sh \
            "${{ matrix.path }}/reports/pyuvm_open_source"

      - name: Upload module reports
        if: always()
        uses: actions/upload-artifact@v7
        with:
          name: ${{ matrix.name }}-open-source-reports
          path: ${{ matrix.path }}/reports/
          if-no-files-found: error
```

`fail-fast: false` allows every module to finish and report its own result. The
matrix job still fails when any child fails, so an integration or release job
that declares `needs: module-checks` cannot start prematurely.

The production workflow should retain the template's tool-version reporting and
diagnostic artifact behavior. Use module-qualified diagnostic paths and artifact
names so parallel jobs cannot be confused during review.

Do not reduce the matrix workflow to only the abbreviated native job above. The
repository-level conversion must preserve these behaviors from the stock
workflow for every manifest entry:

- Native tool setup uses the pinned `mosaic-flow` revision.
- Tool versions are recorded below the module's `reports/tool_versions/` tree.
- Native flow logs are written below the module's `ci-artifacts/` tree.
- Enabled PyUVM flows retain clean JUnit, native HDL coverage, functional
  coverage, and version evidence below the module's report tree.
- The container image embeds the same pinned methodology revision.
- The container runs with `--workdir /workspace/${{ matrix.path }}`.
- Native and container report artifacts include the module name.
- Diagnostic artifacts are uploaded even when the flow fails.

The container execution step must select the matrix module explicitly:

```yaml
- name: Run containerized module flow
  run: |
    docker run --rm \
      --user "$(id -u):$(id -g)" \
      --env HOME=/tmp \
      --volume "${GITHUB_WORKSPACE}:/workspace" \
      --workdir "/workspace/${{ matrix.path }}" \
      "mosaic-module-ci:${GITHUB_SHA}" clean open-source
```

Use distinct artifact names such as
`${{ matrix.name }}-native-reports` and
`${{ matrix.name }}-container-reports`. Reusing one artifact name across matrix
children can overwrite or combine evidence from unrelated module roots.

## RTL checks per module

`make clean open-source` runs the enabled portable flow graph against only the
current module root. Consequently, each matrix child independently performs:

- Verible style lint and formatting
- Slang compilation and elaboration
- Strict Verilator lint
- Yosys generic synthesis
- SymbiYosys formal verification
- EQY RTL-to-netlist equivalence
- Verilator simulation
- PyUVM with the configured open-source simulator
- Native HDL coverage and PyUVM functional coverage evidence
- The aggregate open-source quality gate

The module's `config/flows.mk` decides which checks are enabled. Dependencies
are resolved within that module only. Reports are naturally isolated under
`modules/<name>/reports/<flow-id>/` because `MODULE_ROOT` differs for every
matrix child.

## Regression configuration

The normal simulator contract executes one `TB_TOP` per module, while PyUVM
executes the decorated tests in `PYUVM_TEST_MODULE` against `PYUVM_TOP`.
Configure both paths as self-checking unit regressions.

For each module:

1. Set `TB_TOP` in `config/design.mk` to the regression top.
2. Set `PYUVM_TOP`, `PYUVM_TEST_MODULE`, and `PYUVM_TEST_PATH` for the Python
   environment.
3. Keep DUT and testbench sources in their primary lists, then keep shared
   properties, assertions, and coverage in their dedicated filelists.
4. Make both regression environments execute every required scenario.
5. Make every mismatch, assertion failure, timeout, or incomplete test return a
   nonzero simulation status.
6. Record the test inventory and expected native plus functional coverage in
   `docs/verification-plan.md`.
7. Keep test-generated files under the module's `work/` and `reports/`
   directories.

The regression must not rely on another module's job output. If the DUT imports
a shared package or instantiates another source module, include that dependency
in the module's file lists so a clean job can compile it independently.

The normal simulator adapter does not schedule a list of independent test
executables. PyUVM may discover several decorated tests in one Python module,
but still aggregates them into one flow status. A future process-level test
matrix requires an explicit `mosaic-flow` extension with a test-list contract,
result aggregation, and one final status.

## Container execution

The container image embeds the shared methodology. Mount the repository root
and select the module with Docker's working directory:

```sh
docker run --rm \
  --user "$(id -u):$(id -g)" \
  --env HOME=/tmp \
  --volume "$PWD:/workspace" \
  --workdir /workspace/modules/fifo \
  mosaic-module-ci:local clean open-source
```

A container matrix may use
`--workdir "/workspace/${{ matrix.path }}"`. Building the same image in every
matrix child is correct but expensive. Prefer one cached image build per
workflow, then distribute or publish that immutable image for the module jobs.
Keep the embedded `mosaic-flow` revision equal to the parent gitlink.

## Commercial flows

Run licensed flows from each module root in the authorized environment:

```sh
make -C modules/fifo FLOW_ROOT="$PWD/mosaic-flow" synopsys-check-env
make -C modules/fifo FLOW_ROOT="$PWD/mosaic-flow" synopsys-all
```

Commercial reports and constraints remain module-specific. Do not combine
waivers or signoff evidence from different tops into one status.

## Dependencies and integration

Source dependencies do not normally create GitHub job dependencies. A FIFO that
uses a shared package must compile the package in its own file list rather than
waiting for a package job.

Use `needs: module-checks` for an integration target that should run only after
every unit target passes:

```yaml
  integration-checks:
    needs: module-checks
    runs-on: ubuntu-24.04
    steps:
      - name: Run integrated datapath verification
        run: |
          make -C integration/datapath \
            FLOW_ROOT="${GITHUB_WORKSPACE}/mosaic-flow" \
            clean open-source
```

The integration directory owns its top, assertions, constraints, waivers, and
reports. Unit-level waivers do not automatically authorize an integration-level
violation.

## Local execution

Run the same commands used by one matrix child:

```sh
make -C modules/fifo FLOW_ROOT="$PWD/mosaic-flow" flow-config-check
make -C modules/fifo FLOW_ROOT="$PWD/mosaic-flow" clean open-source

make -C modules/alu FLOW_ROOT="$PWD/mosaic-flow" flow-config-check
make -C modules/alu FLOW_ROOT="$PWD/mosaic-flow" clean open-source
```

The repository may provide a root convenience target that iterates the committed
manifest, but it must delegate to these module-local Makefiles. The module-local
commands remain the release contract.

## Release requirements

A multi-module repository release requires:

- Every manifest entry to complete its enabled unit flows
- Every module regression to pass
- Every required integration target to pass after unit checks
- Separate artifacts and waiver records for every verification target
- The same module revision and methodology gitlink in every job
- Documented compatibility between modules released together

Do not infer repository success from one passing module. The matrix aggregate
and required integration jobs define the repository-level result.
