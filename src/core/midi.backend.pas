unit Midi.Backend;

{$mode objfpc}{$H+}
interface

uses Midi.Core;

type
  IMidiInput = interface
    ['{53E1DAAC-7C83-49A4-9465-B70F09B4616E}']
    procedure Start;
    procedure Stop;
    function Endpoint: TMidiEndpoint;
    function TryRead(out AMessage: TMidiMessage): Boolean;
  end;

  IMidiOutput = interface
    ['{9B32B7D2-3827-44C4-BEAF-7FA9EF192483}']
    procedure Send(const ABytes: array of Byte);
    function Endpoint: TMidiEndpoint;
  end;

  IMidiBackend = interface
    ['{00D86B90-BA83-4C08-B858-ABF23FCD50E1}']
    function Name: string;
    function EnumerateInputs: TMidiEndpointArray;
    function EnumerateOutputs: TMidiEndpointArray;
    function OpenInput(const AEndpoint: TMidiEndpoint): IMidiInput;
    function OpenOutput(const AEndpoint: TMidiEndpoint): IMidiOutput;
  end;

implementation

end.
