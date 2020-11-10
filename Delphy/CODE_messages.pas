// Definition reference from:
//
// Interface Control Document for the RDA/RPG (ICD 2620002F)
//
// Open Build 10; 25 March 2008
// WSR-88D Radar Operations Center (ROC).
//

//{$DEFINE CBO_SINGLE_FUNC} // if Define use Single change Byte Order as function else as procedure

unit CODE_messages;

interface

uses
  WinSock, Math, DateUtils, SysUtils,
  TimeUtils;

const
  cMessageFullSize = 2432; // "Message full size"

type

// Common Operations and Development Environment (CODE) types:

  code1    = byte;     // One byte    ( 8 bits) of integer data representing a bit field.
  code2    = word;     // Two bytes   (16 bits) of integer data representing a bit field.
  int1     = byte;     // One byte    ( 8 bits) of unsigned integer data.
  int2     = word;     // Two bytes   (16 bits) of unsigned integer data.
  int4     = longword; // Four bytes  (32 bits) of unsigned integer data.
  real4    = single;   // Four bytes  (32 bits) of single precision floating point data in IEEE 754 format.
  real8    = double;   // Eight bytes (64 bits) of double precision floating point data in IEEE 754 format.
  Scint1   = byte;     // Floating point data represented by a 1-byte unsigned integer with an assumed decimal point whose position is defined by the precision of the item.
  Scint2   = word;     // Floating point data represented by a 2-byte unsigned integer with an assumed decimal point whose position is defined by the precision of the item.
  Scint4   = longword; // Floating point data represented by a 4-byte unsigned integer with an assumed decimal point whose position is defined by the precision of the item.
  ScSint2  = smallint; // Floating point data represented by a 2-byte signed integer with an assumed decimal point whose position is defined by the precision of the item.
  ScSint4  = longint;  // Floating point data represented by a 4-byte signed integer with an assumed decimal point whose position is defined by the precision of the item.
  sint     = shortint; // One byte   ( 8 bits) of integer data in standard 2's complement format
  sint2    = smallint; // Two bytes  (16 bits) of integer data in standard 2's complement format.
  sint4    = longint;  // Four bytes (32 bits) of integer data in standard 2's complement format.

  halfword = word;     // half of four bytes word;

// CTM Header
  TCTM_Header = record
    typ,
    par,
    len: int4;
  end;

  PCTM_Header = ^TCTM_Header;

// Volume Scan Title
  TVS_Title = record
    file_name          : array[0..8] of char;
    file_ext           : array[0..2] of char;
    julian_date,
    milliseconds_of_day: int4;
    spare              : array[0..3] of char;
  end;

// Message Header
  TMessage_Header = record
    message_size              : int2;
    RDA_redundant_channel,
    message_type              : int1;
    id_sequence_number,
    julian_date               : int2;
    milliseconds_of_day       : int4;
    number_of_message_segments,
    message_segment_number    : int2;
  end;

// Digital Radar Data. Message 1
  TM_Data_Header = record
    collection_time                   : int4;
    modified_julian_date              : int2;
    unambiguous_range                 : Scint2;
    azimuth_angle                     : code2;
    azimuth_number                    : int2;
    radial_status,
    elevation_angle                   : code2;
    elevation_number                  : int2;
    surveillance_range,
    doppler_range,
    surveillance_range_sample_interval,
    doppler_range_sample_interval     : code2;
    number_of_surveillance_bins,
    number_of_doppler_bins,
    cut_sector_number                 : int2;
    calibration_constant              : real4;
    surveillance_pointer,
    velocity_pointer,
    spectral_width_pointer            : int2;
    doppler_velocity_resolution       : code2;
    vcp_number                        : int2;
    spare_1                           : array[46..53] of byte;
    spare_2                           : array[54..59] of byte;
    nyquist_velocity,
    ATMOS,
    TOVER                             : Scint2;
    radial_spot_blanking_status       : int2;
    spare_3                           : array[68..99] of byte;
  end;

  TM_Data = array[0..cMessageFullSize -
                  SizeOf(TCTM_Header) -
                  SizeOf(TMessage_Header) -
                  SizeOf(TM_Data_Header) - 1] of byte;

  TData_Message = record
    Header     : TMessage_Header;
    Data_Header: TM_Data_Header;
    Data       : TM_Data;
  end;

// RDA Status Data. Message 2
  TM_RDA_Status = record
    RDA_status,
    operability_status,
    control_status,
    auxiliary_power_generator_status   : code2;
    average_transmiter_power           : int2;
    reflectivity_calibration_correction: Scint2;
    data_transmision_enabled           : code2;
    vcp_number                         : Sint2;
    RDA_control_authorization          : code2;
    RDA_build_number                   : Scint2;
    operational_mode,
    super_resolution_status            : code2;
    spare_1                            : array[13..14] of halfword;
    RDA_alarm_summary,
    command_acknowledgment,
    channel_control_status,
    spot_blanking_status               : code2;
    bypass_map_generation_date         : int2;
    bypass_map_generation_time         : int2;
    clutter_filter_map_generation_date : int2;
    clutter_filter_map_generation_time : int2;
    spare_2                            : halfword;
    transition_power_source_status     : int2;
    rms_control_status                 : code2;
    spare_3                            : halfword;
    alarm_codes                        : array[0..13] of int2;
  end;

// Performance / Maintenance Data. Message 3
  TM_Performance_Maintenance_Communications = record
    spare_1                                  : halfword;
    loop_back_test_status                    : int2;
    t1_ouput_frames,
    t1_input_frames,
    router_memory_used,
    router_memory_free                       : int4;
    router_memory_utilization                : int2;
    spare_2                                  : halfword;
    csu_loss_of_signal,
    csu_loss_of_frames,
    csu_yellow_alarms,
    csu_blue_alarms,
    csu_24hr_errored_seconds,
    csu_24hr_severely_errored_seconds,
    csu_24hr_severely_errored_framing_seconds,
    csu_24hr_unavailable_seconds,
    csu_24hr_controlled_slip_seconds,
    csu_24hr_path_coding_violations,
    csu_24hr_line_errored_seconds,
    csu_24hr_bursty_errored_seconds,
    csu_24hr_degraded_minutes                : int4;
    lan_switch_memory_used,
    lan_switch_memory_free,
    lan_switch_memory_utlization             : int2;
    spare_3                                  : halfword;
    ntp_rejected_packets                     : int4;
    ntp_estimated_time_error,
    gps_satellites,
    gps_max_signal_strength                  : Sint4;
    ipc_status,
    commanded_channel_control,
    dau_test_0,
    dau_test_1,
    dau_test_2                               : int2;
    spare_4                                  : array[58..98] of halfword;
  end;

  TM_Performance_Maintenance_Power = record
    ups_battery_status,
    ups_time_on_battery     : int4;
    ups_battery_temperature,
    ups_output_voltage,
    ups_output_frequency,
    ups_output_current,
    power_administrator_load: real4;
    spare                   : array[113..136] of halfword;
  end;

  TM_Performance_Maintenance_Transmitter = record
    plus_5_vdc_ps,
    plus_15_vdc_ps,
    plus_28_vdc_ps,
    minus_15_vdc_ps,
    plus_45_vdc_ps,
    filament_ps_voltage,
    vacuum_pump_ps_voltage,
    focus_coil_ps_voltage,
    filament_ps,
    klystron_warmup,
    transmitter_available,
    wg_switch_position,
    wg_pfn_transfer_interlock,
    maintenance_mode,
    maintenance_required,
    pfn_switch_position,
    modulator_overload,
    modulator_inv_current,
    modulator_switch_fail,
    main_power_voltage,
    charging_system_fail,
    inverse_diode_current,
    trigger_amplifier,
    circulator_temperature,
    spectrum_filter_presure,
    wg_arc_vswr,
    cabinet_interlock,
    cabinet_air_temperature,
    cabinet_airflow,
    klystron_current,
    klystron_filament_current,
    klystron_vacion_current,
    klystron_air_temperature,
    klystron_airflow,
    modulator_switch_maintenance,
    post_charge_regulator_maintenance,
    wg_presure_humidity,
    transmitter_overvoltage,
    transmitter_overcurrent,
    focus_coil_current,
    focus_coil_airflow,
    oil_temperature,
    prf_limit,
    transmitter_oil_level,
    transmitter_battery_charging,
    high_voltage_status,
    transmitter_recycling_summary,
    transmitter_inoperable,
    transmitter_air_filter,
    zero_test_bit_0,
    zero_test_bit_1,
    zero_test_bit_2,
    zero_test_bit_3,
    zero_test_bit_4,
    zero_test_bit_5,
    zero_test_bit_6,
    zero_test_bit_7,
    one_test_bit_0,
    one_test_bit_1,
    one_test_bit_2,
    one_test_bit_3,
    one_test_bit_4,
    one_test_bit_5,
    one_test_bit_6,
    one_test_bit_7,
    xmtr_dau_interface,
    transmitter_sumary_status: int2;
    spare_1                  : halfword;
    transmiter_rf_power      : real4;
    spare_2                  : array[207..208] of halfword;
    xmtr_peak_power          : real4;
    spare_3                  : array[211..212] of halfword;
    xmtr_rf_avg_power        : real4;
    xmtr_power_meter_zero    : int2;
    spare_4                  : halfword;
    xmtr_recycle_count       : int4;
    spare_5                  : array[219..228] of halfword;
  end;

  TM_Performance_Maintenance_Tower_Utilities = record
    ac_unit_1_compressor_shut_of,
    ac_unit_2_compressor_shut_of,
    generator_maintenance_required,
    generator_battery_voltage,
    generator_engine,
    generator_volt_frequency,
    power_source,
    transitional_power_source,
    generator_auto_run_off_switch,
    aircraft_hazard_lighting,
    dau_uart                      : int2;
    spare                         : array[240..249] of halfword;
  end;

  TM_Performance_Maintenance_Equipment_Shelter = record
    equipment_shelter_fire_detection_system,
    equipment_shelter_fire_smoke,
    generator_shelter_fire_smoke,
    utility_voltage_frequency,
    site_security_alarm,
    security_equipment,
    security_system,
    receiver_connected_to_antenna,
    radome_hatch,
    ac_unit_1_filter_dirty,
    ac_unit_2_filter_dirty                 : int2;
    equipment_shelter_temperature,
    outside_ambient_temperature,
    transmitter_leaving_air_temperature,
    ac_unit_1_discharge_air_temperature,
    generator_shelter_temperature,
    radome_air_temperature,
    ac_unit_2_discharge_air_temperature,
    dau_plus_15v_ps,
    dau_minus_15v_ps,
    dau_plus_28v_ps,
    dau_plau_5v_ps: real4;
    converted_generator_fuel_level         : int2;
    spare                                  : array[284..290] of halfword;
  end;

  TM_Performance_Maintenance_Antenna_Pedestal = record
    pedestal_plus_28v_ps,
    pedestal_plus_15v_ps,
    encoder_plus_5v_ps,
    pedestal_plus_5v_ps,
    pedestal_minus_15v_ps            : real4;
    plus_150v_overvoltage,
    plus_150v_undervoltage,
    elevation_servo_amp_inhibit,
    elevation_servo_amp_short_circuit,
    elevation_servo_amp_overtemp,
    elevation_motor_overtemp,
    elevation_stow_pin,
    elevation_pcu_parity,
    elevation_dead_limit,
    elevation_plus_normal_limit,
    elevation_minus_normal_limit,
    elevation_encoder_light,
    elevation_gearbox_oil,
    elevation_handwheel,
    elevation_amp_ps,
    azimuth_servo_amp_inhibit,
    azimuth_servo_short_circuit,
    azimuth_servo_amp_overtemp,
    azimuth_motor_overtemp,
    azimuth_stow_pin,
    azimuth_pcu_parity,
    azimuth_encoder_light,
    azimuth_gearbox_oil,
    azimuth_bull_gear_oil,
    azimuth_hand_wheel,
    azimuth_servo_amp_ps,
    servo,
    pedestal_interlock_switch        : int2;
    azimuth_position_correction,
    elevation_position_correction    : code2;
    self_test_1_status,
    self_test_2_status,
    self_test_2_data                 : int2;
    spare                            : array[334..340] of halfword;
  end;

  TM_Performance_Maintenance_RF_Generator_Receiver = record
    coho_clock,
    rf_generator_frequency_select_oscillator,
    rf_generator_rf_stalo,
    rf_generator_phase_shifted_coho,
    plus_9v_receiver_ps,
    plus_5v_receiver_ps,
    plus_minus_18v_receiver_ps,
    minus_9v_receiver_ps,
    plus_5v_receiver_protector_ps           : int2;
    spare_1                                 : halfword;
    short_pulse_noise,
    long_pulse_noise,
    noise_temperature                       : real4;
    spare_2                                 : array[357..362] of halfword;
  end;

  TM_Performance_Maintenance_Calibration = record
    linearity,
    dynamic_range,
    delta_dbz0,
    rcv_prot_attenuation,
    kd_peak_measured,
    kd_injection_point_difference,
    short_pulse_dbz0,
    long_pulse_dbz0                     : real4;
    velocity_processed,
    width_processed,
    velocity_rf_gen,
    width_rf_gen                        : int2;
    io                                  : real4;
    spare_1                             : array[385..408] of halfword;
    clutter_suppression_delta,
    clutter_suppression_unfiltered_power,
    clutter_suppression_filtered_power,
    transmit_busrt_power,
    transmit_burst_phase                : real4;
    spare_2                             : array[419..430] of halfword;
  end;

  TM_Performance_Maintenance_File_Status = record
    state_file_read_status,
    state_file_write_status,
    bypass_map_file_read_status,
    bypass_map_file_write_status        : int2;
    spare_1                             : halfword;
    spare_2                             : halfword;
    current_adaptation_file_read_status,
    current_adaptation_file_write_status,
    cenzor_zone_file_read_status,
    cenzor_zone_file_write_status,
    remote_vcp_file_read_status,
    remote_vcp_file_write_status,
    baseline_adaptation_file_read_status,
    spare_3                             : halfword;
    clutter_filter_map_file_read_status,
    clutter_filter_map_file_write_status,
    general_disk_io_error               : int2;
    spare_4                             : array[448..460] of halfword;
  end;

  TM_Performance_Maintenance_Device_Status = record
    dau_comm_status,
    hci_comm_status,
    pedestal_comm_status,
    signal_processor_comm_status: int2;
    spare_1                     : halfword;
    rms_link_status,
    rpg_link_status             : int2;
    spare_2                     : array[468..480] of halfword;
  end;

  TM_Performance_Maintenance_Message = record
    Communications       : TM_Performance_Maintenance_Communications;
    Power                : TM_Performance_Maintenance_Power;
    Transmitter          : TM_Performance_Maintenance_Transmitter;
    Tower_Utilities      : TM_Performance_Maintenance_Tower_Utilities;
    Equipment_Shelter    : TM_Performance_Maintenance_Equipment_Shelter;
    Antenna_Pedestal     : TM_Performance_Maintenance_Antenna_Pedestal;
    RF_Generator_Receiver: TM_Performance_Maintenance_RF_Generator_Receiver;
    Calibration          : TM_Performance_Maintenance_Calibration;
    File_Status          : TM_Performance_Maintenance_File_Status;
    Device_Status        : TM_Performance_Maintenance_Device_Status;
  end;

// Console. Messages 4 & 10
  TM_Console = record
    message_size: int2;
    message_: array[2..203] of halfword;
  end;

// VCP Data. Messages 5 & 7
  TM_VCP_Header = record
    message_size               : int2;
    pattern_type               : code2;
    pattern_number             : int2;
    number_of_elevation_cuts   : int2;
    clutter_map_group_number   : int2;
    doppler_velocity_resolution: code1;
    pulse_width                : code1;
    spare                      : array[7..11] of halfword;
  end;

  TM_VCP_Elevation = record
    elevation_angle                       : code2;
    channel_configuration,
    waveform_type,
    super_resolution_control              : code1;
    surveillance_prf_number               : int1;
    surveillance_prf_pulse_count_by_radial: int2;
    azimuth_rate                          : code2;
    reflectivity_threshold,
    velocity_threshold,
    spectrum_width_threshold              : ScSint2;
    spares                                : array[9..11] of halfword;
    sector1_edge_angle                    : code2;
    sector1_doppler_prf_number,
    sector1_doppler_prf_count_by_radial   : int2;
    sector1_spare                         : halfword;
    sector2_edge_angle                    : code2;
    sector2_doppler_prf_number,
    sector2_doppler_prf_count_by_radial   : int2;
    sector2_spare                         : halfword;
    sector3_edge_angle                    : code2;
    sector3_doppler_prf_number,
    sector3_doppler_prf_count_by_radial   : int2;
    sector3_spare                         : halfword;
  end;

// RDA Control Commands. Message 6
  TM_RDA_Control_Commands = record
    rda_state_command,
    base_data_transmission_enable,
    auxiliary_power_generator_control,
    rda_control_commands_and_authorization,
    restart_vcp_or_elevation_cut                : code2;
    select_local_vcp_number_for_next_volume_scan: int2;
    automatic_calibration_override              : Scint2;
    super_resolution_control                    : code2;
    spare1                                      : array[9..10] of halfword;
    select_operating_mode,
    channel_control_command                     : code2;
    spare2                                      : array[13..20] of halfword;
    spot_blanking                               : code2;
    spare3                                      : array[22..26] of halfword;
  end;

// Clutter Censor Zones. Message 8
  TM_Clutter_Censor_Zones = record
    override_regions,
    start_range,
    stop_range,
    start_azimuth,
    stop_azimuth,
    elevation_segment_number: int2;
    operator_select_code    : code2;
  end;

// Request for Data. Message 9
  TM_Request_Data = record
    request_type: code2;
  end;

//  Loop Back Test. Messages 11 & 12
  TM_Loop_Back_Test = record
    message_size: sint2;
    bit_pattern : array[2..1200] of byte;
  end;

// Clutter Filter Bypass Map. Message 13
  TM_Clutter_Filter_Bypass_Map_Header = record
    generation_date,
    generation_time,
    number_of_segments: int2;
  end;

  TM_Clutter_Filter_Bypass_Map_Segment = record
    segment_number: int2;
    range_bins: array[1..360, 0..31] of code2;
  end;

// Clutter Filter Map. Message 15
  TM_Clutter_Filter_Map_Header = record
    generation_date,
    generation_time,
    number_of_elevation_segments: int2;
  end;

  TM_Clutter_Filter_Map_Range_Zone = record
    op_code  : code2;
    end_range: int2;
  end;

  TM_Clutter_Filter_Map_Azimuth_Segment = record
    number_of_range_zones: int2;
  end;

// RDA Adaptation Data. Message 18
  TM_RDA_Adaptation_Data = record
  end;

  TRadarId = array[0..3] of char;

// Digital Radar Data Generic Format Message
  TM_Data_Generic_Header = record
    radar_identifier           : TRadarId;
    collection_time            : int4;
    julian_date,
    azimuth_number             : int2;
    azimuth_angle              : real4;
    compression_indicator      : code1;
    spare                      : int1;
    radial_length              : int2;
    azimuth_resolution_spacing,
    radial_status              : code1;
    elevation_number,
    cut_sector_number          : int1;
    elevation_angle            : real4;
    radial_spot_blanking_status: code1;
    azimuth_indexing_mode      : Scint1;
    data_block_count           : int2;
    data_block_pointer         : array[1..9] of int4;
  end;

  // Descriptor of generic data moment type
  TM_Data_Generic_Moment = record
    data_type            : char;
    moment_name          : array[1..3] of char;
    reserved             : int4;
    number_of_gates      : int2;
    range,
    range_sample_interval,
    tover,
    snr_threshold        : ScSint2;
    control_flags        : code1;
    data_word_size       : int1;
    scale,
    offset               : real4;
    // here comes variable length data
  end;

  // Volume data constant type
  TM_Data_Generic_Volume = record
    data_type                       : char;
    data_name                       : array[1..3] of char;
    lrtup                           : int2;
    major_version_number,
    minor_version_number            : int1;
    lat,
    long                            : real4;
    site_height                     : Sint2;
    feedhorn_height                 : int2;
    calibration_constant,
    horizontal_shv_tx_power,
    vertical_shv_tx_power,
    system_diferential_reflectivity,
    initial_system_diferential_phase: real4;
    vcp_number                      : int2;
    spare                           : halfword;
  end;

  // Elevation data constant type
  TM_Data_Generic_Elevation = record
    data_type           : char;
    data_name           : array[1..3] of char;
    lrtup               : int2;
    atmos               : ScSint2;
    calibration_constant: real4;
  end;

  // Radial data constant type
  TM_Data_Generic_Radial = record
    data_type                     : char;
    data_name                     : array[1..3] of char;
    lrtup                         : int2;
    unambiguous_range             : Scint2;
    horizontal_channel_noise_level,
    vertical_channel_noise_level  : real4;
    nyquist_velocity              : Scint2;
    spare                         : halfword;
  end;

// RDA Definitions

type
  Tfloat          = single;
  Tshort          = smallint;
  Tint            = integer;
  Tunsigned_char  = byte;
  Tchar_p         = pchar;
  Tchar           = byte;
  Tunsigned_int   = cardinal;
  Tunsigned_short = word;
  Tunsigned_long  = longword;

const
  RDA_ADAPTATION_DATA = 18;
  RDA_VCP_MSG         =  5;

  CCS_CONTROLLING     = $0000; { RDA-RPG ICD Setting for this channel controlling }
  CCS_NON_CONTROLLING = $0001; { RDA-RPG ICD Setting for this channel not controlling }

  ALIGNMENT_SIZE = 4; {# of bytes for alignment }

  cFALSE = 0;
  cTRUE  = 1;

  ZERO = 0;
  ONE  = 1;

  REQUEST_FOR_STATUS_DATA         = 129;
  REQUEST_FOR_PERFORMANCE_DATA    = 130;
  REQUEST_FOR_BYPASS_MAP_DATA     = 132;
  REQUEST_FOR_NOTCHWIDTH_MAP_DATA = 136;

  //Maximum sizes of data fields
  BASEDATA_REF_SIZE     = 460;
  BASEDATA_VEL_SIZE     = 920;
  MAX_BASEDATA_REF_SIZE = 1840;
  BASEDATA_DOP_SIZE     = 1200;
  BASEDATA_RHO_SIZE     = 1200;
  BASEDATA_PHI_SIZE     = 1200;
  BASEDATA_SNR_SIZE     = 1840;
  BASEDATA_ZDR_SIZE     = 1200;
  BASEDATA_RFR_SIZE     = 240;

  MAX_MESSAGE_SIZE     = 2416;
  MAX_MESSAGE_31_SIZE  = 65535;
  MAX_BUFFER_SIZE      = 6600;
  MAX_NAME_SIZE        = 128;
  MAX_NUM_SURV_BINS    = 460;  {max # of surveillance bins}
  MAX_SR_NUM_SURV_BINS = 1840; {max # of surveillance bins (super resolution)}
  MAX_NUM_VEL_BINS     = 920;  {max # of velocity & spec width bins}
  MAX_SR_NUM_VEL_BINS  = 1200; {max # of velocity & spec width bins (super resolution)}
  MAX_NUM_ZDR_BINS     = BASEDATA_ZDR_SIZE;
  MAX_NUM_PHI_BINS     = BASEDATA_PHI_SIZE;
  MAX_NUM_RHO_BINS     = BASEDATA_RHO_SIZE;
  HALF_DEG_RADIALS     = 0.5;
  ONE_DEG_RADIALS      = 1.0;
  MAX_NUM_RADIALS      = 360; {max # of radials}
  MAX_SR_NUM_RADIALS   = 720; {max # of radials (super resolution)}

  NO_COMMAND_PENDING = -1; {state where a new command has not been received and
                            a command to execute is not pending}

  // define the command states and processing states
  START_OF_ELEVATION          = 0; {processing at begining of elevation}
  PROCESSING_RADIAL_DATA      = 1; {digital radar data being processed}
  END_OF_ELEVATION            = 2; {processing at the end of elevation cut}
  RDASIM_START_OF_VOLUME_SCAN = 3; {processing at the begining of vol scan}
  END_OF_VOLUME_SCAN          = 4; {processing at the end of vol scan}
  NO_PENDING_COMMAND          = 5; {a command is not pending}
  START_UP                    = 6;
  STANDBY                     = 7;
  RDA_RESTART                 = 8;
  OPERATE                     = 9;
  OFFLINE_OPERATE             = 10;
  PLAYBACK                    = 11;
  VCP_ELEVATION_RESTART       = 12;

  // RDA Status
  RDS_STARTUP         = $0002;
  RDS_STANDBY         = $0004;
  RDS_RESTART         = $0008;
  RDS_OPERATE         = $0010;
  RDS_PLAYBACK        = $0020;
  RDS_OFFLINE_OPERATE = $0040;

  // RDA Operability Status
  ROS_RDA_ONLINE                         = $0002;
  ROS_RDA_MAINTENANCE_REQUIRED           = $0004;
  ROS_RDA_MAINTENANCE_MANDATORY          = $0008;
  ROS_RDA_COMMANDED_SHUTDOWN             = $0010;
  ROS_RDA_INOPERABLE                     = $0020;
  ROS_RDA_AUTOMATIC_CALIBRATION_DISABLED = $0001;

  // RDA Control Status
  RCS_RDA_LOCAL_ONLY  = $0002;
  RCS_RDA_REMOTE_ONLY = $0004;
  RCS_RDA_EITHER      = $0008;

  // Aux Power Generator State
  APGS_AUXILIARY_POWER       = $0001;
  APGS_UTILITY_PWR_AVAILABLE = $0002;
  APGS_GENERATOR_ON          = $0004;
  APGS_XFER_SWITCH_IN_MANUAL = $0008;
  APGS_COMMANDED_SWITCHOVER  = $0010;

  // Data Transmision Enabled
  DTE_NONE_ENABLED           = $0002;
  DTE_REFLECTIVITY_ENABLED   = $0004;
  DTE_VELOCITY_ENABLED       = $0008;
  DTE_SPECTRUM_WIDTH_ENABLED = $0010;

  // RDA Control Authorization
  RCA_NO_ACTION              = $0000;
  RCA_LOCAL_CONTROL_REQUEST  = $0002;
  RCA_REMOTE_CONTROL_ENABLED = $0004;

  // RDA Operational Mode
  ROM_MAINTENANCE = $0002;
  ROM_OPERATIONAL = $0004;

  // Super Resolution Status
  SRS_ENABLED  = $0002;
  SRS_DISABLED = $0004;

  // Archive II Status
  A2S_NOT_INSTALLED      = $0000;
  A2S_INSTALLED          = $0001;
  A2S_LOADED             = $0002;
  A2S_WRITE_PROTECTED    = $0004;
  A2S_RESERVED           = $0008;
  A2S_RECORD             = $0010;
  A2S_PLAYBACK_AVAILABLE = $0020;
  A2S_GENERATE_DIRECTORY = $0040;
  A2S_POSITION           = $0080;

  // RDA Alarm Summary
  RAS_NO_ALARMS                 = $0000;
  RAS_TOWER_UTILITIES           = $0002;
  RAS_PEDESTAL                  = $0004;
  RAS_TRANSMITTER               = $0008;
  RAS_RECEIVER_SIGNAL_PROCESSOR = $0010;
  RAS_RECEIVER                  = $0010; // ORDA only
  RAS_RDA_CONTROL               = $0020;
  RAS_RPG_COMMUNICATIONS        = $0040;
  RAS_USER_COMMUNICATION        = $0080;
  RAS_SIGNAL_PROCESSOR          = $0080; // ORDA only
  RAS_ARCHIVE_II                = $0100;

  // Command Acknowledgement
  CA_NO_ACKNOWLEDGEMENT                     = $0000;
  CA_REMOTE_VCP_RECEIVED                    = $0001;
  CA_CLUTTER_BYPASS_MAP_RECEIVED            = $0002;
  CA_CLUTTER_CENSOR_ZONES_RECEIVED          = $0003;
  CA_REDUNDANT_CHANNEL_STANDBY_CMD_ACCEPTED = $0004;

  // Spot Blanking Status
  SBS_NOT_INSTALLED = $0000;
  SBS_ENABLED       = $0002;
  SBS_DISABLED      = $0004;

  //
  RDASIM_VOL_DATA = -3;
  RDASIM_ELV_DATA = -2;
  RDASIM_RAD_DATA = -1;

  RDASIM_REF_DATA = 1;
  RDASIM_VEL_DATA = 2;
  RDASIM_WID_DATA = 3;
  RDASIM_ZDR_DATA = 4;
  RDASIM_PHI_DATA = 5;
  RDASIM_RHO_DATA = 6;

  MAX_DATA_BLOCKS = 9;

  // Processing state in TReq_struct or TResp_struct
  CM_NEW  = 0; {new and unprocessed}
  CM_DONE = 1; {processing finished and response sent}

  // Values for link_state
  LINK_DISCONNECTED = 0;
  LINK_CONNECTED    = 1;

  // Values for conn_activity
  NO_ACTIVITY   = 0; {No connect/disconnect request is being processed}
  CONNECTING    = 1; {a connect request is being processed}
  DISCONNECTING = 2; {a disconnect request is being processed}

  //ICD Defined message types
  DIGITAL_RADAR_DATA           = 1;
  RDA_STATUS_DATA              = 2;
  PERFORMANCE_MAINTENANCE_DATA = 3;
  CONSOLE_MESSAGE_A2G          = 4;
  RDA_RPG_VCP                  = 5;
  RDA_CONTROL_COMMANDS         = 6;
  RPG_RDA_VCP                  = 7;
  CLUTTER_SENSOR_ZONES         = 8;
  REQUEST_FOR_DATA             = 9;
  CONSOLE_MESSAGE_G2A          = 10;
  LOOPBACK_TEST_RDA_RPG        = 11;
  LOOPBACK_TEST_RPG_RDA        = 12;
  CLUTTER_FILTER_BYPASS_MAP    = 13;
  EDITED_CLUTTER_FILTER_MAP    = 14;
  NOTCHWIDTH_MAP_DATA          = 15; {Legacy RDA}
  CLUTTER_MAP_DATA             = 15; {ORDA}
  ADAPTATION_DATA              = 18;
  GENERIC_DIGITAL_RADAR_DATA   = 31;

  //Super resolution
  SR_NOCHANGE = 0;
  SR_ENABLED  = 2;
  SR_DISABLED = 4;

  //comm_manager
  MAX_N_LINKS    = 48;                 {maximum number of links this comm_manager can manage}
  MAX_N_STATIONS = 3;                  {max number of PVCs per link}
  MAX_N_REQS     = 5 + MAX_N_STATIONS; {number of pending request per link}

  //comm_manager request types ("type" in TCM_req_struct or TCM_resp_struct)
  CM_CONNECT    = 0; { make a connection on link "link_ind" }
  CM_DIAL_OUT   = 1; { dail out and make a connection on link "link_ind" }
  CM_DISCONNECT = 2; { terminate the connection on link "link_ind" }
  CM_WRITE      = 3; { write a message of size "data_size" on link "link_ind" with priority "parm";
                       The data is in message of id "data_id";
                       The prority level can be between 0 -  MAX_N_STATIONS - 1;
                       0 indicaets the highest }
  CM_STATUS     = 4; { request a status response on link "link_ind" }
  CM_CANCEL     = 5; { cancel the previous req of number "parm" }
  CM_DATA       = 6; { a incoming data message from the user }
  CM_EVENT      = 7; { a event notification from the comm_manager }
  CM_SET_PARAMS = 8; { sets/resets link parameters }

  // comm_manager return codes in the response messages ("ret_code" in TCM_resp_struct)
  CM_SUCCESS             = 0;	 { requested action completed successfully }
  CM_TIMED_OUT           = 1;	 { transaction time-out }
  CM_NOT_CONFIGURED      = 2;	 { failed because the link is not configured for the requested task }
  CM_DISCONNECTED        = 3;	 { the connection is not built or lost }
  CM_CONNECTED           = 4;	 { the link is connected  }
  CM_BAD_LINK_NUMBER     = 5;	 { the specified link is not configured }
  CM_INVALID_PARAMETER   = 6;	 { a parameter is illegal in the request }
  CM_TOO_MANY_REQUESTS   = 7;	 { too many pending and unfinished requests }
  CM_IN_PROCESSING       = 8;	 { a previous request of the same type is being processed }
  CM_TERMINATED          = 9;	 { requested failed because a new conflicting request started; }
  CM_FAILED              = 10; { requested action failed }
  CM_REJECTED            = 11; { requested action is rejected by the other side of the link }
  CM_LOST_CONN           = 12; { connection lost due to remote action }
  CM_CONN_RESTORED       = 13; { connection restored due to remote action }
  CM_LINK_ERROR          = 14; { a link error is detected and the link is disconnected }
  CM_START               = 15; { this comm_manager instance is just started }
  CM_TERMINATE           = 16; { this comm_manager instance is going to terminates }
  CM_STATISTICS          = 17; { a statistics reporting event }
  CM_EXCEPTION           = 18; { line exception (hardware or software errors detected) }
  CM_NORMAL              = 19; { returned to normal from exception state }
  CM_PORT_IN_USE         = 20; { Dial port is in use  by another client}
  CM_DIAL_ABORTED        = 21; { reset was pressed at the modem front panel during dilaing or modem did not detect a dial tone}
  CM_INCOMING_CALL       = 22; { modem detected an incoming ring after dialing command was entered}
  CM_BUSY_TONE           = 23; { Modem detected a busy tone after dialing}
  CM_PHONENO_FORBIDDEN   = 24; { The no. is on the forbidden numbers list }
  CM_PHONENO_NOT_STORED  = 25; { phone no. not strored in modem memory}
  CM_NO_DIALTONE         = 26; { No answer-back tone or ring-back tone was detected in the remote modem}
  CM_MODEM_TIMEDOUT      = 27; { Ringback is detected, but the call is not completed due to  timeout, i.e modem did not send any response with in the timeout value}
  CM_INVALID_COMMAND     = 28; { Invalid dialout command or a command that the modem cannot execute }
  CM_TRY_LATER           = 29; { Try the request at a later time}
  CM_MODEM_PROBLEMS      = 30; { General catch all modem dial-out problems }
  CM_MODEMRETRY_PROBLEMS = 31; { General catch all modem retry-able dial-out problems }
  CM_RTR_PROBLEMS        = 32; { General catch all router dial-out problems }
  CM_RTRRETRY_PROBLEMS   = 33; { General catch all router retry-able dial-out problems }
  CM_DIAL_TIMEOUT        = 35; { After about 25 seconds modem still didn't go offhook  }
  CM_STATUS_MSG          = 36; { 35 }{ A status message from cm_tcp }
  CM_BUFFER_OVERFLOW     = 37; { To-be-packed messages expired in the request buffer. }
  CM_WRITE_PENDING       = 38; { response for CM_STATUS request }

  //rda_rpg_clutter_map.h
  MAX_BYPASS_MAP_SEGMENTS	     = 2;   {Max num elev segs}
  ORDA_MAX_BYPASS_MAP_SEGMENTS = 5;   {Max num elev segs}
  BYPASS_MAP_RADIALS	         = 256; {Num radials (legacy)}
  ORDA_BYPASS_MAP_RADIALS      = 360; {Num radials (orda)}
  BYPASS_MAP_BINS		           = 512; {Num range bins}
  HW_PER_RADIAL		             = 32;  {Num halfwords per radial}

  //orda_clutter_map.h
  MAX_RANGE_ZONES_ORDA	  = 25;
  NUM_AZIMUTH_SEGS_ORDA	  = 360;
  MAX_ELEVATION_SEGS_ORDA	= 5;

  //used for converting azimuth/elevation rate data to BAMS and viceversa
  ORPGVCP_RATE_BAMS2DEG = 22.5/16384.0;
  ORPGVCP_RATE_DEG2BAMS = 16384.0/22.5;
  ORPGVCP_RATE_HALF_BAM = 0.010986328125/2.0;

  //used for converting azimuth/elevation angles to BAMS and viceversa
  ORPGVCP_AZIMUTH_RATE_FACTOR  = 45.0/32768.0;
  ORPGVCP_ELVAZM_BAMS2DEG      = 180.0/32768.0;
  ORPGVCP_ELVAZM_DEG2BAMS      = 32768.0/180.0;
  ORPGVCP_HALF_BAM             = 0.043945/2.0;
  ORPGVCP_ELEVATION_ANGLE      = $0001;
  ORPGVCP_AZIMUTH_ANGLE        = $0002;
  ORPGVCP_ANGLE_FULL_PRECISION = $0008;

const
  DEFAULT_VELOCITY_RESOLUTION =   2; { ICD defined 0.5 m/s Doppler velocity resolution }
  FAT_RADIAL_SIZE             = 2.1; { size of a fat radial in degrees }
  LOCAL_VCP                   =   1; { vcp data is a local vcp }
  REMOTE_VCP                  =   2; { vcp data is a remote vcp }
  VELOCITY_DATA               =   1; { specifies the data is velocity data }
  ANGULAR_ELEV_DATA           =   2; { specifies the data is an elevation angle }
  ANGULAR_AZM_DATA            =   3; { specifies the data is an azimuth angle }
  NUMBER_LOCAL_VCPS           =   6; { # local/RDA VCPs defined }
  NUMBER_PRFS_DEFINED         =   8; { # PRFs defined for PRI #3 }
  MAX_NUMBER_LOCAL_ELEV_CUTS  =  16; { max number local/RDA elevation cuts for the local VCPs defined }
  MAX_ELEV_CUTS               = 100; { max number of elevation cuts allowed (this number was arbitrarily selected) }

type
  TVcp_data = record   { data for the next VCP to execute }
    pattern_number,                                                            { VCP number }
    number_elev_cuts,                                                          { # elev cuts in this VCP }
    velocity_resolution: Tshort;                                               { Doppler velocity resolution }
    surv_prf_number    : array[0..MAX_ELEV_CUTS - 1] of Tshort;                { surviellance prf numbers }
    surv_prf           : array[0..MAX_ELEV_CUTS - 1] of Tunsigned_short;       { surv pulse count per second }
    doppler_prf_number : array[0..MAX_ELEV_CUTS - 1, 0..2] of Tshort;          { Doppler prfs segment numbers }
    doppler_prf        : array[0..MAX_ELEV_CUTS - 1, 0..2] of Tunsigned_short; { Doppler pulse count per second }
    segment_angles     : array[0..MAX_ELEV_CUTS - 1, 0..2] of Tfloat;          { clockwise leading edge segment angles }
    azimuth_rate       : array[0..MAX_ELEV_CUTS - 1] of Tfloat;                { azimuth rates (deg/sec) }
    elev_angles        : array[0..MAX_ELEV_CUTS - 1] of Tfloat;                { elevation angles }
    atmos_atten        : array[0..MAX_ELEV_CUTS - 1] of Tfloat;                { atmospheric attenuation }
    waveform_type      : array[0..MAX_ELEV_CUTS - 1] of Tshort;                { waveform types }
    super_res          : array[0..MAX_ELEV_CUTS - 1] of Tshort;                { super resolution types }
    dual_pol           : array[0..MAX_ELEV_CUTS - 1] of Tshort;                { dual pol requested }
    ref_snr            : array[0..MAX_ELEV_CUTS - 1] of Tshort;	               { SNR threshold for reflectivity (dB/8) }
    vel_snr            : array[0..MAX_ELEV_CUTS - 1] of Tshort;	               { SNR threshold for velocity (dB/8) }
    sw_snr             : array[0..MAX_ELEV_CUTS - 1] of Tshort;	               { SNR threshold for spectrum width (dB/8) }
    zdr_snr            : array[0..MAX_ELEV_CUTS - 1] of Tshort;	               { SNR threshold for ZDR (dB/8) }
    phi_snr            : array[0..MAX_ELEV_CUTS - 1] of Tshort;	               { SNR threshold for PHI (dB/8) }
    rho_snr            : array[0..MAX_ELEV_CUTS - 1] of Tshort;	               { SNR threshold for RHO (dB/8) }
  end;

var
  Vcp_data: TVcp_data;

  Surv_bins        : array[0..MAX_SR_NUM_SURV_BINS - 1] of Tchar;			      { radial bin array }
  Velocity_bins    : array[0..MAX_SR_NUM_VEL_BINS  - 1] of Tunsigned_char;  {       ''         }
  Aliased_velocity : array[0..MAX_SR_NUM_VEL_BINS  - 1] of Tunsigned_char;  { aliased velocity radial }
  SW_bins          : array[0..MAX_SR_NUM_VEL_BINS  - 1] of Tunsigned_char;	{ spectrum width bin array }
  ZDR_bins         : array[0..MAX_NUM_ZDR_BINS     - 1] of Tunsigned_char;  { ZDR bin array }
  PHI_bins         : array[0..MAX_NUM_PHI_BINS     - 1] of Tunsigned_short; { PHI bin array }
  RHO_bins         : array[0..MAX_NUM_RHO_BINS     - 1] of Tunsigned_char;	{ RHO bin array }

  Radial_sample_interval   : Tfloat;				{ radial sample interval }
  Surv_sample_interval     : Tfloat;				{ surveillance sample interval, in km }
  Doppler_sample_interval  : Tfloat;				{ Doppler sample interval, in km }
  Radials_per_elevation    : Tint;          { # radials per elevation }
  Max_radials_per_elevation: Tint;			    { maximum # radials per elevation }
  New_pattern_selected     : Tshort;				{ New coverage pattern selected }
  New_vcp_selected         : Tint = cFALSE;	{ flag specifying a new vcp has been selected }
  Fixed_azimuth_rate       : Tfloat = 0.0;	{ user defined fixed azimuth rate (deg/sec) }
  Current_vcp              : Tshort = -11;	{ currently selected VCP - default for first scan = local 11 }
  Surv_range               : Tfloat;				{ surveillance range in kilometers }
  Doppler_range            : Tfloat;				{ Doppler range in kilometers }

{ the remaining initialized definitions represent the local/RDA VCPs

  VCP Index for remaining array definitions:

               VCP  11 = 0
               VCP  21 = 1
               VCP  31 = 2
               VCP  32 = 3
               VCP 300 = 4
               VCP  51 = 5}

 VCP_number: array[0..NUMBER_LOCAL_VCPS - 1] of Tshort
   = (11, 21, 31, 32, 300, 51);

 Number_elevation_cuts: array[0..NUMBER_LOCAL_VCPS - 1] of Tshort
   = (16, 11, 8, 7, 4, 16);

 Elevation_angles: array[0..NUMBER_LOCAL_VCPS - 1, 0..MAX_NUMBER_LOCAL_ELEV_CUTS - 1] of Tfloat = (

 {        array index: [VCP_index, elevation_cut]

                                             Elevation Cut
                    1     2     3      4     5      6      7     8
                    9    10    11     12    13     14     15    16   }

      { VCP 11 }  ( 0.50,  0.50,  1.45,  1.45,  2.40,  3.35,  4.3,   5.25,
                    6.20,  7.50,  8.70, 10.00, 12.00, 14.00, 16.7,  19.50),

      { VCP 21 }  ( 0.50,  0.50,  1.45,  1.45,  2.40,   3.35,  4.3,   6.0,
                    9.90, 14.60, 19.50,  0.00,  0.00,   0.00,  0.0,   0.0),

      { VCP 31 }  ( 0.50,  0.50,  1.50,  1.50,  2.50,  2.50,   3.5,   4.5,
                    0.00,  0.00,  0.00,  0.00,  0.00,  0.00,   0.0,   0.0),

      { VCP 32 }  ( 0.50,  0.50,  1.50,  1.50,  2.50,  3.50,   4.5,   0.0,
                    0.00,  0.00,  0.00,  0.00,  0.00,  0.00,   0.0,   0.0),

      { VCP 300 } ( 0.50,  0.50,  2.40,  9.90,  0.00,  0.00,   0.0,   0.0,
                    0.00,  0.00,  0.00,  0.00,   0.0,  0.00,   0.0,   0.0),

      { VCP  51}  ( 0.50,  1.50,  2.90,  4.30,  5.70,  7.10,  8.50,  9.90,
                   11.30, 12.70, 14.10, 15.50, 16.90, 18.30, 19.70, 21.20));

   { the antenna rotation rates in deg/sec for each elevation cut per VCP.  }
  cAzimuth_rate: array[0..NUMBER_LOCAL_VCPS - 1, 0..MAX_NUMBER_LOCAL_ELEV_CUTS - 1] of Tfloat = (

  {        array index: [VCP_index, elevation_cut]

                                      Elevation Cut
                      1       2       3       4       5       6
                      7       8       9      10      11      12
                     13      14      15      16                    }

      { VCP 11 }   (18.675,  19.224, 19.844, 19.225, 16.116, 17.893,
                    17.898,  17.459, 17.466, 25.168, 25.398, 25.421,
                    25.464,  25.515, 25.596, 25.696),

      { VCP 21 }   (11.339,  11.360, 11.339, 11.360, 11.180, 11.182,
                    11.185,  11.189, 14.260, 14.322, 14.415,  0.000,
                     0.000,   0.000,  0.000,  0.000),

      { VCP 31 }   ( 5.039,   5.061,  5.040,  5.062,  5.041,  5.062,
                     5.063,   5.065,  0.000,  0.000,  0.000,  0.000,
                     0.000,   0.000,  0.000,  0.000),

      { VCP 32 }   ( 4.961,   4.544,  4.961,  4.544,  4.060,  4.061,
                     4.063,   0.000,  0.000,  0.000,  0.000,  0.000,
                     0.000,   0.000,  0.000,  0.000),

      { VCP 300 }  (18.675, 19.224, 19.844, 19.225,  0.000,  0.000,
                     4.063,  0.000,  0.000,  0.000,  0.000,  0.000,
                     0.000,  0.000,  0.000,  0.000),

      { VCP  51 }  (12.000, 12.000, 12.000, 12.000, 12.000, 12.000,
                    12.000, 12.000, 12.000, 12.000, 12.000, 12.000,
                    12.000, 12.000, 12.000, 12.000));

   { wave form type for each elevation cut }
  WF_type: array[0..NUMBER_LOCAL_VCPS - 1, 0..MAX_NUMBER_LOCAL_ELEV_CUTS - 1] of Tunsigned_short = (

  {    ICD values for WF type:
       1 = CS (Continuos Surveillance)
       2 = CD (Continuos Doppler) with Ambiguity Resolution
       3 = CD (Continuos Doppler) without Ambiguity Resolution
       4 = B  (Batch)

       array index: [VCP_index, elevation_cut]  }

      { VCP  11 } (1, 2, 1, 2, 4, 4, 4, 4, 4, 3, 3, 3, 3, 3, 3, 3),
      { VCP  21 } (1, 2, 1, 2, 4, 4, 4, 4, 3, 3, 3, 0, 0, 0, 0, 0),
      { VCP  31 } (1, 2, 1, 2, 1, 3, 3, 3, 0, 0, 0, 0, 0, 0, 0, 0),
      { VCP  32 } (1, 2, 1, 2, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0),
      { VCP 300 } (1, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
      { VCP  51 } (1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1));

   { surveillance prfs for each elev cut }
  cSurv_prf: array[0..NUMBER_LOCAL_VCPS - 1, 0..MAX_NUMBER_LOCAL_ELEV_CUTS - 1] of Tunsigned_short = (

{        array index: [VCP_index, elevation_cut] }

      { VCP  11 } (1, 0, 1, 0, 1, 2, 2, 3, 3, 6, 7, 7, 7, 7, 7, 7),
      { VCP  21 } (1, 0, 1, 0, 2, 2, 2, 3, 7, 7, 7, 0, 0, 0, 0, 0),
      { VCP  31 } (1, 0, 1, 0, 1, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0),
      { VCP  32 } (1, 0, 1, 0, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0),
      { VCP 300 } (1, 0, 5, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
      { VCP  51 } (1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1));

   { Doppler prfs for each elev cut per sector }
  Dop_prf: array[0..NUMBER_LOCAL_VCPS - 1, 0..MAX_NUMBER_LOCAL_ELEV_CUTS - 1, 0..2] of Tunsigned_short= (

  {        array index: [vcp_index][elevation_cut][sector number] }

      { VCP 11 }  ((0,   0,   0),
                   (5,   5,   5),
                   (0,   0,   0),
                   (5,   5,   5),
                   (5,   5,   5),
                   (5,   5,   5),
                   (5,   5,   5),
                   (5,   5,   5),
                   (5,   5,   5),
                   (6,   6,   6),
                   (7,   7,   7),
                   (7,   7,   7),
                   (7,   7,   7),
                   (7,   7,   7),
                   (7,   7,   7),
                   (7,   7,   7)),

      { VCP 21 }  ((0,   0,   0),
                   (5,   5,   5),
                   (0,   0,   0),
                   (5,   5,   5),
                   (5,   5,   5),
                   (5,   5,   5),
                   (5,   5,   5),
                   (5,   5,   5),
                   (7,   7,   7),
                   (7,   7,   7),
                   (7,   7,   7),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0)),

      { VCP 31 }  ((0,   0,   0),
                   (2,   2,   2),
                   (0,   0,   0),
                   (2,   2,   2),
                   (0,   0,   0),
                   (2,   2,   2),
                   (2,   2,   2),
                   (2,   2,   2),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0)),

      { VCP 32 }  ((0,   0,   0),
                   (5,   5,   5),
                   (0,   0,   0),
                   (5,   5,   5),
                   (5,   5,   5),
                   (5,   5,   5),
                   (5,   5,   5),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0)),

      { VCP 300 } ((0,   0,   0),
                   (2,   2,   2),
                   (5,   5,   5),
                   (5,   5,   5),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0)),
      { VCP  51 } ((0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0),
                   (0,   0,   0)));

  Sector_angles: array[0..NUMBER_LOCAL_VCPS - 1, 0..MAX_NUMBER_LOCAL_ELEV_CUTS - 1, 0..2] of Tfloat = (

{        array index: [vcp_index][elevation_cut][sector number] }

      { VCP 11 }  (( 0.0,     0.0,     0.0),
                   (30.0,   210.0,   335.0),
                   ( 0.0,     0.0,     0.0),
                   (30.0,   210.0,   335.0),
                   (30.0,   210.0,   335.0),
                   (30.0,   210.0,   335.0),
                   (30.0,   210.0,   335.0),
                   (30.0,   210.0,   335.0),
                   (30.0,   210.0,   335.0),
                   (30.0,   210.0,   335.0),
                   (30.0,   210.0,   335.0),
                   (30.0,   210.0,   335.0),
                   (30.0,   210.0,   335.0),
                   (30.0,   210.0,   335.0),
                   (30.0,   210.0,   335.0),
                   (30.0,   210.0,   335.0)),

      { VCP 21 }  (( 0.0,     0.0,     0.0),
                   (30.0,   210.0,   335.0),
                   ( 0.0,     0.0,     0.0),
                   (30.0,   210.0,   335.0),
                   (30.0,   210.0,   335.0),
                   (30.0,   210.0,   335.0),
                   (30.0,   210.0,   335.0),
                   (30.0,   210.0,   335.0),
                   (30.0,   210.0,   335.0),
                   (30.0,   210.0,   335.0),
                   (30.0,   210.0,   335.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0)),

      { VCP 31 }  (( 0.0,     0.0,     0.0),
                   (30.0,   210.0,   335.0),
                   ( 0.0,     0.0,     0.0),
                   (30.0,   210.0,   335.0),
                   ( 0.0,     0.0,     0.0),
                   (30.0,   210.0,   335.0),
                   (30.0,   210.0,   335.0),
                   (30.0,   210.0,   335.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0)),

      { VCP 32 }  (( 0.0,     0.0,     0.0),
                   (30.0,   210.0,   335.0),
                   ( 0.0,     0.0,     0.0),
                   (30.0,   210.0,   335.0),
                   (30.0,   210.0,   335.0),
                   (30.0,   210.0,   335.0),
                   (30.0,   210.0,   335.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0)),

      { VCP 300 } (( 0.0,     0.0,     0.0),
                   (30.0,   210.0,   335.0),
                   (30.0,   210.0,   335.0),
                   (30.0,   210.0,   335.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0)),
      { VCP  51 } (( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0),
                   ( 0.0,     0.0,     0.0)));

      { pulse count per radial for local VCPs }
  Surv_pulse_count: array[0..NUMBER_LOCAL_VCPS - 1, 0..MAX_NUMBER_LOCAL_ELEV_CUTS - 1] of Tshort = (

         { VCP  11 } ( 17,  0, 16,  0,  6,  6,  6, 10, 10,   0,  0,  0,  0,  0,  0,  0),
         { VCP  21 } ( 28,  0, 28,  0,  8,  8,  8, 12,  0,   0,  0,  0,  0,  0,  0,  0),
         { VCP  31 } ( 63,  0, 63,  0, 63,  0,  0,  0,  0,   0,  0,  0,  0,  0,  0,  0),
         { VCP  32 } ( 64,  0, 64,  0, 11, 11, 11,  0,  0,   0,  0,  0,  0,  0,  0,  0),
         { VCP 300 } ( 16,  0,  0,  0,  0,  0,  0,  0,  0,   0,  0,  0,  0,  0,  0,  0),
         { VCP  51 } ( 27, 27, 27, 27, 27, 27, 27, 27,  27, 27, 27, 27, 27, 27, 27, 27));

      { pulse count per radial for local VCPs }
  Doppler_pulse_count: array[0..NUMBER_LOCAL_VCPS - 1, 0..MAX_NUMBER_LOCAL_ELEV_CUTS - 1] of Tshort = (

         { VCP  11 } (  0,  52,  0,  52,  41,  41,  41, 41, 41, 43, 46, 46, 46, 46, 46, 46),
         { VCP  21 } (  0,  88,  0,  88,  70,  70,  70, 70, 82, 82, 82,  0,  0,  0,  0,  0),
         { VCP  31 } (  0,  87,  0,  87,   0,  87,  87, 87,  0,  0,  0,  0,  0,  0,  0,  0),
         { VCP  32 } (  0, 220,  0, 220, 220, 220, 220,  0,  0,  0,  0,  0,  0,  0,  0,  0),
         { VCP 300 } (  0,  64, 64,  64,   0,   0,   0,  0,  0,  0,  0,  0,  0,  0,  0,  0),
         { VCP  51 } (  0,   0,  0,   0,   0,   0,   0,  0,  0,  0,  0,  0,  0,  0,  0,  0));

// Change Byte Order routines

procedure CBO_CTMHeader   (var aCTMHeader   : TCTM_Header);

procedure CBO_VSTitle     (var aVSTitle     : TVS_Title);

procedure CBO_RDAStatus   (var aRDAStatus   : TM_RDA_Status);

procedure CBO_Header      (var aHeader      : TMessage_Header );

procedure CBO_DataHeader  (var aDataHeader  : TM_Data_Header);

procedure CBO_VCPHeader   (var aVCPHeader   : TM_VCP_Header);
procedure CBO_VCPElevation(var aVCPElevation: TM_VCP_Elevation);

procedure CBO_RDAControlCommands(var aCommands: TM_RDA_Control_Commands);

procedure CBO_LoopBackTest(var aLBT: TM_Loop_Back_Test);

procedure CBO_CFBMHeader  (var aCFBMHeader  : TM_Clutter_Filter_Bypass_Map_Header);
procedure CBO_CFBMSegment (var aCFBMSegment : TM_Clutter_Filter_Bypass_Map_Segment);

procedure CBO_CFMHeader   (var aCFMHeader   : TM_Clutter_Filter_Map_Header);
procedure CBO_CFMSegment  (var aCFMSegment  : TM_Clutter_Filter_Map_Azimuth_Segment);
procedure CBO_CFMRangeZone(var aCFMRangeZone: TM_Clutter_Filter_Map_Range_Zone);

procedure CBO_DataGenericHeader   (var aDGH: TM_Data_Generic_Header);
procedure CBO_DataGenericVolume   (var aDGV: TM_Data_Generic_Volume);
procedure CBO_DataGenericElevation(var aDGE: TM_Data_Generic_Elevation);
procedure CBO_DataGenericRadial   (var aDGR: TM_Data_Generic_Radial);
procedure CBO_DataGenericMoment   (var aDGM: TM_Data_Generic_Moment);

// value conversion routines

procedure DateTimeToJulianDate_msec(aDateTime: TDateTime; var j_date, m_secof: int4);
procedure DateTimeToJulianDate_min(aDateTime: TDateTime; var j_date, minof: int2);

function AngleToCODEAngle(aAng: single): code2;
function Convert_data_out(data_to_convert: TFloat; data_type: Tint): Tunsigned_short;
function FloatToCode2(val, m: TFloat): code2;

implementation

{$IFDEF CBO_SINGLE_FUNC}
function CBO_Single(aSingle: single): single;
type
  TBR = record
    b0, b1, b2, b3: byte;
  end;
begin
  TBR(aSingle).b0 := TBR(result).b3;
  TBR(aSingle).b1 := TBR(result).b2;
  TBR(aSingle).b2 := TBR(result).b1;
  TBR(aSingle).b3 := TBR(result).b0;
end;
{$ELSE}
procedure CBO_Single(var aSingle: single);
type
  TBR = record
    b0, b1, b2, b3: byte;
  end;
var
  tmp: single;
begin
  tmp := aSingle;
  TBR(aSingle).b0 := TBR(tmp).b3;
  TBR(aSingle).b1 := TBR(tmp).b2;
  TBR(aSingle).b2 := TBR(tmp).b1;
  TBR(aSingle).b3 := TBR(tmp).b0;
end;
{$ENDIF}

procedure CBO_CTMHeader(var aCTMHeader: TCTM_Header);
begin
  with aCTMHeader do
    begin
      typ := ntohl(typ);
      par := ntohl(par);
      len := ntohl(len);
    end;
end;

procedure CBO_VSTitle(var aVSTitle: TVS_Title);
begin
  with aVSTitle do
    begin
      julian_date         := ntohl(julian_date);
      milliseconds_of_day := ntohl(milliseconds_of_day);
    end;
end;

procedure CBO_Header(var aHeader: TMessage_Header );
begin
  with aHeader do
    begin
      message_size               := ntohs(message_size);
      id_sequence_number         := ntohs(id_sequence_number);
      julian_date                := ntohs(julian_date);
      milliseconds_of_day        := ntohl(milliseconds_of_day);
      number_of_message_segments := ntohs(number_of_message_segments);
      message_segment_number     := ntohs(message_segment_number);
    end;
end;

procedure CBO_DataHeader(var aDataHeader: TM_Data_Header);
begin
  with aDataHeader do
    begin
      collection_time                    := ntohl(collection_time);
      modified_julian_date               := ntohs(modified_julian_date);
      unambiguous_range                  := ntohs(unambiguous_range);
      azimuth_angle                      := ntohs(azimuth_angle);
      azimuth_number                     := ntohs(azimuth_number);
      radial_status                      := ntohs(radial_status);
      elevation_angle                    := ntohs(elevation_angle);
      elevation_number                   := ntohs(elevation_number);
      surveillance_range                 := ntohs(surveillance_range);
      doppler_range                      := ntohs(doppler_range);
      surveillance_range_sample_interval := ntohs(surveillance_range_sample_interval);
      doppler_range_sample_interval      := ntohs(doppler_range_sample_interval);
      number_of_surveillance_bins        := ntohs(number_of_surveillance_bins);
      number_of_doppler_bins             := ntohs(number_of_doppler_bins);
      cut_sector_number                  := ntohs(cut_sector_number);
{$IFDEF CBO_SINGLE_FUNC}
      calibration_constant               := CBO_Single(calibration_constant);
{$ELSE}
      CBO_Single(calibration_constant);
{$ENDIF}
      surveillance_pointer               := ntohs(surveillance_pointer);
      velocity_pointer                   := ntohs(velocity_pointer);
      spectral_width_pointer             := ntohs(spectral_width_pointer);
      doppler_velocity_resolution        := ntohs(doppler_velocity_resolution);
      vcp_number                         := ntohs(vcp_number);
      nyquist_velocity                   := ntohs(nyquist_velocity);
      ATMOS                              := ntohs(ATMOS);
      TOVER                              := ntohs(TOVER);
      radial_spot_blanking_status        := ntohs(radial_spot_blanking_status);
    end;
end;

procedure CBO_VCPHeader (var aVCPHeader : TM_VCP_Header);
begin
  with aVCPHeader do
    begin
      message_size             := ntohs(message_size);
      pattern_type             := ntohs(pattern_type);
      pattern_number           := ntohs(pattern_number);
      number_of_elevation_cuts := ntohs(number_of_elevation_cuts);
      clutter_map_group_number := ntohs(clutter_map_group_number);
    end;
end;

procedure CBO_VCPElevation(var aVCPElevation: TM_VCP_Elevation);
begin
  with aVCPElevation do
    begin
      elevation_angle                        := ntohs(elevation_angle);
      surveillance_prf_pulse_count_by_radial := ntohs(surveillance_prf_pulse_count_by_radial);
      azimuth_rate                           := ntohs(azimuth_rate);
      reflectivity_threshold                 := ntohs(reflectivity_threshold);
      velocity_threshold                     := ntohs(velocity_threshold);
      spectrum_width_threshold               := ntohs(spectrum_width_threshold);
      sector1_edge_angle                     := ntohs(sector1_edge_angle);
      sector1_doppler_prf_number             := ntohs(sector1_doppler_prf_number);
      sector1_doppler_prf_count_by_radial    := ntohs(sector1_doppler_prf_count_by_radial);
      sector2_edge_angle                     := ntohs(sector2_edge_angle);
      sector2_doppler_prf_number             := ntohs(sector2_doppler_prf_number);
      sector2_doppler_prf_count_by_radial    := ntohs(sector2_doppler_prf_count_by_radial);
      sector3_edge_angle                     := ntohs(sector3_edge_angle);
      sector3_doppler_prf_number             := ntohs(sector3_doppler_prf_number);
      sector3_doppler_prf_count_by_radial    := ntohs(sector3_doppler_prf_count_by_radial);
    end;
end;

procedure CBO_LoopBackTest(var aLBT: TM_Loop_Back_Test);
begin
  with aLBT do
    message_size := ntohs(message_size);
end;

procedure CBO_CFBMHeader  (var aCFBMHeader  : TM_Clutter_Filter_Bypass_Map_Header);
begin
  with aCFBMHeader do
    begin
      generation_date    := ntohs(generation_date);
      generation_time    := ntohs(generation_time);
      number_of_segments := ntohs(number_of_segments);
    end;
end;

procedure CBO_CFBMSegment (var aCFBMSegment : TM_Clutter_Filter_Bypass_Map_Segment);
var
  i, j: integer;
begin
  with aCFBMSegment do
    begin
      segment_number := ntohs(segment_number);
      for i := 1 to 360 do
        for j := 0 to 31 do
          range_bins[i, j] := ntohs(range_bins[i, j]);
    end;
end;

procedure CBO_RDAStatus   (var aRDAStatus   : TM_RDA_Status);
var
  i: integer;
begin
  with aRDAStatus do
    begin
      RDA_status                         := ntohs(RDA_status);
      operability_status                 := ntohs(operability_status);
      control_status                     := ntohs(control_status);
      auxiliary_power_generator_status   := ntohs(auxiliary_power_generator_status);
      average_transmiter_power           := ntohs(average_transmiter_power);
      reflectivity_calibration_correction:= ntohs(reflectivity_calibration_correction);
      data_transmision_enabled           := ntohs(data_transmision_enabled);
      vcp_number                         := ntohs(vcp_number);
      RDA_control_authorization          := ntohs(RDA_control_authorization);
      RDA_build_number                   := ntohs(RDA_build_number);
      operational_mode                   := ntohs(operational_mode);
      super_resolution_status            := ntohs(super_resolution_status);
      RDA_alarm_summary                  := ntohs(RDA_alarm_summary);
      command_acknowledgment             := ntohs(command_acknowledgment);
      channel_control_status             := ntohs(channel_control_status);
      spot_blanking_status               := ntohs(spot_blanking_status);
      bypass_map_generation_date         := ntohs(bypass_map_generation_date);
      bypass_map_generation_time         := ntohs(bypass_map_generation_time);
      clutter_filter_map_generation_date := ntohs(clutter_filter_map_generation_date);
      clutter_filter_map_generation_time := ntohs(clutter_filter_map_generation_time);
      transition_power_source_status     := ntohs(transition_power_source_status);
      rms_control_status                 := ntohs(rms_control_status);
      for i := 0 to 13 do
        alarm_codes[i]                   := ntohs(alarm_codes[i]);
    end;
end;

procedure CBO_CFMHeader(var aCFMHeader: TM_Clutter_Filter_Map_Header);
begin
  with aCFMHeader do
    begin
      generation_date              := ntohs(generation_date);
      generation_time              := ntohs(generation_time);
      number_of_elevation_segments := ntohs(number_of_elevation_segments);
    end;
end;

procedure CBO_CFMSegment(var aCFMSegment: TM_Clutter_Filter_Map_Azimuth_Segment);
begin
  with aCFMSegment do
    number_of_range_zones :=  ntohs(number_of_range_zones);
end;

procedure CBO_CFMRangeZone(var aCFMRangeZone: TM_Clutter_Filter_Map_Range_Zone);
begin
  with aCFMRangeZone do
    begin
      op_code  := ntohs(op_code);
      end_range:= ntohs(end_range);
    end;
end;

procedure CBO_DataGenericHeader(var aDGH: TM_Data_Generic_Header);
var
  i: integer;
begin
  with aDGH do
    begin
      collection_time         := ntohl(collection_time);
      julian_date             := ntohs(julian_date);
      azimuth_number          := ntohs(azimuth_number);
{$IFDEF CBO_SINGLE_FUNC}
      azimuth_angle           := CBO_Single(azimuth_angle);
      elevation_angle         := CBO_Single(elevation_angle);
{$ELSE}
      CBO_Single(azimuth_angle);
      CBO_Single(elevation_angle);
{$ENDIF}
      radial_length           := ntohs(radial_length);
      data_block_count        := ntohs(data_block_count);
      for i := 1 to 9 do
        data_block_pointer[i] := ntohl(data_block_pointer[i]);
    end;
end;

procedure CBO_DataGenericVolume(var aDGV: TM_Data_Generic_Volume);
begin
  with aDGV do
    begin
      lrtup                            := ntohs(lrtup);
{$IFDEF CBO_SINGLE_FUNC}
      lat                              := CBO_Single(lat);
      long                             := CBO_Single(long);
      calibration_constant             := CBO_Single(calibration_constant);
      horizontal_shv_tx_power          := CBO_Single(horizontal_shv_tx_power);
      vertical_shv_tx_power            := CBO_Single(vertical_shv_tx_power);
      system_diferential_reflectivity  := CBO_Single(system_diferential_reflectivity);
      initial_system_diferential_phase := CBO_Single(initial_system_diferential_phase);
{$ELSE}
      CBO_Single(lat);
      CBO_Single(long);
      CBO_Single(calibration_constant);
      CBO_Single(horizontal_shv_tx_power);
      CBO_Single(vertical_shv_tx_power);
      CBO_Single(system_diferential_reflectivity);
      CBO_Single(initial_system_diferential_phase);
{$ENDIF}
      site_height                      := ntohs(site_height);
      feedhorn_height                  := ntohs(feedhorn_height);
      vcp_number                       := ntohs(vcp_number);
    end;
end;

procedure CBO_DataGenericElevation(var aDGE: TM_Data_Generic_Elevation);
begin
  with aDGE do
    begin
      lrtup                := ntohs(lrtup);
      atmos                := ntohs(atmos);
{$IFDEF CBO_SINGLE_FUNC}
      calibration_constant := CBO_Single(calibration_constant);
{$ELSE}
      CBO_Single(calibration_constant);
{$ENDIF}
    end;
end;

procedure CBO_DataGenericRadial(var aDGR: TM_Data_Generic_Radial);
begin
  with aDGR do
    begin
      lrtup                          := ntohs(lrtup);
      unambiguous_range              := ntohs(unambiguous_range);
{$IFDEF CBO_SINGLE_FUNC}
      horizontal_channel_noise_level := CBO_Single(horizontal_channel_noise_level);
      vertical_channel_noise_level   := CBO_Single(vertical_channel_noise_level);
{$ELSE}
      CBO_Single(horizontal_channel_noise_level);
      CBO_Single(vertical_channel_noise_level);
{$ENDIF}
      nyquist_velocity               := ntohs(nyquist_velocity);
    end;
end;

procedure CBO_DataGenericMoment(var aDGM: TM_Data_Generic_Moment);
begin
  with aDGM do
    begin
      reserved              := ntohl(reserved);
      number_of_gates       := ntohs(number_of_gates);
      range                 := ntohs(range);
      range_sample_interval := ntohs(range_sample_interval);
      tover                 := ntohs(tover);
      snr_threshold         := ntohs(snr_threshold);
{$IFDEF CBO_SINGLE_FUNC}
      scale                 := CBO_Single(scale);
      offset                := CBO_Single(offset);
{$ELSE}
      CBO_Single(scale);
      CBO_Single(offset);
{$ENDIF}
    end;
end;

function AngleToCODEAngle(aAng: single): code2;
begin
  result := Round(aAng / (180/4096)*8)
end;

procedure DateTimeToJulianDate_msec(aDateTime: TDateTime; var j_date, m_secof: int4);
var
  start_date: TDateTime;
begin
  aDateTime  := LocalTimeToZTime(aDateTime);
  start_date := EncodeDateTime(1970, 1, 1, 0, 0, 0, 0);
  j_date     := DaysBetween(start_date, aDateTime) + 1;
  m_secof    := MSecsPerDay - MilliSecondsBetween(IncDay(start_date, j_date), aDateTime);
end;

procedure DateTimeToJulianDate_min(aDateTime: TDateTime; var j_date, minof: int2);
var
  start_date: TDateTime;
begin
  aDateTime  := LocalTimeToZTime(aDateTime);
  start_date := EncodeDateTime(1970, 1, 1, 12, 0, 0, 0);
  j_date     := DaysBetween(start_date, aDateTime) + 1;
  minof      := MinsPerDay - MinutesBetween(IncDay(start_date, j_date), aDateTime);
end;

procedure CBO_RDAControlCommands(var aCommands: TM_RDA_Control_Commands);
begin
  with aCommands do
    begin
      rda_state_command                           := ntohs(rda_state_command);
      base_data_transmission_enable               := ntohs(base_data_transmission_enable);
      auxiliary_power_generator_control           := ntohs(auxiliary_power_generator_control);
      rda_control_commands_and_authorization      := ntohs(rda_control_commands_and_authorization);
      restart_vcp_or_elevation_cut                := ntohs(restart_vcp_or_elevation_cut);
      select_local_vcp_number_for_next_volume_scan:= ntohs(select_local_vcp_number_for_next_volume_scan);
      automatic_calibration_override              := ntohs(automatic_calibration_override);
      super_resolution_control                    := ntohs(super_resolution_control);
      select_operating_mode                       := ntohs(select_operating_mode);
      channel_control_command                     := ntohs(channel_control_command);
      spot_blanking                               := ntohs(spot_blanking);
    end;
end;

function Convert_data_out(data_to_convert: TFloat; data_type: Tint): Tunsigned_short;
begin
  result := 0;
  case data_type of
    VELOCITY_DATA:
      begin
        if data_to_convert < 0 then
          data_to_convert := -data_to_convert + 45;
        result := FloatToCode2(data_to_convert, 45);
      end;
    ANGULAR_ELEV_DATA, ANGULAR_AZM_DATA:
      begin
        if data_to_convert < 0 then
          data_to_convert := 360 + data_to_convert;
        result := FloatToCode2(data_to_convert, 180);
      end;
  end;
  result := result and $FFF8;
end;

function FloatToCode2(val, m: TFloat): code2;
var
  i: integer;
begin
  result := 0;
  for i := 15 downto 0 do
    begin
      if val > m then
        begin
          Inc(result, Trunc(power(2, i)));
          val := val - m;
        end;
      m := m/2;
    end;
end;

end.
