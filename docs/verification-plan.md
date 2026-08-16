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
- RTL compiles and elaborates in independent frontends
- RTL is generically synthesizable
- Yosys synthesis preserves RTL behavior under the configured EQY strategy

The example does not claim protocol, performance, coverage, or parameter-space
closure for a production module.

## Verification environments

| Environment | Top | Purpose |
| --- | --- | --- |
| Verilator simulation | `mosaic_module_tb` | Directed stimulus, bound SVA, end-to-end smoke check |
| VCS simulation | `mosaic_module_tb` | Licensed simulation and SAIF generation path |
| SymbiYosys | `mosaic_module_formal` | Reset, update, and hold proofs |
| EQY | `mosaic_module` | RTL-to-Yosys-netlist equivalence |
| Static frontends | `mosaic_module` | Style, lint, compile, hierarchy, and synthesizability checks |

## Requirements traceability

| ID | Requirement | Simulation | Assertion or formal evidence |
| --- | --- | --- | --- |
| `REQ-RST-001` | Active reset clears `data_o` | Reset sequence in `mosaic_module_tb` | Combinational reset assertion in formal harness |
| `REQ-DATA-001` | Enabled edge captures `data_i` | Directed `32'h1234_5678` transfer | `output_updates_when_enabled` and formal update assertion |
| `REQ-HOLD-001` | Disabled edge preserves `data_o` | Disable after directed transfer | `output_holds_when_disabled` and formal hold assertion |
| `REQ-SYN-001` | RTL is synthesizable | Not applicable | Yosys synthesis and structural checks |
| `REQ-EQY-001` | Generic netlist matches RTL | Not applicable | EQY SAT strategy |

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

Assertions are bound through `verif/assertions/mosaic_module_bind.sv` and are
compiled in the simulation file list. Verilator simulation enables assertions
with `--assert`.

For every assertion, document:

- Requirement ID
- Clock and reset domain
- Antecedent reachability
- Failure severity
- Formal and simulation applicability
- Any legal disable condition

An assertion that never reaches its antecedent is not useful evidence. Add cover
properties or coverage points for important activation conditions.

## Formal plan

The formal harness treats reset, enable, and input data as symbolic. It proves
reset behavior plus enabled update and disabled hold behavior with an induction
depth of eight.

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

The template does not yet collect functional or code coverage. A production
plan must define:

| Coverage type | Required content |
| --- | --- |
| Requirements | Every requirement has at least one evidence item |
| Functional | Features, modes, transitions, errors, and cross coverage |
| Assertions | Antecedent attempts, passes, failures, and vacuity review |
| Code | Statement, branch, expression, toggle, and FSM goals as applicable |
| Formal | Proven, failed, bounded, unreachable, and covered property counts |

State quantitative targets and the approval process for exclusions.

## Parameter and configuration matrix

The smoke flow uses `DATA_WIDTH=32`. Add a reviewed matrix for all supported
values. At minimum, test boundary widths and values that change generated
structure.

| Configuration | Simulation | Formal | Synthesis | Equivalence | Status |
| --- | --- | --- | --- | --- | --- |
| `DATA_WIDTH=32` | Required | Required | Required | Required | Template smoke |

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
- [ ] Assertions have no failures and meaningful activation is demonstrated.
- [ ] Formal properties are proven or have reviewed bounded status.
- [ ] Equivalence passes for every required synthesis configuration.
- [ ] Coverage goals are met and exclusions are approved.
- [ ] All waivers are recorded in [Reviewed waivers](waivers.md).
- [ ] The release checklist is complete.
