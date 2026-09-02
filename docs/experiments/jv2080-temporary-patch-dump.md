# JV-2080 Temporary Patch dump

## Goal

Read the currently selected Patch from the JV-2080 temporary area and retain
the unmodified SysEx response before decoding any parameters. This experiment
is read-only: MidiLab transmits RQ1 (`11H`) and never DT1 (`12H`).

## Source

Roland JV-2080 Owner's Manual, MIDI Implementation, parameter address map
(pages 187-190 of the printed manual). Model ID is `6AH`.

## Requests

The temporary Patch starts at `03 00 00 00`. Because its sections are not one
contiguous parameter block, MidiLab sends five requests:

| Block | Address | Size |
| --- | --- | --- |
| Common | `03 00 00 00` | `00 00 00 4A` |
| Tone 1 | `03 00 10 00` | `00 00 01 01` |
| Tone 2 | `03 00 12 00` | `00 00 01 01` |
| Tone 3 | `03 00 14 00` | `00 00 01 01` |
| Tone 4 | `03 00 16 00` | `00 00 01 01` |

Addresses and sizes use Roland's 7-bit base-128 representation. The default
device ID is `10H` and can be changed in the form.

## First test procedure

1. Connect JV-2080 MIDI OUT to the selected PC input and PC output to JV-2080
   MIDI IN.
2. Ensure reception of System Exclusive messages is enabled on the JV-2080.
3. Disconnect the endpoints in MidiLab's main monitor before opening them in
   the Patch Dump form.
4. Open **JV-2080 Patch Dump**, select both endpoints and connect.
5. Press **Request selected patch**.
6. Preserve the five transmitted RQ1 messages and every received DT1 frame.

The first successful capture will define the DT1 reassembly and parameter
decoding tests. No assumption is made yet about response packet boundaries.
