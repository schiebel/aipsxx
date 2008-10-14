#-----------------------------------------------------------------------------
# gridzilla.g: Handler and optional GUI for the Parkes multibeam gridder.
#-----------------------------------------------------------------------------
# Copyright (C) 1996-2006
# Associated Universities, Inc. Washington DC, USA.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: gridzilla.g,v 19.26 2006/07/14 05:28:56 mcalabre Exp $
#-----------------------------------------------------------------------------
# Handler and optional GUI for the Parkes multibeam gridder.
#
# Arguments (string representation of numeric values is allowed):
#    config            string   'DEFAULTS', 'GENERAL', 'CONTINUUM', 'HIPASS',
#                               'HVC', 'METHANOL', 'ZOA', 'MOPRA', or 'AUDS'.
#    client_name       string   Name of the gridder client.
#    client_dir        string   Directory containing client executable.  May
#                               be blank to use PATH.
#    client_host       string   Host on which to run the gridder client.
#    cubcen_dir        string   Directory containing standard cube centre
#                               files, HIPASS_CUBE_CENTRES & HVC_CUBE_CENTRES.
#    remote            boolean  If true, we are being remotely controlled.
#                               Certain GUI functions are disabled.
#    beamsel           bool[13] Mask of beams selected subject to their
#                               presence in the data.
#    rangeSpec         string   Spectral range specification, 'FREQUENCY' or
#                               'VELOCITY'.
#    startSpec         double   Start spectral frequency or radio velocity.
#    endSpec           double   End spectral frequency or radio velocity.
#    restFreq          double   Line rest frequency, in MHz.
#    IFsel             bool[16] Mask of IFs selected subject to their presence
#                               in the data.
#    pol_op            string   'A&B': Spectra from both polarizations are
#                                      aggregated before averaging, the
#                                      distinction between polarizations being
#                                      ignored.
#                                 'A': Process only 'A' polarization data, 'B'
#                                      polarization data is ignored.
#                                 'B': Process only 'B' polarization data, 'A'
#                                      polarization data is ignored.
#                               'A+B': Add the spectra for each polarization
#                                      before averaging.
#                               'A-B': Subtract the spectra for each
#                                      polarization before averaging.
#    spectral          boolean  Produce spectral cube.
#    continuum         boolean  Produce continuum and spectral index maps.
#    baseline          boolean  Produce baseline polynomial coefficient cube.
#    directories       string   Directory search path for data files.
#    filemask          string   Wildcard specification(s) for input files
#                               (other than HIPASS, HVC, and ZOA
#                               configurations).
#    filext            string   File extensions of input datasets (HIPASS, HVC
#                               and ZOA configurations).
#    files             string[] List of data files.
#    selection         int[]    Selected input files.
#    HIPASS_field      string   Field centres on a fixed grid for HIPASS,
#                      or int   HIPASS cube number.
#    HVC_field         string   Field centres on a fixed grid for HVC,
#                      or int   HVC cube number.
#    ZOA_field         string   ZOA galactic longitude (deg),
#                      or int   ZOA galactic longitude (deg).
#    cull              boolean  Cull flagged files from the input list for
#                               standard fields?  (Uses 'coverage' utility.)
#    projection        string   Map projection; valid codes are listed below.
#    pv                double[20]
#                               Projection parameters, first element is PVi_0.
#    coordSys          string   Coordinate system: EQUATORIAL (J2000.0),
#                               GALACTIC, or FEED-PLANE.
#    refpoint          boolean  Specify reference point?  Else it is tied to
#                               the map centre.
#    reference_lng     double   Celestial longitude of the reference point,
#                               see note 1.
#    reference_lat     double   Celestial latitude  of the reference point
#                               (deg).
#    lonpole           double   Native longitude of the celestial pole (deg).
#    latpole           double   Native latitude  of the celestial pole (deg).
#    autosize          boolean  Set image centre and extent to encompass input
#                               data?
#    intrefpix         boolean  Round reference pixel coordinates to the
#                               nearest integer?
#    centre_lng        double   Central longitude, see note 1.
#    centre_lat        double   Central latitude (deg).
#    pixel_width       double   Pixel width and height; should always be
#                               4 arcmin for HIPASS, HVC and ZOA cubes.
#    pixel_height      double
#    image_width       int      For HIPASS, image width=170 and image
#                               height=160 pixels, except H001 which is 200 x
#                               200.
#                               For HVC, image width=540 and image
#                               height=420 pixels, except C01 which is 650 x
#                               650.
#    image_height      int
#    tsysmin           double   Data with Tsys equal to or below this value
#                               will be discarded.  Note that Tsys was set to
#                               25 to flag data in HIPASS.
#    tsysmax           double   Data with Tsys equal to or above this value
#                               will be discarded.
#    datamin           double   Individual spectral channels that are equal to
#                               or below this value will be rejected.
#    datamax           double   Individual spectral channels that are equal to
#                               or above this value will be rejected.
#    chan_err          double   Reject spectra that, because of Doppler-
#                               rescaling of the frequency axis, cannot be
#                               registered on the fiducial frequency grid to
#                               within this many channels.
#    statistic         string[] Statistical estimator:
#                                 'WGTMED'   the weighted median of the values
#                                            as opposed to
#                                 'MEDIAN'   which is the median of the
#                                            weighted values.
#                                 'MEAN'     sum(wgt*value)/sum(wgt).
#                                 'SUM'      sum(wgt*value).
#                                 'RSS'      sqrt(sum(square(wgt*value))).
#                                 'QUARTILE' wgtmed{|X - wgtmed(X)|} and
#                                            measures the inter-quartile range
#                                            of the pixel values.
#                                 'NSPECTRA' number of spectra contributing to
#                                            each pixel.
#                                 'WEIGHT'   sum(wgt).
#                                 'BEAMSUM'  sum of beam weights alone
#                                            (excluding Tsys and smoothing
#                                            weights).
#                                 'BEAMRSS'  root sum of squares of beam
#                                            weights, a measure of the
#                                            sensitivity.
#    clip_fraction     int      Percentage of data to discard in the smoothing
#                               operation.
#    tsys_weight       boolean  Apply Tsys weighting?
#    beam_weight       int      Beam weighting is based on the beam response
#                               calculated for the distance of each spectrum
#                               from the pixel.
#                                 0: No beam weighting.
#                                 1: Weight spectra by beam response.
#                                 2: Weight spectra by square of beam response.
#                                 3: Weight spectra by cube   of beam response.
#    beam_FWHM         double   Beam full width at half maximum, in arcmin.
#    beam_normal       boolean  Apply beam normalization?
#    kernel_type       string   Smoothing kernel function:
#                                 TOP-HAT
#                                 GAUSSIAN
#    kernel_FWHM       double   FWHM in arcmin of the smoothing kernel.
#    cutoff_radius     double   The smoothing cutoff radius should always be
#                               6 arcmin for HIPASS, HVC and ZOA cubes.
#    blank_level       double   Pixels for which the root sum of squares of
#                               beam weights is less than this value will be
#                               blanked.
#    storage           int      Percentage of the processor memory to make
#                               available to the gridder.
#    spectype          string   FITS spectral axis type required in the output
#                               cube; the input is assumed always to be linear
#                               in frequency.
#                                 Frequency types:
#                                   FREQ, AFRQ, ENER, WAVN, VRAD
#                                 Wavelength types:
#                                   WAVE-F2W, VOPT-F2W, ZOPT-F2W
#                                 Velocity types:
#                                   VELO-F2V, BETA-F2V
#                                 AIPS convention types:
#                                   VELO-xxx, FELO-xxx
#    short_int         boolean  Small means 16-bit FITS integer on scale -8 to
#                               32 Jy, else IEEE floating.
#    write_dir         string   Output FITS directory.
#    p_FITSfilename    string   Output FITS file name without extension.
#    sources           record   Simulation source parameters, see below.
#
# Received events:
#    setparm(record)     Set parameter values.
#    setconfig(string)   Set configuration to 'DEFAULTS', 'GENERAL',
#                        'CONTINUUM', 'HIPASS', 'HVC', 'METHANOL', 'ZOA',
#                        'MOPRA', or 'AUDS'.
#    printparms()        Show parameter values.
#    printvalid()        Print parameter validation rules.
#    lock()              Disable parameter entry.
#    unlock()            Enable parameter entry.
#    go(record)          Start gridding.  Parameter values may optionally be
#                        specified.
#    HIPASS_field(string|int)
#                        Process a HIPASS field (string) or cube number (int).
#    HVC_field(string|int)
#                        Process a HVC field (string) or cube number (int).
#    ZOA_field(string|int)
#                        Process a ZOA field.
#    abort()             Abort gridding.
#    showgui(agent)      Create the GUI or make it visible if it already
#                        exists.  The parent frame may be specified.
#    hidegui()           Make the GUI invisible.
#    terminate()         Close down.
#
# Sent events:
#    finished()          Processing finished.
#    guidone()           Finished constructing GUI.
#    done()              Agent has terminated.
#
# Notes:
#    1) reference_lng and centre_lng are set as hr or deg depending on
#       the coordinate system but are stored internally in degrees.
#
#    2) Simulation source parameters (not currently implemented in the GUI)
#       are specified as a record with record-valued fields of the form
#
#       parms.sources :=
#         [source001 = [ra=-60.0, dec=-60.0, flux=1.0, width=0.0,
#                       start_channel=200, end_channel=300],
#          source002 = [ra=+60.0, dec=-60.0, flux=2.0, width=0.0,
#                       start_channel=250, end_channel=350],
#          source003 = [ra=-60.0, dec=+60.0, flux=3.0, width=14.0,
#                       start_channel=200, end_channel=300],
#          source004 = [ra=+60.0, dec=+60.0, flux=4.0, width=14.0,
#                       start_channel=250, end_channel=350]]
#
#       Sources are listed consecutively from source001 to source999.  The
#       record fields are ra and dec offsets in arcmin, peak flux in Jy, and
#       FWHM in arcmin.  The channel range is inclusive and refers to actual
#       correlator channels, not cube channels.
#
# Original: 1998/05/22, Mark Calabretta
#-----------------------------------------------------------------------------

pragma include once

include 'pkslib.g'

const gridzilla := subsequence(config         = 'GENERAL',
                               client_name    = 'pksgridzilla',
                               client_dir     = '',
                               client_host    = 'localhost',
                               cubcen_dir = '/nfs/atapplic/multibeam/archive',
                               remote         = F,
                               beamsel        = [T,T,T,T,T,T,T,T,T,T,T,T,T],
                               rangeSpec      = 'FREQUENCY',
                               startSpec      = 0.0,
                               endSpec        = 200000.0,
                               restFreq       = 1420.40575,
                               IFsel          = array(T, 16),
                               pol_op         = 'A&B',
                               spectral       = T,
                               continuum      = T,
                               baseline       = F,
                               directories    = '.',
                               filemask       = '*.sdfits',
                               filext         = 'sdfits ms2cal',
                               files          = "",
                               selection      = [],
                               HIPASS_field   = '0000-90',
                               HVC_field      = '0000-90',
                               ZOA_field      = '216',
                               cull           = T,
                               projection     = 'SIN',
                               pv             = array(0.0, 20),
                               coordSys       = 'EQUATORIAL',
                               refpoint       = F,
                               reference_lng  = '00:00:00.0',
                               reference_lat  = '-90:00:00',
                               lonpole        = 999.0,
                               latpole        = 999.0,
                               autosize       = F,
                               intrefpix      = T,
                               centre_lng     = '00:00:00.0',
                               centre_lat     = '-90:00:00',
                               pixel_width    = 4.0,
                               pixel_height   = 4.0,
                               image_width    = 170,
                               image_height   = 160,
                               tsysmin        = 22.0,
                               tsysmax        = 10000.0,
                               datamin        = -10000.0,
                               datamax        =  10000.0,
                               chan_err       =  0.1,
                               statistic      = "WGTMED",
                               clip_fraction  = 0,
                               tsys_weight    = F,
                               beam_weight    = 1,
                               beam_FWHM      = 14.4,
                               beam_normal    = T,
                               kernel_type    = 'TOP-HAT',
                               kernel_FWHM    = 12.0,
                               cutoff_radius  = 6.0,
                               blank_level    = 0.0,
                               storage        = 25,
                               spectype       = 'FREQ',
                               short_int      = F,
                               write_dir      = '.',
                               p_FITSfilename = 'gridzilla',
                               sources        = [=]) : [reflect=T]
{
  # Our identity.
  self.name := 'gridzilla'
  self.file := 'gridzilla.g'

  # Recognized map projections.
    projections := [
      Zenithal = [
        AZP = [PVn = 102, name = 'Zenithal perspective'],
        SZP = [PVn = 103, name = 'Slant zenithal perspective'],
        TAN = [PVn =   0, name = 'Gnomonic'],
        STG = [PVn =   0, name = 'Stereographic'],
        SIN = [PVn = 102, name = 'Slant orthographic'],
        NCP = [PVn =   0, name = 'North Celestial Pole'],
        ARC = [PVn =   0, name = 'Zenithal equidistant'],
        ZPN = [PVn = 020, name = 'Zenithal polynomial'],
        ZEA = [PVn =   0, name = 'Zenithal equal area'],
        AIR = [PVn = 101, name = 'Airy']],
      Cylindrical = [
        CYP = [PVn = 102, name = 'Cylindrical perspective'],
        CEA = [PVn = 101, name = 'Cylindrical equal area'],
        CAR = [PVn =   0, name = 'Plate carree'],
        MER = [PVn =   0, name = 'Mercator']],
      Pseudo_cylindrical = [
        SFL = [PVn =   0, name = 'Sanson-Flamsteed'],
        PAR = [PVn =   0, name = 'Parabolic'],
        MOL = [PVn =   0, name = 'Mollweide\'s']],
      Conventional = [
        AIT = [PVn =   0, name = 'Hammer-Aitoff']],
      Conic = [
        COP = [PVn = 102, name = 'Conic perspective'],
        COE = [PVn = 102, name = 'Conic equal area'],
        COD = [PVn = 102, name = 'Conic equidistant'],
        COO = [PVn = 102, name = 'Conic orthomorphic']],
      Polyconic = [
        BON = [PVn = 101, name = 'Bonne\'s'],
        PCO = [PVn =   0, name = 'Polyconic']],
      Quad_cube = [
        TSC = [PVn =   0, name = 'Tangential spherical cube'],
        CSC = [PVn =   0, name = 'COBE Quadrilateralized spherical cube'],
        QSC = [PVn =   0, name = 'Quadrilateralized spherical cube']],
      HEALPix = [
        HPX = [PVn = 102, name = 'HEALPix']]]

  for (type in field_names(projections)) {
    for (pcode in field_names(projections[type])) {
      pcodes[pcode] := projections[type][pcode].PVn
    }
  }


  # Parameter values.
  parms := [=]

  # Parameter value checking.
  pchek := [
    config         = [string  = [default = 'GENERAL',
                                 valid   = "DEFAULTS GENERAL CONTINUUM \
                                            HIPASS HVC METHANOL ZOA MOPRA \
                                            AUDS"]],
    client_name    = [string  = [default = 'pksgridzilla']],
    client_dir     = [string  = [default = '']],
    client_host    = [string  = [default = 'localhost',
                                 invalid = '']],
    cubcen_dir     = [string  = [default = '/nfs/atapplic/multibeam/archive']],
    remote         = [boolean = [default = F]],
    beamsel        = [boolean = [default = [T,T,T,T,T,T,T,T,T,T,T,T,T]]],
    rangeSpec      = [string  = [default = 'FREQUENCY',
                                 valid   = "FREQUENCY VELOCITY"]],
    startSpec      = [double  = [default = 0.0,
                                 maximum =  299792.458]],
    endSpec        = [double  = [default =  99999.0,
                                 maximum =  299792.458]],
    restFreq       = [double  = [default = 1420.40575,
                                 exclmin = 0.0]],
    IFsel          = [boolean = [default = array(T, 16)]],
    pol_op         = [string  = [default = 'A&B',
                                 valid   = "A&B A B A+B A-B"]],
    spectral       = [boolean = [default = T]],
    continuum      = [boolean = [default = T]],
    baseline       = [boolean = [default = T]],
    directories    = [string  = [default = '.',
                                 invalid = '']],
    filemask       = [string  = [default = '*.sdfits']],
    filext         = [string  = [default = 'sdfits ms2cal']],
    files          = [string  = [default = ""]],
    selection      = [integer = [default = []]],
    HIPASS_field   = [string  = [default = '0000-90',
                                 valid   = m|\d\d\d\d[+-]\d\d|],
                      integer = [minimum = 1,
                                 maximum = 538,
                                 format  = 'H%.3d']],
    HVC_field      = [string  = [default = '0000-90',
                                 valid   = m|\d\d\d\d[+-]\d\d|],
                      integer = [minimum = 1,
                                 maximum = 56,
                                 format  = 'C%.2d']],
    ZOA_field      = [string  = [default = '216',
                                 valid   = sprintf('%.3d',
                                           [seq(200, 352, 8), seq(0, 48, 8)])],
                      integer = [valid   = [seq(200, 352, 8), seq(0, 48, 8)],
                                 format  = '%.3d']],
    cull           = [boolean = [default = T]],
    projection     = [string  = [default = 'SIN',
                                 valid   = field_names(pcodes)]],
    pv             = [double  = [default = array(0.0, 20)]],
    coordSys       = [string  = [default = 'EQUATORIAL',
                                 valid   = "EQUATORIAL GALACTIC FEED-PLANE"]],
    refpoint       = [boolean = [default = F]],
    reference_lng  = [double  = [default =    0.0,
                                 minimum = -360.0,
                                 maximum = +364.0,
                                 sexages = T]],
    reference_lat  = [double  = [default = -90.0,
                                 minimum = -90.0,
                                 maximum =  90.0,
                                 sexages = 'angle']],
    lonpole        = [double  = [default =  999.0,
                                 minimum = -180.0,
                                 maximum =  180.0,
                                 allowed =  999.0,
                                 sexages = 'angle']],
    latpole        = [double  = [default =  999.0,
                                 sexages = 'angle']],
    autosize       = [boolean = [default = F]],
    intrefpix      = [boolean = [default = T]],
    centre_lng     = [double  = [default =    0.0,
                                 minimum = -360.0,
                                 maximum = +360.0,
                                 sexages = T]],
    centre_lat     = [double  = [default = -90.0,
                                 minimum = -90.0,
                                 maximum =  90.0,
                                 sexages = 'angle']],
    pixel_width    = [double  = [default = 4.0,
                                 exclmin = 0.0]],
    pixel_height   = [double  = [default = 4.0,
                                 exclmin = 0.0]],
    image_width    = [integer = [default = 170,
                                 minimum = 1]],
    image_height   = [integer = [default = 160,
                                 minimum = 1]],
    tsysmin        = [double  = [default = 22.0,
                                 minimum = 0.0]],
    tsysmax        = [double  = [default = 10000.0,
                                 minimum = 0.0]],
    datamin        = [double  = [default = -10000.0]],
    datamax        = [double  = [default =  10000.0]],
    chan_err       = [double  = [default = 0.1,
                                 minimum = 0.0,
                                 maximum = 1.0]],
    statistic      = [string  = [default = "WGTMED",
                                 varlen  = -11,
                                 valid   = "WGTMED MEDIAN MEAN SUM RSS RMS \
                                            QUARTILE NSPECTRA WEIGHT BEAMSUM \
                                            BEAMRSS"]],
    clip_fraction  = [integer = [default = 0,
                                 minimum = 0,
                                 maximum = 100]],
    tsys_weight    = [boolean = [default = F]],
    beam_weight    = [integer = [default = 1,
                                 valid   = 0:3]],
    beam_FWHM      = [double  = [default = 14.4,
                                 exclmin = 0.0]],
    beam_normal    = [boolean = [default = T]],
    kernel_type    = [string  = [default = 'TOP-HAT',
                                 valid   = "TOP-HAT GAUSSIAN"]],
    kernel_FWHM    = [double  = [default = 12.0,
                                 exclmin = 0.0]],
    cutoff_radius  = [double  = [default = 6.0,
                                 exclmin = 0.0]],
    blank_level    = [double  = [default = 0.0,
                                 mininum = 0.0]],
    storage        = [integer = [default = 25,
                                 minimum = 0,
                                 maximum = 500]],
    spectype       = [string  = [default = 'FREQ',
                                   valid = "FREQ AFRQ ENER WAVN VRAD \
                                            WAVE-F2W VOPT-F2W ZOPT-F2W \
                                            VELO-F2V BETA-F2V \
                                            VELO-xxx FELO-xxx"]],
    short_int      = [boolean = [default = F]],
    write_dir      = [string  = [default = '.',
                                 invalid = '']],
    p_FITSfilename = [string  = [default = 'gridzilla',
                                 invalid = '']],
    sources        = [record  = [default = [=]]]]

  if (!streq(field_names(pchek), field_names(parameters()))) {
    fail spaste(self.file, ': internal inconsistency - pchek field names.')
  }

  # Version number maintained by RCS.
  wrk := [=]
  wrk.RCSid    := "$Revision: 19.26 $$Date: 2006/07/14 05:28:56 $"
  wrk.version  := spaste(wrk.RCSid[2], ', ', wrk.RCSid[4])
  wrk.lastexit := './gridzilla.lastexit'

  # Work variables.
  wrk.client := F

  wrk.host   := system.host ~ s|\..*||
  wrk.hosts  := [=]

  wrk.locked  := F
  wrk.logfile := shell("date +'gridzilla-%Y%m%d.log'")
  wrk.logger  := pkslogger(file=wrk.logfile, utc=F, reuse=T, share=T)
  wrk.search  := F

  wrk.coverage      := [=]
  wrk.HIPASS_fields := ""
  wrk.HIPASS_cubes  := [=]
  wrk.HIPASS_scans  := [=]
  wrk.HVC_fields    := ""
  wrk.HVC_cubes     := [=]
  wrk.HVC_scans     := [=]
  wrk.ZOA_fields    := ""


  # GUI widgets.
  gui := [f1 = F]


  #---------------------------------------------------------------------------
  #  Local function definitions.
  #---------------------------------------------------------------------------
  local coverage, file_search, go, helpmsg, HIPASS_fields, HVC_fields,
        message, readgui, set := [=], sethelp, setparm, showgui, showmenu

  #------------------------------------------------------------------ coverage

  # Run one of the various 'coverage' scripts to determine the files required
  # for the standard HIPASS, HVC or ZOA cubes.  The cube argument is specified
  # as a string of format
  #
  #    'H%.3d'   ...HIPASS
  #    'C%.2d'   ...HVC
  #    'Z%.3d'   ...ZOA

  const coverage := function(cube)
  {
    wider wrk

    if (has_field(wrk.coverage, cube)) return

    message('Running coverage for ', cube, '...')

    # Need to run coverage.
    if (cube ~ m|^H|) {
      # HIPASS cube.
      hino := cube ~ s|^H||
      pipe := open(paste('coverage.pl     -c', hino, '-m abcde -q 1 |'))

    } else if (cube ~ m|^C|) {
      # HVC cube.
      pipe := open(paste('coverage-hvc.pl -c', cube, '-m abcde -q 1 |'))

    } else if (cube ~ m|^Z|) {
      # ZOA cube.
      glon := cube ~ s|^Z||
      pipe := open(paste('coverage-zoa.pl -l', glon, '-m a-y   -q 1 |'))

    } else {
      # Unrecognized.
      return
    }

    wrk.coverage[cube] := ""
    j := -1
    while (rec := read(pipe)) {
      if (rec ~ m/^Searching/) {j := 0 ; continue}
      if (rec ~ m/^Search ends/) break
      if (j < 0) continue
      j +:= 1
      wrk.coverage[cube][j] := rec ~ s|\n$|| ~ s|\t$||
    }

    message()
  }

  #--------------------------------------------------------------- file_search

  # Find files in the specified directory search path.

  const file_search := function()
  {
    wider wrk

    # Skip if we are being remotely controlled.
    if (parms.remote || !wrk.search) return

    if (is_agent(gui.f1)) {
      # Set watch cursor.
      gui.f1->cursor('watch')
      message('Searching...')

      gui[spaste(parms.config, '_field')].bn->text('Searching...')

      gui.files.lb->delete('start', 'end')
      gui.files.lb->insert('Searching...')

      # Update directory search path.
      setparm([directories = gui.directories.en->get(),
               filemask    = gui.filemask.en->get(),
               filext      = gui.filext.en->get()])
    }


    selection := []

    if (!any(parms.config == "HIPASS HVC ZOA")) {
      # Search all specified directories for the specified extensions.
      files := ""
      for (dir in split(parms.directories ~ s|[ ,:]+| |g)) {
        dirls := shell('ls', dir, '2>/dev/null ; true')
        if (is_fail(dirls) || len(dirls) == 0) continue

        dirls := dirls[dirls ~ filexp(parms.filemask)]

        # Collect the files found in this directory.
        if (len(dirls)) {
          eval(spaste('pattern := s|$| (in ', dir, ')|'))
          files := [files, dirls ~ pattern]
        }
      }

    } else {
      # Select only those files required for this standard cube.
      scans := [=]

      if (parms.config == 'HIPASS') {
        cube := sprintf('H%.3d', wrk.HIPASS_cube)

        # Scans required for this cube.
        dec := parms.HIPASS_field ~ s|^....(...)$|$1|
        scans[dec ~ s|\+|p|] := wrk.HIPASS_scans[wrk.HIPASS_cube]

        # Scan letters.
        alpha := "a b c d e"

      } else if (parms.config == 'HVC') {
        cube := sprintf('C%.2d', wrk.HVC_cube)

        # Scans required for this cube.
        for (dec in field_names(wrk.HVC_scans[wrk.HVC_cube])) {
          scans[dec ~ s|\+|p|] := wrk.HVC_scans[wrk.HVC_cube][dec]
        }

        # Scan letters.
        alpha := "a b c d e"

      } else if (parms.config == 'ZOA') {
        cube := spaste('Z', parms.ZOA_field)

        # Scans required for this cube.
        scans[parms.ZOA_field] := 1:17

        # Scan letters.
        alpha := "a b c d e f g h i j k l m n o p q r s t u v w x y"
      }

      # Sub-scan counts.
      count := array(0, len(alpha))

      ifile := 0
      nreq  := 0
      files := ""
      for (zone in field_names(scans)) {
        message('Searching for files in zone ', zone, '...')

        # Do wildcard search.
        zonels := ''
        for (dir in split(parms.directories ~ s|[ ,:]+| |g)) {
          dirls := shell('ls', dir, '2>/dev/null ; true')
          if (is_fail(dirls) || len(dirls) == 0) continue

          if (parms.config == 'ZOA') {
            eval(spaste('pattern := m/.*_', zone,
                        '[p-]\\d{6}_\\d\\d[a-y]\\.(',
                        parms.filext ~ s/ /|/g, ')$/'))
          } else {
            eval(spaste('pattern := m/.*_\\d{6}', zone,
                        '_\\d\\d\\d[a-e]\\.(',
                        parms.filext ~ s/ /|/g, ')$/'))
          }
          dirls := dirls[dirls ~ pattern]

          # Collect the files found in this directory.
          if (len(dirls)) {
            eval(spaste('pattern := s|^|', dir, '/|'))
            zonels := [zonels, dirls ~ pattern]
          }
        }

        for (scan in scans[zone]) {
          nreq +:= 1

          # This helps for really large directory listings.
          if (len(zonels)) {
            if (parms.config == 'ZOA') {
              eval(sprintf('pattern := m|.*_%s......._%.2d[a-y]\\\\.|', zone,
                            scan))
            } else {
              eval(sprintf('pattern := m|.*%s_%.3d[a-e]\\\\.|', zone, scan))
            }

            scanls := zonels[zonels ~ pattern]

          } else {
            scanls := ""
          }

          for (letter in alpha) {
            # Construct scan specification string and regexp for it.
            if (parms.config == 'ZOA') {
              spec := sprintf('%s_%.2d%c', zone, scan, letter)
              eval(sprintf('pattern := m|.*_%s......._%.2d%c\\\\.|', zone,
                            scan, letter))
            } else {
              spec := sprintf('%s_%.3d%c', zone, scan, letter)
              eval(spaste('pattern := m|.*', spec, '\\.|'))
            }

            # Files that match the scan specification.
            if (len(scanls)) {
              specls := scanls[scanls ~ pattern]
            } else {
              specls := ""
            }

            # Cull out flagged files?
            if (parms.cull && len(specls)) {
              coverage(cube)

              for (file in specls) {
                name := file ~ s|.*/(.*)\..*|$1|

                message('Checking ', name)

                if (!any(wrk.coverage[cube] == name)) {
                  # Cull it.
                  specls := specls[specls != file]
                }
              }
            }

            if (len(specls)) {
              # Reformat.
              specls := sort(specls ~ s|(.*)/(.*)|$2 (in $1)| ~ s|^9|  9|)

              if (len(specls) > 1) {
                print '\nWARNING: Multiple files found for', spec
                for (file in specls) {
                  print '  ', file
                }
              }

              prev := ''
              for (file in specls) {
                this := split(file)[1]
                if (this == prev) {
                  # N.B. the directory list is a search path.
                  continue
                }

                ifile +:= 1
                files[ifile] := spaste(spec, ': ', file)
                selection := [selection, ifile]

                prev := this
              }

              count[alpha == letter] +:= 1

            } else {
              ifile +:= 1
              files[ifile] := spaste(spec, ': not found')
            }
          }
        }
      }

      # Construct the default output file name.
      if (all(count == nreq)) {
        suffix := ''
      } else if (all(count == 0)) {
        suffix := '_???'
      } else if (any(count > 0 & count < nreq)) {
        suffix := spaste('_', spaste(alpha[count > 0]), '_partial')
      } else {
        suffix := spaste('_', spaste(alpha[count > 0]))
      }

      setparm([p_FITSfilename = spaste(cube, suffix)])
    }


    # Update the listbox.
    setparm([files = files, selection = selection])

    if (is_agent(gui.f1)) {
      if (any(parms.config == "HIPASS HVC ZOA")) {
        gotone := len(parms.selection)
      } else {
        gotone := len(files)
      }

      if (gotone) {
        message()
      } else {
        message('Nothing found in search path')
      }

      # Restore default cursor.
      gui.f1->cursor('')
    }
  }

  #------------------------------------------------------------------------ go

  # Initialize the gridder and start it running.

  const go := function()
  {
    global system
    wider wrk

    if (is_agent(gui.f1)) {
      # Disable the "Go" button.
      if (is_agent(gui.go.bn)) {
        if (wrk.locked) gui.f1->enable()
        gui.go.bn->disabled(T)
        if (wrk.locked) gui.f1->disable()
      }

      # Read all entry boxes.
      readgui()
    }

    # Construct the gridder argument list.
    args := [=]

    args.beamsel   := parms.beamsel
    args.rangeSpec := parms.rangeSpec
    args.startSpec := parms.startSpec
    args.endSpec   := parms.endSpec
    args.restFreq  := parms.restFreq
    args.IFsel     := parms.IFsel
    args.pol_op    := parms.pol_op
    args.spectral  := parms.spectral
    args.continuum := parms.continuum
    args.baseline  := parms.baseline

    args.directories := split(parms.directories ~ s|[ ,:]+| |g)
    args.files := parms.files[parms.selection] ~ s|.*: +|| ~ s| \(in .*||
    if (len(args.files)) {
      args.files := unique(args.files[args.files != 'not found'])
    }

    if (any(parms.config == "HIPASS HVC ZOA")) {
      # Resort the files into survey order.
      if (parms.config == 'ZOA') {
        index := args.files ~ s|.*_(\d\d[a-y])\..*|$1|
      } else {
        index := args.files ~ s|.*_(\d\d\d[a-e])\..*|$1|
      }
      args.files := sort_pair(index, args.files)
    }

    args.projection    := parms.projection
    args.pv            := parms.pv
    args.coordSys      := parms.coordSys
    args.refpoint      := parms.refpoint
    args.reference_lng := parms.reference_lng
    args.reference_lat := parms.reference_lat
    args.lonpole       := parms.lonpole
    args.latpole       := parms.latpole

    args.autosize := parms.autosize
    if (!parms.autosize) {
      args.intrefpix  := parms.intrefpix
      args.centre_lng := parms.centre_lng
      args.centre_lat := parms.centre_lat

      args.image_width  := parms.image_width
      args.image_height := parms.image_height
    }

    args.pixel_width   := parms.pixel_width
    args.pixel_height  := parms.pixel_height

    args.tsysmin       := parms.tsysmin
    args.tsysmax       := parms.tsysmax
    args.datamin       := parms.datamin
    args.datamax       := parms.datamax
    args.chan_err      := parms.chan_err
    args.statistic     := parms.statistic
    args.clip_fraction := parms.clip_fraction/100.0
    args.tsys_weight   := parms.tsys_weight
    args.beam_weight   := parms.beam_weight
    args.beam_FWHM     := parms.beam_FWHM
    args.beam_normal   := parms.beam_normal
    args.kernel_type   := parms.kernel_type
    args.kernel_FWHM   := parms.kernel_FWHM
    args.cutoff_radius := parms.cutoff_radius
    args.blank_level   := parms.blank_level

    args.storage       := as_integer(wrk.memory*parms.storage/100)

    args.spectype  := parms.spectype
    args.short_int := parms.short_int
    args.p_FITSfilename := spaste(parms.write_dir, '/', parms.p_FITSfilename)
    if (any(parms.config == "HIPASS HVC ZOA")) {
      args.counts := 'scan'
    } else {
      args.counts := 'spectra'
    }

    args.sources := parms.sources

    # Basic checks.
    if (is_fail(args.files) || len(args.files) == 0) {
      print 'No input files were selected, job dropped.'
      if (is_agent(gui.f1)) {
        message('No files selected, job dropped.')
        if (wrk.locked) gui.f1->enable()
        gui.go.bn->disabled(F)
        if (wrk.locked) gui.f1->disable()
      }
      self->finished()
      return
    }

    # Start gridder.
    # wrk.client := create_agent()	# Echo-client, used for debugging.
    if (parms.client_dir == '') {
      gridder := spaste(parms.client_name)
    } else {
      gridder := spaste(parms.client_dir, '/', parms.client_name)
    }
    message('Starting ',gridder)

    if (parms.client_host == wrk.host) {
      # Local execution.
      wrk.client := client(gridder)
    } else {
      # Remote execution.
      if (parms.client_dir != '' ) system.path.bin.default := parms.client_dir
      wrk.client := client(gridder, host=parms.client_host)
    }

    whenever
      wrk.client->log do
        wrk.logger->log($value)

    whenever
      wrk.client->done,
      wrk.client->fail do {
        wrk.client := F
        if (is_agent(gui.f1)) {
          if (wrk.locked) gui.f1->enable()
          if (is_agent(gui.go.bn)) gui.go.bn->disabled(F)
          gui.abort.bn->disabled(T)
          if (wrk.locked) gui.f1->disable()

          if ($name == 'done') {
            message('Processing completed')
            wrk.logger->log([location='gridzilla',
                             message='Processing completed.',
                             priority='NORMAL'])
          } else {
            message('Processing failed')
# Causes glish segv when processing is aborted manually?!
#            wrk.logger->log([location='gridzilla',
#                             message='PROCESSING FAILED.', priority='SEVERE'])
          }
        }
        self->finished()
      }

    wrk.client->init(args)
    wrk.client->go()

    if (is_agent(gui.f1)) {
      message('Processing on ', parms.client_host)
      if (wrk.locked) gui.f1->enable()
      gui.abort.bn->disabled(F)
      if (wrk.locked) gui.f1->disable()
    }
  }

  #------------------------------------------------------------------- helpmsg

  # Write a widget help message.

  const helpmsg := function(msg='')
  {
    if (is_agent(gui.helpmsg)) gui.helpmsg->text(msg)
  }

  #------------------------------------------------------------- HIPASS_fields

  # Load HIPASS field centres and scan numbers.

  const HIPASS_fields := function(msg='')
  {
    wider config, wrk

    # HIPASS field centres and scan numbers.
    file := open(spaste('< ', parms.cubcen_dir, '/HIPASS_CUBE_CENTRES'))
    if (is_fail(file)) {
      print 'HIPASS_CUBE_CENTRES: file not found.'
      if (config == 'HIPASS') config := 'GENERAL'

    } else {
      i := 0
      while (a := read(file)) {
        a := split(a)
        if (len(a) < 3) continue
        if (a[1] == '#') continue
        ra  := a[2] ~ s|...$||
        dec := a[2] ~ s|^....||
        i +:= 1
        wrk.HIPASS_fields[i] := spaste(ra,dec)
        wrk.HIPASS_cubes[dec][ra] := i
        wrk.HIPASS_scans[i] := as_integer(a[3:len(a)])
      }
    }
  }

  #---------------------------------------------------------------- HVC_fields

  # Load HVC field centres and scan numbers.

  const HVC_fields := function(msg='')
  {
    wider config, wrk

    file := open(spaste('< ', parms.cubcen_dir, '/HVC_CUBE_CENTRES'))
    if (is_fail(file)) {
      print 'HVC_CUBE_CENTRES: file not found.'
      if (config == 'HVC') config := 'GENERAL'

    } else {
      i := 0
      while (a := read(file)) {
        a := split(a)
        if (a[1] !~ m/^C\d\d/) continue
        ra  := a[2] ~ s|...$||
        dec := a[2] ~ s|^....||
        i +:= 1
        wrk.HVC_fields[i] := spaste(ra,dec)
        wrk.HVC_cubes[dec][ra] := i

        wrk.HVC_scans[i] := [=]
        for (j in 1:3) {
          a := read(file)
          a := split(a)
          dec := a[1] ~ s|\((.*)\)|$1|
          wrk.HVC_scans[i][dec] := as_integer(a[2:len(a)])
        }
      }
    }
  }

  #------------------------------------------------------------------- message

  # Write a status message.

  const message := function(...)
  {
    if (is_agent(gui.f1)) gui.status.la->text(spaste(...))
  }

  #------------------------------------------------------------------- readgui

  # Read values from entry boxes.

  const readgui := function()
  {
    if (is_agent(gui.f1)) {
      setparm([startSpec      = gui.startSpec.en->get(),
               endSpec        = gui.endSpec.en->get(),
               restFreq       = gui.restFreq.en->get(),
               directories    = gui.directories.en->get(),
               filemask       = gui.filemask.en->get(),
               filext         = gui.filext.en->get(),
               selection      = gui.files.lb->selection() + 1,
               pv             = [gui.pv.en[1]->get(),
                                 gui.pv.en[2]->get(),
                                 gui.pv.en[3]->get(),
                                 gui.pv.en[4]->get()],
               reference_lng  = gui.reference_lng.en->get(),
               reference_lat  = gui.reference_lat.en->get(),
               lonpole        = gui.lonpole.en->get(),
               latpole        = gui.latpole.en->get(),
               centre_lng     = gui.centre_lng.en->get(),
               centre_lat     = gui.centre_lat.en->get(),
               pixel_width    = gui.pixel_width.en->get(),
               pixel_height   = gui.pixel_height.en->get(),
               image_width    = gui.image_width.en->get(),
               image_height   = gui.image_height.en->get(),
               tsysmin        = gui.tsysmin.en->get(),
               tsysmax        = gui.tsysmax.en->get(),
               datamin        = gui.datamin.en->get(),
               datamax        = gui.datamax.en->get(),
               chan_err       = gui.chan_err.en->get(),
               clip_fraction  = gui.clip_fraction.en->get(),
               beam_FWHM      = gui.beam_FWHM.en->get(),
               kernel_FWHM    = gui.kernel_FWHM.en->get(),
               cutoff_radius  = gui.cutoff_radius.en->get(),
               blank_level    = gui.blank_level.en->get(),
               client_host    = gui.client_host.en->get(),
               storage        = gui.storage.en->get(),
               write_dir      = gui.write_dir.en->get(),
               p_FITSfilename = gui.p_FITSfilename.en->get()])
    }
  }

  #------------------------------------------------------------------ sethelp

  # Set up the help message for a widget.

  const sethelp := function(ref widget, msg='')
  {
    if (!gui.dohelp) return

    widget.helpmsg := msg

    widget->bind('<Enter>', 'Enter')
    widget->bind('<Leave>', 'Leave')

    whenever
      widget->Enter do
        helpmsg(widget.helpmsg)

    whenever
      widget->Leave do
        helpmsg('')
  }

  #------------------------------------------------------------------- setparm

  # setparm() updates parameter values, also updating any associated widget(s)
  # using showparm() if the GUI is active.
  #
  # Given:
  #    rawvals     record   Each field name, item, identifies the parameter as
  #
  #                           parms[item]
  #
  #                        The field values, subject to validation, are the
  #                        new parameter settings.

  const setparm := function(rawvals)
  {
    wider parms

    # Do parameter validation.
    values := validate(pchek, parms, rawvals, is_agent(gui.f1))

    if (len(parms) == 0) {
      # Initialize parms.
      parms := values
    }

    for (item in field_names(values)) {
      rawval := rawvals[item]
      value  := values[item]

      # print spaste('item=', item, ', value=', rawval, '::',
      #              as_string(rawval::), ' (', type_name(rawval), ') -> ',
      #              value, '::', as_string(value::), ' (', type_name(value),
      #              ')')

      if (has_field(set, item)) {
        # Invoke specialized update procedure.
        set[item](value)

      } else {
        # Update the parameter value.
        parms[item] := value
      }

      rec := [=]
      rec[item] := parms[item]
      showparm(gui, rec)
    }
  }

  #------------------------------------------------------------ set.centre_lng

  # Set the celestial longitude of the central point.

  const set.centre_lng := function(value)
  {
    wider parms

    parms.centre_lng := resex(value, parms.coordSys == 'EQUATORIAL')
    if (!parms.refpoint) setparm([reference_lng = parms.centre_lng])
  }

  #------------------------------------------------------------ set.centre_lat

  # Set the celestial latitude of the central point.

  const set.centre_lat := function(value)
  {
    wider parms

    parms.centre_lat := resex(value, F)
    if (!parms.refpoint) setparm([reference_lat = parms.centre_lat])
  }

  #----------------------------------------------------------- set.client_host

  # Set the processor host and determine how much memory it has.

  const set.client_host := function(value)
  {
    wider parms, wrk

    parms.client_host := value

    if (has_field(wrk.hosts, parms.client_host)) {
      # Use cached value.
      wrk.memory := wrk.hosts[parms.client_host]

      if (has_field(wrk.hosts[parms.client_host]::, 'assumed')) {
        message('Warning: ', wrk.memory,' MByte memory for ',
                       parms.client_host, ' is assumed.')
      } else {
        message()
      }

    } else {
      if (parms.client_host == 'localhost') {
        parms.client_host := wrk.host
      }

      # This usually takes a while...
      if (is_agent(gui.f1)) {
        gui.memory.sv->text('% of ...')
        message('Determining memory for ', parms.client_host, '...')
      }

      # Check the processor host.
      if (parms.client_host != wrk.host) {
        # Make sure we can rsh to it.
        status := shell('rsh', parms.client_host,
                        'hostname 2> /dev/null || exit 0')

        if (len(status) == 0) {
          message('Could not rsh to ', parms.client_host, ' reverting to ',
                  wrk.host)
          parms.client_host := wrk.host
        }
      }

      # How much memory (in MB) to make available to the gridder.
      if (parms.client_host == wrk.host) {
        sysinfo := shell('/usr/local/bin/sysinfo',
                         '-class General -show memory -format report',
                         '2>/dev/null')
      } else {
        sysinfo := shell('rsh', parms.client_host, '/usr/local/bin/sysinfo',
                         '-class General -show memory -format report',
                         '2>/dev/null')
      }

      sysinfo := split(sysinfo)
      if (len(sysinfo) > 9 && sysinfo[10] == 'MB') {
        wrk.memory := as_integer(sysinfo[9])
        wrk.hosts[parms.client_host] := wrk.memory
        message()

      } else if (len(sysinfo) > 9 && sysinfo[10] == 'GB') {
        wrk.memory := as_integer(as_double(sysinfo[9]) * 1000)
        wrk.hosts[parms.client_host] := wrk.memory
        message()

      } else {
        # 'sysinfo' failed - try 'top'.
        if (parms.client_host == wrk.host) {
          top := shell('top -b -n 1 | awk \'/^Mem/{print $2}\'')
        } else {
          top := shell('rsh', parms.client_host, 'top -b -n 1 |',
                       'awk \'/^Mem/{print $2}\'')
        }

        # Default memory value is 100 MByte.
        wrk.memory := 100
        if (len(top) && top ~ m|[MkKG]$|) {
          if (top ~ m|M$|) {
            wrk.memory := as_integer(top ~ s/M$//)
          } else if (top ~ m|[kK]$|) {
            wrk.memory := as_integer(as_integer(top ~ s/[kK]$//)/1000)
          } else if (top ~ m|G$|) {
            wrk.memory := as_integer(top ~ s/G$//)*1000
          }
          wrk.hosts[parms.client_host] := wrk.memory
          message()

        } else {
          # 'top' failed too - assume the default.
          message('Couldn\'t determine memory for ', parms.client_host,
                         ', assuming ', wrk.memory, ' MByte.')
          wrk.hosts[parms.client_host] := wrk.memory
          wrk.hosts[parms.client_host]::assumed := T
        }
      }
    }
  }

  #---------------------------------------------------------------- set.config

  # Set the processing configuration, enforcing HIPASS, HVC or ZOA parameter
  # restrictions.

  const set.config := function(value)
  {
    wider parms

    if (any(parms.config == "HIPASS HVC ZOA") &&
       !any(value == "HIPASS HVC ZOA")) {
      # This avoids a trap for the unwary.
      ram := as_integer(4*parms.centre_lng + 0.5)
      rah := as_integer(ram / 60)
      ram := ram%60
      dec := as_integer(parms.centre_lat)
      setparm([p_FITSfilename = sprintf('%.2d%.2d%+.2d', rah, ram, dec),
               short_int = F])
    }

    parms.config := value

    if (parms.config == 'DEFAULTS') {
      for (parm in field_names(pchek)) {
        args[parm] := pchek[parm][1].default
      }
      setparm(args)

    } else if (any(parms.config == "HIPASS HVC ZOA")) {
      # Set standard gridding parameters.
      setparm([beamsel       = [T,T,T,T,T,T,T,T,T,T,T,T,T],
               rangeSpec     = 'FREQUENCY',
               startSpec     = 1426.5,
               endSpec       = 1362.5625,
               restFreq      = 1420.40575,
               IFsel         = [T,T,F,F,F,F,F,F,F,F,F,F,F,F,F,F],
               pol_op        = 'A&B',
               spectral      = T,
               projection    = 'SIN',
               pv            = array(0.0, 20),
               refpoint      = F,
               pixel_width   = 4.0,
               pixel_height  = 4.0,
               tsysmin       = 25.0,
               tsysmax       = 10000.0,
               datamin       = -10000.0,
               datamax       =  10000.0,
               chan_err      =  0.1,
               statistic     = "MEDIAN",
               clip_fraction = 0,
               tsys_weight   = F,
               beam_FWHM     = 14.4,
               kernel_type   = 'TOP-HAT',
               kernel_FWHM   = 12.0,
               cutoff_radius = 6.0,
               blank_level   = 0.0,
               spectype      = 'VRAD',
               sources       = [=]])

      # Set standard fields.
      if (parms.config == 'HIPASS') {
        setparm([autosize    = F,
                 beam_weight = 1,
                 beam_normal = T,
                 short_int   = T])

        if (has_field(value::, 'field')) {
          setparm([HIPASS_field = value::field])
        } else {
          setparm([HIPASS_field = parms.HIPASS_field])
        }

      } else if (parms.config == 'HVC') {
        setparm([autosize    = F,
                 beam_weight = 0,
                 beam_normal = F,
                 short_int   = F])

        if (has_field(value::, 'field')) {
          setparm([HVC_field = value::field])
        } else {
          setparm([HVC_field = parms.HVC_field])
        }

      } else if (parms.config == 'ZOA') {
        setparm([autosize    = T,
                 beam_weight = 1,
                 beam_normal = T,
                 short_int   = T])

        if (has_field(value::, 'field')) {
          setparm([ZOA_field = value::field])
        } else {
          setparm([ZOA_field = parms.ZOA_field])
        }
      }

    } else if (parms.config == 'METHANOL') {
      setparm([beamsel       = [T,T,T,T,T,T,T,F,F,F,F,F,F],
               rangeSpec     = 'FREQUENCY',
               startSpec     = 0.0,
               endSpec       = 200000.0,
               restFreq      = 6668.5192,
               IFsel         = [T,F,F,F,F,F,F,F,F,F,F,F,F,F,F,F],
               pol_op        = 'A+B',
               spectral      = T,
               continuum     = F,
               baseline      = F,
               projection    = 'SIN',
               pv            = array(0.0, 20),
               refpoint      = F,
               coordSys      = 'GALACTIC',
               refpoint      = F,
               autosize      = T,
               pixel_width   = 1.0,
               pixel_height  = 1.0,
               tsysmin       = 22.0,
               tsysmax       = 10000.0,
               datamin       = -10000.0,
               datamax       =  10000.0,
               chan_err      =  0.5,
               statistic     = "MEAN WGTMED",
               clip_fraction = 0,
               tsys_weight   = F,
               beam_weight   = 2,
               beam_FWHM     = 4.4,
               beam_normal   = T,
               kernel_type   = 'TOP-HAT',
               kernel_FWHM   = 4.4,
               cutoff_radius = 2.2,
               blank_level   = 0.0,
               spectype      = 'VRAD',
               sources       = [=]])

    } else if (parms.config == 'MOPRA') {
      setparm([beamsel       = [T,F,F,F,F,F,F,F,F,F,F,F,F],
               rangeSpec     = 'VELOCITY',
               startSpec     = -1000.0,
               endSpec       = +1000.0,
               restFreq      = 110201.353,
               IFsel         = [T,T,F,F,F,F,F,F,F,F,F,F,F,F,F,F],
               pol_op        = 'A&B',
               spectral      = T,
               continuum     = F,
               baseline      = F,
               projection    = 'SIN',
               pv            = array(0.0, 20),
               refpoint      = F,
               autosize      = T,
               pixel_width   = 0.25,
               pixel_height  = 0.25,
               tsysmin       = 0.0,
               tsysmax       = 10000.0,
               datamin       = -10000.0,
               datamax       =  10000.0,
               chan_err      =  0.1,
               statistic     = "MEAN",
               clip_fraction = 0,
               tsys_weight   = F,
               beam_weight   = 0,
               beam_FWHM     = 0.77,
               beam_normal   = F,
               kernel_type   = 'GAUSSIAN',
               kernel_FWHM   = 0.55,
               cutoff_radius = 0.55,
               blank_level   = 0.0,
               spectype      = 'VELO-XXX',
               sources       = [=]])

    } else if (parms.config == 'AUDS') {
      setparm([beamsel       = [T,T,T,T,T,T,T,F,F,F,F,F,F],
               restFreq      = 1420.40575,
               IFsel         = [T,F,F,F,F,F,F,F,F,F,F,F,F,F,F,F],
               pol_op        = 'A&B',
               spectral      = T,
               projection    = 'SIN',
               pv            = array(0.0, 20),
               refpoint      = F,
               autosize      = F,
               centre_lng    = '00:00:04.0',
               centre_lat    = '15:42:41',
               pixel_width   = 1.0,
               pixel_height  = 5.2,
               image_width   = 45,
               image_height  = 3,
               tsysmin       = 1.0,
               tsysmax       = 10000.0,
               datamin       = -0.050,
               datamax       =  0.050,
               chan_err      =  0.1,
               statistic     = "WGTMED MEAN RMS QUARTILE",
               clip_fraction = 0,
               tsys_weight   = F,
               beam_FWHM     = 3.4,
               kernel_type   = 'TOP-HAT',
               kernel_FWHM   = 3.0,
               cutoff_radius = 1.5,
               blank_level   = 0.0,
               spectype      = 'FREQ',
               sources       = [=]])

    } else {
      if (parms.config == 'CONTINUUM') {
        setparm([continuum = T])
      }

      setparm([tsysmin = 22.0,
               tsysmax = 10000.0])

      # Search for files.
      file_search()
    }
  }

  #-------------------------------------------------------------- set.coordSys

  # Set coordinate system.

  const set.coordSys := function(value)
  {
    wider parms
    wider centre_lat, centre_lng, reference_lat, reference_lng

    if (value != parms.coordSys) {
      # Transform coordinates.
      if (parms.coordSys == 'GALACTIC' && value == 'EQUATORIAL') {
        # Convert galactic to equatorial J2000.0.
        gal2equ(parms.reference_lng, parms.reference_lat,
                reference_lng, reference_lat)
        gal2equ(parms.centre_lng, parms.centre_lat, centre_lng, centre_lat)

      } else if (parms.coordSys == 'EQUATORIAL' && value == 'GALACTIC') {
        # Convert equatorial J2000.0 to galactic.
        equ2gal(parms.reference_lng, parms.reference_lat,
                reference_lng, reference_lat)
        equ2gal(parms.centre_lng, parms.centre_lat, centre_lng, centre_lat)

      } else if (value == 'FEED-PLANE') {
        reference_lng := '00:00:00'
        reference_lat := '90:00:00'
        centre_lng    := '00:00:00'
        centre_lat    := '90:00:00'

      } else {
        parms.coordSys := value
        return
      }

      parms.coordSys := value
      setparm([reference_lng = reference_lng,
               reference_lat = reference_lat,
               centre_lng    = centre_lng,
               centre_lat    = centre_lat])
    }
  }

  #-------------------------------------------------------------- set.filemask

  # Set the wildcard specification(s) for input files.

  const set.filemask := function(value)
  {
    wider parms

    parms.filemask := value ~ s|[ ,:]+| |g
  }

  #---------------------------------------------------------------- set.filext

  # Set the file suffix of input datasets.

  const set.filext := function(value)
  {
    wider parms

    parms.filext := value ~ s|[ ,:]+| |g
  }

  #---------------------------------------------------------- set.HIPASS_field

  # Set HIPASS field centre.

  const set.HIPASS_field := function(value)
  {
    wider parms, wrk

    if (len(wrk.HIPASS_fields) == 0) return

    # Update HIPASS field.
    if (value ~ m|H\d\d\d|) {
      value := as_integer(value ~ s|H||)
      parms.HIPASS_field := wrk.HIPASS_fields[value]
    } else {
      parms.HIPASS_field := value
    }

    # Parse the field name.
    rah := parms.HIPASS_field ~ s/^(..).....$/$1/
    ram := parms.HIPASS_field ~ s/^..(..)...$/$1/
    dec := parms.HIPASS_field ~ s/^....(...)$/$1/

    # Update the HIPASS cube number.
    ra := spaste(rah, ram)
    wrk.HIPASS_cube := wrk.HIPASS_cubes[dec][ra]

    if (parms.config == 'HIPASS') {
      # Update coordinates.
      setparm([coordSys   = 'EQUATORIAL',
               refpoint   = F,
               lonpole    = 999.0,
               latpole    = 999.0,
               centre_lng = spaste(rah, ':', ram),
               centre_lat = dec])

      # Update the image size.
      if (parms.HIPASS_field == '0000-90') {
        setparm([image_width = 200, image_height = 200])
      } else {
        setparm([image_width = 170, image_height = 160])
      }

      file_search()
    }
  }

  #------------------------------------------------------------- set.HVC_field

  # Set HVC field centre.

  const set.HVC_field := function(value)
  {
    wider parms, wrk

    if (len(wrk.HVC_fields) == 0) return

    # Update HVC field.
    if (value ~ m|C\d\d|) {
      value := as_integer(value ~ s|C||)
      parms.HVC_field := wrk.HVC_fields[value]
    } else {
      parms.HVC_field := value
    }

    # Parse the field name.
    rah := parms.HVC_field ~ s/^(..).....$/$1/
    ram := parms.HVC_field ~ s/^..(..)...$/$1/
    dec := parms.HVC_field ~ s/^....(...)$/$1/

    # Update the HVC cube number.
    ra := spaste(rah, ram)
    wrk.HVC_cube := wrk.HVC_cubes[dec][ra]

    if (parms.config == 'HVC') {
      # Update coordinates.
      setparm([coordSys   = 'EQUATORIAL',
               refpoint   = F,
               lonpole    = 999.0,
               latpole    = 999.0,
               centre_lng = spaste(rah, ':', ram),
               centre_lat = dec])

      # Update the image size.
      if (parms.HVC_field == '0000-90') {
        setparm([image_width = 650, image_height = 650])
      } else {
        setparm([image_width = 540, image_height = 420])
      }

      file_search()
    }
  }

  #------------------------------------------------------------- set.rangeSpec

  # The spectral range may be specified as a frequency or radio velocity.

  const set.rangeSpec := function(value)
  {
    wider parms

    reset := parms.rangeSpec != value
    parms.rangeSpec := value

    if (parms.rangeSpec != 'FREQUENCY' &&
        parms.rangeSpec != 'VELOCITY') parms.rangeSpec := 'FREQUENCY'

    # Convert frequency to/from radio velocity.
    if (reset) {
      if (is_agent(gui.f1)) {
        setparm([restFreq  = gui.restFreq.en->get(),
                 startSpec = gui.startSpec.en->get(),
                 endSpec   = gui.endSpec.en->get()])
      }

      if (parms.rangeSpec == 'FREQUENCY') {
        freq := parms.restFreq * (1.0 - parms.startSpec/299792.458)
        setparm([startSpec = freq])
        freq := parms.restFreq * (1.0 - parms.endSpec/299792.458)
        setparm([endSpec = freq])
      } else {
        vel := 299792.458 * (1.0 - parms.startSpec/parms.restFreq)
        setparm([startSpec = vel])
        vel := 299792.458 * (1.0 - parms.endSpec/parms.restFreq)
        setparm([endSpec = vel])
      }
    }
  }

  #--------------------------------------------------------- set.reference_lng

  # Set the celestial longitude of the reference point.

  const set.reference_lng := function(value)
  {
    wider parms

    parms.reference_lng := resex(value, parms.coordSys == 'EQUATORIAL')
  }

  #--------------------------------------------------------- set.reference_lat

  # Set the celestial latitude of the reference point.

  const set.reference_lat := function(value)
  {
    wider parms

    parms.reference_lat := resex(value, F)
  }

  #-------------------------------------------------------------- set.refpoint

  # Specify reference point?  Else it is tied to the map centre.

  const set.refpoint := function(value)
  {
    wider parms

    parms.refpoint := value

    if (!parms.refpoint) {
      setparm([reference_lng = parms.centre_lng,
               reference_lat = parms.centre_lat])
    }
  }

  #------------------------------------------------------------- set.statistic

  # Set the gridding statistic

  const set.statistic:= function(value)
  {
    wider parms

    parms.statistic := value

    if (all(parms.statistic == 'NSPECTRA' |
            parms.statistic == 'WEIGHT'   |
            parms.statistic == 'BEAMSUM'  |
            parms.statistic == 'BEAMRSS')) {
      setparm([blank_level = 0.0])
    }
  }

  #--------------------------------------------------------------- set.storage

  # Determine the amount of memory to use.

  const set.storage := function(value)
  {
    wider parms

    parms.storage := value

    if (parms.storage <= 0 || parms.storage > 100) {
      # Allocate a quarter of the available memory.
      if (!has_field(wrk.hosts[parms.client_host]::, 'assumed')) {
        parms.storage := 25

        if (wrk.memory <= 48) {
          # Probably someone's personal machine.
          parms.storage := 75
        }
      }
    }
  }

  #------------------------------------------------------------- set.write_dir

  # Determine the fully-qualified output directory.

  const set.write_dir := function(value)
  {
    wider parms

    parms.write_dir := value

    # Resolve relative pathnames.
    parms.write_dir := spaste(shell('cd', parms.write_dir, ' && pwd'))
  }

  #------------------------------------------------------------- set.ZOA_field

  # Set ZOA field centre.

  const set.ZOA_field := function(value)
  {
    wider parms
    local dec, ra

    parms.ZOA_field := value

    # Convert galactic field centre to equatorial J2000.0.
    gal2equ(as_double(value),0,ra,dec)
    ra  := resex(ra,  F)
    dec := resex(dec, F)
    ra::format.precision  := 0
    dec::format.precision := 0

    # Update coordinates.
    setparm([coordSys   = 'EQUATORIAL',
             refpoint   = F,
             centre_lng = ra,
             centre_lat = dec,
             lonpole    = 999.0,
             latpole    = 999.0])

    if (parms.config == 'ZOA') file_search()
  }

  #------------------------------------------------------------------- showgui

  # Build a graphical user interface for the gridder client.
  # If the parent frame is not specified a separate window will be created.

  const showgui := function(parent=F)
  {
    wider gui, parms, wrk

    if (is_agent(gui.f1)) {
      # Show the GUI and bring it to the top of the window stack.
      gui.f1->map()
      gui.f1->raise()
      return
    }

    # Check whether DISPLAY is defined.
    if (!has_field(environ, 'DISPLAY')) {
       print 'DISPLAY environment variable is not set, can\'t construct GUI!'
       return
    }

    # Parent window.
    tk_hold()
    if (is_agent(parent)) {
      gui.f1 := parent
      gui.f1->side('top')
      gui.f1->title(spaste('Parkes Multibeam Gridder (v', wrk.version,
                                   ')'))
    } else {
      gui.f1 := frame(title=spaste('Parkes Multibeam Gridder(v', wrk.version,
                                   ')'), icon='gridzilla.xbm')

      if (is_fail(gui.f1)) {
        wrk.logger->log([location='gridzilla',
                         message='GUI construction failed.', priority='WARN'])
        return
      }
    }

    gui.helpmsg := T
    if (is_record(parent) && has_field(parent, 'helpmsg')) {
      gui.helpmsg := parent.helpmsg
    }
    gui.dohelp := is_agent(gui.helpmsg) || gui.helpmsg

    gui.f11 := frame(gui.f1, side='left', borderwidth=0)

    #=========================================================================
    # Data selection panel.
    gui.f111  := frame(gui.f11, borderwidth=4, relief='ridge')
    gui.f1111 := frame(gui.f111, side='left', expand='x')
    gui.datasel.la := label(gui.f1111, 'INPUT DATA SELECTION',
                            foreground='#0000a0')
    sethelp(gui.datasel.la, 'Input data selection panel.')

    # Beam selection ---------------------------------------------------------
    gui.f1112  := frame(gui.f111, side='left', borderwidth=0, expand='x')
    gui.f11121 := frame(gui.f1112, side='left', relief='ridge', padx=4,
                       expand='y')
    sethelp(gui.f11121, 'Input beam selection')
    gui.f111211 := frame(gui.f11121, side='left', expand='none')

    # Define a record with 13 fields.
    gui.beamsel.bn := [=]
    for (j in 1:13) gui.beamsel.bn[j] := F

    gui.f1112111  := frame(gui.f111211, borderwidth=0)
    gui.f11121111 := frame(gui.f1112111, height=35, width=0, expand='none')
    gui.beamsel.bn[8]  := button(gui.f1112111,  '8', value=8,  width=1, padx=4,
                                 pady=1)
    sethelp(gui.beamsel.bn[8], 'Select or deselect input for beam 8.')

    gui.f1112112 := frame(gui.f111211, borderwidth=0)
    gui.beamsel.bn[13] := button(gui.f1112112, '13', value=13, width=1, padx=4,
                                 pady=1)
    sethelp(gui.beamsel.bn[13], 'Select or deselect input for beam 13.')
    gui.beamsel.bn[7]  := button(gui.f1112112,  '7', value=7,  width=1, padx=4,
                                 pady=1)
    sethelp(gui.beamsel.bn[7], 'Select or deselect input for beam 7.')
    gui.beamsel.bn[2]  := button(gui.f1112112,  '2', value=2,  width=1, padx=4,
                                 pady=1)
    sethelp(gui.beamsel.bn[2], 'Select or deselect input for beam 2.')
    gui.beamsel.bn[9]  := button(gui.f1112112,  '9', value=9,  width=1, padx=4,
                                 pady=1)
    sethelp(gui.beamsel.bn[9], 'Select or deselect input for beam 9.')

    gui.f1112113  := frame(gui.f111211, borderwidth=0)
    gui.f11121131 := frame(gui.f1112113, height=12, width=0, expand='none')
    gui.beamsel.bn[6]  := button(gui.f1112113,  '6', value=6,  width=1, padx=4,
                                 pady=1)
    sethelp(gui.beamsel.bn[6], 'Select or deselect input for beam 6.')
    gui.beamsel.bn[1]  := button(gui.f1112113,  '1', value=1,  width=1, padx=4,
                                 pady=1)
    sethelp(gui.beamsel.bn[1], 'Select or deselect input for beam 1.')
    gui.beamsel.bn[3]  := button(gui.f1112113,  '3', value=3,  width=1, padx=4,
                                 pady=1)
    sethelp(gui.beamsel.bn[3], 'Select or deselect input for beam 3.')

    gui.f1112114 := frame(gui.f111211, borderwidth=0)
    gui.beamsel.bn[12] := button(gui.f1112114, '12', value=12, width=1, padx=4,
                                 pady=1)
    sethelp(gui.beamsel.bn[12], 'Select or deselect input for beam 12.')
    gui.beamsel.bn[5]  := button(gui.f1112114,  '5', value=5,  width=1, padx=4,
                                 pady=1)
    sethelp(gui.beamsel.bn[5], 'Select or deselect input for beam 5.')
    gui.beamsel.bn[4]  := button(gui.f1112114,  '4', value=4,  width=1, padx=4,
                                 pady=1)
    sethelp(gui.beamsel.bn[4], 'Select or deselect input for beam 4.')
    gui.beamsel.bn[10] := button(gui.f1112114, '10', value=10, width=1, padx=4,
                                 pady=1)
    sethelp(gui.beamsel.bn[10], 'Select or deselect input for beam 10.')

    gui.f1112115  := frame(gui.f111211, borderwidth=0)
    gui.f11121151 := frame(gui.f1112115, height=35, width=0, expand='none')
    gui.beamsel.bn[11] := button(gui.f1112115, '11', value=11, width=1, padx=4,
                                 pady=1)
    sethelp(gui.beamsel.bn[11], 'Select or deselect input for beam 11.')

    whenever
      gui.beamsel.bn[1]->press,
      gui.beamsel.bn[2]->press,
      gui.beamsel.bn[3]->press,
      gui.beamsel.bn[4]->press,
      gui.beamsel.bn[5]->press,
      gui.beamsel.bn[6]->press,
      gui.beamsel.bn[7]->press,
      gui.beamsel.bn[8]->press,
      gui.beamsel.bn[9]->press,
      gui.beamsel.bn[10]->press,
      gui.beamsel.bn[11]->press,
      gui.beamsel.bn[12]->press,
      gui.beamsel.bn[13]->press do {
        if (parms.beamsel[$value]) {
          parms.beamsel[$value] := F
        } else {
          parms.beamsel[$value] := T
        }
        setparm([beamsel = parms.beamsel])
      }


    # Spectral range ---------------------------------------------------------
    gui.f11122  := frame(gui.f1112, relief='ridge')
    sethelp(gui.f11122, 'Input selection by data type.')
    gui.f111221 := frame(gui.f11122, side='left')

    gui.rangeSpec.bn  := button(gui.f111221, type='menu', relief='groove',
                                width=14)
    sethelp(gui.rangeSpec.bn, 'Spectral range specification, frequency or \
                               radio velocity (does conversions).')
    showmenu('rangeSpec')

    gui.startSpec.en := entry(gui.f111221, width=10, justify='left', fill='x')
    sethelp(gui.startSpec.en, 'First channel of spectrum (set extreme to \
                               get whole range in data).')

    whenever
      gui.startSpec.en->return do
        setparm([startSpec = $value])

    gui.chan_sep.la := label(gui.f111221, '-')
    sethelp(gui.chan_sep.la, 'The ordering is honoured, output spectra will \
                              be inverted if necessary.')

    gui.endSpec.en  := entry(gui.f111221, width=10, justify='left', fill='x')
    sethelp(gui.endSpec.en, 'Last channel of spectrum (set extreme to get \
                             whole range in data).')

    whenever
      gui.endSpec.en->return do
        setparm([endSpec = $value])

    gui.rangeSpec.la := label(gui.f111221, width=3)


    # Rest frequency ---------------------------------------------------------
    gui.f111222  := frame(gui.f11122, side='left')
    gui.f1112221 := frame(gui.f111222, borderwidth=0)

    gui.f11122211 := frame(gui.f1112221, side='left', borderwidth=0)
    gui.restFreq.la := label(gui.f11122211, 'Line rest frequency')

    gui.restFreq.en  := entry(gui.f11122211, width=16, justify='right',
                              fill='x')
    sethelp(gui.f11122211, 'Line rest frequency (for frequency/velocity \
                            conversions).')

    gui.restFreq.la2 := label(gui.f11122211, 'MHz', justify='left')

    whenever
      gui.restFreq.en->return do
        setparm([restFreq = $value])

    # IF selection -----------------------------------------------------------
    gui.f11122212 := frame(gui.f1112221, side='left', borderwidth=0)

    gui.f111222121    := frame(gui.f11122212, relief='sunken', borderwidth=1,
                               expand='none')

    gui.f1112221211   := frame(gui.f111222121, side='right', borderwidth=0,
                               expand='none')

    gui.f11122212111  := frame(gui.f1112221211, borderwidth=0, expand='none')
    gui.f111222121111 := frame(gui.f11122212111, side='left', borderwidth=0,
                              expand='none')
    gui.f111222121112 := frame(gui.f11122212111, side='left', borderwidth=0,
                              expand='none')

    # Define a record with 16 fields.
    gui.IFsel.bn := [=]
    for (j in 1:16) gui.IFsel.bn[j] := F

    gui.IFsel.bn[1]  := button(gui.f111222121111,  '1', value= 1,
                               font=fonts.Vb8, borderwidth=1, width=3, padx=0,
                               pady=1)
    gui.IFsel.bn[2]  := button(gui.f111222121111,  '2', value= 2,
                               font=fonts.Vb8, borderwidth=1, width=3, padx=0,
                               pady=1)
    gui.IFsel.bn[3]  := button(gui.f111222121111,  '3', value= 3,
                               font=fonts.Vb8, borderwidth=1, width=3, padx=0,
                               pady=1)
    gui.IFsel.bn[4]  := button(gui.f111222121111,  '4', value= 4,
                               font=fonts.Vb8, borderwidth=1, width=3, padx=0,
                               pady=1)
    gui.IFsel.bn[5]  := button(gui.f111222121111,  '5', value= 5,
                               font=fonts.Vb8, borderwidth=1, width=3, padx=0,
                               pady=1)
    gui.IFsel.bn[6]  := button(gui.f111222121111,  '6', value= 6,
                               font=fonts.Vb8, borderwidth=1, width=3, padx=0,
                               pady=1)
    gui.IFsel.bn[7]  := button(gui.f111222121111,  '7', value= 7,
                               font=fonts.Vb8, borderwidth=1, width=3, padx=0,
                               pady=1)
    gui.IFsel.bn[8]  := button(gui.f111222121111,  '8', value= 8,
                               font=fonts.Vb8, borderwidth=1, width=3, padx=0,
                               pady=1)
    gui.IFsel.bn[9]  := button(gui.f111222121112,  '9', value= 9,
                               font=fonts.Vb8, borderwidth=1, width=3, padx=0,
                               pady=1)
    gui.IFsel.bn[10] := button(gui.f111222121112, '10', value=10,
                               font=fonts.Vb8, borderwidth=1, width=3, padx=0,
                               pady=1)
    gui.IFsel.bn[11] := button(gui.f111222121112, '11', value=11,
                               font=fonts.Vb8, borderwidth=1, width=3, padx=0,
                               pady=1)
    gui.IFsel.bn[12] := button(gui.f111222121112, '12', value=12,
                               font=fonts.Vb8, borderwidth=1, width=3, padx=0,
                               pady=1)
    gui.IFsel.bn[13] := button(gui.f111222121112, '13', value=13,
                               font=fonts.Vb8, borderwidth=1, width=3, padx=0,
                               pady=1)
    gui.IFsel.bn[14] := button(gui.f111222121112, '14', value=14,
                               font=fonts.Vb8, borderwidth=1, width=3, padx=0,
                               pady=1)
    gui.IFsel.bn[15] := button(gui.f111222121112, '15', value=15,
                               font=fonts.Vb8, borderwidth=1, width=3, padx=0,
                               pady=1)
    gui.IFsel.bn[16] := button(gui.f111222121112, '16', value=16,
                               font=fonts.Vb8, borderwidth=1, width=3, padx=0,
                               pady=1)

    for (i in 1:16) {
      sethelp(gui.IFsel.bn[i],
              spaste('Select or deselect input for IF ', i, '.'))
    }

    whenever
      gui.IFsel.bn[1]->press,
      gui.IFsel.bn[2]->press,
      gui.IFsel.bn[3]->press,
      gui.IFsel.bn[4]->press,
      gui.IFsel.bn[5]->press,
      gui.IFsel.bn[6]->press,
      gui.IFsel.bn[7]->press,
      gui.IFsel.bn[8]->press,
      gui.IFsel.bn[9]->press,
      gui.IFsel.bn[10]->press,
      gui.IFsel.bn[11]->press,
      gui.IFsel.bn[12]->press,
      gui.IFsel.bn[13]->press,
      gui.IFsel.bn[14]->press,
      gui.IFsel.bn[15]->press,
      gui.IFsel.bn[16]->press do {
        p := parms.IFsel
        p[$value] := !p[$value]
        setparm([IFsel = p])
      }

    gui.IFsel.la := label(gui.f1112221211, 'IFs', padx=2, fill='both')
    sethelp(gui.IFsel.la, 'IF selection panel; all IFs must have the same \
      original (i.e. non-Doppler-shifted) channel spacing.')

    # Polarization mode ------------------------------------------------------
    gui.f111222122 := frame(gui.f11122212, borderwidth=0)
    sethelp(gui.f111222122, 'Polarization processing options.')

    gui.pol_op.la := label(gui.f111222122, 'Polarization')
    gui.pol_op.bn := button(gui.f111222122, type='menu', relief='groove',
                            width=7, pady=2)

    showmenu('pol_op', ['A&B: Aggregate polarizations',
                        'A: Polarization A only',
                        'B: Polarization B only',
                        '(A+B)/2: Add polarizations',
                        '(A-B)/2: Subtract polarizations'], add=F)

    # Line, continuum, and/or baseline processing? ---------------------------
    gui.f1112222 := frame(gui.f111222, borderwidth=0)
    gui.spectral.bn := button(gui.f1112222, 'Spectral   ', type='check',
                              width=10)
    sethelp(gui.spectral.bn, 'Produce spectral line cube?')

    whenever
      gui.spectral.bn->press do
        setparm([spectral = gui.spectral.bn->state()])


    gui.continuum.bn := button(gui.f1112222, 'Continuum', type='check',
                               width=10)
    sethelp(gui.continuum.bn, 'Produce continuum and spectral index maps?')

    whenever
      gui.continuum.bn->press do
        setparm([continuum = gui.continuum.bn->state()])


    gui.baseline.bn := button(gui.f1112222, 'Baseline   ', type='check',
                              width=10)
    sethelp(gui.baseline.bn, 'Produce baseline polynomial coefficient cube?')

    whenever
      gui.baseline.bn->press do
        setparm([baseline = gui.baseline.bn->state()])

    #=========================================================================
    # Input file specification.
    gui.f1113  := frame(gui.f111, relief='ridge')
    gui.f11131 := frame(gui.f1113, borderwidth=0, expand='x')

    # Directory search path and input file list ------------------------------
    gui.f111311 := frame(gui.f11131, side='left', borderwidth=0, expand='x')
    sethelp(gui.f111311, 'Colon-separated search path for input files \
      (set via GRIDZILLA_READ_DIR).')

    gui.directories.la := label(gui.f111311, '     Search path', width=13)
    gui.directories.en := entry(gui.f111311, font='courier-bold', width=1,
                                fill='x')

    whenever
      gui.directories.en->return do
        file_search()

    # File wildcard(s) -------------------------------------------------------
    gui.f111312   := frame(gui.f11131, side='left', borderwidth=0)
    gui.f1113121  := frame(gui.f111312, borderwidth=0, expand='x')
    gui.f11131211 := frame(gui.f1113121, side='left', borderwidth=0,
                           expand='x')
    sethelp(gui.f11131211, 'Wildcard specification(s) for input files.')

    gui.f11131211->unmap()
    gui.filemask.la := label(gui.f11131211, 'File wildcard(s)', width=13)
    gui.filemask.en := entry(gui.f11131211, font='courier-bold', width=1,
                             fill='x')

    # Filename extension -----------------------------------------------------
    gui.f11131212 := frame(gui.f1113121, side='left', borderwidth=0,
                           expand='x')
    gui.filext.la := label(gui.f11131212, '     File suffixes', width=13)
    gui.filext.en := entry(gui.f11131212, font='courier-bold', width=1,
                           fill='x')
    sethelp(gui.f11131212, 'File suffixes of input datasets.')

    whenever
      gui.filemask.en->return,
      gui.filext.en->return do
        file_search()

    # Search button ----------------------------------------------------------
    if (!parms.remote) {
      gui.f1113122 := frame(gui.f111312, side='right', borderwidth=0,
                            expand='none')
      gui.search.bn := button(gui.f1113122, 'Search')
      sethelp(gui.search.bn, 'Update the search for input files.')

      whenever
        gui.search.bn->press do
          file_search()
    }

    # List of input files ----------------------------------------------------
    gui.f11132 := frame(gui.f1113, side='left', borderwidth=0, expand='both')
    gui.f11133 := frame(gui.f1113, side='left', borderwidth=0, expand='x')
    gui.files.lb := listbox(gui.f11132, mode='extended', font='courier-bold',
                            width=76, height=12, fill='both')
    sethelp(gui.files.lb, 'Files required (HIPASS, ZOA & HVC) and found; \
                           select for processing.')

    whenever
      gui.files.lb->yscroll do
        gui.files.vsb->view($value)

    whenever
      gui.files.lb->xscroll do
        gui.files.hsb->view($value)

    gui.files.vsb := scrollbar(gui.f11132, width=8)
    gui.files.hsb := scrollbar(gui.f11133, orient='horizontal', width=8)

    whenever
      gui.files.vsb->scroll,
      gui.files.hsb->scroll do
        gui.files.lb->view($value)

    gui.files.bx := button(gui.f11133, bitmap='blank6x6.xbm')
    sethelp(gui.files.bx, 'Press to scroll to bottom.')

    whenever
      gui.files.bx->press do
        gui.files.lb->see('end')

    #=========================================================================
    gui.f112  := frame(gui.f11, borderwidth=0, expand='y')
    gui.f1121 := frame(gui.f112, side='left', borderwidth=4, expand='x')

    gui.gridzilla.la := label(gui.f1121, 'GRIDZILLA', foreground='#0000a0')
    sethelp(gui.gridzilla.la, spaste('Control panel (v', wrk.version,
            ') for the multibeam gridder client.'))


    # Spacer.
    gui.f11211 := frame(gui.f1121, width=0, height=0, borderwidth=0,
                        expand='x')

    # Configuration ----------------------------------------------------------
    gui.config.la := label(gui.f1121, 'Parameter set')
    gui.config.bn := button(gui.f1121, type='menu', relief='groove', width=10)
    sethelp(gui.f1121, 'Predefined processing modes (set via \
      GRIDZILLA_MODE).')

    gui.config_0.bn := button(gui.config.bn, 'Factory defaults',
                                                          value='DEFAULTS')
    gui.config_1.bn := button(gui.config.bn, 'GENERAL',   value='GENERAL')
    gui.config_2.bn := button(gui.config.bn, 'CONTINUUM', value='CONTINUUM')
    gui.config_3.bn := button(gui.config.bn, 'HIPASS',    value='HIPASS',
                              disabled=(len(wrk.HIPASS_fields) == 0))
    gui.config_4.bn := button(gui.config.bn, 'HVC',       value='HVC',
                              disabled=(len(wrk.HVC_fields) == 0))
    gui.config_5.bn := button(gui.config.bn, 'METHANOL',  value='METHANOL')
    gui.config_6.bn := button(gui.config.bn, 'ZOA',       value='ZOA')
    gui.config_7.bn := button(gui.config.bn, 'MOPRA',     value='MOPRA')
    gui.config_8.bn := button(gui.config.bn, 'AUDS',      value='AUDS')

    whenever
      gui.config_0.bn->press,
      gui.config_1.bn->press,
      gui.config_2.bn->press,
      gui.config_3.bn->press,
      gui.config_4.bn->press,
      gui.config_5.bn->press,
      gui.config_6.bn->press,
      gui.config_7.bn->press,
      gui.config_8.bn->press do
        setparm([config = $value])

    #=========================================================================
    gui.f1122  := frame(gui.f112, relief='ridge', borderwidth=4, expand='x')
    gui.f11221 := frame(gui.f1122, side='left')
    gui.datasel.la := label(gui.f11221, 'PROCESSING OPTIONS',
                            foreground='#0000a0')
    sethelp(gui.datasel.la, 'Panel for setting gridding parameters')

    #=========================================================================
    # Output image geometry.
    gui.f11222  := frame(gui.f1122, relief='ridge', expand='x')
    gui.f112221 := frame(gui.f11222, side='left', borderwidth=0)
    gui.imagespec.la := label(gui.f112221, 'Output image geometry',
                              foreground='#0000a0')
    sethelp(gui.imagespec.la, 'Panel containing parameters for setting the \
      output image projection and obliquity.')

    gui.f112222 := frame(gui.f11222, side='left', borderwidth=0, expand='x')

    # Projection type --------------------------------------------------------
    gui.f1122221 := frame(gui.f112222, side='left', relief='ridge',
                          borderwidth=1, pady=2, expand='y')

    gui.f11222211  := frame(gui.f1122221, borderwidth=0, expand='y')
    gui.f112222111 := frame(gui.f11222211, side='left', borderwidth=0,
                            expand='x')
    gui.projection.la := label(gui.f112222111, 'Projection')
    gui.projection.bn := button(gui.f112222111, type='menu', relief='groove',
                                width=4)
    sethelp(gui.f112222111, 'Output map projection.')

    for (ptype in field_names(projections)) {
      gui[ptype].bn := button(gui.projection.bn, ptype, type='menu')

      for (pcode in field_names(projections[ptype])) {
        t := spaste(ptype, '_', pcode)
        gui[t].bn := button(gui[ptype].bn, spaste(pcode, ': ',
                            projections[ptype][pcode].name), value=pcode)

        whenever
          gui[t].bn->press do
            setparm([projection = $value])
      }
    }

    # ZPN is not handled by the GUI because of the number of parameters.
    gui.Zenithal_ZPN.bn->disabled(T)

    # Projection parameters --------------------------------------------------
    gui.f11222212  := frame(gui.f1122221, borderwidth=0, expand='y')
    gui.f112222120 := frame(gui.f11222212, borderwidth=0, width=95, height=0,
                            expand='none')
    gui.pv.fr := [=]
    gui.pv.en := [=]

    gui.pv.fr[1] := frame(gui.f11222212, side='left', width=0, height=0,
                          borderwidth=0, expand='none')
    gui.pv0.la := label(gui.pv.fr[1], '  P0:', padx=0)
    gui.pv.en[1] := entry(gui.pv.fr[1], width=8)
    sethelp(gui.pv.fr[1], 'Zeroth projection parameter, PVi_0')
    gui.pv.fr[1]->unmap()

    gui.pv.fr[2] := frame(gui.f11222212, side='left', width=0, height=0,
                          borderwidth=0, expand='none')
    gui.pv1.la := label(gui.pv.fr[2], '  P1:', padx=0)
    gui.pv.en[2] := entry(gui.pv.fr[2], width=8)
    sethelp(gui.pv.fr[2], 'First projection parameter, PVi_1')

    gui.pv.fr[3] := frame(gui.f11222212, side='left', width=0, height=0,
                          borderwidth=0, expand='none')
    gui.pv2.la := label(gui.pv.fr[3], '  P2:', padx=0)
    gui.pv.en[3] := entry(gui.pv.fr[3], width=8)
    sethelp(gui.pv.fr[3], 'Second projection parameter, PVi_2')

    gui.pv.fr[4] := frame(gui.f11222212, side='left', width=0, height=0,
                          borderwidth=0, expand='none')
    gui.pv3.la := label(gui.pv.fr[4], '  P3:', padx=0)
    gui.pv.en[4] := entry(gui.pv.fr[4], width=8)
    sethelp(gui.pv.fr[4], 'Third projection parameter, PVi_3')

    whenever
      gui.pv.en[1]->return,
      gui.pv.en[2]->return,
      gui.pv.en[3]->return,
      gui.pv.en[4]->return do
        setparm([pv = [gui.pv.en[1]->get(),
                       gui.pv.en[2]->get(),
                       gui.pv.en[3]->get(),
                       gui.pv.en[4]->get()]])

    # Reference point --------------------------------------------------------
    gui.f1122222 := frame(gui.f112222, relief='ridge', borderwidth=1,
                          expand='x')
    gui.f11222221 := frame(gui.f1122222, side='left', borderwidth=0)
    gui.refpoint.bn := button(gui.f11222221, 'Reference point', type='check')
    sethelp(gui.refpoint.bn, 'Set reference point?  Else it is tied to the \
      map centre.')

    whenever
      gui.refpoint.bn->press do
        setparm([refpoint = gui.refpoint.bn->state()])

    # Equatorial or galactic? ------------------------------------------------
    gui.f112222211 := frame(gui.f11222221, side='right', borderwidth=0)
    gui.coordSys.bn := button(gui.f112222211, '', type='menu',
                              relief='groove', padx=5, width=11)
    sethelp(gui.coordSys.bn, 'Select J2000.0 equatorial, galactic, or feed \
      plane coordinates.')
    showmenu('coordSys')

    # Reference longitude ----------------------------------------------------
    gui.f11222222   := frame(gui.f1122222, side='left', borderwidth=0)
    gui.f112222221  := frame(gui.f11222222, borderwidth=0)
    gui.f1122222211 := frame(gui.f112222221, borderwidth=0)

    gui.f11222222111 := frame(gui.f1122222211, side='left', borderwidth=0)
    gui.reference_lng.la := label(gui.f11222222111, '    LNG', width=4)
    gui.reference_lng.en := entry(gui.f11222222111, width=12)
    sethelp(gui.f11222222111, 'Celestial longitude of the reference point; \
      decimal and sexagesimal notation (e.g. 19:34:47.9) is understood.')

    whenever
      gui.reference_lng.en->return do
        setparm([reference_lng = $value])

    # Reference latitude  ----------------------------------------------------
    gui.f11222222112 := frame(gui.f1122222211, side='left', borderwidth=0)
    gui.reference_lat.la := label(gui.f11222222112, '    LAT', width=4)
    gui.reference_lat.en := entry(gui.f11222222112, width=12)
    sethelp(gui.f11222222112, 'Celestial latitude of the reference point; \
      decimal and sexagesimal notation (e.g. -63:49:36.0) is understood.')

    whenever
      gui.reference_lat.en->return do
        setparm([reference_lat = $value])

    # LONPOLE ----------------------------------------------------------------
    gui.f112222222 := frame(gui.f11222222, borderwidth=0)

    gui.f1122222221 := frame(gui.f112222222, side='left', borderwidth=0)
    gui.lonpole.la := label(gui.f1122222221, '   LONPOLE', padx=3, width=10)
    gui.lonpole.en := entry(gui.f1122222221, width=12)
    sethelp(gui.f1122222221, 'Native longitude of the celestial pole \
      (normally 999.0); decimal and sexagesimal notation (e.g. 150:03:23.1) \
      is understood.')

    whenever
      gui.lonpole.en->return do
        setparm([lonpole = $value])

    # LATPOLE ----------------------------------------------------------------
    gui.f1122222222 := frame(gui.f112222222, side='left', borderwidth=0)
    gui.latpole.la := label(gui.f1122222222, '   LATPOLE', padx=3, width=10)
    gui.latpole.en := entry(gui.f1122222222, width=12)
    sethelp(gui.f1122222222, 'Native latitude of the celestial pole (normally \
      999.0); decimal and sexagesimal notation (e.g. -22:34:21.1) is \
      understood.')

    whenever
      gui.latpole.en->return do
        setparm([latpole = $value])

    #=========================================================================
    # Image centre and extent.
    gui.f11223   := frame(gui.f1122, relief='ridge', expand='x')
    gui.f112231  := frame(gui.f11223, side='left', borderwidth=0, expand='x')
    gui.extent.la := label(gui.f112231, 'Image centre and extent',
                           foreground='#0000a0')
    sethelp(gui.extent.la, 'Panel containing parameters for setting the \
      output image size.')

    # Autosize? --------------------------------------------------------------
    gui.f1122311 := frame(gui.f112231, side='right', borderwidth=0,
                          expand='x')
    gui.autosize.bn := button(gui.f1122311, 'Autosize', type='check')
    sethelp(gui.autosize.bn, 'Automatically set the map size to encompass \
                              the input data?')

    whenever
      gui.autosize.bn->press do
        setparm([autosize = gui.autosize.bn->state()])

    # General field specification --------------------------------------------
    gui.f112232  := frame(gui.f11223, side='left', relief='ridge',
                          borderwidth=1, expand='x')
    gui.f1122320 := frame(gui.f112232, width=0, height=52, expand='none')
    gui.f1122321 := frame(gui.f112232, expand='none')
    gui.f11223210 := frame(gui.f1122321, width=125, height=0, borderwidth=0,
                           expand='none')

    gui.f11223211 := frame(gui.f1122321, borderwidth=0)
    gui.f11223211->unmap()

    # Central longitude ------------------------------------------------------
    gui.f112232111 := frame(gui.f11223211, side='left', borderwidth=0)
    gui.centre_lng.la := label(gui.f112232111, 'LNG', padx=3, width=3)
    gui.centre_lng.en := entry(gui.f112232111, width=12)
    sethelp(gui.f112232111, 'Celestial longitude of the map centre; decimal \
      and sexagesimal notation (e.g. 19:34:47.9) is understood.')

    whenever
      gui.centre_lng.en->return do
        setparm([centre_lng = $value])

    # Central latitude -------------------------------------------------------
    gui.f112232112 := frame(gui.f11223211, side='left', borderwidth=0)
    gui.centre_lat.la := label(gui.f112232112, 'LAT', padx=3, width=3)
    gui.centre_lat.en := entry(gui.f112232112, width=12)
    sethelp(gui.f112232112, 'Celestial latitude of the map centre; decimal \
      and sexagesimal notation (e.g. -63:49:36.0) is understood.')

    whenever
      gui.centre_lat.en->return do
        setparm([centre_lat = $value])

    # Menu of HIPASS fields --------------------------------------------------
    gui.f11223212 := frame(gui.f1122321, borderwidth=0)
    gui.f11223212->unmap()

    gui.HIPASS_field.la := label(gui.f11223212, 'HIPASS field')
    gui.HIPASS_field.bn := button(gui.f11223212, '', type='menu',
                                  relief='groove', width=15)
    sethelp(gui.f11223212, 'Standard HIPASS field selection.')

    for (dec in field_names(wrk.HIPASS_cubes)) {
      gui.HIPASS_field[dec].bn := [=]
      gui.HIPASS_field[dec].bn[1] := button(gui.HIPASS_field.bn, dec,
                                            type='menu')

      nmenu := ceil(len(wrk.HIPASS_cubes[dec])/15)
      if (nmenu > 1) {
        for (i in 2:nmenu) {
          gui.HIPASS_field[dec].bn[i] := button(gui.HIPASS_field[dec].bn[i-1],
                                                'more', type='menu',
                                                foreground='#b03060')
        }
      }

      count := 0
      for (ra in field_names(wrk.HIPASS_cubes[dec])) {
        count +:= 1
        i := ceil(count/15)

        gui.HIPASS_field[dec][ra].bn := button(gui.HIPASS_field[dec].bn[i],
                                               sprintf('%s (H%.3d)', ra,
                                                 wrk.HIPASS_cubes[dec][ra]),
                                               value=spaste(ra,dec))

        whenever
          gui.HIPASS_field[dec][ra].bn->press do
            setparm([HIPASS_field = $value])
      }
    }


    # Menu of HVC fields -----------------------------------------------------
    gui.f11223213 := frame(gui.f1122321, borderwidth=0)
    gui.f11223213->unmap()

    gui.HVC_field.la := label(gui.f11223213, 'HVC field')
    gui.HVC_field.bn := button(gui.f11223213, '0000-90', type='menu',
                               relief='groove', width=15)
    sethelp(gui.f11223213, 'Standard HVC field selection.')

    for (dec in field_names(wrk.HVC_cubes)) {
      gui.HVC_field[dec].bn := button(gui.HVC_field.bn, dec, type='menu')

      for (ra in field_names(wrk.HVC_cubes[dec])) {
        gui.HVC_field[dec][ra].bn := button(gui.HVC_field[dec].bn,
                                            sprintf('%s (C%.2d)', ra,
                                              wrk.HVC_cubes[dec][ra]),
                                            value=spaste(ra,dec))

        whenever
          gui.HVC_field[dec][ra].bn->press do
            setparm([HVC_field = $value])
      }
    }


    # Menu of ZOA fields -----------------------------------------------------
    gui.f11223214 := frame(gui.f1122321, borderwidth=0)

    gui.ZOA_field.la :=  label(gui.f11223214, 'Galactic longitude')
    gui.ZOA_field.bn := button(gui.f11223214, '216', type='menu',
                               relief='groove', width=15)
    sethelp(gui.f11223214, 'Standard ZOA field selection.')

    for (lng in wrk.ZOA_fields) {
      gui.ZOA_field[lng].bn := button(gui.ZOA_field.bn,
                                      spaste(lng,sprintf('%c', 176)),
                                      value=lng)

      whenever
        gui.ZOA_field[lng].bn->press do
          setparm([ZOA_field = $value])
    }

    # Image and pixel width and height ---------------------------------------
    gui.f1122322 := frame(gui.f112232, borderwidth=0, expand='none')

    gui.f11223221 := frame(gui.f1122322, side='left', borderwidth=0)
    gui.width.la := label(gui.f11223221, ' x-scale:', padx=0, width=8)
    gui.pixel_width.en := entry(gui.f11223221, width=4, justify='right')
    gui.width_unit2.la := label(gui.f11223221, 'arcmin / pixel',
                                width=11)
    sethelp(gui.f11223221, 'Pixel separation in the x-direction at \
      the reference point (CDELT1).')

    gui.f112232211 := frame(gui.f11223221, side='left', borderwidth=0)
    gui.width_unit3.la := label(gui.f112232211, 'x', padx=0, width=1)

    gui.image_width.en := entry(gui.f112232211, width=5, justify='right')
    sethelp(gui.f112232211, 'Map extent in the x-direction.')

    gui.width_unit1.la := label(gui.f112232211, 'pixels =', width=6)
    gui.total_width.la := label(gui.f112232211, width=5)
    gui.width_unit4.la := label(gui.f112232211, '"arcmin"', padx=0, width=7)

    whenever
      gui.image_width.en->return do
        setparm([image_width = gui.image_width.en->get()])

    whenever
      gui.pixel_width.en->return do
        setparm([pixel_width = gui.pixel_width.en->get()])

    whenever
      gui.image_width.en->activity,
      gui.pixel_width.en->activity do
        gui.total_width.la->text('')

    gui.f11223222 := frame(gui.f1122322, side='left', borderwidth=0)
    gui.height.la := label(gui.f11223222, ' y-scale:', padx=0, width=8)
    gui.pixel_height.en := entry(gui.f11223222, width=4, justify='right')
    gui.height_unit2.la := label(gui.f11223222, 'arcmin / pixel',
                                 width=11)
    sethelp(gui.f11223222, 'Pixel separation in the y-direction at the \
      reference point (CDELT2).')

    gui.f112232221 := frame(gui.f11223222, side='left', borderwidth=0)
    gui.height_unit3.la := label(gui.f112232221, 'x', padx=0, width=1)

    gui.image_height.en := entry(gui.f112232221, width=5, justify='right')
    sethelp(gui.f112232221, 'Map extent in the y-direction.')

    gui.height_unit1.la := label(gui.f112232221, 'pixels =', width=6)
    gui.total_height.la := label(gui.f112232221, width=5)
    gui.height_unit4.la := label(gui.f112232221, '"arcmin"', padx=0, width=7)

    whenever
      gui.image_height.en->return do
        setparm([image_height = gui.image_height.en->get()])

    whenever
      gui.pixel_height.en->return do
        setparm([pixel_height = gui.pixel_height.en->get()])

    whenever
      gui.image_height.en->activity,
      gui.pixel_height.en->activity do
        gui.total_height.la->text('')

    #=========================================================================
    # Data validation
    gui.f11224  := frame(gui.f1122, relief='ridge', expand='x')
    gui.f112241 := frame(gui.f11224, side='left')
    gui.gridding.la := label(gui.f112241, 'Data validation',
                             foreground='#0000a0')
    sethelp(gui.gridding.la, 'Panel containing data validation parameters.')

    gui.f112242  := frame(gui.f11224, side='left', borderwidth=0)
    gui.f1122421 := frame(gui.f112242, relief='ridge', side='left',
                          borderwidth=1, pady=2)

    # Tsys checking ----------------------------------------------------------
    gui.f11224211  := frame(gui.f1122421, borderwidth=0, expand='x')
    gui.f112242111 := frame(gui.f11224211, side='left', borderwidth=0,
                            expand='x')
    gui.tsysmin.la := label(gui.f112242111, 'Tsys range', anchor='e',
                            width=10)
    sethelp(gui.tsysmin.la, 'Data selection based on the value of Tsys.')
    gui.tsysmin.en := entry(gui.f112242111, width=5, justify='right')
    sethelp(gui.tsysmin.en, 'Reject spectra with Tsys less than or equal \
      to this value.')

    whenever
      gui.tsysmin.en->return do
        setparm([tsysmin = $value])

    gui.tsysmax.la := label(gui.f112242111, '-')
    gui.tsysmax.en := entry(gui.f112242111, width=5, justify='right')
    sethelp(gui.tsysmax.en, 'Reject spectra with Tsys greater than or \
      equal to this value.')

    whenever
      gui.tsysmax.en->return do
        setparm([tsysmax = $value])

    # Data checking ----------------------------------------------------------
    gui.f112242112 := frame(gui.f11224211, side='left', borderwidth=0,
                            expand='x')
    gui.datamin.la := label(gui.f112242112, 'Data range', anchor='e',
                            width=10)
    sethelp(gui.datamin.la, 'Data selection based on the data value.')
    gui.datamin.en := entry(gui.f112242112, width=5, justify='right')
    sethelp(gui.datamin.en, 'Reject individual channels that are less than \
      or equal to this value.')

    whenever
      gui.datamin.en->return do
        setparm([datamin = $value])

    gui.datamax.la := label(gui.f112242112, '-')
    gui.datamax.en := entry(gui.f112242112, width=5, justify='right')
    sethelp(gui.datamax.en, 'Reject individual channels that are greater \
      than or equal to this value.')

    whenever
      gui.datamax.en->return do
        setparm([datamax = $value])

    # Channel alignment ------------------------------------------------------
    gui.f11224212 := frame(gui.f1122421, side='left', borderwidth=0,
                           expand='x')
    gui.chan_err.la := label(gui.f11224212, 'Doppler registration',
                             anchor='e', width=20)
    gui.chan_err.en := entry(gui.f11224212, width=5, justify='right',
                             fill='none')
    gui.chan_err2.la := label(gui.f11224212, 'channel')
    sethelp(gui.f11224212, 'Reject input spectra that do not register on \
      the output frequency axis to within this tolerance at every channel.')

    whenever
      gui.chan_err.en->return do
        setparm([chan_err = $value])

    #=========================================================================
    # Gridding parameters.
    gui.f11225  := frame(gui.f1122, relief='ridge', expand='x')
    gui.f112251 := frame(gui.f11225, side='left')
    gui.gridding.la := label(gui.f112251, 'Gridding parameters',
                             foreground='#0000a0')
    sethelp(gui.gridding.la, 'Panel containing gridding control parameters.')

    gui.f112252  := frame(gui.f11225, side='left', borderwidth=0)
    gui.f1122521 := frame(gui.f112252, relief='ridge', borderwidth=1, pady=2)

    # Gridding statistic -----------------------------------------------------
    gui.f11225211 := frame(gui.f1122521, side='left', borderwidth=0)
    gui.statistic.la :=  label(gui.f11225211, 'Statistic', padx=3)
    gui.statistic.bn := button(gui.f11225211, type='menu', relief='groove',
                               pady=2, width=8)
    sethelp(gui.f11225211, 'Statistical estimator applied to data.')

    gui.statistics := [WGTMED   = 'weighted median',
                       MEDIAN   = 'median of weighted values',
                       MEAN     = 'weighted mean',
                       SUM      = 'weighted sum',
                       RSS      = 'weighted root sum of squares',
                       RMS      = 'weighted rms',
                       QUARTILE = 'weighted quartile range',
                       NSPECTRA = 'no. of spectra for each pixel',
                       WEIGHT   = 'sum of weights',
                       BEAMSUM  = 'sum of beam weights only',
                       BEAMRSS  = 'root sumsq of beam weights']

    i := 0
    for (s in field_names(gui.statistics)) {
      i +:= 1
      t := spaste('statistic_', i)
      gui[t].bn := button(gui.statistic.bn,
                          spaste(s, ': ', gui.statistics[s]),
                          type='check', value=s)

      whenever
        gui[t].bn->press do {
          if ($agent->state()) {
            setparm([statistic = [parms.statistic, $value]])
          } else {
            setparm([statistic = parms.statistic[parms.statistic != $value]])
          }
        }
    }

    # Clip fraction ----------------------------------------------------------
    gui.f11225212 := frame(gui.f1122521, side='left', borderwidth=0)
    gui.clip_fraction.la  := label(gui.f11225212, 'Clip fraction', width=10)
    gui.clip_fraction.en  := entry(gui.f11225212, width=2, justify='right')
    gui.clip_fraction.la2 := label(gui.f11225212, '%')
    sethelp(gui.f11225212, 'Fraction of extremum data to discard.')

    whenever
      gui.clip_fraction.en->return do
        setparm([clip_fraction = $value])

    # Tsys weighting? --------------------------------------------------------
    gui.tsys_weight.bn := button(gui.f1122521, 'Tsys weighting', type='check',
                                 fill='x')
    sethelp(gui.tsys_weight.bn, 'Weight data inversely by Tsys?')

    whenever
      gui.tsys_weight.bn->press do
        setparm([tsys_weight = gui.tsys_weight.bn->state()])

    # Beam weighting type ----------------------------------------------------
    gui.f1122522  := frame(gui.f112252, relief='ridge', borderwidth=1, pady=2)
    gui.f11225221 := frame(gui.f1122522, side='left', borderwidth=0)
    gui.beam_weight.la := label(gui.f11225221, 'Beam weighting')
    gui.beam_weight.bn := button(gui.f11225221, type='menu', relief='groove')
    sethelp(gui.f11225221, 'Statistical weighting by beam response.')
    showmenu('beam_weight', ['None', 'Proportional', 'Squared', 'Cubed'])

    # Beam FWHM --------------------------------------------------------------
    gui.f11225222 := frame(gui.f1122522, side='left', borderwidth=0)
    gui.beam_FWHM.la := label(gui.f11225222, 'Beam FWHM')
    gui.beam_FWHM.en := entry(gui.f11225222, width=4)
    gui.beam_FWHM.la2 := label(gui.f11225222, 'arcmin', padx=2)
    sethelp(gui.f11225222, 'Beam FWHM (for beam weighting and \
                            normalization).  N.B. Should always be set to \
                            the true beam FWHM.')

    whenever
      gui.beam_FWHM.en->return do
        setparm([beam_FWHM = $value])

    # Beam normalization -----------------------------------------------------
    gui.f11225223 := frame(gui.f1122522, borderwidth=0)
    gui.beam_normal.bn := button(gui.f11225223, 'Beam normalization',
                                 type='check', fill='x')
    sethelp(gui.beam_normal.bn, 'Scale measured flux densities by inverse of \
                                 beam response?')

    whenever
      gui.beam_normal.bn->press do
        setparm([beam_normal = gui.beam_normal.bn->state()])


    # Gridding kernel parameters ---------------------------------------------
    gui.f1122523  := frame(gui.f112252, relief='ridge', borderwidth=1, pady=2)
    gui.f11225231 := frame(gui.f1122523, side='left', borderwidth=0)
    gui.kernel_type.la := label(gui.f11225231, 'Smoothing kernel')
    gui.kernel_type.bn := button(gui.f11225231, type='menu', relief='groove',
                                 width=8)
    sethelp(gui.f11225231, 'Function used for statistical weighting (in \
                                 addition to beam weighting).')
    showmenu('kernel_type')

    # Kernel FWHM ------------------------------------------------------------
    gui.f11225232 := frame(gui.f1122523, side='right', borderwidth=0)
    gui.kernel_FWHM.la2 := label(gui.f11225232, 'arcmin')
    gui.kernel_FWHM.en  := entry(gui.f11225232, justify='right', width=4)
    gui.kernel_FWHM.la  := label(gui.f11225232, 'Kernel FWHM')
    sethelp(gui.f11225232, 'FWHM of smoothing kernel.')

    whenever
      gui.kernel_FWHM.en->return do
        setparm([kernel_FWHM = $value])

    # Cutoff radius ----------------------------------------------------------
    gui.f11225233 := frame(gui.f1122523, side='right', borderwidth=0)
    gui.cutoff_radius.la2 := label(gui.f11225233, 'arcmin')
    gui.cutoff_radius.en  := entry(gui.f11225233, width=4, justify='right')
    gui.cutoff_radius.la  := label(gui.f11225233, 'Cutoff radius')
    sethelp(gui.f11225233, 'Support radius of smoothing kernel.')

    whenever
      gui.cutoff_radius.en->return do
        setparm([cutoff_radius = $value])

    #=========================================================================
    # Blanking level
    gui.f11226  := frame(gui.f1122, side='left', borderwidth=0)
    gui.f112261 := frame(gui.f11226, side='left', relief='ridge', expand='y')

    gui.blank_level.la := label(gui.f112261, 'Blanking level ')
    gui.blank_level.en := entry(gui.f112261, width=4, justify='left')
    sethelp(gui.f112261, 'Pixels for which the root sum of squares of beam \
      weights (a measure of sensitivity) is less than this value will be \
      blanked.')

    whenever
      gui.blank_level.en->return do
        setparm([blank_level = $value])

    # Processor host ---------------------------------------------------------
    gui.f112262 := frame(gui.f11226, side='left', relief='ridge')

    gui.f1122621 := frame(gui.f112262, side='left', relief='ridge')
    gui.client_host.la := label(gui.f1122621, 'Processor host')
    gui.client_host.en := entry(gui.f1122621, width=8)
    sethelp(gui.f1122621, 'Host on which to run the gridder client to \
                           process the data.')

    whenever
      gui.client_host.en->return do
        setparm([client_host = $value])

    # Processor memory -------------------------------------------------------
    gui.f1122622 := frame(gui.f112262, side='left', relief='ridge')
    gui.storage.la := label(gui.f1122622, '   Use')
    gui.storage.en := entry(gui.f1122622, width=4, justify='right')
    sethelp(gui.f1122622, 'Processor memory to use (overuse of virtual \
                           memory will cause thrashing).')

    gui.memory.sv := label(gui.f112262, '% of available memory', anchor='w',
                           width=18, padx=1)
    sethelp(gui.memory.sv, '')

    whenever
      gui.storage.en->return do
        setparm([storage = $value])


    #=========================================================================
    # Output file specification.
    gui.f11227 := frame(gui.f1122, relief='ridge', expand='x')

    # FITS spectral axis type ------------------------------------------------
    gui.f112271 := frame(gui.f11227, side='left', borderwidth=0, expand='x')

    gui.f1122711 := frame(gui.f112271, side='left', borderwidth=0, expand='x')
    gui.spectype.la := label(gui.f1122711, 'FITS spectral type')
    gui.spectype.bn := button(gui.f1122711, type='menu', relief='groove',
                              width=12)
    sethelp(gui.f1122711, 'Spectral axis type required in the output FITS \
      cube; the input is assumed always to be linear in frequency.')

    gui.freqtype.bn   := button(gui.spectype.bn, 'Frequency types',
                                type='menu')
    gui.spectype_1.bn := button(gui.freqtype.bn,
                                'FREQ (frequency)', value='FREQ')
    gui.spectype_2.bn := button(gui.freqtype.bn,
                                'VRAD (radio velocity)', value='VRAD')
    gui.spectype_3.bn := button(gui.freqtype.bn,
                                'AFRQ (angular frequency)', value='AFRQ')
    gui.spectype_4.bn := button(gui.freqtype.bn,
                                'ENER (photon energy)', value='ENER')
    gui.spectype_5.bn := button(gui.freqtype.bn,
                                'WAVN (wavenumber)', value='WAVN')

    gui.wavetype.bn   := button(gui.spectype.bn, 'Wavelength types',
                                type='menu')
    gui.spectype_6.bn := button(gui.wavetype.bn,
                                'WAVE-F2W (wavelength)',
                                value='WAVE-F2W')
    gui.spectype_7.bn := button(gui.wavetype.bn,
                                'VOPT-F2W (optical velocity)',
                                value='VOPT-F2W')
    gui.spectype_8.bn := button(gui.wavetype.bn,
                                'ZOPT-F2W (redshift)',
                                value='ZOPT-F2W')

    gui.velotype.bn   := button(gui.spectype.bn, 'Velocity types',
                                type='menu')
    gui.spectype_9.bn := button(gui.velotype.bn,
                                'VELO-F2V (relativistic velocity)',
                                value='VELO-F2V')
    gui.spectype_a.bn := button(gui.velotype.bn,
                                'BETA-F2V (relativistic beta)',
                                value='BETA-F2V')

    gui.aipstype.bn   := button(gui.spectype.bn, 'AIPS convention types',
                                type='menu')
    gui.spectype_b.bn := button(gui.aipstype.bn,
                                'VELO-xxx (radio velocity)',
                                value='VELO-xxx')
    gui.spectype_c.bn := button(gui.aipstype.bn,
                                'FELO-xxx (optical velocity)',
                                value='FELO-xxx')

    whenever
      gui.spectype_1.bn->press,
      gui.spectype_2.bn->press,
      gui.spectype_3.bn->press,
      gui.spectype_4.bn->press,
      gui.spectype_5.bn->press,
      gui.spectype_6.bn->press,
      gui.spectype_7.bn->press,
      gui.spectype_8.bn->press,
      gui.spectype_9.bn->press,
      gui.spectype_a.bn->press,
      gui.spectype_b.bn->press,
      gui.spectype_c.bn->press do
        setparm([spectype = $value])

    # FITS data format -------------------------------------------------------
    gui.f1122712 := frame(gui.f112271, side='left', borderwidth=0, expand='x')
    gui.short_int.la := label(gui.f1122712, 'FITS numerical format',
                              anchor='e', fill='x')
    gui.short_int.bn := button(gui.f1122712, type='menu', relief='groove',
                               width=12)
    sethelp(gui.f1122712, 'Output FITS data format, short integer is more \
                           compact but less precise.')
    showmenu('short_int', ['16-bit integer', 'IEEE floating'], add=F)

    # Output directory -------------------------------------------------------
    gui.f112272 := frame(gui.f11227, side='left', borderwidth=0, expand='x')
    gui.write_dir.la := label(gui.f112272, 'Output FITS directory')
    gui.write_dir.en := entry(gui.f112272, font='courier-bold', justify='left',
                              fill='x')
    sethelp(gui.f112272, 'Output directory for the FITS file (set via \
                               GRIDZILLA_WRITE_DIR).')

    whenever
      gui.write_dir.en->return do
        setparm([write_dir = $value])

    # Output file name -------------------------------------------------------
    gui.f112273 := frame(gui.f11227, side='left', borderwidth=0, expand='x')
    gui.p_FITSfilename.la := label(gui.f112273, 'Output FITS file name')
    gui.p_FITSfilename.en := entry(gui.f112273, font='courier-bold',
                                   justify='right', fill='x')
    sethelp(gui.f112273, 'Output FITS file name, without extension; existing \
                          files will be overwritten.')

    gui.p_FITSfilename.la2 := label(gui.f112273, '.fits', font='courier-bold',
                                    padx=0)

    whenever
      gui.p_FITSfilename.en->return do
        setparm([p_FITSfilename = $value])

    #=========================================================================
    # Action buttons.
    gui.f1123 := frame(gui.f112, side='left', relief='ridge', borderwidth=4,
                     expand='x')

    gui.go.bn := F
    if (!parms.remote) {
      gui.go.bn := button(gui.f1123, 'GO', foreground='#009900')
      sethelp(gui.go.bn, 'Start gridding on the selected host; be sure to \
                          select some input files!')

      whenever
        gui.go.bn->press do
          go()
    }

    gui.abort.bn := button(gui.f1123, 'ABORT', foreground='#dd0000',
                           disabled=T)
    sethelp(gui.abort.bn, 'Abort gridding, possibly leaving an incomplete \
                           FITS file behind.')

    whenever
      gui.abort.bn->press do
        self->abort()

    gui.f11231 := frame(gui.f1123, side='left', borderwidth=0, expand='x')
    gui.status.la := label(gui.f11231, relief='flat', foreground='#b03060',
                           width=1, fill='x', borderwidth=0)
    sethelp(gui.status.la, 'Status messages.')

    if (!parms.remote) {
      gui.exit.bn := button(gui.f1123, 'EXIT', foreground='#dd0000')
      sethelp(gui.exit.bn, 'Shut down the GUI without aborting the gridder \
                            client.')

      whenever
        gui.exit.bn->press do
          self->terminate()
    }

    # Padding.
    gui.f1124 := frame(gui.f112, width=0, height=0, expand='both')

    #=========================================================================
    # Logger window.
    if (!remote) {
      gui.f12 := frame(gui.f1, relief='ridge', borderwidth=0, expand='both')
      wrk.logger->showgui(gui.f12)
    }

    #=========================================================================
    # Widget help messages.
    if (gui.dohelp) {
      if (!is_agent(gui.helpmsg)) {
        gui.f13 := frame(gui.f1, relief='ridge', expand='x')
        gui.helpmsg := label(gui.f13, '', font='courier', width=1, fill='x',
                             borderwidth=0)
        sethelp(gui.helpmsg, 'Widget help messages.')
      }
    }

    #=========================================================================
    # Initialize the GUI.
    gui.image_width.en->bind('<Key>', 'activity')
    gui.image_width.en->bind('<ButtonRelease-2>', 'activity')
    gui.image_width.en->bind('<Leave>', 'return')

    gui.pixel_width.en->bind('<Key>', 'activity')
    gui.pixel_width.en->bind('<ButtonRelease-2>', 'activity')
    gui.pixel_width.en->bind('<Leave>', 'return')

    gui.image_height.en->bind('<Key>', 'activity')
    gui.image_height.en->bind('<ButtonRelease-2>', 'activity')
    gui.image_height.en->bind('<Leave>', 'return')

    gui.pixel_height.en->bind('<Key>', 'activity')
    gui.pixel_height.en->bind('<ButtonRelease-2>', 'activity')
    gui.pixel_height.en->bind('<Leave>', 'return')


    # Lock parameter entry?  (Must precede showparm.)
    if (wrk.locked) gui.f1->disable()

    # Initialize widgets.
    showparm(gui, parms)

    tk_release()
  }

  #--------------------------------------------------------- gui.autosize.show

  # Reconfigure GUI for automatic map sizing.

  const gui.autosize.show := function()
  {
    tk_hold()

    gui.autosize.bn->state(parms.autosize)

    if (parms.autosize) {
      if (!any(parms.config == "HIPASS HVC ZOA")) {
        if (!parms.refpoint) gui.f1122222211->unmap()
        gui.f11223211->unmap()
      }
      gui.f112232211->unmap()
      gui.f112232221->unmap()

    } else {
      if (!any(parms.config == "HIPASS HVC ZOA")) {
        gui.f1122222211->map()
        gui.f11223211->map()
      }
      gui.f112232211->map()
      gui.f112232221->map()
    }

    tk_release()
  }

  #------------------------------------------------------------------ showmenu

  # Build a menu for a parameter from its valid values.

  const showmenu := function(parm, labels="", add=T)
  {
    wider gui

    if (field_names(pchek[parm])[1] == 'boolean') {
      valid := [T, F]
    } else {
      valid := ref(pchek[parm][1].valid)
    }

    dolbl := (len(labels) == len(valid))
    verbatim := dolbl & !add

    i := 0
    for (v in valid) {
      i +:= 1
      t := spaste(parm, '_', i)

      if (verbatim) {
        lbl := labels[i]
      } else {
        lbl := as_string(v)
        if (dolbl) {
          lbl := spaste(lbl, ': ', labels[i])
        }
      }

      gui[t].bn := button(gui[parm].bn, lbl, value=v)

      whenever
        gui[t].bn->press do {
          rec[parm] := $value
          setparm(rec)
        }
    }
  }

  #---------------------------------------------------------- gui.beamsel.show

  # Show the mask of beams selected.

  const gui.beamsel.show := function()
  {
    for (j in 1:13) {
      gui.beamsel.bn[j]->foreground('#000000')
      if (parms.beamsel[j]) {
        gui.beamsel.bn[j]->background('#00a0b3')
      } else {
        gui.beamsel.bn[j]->background('#d4d4d4')
      }
      gui.beamsel.bn[j]->relief('raised')
    }
  }

  #------------------------------------------------------- gui.centre_lng.show

  # Show the celestial longitude of the central point.

  const gui.centre_lng.show := function()
  {
    lng := parms.centre_lng

    if (parms.coordSys == 'EQUATORIAL') {
      # Format as a time value.
      lng /:= 15.0
      lng::format.type := 'time'
      lng::format.signed := F
      lng::format.precision +:= 1
    }

    gui.centre_lng.en->delete('start', 'end')
    gui.centre_lng.en->insert(sformat(lng))
  }

  #------------------------------------------------------ gui.client_host.show

  # Show the processor host and how much memory it has.

  const gui.client_host.show := function()
  {
    wider gui

    gui.client_host.en->delete('start', 'end')
    gui.client_host.en->insert(parms.client_host)

    if (has_field(wrk.hosts[parms.client_host]::, 'assumed')) {
      gui.memory.sv->text(spaste('% of ', wrk.memory, '(?) MByte'))
    } else {
      gui.memory.sv->text(spaste('% of ', wrk.memory, 'MByte'))
    }

    gui.memory.sv.helpmsg := 'Amount of real processor memory available.'
  }

  #----------------------------------------------------------- gui.config.show

  # Show the processing configuration, enforcing HIPASS, HVC or ZOA parameter
  # restrictions.

  const gui.config.show := function()
  {

    # Set watch cursor.
    gui.f1->cursor('watch')
    message('Reconfiguring...')

    gui.config.bn->text(parms.config)

    tk_hold()
    if (wrk.locked) gui.f1->enable()

    if (!any(parms.config == "HIPASS HVC ZOA")) {
      # Input data specification.
      for (j in 1:13) {
        gui.beamsel.bn[j]->relief('raised')
        gui.beamsel.bn[j]->disabled(F)
      }

      gui.rangeSpec.bn->relief('groove')
      gui.rangeSpec.bn->disabled(F)
      gui.startSpec.en->relief('sunken')
      gui.startSpec.en->disabled(F)
      gui.endSpec.en->relief('sunken')
      gui.endSpec.en->disabled(F)

      gui.restFreq.en->relief('sunken')
      gui.restFreq.en->disabled(F)

      gui.spectral_id.bn->relief('groove')
      gui.spectral_id.bn->disabled(F)

      gui.pol_op.bn->relief('groove')
      gui.pol_op.bn->disabled(F)

      gui.continuum.bn->disabled(parms.config == 'CONTINUUM')
      gui.spectral.bn->disabled(F)

      # Output image specification.
      gui.projection.bn->relief('groove')
      gui.projection.bn->disabled(F)
      gui.pv.en[2]->relief('sunken')
      gui.pv.en[2]->disabled(F)
      gui.pv.en[3]->relief('sunken')
      gui.pv.en[3]->disabled(F)
      gui.pv.en[4]->relief('sunken')
      gui.pv.en[4]->disabled(F)

      gui.coordSys.bn->disabled(F)
      gui.refpoint.bn->disabled(F)
      gui.reference_lng.en->relief('sunken')
      gui.reference_lng.en->disabled(F)
      gui.reference_lat.en->relief('sunken')
      gui.reference_lat.en->disabled(F)
      gui.lonpole.en->relief('sunken')
      gui.lonpole.en->disabled(F)
      gui.latpole.en->relief('sunken')
      gui.latpole.en->disabled(F)

      gui.autosize.bn->disabled(F)

      gui.f11223212->unmap()
      gui.f11223213->unmap()
      gui.f11223214->unmap()
      gui.f112232211->map()

      gui.autosize.show()

      gui.pixel_width.en->relief('sunken')
      gui.pixel_width.en->disabled(F)

      gui.pixel_height.en->relief('sunken')
      gui.pixel_height.en->disabled(F)

      gui.image_width.en->relief('sunken')
      gui.image_width.en->disabled(F)

      gui.image_height.en->relief('sunken')
      gui.image_height.en->disabled(F)

      # Gridding parameters.
      gui.statistic.bn->relief('groove')
      gui.statistic.bn->disabled(F)

      gui.clip_fraction.en->relief('sunken')
      gui.clip_fraction.en->disabled(F)

      gui.tsys_weight.bn->relief('raised')
      gui.tsys_weight.bn->disabled(F)

      gui.beam_weight.bn->relief('groove')
      gui.beam_weight.bn->disabled(F)

      gui.beam_FWHM.en->relief('sunken')
      gui.beam_FWHM.en->disabled(F)

      gui.beam_normal.bn->relief('raised')
      gui.beam_normal.bn->disabled(F)

      gui.kernel_type.bn->relief('groove')
      gui.kernel_type.bn->disabled(F)

      gui.kernel_FWHM.en->relief('sunken')
      gui.kernel_FWHM.en->disabled(F)

      gui.cutoff_radius.en->relief('sunken')
      gui.cutoff_radius.en->disabled(F)

      gui.blank_level.en->relief('sunken')
      gui.blank_level.en->disabled(F)

      gui.spectype.bn->relief('groove')
      gui.spectype.bn->disabled(F)

      gui.short_int.bn->relief('groove')
      gui.short_int.bn->disabled(F)

      gui.f11131212->unmap()
      gui.f11131211->map()

    } else {
      # Input data specification.
      for (j in 1:13) {
        gui.beamsel.bn[j]->relief('ridge')
        gui.beamsel.bn[j]->disabled(T)
      }

      gui.rangeSpec.bn->relief('ridge')
      gui.rangeSpec.bn->disabled(T)
      gui.startSpec.en->relief('ridge')
      gui.startSpec.en->disabled(T)
      gui.endSpec.en->relief('ridge')
      gui.endSpec.en->disabled(T)

      gui.restFreq.en->relief('ridge')
      gui.restFreq.en->disabled(T)

      gui.spectral_id.bn->relief('ridge')
      gui.spectral_id.bn->disabled(T)

      gui.pol_op.bn->relief('ridge')
      gui.pol_op.bn->disabled(T)

      gui.spectral.bn->disabled(T)
      gui.continuum.bn->disabled(F)

      # Output image specification.
      gui.projection.bn->relief('ridge')
      gui.projection.bn->disabled(T)
      gui.pv.en[2]->relief('ridge')
      gui.pv.en[2]->disabled(T)
      gui.pv.en[3]->relief('ridge')
      gui.pv.en[3]->disabled(T)
      gui.pv.en[4]->relief('ridge')
      gui.pv.en[4]->disabled(T)

      gui.refpoint.bn->disabled(T)
      gui.reference_lng.en->relief('ridge')
      gui.reference_lng.en->disabled(T)
      gui.reference_lat.en->relief('ridge')
      gui.reference_lat.en->disabled(T)
      gui.lonpole.en->relief('ridge')
      gui.lonpole.en->disabled(T)
      gui.latpole.en->relief('ridge')
      gui.latpole.en->disabled(T)

      if (parms.config == 'HIPASS') {
        gui.coordSys.bn->disabled(T)

        gui.f11223211->unmap()
        gui.f11223213->unmap()
        gui.f11223214->unmap()
        gui.f11223212->map()

        gui.image_width.en->relief('ridge')
        gui.image_width.en->disabled(T)

        gui.image_height.en->relief('ridge')
        gui.image_height.en->disabled(T)

        gui.f112232211->map()
        gui.f112232221->map()

      } else if (parms.config == 'HVC') {
        gui.coordSys.bn->disabled(T)

        gui.f11223211->unmap()
        gui.f11223212->unmap()
        gui.f11223214->unmap()
        gui.f11223213->map()

        gui.image_width.en->relief('ridge')
        gui.image_width.en->disabled(T)

        gui.image_height.en->relief('ridge')
        gui.image_height.en->disabled(T)

        gui.f112232211->map()
        gui.f112232221->map()

      } else if (parms.config == 'ZOA') {
        gui.coordSys.bn->disabled(F)

        gui.f11223211->unmap()
        gui.f11223212->unmap()
        gui.f11223213->unmap()
        gui.f11223214->map()

        gui.f112232211->unmap()
        gui.f112232221->unmap()
        gui.autosize.bn->disabled(F)
      }

      gui.pixel_width.en->relief('ridge')
      gui.pixel_width.en->disabled(T)

      gui.pixel_height.en->relief('ridge')
      gui.pixel_height.en->disabled(T)

      # Gridding parameters.
      gui.statistic.bn->relief('ridge')
      gui.statistic.bn->disabled(T)

      gui.clip_fraction.en->relief('ridge')
      gui.clip_fraction.en->disabled(T)

      gui.tsys_weight.bn->relief('ridge')
      gui.tsys_weight.bn->disabled(T)

      gui.beam_weight.bn->relief('ridge')
      gui.beam_weight.bn->disabled(T)

      gui.beam_FWHM.en->relief('ridge')
      gui.beam_FWHM.en->disabled(T)

      gui.beam_normal.bn->relief('ridge')
      gui.beam_normal.bn->disabled(T)

      gui.kernel_type.bn->relief('ridge')
      gui.kernel_type.bn->disabled(T)

      gui.kernel_FWHM.en->relief('ridge')
      gui.kernel_FWHM.en->disabled(T)

      gui.cutoff_radius.en->relief('ridge')
      gui.cutoff_radius.en->disabled(T)

      gui.blank_level.en->relief('ridge')
      gui.blank_level.en->disabled(T)

      gui.spectype.bn->relief('ridge')
      gui.spectype.bn->disabled(T)

      gui.short_int.bn->relief('ridge')
      gui.short_int.bn->disabled(T)

      gui.f11131211->unmap()
      gui.f11131212->map()
    }

    # Restore default cursor.
    message()
    gui.f1->cursor('')

    if (wrk.locked) gui.f1->enable()
    tk_release()
  }

  #--------------------------------------------------------- gui.coordSys.show

  # Show coordinate system.

  const gui.coordSys.show := function()
  {
    gui.coordSys.bn->text(parms.coordSys)

    if (parms.coordSys == 'EQUATORIAL') {
      gui.reference_lng.la->text('    RA')
      gui.reference_lat.la->text('   Dec')
      gui.centre_lng.la->text(' RA')
      gui.centre_lat.la->text('Dec')

    } else if (parms.coordSys == 'GALACTIC') {
      gui.reference_lng.la->text('      l')
      gui.reference_lat.la->text('      b')
      gui.centre_lng.la->text('   l')
      gui.centre_lat.la->text('   b')

    } else if (parms.coordSys == 'FEED-PLANE') {
      gui.reference_lng.la->text('    PA')
      gui.reference_lat.la->text('   Pol')
      gui.centre_lng.la->text(' PA')
      gui.centre_lat.la->text('Pol')
    }

    rec := [reference_lng = parms.reference_lng,
            centre_lng    = parms.centre_lng]
    showparm(gui, rec)
  }

  #----------------------------------------------------- gui.HIPASS_field.show

  # Show HIPASS field centre.

  const gui.HIPASS_field.show := function()
  {
    if (parms.config == 'HIPASS') {
      gui.HIPASS_field.bn->text(sprintf('%s (H%.3d)', parms.HIPASS_field,
                                wrk.HIPASS_cube))
    }
  }

  #-------------------------------------------------------- gui.HVC_field.show

  # Show HVC field centre.

  const gui.HVC_field.show := function()
  {
    if (parms.config == 'HVC') {
      gui.HVC_field.bn->text(sprintf('%s (C%.2d)', parms.HVC_field,
                             wrk.HVC_cube))
    }
  }

  #------------------------------------------------------------ gui.IFsel.show

  # Show the mask of IFs selected (subject to their presence in the data).

  const gui.IFsel.show := function()
  {
    for (j in 1:16) {
      gui.IFsel.bn[j]->foreground('#000000')
      if (parms.IFsel[j]) {
        gui.IFsel.bn[j]->background('#00a0b3')
      } else {
        gui.IFsel.bn[j]->background('#d4d4d4')
      }
      gui.IFsel.bn[j]->relief('raised')
    }
  }

  #----------------------------------------------------- gui.image_height.show

  # Show the image height.

  const gui.image_height.show := function()
  {
    gui.image_height.en->delete('start', 'end')
    gui.image_height.en->insert(as_string(parms.image_height))

    t := sprintf('%.1f', parms.image_height*parms.pixel_height)
    gui.total_height.la->text(t)
  }

  #------------------------------------------------------ gui.image_width.show

  # Show the image width.

  const gui.image_width.show := function()
  {
    gui.image_width.en->delete('start', 'end')
    gui.image_width.en->insert(as_string(parms.image_width))

    t := sprintf('%.1f', parms.image_width*parms.pixel_width)
    gui.total_width.la->text(t)
  }

  #----------------------------------------------------- gui.pixel_height.show

  # Show the pixel height.

  const gui.pixel_height.show := function()
  {
    gui.pixel_height.en->delete('start', 'end')
    gui.pixel_height.en->insert(as_string(parms.pixel_height))

    t := sprintf('%.1f', parms.image_height*parms.pixel_height)
    gui.total_height.la->text(t)
  }

  #------------------------------------------------------ gui.pixel_width.show

  # Show the pixel width.

  const gui.pixel_width.show := function()
  {
    gui.pixel_width.en->delete('start', 'end')
    gui.pixel_width.en->insert(as_string(parms.pixel_width))

    t := sprintf('%.1f', parms.image_width*parms.pixel_width)
    gui.total_width.la->text(t)
  }

  #------------------------------------------------------- gui.projection.show

  # Show the projection type.

  const gui.projection.show := function()
  {
    gui.projection.bn->text(parms.projection)

    pmin := as_integer(pcodes[parms.projection]/100)
    pmax := pmin + pcodes[parms.projection]%100 - 1
    for (m in 1:3) {
      if (m < pmin || pmax < m) {
        gui.pv.fr[m+1]->unmap()
      } else {
        gui.pv.fr[m+1]->map()
      }
    }
  }

  #-------------------------------------------------------- gui.rangeSpec.show

  # Show the spectral range specification.

  const gui.rangeSpec.show := function()
  {
    if (parms.rangeSpec == 'FREQUENCY') {
      gui.rangeSpec.bn->text('Frequency range')
      gui.rangeSpec.la->text('MHz')
    } else if (parms.rangeSpec == 'VELOCITY') {
      gui.rangeSpec.bn->text('Velocity range')
      gui.rangeSpec.la->text('km/s')
    }
  }

  #---------------------------------------------------- gui.reference_lng.show

  # Show the celestial longitude of the reference point.

  const gui.reference_lng.show := function()
  {
    lng := parms.reference_lng

    if (parms.coordSys == 'EQUATORIAL') {
      # Format as a time value.
      lng /:= 15.0
      lng::format.type := 'time'
      lng::format.signed := F
      lng::format.precision +:= 1
    }

    gui.reference_lng.en->delete('start', 'end')
    gui.reference_lng.en->insert(sformat(lng))
  }

  #--------------------------------------------------------- gui.refpoint.show

  # Set reference point?  Else it is tied to the map centre.

  const gui.refpoint.show := function()
  {
    gui.refpoint.bn->state(parms.refpoint)

    if (parms.refpoint) {
      gui.f1122222211->map()
      gui.reference_lng.en->disabled(F)
      gui.reference_lng.en->relief('sunken')
      gui.reference_lat.en->disabled(F)
      gui.reference_lat.en->relief('sunken')
    } else {
      gui.reference_lng.en->disabled(T)
      gui.reference_lng.en->relief('ridge')
      gui.reference_lat.en->disabled(T)
      gui.reference_lat.en->relief('ridge')

      if (parms.autosize && !any(parms.config == "HIPASS HVC ZOA")) {
        gui.f1122222211->unmap()
      }
    }
  }

  #-------------------------------------------------------- gui.selection.show

  # Show files selected in the listbox.

  const gui.selection.show := function()
  {
    # Selection indices converted to 0-relative.
    for (i in parms.selection-1) {
      gui.files.lb->select(as_string(i))
    }
  }

  #-------------------------------------------------------- gui.short_int.show

  # Show output FITS data format.

  const gui.short_int.show := function()
  {
    if (parms.short_int) {
      gui.short_int.bn->text('16-bit integer')
    } else {
      gui.short_int.bn->text('IEEE floating')
    }
  }

  #-------------------------------------------------------- gui.statistic.show

  # Show the gridding statistic.

  const gui.statistic.show := function()
  {
    if (len(parms.statistic) == 1) {
      gui.statistic.bn->text(parms.statistic)
    } else {
      gui.statistic.bn->text('(multiple)')
    }

    i := 0
    for (s in field_names(gui.statistics)) {
      i +:= 1
      t := spaste('statistic_', i)
      gui[t].bn->state(any(parms.statistic == s))
    }

    if (all(parms.statistic == 'NSPECTRA' |
            parms.statistic == 'WEIGHT'   |
            parms.statistic == 'BEAMSUM'  |
            parms.statistic == 'BEAMRSS')) {
      gui.blank_level.en->relief('ridge')
      gui.blank_level.en->disabled(T)
    } else {
      if (!any(parms.config == "HIPASS HVC ZOA")) {
        gui.blank_level.en->relief('sunken')
        gui.blank_level.en->disabled(F)
      }
    }
  }

  #-------------------------------------------------------- gui.ZOA_field.show

  # Show ZOA field centre.

  const gui.ZOA_field.show := function()
  {
    if (parms.config == 'ZOA') {
      # Update the ZOA cube id.
      gui.ZOA_field.bn->text(spaste(parms.ZOA_field, sprintf('%c', 176)))
    }
  }

  #---------------------------------------------------------------------------
  # Events that we respond to.
  #---------------------------------------------------------------------------

  # Set parameter values.
  whenever
    self->setparm do
      if (!wrk.locked) setparm($value)

  # Set parameter set.
  whenever
    self->setconfig do
      setparm([config = $value])

  # Show parameter values.
  whenever
    self->printparms do {
      readgui()
      print ''
      printrecord(parms, 'parms')
    }

  # Show parameter validation rules.
  whenever
    self->printvalid do {
      print ''
      printrecord(pchek, 'valid')
    }

  # Disable parameter entry.
  whenever
    self->lock do {
      if (!wrk.locked) {
        wrk.locked := T
        if (is_agent(gui.f1)) gui.f1->disable()
      }
    }

  # Enable parameter entry.
  whenever
    self->unlock do {
      if (wrk.locked) {
        if (is_agent(gui.f1)) gui.f1->enable()
        wrk.locked := F
      }
    }

  # Start gridding.
  whenever
    self->go do {
      setparm($value)
      go()
    }

  # Process a HIPASS field (string) or cube number (integer).
  whenever
    self->HIPASS_field do {
      config := 'HIPASS'
      config::field := $value
      setparm([config = config])
      go()
    }

  # Process a HVC field (string) or cube number (integer).
  whenever
    self->HVC_field do {
      config := 'HVC'
      config::field := $value
      setparm([config = config])
      go()
    }

  # Process a ZOA field (string or integer).
  whenever
    self->ZOA_field do {
      config := 'ZOA'
      config::field := $value
      setparm([config = config])
      go()
    }

  # Abort gridding.
  whenever
    self->abort do {
      if (is_agent(wrk.client)) {
        if (wrk.client.host == wrk.host) {
          # Local invokation.
          message('Sending SIGKILL to PID ', wrk.client.established.pid)
          shell('kill -KILL', wrk.client.established.pid)

        } else {
          # Remote invokation.
          message('Sending SIGKILL to PID ', wrk.client.established.pid, '@',
                  wrk.client.host)
          shell('rsh', wrk.client.host, 'kill -KILL',
                wrk.client.established.pid)
        }

        wrk.logger->log([location='gridzilla', message='ABORTED ON REQUEST.',
                         priority='NORMAL'])
      }

      wrk.client := F
      if (is_agent(gui.f1)) {
        if (wrk.locked) gui.f1->enable()
        if (is_agent(gui.go.bn)) gui.go.bn->disabled(F)
        gui.abort.bn->disabled(T)
        if (wrk.locked) gui.f1->disable()
        message('Processing aborted')
      }

      self->finished()
    }


  # Create or expose the GUI.
  whenever
    self->showgui do {
      showgui($value)
      self->guidone()
    }

  # Hide the GUI.
  whenever
    self->hidegui do
      if (is_agent(gui.f1)) gui.f1->unmap()

  # Close down.
  whenever
    self->terminate do {
      readgui()
      store(parms, wrk.lastexit)

      if (is_agent(wrk.client)) {
        wrk.client->terminate()
        deactivate whenever_stmts(wrk.client).stmt
      }

      deactivate wrk.whenevers
      self->done()
      gui  := F
      wrk  := F
      self := F
    }

  wrk.whenevers := whenever_stmts(self).stmt

  #---------------------------------------------------------------------------
  # Initialize.
  #---------------------------------------------------------------------------

  # Set parameters.
  args := [config         = 'GENERAL',
           client_name    = client_name,
           client_dir     = client_dir,
           client_host    = client_host,
           cubcen_dir     = cubcen_dir,
           remote         = remote,
           beamsel        = beamsel,
           rangeSpec      = rangeSpec,
           startSpec      = startSpec,
           endSpec        = endSpec,
           restFreq       = restFreq,
           IFsel          = IFsel,
           pol_op         = pol_op,
           spectral       = spectral,
           continuum      = continuum,
           baseline       = baseline,
           directories    = directories,
           filemask       = filemask,
           filext         = filext,
           files          = files,
           selection      = selection,
           HIPASS_field   = HIPASS_field,
           HVC_field      = HVC_field,
           ZOA_field      = ZOA_field,
           cull           = cull,
           projection     = projection,
           pv             = pv,
           coordSys       = coordSys,
           refpoint       = refpoint,
           reference_lng  = reference_lng,
           reference_lat  = reference_lat,
           lonpole        = lonpole,
           latpole        = latpole,
           autosize       = autosize,
           intrefpix      = intrefpix,
           centre_lng     = centre_lng,
           centre_lat     = centre_lat,
           pixel_width    = pixel_width,
           pixel_height   = pixel_height,
           image_width    = image_width,
           image_height   = image_height,
           tsysmin        = tsysmin,
           tsysmax        = tsysmax,
           datamin        = datamin,
           datamax        = datamax,
           chan_err       = chan_err,
           statistic      = statistic,
           clip_fraction  = clip_fraction,
           tsys_weight    = tsys_weight,
           beam_weight    = beam_weight,
           beam_FWHM      = beam_FWHM,
           beam_normal    = beam_normal,
           kernel_type    = kernel_type,
           kernel_FWHM    = kernel_FWHM,
           cutoff_radius  = cutoff_radius,
           blank_level    = blank_level,
           storage        = storage,
           spectype       = spectype,
           short_int      = short_int,
           write_dir      = write_dir,
           p_FITSfilename = p_FITSfilename,
           sources        = sources]

  if (!streq(field_names(args), field_names(pchek))) {
    fail spaste(self.file, ': internal inconsistency - args field names.')
  }

  # Recover last exit state.
  if (len(stat(wrk.lastexit))) {
    last := read_value(wrk.lastexit)

    j := 0
    for (parm in field_names(pchek)) {
      j +:= 1

      # Don't override any non-defaulting arguments.
      if (has_field(args, parm) && has_field(last, parm)) {
        if (missing()[j]) {
          # Parameters not to recover:
          if (any(parm == "client_dir client_host remote")) continue

          args[parm] := last[parm]

        } else {
          # Reset the default value for this parameter.
          pchek[parm][1].default := args[parm]
        }
      }
    }
  }

  setparm(args)

  # Load HIPASS and HVC field centres and scan numbers.
  HIPASS_fields()
  HVC_fields()

  # Zone of Avoidance standard galactic longitudes.
  wrk.ZOA_fields := pchek.ZOA_field.string.valid

  # Enable searching and enforce processing restrictions.
  wrk.search := T
  setparm([config = config])
}
