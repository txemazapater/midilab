unit mainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, Midi.Core, Midi.Backend;

type
  TForm1 = class(TForm)
    ClearButton: TButton;
    ConnectInputButton: TButton;
    ConnectOutputButton: TButton;
    DiscoveryButton: TButton;
    InputCombo: TComboBox;
    InputLabel: TLabel;
    MonitorList: TListView;
    OutputCombo: TComboBox;
    OutputLabel: TLabel;
    PatchDumpButton: TButton;
    PollTimer: TTimer;
    RawEdit: TEdit;
    RawLabel: TLabel;
    RefreshButton: TButton;
    SendButton: TButton;
    SendPanel: TPanel;
    StatusBar: TStatusBar;
    TopPanel: TPanel;
    procedure ClearButtonClick(Sender: TObject);
    procedure ConnectInputButtonClick(Sender: TObject);
    procedure ConnectOutputButtonClick(Sender: TObject);
    procedure DiscoveryButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure PollTimerTimer(Sender: TObject);
    procedure PatchDumpButtonClick(Sender: TObject);
    procedure RefreshButtonClick(Sender: TObject);
    procedure SendButtonClick(Sender: TObject);
  private
    FBackend: IMidiBackend;
    FInputs, FOutputs: TMidiEndpointArray;
    FInput: IMidiInput;
    FOutput: IMidiOutput;
    procedure RefreshDevices;
    procedure AddMessage(const AMessage: TMidiMessage);
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

uses
  patchdumpform, discoveryform
  {$IFDEF WINDOWS}, Midi.WinMM{$ELSE}, Midi.Null{$ENDIF};

procedure TForm1.FormCreate(Sender: TObject);
begin
  {$IFDEF WINDOWS}
  FBackend := TWinMMMidiBackend.Create;
  {$ELSE}
  FBackend := TNullMidiBackend.Create;
  {$ENDIF}
  RefreshDevices;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  PollTimer.Enabled := False;
  if FInput <> nil then FInput.Stop;
  FInput := nil;
  FOutput := nil;
  FBackend := nil;
end;

procedure TForm1.RefreshDevices;
var I: Integer;
begin
  if (FInput <> nil) or (FOutput <> nil) then
  begin
    StatusBar.SimpleText := 'Disconnect endpoints before refreshing.';
    Exit;
  end;
  FInputs := FBackend.EnumerateInputs;
  FOutputs := FBackend.EnumerateOutputs;
  InputCombo.Clear;
  for I := 0 to High(FInputs) do InputCombo.Items.Add(FInputs[I].Name);
  OutputCombo.Clear;
  for I := 0 to High(FOutputs) do OutputCombo.Items.Add(FOutputs[I].Name);
  if InputCombo.Items.Count > 0 then InputCombo.ItemIndex := 0;
  if OutputCombo.Items.Count > 0 then OutputCombo.ItemIndex := 0;
  StatusBar.SimpleText := Format('%s: %d input(s), %d output(s)',
    [FBackend.Name, Length(FInputs), Length(FOutputs)]);
end;

procedure TForm1.RefreshButtonClick(Sender: TObject);
begin
  RefreshDevices;
end;

procedure TForm1.PatchDumpButtonClick(Sender: TObject);
begin
  with TMidiPatchDumpForm.Create(Self) do Show;
end;

procedure TForm1.DiscoveryButtonClick(Sender: TObject);
begin
  with TMidiDiscoveryForm.Create(Self) do Show;
end;

procedure TForm1.ConnectInputButtonClick(Sender: TObject);
begin
  try
    if FInput <> nil then
    begin
      FInput.Stop;
      FInput := nil;
      ConnectInputButton.Caption := 'Connect';
    end
    else
    begin
      if InputCombo.ItemIndex < 0 then Exit;
      FInput := FBackend.OpenInput(FInputs[InputCombo.ItemIndex]);
      FInput.Start;
      ConnectInputButton.Caption := 'Disconnect';
    end;
  except
    on E: Exception do StatusBar.SimpleText := E.Message;
  end;
end;

procedure TForm1.ConnectOutputButtonClick(Sender: TObject);
begin
  try
    if FOutput <> nil then
    begin
      FOutput := nil;
      ConnectOutputButton.Caption := 'Connect';
    end
    else
    begin
      if OutputCombo.ItemIndex < 0 then Exit;
      FOutput := FBackend.OpenOutput(FOutputs[OutputCombo.ItemIndex]);
      ConnectOutputButton.Caption := 'Disconnect';
    end;
  except
    on E: Exception do StatusBar.SimpleText := E.Message;
  end;
end;

procedure TForm1.SendButtonClick(Sender: TObject);
var
  B: TMidiBytes;
  ErrorText: string;
  M: TMidiMessage;
begin
  if FOutput = nil then
  begin
    StatusBar.SimpleText := 'Connect a MIDI output first.';
    Exit;
  end;
  if not TryHexToBytes(RawEdit.Text, B, ErrorText) then
  begin
    StatusBar.SimpleText := ErrorText;
    Exit;
  end;
  try
    FOutput.Send(B);
    M := MidiMessageFromBytes(B, mdOutput, FOutput.Endpoint.Id);
    AddMessage(M);
  except
    on E: Exception do StatusBar.SimpleText := E.Message;
  end;
end;

procedure TForm1.ClearButtonClick(Sender: TObject);
begin
  MonitorList.Items.Clear;
end;

procedure TForm1.PollTimerTimer(Sender: TObject);
var M: TMidiMessage;
begin
  if FInput <> nil then
    while FInput.TryRead(M) do AddMessage(M);
end;

procedure TForm1.AddMessage(const AMessage: TMidiMessage);
var Item: TListItem;
begin
  Item := MonitorList.Items.Add;
  Item.Caption := FormatDateTime('hh:nn:ss.zzz', AMessage.TimestampUtc);
  if AMessage.Direction = mdInput then Item.SubItems.Add('IN')
  else Item.SubItems.Add('OUT');
  Item.SubItems.Add(BytesToHex(AMessage.RawBytes));
  Item.SubItems.Add(MidiMessageDescription(AMessage));
  Item.MakeVisible(False);
end;

end.
