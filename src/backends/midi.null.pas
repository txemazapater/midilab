unit Midi.Null;

{$mode objfpc}{$H+}

interface

uses Midi.Core, Midi.Backend;

type
  TNullMidiBackend = class(TInterfacedObject, IMidiBackend)
  public
    function Name: string;
    function EnumerateInputs: TMidiEndpointArray;
    function EnumerateOutputs: TMidiEndpointArray;
    function OpenInput(const AEndpoint: TMidiEndpoint): IMidiInput;
    function OpenOutput(const AEndpoint: TMidiEndpoint): IMidiOutput;
  end;

implementation

function TNullMidiBackend.Name: string; begin Result := 'No MIDI backend'; end;
function TNullMidiBackend.EnumerateInputs: TMidiEndpointArray; begin SetLength(Result, 0); end;
function TNullMidiBackend.EnumerateOutputs: TMidiEndpointArray; begin SetLength(Result, 0); end;
function TNullMidiBackend.OpenInput(const AEndpoint: TMidiEndpoint): IMidiInput; begin Result := nil; end;
function TNullMidiBackend.OpenOutput(const AEndpoint: TMidiEndpoint): IMidiOutput; begin Result := nil; end;

end.
