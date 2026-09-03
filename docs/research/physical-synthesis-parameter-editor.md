# Future Research — Physical Synthesis Parameter Editor

> Status: long-term product/research direction. Not scheduled for the current Phase 1 implementation.

## Origin

A long-standing idea is to build a **physical hardware editor for synthesis parameters**: a dedicated control surface with knobs, switches, displays and other tactile controls that can expose the editable architecture of external musical devices without forcing the musician to work through small screens, nested menus or a computer mouse.

The Universal Music Device Editor project may provide the missing software abstraction needed to make that idea practical across multiple devices rather than as a one-off controller for a single synthesizer.

## Core idea

Instead of hard-wiring a panel to one synthesizer model, the physical editor would consume the same device definitions, capability metadata and parameter bindings used by desktop/headless applications.

```text
               Universal Device Definition
                         |
                 Capability / Binding
                         |
          +--------------+--------------+
          |                             |
     Desktop Editor              Physical Editor
          |                             |
       mouse/UI                  knobs/buttons/display
          |                             |
          +--------------+--------------+
                         |
                     Device
```

The physical surface therefore becomes another presentation/interaction client of the common core.

## Design intent

The device should prioritize **direct, tactile synthesis interaction**.

Candidate goals:

- one-knob-per-function where practical;
- dynamically assigned controls where necessary;
- clear visual indication of parameter identity and current value;
- immediate feedback when device state changes;
- support for pickup/relative/absolute control strategies;
- parameter pages derived from device architecture rather than hard-coded panel assumptions;
- reusable physical groups such as oscillator, pitch, filter, amplifier, envelopes, LFO, modulation and effects where semantic mapping is justified;
- explicit access to device-native parameters that do not fit the universal semantic layer;
- bidirectional synchronization where the target device supports it;
- multiple device profiles without reflashing/rebuilding the hardware;
- standalone operation where possible.

## The abstraction problem

A universal physical editor is harder than a universal graphical editor because physical controls are finite.

The design must distinguish:

```text
semantic control
    e.g. filter.cutoff

physical control
    e.g. encoder 07

device binding
    e.g. JD-08 CC / JV-2080 SysEx address
```

The physical layout must not define the core data model.

A future mapping layer may therefore require concepts such as:

- control groups/pages;
- control roles;
- preferred semantic mappings;
- dynamic labels;
- takeover/pickup mode;
- value scaling/curves;
- coarse/fine editing;
- modifiers/shift layers;
- device-native fallback pages.

## Possible hardware role for Uno Q-class platform

A hybrid Linux + real-time microcontroller platform such as the already available Uno Q-class hardware is an attractive future host because it could separate high-level application responsibilities from deterministic I/O.

Possible split:

```text
Linux/application side
  device definitions
  UI/display
  library
  networking
  USB host
  profile management
  updates

real-time side
  encoders
  buttons
  LEDs
  MIDI timing
  GPIO
  deterministic control scanning
  future hardware interfaces
```

This is not a commitment to Uno Q as the final hardware platform.

## Relationship to the Device Bridge

The physical editor and the proposed Universal Device Bridge may be separate products or two operating modes of the same appliance.

```text
                    Hardware Appliance
                           |
             +-------------+-------------+
             |                           |
       Device Bridge                Physical Editor
       headless/network             tactile UI
             |                           |
             +-------------+-------------+
                           |
                 protocols/transports
                           |
                         device
```

A combined appliance could remain permanently connected to a studio rack, provide MIDI/USB/network bridging, expose legacy devices to modern software and offer immediate physical editing without a PC.

## Architectural consequence today

Even though this hardware does not belong to the current implementation phase, it introduces one useful constraint now:

> **The universal core, device definitions and protocol engines must not depend on a desktop graphical UI.**

They should remain usable by:

- desktop applications;
- headless services;
- embedded/Linux appliances;
- physical control surfaces.

## Validation strategy

Do not design the final panel before the device model is validated.

A sensible progression is:

1. use MidiLab to understand raw device behaviour;
2. use the desktop editor to validate semantic/device mappings;
3. identify which parameter groups recur naturally across devices;
4. prototype a small physical control surface;
5. test it first against JD-08 and JV-2080;
6. introduce a radically different device/manufacturer;
7. only then decide whether a truly universal hardware control layout is viable.

## Open questions

- fixed panel versus fully dynamic control surface;
- endless encoders versus potentiometers;
- motorized controls where useful;
- display count and placement;
- touch versus non-touch UI;
- universal semantic sections versus native device pages;
- standalone library/storage requirements;
- number and type of simultaneous MIDI/USB connections;
- relationship to future hardware peripheral virtualization;
- whether the product should be modular/expandable.

## Guiding principle

The goal is not to reproduce the front panel of every synthesizer.

The goal is to give a musician **direct physical access to the meaningful parameters of the connected device**, using the same universal description that powers the rest of the platform.
