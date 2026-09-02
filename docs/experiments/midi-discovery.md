# MIDI 1.0 device discovery

## Purpose

Discover which MIDI input paths receive traffic after probing each MIDI output.
Windows enumerates interfaces, not the instruments connected behind them, so
MidiLab records evidence instead of treating silence as proof of absence.

## Standard probe

MidiLab sends the Universal Non-Realtime Identity Request using the all-call
device ID:

```text
F0 7E 7F 06 01 F7
```

An implementing device can answer with Identity Reply (`06 02`), containing
its manufacturer ID, family, family member and four revision bytes.

## Scan algorithm

1. Enumerate and open every available MIDI input.
2. Open one MIDI output.
3. Send Identity Request and listen on every input for 1.2 seconds.
4. Record Identity Reply as strong correlated evidence.
5. Record all other received MIDI as activity, not identity.
6. Close that output and repeat for the next output.

If an input is already open in another MidiLab form, the failure is recorded in
the results. Disconnect the main monitor and Patch Dump form for a clean scan.

## Interpretation

- **Identity reply** identifies a responding device and correlates an output to
  the input that carried its response.
- **MIDI activity** proves that an input path is active but does not prove that
  the traffic was caused by the current probe.
- **No response** is inconclusive: the device may not implement Identity Reply,
  SysEx reception may be disabled, or no return path may exist.
- Several devices on a chain may answer one all-call request.

Later model-specific probes must be separately registered and read-only. They
must not be presented as part of the universal identity standard.
