# ADR-0002: Consolidate MidiLab and UniRoland into one product platform

- Status: Accepted
- Date: 2026-09-03

## Context

Two repositories currently describe different halves of what has become the same project.

`txemazapater/uniroland` began as research for a Universal Roland Synth Editor and evolved into the broader **Universal Music Device Editor** concept. It contains the manufacturer-neutral device model, capability model, device research, Roland SysEx research, preservation goals and future hardware-virtualization work.

`txemazapater/midilab` began as a small MIDI engineering laboratory. It already contains executable Free Pascal/Lazarus code organized into application, backend, core and protocol layers. Its portable MIDI model and Roland helpers are intentionally UI- and platform-independent.

The boundary between the repositories is now artificial:

```text
uniroland                         midilab
---------                         -------
Universal Device Model           portable core
Device definitions               protocol units
Capability model                 MIDI backends
JD-08/JV-2080 research           device discovery
Protocol architecture            raw MIDI/SysEx experiments
Preservation strategy            desktop engineering tool
Hardware virtualization          executable/test harness
```

Continuing independently would create duplicated ADRs, competing abstractions and unclear ownership of the core.

## Decision

The projects will be consolidated into a **single product platform and repository lineage**.

The implementation-bearing `midilab` repository is the preferred physical destination because it already contains source code, tests, build scripts and CI structure. The `uniroland` repository is primarily a research/documentation corpus and will eventually be archived after its validated material is migrated.

This ADR authorizes the consolidation, but **does not perform the migration yet**.

A controlled migration must preserve both repositories until documentation, builds, tests and history references have been checked.

## Product model

The unified project is not "MidiLab plus an editor". Both are applications/capabilities built on a common platform:

```text
                 Universal Music Device Platform
                              |
                +-------------+-------------+
                |             |             |
              Core        Applications     Hardware
                |             |             |
        Device model        Editor        Device Bridge
        Capabilities        MidiLab       Physical Editor
        Definitions         Librarian     Resource proxies
        Protocols           Diagnostics   Future appliances
        Transports
```

The public product name remains **Universal Music Device Editor** for the editing experience unless a later naming decision introduces a broader platform name.

`MidiLab` remains useful as the name of the engineering/diagnostic application inside the platform.

## Repository target shape

The exact filesystem layout remains subject to implementation evidence, but the intended separation is approximately:

```text
src/
  core/
  protocols/
  transports/
  backends/
  devices/
  library/

apps/
  editor/
  midilab/

hardware/
  bridge/
  physical-editor/
  resource-proxies/

devices/
  roland/
    jd-08/
    jv-2080/
  other-manufacturers/

docs/
  architecture/
  adr/
  research/
  experiments/

tests/
```

This is a directional map, not a mandatory immediate refactor.

## Architectural ownership after consolidation

The unified core owns:

- manufacturer-neutral device concepts;
- parameter and operation identities;
- capability semantics;
- bindings;
- protocol/profile interfaces;
- transport interfaces;
- state synchronization contracts;
- resource/storage abstractions when validated.

Applications own presentation and workflows.

Protocol modules own manufacturer/protocol-specific encoding and transactions.

Backends own operating-system or physical transport access.

Hardware projects consume the same device definitions and protocol semantics where practical rather than reimplementing them independently.

## Existing decisions retained

The consolidation does not supersede these accepted principles:

- Roland-first, not Roland-bound;
- no synthesizer-only root model;
- device-native identity remains visible;
- declarative-first device definitions;
- semantic identity is independent from physical binding;
- protocol and transport are separate concerns;
- MIDI is an initial evidence base, not the permanent boundary;
- temporary and persistent state are distinct;
- synchronization capabilities are device-dependent;
- functional preservation is a first-class goal;
- hardware peripheral virtualization is a valid future integration mechanism.

MidiLab ADR-0001 also remains valid: Free Pascal/Lazarus and pluggable MIDI backends are the accepted implementation choice for the **current desktop engineering application**, not automatically for every future platform component.

## Migration plan

### Phase A — Inventory and reconciliation

1. Inventory all files, ADRs, research notes and experiments in both repositories.
2. Identify duplicated or contradictory decisions.
3. Map current MidiLab source modules to the universal architecture.
4. Decide which UniRoland documents are canonical, historical or obsolete.

### Phase B — Documentation migration

1. Move canonical UniRoland architecture/research material into the unified repository.
2. Normalize ADR numbering/naming without losing provenance.
3. Replace obsolete references to JV-1080 with JV-2080 where it is now the physical reference device, while keeping JV-1080 as a sibling/reference model.
4. Add manufacturer/device definition directories only when their schemas become stable enough.

### Phase C — Code alignment

1. Keep the existing portable MIDI core and backend interfaces.
2. Ensure Roland protocol code remains independent from UI and OS backends.
3. Introduce device-definition and capability layers only after current hardware experiments justify their APIs.
4. Retain MidiLab as the engineering application used to interrogate, capture and validate devices.

### Phase D — Validation

Before retiring either repository:

- desktop build succeeds;
- portable tests succeed;
- documentation links resolve;
- JD-08 workflow still works;
- JV-2080 discovery/SysEx workflow works;
- no accepted ADR is lost;
- LICENSE and public-project metadata are preserved.

### Phase E — Repository retirement/rename

After validation:

- archive `uniroland` with a final README pointing to the unified project;
- optionally rename `midilab` to the final project/repository name;
- keep `MidiLab` as the diagnostic application name unless a later ADR says otherwise.

## Consequences

### Positive

- one architectural source of truth;
- one issue/roadmap surface;
- device research feeds executable tests directly;
- MidiLab becomes the natural hardware-validation harness;
- desktop, headless and hardware products can share definitions/protocols;
- fewer duplicated abstractions and fewer cross-repository synchronization errors.

### Costs/risks

- migration must reconcile two different ADR traditions;
- current source layout may need gradual restructuring;
- a monorepo can become unfocused if component boundaries are not maintained;
- hardware work must not contaminate the portable core with board-specific assumptions.

## Non-decisions

This ADR does not choose:

- a final repository name;
- a final platform/product brand beyond the existing Universal Music Device Editor name;
- a serialization format for device definitions;
- a single language for every component;
- Uno Q as mandatory hardware;
- a final UI architecture;
- a plugin/package distribution system.

Those decisions require separate evidence and ADRs.
