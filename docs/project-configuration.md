# Project configuration

## Configuration layers

The module consumes shared defaults and then applies design-owned policy:

1. `config/design.mk` defines module identity, paths, and technology inputs.
2. `mosaic-flow/config/tools.mk` defines pinned tool locations and command
   defaults.
3. `mosaic-flow/config/flows.mk` defines canonical flow states and dependencies.
4. Module `config/flows.mk` replaces shared states or dependencies.
5. Make command-line assignments provide temporary diagnostic overrides.

The root Makefile establishes this order. Keep it free of design-specific flow
logic.

## Module identity

These values must agree with the RTL and verification hierarchy:

| Variable | Meaning | Template value |
| --- | --- | --- |
| `DESIGN_TOP` | Synthesizable top | `mosaic_module` |
| `TB_TOP` | Simulation top | `mosaic_module_tb` |
| `FORMAL_TOP` | Formal harness top | `mosaic_module_formal` |
| `DUT_INSTANCE` | Hierarchical DUT for SAIF annotation | `mosaic_module_tb/dut` |

`DUT_INSTANCE` uses the hierarchy syntax expected by PrimePower activity
annotation. Confirm it against the generated SAIF hierarchy rather than assuming
the simulation source name is sufficient.

## Paths

`FLOW_CONFIG_ROOT` points to the module-owned `flows/` directory. Other exported
paths identify:

- RTL and simulation file lists
- Verible and Verilator waiver policy
- Formal and equivalence configuration
- OpenROAD design configuration
- Synthesis, CDC, DFT, and UPF intent
- Report and work roots

Prefer absolute paths derived from `MODULE_ROOT`. Tool adapters may change their
working directory, while the module contract should remain stable.

The current Design Compiler adapter reads
`$(CONSTRAINT_DIR)/timing.sdc`. Keep `SYNTHESIS_CONSTRAINT_FILE` consistent with
that file.

## Flow states

Every canonical flow has an explicit module policy:

```make
FLOW_verilator_sim := enabled
FLOW_openroad := disabled
```

Only `enabled` and `disabled` are valid. Disabled flows record `SKIP` when their
target is invoked. The quality gate requires `PASS` for enabled flows and
`SKIP` for disabled flows.

The template enables the portable RTL gate, disables optional OpenROAD, selects
VC CDC, and leaves commercial flows enabled for local qualification.

Run:

```sh
make flow-config-check
```

Review the output after every state or dependency change.

## Dependencies

Dependencies use canonical flow IDs and replace the complete shared dependency
list:

```make
FLOW_DEPENDENCIES_eqy_equivalence := yosys_synthesis
FLOW_DEPENDENCIES_synopsys_primepower := vcs_sim synopsys_synthesis
```

The configuration validator rejects unknown IDs, self dependencies, cycles,
and enabled flows that depend on disabled flows. The runner requires every
dependency to record `PASS` before launching the dependent tool.

Use dependencies for real artifact or policy requirements. Do not add edges
only to force a preferred display order.

## Diagnostic overrides

A one-run Make assignment can inspect a different policy without editing the
project file:

```sh
make FLOW_symbiyosys_formal=disabled open-source
make CDC_TOOL=sg synopsys-cdc
```

`FORCE_FLOW=1` may execute one disabled flow for diagnosis:

```sh
make open-formal FORCE_FLOW=1
```

The flow remains disabled in project policy, so the aggregate gate still expects
`SKIP`. Do not use force mode as release evidence.

## Technology setup

Commercial implementation uses environment-provided site data:

| Variable | Purpose |
| --- | --- |
| `TECH_SETUP_TCL` | Optional setup sourced by synthesis, timing, and power Tcl |
| `TARGET_LIBRARY` | Target technology library used by site setup |
| `LINK_LIBRARY` | Link libraries used by site setup |
| `OPERATING_CONDITION` | Requested analysis corner used by site setup |
| `ACTIVITY_FILE` | SAIF activity consumed by PrimePower |

These values are empty or generic in the template. Supply them through the
authorized local environment. Never commit licenses, credentials, PDK paths, or
proprietary libraries.

## Tool executable overrides

The shared methodology defines executable defaults. Override them only when the
site installation uses a different command or wrapper:

```sh
make VERILATOR_CMD=/opt/verilator/bin/verilator open-lint
make SYNTH_BIN=/eda/synopsys/bin/dc_shell synopsys-synth
```

Do not pin open-source versions in this repository. Update the `mosaic-flow`
gitlink to a qualified release that carries the new version manifest.

## Updating the methodology revision

Fetch and inspect the candidate revision:

```sh
git -C mosaic-flow fetch origin
git -C mosaic-flow checkout --detach <qualified-commit>
git add mosaic-flow
```

Verify the parent gitlink and submodule checkout agree:

```sh
git submodule status
git ls-files -s mosaic-flow
git -C mosaic-flow rev-parse HEAD
```

Then rerun native, containerized, and applicable commercial gates. Review the
candidate's documentation and release notes for changed inputs, statuses, tool
versions, and policy before accepting the pointer update.

## Further reference

The authoritative shared configuration semantics are documented in
[`mosaic-flow/docs/configuration.md`](../mosaic-flow/docs/configuration.md).
The complete flow IDs, inputs, outputs, and tool references are in the shared
[flow catalog](../mosaic-flow/docs/flows.md).
