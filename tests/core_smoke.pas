program CoreSmoke;

{$mode objfpc}{$H+}

uses SysUtils, Midi.Core, Roland.Protocol;

procedure Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then begin WriteLn(StdErr, 'FAIL: ', AMessage); Halt(1); end;
end;

var
  B, S: TMidiBytes;
  E: string;
  M: TMidiMessage;
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
  WriteLn('MidiLab core smoke tests passed.');
end.
