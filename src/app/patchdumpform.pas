unit patchdumpform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, Midi.Core, Midi.Backend;

type
  TMidiPatchDumpForm = class(TForm)
    ClearButton: TButton;
    ConnectButton: TButton;
    DeviceIdEdit: TEdit;
    DeviceIdLabel: TLabel;
    DumpMemo: TMemo;
    InputCombo: TComboBox;
    InputLabel: TLabel;
    OutputCombo: TComboBox;
    OutputLabel: TLabel;
    PollTimer: TTimer;
    RequestButton: TButton;
    StatusBar: TStatusBar;
    TopPanel: TPanel;
    procedure ClearButtonClick(Sender: TObject);
    procedure ConnectButtonClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure PollTimerTimer(Sender: TObject);
    procedure RequestButtonClick(Sender: TObject);
  private
    FBackend: IMidiBackend;
    FInputs, FOutputs: TMidiEndpointArray;
    FInput: IMidiInput;
    FOutput: IMidiOutput;
    procedure Disconnect;
    procedure SendRequest(ADeviceId: Byte; const AAddress, ASize: array of Byte;
      const ABlockName: string);
  end;

implementation

{$R *.lfm}

uses
  Roland.Protocol
  {$IFDEF WINDOWS}, Midi.WinMM{$ELSE}, Midi.Null{$ENDIF};

procedure TMidiPatchDumpForm.FormCreate(Sender: TObject);
var I: Integer;
begin
  {$IFDEF WINDOWS}
  FBackend := TWinMMMidiBackend.Create;
  {$ELSE}
  FBackend := TNullMidiBackend.Create;
  {$ENDIF}
  FInputs := FBackend.EnumerateInputs;
  FOutputs := FBackend.EnumerateOutputs;
  for I := 0 to High(FInputs) do InputCombo.Items.Add(FInputs[I].Name);
  for I := 0 to High(FOutputs) do OutputCombo.Items.Add(FOutputs[I].Name);
  if InputCombo.Items.Count > 0 then InputCombo.ItemIndex := 0;
  if OutputCombo.Items.Count > 0 then OutputCombo.ItemIndex := 0;
  StatusBar.SimpleText := Format('%d input(s), %d output(s)',
    [Length(FInputs), Length(FOutputs)]);
end;

procedure TMidiPatchDumpForm.FormDestroy(Sender: TObject);
begin
  PollTimer.Enabled := False;
  Disconnect;
  FBackend := nil;
end;

procedure TMidiPatchDumpForm.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  CloseAction := caFree;
end;

procedure TMidiPatchDumpForm.Disconnect;
begin
  if FInput <> nil then FInput.Stop;
  FInput := nil;
  FOutput := nil;
  ConnectButton.Caption := 'Connect';
  RequestButton.Enabled := False;
end;

procedure TMidiPatchDumpForm.ConnectButtonClick(Sender: TObject);
begin
  if (FInput <> nil) or (FOutput <> nil) then
  begin
    Disconnect;
    Exit;
  end;
  if (InputCombo.ItemIndex < 0) or (OutputCombo.ItemIndex < 0) then
  begin
    StatusBar.SimpleText := 'Select both MIDI endpoints.';
    Exit;
  end;
  try
    FInput := FBackend.OpenInput(FInputs[InputCombo.ItemIndex]);
    FOutput := FBackend.OpenOutput(FOutputs[OutputCombo.ItemIndex]);
    FInput.Start;
    ConnectButton.Caption := 'Disconnect';
    RequestButton.Enabled := True;
    StatusBar.SimpleText := 'Connected. The operation is read-only (RQ1).';
  except
    on E: Exception do
    begin
      Disconnect;
      StatusBar.SimpleText := E.Message;
    end;
  end;
end;

procedure TMidiPatchDumpForm.SendRequest(ADeviceId: Byte;
  const AAddress, ASize: array of Byte; const ABlockName: string);
var MessageBytes: TMidiBytes;
begin
  MessageBytes := BuildRolandRequest1(ADeviceId, $6A, AAddress, ASize);
  FOutput.Send(MessageBytes);
  DumpMemo.Lines.Add('TX RQ1 ' + ABlockName + ': ' + BytesToHex(MessageBytes));
  Sleep(25);
end;

procedure TMidiPatchDumpForm.RequestButtonClick(Sender: TObject);
var DeviceIdValue: Integer;
begin
  if (FInput = nil) or (FOutput = nil) then Exit;
  if not TryStrToInt('$' + Trim(DeviceIdEdit.Text), DeviceIdValue) or
     (DeviceIdValue < $10) or (DeviceIdValue > $1F) then
  begin
    StatusBar.SimpleText := 'Device ID must be hexadecimal 10 through 1F.';
    Exit;
  end;
  DumpMemo.Lines.Add('--- JV-2080 Temporary Patch request ---');
  try
    SendRequest(Byte(DeviceIdValue), [$03, $00, $00, $00],
      [$00, $00, $00, $4A], 'Common');
    SendRequest(Byte(DeviceIdValue), [$03, $00, $10, $00],
      [$00, $00, $01, $01], 'Tone 1');
    SendRequest(Byte(DeviceIdValue), [$03, $00, $12, $00],
      [$00, $00, $01, $01], 'Tone 2');
    SendRequest(Byte(DeviceIdValue), [$03, $00, $14, $00],
      [$00, $00, $01, $01], 'Tone 3');
    SendRequest(Byte(DeviceIdValue), [$03, $00, $16, $00],
      [$00, $00, $01, $01], 'Tone 4');
    StatusBar.SimpleText := 'Five RQ1 requests sent; waiting for DT1 responses.';
  except
    on E: Exception do StatusBar.SimpleText := E.Message;
  end;
end;

procedure TMidiPatchDumpForm.PollTimerTimer(Sender: TObject);
var Message: TMidiMessage;
begin
  if FInput = nil then Exit;
  while FInput.TryRead(Message) do
  begin
    if Message.Kind = mmSysEx then
      DumpMemo.Lines.Add('RX SysEx: ' + BytesToHex(Message.RawBytes))
    else
      DumpMemo.Lines.Add('RX ' + MidiMessageDescription(Message) + ': ' +
        BytesToHex(Message.RawBytes));
  end;
end;

procedure TMidiPatchDumpForm.ClearButtonClick(Sender: TObject);
begin
  DumpMemo.Clear;
end;

end.
