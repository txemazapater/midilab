unit Midi.WinMM;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows, MMSystem, Midi.Core, Midi.Backend;

type
  TWinMMMidiBackend = class(TInterfacedObject, IMidiBackend)
  public
    function Name: string;
    function EnumerateInputs: TMidiEndpointArray;
    function EnumerateOutputs: TMidiEndpointArray;
    function OpenInput(const AEndpoint: TMidiEndpoint): IMidiInput;
    function OpenOutput(const AEndpoint: TMidiEndpoint): IMidiOutput;
  end;

implementation

type
  PMidiNode = ^TMidiNode;
  TMidiNode = record
    Message: TMidiMessage;
    Next: PMidiNode;
  end;

  TWinMMMidiInput = class(TInterfacedObject, IMidiInput)
  private
    FEndpoint: TMidiEndpoint;
    FHandle: HMIDIIN;
    FLock: TRTLCriticalSection;
    FHead, FTail: PMidiNode;
    procedure EnqueueShort(AValue: DWORD);
  public
    constructor Create(const AEndpoint: TMidiEndpoint);
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    function Endpoint: TMidiEndpoint;
    function TryRead(out AMessage: TMidiMessage): Boolean;
  end;

  TWinMMMidiOutput = class(TInterfacedObject, IMidiOutput)
  private
    FEndpoint: TMidiEndpoint;
    FHandle: HMIDIOUT;
  public
    constructor Create(const AEndpoint: TMidiEndpoint);
    destructor Destroy; override;
    procedure Send(const ABytes: array of Byte);
    function Endpoint: TMidiEndpoint;
  end;

procedure MidiInputCallback(AHandle: HMIDIIN; AMessage: UINT;
  AInstance, AParam1, AParam2: DWORD_PTR); stdcall;
begin
  if (AMessage = MIM_DATA) and (AInstance <> 0) then
    TWinMMMidiInput(Pointer(AInstance)).EnqueueShort(DWORD(AParam1));
end;

function DeviceIndex(const AEndpoint: TMidiEndpoint): UINT;
begin
  Result := StrToIntDef(Copy(AEndpoint.Id, Pos(':', AEndpoint.Id) + 1,
    MaxInt), -1);
  if Result = UINT(-1) then raise Exception.Create('Invalid WinMM endpoint id');
end;

function TWinMMMidiBackend.Name: string; begin Result := 'Windows WinMM'; end;

function TWinMMMidiBackend.EnumerateInputs: TMidiEndpointArray;
var I, Count: UINT; Caps: MIDIINCAPS;
begin
  Count := midiInGetNumDevs;
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
  begin
    FillChar(Caps, SizeOf(Caps), 0);
    if midiInGetDevCaps(I, @Caps, SizeOf(Caps)) <> MMSYSERR_NOERROR then Continue;
    Result[I].Id := 'winmm-in:' + IntToStr(I);
    Result[I].Name := Caps.szPname;
    Result[I].IsInput := True;
  end;
end;

function TWinMMMidiBackend.EnumerateOutputs: TMidiEndpointArray;
var I, Count: UINT; Caps: MIDIOUTCAPS;
begin
  Count := midiOutGetNumDevs;
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
  begin
    FillChar(Caps, SizeOf(Caps), 0);
    if midiOutGetDevCaps(I, @Caps, SizeOf(Caps)) <> MMSYSERR_NOERROR then Continue;
    Result[I].Id := 'winmm-out:' + IntToStr(I);
    Result[I].Name := Caps.szPname;
    Result[I].IsInput := False;
  end;
end;

function TWinMMMidiBackend.OpenInput(const AEndpoint: TMidiEndpoint): IMidiInput;
begin Result := TWinMMMidiInput.Create(AEndpoint); end;
function TWinMMMidiBackend.OpenOutput(const AEndpoint: TMidiEndpoint): IMidiOutput;
begin Result := TWinMMMidiOutput.Create(AEndpoint); end;

constructor TWinMMMidiInput.Create(const AEndpoint: TMidiEndpoint);
var R: MMRESULT;
begin
  inherited Create;
  FEndpoint := AEndpoint;
  InitCriticalSection(FLock);
  R := midiInOpen(@FHandle, DeviceIndex(AEndpoint), DWORD_PTR(@MidiInputCallback),
    DWORD_PTR(Self), CALLBACK_FUNCTION);
  if R <> MMSYSERR_NOERROR then raise Exception.CreateFmt('Cannot open MIDI input (%d)', [R]);
end;

destructor TWinMMMidiInput.Destroy;
var M: TMidiMessage;
begin
  Stop;
  if FHandle <> 0 then midiInClose(FHandle);
  while TryRead(M) do ;
  DoneCriticalSection(FLock);
  inherited Destroy;
end;

procedure TWinMMMidiInput.Start;
begin if midiInStart(FHandle) <> MMSYSERR_NOERROR then raise Exception.Create('Cannot start MIDI input'); end;
procedure TWinMMMidiInput.Stop;
begin if FHandle <> 0 then midiInStop(FHandle); end;
function TWinMMMidiInput.Endpoint: TMidiEndpoint; begin Result := FEndpoint; end;

procedure TWinMMMidiInput.EnqueueShort(AValue: DWORD);
var N: PMidiNode; Status, L: Byte; B: TMidiBytes;
begin
  Status := AValue and $FF;
  if Status >= $F8 then L := 1
  else if (Status and $F0) in [$C0, $D0] then L := 2 else L := 3;
  SetLength(B, L);
  B[0] := Status;
  if L > 1 then B[1] := (AValue shr 8) and $FF;
  if L > 2 then B[2] := (AValue shr 16) and $FF;
  New(N);
  N^.Message := MidiMessageFromBytes(B, mdInput, FEndpoint.Id);
  N^.Next := nil;
  EnterCriticalSection(FLock);
  try
    if FTail = nil then FHead := N else FTail^.Next := N;
    FTail := N;
  finally LeaveCriticalSection(FLock); end;
end;

function TWinMMMidiInput.TryRead(out AMessage: TMidiMessage): Boolean;
var N: PMidiNode;
begin
  EnterCriticalSection(FLock);
  try
    N := FHead;
    Result := N <> nil;
    if Result then
    begin
      FHead := N^.Next;
      if FHead = nil then FTail := nil;
      AMessage := N^.Message;
    end;
  finally LeaveCriticalSection(FLock); end;
  if Result then Dispose(N);
end;

constructor TWinMMMidiOutput.Create(const AEndpoint: TMidiEndpoint);
var R: MMRESULT;
begin
  inherited Create;
  FEndpoint := AEndpoint;
  R := midiOutOpen(@FHandle, DeviceIndex(AEndpoint), 0, 0, CALLBACK_NULL);
  if R <> MMSYSERR_NOERROR then raise Exception.CreateFmt('Cannot open MIDI output (%d)', [R]);
end;

destructor TWinMMMidiOutput.Destroy;
begin if FHandle <> 0 then midiOutClose(FHandle); inherited Destroy; end;
function TWinMMMidiOutput.Endpoint: TMidiEndpoint; begin Result := FEndpoint; end;

procedure TWinMMMidiOutput.Send(const ABytes: array of Byte);
var Packed: DWORD; R: MMRESULT;
begin
  if (Length(ABytes) < 1) or (Length(ABytes) > 3) then
    raise Exception.Create('WinMM short output accepts one to three bytes; SysEx output is the next slice.');
  Packed := ABytes[0];
  if Length(ABytes) > 1 then Packed := Packed or (DWORD(ABytes[1]) shl 8);
  if Length(ABytes) > 2 then Packed := Packed or (DWORD(ABytes[2]) shl 16);
  R := midiOutShortMsg(FHandle, Packed);
  if R <> MMSYSERR_NOERROR then raise Exception.CreateFmt('MIDI send failed (%d)', [R]);
end;

end.
