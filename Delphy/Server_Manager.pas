unit Server_Manager;

interface

uses
  Classes, SysUtils, XMLIntf, XMLDoc, Contnrs, Registry, xmldom,
  CODE_messages,
  IdRDA_TCPServer, IdRDA_ObsServer;

const
  Base_FileName  = 'RDA_Backend';
  Instances_File = Base_FileName + '.service.xml';

  Open_RDA_Mask   = $8; // Bit 4 on RDA_Channel
  Legacy_RDA_Mask = $0; //

type
  TServer_Manager = class (TThread)
  private
    fRDA_TCPServer: TIdRDA_TCPServer;
    fRDA_ObsServer: TIdRDA_ObsServer;
    fConf: IXMLDocument;
    fInstance: integer;
    function Create_CFBM: TMemoryStream;
    function Create_CFM: TMemoryStream;
  public
    constructor Create(instance: integer; verbose: boolean = false);
    destructor Destroy; override;
    procedure Execute; override;
    procedure Start;
    procedure Stop;
  property
    Instance: integer read fInstance;
  end;

  TServer_Manager_List = class(TObjectList)
    fInstances_Conf: IXMLDocument;
    constructor Create(verbose: boolean = false);
    procedure Start;
    procedure Stop;
  end;

implementation

constructor TServer_Manager_List.Create;
var
  i, c : integer;
  XML_1, XML_2: IXMLDocument;
begin
  // Load configuration file
  fInstances_Conf := NewXMLDocument;
  fInstances_Conf.LoadFromFile(Instances_File);
  c := fInstances_Conf.DocumentElement.Attributes['instances'];

  // Create Instances
  XML_1 := NewXMLDocument;
  XML_2 := NewXMLDocument;
  for i := 0 to c - 1 do
    try
      XML_1.LoadFromFile(Base_FileName + '_' + IntToStr(i) + '.conf.xml');
      XML_2.LoadFromFile(Base_FileName + '_' + IntToStr(i) +  '.vcp.xml');
      Add(TServer_Manager.Create(i, verbose));
    except
      on E: EDOMParseError do ;
    end;
end;

procedure TServer_Manager_List.Start;
var
  i: integer;
begin
  for i := 0 to count - 1 do
    TServer_Manager(Items[i]).Resume;
end;

procedure TServer_Manager_List.Stop;
var
  i: integer;
begin
  for i := 0 to count - 1 do
    TServer_Manager(Items[i]).Stop
end;

constructor TServer_Manager.Create;
var
  i: integer;
  f: TFileStream;
  filedir: string;
  Dummy_Msg: TMemoryStream;
begin
  fInstance := instance;

  // Load configuration file
  fConf := NewXMLDocument;
  fConf.LoadFromFile(Base_FileName + '_' + IntToStr(fInstance) + '.conf.xml');

  // Create the servers
  fRDA_TCPServer := TIdRDA_TCPServer.Create(nil, fInstance, verbose);
  fRDA_ObsServer := TIdRDA_ObsServer.Create(nil);

  // Configure RDA_TCPServer
  with fRDA_TCPServer, fConf.DocumentElement.ChildNodes['RDA_TCPServer'] do
    begin
      DefaultPort  := Attributes['port'];
      LinkPassword := Attributes['password'];
      RDA_Channel  := 0 or Open_RDA_Mask;  // Always use Open RDA configuration

      // Load Dummy Messages
      filedir := ExtractFilePath(ParamStr(0));
      with fConf.DocumentElement.ChildNodes['RDA_Dummy_Message_Files'] do
      for i := 0 to ChildNodes.Count - 1 do
        with ChildNodes[i] do
          if (LocalName = 'message') and
             HasAttribute('file') and
             FileExists(filedir + Attributes['file']) then
            begin
              f := TFileStream.Create(filedir + Attributes['file'], fmOpenRead);
              Dummy_Msg := TMemoryStream.Create;
              Dummy_Msg.LoadFromStream(f);
              f.Free;
              Msg[Attributes['number']] := Dummy_Msg;
            end;

      // if no Dummy, initialize Clutter Filter Messages
      if not Assigned(Msg[13]) then
        Msg[13] := Create_CFBM;
      if not Assigned(Msg[15]) then
        Msg[15] := Create_CFM;

    end;

  // Configure ObsServer
  with fRDA_ObsServer, fConf.DocumentElement.ChildNodes['RDA_ObsServer'] do
    begin
      DefaultPort        := Attributes['port'];
      Use_VCP_Table      := Attributes['use_vcp_table'];
      Default_VCP_Number := Attributes['default_vcp_number'];
      DataMessageDelay   := Attributes['delay_of_data'];
    end;

  // Connect the servers
  fRDA_ObsServer.RDA_Connection := fRDA_TCPServer;
  inherited Create(false);
end;

destructor TServer_Manager.Destroy;
begin
  Stop;
  fRDA_TCPServer.Free;
  fRDA_ObsServer.Free;
  inherited;
end;

procedure TServer_Manager.Execute;
begin
  Start;
  while not Terminated do
    Sleep(1);
end;

procedure TServer_Manager.Start;
begin
  fRDA_TCPServer.Active := true;
  fRDA_ObsServer.Active := true;
end;

procedure TServer_Manager.Stop;
begin
  fRDA_TCPServer.Active := false;
  fRDA_ObsServer.Active := false;
  Terminate;
end;

function TServer_Manager.Create_CFBM: TMemoryStream;
var
  Header: TM_Clutter_Filter_Bypass_Map_Header;
  Segment: TM_Clutter_Filter_Bypass_Map_Segment;
  jd, mo: int2;
  i, j, k: integer;
begin
  result := TMemoryStream.Create;
  with Header do
    begin
      DateTimeToJulianDate_min(Now, jd, mo);
      generation_date    := jd;
      generation_time    := mo;
      number_of_segments := 1;
    end;
  CBO_CFBMHeader(Header);
  result.Write(Header, SizeOf(Header));
  CBO_CFBMHeader(Header);
  for k := 0 to Header.number_of_segments - 1 do
    with Segment do
      begin
        segment_number := k + 1;
        for i := 1 to 360 do
          for j := 0 to 31 do
            range_bins[i, j] := $FF;
        CBO_CFBMSegment(Segment);
        result.Write(Segment, SizeOf(Segment));
      end;
end;

function TServer_Manager.Create_CFM: TMemoryStream;
var
  Header: TM_Clutter_Filter_Map_Header;
  Segment: TM_Clutter_Filter_Map_Azimuth_Segment;
  Range_Zone: TM_Clutter_Filter_Map_Range_Zone;
  i, j, k: integer;
  jd, mo: int2;
begin
  result := TMemoryStream.Create;
  with Header do
    begin
      DateTimeToJulianDate_min(Now, jd, mo);
      generation_date := jd;
      generation_time := mo;
      number_of_elevation_segments := 1;
      CBO_CFMHeader(Header);
      result.Write(Header, SizeOf(Header));
      CBO_CFMHeader(Header);
      for k := 0 to Header.number_of_elevation_segments - 1 do
        begin
          for i := 1 to 360 do  // 360 azimuth segments
            with Segment do
              begin
                number_of_range_zones := 1;
                CBO_CFMSegment(Segment);
                result.Write(Segment, SizeOf(Segment));
                CBO_CFMSegment(Segment);
                for j := 0 to number_of_range_zones - 1 do
                  begin
                    with Range_Zone do
                      begin
                        op_code   := 0; // Bypass Filter
                        end_range := 10;
                      end;
                    CBO_CFMRangeZone(Range_Zone);
                    result.Write(Range_Zone, SizeOf(Range_Zone));
                  end;
              end;
        end;
    end;
end;

end.
