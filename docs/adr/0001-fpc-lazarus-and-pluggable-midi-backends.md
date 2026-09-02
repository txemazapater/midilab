# ADR-0001: FPC/Lazarus and pluggable MIDI backends

- Status: Accepted
- Date: 2026-09-02

## Context

MidiLab must enumerate local MIDI interfaces, exchange raw MIDI 1.0 traffic
and preserve exact bytes for hardware protocol research. It should be public,
MIT-licensed, buildable without a commercial toolchain and useful as the source
of reusable MIDI infrastructure for the Universal Roland editor.

Windows offers both the established WinMM API and newer MIDI APIs. Binding the
domain model directly to either API would make later portability and MIDI 2.0
work unnecessarily expensive.

## Decision

Use Free Pascal and Lazarus/LCL for the first desktop application. Put all
platform operations behind `IMidiBackend`, `IMidiInput` and `IMidiOutput`.

The first real backend is WinMM because it gives a small, dependency-free path
to MIDI 1.0 hardware. The domain model retains raw bytes alongside decoded
fields. Roland checksum and SysEx construction live in an independent protocol
unit.

Windows executables are built locally with Lazarus/FPC. CI validates only the
portable core until Windows cross-compilation is shown to be dependable.

## Consequences

- No Microsoft development license or runtime is needed.
- The first release is Windows/MIDI 1.0 oriented.
- WinRT/Windows MIDI Services, ALSA, CoreMIDI or RtMidi can be added without
  changing the application model.
- SysEx input requires managed WinMM long-message buffers and is deliberately
  deferred to the next vertical slice.
- Extracting `midi.core` as a separately versioned package is postponed until
  real JD-08 and JV-2080 sessions validate the API.
