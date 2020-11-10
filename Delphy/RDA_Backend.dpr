program RDA_Backend;

{$DEFINE SERVICE} // If define SERVICE, compile as service,
                  // else compile as console application.

uses
  SvcMgr,
  SysUtils,
  Classes,
  IdRDA_TCPServer in 'IdRDA_TCPServer.pas',
  IdRDA_ObsServer in 'IdRDA_ObsServer.pas',
  RDA_Backend_ServiceForm in 'RDA_Backend_ServiceForm.pas' {RDA_Backend_Service: TService},
  Server_Manager in 'Server_Manager.pas';

{$IFNDEF SERVICE}
{$APPTYPE CONSOLE}
var
  Server_List: TServer_Manager_List;
{$ENDIF}

begin
{$IFDEF SERVICE}
  Application.Initialize;
  Application.Title := 'RDA_Backend';
  Application.CreateForm(TRDA_Backend_Service, RDA_Backend_Service);
  Application.Run;
{$ELSE}
  Server_List := TServer_Manager_List.Create(true);
  Server_List.Start;
  WriteLn('RDA_Backend'#10#13);
  WriteLn('^C to quit...'#10#13);
  // loop forever
  while true do
    Sleep(1);
{$ENDIF}
end.
