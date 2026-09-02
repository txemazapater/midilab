program CoreSmoke;

{$mode objfpc}{$H+}

uses SysUtils, Midi.Core, Midi.Discovery, Roland.Protocol;

procedure Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then begin WriteLn(StdErr, 'FAIL: ', AMessage); Halt(1); end;
end;

var
  B, S: TMidiBytes;
  E: string;
  M: TMidiMessage;
  Identity: TMidiIdentity;
begin
  Check(TryHexToBytes('B0 10 64', B, E), E);
  Check(BytesToHex(B) = 'B0 10 64', 'hex round-trip');
  M := MidiMessageFromBytes(B, mdInput, 'test');
  Check((M.Kind = mmControlChange) and (M.Channel = 1), 'CC decode');
  Check(RolandChecksum([$10, $00, $00, $00, $01]) = $6F, 'Roland checksum');
  S := BuildRolandDataSet1($10, $6A, [$10, $00, $00, $00], [$01]);
  Check((Length(S) = 12) and (S[0] = $F0) and (S[High(S)] = $F7), 'DT1 frame');
  S := BuildRolandRequest1($10, $6A, [$03, $00, $00, $00], [$00, $00, $00, $4A]);
  Check((Length(S) = 15) and (S[4] = $11) and (S[13] = $33), 'RQ1 frame');
  S := BuildIdentityRequest;
  Check(BytesToHex(S) = 'F0 7E 7F 06 01 F7', 'identity request');
  Check(TryParseIdentityReply(
    [$F0, $7E, $10, $06, $02, $41, $01, $02, $03, $04, $31, $2E, $30, $30, $F7],
    Identity), 'identity reply');
  Check(Identity.ManufacturerName = 'Roland', 'identity manufacturer');
  WriteLn('MidiLab core smoke tests passed.');
end.
