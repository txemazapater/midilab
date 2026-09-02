unit discoveryform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, Midi.Core, Midi.Backend, Midi.Discovery;

type
  TMidiInputArray = array of IMidiInput;

  TMidiDiscoveryForm = class(TForm)
    ClearButton: TButton;
    DiscoveryTimer: TTimer;
    ResultsList: TListView;
    ScanButton: TButton;
    StatusBar: TStatusBar;
    StopButton: TButton;
    TopPanel: TPanel;
    procedure ClearButtonClick(Sender: TObject);
    procedure DiscoveryTimerTimer(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ScanButtonClick(Sender: TObject);
    procedure StopButtonClick(Sender: TObject);
  private
    FBackend: IMidiBackend;
    FInputEndpoints, FOutputEndpoints: TMidiEndpointArray;
    FOpenInputs: TMidiInputArray;
    FOutput: IMidiOutput;
    FCurrentOutput: Integer;
    FDeadline: TDateTime;
    FIdentityCount: Integer;
    FTrafficCount: Integer;
    procedure StartScan;
    procedure StopScan(const AStatus: string);
    procedure AdvanceOutput;
    procedure PollInputs;
    procedure AddResult(const AOutputName, AInputName, AEvidence,
      ADetail, ARaw: string);
  end;

implementation

{$R *.lfm}

{$IFDEF WINDOWS}
uses Midi.WinMM;
{$ELSE}
uses Midi.Null;
{$ENDIF}

procedure TMidiDiscoveryForm.FormCreate(Sender: TObject);
begin
  {$IFDEF WINDOWS}
  FBackend := TWinMMMidiBackend.Create;
  {$ELSE}
  FBackend := TNullMidiBackend.Create;
  {$ENDIF}
  FInputEndpoints := FBackend.EnumerateInputs;
  FOutputEndpoints := FBackend.EnumerateOutputs;
  StatusBar.SimpleText := Format('Ready: %d input(s), %d output(s).',
    [Length(FInputEndpoints), Length(FOutputEndpoints)]);
end;

procedure TMidiDiscoveryForm.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  CloseAction := caFree;
end;

procedure TMidiDiscoveryForm.FormDestroy(Sender: TObject);
begin
  StopScan('');
  FBackend := nil;
end;

procedure TMidiDiscoveryForm.ScanButtonClick(Sender: TObject);
begin
  StartScan;
end;

procedure TMidiDiscoveryForm.StopButtonClick(Sender: TObject);
begin
  StopScan('Scan stopped.');
end;

procedure TMidiDiscoveryForm.ClearButtonClick(Sender: TObject);
begin
  ResultsList.Items.Clear;
end;

procedure TMidiDiscoveryForm.StartScan;
var I: Integer;
begin
  StopScan('');
  FInputEndpoints := FBackend.EnumerateInputs;
  FOutputEndpoints := FBackend.EnumerateOutputs;
  if Length(FOutputEndpoints) = 0 then
  begin
    StatusBar.SimpleText := 'No MIDI outputs are available.';
    Exit;
  end;
  SetLength(FOpenInputs, Length(FInputEndpoints));
  for I := 0 to High(FInputEndpoints) do
  begin
    try
      FOpenInputs[I] := FBackend.OpenInput(FInputEndpoints[I]);
      FOpenInputs[I].Start;
    except
      on E: Exception do
      begin
        FOpenInputs[I] := nil;
        AddResult('', FInputEndpoints[I].Name, 'Open failed', E.Message, '');
      end;
    end;
  end;
  FCurrentOutput := -1;
  FIdentityCount := 0;
  FTrafficCount := 0;
  ScanButton.Enabled := False;
  StopButton.Enabled := True;
  DiscoveryTimer.Enabled := True;
  AdvanceOutput;
end;

procedure TMidiDiscoveryForm.StopScan(const AStatus: string);
var I: Integer;
begin
  DiscoveryTimer.Enabled := False;
  FOutput := nil;
  for I := 0 to High(FOpenInputs) do
  begin
    if FOpenInputs[I] <> nil then FOpenInputs[I].Stop;
    FOpenInputs[I] := nil;
  end;
  SetLength(FOpenInputs, 0);
  ScanButton.Enabled := True;
  StopButton.Enabled := False;
  if AStatus <> '' then StatusBar.SimpleText := AStatus;
end;

procedure TMidiDiscoveryForm.AdvanceOutput;
var Request: TMidiBytes;
begin
  FOutput := nil;
  Inc(FCurrentOutput);
  if FCurrentOutput > High(FOutputEndpoints) then
  begin
    StopScan(Format('Finished: %d identity response(s), %d other message(s).',
      [FIdentityCount, FTrafficCount]));
    Exit;
  end;
  try
    FOutput := FBackend.OpenOutput(FOutputEndpoints[FCurrentOutput]);
    Request := BuildIdentityRequest;
    FOutput.Send(Request);
    AddResult(FOutputEndpoints[FCurrentOutput].Name, '', 'Identity request',
      'Universal Non-Realtime, all-call', BytesToHex(Request));
    FDeadline := IncMilliSecond(Now, 1200);
    StatusBar.SimpleText := Format('Probing output %d/%d: %s',
      [FCurrentOutput + 1, Length(FOutputEndpoints),
       FOutputEndpoints[FCurrentOutput].Name]);
  except
    on E: Exception do
    begin
      AddResult(FOutputEndpoints[FCurrentOutput].Name, '', 'Output failed',
        E.Message, '');
      FDeadline := IncMilliSecond(Now, 50);
    end;
  end;
end;

procedure TMidiDiscoveryForm.DiscoveryTimerTimer(Sender: TObject);
begin
  PollInputs;
  if DiscoveryTimer.Enabled and (Now >= FDeadline) then AdvanceOutput;
end;

procedure TMidiDiscoveryForm.PollInputs;
var
  I: Integer;
  Message: TMidiMessage;
  Identity: TMidiIdentity;
  OutputName: string;
begin
  if (FCurrentOutput >= 0) and (FCurrentOutput <= High(FOutputEndpoints)) then
    OutputName := FOutputEndpoints[FCurrentOutput].Name else OutputName := '';
  for I := 0 to High(FOpenInputs) do
    if FOpenInputs[I] <> nil then
      while FOpenInputs[I].TryRead(Message) do
      begin
        if TryParseIdentityReply(Message.RawBytes, Identity) then
        begin
          Inc(FIdentityCount);
          AddResult(OutputName, FInputEndpoints[I].Name, 'Identity reply',
            DescribeIdentity(Identity), BytesToHex(Message.RawBytes));
        end
        else
        begin
          Inc(FTrafficCount);
          AddResult(OutputName, FInputEndpoints[I].Name, 'MIDI activity',
            MidiMessageDescription(Message), BytesToHex(Message.RawBytes));
        end;
      end;
end;

procedure TMidiDiscoveryForm.AddResult(const AOutputName, AInputName,
  AEvidence, ADetail, ARaw: string);
var Item: TListItem;
begin
  Item := ResultsList.Items.Add;
  Item.Caption := FormatDateTime('hh:nn:ss.zzz', Now);
  Item.SubItems.Add(AOutputName);
  Item.SubItems.Add(AInputName);
  Item.SubItems.Add(AEvidence);
  Item.SubItems.Add(ADetail);
  Item.SubItems.Add(ARaw);
  Item.MakeVisible(False);
end;

end.
