unit Midi.Discovery;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Midi.Core;

type
  TMidiIdentity = record
    DeviceId: Byte;
    ManufacturerId: string;
    ManufacturerName: string;
    FamilyCode: string;
    FamilyMemberCode: string;
    SoftwareRevision: string;
  end;

function BuildIdentityRequest: TMidiBytes;
function TryParseIdentityReply(const ABytes: array of Byte;
  out AIdentity: TMidiIdentity): Boolean;
function DescribeIdentity(const AIdentity: TMidiIdentity): string;

implementation

function BuildIdentityRequest: TMidiBytes;
begin
  SetLength(Result, 6);
  Result[0] := $F0;
  Result[1] := $7E;
  Result[2] := $7F;
  Result[3] := $06;
  Result[4] := $01;
  Result[5] := $F7;
end;

function ManufacturerName(const AId: string): string;
begin
  case AId of
    '41': Result := 'Roland';
    '42': Result := 'Korg';
    '43': Result := 'Yamaha';
    '44': Result := 'Casio';
    '47': Result := 'Akai';
    '40': Result := 'Kawai';
    '00 20 29': Result := 'Novation';
    '00 20 33': Result := 'M-Audio';
  else
    Result := 'Unknown manufacturer';
  end;
end;

function TryParseIdentityReply(const ABytes: array of Byte;
  out AIdentity: TMidiIdentity): Boolean;
var P: Integer;
begin
  AIdentity := Default(TMidiIdentity);
  Result := False;
  if Length(ABytes) < 15 then Exit;
  if (ABytes[0] <> $F0) or (ABytes[1] <> $7E) or
     (ABytes[3] <> $06) or (ABytes[4] <> $02) or
     (ABytes[High(ABytes)] <> $F7) then Exit;
  AIdentity.DeviceId := ABytes[2];
  if ABytes[5] = 0 then
  begin
    if Length(ABytes) < 17 then Exit;
    AIdentity.ManufacturerId := BytesToHex([ABytes[5], ABytes[6], ABytes[7]]);
    P := 8;
  end
  else
  begin
    AIdentity.ManufacturerId := IntToHex(ABytes[5], 2);
    P := 6;
  end;
  if P + 8 >= Length(ABytes) then Exit;
  AIdentity.ManufacturerName := ManufacturerName(AIdentity.ManufacturerId);
  AIdentity.FamilyCode := BytesToHex([ABytes[P], ABytes[P + 1]]);
  AIdentity.FamilyMemberCode := BytesToHex([ABytes[P + 2], ABytes[P + 3]]);
  AIdentity.SoftwareRevision := BytesToHex([ABytes[P + 4], ABytes[P + 5],
    ABytes[P + 6], ABytes[P + 7]]);
  Result := True;
end;

function DescribeIdentity(const AIdentity: TMidiIdentity): string;
begin
  Result := Format('%s [%s], device=%s, family=%s, member=%s, version=%s',
    [AIdentity.ManufacturerName, AIdentity.ManufacturerId,
     IntToHex(AIdentity.DeviceId, 2), AIdentity.FamilyCode,
     AIdentity.FamilyMemberCode, AIdentity.SoftwareRevision]);
end;

end.
