program MidiLab;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, MainForm;

var Form: TMidiLabForm;
begin
  Application.Title := 'MidiLab';
  Application.Initialize;
  Form := TMidiLabForm.CreateNew(Application);
  Application.Run;
end.
