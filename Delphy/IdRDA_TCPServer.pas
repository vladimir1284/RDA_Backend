unit IdRDA_TCPServer;

interface

uses
  SysUtils, Classes, DateUtils, Contnrs, XMLIntf, XMLDoc,
  IdTCPServer, IdComponent,
  CODE_messages;

const
  Seconds_Without_Message = 30;
  Wait_for_ORPG           =  0;
  Wait_before_connecting  = 10;

type
  TIdRDA_TCPServer = class;

  TRDAEvent = procedure(Sender: TIdRDA_TCPServer) of object;

  TIdRDA_TCPServer = class(TIdTCPServer)
  private
    fLinkPassword     : string;
    fMsg              : array[1..31] of TMemoryStream;
    fMsg_Queue,
    fData_Queue       : TQueue;
    fRDA_Status       : TM_RDA_Status;
    fInstance,
    fsequence_number  : integer;
    fTimeOfLastMess   : TDateTime;
    fOnControlCommands,
    fOnVCP            : TRDAEvent;
    fConnected,
    fVerbose,
    fSendMetadata,
    fIsOpenRDA        : boolean;
    fRDA_Channel      : int1;
    fVCP_Table        : IXMLDocument;
    // Process protocol
    procedure Process_Requests     (Connection: TIdTCPServerConnection);
    procedure Process_Digital_Data (Connection: TIdTCPServerConnection);
    procedure Process_Message_Queue(Connection: TIdTCPServerConnection);
    // Process CTM
    procedure Process_Login    (CTM: TCTM_Header; Connection: TIdTCPServerConnection);
    procedure Process_Data     (CTM: TCTM_Header; Connection: TIdTCPServerConnection);
    procedure Process_KeppAlive(CTM: TCTM_Header; Connection: TIdTCPServerConnection);
    // Process Messages
    procedure Process_Control_Commands; // Message  6
    procedure Process_VCP;              // Message  7
    procedure Process_Request_Data;     // Message  9
    procedure Process_LoopBack_Test;    // Message 11
    procedure Send_Message(number: integer; Ack: boolean = false);
    //
    procedure SetMsg(ind: byte; S: TStream);
    procedure SetRDA_Status(aStatus: code2);
    procedure SetRDA_Channel(Channel: int1);
    function  Construc_Msg_Header(size: int2; m_type: int1; n_segments, segment_n: int2): TMessage_Header;
    function  Get_sequence_number: integer;
    function  GetMsg(ind: byte): TStream;
    function  GetRDA_Status: code2;
    function  GetVCP_Node(number: integer): IXMLNode;
    property  sequence_number: integer read Get_sequence_number;
    property  RDA_Status: code2 read GetRDA_Status write SetRDA_Status ;
  protected
    function DoExecute(AThread: TIdPeerThread): boolean; override;
    property MaxConnections;
  public
    constructor Create(AOwner: TComponent; instance: integer; verbose: boolean = false);
    destructor Destroy; override;
    function CreateVCP_Msg(number: integer): TMemoryStream;
    property Digital_Data: TQueue read fData_Queue write fData_Queue;
    property Msg[ind: byte]: TStream  read GetMsg write SetMsg; default;
    property IsOpenRDA: boolean read fIsOpenRDA;
    property VCP_Table: IXMLDocument read fVCP_Table;
    property RDA_Channel: int1 read fRDA_Channel write SetRDA_Channel;
  published
    property LinkPassword: string write fLinkPassword;
    property OnControlCommands: TRDAEvent read fOnControlCommands write fOnControlCommands;
    property OnVCP: TRDAEvent read fOnVCP write fOnVCP;
  end;

implementation

uses
  WinSock, utStr, TimeUtils, Math,
  Server_Manager;

function GetMessageName(msg: integer): string;
begin
  case msg of
     1:     result := 'Digital Radar Data';
     2:     result := 'RDA Status Data';
     3:     result := 'Performance/Maintenance Data';
     4, 10: result := 'Console Mensaje';
    11, 12: result := 'Loopback Test';
    13:     result := 'Clutter Filter Bypass Map';
     6:     result := 'RDA Control Commands';
     5,  7: result := 'Volume Coverage Pattern';
     8:     result := 'Clutter Sensor Zones';
     9:     result := 'Request for Data';
    15:     result := 'Clutter Filter Map';
    18:     result := 'RDA Adaptation Data';
    31:     result := 'Digital Radar Data Generic Format Blocks';
    else
      result := 'Unknow message';
  end;
end;

function TIdRDA_TCPServer.Get_sequence_number: integer;
begin
  Inc(fsequence_number);
  if fsequence_number = $8000 then
    fsequence_number := 0;
  result := fsequence_number;
end;

function TIdRDA_TCPServer.Construc_Msg_Header(size: int2; m_type: int1; n_segments, segment_n: int2): TMessage_Header;
var
  jd, mo: int4;
begin
  DateTimeToJulianDate_msec(Now, jd, mo);
  with Result do
    begin
      message_size               := size;
      RDA_redundant_channel      := fRDA_Channel;
      message_type               := m_type;
      id_sequence_number         := sequence_number;
      julian_date                := jd;
      milliseconds_of_day        := mo;
      number_of_message_segments := n_segments;
      message_segment_number     := segment_n;
    end;
end;

constructor TIdRDA_TCPServer.Create;

  procedure DecodeDateTime(aDateTime: TDateTime; out j_date, m_secof: int4);
  begin
    aDateTime := LocalTimeToZTime(aDateTime);
    j_date    := DaysBetween(EncodeDateTime(1970, 1, 1, 0, 0, 0, 0), aDateTime);
    m_secof   := MilliSecondsBetween(RecodeTime(aDateTime, 0, 0, 0, 0), aDateTime);
  end;

var
  i: integer;
  LBT: TM_Loop_Back_Test;
begin
  inherited Create(AOwner);
  MaxConnections := 1;
  fMsg_Queue       := TQueue.Create;
  fData_Queue      := TQueue.Create;
  fsequence_number := 0;
  fTimeOfLastMess  := Now;
  fConnected       := false;
  fVerbose         := verbose;
  fVCP_Table       := NewXMLDocument;
  fInstance        := instance;
  fVCP_Table.LoadFromFile(Base_FileName + '_' + IntToStr(fInstance) + '.vcp.xml');

  // Initialize RDA Status Message
  FillChar(fRDA_Status, SizeOf(fRDA_Status), 0);
  with fRDA_Status do
    begin
      RDA_status                          := RDS_STANDBY;
      operability_status                  := ROS_RDA_ONLINE;
      control_status                      := RCS_RDA_EITHER;
      auxiliary_power_generator_status    := APGS_UTILITY_PWR_AVAILABLE;
      average_transmiter_power            := $0582;
      data_transmision_enabled            := DTE_NONE_ENABLED;
      vcp_number                          := 51;
      RDA_control_authorization           := RCA_NO_ACTION;
      operational_mode                    := ROM_OPERATIONAL;
      super_resolution_status             := 0;
      spare_1[14]                         := 1; // legacy
      RDA_alarm_summary                   := 0;
      command_acknowledgment              := CA_NO_ACKNOWLEDGEMENT;
      channel_control_status              := 0;
      spot_blanking_status                := SBS_NOT_INSTALLED;
      reflectivity_calibration_correction := 0; //
      RDA_build_number                    := 1120; // 11.20
      rms_control_status                  := 0;
      for i := 0 to 13 do
        alarm_codes[i] := 0;
    end;
  fMsg[2] := TMemoryStream.Create;

  // Initialize VCP data
  fMsg[5] := CreateVCP_Msg(fVCP_Table.DocumentElement.ChildNodes.FindNode('vcp').Attributes['pattern_number']);

  // Initialize LoopBack Test Data
  with LBT do
    begin
      message_size := 50;
      for i := 0 to message_size - 1 do
        bit_pattern[i] := i;
    end;
  CBO_LoopBackTest(LBT);
  fMsg[11] := TMemoryStream.Create;
  fMsg[11].Write(LBT, 52);
end;

destructor TIdRDA_TCPServer.Destroy;
var
  i: integer;
begin
  fMsg_Queue.Free;
  fData_Queue.Free;
  for i := 1 to 31 do
    if Assigned(fMsg[i]) then
      fMsg[i].Free;
  inherited;
end;

function TIdRDA_TCPServer.DoExecute(AThread: TIdPeerThread): boolean;
begin
  result := inherited DoExecute(AThread);
  try
    while AThread.Connection.Connected do
      begin
      // Get and process request from ORPG
        Process_Requests(AThread.Connection);
      // Enqueue digital data
        Process_Digital_Data(AThread.Connection);
      // Send one message from queue
      if fConnected then
        Process_Message_Queue(AThread.Connection);
      end;
  except
    on E: Exception do
      begin
        if fVerbose then
          begin
            WriteLn;
            WriteLn(E.message);
            WriteLn('RDA =|= ORPG not connected.');
            WriteLn;
            fConnected := false;
          end;
      end;
  end;
end;

procedure TIdRDA_TCPServer.Process_Requests;
var
  CTM: TCTM_Header;
begin
  with Connection do
    if ReadFromStack(false, 1, false) >= SizeOf(CTM) then
      begin
        ReadBuffer(CTM, SizeOf(CTM));
        CBO_CTMHeader(CTM);
        fTimeOfLastMess := Now;
        case CTM.typ of
          0 : Process_Login(CTM, Connection);       // login request
          1 : ;                                     // login acknowledgement
          2 : if fConnected then
                Process_Data (CTM, Connection);     // data
          3 : ;                                     // data acknowledgement
          4 : if fConnected then
                Process_KeppAlive(CTM, Connection); // kepp alive
          else
            ; // Unknow CTM
        end;
      end
end;

procedure TIdRDA_TCPServer.Process_Digital_Data;
var
  DH: TM_Data_Header;
  DGH: TM_Data_Generic_Header;
  S: TMemoryStream;
  dm, rs: integer;
begin
  if fData_Queue.Count > 0 then
    begin
      if RDA_Status = RDS_STANDBY then
        begin
          RDA_Status := RDS_OPERATE;
          exit;
        end;
      S := fData_Queue.Pop;
      with S do
        begin
          Seek(0, soFromBeginning);
          if fIsOpenRDA then
            begin
              dm := 31;
              Read(DGH, SizeOf(DGH));
              CBO_DataGenericHeader(DGH);
              rs := DGH.radial_status;
            end
          else
            begin
              dm := 1;
              Read(DH, SizeOf(DH));
              CBO_DataHeader(DH);
              rs := DH.radial_status;
            end;
          // New volume, send metadata
          if rs = 3 then
            begin
              Send_Message(2);
              Send_Message(3);
              Send_Message(5);
            end;
          Msg[dm] := S;
          Send_Message(dm);
        end;
    end;
end;

procedure TIdRDA_TCPServer.Process_Login(CTM: TCTM_Header; Connection: TIdTCPServerConnection);
var
  s: string;
  buf: pointer;
begin
  with CTM, Connection do
    begin
      GetMem(buf, len);
      ReadBuffer(buf^, len);
      if GetStringItem(pchar(buf) + ' ', ' ', 3) = fLinkPassword then
        begin
          s := GetStringItem(pchar(buf), ' ', 0) + ' ' +
               GetStringItem(pchar(buf), ' ', 1) + ' connected';
          typ := 1;
          len := Length(s);
          CBO_CTMHeader(CTM);
          Sleep(Wait_before_connecting);
          WriteBuffer(CTM, SizeOf(CTM));
          WriteBuffer(pchar(s)^, Length(s));
          fConnected := true;
          RDA_Status := RDS_STANDBY;
          Send_Message(11); // do LoopBackTest
          fSendMetadata := true;
        end;
    end;
  if fConnected and fVerbose then
    begin
      WriteLn('RDA === RPG sucessfull connected.');
      WriteLn;
    end;
end;

procedure TIdRDA_TCPServer.Process_Data(CTM: TCTM_Header; Connection: TIdTCPServerConnection);
var
  S: TMemoryStream;
  MH: TMessage_Header;
begin
  with Connection do
    begin
      ReadBuffer(MH, SizeOf(MH));
      CBO_Header(MH);
      S := TMemoryStream.Create;
      ReadStream(S, MH.message_size*2 - SizeOf(MH));
      Msg[MH.message_type] := S;
      // Send data Acknowledgement
      if CTM.par <> 0 then
        begin
          CTM.typ := 3;
          CTM.len := 0;
          CBO_CTMHeader(CTM);
          WriteBuffer(CTM, SizeOf(TCTM_Header));
        end;
    end;
  if fVerbose then
    WriteLn('Instance: ', fInstance:2, '  message recv: ', MH.message_type:2, ' <- ', GetMessageName(MH.message_type), ' ', DateTimeToStr(Now));
  case MH.message_type of
    6 : Process_Control_Commands;
    7 : Process_VCP;
    8 : ;                         // to do. Clutter Censor Zones
    9 : Process_Request_Data;
    10: ;                         // to do. Console Message
    11: Process_LoopBack_Test;
    12: Send_Message(12);
  end;
end;

procedure TIdRDA_TCPServer.Process_KeppAlive(CTM: TCTM_Header; Connection: TIdTCPServerConnection);
begin
  CBO_CTMHeader(CTM);
  Connection.WriteBuffer(CTM, SizeOf(TCTM_Header));
end;

procedure TIdRDA_TCPServer.Send_Message(number: integer; Ack: boolean = false);
var
  CTM: TCTM_Header;
  MH: TMessage_Header;
  buffer: pointer;
  M_Size, M_Count, i, transf: integer;
  S: TMemoryStream;
begin
  Sleep(1);
  GetMem(buffer, cMessageFullSize - SizeOf(TCTM_Header));
  fMsg[number].Seek(0, soFromBeginning);
  M_Size  := cMessageFullSize - SizeOf(TCTM_Header) - SizeOf(TMessage_Header) + 1;
  M_Count := (fMsg[number].Size div M_Size) + 1;
  for i := 0 to M_Count - 1 do
    begin
      S := TMemoryStream.Create;
      transf := fMsg[number].Read(buffer^, M_Size);
      MH := Construc_Msg_Header((transf + SizeOf(TMessage_Header)) div 2, number, M_Count, i + 1);
      CTM.typ := 2;
      if Ack then
        CTM.par := MH.id_sequence_number
      else
        CTM.par := 0;
      CTM.len := SizeOf(TMessage_Header) + transf;
      CBO_CTMHeader(CTM);
      CBO_Header(MH);
      S.Write(CTM, SizeOf(TCTM_Header));
      S.Write(MH, SizeOf(TMessage_Header));
      S.Write(buffer^, transf);
      fMsg_Queue.Push(S);
    end;
  FreeMem(buffer);
  Sleep(1);
end;

procedure TIdRDA_TCPServer.Process_Message_Queue;
var
  S: TMemoryStream;
  number: int1;
begin
  with fMsg_Queue do
    if Count > 0 then
      begin
        S := Pop;
        Connection.WriteStream(S);
        S.Position := 15;
        S.Read(number, 1);
        S.Free;
        if fVerbose then
          WriteLn('Instance: ', fInstance:2, '  message send: ', number:2, ' -> ', GetMessageName(number), ' ', DateTimeToStr(Now));
        fTimeOfLastMess := Now;
        if (number = 11) then
          Sleep(Wait_for_ORPG); // wait for ORPG loopback response
      end
    else if SecondsBetween(fTimeOfLastMess, Now) > Seconds_Without_Message then
      begin
        if RDA_Status = RDS_OPERATE then
          RDA_Status := RDS_STANDBY
        else
         // Send_Message(11); // do LoopBackTest
      end;
end;

procedure TIdRDA_TCPServer.SetRDA_Status(aStatus: code2);
begin
  fRDA_Status.RDA_status := aStatus;
  CBO_RDAStatus(fRDA_Status);
  fMsg[2].Seek(0, soFromBeginning);
  fMsg[2].Write(fRDA_Status, SizeOf(fRDA_Status));
  CBO_RDAStatus(fRDA_Status);
  Send_Message(2);
end;

function TIdRDA_TCPServer.GetRDA_Status: code2;
begin
  result := fRDA_Status.RDA_status
end;

function TIdRDA_TCPServer.GetVCP_Node(number: integer): IXMLNode;
var
  i: integer;
  N: IXMLNode;
begin
  result := nil;
  with fVCP_Table.DocumentElement.ChildNodes do
    begin
      for i := 0 to Count - 1 do
        begin
          N := Nodes[i];
          if (N.LocalName = 'vcp') and (N.Attributes['pattern_number'] = number) then
            begin
              result := N;
              exit;
            end;
        end;
    end;
  raise Exception.Create('No vcp ' + IntToStr(number) + ' definition.');
end;

function TIdRDA_TCPServer.CreateVCP_Msg(number: integer): TMemoryStream;
var
  VCPHeader: TM_VCP_Header;
  VCPElevation: TM_VCP_Elevation;
  i: integer;
  VCP_Node, Elevation_Node: IXMLNode;
begin
  result := TMemoryStream.Create;
  VCP_Node := GetVCP_Node(number);
  with VCPHeader, VCP_Node do
    begin
      message_size                := (SizeOf(TM_VCP_Header) + SizeOf(TM_VCP_Elevation) * Attributes['number_of_elevation_cuts']) div 2;
      pattern_type                := Attributes['pattern_type'];
      pattern_number              := Attributes['pattern_number'];
      number_of_elevation_cuts    := Attributes['number_of_elevation_cuts'];
      clutter_map_group_number    := Attributes['clutter_map_group_number'];
      doppler_velocity_resolution := Attributes['doppler_velocity_resolution'];
      pulse_width                 := Attributes['pulse_width'];
    end;
  CBO_VCPHeader(VCPHeader);
  result.Write(VCPHeader, SizeOf(TM_VCP_Header));
  with VCPElevation do
    for i := 1 to VCP_Node.Attributes['number_of_elevation_cuts'] do
      begin
        Elevation_Node := VCP_Node.ChildNodes.FindSibling(VCP_Node, i + 1);
        FillChar(VCPElevation, SizeOf(TM_VCP_Elevation), 0);
        with Elevation_Node do
          begin
            elevation_angle                        := Convert_data_out(Attributes['angle'], ANGULAR_ELEV_DATA);
            channel_configuration                  := Attributes['channel_configuration'];
            waveform_type                          := Attributes['waveform_type'];
            super_resolution_control               := Attributes['super_resolution_control'];
            surveillance_prf_number                := Attributes['surveillance_prf_number'];
            surveillance_prf_pulse_count_by_radial := Attributes['surveillance_prf_pulse_count_by_radial'];
            azimuth_rate                           := Attributes['azimuth_rate'];
            reflectivity_threshold                 := Attributes['reflectivity_threshold'];
            velocity_threshold                     := Attributes['velocity_threshold'];
            spectrum_width_threshold               := Attributes['spectrum_width_threshold'];
            CBO_VCPElevation(VCPElevation);
            result.Write(VCPElevation, SizeOf(TM_VCP_Elevation));
          end;
      end;
end;

procedure TIdRDA_TCPServer.SetRDA_Channel(Channel: int1);
begin
  fRDA_Channel := Channel;
  fIsOpenRDA   := (fRDA_Channel and $8) > 0;
end;

procedure TIdRDA_TCPServer.SetMsg(ind: byte; S: TStream);
var
  d, t: int2;
begin
  if Assigned(fMsg[ind]) then
    FreeAndNil(fMsg[ind]);
  fMsg[ind] := TMemoryStream(S);
  if ind = 13 then      // Clutter Filter Bypass Map.
    with fMsg[13], fRDA_Status do
      begin
        Seek(0, soFromBeginning);
        Read(d, 2);
        Read(t, 2);
        clutter_filter_map_generation_date := ntohs(d);
        clutter_filter_map_generation_time := ntohs(t);
      end
  else if ind = 15 then // Clutter Filter Map.
    with fMsg[15], fRDA_Status do
      begin
        Seek(0, soFromBeginning);
        Read(d, 2);
        Read(t, 2);
        bypass_map_generation_date := ntohs(d);
        bypass_map_generation_time := ntohs(t);
      end;
end;

function TIdRDA_TCPServer.GetMsg(ind: byte): TStream;
begin
  result := fMsg[ind];
end;

procedure TIdRDA_TCPServer.Process_Request_Data;
var
  R_Type: code2;
begin
  fMsg[9].Seek(-2, soFromEnd);
  fMsg[9].Read(R_Type, 2);
    case ntohs(R_Type) of
      129: Send_Message( 2); // Request Sumary RDA Status
      130: Send_Message( 3); // Request RDA Performance/Maintenance Data
      132: Send_Message(13); // Request Clutter Filter Bypass Map
      136: Send_Message(15); // Request Clutter Filter Map
      144: Send_Message(18); // Request RDA Adaptation Data
      160: Send_Message( 5); // Request Volume Coverage Pattern Data
    end;
end;

procedure TIdRDA_TCPServer.Process_Control_Commands;
var
  Commands: TM_RDA_Control_Commands;
  changed: boolean;
begin
  fMsg[6].Seek(0, soFromBeginning);
  fMsg[6].Read(Commands, SizeOf(Commands));
  CBO_RDAControlCommands(Commands);
  changed := false;
  if Assigned(OnControlCommands) then
    OnControlCommands(Self)
  else
    with Commands do
      begin
        if base_data_transmission_enable > 0 then
          begin
            fRDA_Status.data_transmision_enabled := (base_data_transmission_enable - 32768 + 1) shr 1;
            changed := true;
          end;
        if auxiliary_power_generator_control > 0 then
          begin
            fRDA_Status.auxiliary_power_generator_status := auxiliary_power_generator_control;
            changed := true;
          end;
        if RDA_control_commands_and_authorization > 0 then
          begin
            fRDA_Status.rda_control_authorization := rda_control_commands_and_authorization;
            changed := true;
          end;
        if restart_vcp_or_elevation_cut > 0 then
          begin
            // to do
            changed := true;
          end;
        if (select_local_vcp_number_for_next_volume_scan >= 1) and
           (select_local_vcp_number_for_next_volume_scan <= 767) then
          begin
            fRDA_Status.vcp_number := select_local_vcp_number_for_next_volume_scan;
            changed := true;
          end;
        if automatic_calibration_override <> 32767 then
          begin
            // to do
            changed := true;
          end;
        if super_resolution_control > 0 then
          begin
            fRDA_Status.super_resolution_status := super_resolution_control;
            changed := true;
          end;
        if select_operating_mode > 0 then
          begin
            fRDA_Status.operational_mode := select_operating_mode;
            changed := true;
          end;
        if channel_control_command > 0 then
          begin
            fRDA_Status.channel_control_status := channel_control_command;
            changed := true;
          end;
        if spot_blanking > 0 then
          begin
            fRDA_Status.spot_blanking_status := spot_blanking;
            changed := true;
          end;
        if RDA_State_Command > 0 then
          begin
            case RDA_State_Command of
              32769: fRDA_Status.RDA_status := RDS_STANDBY;
              32770: fRDA_Status.RDA_status := RDS_OFFLINE_OPERATE;
              32772: fRDA_Status.RDA_status := RDS_OPERATE;
              32776: fRDA_Status.RDA_status := RDS_RESTART;
            end;
            changed := true;
          end;
        if changed then
          RDA_Status := RDA_Status;
      end;
end;

procedure TIdRDA_TCPServer.Process_VCP;
var
  vcp: int2;
begin
  fMsg[7].Seek(4, soFromBeginning);
  fMsg[7].Read(vcp, 2);
  fRDA_Status.vcp_number := ntohs(vcp);
  if Assigned(OnVCP) then
    OnVCP(Self);
  fRDA_Status.command_acknowledgment := CA_REMOTE_VCP_RECEIVED;
  RDA_Status := RDA_status;
  fRDA_Status.command_acknowledgment := CA_NO_ACKNOWLEDGEMENT;
end;

procedure TIdRDA_TCPServer.Process_LoopBack_Test;
begin
  // to do. Check loopback response data.
  ;
  if fSendMetadata then
    begin
      // Send Metadata upon wideband connection
      Send_Message(2);
      Send_Message(3);
      Send_Message(5);
      Send_Message(13);
      Send_Message(15);
      Send_Message(18);
      fSendMetadata := false;
    end;
end;

end.
