# Verification plan

[Return to the module documentation index](README.md).

This plan maps the public [interface specification](interface.md) to unit-level
evidence. The current content describes the template smoke design and provides a
structure to replace for a production module.

## Verification objectives

The template verifies:

- Asynchronous reset clears the output
- An enabled rising edge captures input data
- A disabled rising edge preserves output data
- The directed behavior passes through both SystemVerilog and PyUVM stimulus
- Shared assertions run under normal simulation, PyUVM, and formal proof
- Representative property antecedents are reachable in formal cover mode
- RTL compiles and elaborates in independent frontends
- RTL is generically synthesizable
- Yosys synthesis preserves RTL behavior under the configured EQY strategy

The example does not claim protocol, performance, quantitative coverage, or
parameter-space closure for a production module.

## Verification environments

| Environment | Top | Purpose |
| --- | --- | --- |
| Verilator simulation | `mosaic_module_tb` | Directed SystemVerilog stimulus, bound SVA, and native coverage |
| PyUVM with Verilator | `mosaic_module` | Python-driven smoke test, the same bound SVA, native coverage, and functional coverage |
| VCS simulation | `mosaic_module_tb` | Licensed simulation and SAIF generation path |
| SymbiYosys proof | `mosaic_module_formal` | Reset, update, and hold proofs using the shared assertion wrapper |
| SymbiYosys cover | `mosaic_module_formal` | Reachability of representative reset, update, and hold scenarios |
| EQY | `mosaic_module` | RTL-to-Yosys-netlist equivalence |
| Static frontends | `mosaic_module` | Style, lint, compile, hierarchy, and synthesizability checks |

## Requirements traceability

| ID | Requirement | SystemVerilog simulation | PyUVM | Assertion or formal evidence |
| --- | --- | --- | --- | --- |
| `REQ-RST-001` | Active reset clears `data_o` | Reset sequence in `mosaic_module_tb` | Reset phase in `MosaicModuleTest` | `reset_clears_output` |
| `REQ-DATA-001` | Enabled edge captures `data_i` | Directed `32'h1234_5678` transfer | Enabled-update phase and functional coverage | `output_updates_when_enabled` |
| `REQ-HOLD-001` | Disabled edge preserves `data_o` | Disable after directed transfer | Disabled-hold phase and functional coverage | `output_holds_when_disabled` |
| `REQ-SYN-001` | RTL is synthesizable | Not applicable | Not applicable | Yosys synthesis and structural checks |
| `REQ-EQY-001` | Generic netlist matches RTL | Not applicable | Not applicable | EQY SAT strategy |

Replace this table with every production requirement. A requirement without an
evidence mapping is not covered merely because the testbench passes.

## Simulation plan

The current directed test:

1. Holds asynchronous reset active for two rising edges.
2. Releases reset on a falling edge.
3. Applies one enabled input value.
4. Disables updates and checks the registered output.
5. Waits long enough for one-cycle implication assertions to complete.

Production simulation must add as applicable:

- All commands, responses, opcodes, and error paths
- Minimum, maximum, and representative parameter values
- Reset assertion and release at varied clock phases
- Back-to-back traffic, idle gaps, and backpressure
- Boundary values, overflow, underflow, and signedness cases
- Concurrent events and arbitration
- Low-power and test-mode sequences
- Randomized regressions with recorded seeds
- Scoreboards or reference models independent from DUT logic

## Assertion plan

Reusable sequences live in `verif/properties/mosaic_module_sequences.svh`, and
named properties live in `verif/properties/mosaic_module_properties.svh`. The
assertion checker includes those properties and is attached to the DUT through
`verif/assertions/mosaic_module_bind.sv` in normal simulation and PyUVM.
Verilator enables assertions with `--assert`. The formal harness explicitly
instantiates the same checker rather than relying on `bind`.

For every assertion, document:

- Requirement ID
- Clock and reset domain
- Antecedent reachability
- Failure severity
- Formal and simulation applicability
- Any legal disable condition

An assertion that never reaches its antecedent is not useful evidence. Add cover
properties or coverage points for important activation conditions.

## PyUVM plan

`verif/pyuvm/test_mosaic_module.py` repeats reset, enabled-update, and
disabled-hold behavior through cocotb. PyUVM owns Python stimulus and checking.
It does not call SVA. The HDL simulator compiles the shared assertion and
coverage wrappers, then evaluates them concurrently while PyUVM drives the DUT.

The flow must retain a clean JUnit result, native coverage, and the separate
`functional-coverage.json` summary under `reports/pyuvm_open_source/`. The
repository CI evidence check verifies that all files exist and that native
coverage names both the assertion and coverage source areas.

## Formal plan

The formal harness treats reset, enable, and input data as symbolic. Proof mode
checks reset behavior plus enabled update and disabled hold behavior with an
induction depth of eight. Cover mode demonstrates that representative
antecedents and transfers are reachable.

Before release, review:

- Whether every assumption represents a real integration guarantee
- Whether reset initialization permits all legal startup behavior
- Whether proof depth is justified
- Whether liveness properties need fairness assumptions
- Whether covers demonstrate key legal scenarios are reachable
- Whether parameter configurations require separate proofs

Retain counterexamples for failed properties as debugging evidence. Do not waive
a failing property by strengthening assumptions without an interface review.

## Equivalence plan

EQY compares `rtl/mosaic_module.sv` with the netlist generated under
`work/yosys_synthesis/`. Yosys synthesis is a declared dependency and must record
`PASS` first.

The current SAT strategy uses depth eight. A production module must justify its
strategy and account for memories, black boxes, undriven state, initialization,
and any synthesis transformations that require matching rules.

## Coverage plan

The template produces native Verilator coverage for normal simulation and
PyUVM, a separate JSON functional coverage summary from PyUVM, and formal cover
reachability results. These artifacts demonstrate the integration contract but
do not define production closure targets. A production plan must define:

| Coverage type | Required content |
| --- | --- |
| Requirements | Every requirement has at least one evidence item |
| Functional | Features, modes, transitions, errors, and cross coverage |
| Assertions | Antecedent attempts, passes, failures, and vacuity review |
| Code | Statement, branch, expression, toggle, and FSM goals as applicable |
| Formal | Proven, failed, bounded, unreachable, and covered property counts |

State quantitative targets and the approval process for exclusions.

Review native and Python coverage independently. Python bins do not prove that
bound SVA or HDL cover properties executed, while native HDL coverage does not
replace transaction and scenario coverage sampled by the verification model.

## Parameter and configuration matrix

The smoke flow uses `DATA_WIDTH=32`. Add a reviewed matrix for all supported
values. At minimum, test boundary widths and values that change generated
structure.

| Configuration | Simulation | Formal | Synthesis | Equivalence | Status |
| --- | --- | --- | --- | --- | --- |
| `DATA_WIDTH=32` | Required | Required | Required | Required | Template smoke |

The current Yosys and EQY adapters qualify only `DESIGN_TOP` with its default
parameter values. Listing another profile in this table does not make synthesis
or equivalence evidence exist for it. Use a reviewed wrapper top or separate
configured verification target for every profile that requires persistent
synthesis and EQY reports until `mosaic-flow` provides a shared parameter-matrix
contract.

Simulation and formal harnesses may instantiate multiple profiles in one top.
Record those instances explicitly and distinguish structural elaboration from
per-profile synthesis, timing, power, and equivalence evidence.

## Negative testing

Qualification must prove that checking fails when behavior is wrong. Introduce
temporary faults or dedicated negative fixtures to confirm detection of:

- Incorrect reset value
- Update while disabled
- Failure to capture while enabled
- Assertion failure
- RTL and synthesized netlist mismatch
- Lint or formatting violation

Do not retain injected faults in the release branch.

## Exit criteria

- [ ] Every interface requirement has reviewed evidence.
- [ ] All supported configurations complete their required matrix.
- [ ] Enabled portable flows record `PASS`.
- [ ] Disabled portable flows have an approved reason and record `SKIP`.
- [ ] Simulation regressions pass with recorded tests and seed policy.
- [ ] PyUVM reports clean JUnit, native coverage, and functional coverage evidence.
- [ ] Assertions have no failures and meaningful activation is demonstrated.
- [ ] Formal properties are proven and required cover properties are reachable.
- [ ] Equivalence passes for every required synthesis configuration.
- [ ] Coverage goals are met and exclusions are approved.
- [ ] All waivers are recorded in [Reviewed waivers](waivers.md).
- [ ] The release checklist is complete.
