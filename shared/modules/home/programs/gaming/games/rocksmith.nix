#=====================================================================#
# ROCKSMITH 2014 CONFIGURATION
#=====================================================================#
#- Steam game; the Katana DI reaches it through RS_ASIO -> PipeASIO.
#- The RS_ASIO/PipeASIO binaries and launch options are installed by
#- hand, see docs/gaming/rocksmith-2014.md.
{...}: {
  #--------------------------------------------------------------------#
  #-- RS_ASIO
  #--------------------------------------------------------------------#
  #--- Endpoint volume off: in-game calibration drives it to the 0.01 floor.
  #--- 490% makes up for the weak Katana DI (hard strums peak near 0.06).
  home.file.".local/share/Steam/steamapps/common/Rocksmith2014/RS_ASIO.ini".text = ''
    [Config]
    EnableWasapiOutputs=0
    EnableWasapiInputs=0
    EnableAsio=1

    [Asio]
    BufferSizeMode=driver
    CustomBufferSize=

    [Asio.Output]
    Driver=PipeASIO
    BaseChannel=0
    AltBaseChannel=
    EnableSoftwareEndpointVolumeControl=1
    EnableSoftwareMasterVolumeControl=1
    SoftwareMasterVolumePercent=100
    EnableRefCountHack=

    [Asio.Input.0]
    Driver=PipeASIO
    Channel=0
    EnableSoftwareEndpointVolumeControl=0
    EnableSoftwareMasterVolumeControl=1
    SoftwareMasterVolumePercent=490
    EnableRefCountHack=

    [Asio.Input.1]
    Driver=
    Channel=1
    EnableSoftwareEndpointVolumeControl=1
    EnableSoftwareMasterVolumeControl=1
    SoftwareMasterVolumePercent=100
    EnableRefCountHack=

    [Asio.Input.Mic]
    Driver=
    Channel=1
    EnableSoftwareEndpointVolumeControl=1
    EnableSoftwareMasterVolumeControl=1
    SoftwareMasterVolumePercent=100
    EnableRefCountHack=
  '';

  #--------------------------------------------------------------------#
  #-- PipeASIO
  #--------------------------------------------------------------------#
  #--- Line4 is the Katana's dry DI pair (capture ch 3/4). A read-only
  #--- symlink, so PipeASIO's settings panel can no longer save here.
  xdg.configFile."pipeasio/config.ini".text = ''
    [pipeasio]
    input_device=alsa_input.usb-BOSS_KATANA-01.HiFi__Line4__source
    buffer_size=256
  '';
}
