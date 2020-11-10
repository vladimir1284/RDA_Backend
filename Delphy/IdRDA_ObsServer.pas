unit IdRDA_ObsServer;

interface

uses
  Classes, Contnrs, DateUtils, SysUtils, Math, WinSock, XMLIntf, XMLDoc,
  IdTCPServer, IdRDA_TCPServer,
  VestaTranslator, Code_Messages, Angle, Description, Radars,
  Movement, Scan, Measure, Plane;

const
  // Until ORPG 12.2 the range sample interval accuracy is 250 meters
  // but ICD defines 50 meters, so I think this will corrected on new versions.

  RSI_ACCURACY = 250; // Range Sample Interval Accuracy (meters)

  // May 12, 2012. Range Sample Interval set to 1 km. !!! (needs more understanding about super resolution)

type
  TCellA = array[0..4000] of byte;

  TIdRDA_ObsServer = class(TIdTCPServer)
  private
    fStream            : TMemoryStream;
    fTranslator        : TVestaTranslator;
    fRDA_Connection    : TIdRDA_TCPServer;
    fQueue_Capacity    : integer;
    fUse_VCP_Table     : boolean;
    fDefault_VCP_Number: int2;
    fDataMessageDelay  : integer;
    fSector_Count      : integer;
  protected
    procedure DoDisconnect(AThread: TIdPeerThread);       override;
    function  DoExecute(AThread: TIdPeerThread): boolean; override;
    //
    function  VCP_Number: integer;
    function  CreateVCP_Msg: TMemoryStream;
    function  RadarId: TRadarId;
    procedure Parse_Obs_Message31; virtual; // Open RDA
    procedure SetSize(var Channel: TChannelDesc; var Moment: TM_Data_Generic_Moment);
    procedure AdjustRay(ray: integer; var aScan: TScan; Moment: TM_Data_Generic_Moment; var data: TCellA);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy;                     override;
    property Use_VCP_Table: boolean write fUse_VCP_Table;
    property Default_VCP_Number: int2 write fDefault_VCP_Number;
    property DataMessageDelay: integer write fDataMessageDelay;
    property RDA_Connection: TIdRDA_TCPServer write fRDA_Connection;
    property Queue_Capacity: integer read fQueue_Capacity write fQueue_Capacity default 100;
  end;

implementation

uses
  Server_Manager, Translator;

constructor TIdRDA_ObsServer.Create;
begin
  inherited Create(AOwner);
  MaxConnections  := 1;
  fQueue_Capacity := 1;
  fStream         := TMemoryStream.Create;
  fTranslator     := TVestaTranslator.CreateTranslator;
end;

destructor TIdRDA_ObsServer.Destroy;
begin
  fStream.Free;
  fTranslator.Free;
  inherited;
end;

function TIdRDA_ObsServer.DoExecute(AThread: TIdPeerThread): boolean;
begin
  inherited DoExecute(AThread);
  with AThread.Connection do
    if Connected then
      begin
        fStream.Size := 0;
        ReadStream(fStream, -1, true);
        result := true;
      end;
  result := true;
end;

procedure TIdRDA_ObsServer.DoDisconnect(AThread: TIdPeerThread);
begin
  inherited DoDisconnect(AThread);

  fTranslator.OpenFromStream(fStream);

  if fUse_VCP_Table then
    // Create VCP message from RDA_Backend.vcp.xml configuration file
    // The VCP_Number is selected from observation "design"
    // This is to use automatic VCP change and mode selection (algorithm) from ORPG.
    fRDA_Connection.Msg[5] :=  fRDA_Connection.CreateVCP_Msg(VCP_Number)
  else
    // Create VCP from actual obs.
    // Use "default_vcp_number" option from RDA_Backend.conf.xml configuration file.
    // Always use default mode from ORPG (precipitation)
    fRDA_Connection.Msg[5] :=  CreateVCP_Msg;

  if fRDA_Connection.IsOpenRDA then
    Parse_Obs_Message31;

  fTranslator.Close;
end;

procedure TIdRDA_ObsServer.Parse_Obs_Message31;
var
  i, j, k,
  jd, mo    : int4;
  msec      : integer;
  Header    : TM_Data_Generic_Header;
  Volume    : TM_Data_Generic_Volume;
  Elevation : TM_Data_Generic_Elevation;
  Radial    : TM_Data_Generic_Radial;
  Moment    : array[0..2] of TM_Data_Generic_Moment;
  Moment_d  : TCellA;
  Chan      : TChannelDesc;
  S         : TMemoryStream;
  Move      : TMovement;
  Scan      : array[0..2] of TScan;
begin
  with fTranslator do
    begin
      Chan := Channel[0];
      for i := 0 to MovementsInChannel[0] - 1 do
        begin
          for k := 0 to 2 do
            begin
              Scan[k] := nil;
              Move := MovementFromChannel[i, k];
              if Assigned(Move) then
                begin
                  Scan[k] := TScan.Create;
                  case k of
                    0   : Scan[k].Measure := undBZ;
                    1, 2: Scan[k].Measure := unMS;
                  end;
                  Scan[k].Convert(Move);
                  Move.Free;
                end
            end;
          if Chan.Sectors < 400 then
            fSector_Count := Chan.Sectors
          else
            fSector_Count := 360;
          msec := MilliSecondsBetween(MovementFromChannelStartTime[i, 0], MovementFromChannelEndTime[i, 0]) div fSector_Count;
          for j := 0 to fSector_Count - 1 do
            begin
              DateTimeToJulianDate_msec(IncMilliSecond(Scan[0].Time, j * msec), jd, mo);
              with Header do
                begin
                  radar_identifier           := RadarId;
                  collection_time            := mo;
                  julian_date                := jd;
                  azimuth_number             := j + 1;
                  azimuth_angle              := j * 360 / fSector_Count;
                  azimuth_indexing_mode      := 0;
                  compression_indicator      := 0;
                  azimuth_resolution_spacing := 2;
                  if (i = 0) and (j = 0) then
                    radial_status := 3  // beginning of volume scan
                  else if (i = Movements - 1) and (j = fSector_Count - 1) then
                    radial_status := 4  // end of volume scan
                  else if (j = 0) then
                    radial_status := 0  // start of new elevation
                  else if (j = fSector_Count - 1) then
                    radial_status := 2  // end of elevation
                  else
                    radial_status := 1; // intermediate radial
                  elevation_number            := i + 1;
                  cut_sector_number           := 0;
                  elevation_angle             := CodeAngle(Scan[0].Angle);
                  radial_spot_blanking_status := 0;
                  azimuth_indexing_mode       := 0;
                  data_block_count            := 3;
                  for k := 0 to 2 do
                    if Assigned(Scan[k]) then
                      begin
                        Inc(data_block_count);
                        SetSize(Chan, Moment[k]);
                      end
                    else
                      FillChar(Moment[k], SizeOf(TM_Data_Generic_Moment), 0);
                  data_block_pointer[1] := SizeOf(TM_Data_Generic_Header);
                  data_block_pointer[2] := data_block_pointer[1] + SizeOf(TM_Data_Generic_Volume);
                  data_block_pointer[3] := data_block_pointer[2] + SizeOf(TM_Data_Generic_Elevation);
                  data_block_pointer[4] := data_block_pointer[3] + SizeOf(TM_Data_Generic_Radial);
                  data_block_pointer[5] := data_block_pointer[4] + SizeOf(TM_Data_Generic_Moment) + Moment[1].number_of_gates;
                  data_block_pointer[6] := data_block_pointer[5] + SizeOf(TM_Data_Generic_Moment) + Moment[2].number_of_gates;
                  data_block_pointer[7] := 0; // Polarimetric ZdR
                  data_block_pointer[8] := 0; // Polarimetric PhdR
                  data_block_pointer[9] := 0; // Polarimetric Correlation
                  radial_length         := SizeOf(TM_Data_Generic_Header   ) +
                                           SizeOf(TM_Data_Generic_Volume   ) +
                                           SizeOf(TM_Data_Generic_Elevation) +
                                           SizeOf(TM_Data_Generic_Radial   ) +
                                           SizeOf(TM_Data_Generic_Moment   )*(data_block_count - 3) +
                                           Moment[0].number_of_gates + Moment[1].number_of_gates + Moment[2].number_of_gates;
                end;
              with Volume do
                begin
                  data_type                        := 'R';
                  data_name                        := 'VOL';
                  lrtup                            := 44;
                  major_version_number             := 1;
                  minor_version_number             := 0;
                  lat                              := Find(Radar).Location.Latitude;
                  long                             := -Find(Radar).Location.Longitude;
                  site_height                      := Trunc(Find(Radar).Location.Altitude);
                  feedhorn_height                  := 3;
                  calibration_constant             := -54.0; // from rda_simulator
                  horizontal_shv_tx_power          := 500;
                  vertical_shv_tx_power            := 0;
                  system_diferential_reflectivity  := 0;
                  initial_system_diferential_phase := 0;
                  vcp_number                       := Self.VCP_Number;
                end;
              with Elevation do
                begin
                  data_type            := 'R';
                  data_name            := 'ELV';
                  lrtup                := 12;
                  atmos                := -11; // from rda_simulator
                  calibration_constant := Volume.calibration_constant;
                end;
              with Radial do
                begin
                  data_type                      := 'R';
                  data_name                      := 'RAD';
                  lrtup                          := 20;

                  // must be calculated !!
                  unambiguous_range              := 100 * 10; // scaled/10
                  horizontal_channel_noise_level := -100;
                  vertical_channel_noise_level   := -100;
                  nyquist_velocity               := 1000; // scaled/100
                end;
              with Moment[0] do // Z
                begin
                  data_type             := 'D';
                  moment_name           := 'REF';
                  reserved              := 0;
                  range                 := 0;
                  tover                 := 1;
                  snr_threshold         := 12;
                  control_flags         := 0;
                  data_word_size        := 8;
                  scale                 := 2;
                  offset                := 33;
                end;
              with Moment[1] do // V
                begin
                  data_type             := 'D';
                  moment_name           := 'VEL';
                  reserved              := 0;
                  range                 := 0;
                  tover                 := 1;
                  snr_threshold         := 12;
                  control_flags         := 0;
                  data_word_size        := 8;
                  scale                 := 2;
                  offset                := 64.5;
                end;
              with Moment[2] do // W
                begin
                  data_type             := 'D';
                  moment_name           := 'SW ';
                  reserved              := 0;
                  range                 := 0;
                  tover                 := 1;
                  snr_threshold         := 12;
                  control_flags         := 0;
                  data_word_size        := 8;
                  scale                 := 2;
                  offset                := 64.5;
                end;
              //
              CBO_DataGenericHeader(Header);
              CBO_DataGenericVolume(Volume);
              CBO_DataGenericElevation(Elevation);
              CBO_DataGenericRadial(Radial);
              S := TMemoryStream.Create;
              S.WriteBuffer(Header, SizeOf(Header));
              S.WriteBuffer(Volume, SizeOf(Volume));
              S.WriteBuffer(Elevation, SizeOf(Elevation));
              S.WriteBuffer(Radial, SizeOf(Radial));
              for k := 0 to ntohs(Header.data_block_count) - 4 do
                begin
                  AdjustRay(j, Scan[k], Moment[k], Moment_d);
                  CBO_DataGenericMoment(Moment[k]);
                  S.WriteBuffer(Moment[k], SizeOf(TM_Data_Generic_Moment));
                  S.WriteBuffer(Moment_d, ntohs(Moment[k].number_of_gates));
                end;
              while fRDA_Connection.Digital_Data.Count >= fQueue_Capacity do
                Sleep(1);
              fRDA_Connection.Digital_Data.Push(S);
              Sleep(fDataMessageDelay);
            end;
          for k:= 0 to 2 do
            FreeAndNil(Scan[k]);
        end;
    end;
end;

function TIdRDA_ObsServer.VCP_Number: integer;
var
  i, j: integer;
  N, N1, N2: IXMLNode;
begin
  if fUse_VCP_Table then
    begin
      result := 0;
      with fRDA_Connection.VCP_Table.DocumentElement.ChildNodes do
        begin
          for i := 0 to Count - 1 do
            begin
              N := Nodes[i];
              if N.LocalName = 'vcp' then
                begin
                  N1 := N.ChildNodes.FindNode('equivalent');
                  if N1 <> nil then
                    for j := 0 to N1.ChildNodes.Count - 1 do
                      begin
                        N2 := N1.ChildNodes[j];
                        if (N2.LocalName = 'obs') and (N2.Attributes['design'] = fTranslator.Design) then
                          begin
                            result := N.Attributes['pattern_number'];
                            exit;
                          end;
                      end
                end;
            end;
        end;
      raise Exception.Create('No vcp definition for observation design.');
    end
  else
    result := fDefault_VCP_Number;
end;

function TIdRDA_ObsServer.RadarId: TRadarId;
var
  i, j: integer;
  id: string;
begin
  result := '';
  with fRDA_Connection.VCP_Table.DocumentElement.ChildNodes.Nodes['Radar_ID'] do
    for i := 0 to ChildNodes.Count - 1 do
      with ChildNodes.Nodes[i] do
        if Attributes['name'] = Find(fTranslator.Radar).Name then
          begin
            id := Attributes['ID'];
            for j := 0 to 3 do
              result[j] := id[j + 1];
            exit;
          end;
  raise Exception.Create('No id definition for radar name.');
end;

function TIdRDA_ObsServer.CreateVCP_Msg: TMemoryStream;
var
  VCPHeader: TM_VCP_Header;
  VCPElevation: TM_VCP_Elevation;
  Move: TMovement;
  i: integer;
begin
  // Only reflectivity observations.
  // Some parameters may contain bad values, they are here only as metadata (whitout use).
  result := TMemoryStream.Create;
  with VCPHeader, fTranslator do
    begin
      message_size                := (SizeOf(TM_VCP_Header) + SizeOf(TM_VCP_Elevation) * Movements) div 2;
      pattern_type                := 2; // constant elevation cut.
      pattern_number              := fDefault_VCP_Number;
      number_of_elevation_cuts    := Movements;
      clutter_map_group_number    := 1; // Clutter map groups are not currently implemented on ORPG (june, 2011).
      doppler_velocity_resolution := 2; // 0.5 m/s.
      pulse_width                 := 2; // short pulse.
    end;
  CBO_VCPHeader(VCPHeader);
  result.Write(VCPHeader, SizeOf(TM_VCP_Header));
  with VCPElevation, fTranslator do
    for i := 1 to Movements - 1 do
      begin
        Move := Movement[i];
        FillChar(VCPElevation, SizeOf(TM_VCP_Elevation), 0);
        elevation_angle                        := Convert_data_out(CodeAngle(Move.Angle), ANGULAR_ELEV_DATA);
        channel_configuration                  := 0;  // Constant phase.
        waveform_type                          := 1;  // Contiguos Surveillance.
        super_resolution_control               := 0;  // No super resolution.
        surveillance_prf_number                := 1;  // first tabulated prf.
        surveillance_prf_pulse_count_by_radial := 27; // pulse count by radial.
        azimuth_rate                           := 30; // deg/seconds.
        reflectivity_threshold                 := 1;  // Signal to noise ratio (SNR) threshold for reflectivity.
        velocity_threshold                     := 1;  // Signal to noise ratio (SNR) threshold for velocity.
        spectrum_width_threshold               := 1;  // Signal to noise ratio (SNR) threshold for spectrum width.
        CBO_VCPElevation(VCPElevation);
        result.Write(VCPElevation, SizeOf(TM_VCP_Elevation));
        Move.Free;
      end;
end;

procedure TIdRDA_ObsServer.AdjustRay(ray: integer; var aScan: TScan; Moment: TM_Data_Generic_Moment; var data: TCellA);
var
  k, r,
  cell_index,
  cell_ave_c: integer;
  cell_ave  : real;
  val,
  ang1,
  ang2       : real;
  src_sum,
  src       : array of real;
  src_count : array of integer;
  ray_array : array[0..400] of integer;
  ray_count : integer;
begin
  // Sector selection for ray average
  ang1 := (ray - 0.5)*360/fSector_Count;
  ang2 := (ray + 0.5)*360/fSector_Count;
  ray_count := 0;
  k := ray*(aScan.Angles div fSector_Count) - 3;
  repeat
    Inc(k);
    val := k*360/aScan.Angles;
    if (val >= ang1) and (val < ang2) then
      begin
        ray_array[ray_count] := k;
        if k < 0 then
          Inc(ray_array[ray_count], aScan.Angle);
        Inc(ray_count);
      end
  until val > ang2;

  // Ray average
  SetLength(src,       aScan.Radiuses);
  SetLength(src_sum  , aScan.Radiuses);
  SetLength(src_count, aScan.Radiuses);
  for k := 0 to aScan.Radiuses - 1 do
    begin
      src_sum[k]   := 0;
      src_count[k] := 0;
    end;
  for r := 0 to ray_count - 1 do
    for k := 0 to aScan.Radiuses - 1 do
      begin
        val := CodeMeasure(aScan.Cell[k, ray_array[r]], aScan.Measure);
        if not ((aScan.Measure = undBZ) and (val = -80)) then
          begin
            src_sum[k] := src_sum[k] + val;
            Inc(src_count[k]);
          end;
      end;
  for k := 0 to aScan.Radiuses - 1 do
    if src_sum[k] <> 0 then
      src[k] := src_sum[k] / src_count[k]
    else
      src[k] := 0;

  // Cell average
  cell_index := 1;
  cell_ave   := 0;
  cell_ave_c := 0;
  k := 0;
  repeat
    if ((k + 0.5)*aScan.Length) <= (cell_index * Moment.range_sample_interval) then
      begin
        cell_ave := cell_ave + src[k];
        Inc(cell_ave_c);
      end
    else
      begin
        if cell_ave_c = 0 then
          data[cell_index - 1] := 0
        else
          data[cell_index - 1] := Trunc((cell_ave/cell_ave_c + Moment.offset)*Moment.scale);
        Inc(cell_index);
        cell_ave   := 0;
        cell_ave_c := 0;
        Dec(k);
      end;
    Inc(k);
  until (k >= aScan.Radiuses) or (cell_index - 1 >= Moment.number_of_gates);
end;

procedure TIdRDA_ObsServer.SetSize(var Channel: TChannelDesc; var Moment: TM_Data_Generic_Moment);
var
  n, r: integer;
begin
  // Determine range sample interval near Channel.Length
  n := Channel.Length div RSI_ACCURACY;
  r := Channel.Length mod RSI_ACCURACY;
  if (r <= RSI_ACCURACY/2) then
    Moment.range_sample_interval := n*RSI_ACCURACY
  else
    Moment.range_sample_interval := (n+1)*RSI_ACCURACY;

  // Fixed to 1 km. Problems found on products geolocation, maybe Super resolution must be enabled to solve.
  Moment.range_sample_interval := 1000;

  Moment.number_of_gates := Round(Channel.Cells * Channel.Length / Moment.range_sample_interval);
end;

end.


