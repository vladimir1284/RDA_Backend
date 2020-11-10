unit RDA_Backend_ServiceForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, SvcMgr, Dialogs, ActiveX,
  Server_Manager;

type
  TRDA_Backend_Service = class(TService)
    procedure ServicePause(Sender: TService; var Paused: Boolean);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    procedure ServiceContinue(Sender: TService; var Continued: Boolean);
  private
    fServer_List: TServer_Manager_List;
  public
    function GetServiceController: TServiceController; override;
  end;

var
  RDA_Backend_Service: TRDA_Backend_Service;

implementation

uses ComObj;

{$R *.DFM}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  RDA_Backend_Service.Controller(CtrlCode);
end;

function TRDA_Backend_Service.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TRDA_Backend_Service.ServicePause(Sender: TService;
  var Paused: Boolean);
begin
  fServer_List.Stop;
end;

procedure TRDA_Backend_Service.ServiceStart(Sender: TService;
  var Started: Boolean);
begin
  CoInitialize(nil);
  fServer_List := TServer_Manager_List.Create;
  fServer_List.Start;
end;

procedure TRDA_Backend_Service.ServiceStop(Sender: TService;
  var Stopped: Boolean);
begin
  fServer_List.Stop;
end;

procedure TRDA_Backend_Service.ServiceContinue(Sender: TService;
  var Continued: Boolean);
begin
  fServer_List.Start;
end;

end.
