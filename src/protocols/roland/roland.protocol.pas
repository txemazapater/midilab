unit Roland.Protocol;

{$mode objfpc}{$H+}

interface

uses Midi.Core;

function RolandChecksum(const AData: array of Byte): Byte;
function BuildRolandDataSet1(ADeviceId, AModelId: Byte;
  const AAddress, AData: array of Byte): TMidiBytes;

implementation

function RolandChecksum(const AData: array of Byte): Byte;
var I, Sum: Integer;
begin
  Sum := 0;
  for I := 0 to High(AData) do Inc(Sum, AData[I]);
  Result := Byte((128 - (Sum mod 128)) mod 128);
end;

function BuildRolandDataSet1(ADeviceId, AModelId: Byte;
  const AAddress, AData: array of Byte): TMidiBytes;
var
  CheckData: TMidiBytes;
  I, P: Integer;
begin
  SetLength(CheckData, Length(AAddress) + Length(AData));
  P := 0;
  for I := 0 to High(AAddress) do begin CheckData[P] := AAddress[I]; Inc(P); end;
  for I := 0 to High(AData) do begin CheckData[P] := AData[I]; Inc(P); end;
  SetLength(Result, 7 + Length(CheckData));
  Result[0] := $F0;
  Result[1] := $41;
  Result[2] := ADeviceId;
  Result[3] := AModelId;
  Result[4] := $12;
  for I := 0 to High(CheckData) do Result[5 + I] := CheckData[I];
  Result[5 + Length(CheckData)] := RolandChecksum(CheckData);
  Result[6 + Length(CheckData)] := $F7;
end;

end.
