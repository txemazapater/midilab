unit Midi.Core;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DateUtils;

type
  TMidiDirection = (mdInput, mdOutput);
  TMidiMessageKind = (mmUnknown, mmNoteOff, mmNoteOn, mmPolyPressure,
    mmControlChange, mmProgramChange, mmChannelPressure, mmPitchBend,
    mmSystem, mmSysEx);
  TMidiBytes = array of Byte;

  TMidiEndpoint = record
    Id: string;
    Name: string;
    IsInput: Boolean;
  end;
  TMidiEndpointArray = array of TMidiEndpoint;

  TMidiMessage = record
    TimestampUtc: TDateTime;
    Direction: TMidiDirection;
    EndpointId: string;
    RawBytes: TMidiBytes;
    Kind: TMidiMessageKind;
    Channel: Integer;
    Data1: Integer;
    Data2: Integer;
  end;

  TMidiMessageEvent = procedure(const AMessage: TMidiMessage) of object;

function MidiMessageFromBytes(const ABytes: array of Byte;
  ADirection: TMidiDirection; const AEndpointId: string): TMidiMessage;
function MidiMessageDescription(const AMessage: TMidiMessage): string;
function BytesToHex(const ABytes: array of Byte): string;
function TryHexToBytes(const AText: string; out ABytes: TMidiBytes;
  out AError: string): Boolean;

implementation

function MidiMessageFromBytes(const ABytes: array of Byte;
  ADirection: TMidiDirection; const AEndpointId: string): TMidiMessage;
var
  I, Status: Integer;
begin
  Result.TimestampUtc := LocalTimeToUniversal(Now);
  Result.Direction := ADirection;
  Result.EndpointId := AEndpointId;
  SetLength(Result.RawBytes, Length(ABytes));
  for I := 0 to High(ABytes) do Result.RawBytes[I] := ABytes[I];
  Result.Kind := mmUnknown;
  Result.Channel := -1;
  Result.Data1 := -1;
  Result.Data2 := -1;
  if Length(ABytes) = 0 then Exit;
  Status := ABytes[0];
  if Status = $F0 then Result.Kind := mmSysEx
  else if Status >= $F0 then Result.Kind := mmSystem
  else if Status >= $80 then
  begin
    Result.Channel := (Status and $0F) + 1;
    case Status and $F0 of
      $80: Result.Kind := mmNoteOff;
      $90: if (Length(ABytes) > 2) and (ABytes[2] = 0) then
             Result.Kind := mmNoteOff else Result.Kind := mmNoteOn;
      $A0: Result.Kind := mmPolyPressure;
      $B0: Result.Kind := mmControlChange;
      $C0: Result.Kind := mmProgramChange;
      $D0: Result.Kind := mmChannelPressure;
      $E0: Result.Kind := mmPitchBend;
    end;
  end;
  if Length(ABytes) > 1 then Result.Data1 := ABytes[1];
  if Length(ABytes) > 2 then Result.Data2 := ABytes[2];
end;

function MidiMessageDescription(const AMessage: TMidiMessage): string;
const
  Names: array[TMidiMessageKind] of string = ('Unknown', 'Note Off', 'Note On',
    'Poly Pressure', 'Control Change', 'Program Change', 'Channel Pressure',
    'Pitch Bend', 'System', 'SysEx');
begin
  Result := Names[AMessage.Kind];
  if AMessage.Channel > 0 then Result := Result + ' ch=' + IntToStr(AMessage.Channel);
  if AMessage.Data1 >= 0 then Result := Result + ' data1=' + IntToStr(AMessage.Data1);
  if AMessage.Data2 >= 0 then Result := Result + ' data2=' + IntToStr(AMessage.Data2);
end;

function BytesToHex(const ABytes: array of Byte): string;
var I: Integer;
begin
  Result := '';
  for I := 0 to High(ABytes) do
  begin
    if I > 0 then Result := Result + ' ';
    Result := Result + IntToHex(ABytes[I], 2);
  end;
end;

function TryHexToBytes(const AText: string; out ABytes: TMidiBytes;
  out AError: string): Boolean;
var
  Tokens: TStringList;
  I, V: Integer;
begin
  Result := False;
  AError := '';
  SetLength(ABytes, 0);
  Tokens := TStringList.Create;
  try
    Tokens.Delimiter := ' ';
    Tokens.StrictDelimiter := True;
    Tokens.DelimitedText := StringReplace(Trim(AText), #9, ' ', [rfReplaceAll]);
    for I := Tokens.Count - 1 downto 0 do
      if Tokens[I] = '' then Tokens.Delete(I);
    SetLength(ABytes, Tokens.Count);
    for I := 0 to Tokens.Count - 1 do
    begin
      if (Length(Tokens[I]) > 2) or
         not TryStrToInt('$' + Tokens[I], V) or (V < 0) or (V > 255) then
      begin
        AError := 'Invalid hexadecimal byte: "' + Tokens[I] + '"';
        SetLength(ABytes, 0);
        Exit;
      end;
      ABytes[I] := Byte(V);
    end;
    Result := Length(ABytes) > 0;
    if not Result then AError := 'Enter at least one hexadecimal byte.';
  finally
    Tokens.Free;
  end;
end;

end.
