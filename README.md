# MidiLab

MidiLab is a small, native MIDI laboratory for inspecting and testing hardware
synthesizers. It is the engineering companion of the Universal Roland Music
Device Editor project, but it deliberately remains vendor-neutral.

The first milestone targets Windows MIDI 1.0 through WinMM. This initial slice
provides:

- independent MIDI input and output endpoint enumeration;
- explicit connect/disconnect lifecycle;
- incoming-message monitoring with timestamp, decoded form and original bytes;
- transmission of raw short MIDI messages;
- a platform-independent MIDI model and Roland protocol helpers.

## Architecture

```text
app (Lazarus/LCL)
  -> midi.core
  -> midi.backend
       -> midi.winmm (Windows)
       -> midi.null  (development/fallback)
  -> roland.protocol
```

Neither `midi.core` nor `roland.protocol` depends on LCL, WinMM or a specific
operating system. They are intended to become reusable packages once their API
has been exercised against real devices.

## Build on Windows

Install a current Lazarus/FPC release, open `src/app/midilab.lpi`, select the
`Release` build mode and build the project. From PowerShell the equivalent is:

```powershell
./scripts/build-windows.ps1
```

The executable is written to `build/windows/x86_64/MidiLab.exe`. No Microsoft
SDK, .NET runtime or commercial compiler is required.

## Tests

The core smoke test does not require Lazarus or MIDI hardware:

```bash
fpc -Fu./src/core -Fu./src/protocols/roland -FE./build/tests tests/core_smoke.pas
./build/tests/core_smoke
```

GitHub Actions runs only this portable validation. Producing a Windows binary
is intentionally a local build until the cross-compilation toolchain is proven
reliable.

## Status

This is an initial engineering sketch. WinMM endpoint enumeration and short
message transmission are implemented. Input monitoring is implemented for
short MIDI messages; long SysEx input/output buffering and session persistence
are the next vertical slice.

## License

MIT. See [LICENSE](LICENSE).
