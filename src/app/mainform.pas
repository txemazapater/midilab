unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, ComCtrls,
  Midi.Core, Midi.Backend;

type
  TMidiLabForm = class(TForm)
  private
    FBackend: IMidiBackend;
    FInputs, FOutputs: TMidiEndpointArray;
    FInput: IMidiInput;
    FOutput: IMidiOutput;
    FInputCombo, FOutputCombo: TComboBox;
    FConnectInput, FConnectOutput, FRefresh, FSend, FClear: TButton;
    FRawEdit: TEdit;
    FMonitor: TListView;
    FTimer: TTimer;
    FStatus: TStatusBar;
    procedure BuildUi;
    procedure RefreshDevices(Sender: TObject);
    procedure ToggleInput(Sender: TObject);
    procedure ToggleOutput(Sender: TObject);
    procedure SendRaw(Sender: TObject);
    procedure ClearMonitor(Sender: TObject);
    procedure PollInput(Sender: TObject);
    procedure AddMessage(const AMessage: TMidiMessage);
  public
    constructor CreateNew(AOwner: TComponent; Num: Integer = 0); override;
    destructor Destroy; override;
  end;

implementation

{$IFDEF WINDOWS}
uses Midi.WinMM;
{$ELSE}
uses Midi.Null;
{$ENDIF}

constructor TMidiLabForm.CreateNew(AOwner: TComponent; Num: Integer);
begin
  inherited CreateNew(AOwner, Num);
  Caption := 'MidiLab';
  Width := 980; Height := 620; Position := poScreenCenter;
  {$IFDEF WINDOWS} FBackend := TWinMMMidiBackend.Create;
  {$ELSE} FBackend := TNullMidiBackend.Create; {$ENDIF}
  BuildUi;
  RefreshDevices(nil);
end;

destructor TMidiLabForm.Destroy;
begin FInput := nil; FOutput := nil; FBackend := nil; inherited Destroy; end;

procedure TMidiLabForm.BuildUi;
var TopPanel, SendPanel: TPanel; L: TLabel;
begin
  TopPanel := TPanel.Create(Self); TopPanel.Parent := Self; TopPanel.Align := alTop; TopPanel.Height := 84;
  L := TLabel.Create(Self); L.Parent := TopPanel; L.Caption := 'MIDI input'; L.SetBounds(12, 10, 100, 20);
  FInputCombo := TComboBox.Create(Self); FInputCombo.Parent := TopPanel; FInputCombo.Style := csDropDownList; FInputCombo.SetBounds(12, 31, 300, 30);
  FConnectInput := TButton.Create(Self); FConnectInput.Parent := TopPanel; FConnectInput.Caption := 'Connect'; FConnectInput.SetBounds(320, 29, 90, 32); FConnectInput.OnClick := @ToggleInput;
  L := TLabel.Create(Self); L.Parent := TopPanel; L.Caption := 'MIDI output'; L.SetBounds(430, 10, 100, 20);
  FOutputCombo := TComboBox.Create(Self); FOutputCombo.Parent := TopPanel; FOutputCombo.Style := csDropDownList; FOutputCombo.SetBounds(430, 31, 300, 30);
  FConnectOutput := TButton.Create(Self); FConnectOutput.Parent := TopPanel; FConnectOutput.Caption := 'Connect'; FConnectOutput.SetBounds(738, 29, 90, 32); FConnectOutput.OnClick := @ToggleOutput;
  FRefresh := TButton.Create(Self); FRefresh.Parent := TopPanel; FRefresh.Caption := 'Refresh'; FRefresh.SetBounds(840, 29, 90, 32); FRefresh.OnClick := @RefreshDevices;

  SendPanel := TPanel.Create(Self); SendPanel.Parent := Self; SendPanel.Align := alBottom; SendPanel.Height := 78;
  L := TLabel.Create(Self); L.Parent := SendPanel; L.Caption := 'Raw hexadecimal MIDI'; L.SetBounds(12, 8, 180, 20);
  FRawEdit := TEdit.Create(Self); FRawEdit.Parent := SendPanel; FRawEdit.Text := 'B0 10 64'; FRawEdit.SetBounds(12, 31, 700, 30);
  FSend := TButton.Create(Self); FSend.Parent := SendPanel; FSend.Caption := 'Send'; FSend.SetBounds(720, 29, 90, 32); FSend.OnClick := @SendRaw;
  FClear := TButton.Create(Self); FClear.Parent := SendPanel; FClear.Caption := 'Clear'; FClear.SetBounds(820, 29, 90, 32); FClear.OnClick := @ClearMonitor;

  FStatus := TStatusBar.Create(Self); FStatus.Parent := Self; FStatus.Align := alBottom; FStatus.SimplePanel := True;
  FMonitor := TListView.Create(Self); FMonitor.Parent := Self; FMonitor.Align := alClient; FMonitor.ViewStyle := vsReport; FMonitor.ReadOnly := True; FMonitor.RowSelect := True;
  FMonitor.Columns.Add.Caption := 'UTC time'; FMonitor.Columns[0].Width := 110;
  FMonitor.Columns.Add.Caption := 'Dir'; FMonitor.Columns[1].Width := 45;
  FMonitor.Columns.Add.Caption := 'Raw bytes'; FMonitor.Columns[2].Width := 260;
  FMonitor.Columns.Add.Caption := 'Decoded'; FMonitor.Columns[3].Width := 430;
  FTimer := TTimer.Create(Self); FTimer.Interval := 20; FTimer.OnTimer := @PollInput; FTimer.Enabled := True;
end;

procedure TMidiLabForm.RefreshDevices(Sender: TObject);
var I: Integer;
begin
  if (FInput <> nil) or (FOutput <> nil) then begin FStatus.SimpleText := 'Disconnect endpoints before refreshing.'; Exit; end;
  FInputs := FBackend.EnumerateInputs; FOutputs := FBackend.EnumerateOutputs;
  FInputCombo.Clear; for I := 0 to High(FInputs) do FInputCombo.Items.Add(FInputs[I].Name);
  FOutputCombo.Clear; for I := 0 to High(FOutputs) do FOutputCombo.Items.Add(FOutputs[I].Name);
  if FInputCombo.Items.Count > 0 then FInputCombo.ItemIndex := 0;
  if FOutputCombo.Items.Count > 0 then FOutputCombo.ItemIndex := 0;
  FStatus.SimpleText := Format('%s: %d input(s), %d output(s)', [FBackend.Name, Length(FInputs), Length(FOutputs)]);
end;

procedure TMidiLabForm.ToggleInput(Sender: TObject);
begin
  try
    if FInput <> nil then begin FInput.Stop; FInput := nil; FConnectInput.Caption := 'Connect'; end
    else begin if FInputCombo.ItemIndex < 0 then Exit; FInput := FBackend.OpenInput(FInputs[FInputCombo.ItemIndex]); FInput.Start; FConnectInput.Caption := 'Disconnect'; end;
  except on E: Exception do FStatus.SimpleText := E.Message; end;
end;

procedure TMidiLabForm.ToggleOutput(Sender: TObject);
begin
  try
    if FOutput <> nil then begin FOutput := nil; FConnectOutput.Caption := 'Connect'; end
    else begin if FOutputCombo.ItemIndex < 0 then Exit; FOutput := FBackend.OpenOutput(FOutputs[FOutputCombo.ItemIndex]); FConnectOutput.Caption := 'Disconnect'; end;
  except on E: Exception do FStatus.SimpleText := E.Message; end;
end;

procedure TMidiLabForm.SendRaw(Sender: TObject);
var B: TMidiBytes; E: string; M: TMidiMessage;
begin
  if FOutput = nil then begin FStatus.SimpleText := 'Connect a MIDI output first.'; Exit; end;
  if not TryHexToBytes(FRawEdit.Text, B, E) then begin FStatus.SimpleText := E; Exit; end;
  try FOutput.Send(B); M := MidiMessageFromBytes(B, mdOutput, FOutput.Endpoint.Id); AddMessage(M);
  except on X: Exception do FStatus.SimpleText := X.Message; end;
end;

procedure TMidiLabForm.ClearMonitor(Sender: TObject); begin FMonitor.Items.Clear; end;
procedure TMidiLabForm.PollInput(Sender: TObject);
var M: TMidiMessage;
begin if FInput <> nil then while FInput.TryRead(M) do AddMessage(M); end;

procedure TMidiLabForm.AddMessage(const AMessage: TMidiMessage);
var Item: TListItem;
begin
  Item := FMonitor.Items.Add;
  Item.Caption := FormatDateTime('hh:nn:ss.zzz', AMessage.TimestampUtc);
  if AMessage.Direction = mdInput then Item.SubItems.Add('IN') else Item.SubItems.Add('OUT');
  Item.SubItems.Add(BytesToHex(AMessage.RawBytes));
  Item.SubItems.Add(MidiMessageDescription(AMessage));
  Item.MakeVisible(False);
end;

end.
