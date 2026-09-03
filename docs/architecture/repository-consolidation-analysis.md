# Repository Consolidation Analysis

## Summary

`midilab` and `uniroland` are no longer separate projects in architectural terms.

They represent complementary layers of one platform:

- `uniroland` contains the research, domain model, device/protocol studies and long-term preservation strategy;
- `midilab` contains the executable MIDI laboratory and the first reusable implementation layers.

Maintaining them independently would force artificial ownership boundaries and duplicate decisions.

## Current strengths of MidiLab

- Free Pascal/Lazarus desktop application already builds and runs;
- platform-independent MIDI model;
- pluggable backend interfaces;
- WinMM implementation;
- raw MIDI monitoring;
- short-message output;
- Roland protocol helpers;
- tests, scripts and CI skeleton;
- explicit separation between application, core, protocols and backends.

This makes MidiLab the natural implementation-bearing repository.

## Current strengths of UniRoland

- Universal Music Device Editor identity;
- manufacturer-neutral architectural principles;
- universal/device-native/binding identity separation;
- device capability model;
- JD-08 and JV family research;
- Roland RQ1/DT1 direction;
- state-synchronization research;
- functional preservation objective;
- hardware peripheral virtualization ADR;
- future hardware/device-bridge direction.

This material should become canonical architecture/research documentation inside the unified repository.

## Overlap and conflict risk

Both repositories already address:

- portable protocol logic;
- Roland SysEx;
- device independence;
- UI independence;
- real-device validation;
- architectural ADRs.

Without consolidation, a change such as defining a new Device ID abstraction could require coordinated edits in two repositories and two ADR histories.

## Recommended responsibility map

```text
Universal core
  device model
  capabilities
  semantic/device identities
  bindings
  synchronization contracts

Protocol modules
  MIDI messages
  manufacturer SysEx
  transaction logic
  checksums/addressing

Transport/backends
  WinMM
  USB MIDI
  ALSA/CoreMIDI/future
  physical hardware bridges

Applications
  MidiLab
  Editor
  Librarian
  diagnostics

Hardware
  Device Bridge
  physical parameter editor
  resource/peripheral proxies

Knowledge
  device definitions
  protocol docs
  experiments
  captures
```

## Why not keep two repositories?

A split would make sense only if MidiLab were a general-purpose independent MIDI utility with no dependence on the device platform.

That is no longer the intended direction. MidiLab is becoming the project's diagnostic and protocol-development front end, while its reusable core is the implementation substrate for the editor.

Keeping it separate would therefore create packaging and versioning work before the reusable APIs have stabilized.

## Why not migrate code into UniRoland instead?

It is technically possible, but provides little benefit.

MidiLab already has the build/test/toolchain structure. UniRoland is documentation-centric. Moving the smaller research corpus into the implementation repository is lower risk than relocating the active source tree and build history.

## Recommended timing

Consolidate now, before:

- SysEx long-message support becomes large;
- device definitions acquire stable schemas;
- JV-2080 experiments generate significant captured data;
- additional applications appear;
- hardware prototypes begin;
- external contributors start depending on repository paths/packages.

The current project size makes this the cheapest point at which to converge.

## Immediate next step

Do not perform a blind file copy.

The next action after ADR-0002 should be a migration inventory that classifies every UniRoland file as one of:

```text
canonical -> migrate
merge     -> reconcile with existing MidiLab material
historical -> retain only in archived source repo
obsolete  -> do not migrate
```

Only then should the physical move begin.
