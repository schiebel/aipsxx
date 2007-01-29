#RECIPE:   Fill, reduce and image VLA continuum data
#CATAGORY: Synthesis
#GOALS:    Fill, reduce and image VLA continuum data
#USING:	   ms, msplot, calibrater, imager
#RESULTS:  calibrated data set, image 
#ASSUME:   data: mol74h.uvf
#SYNOPSIS: Script fills data into AIPS from a 1994 VLA archive tape
#          It then uses AIPS to write out a UVFITS file.
#          AIPS++ is then used to reduce and image one of the sources.
#SCRIPTNAME: vlacontrec.g
#SCRIPT - NOTE: OUTPUT is mixed within the script
# 
# This script fills data into AIPS from a 1994 VLA archive tape. 
# It then uses AIPS to write out a UVFITS file.  
# AIPS++ is then used to reduce and image one of the sources in the file. 
# 
# Created by D. Shepherd on 16sep02
# 
 
## Data:
# Project code: AM 462: Ricardo Cesaroni, 4.8 GHz C-band 6cm
# BnC array ==> more than 2" resolution
# Primary Beam = 9' at C band
# 
# Data is on: 
# Archive tape XH94071, Project tape N5517, 10th file on archive tape
# 
# Source of interest = Mol74H 
# (there are many sources in this file, this script only calibrates
# and images one source, mol74h).  
#    The mol74h field is centered on an InfraRed Source 
#    at B1950 18 50 45.198 +01 21 09.087
# Data is published in: 
#       Molinari S., Brand J., Cesaroni R., Palla F., Palumbo G.G.C.
#       <Astron. Astrophys. 336, 339 (1998)>
      
# This data was reduced and imaged again in AIPS++ because I wanted
# to see if emission existed 40" north of the phase center.  The published
# image did not show this region. 

#=============================================================
# AIPS: Fill the data from an old archive tape
#=============================================================

# fill archive data from 1994
# start aips
# tape
# inp mount
# intap 1; remhost ''; mount

# task 'fillm'
# vlaobs 'am462'
# doall 1; ncount 1000; nfiles 9
# cparm 0; dparm 0; bparm 0
# doweight 1; doconcat 0; douvcomp 0; outdi 1
# inp
# go fillm

#=============================================================
# flux cal = 0134+329 (3c48) 
# 	==> uvrange restriction = 0-25 for C band in BnC config 
# source and gain cals are: 
# > FILLM1: Found 1801+010  :    0 50.000 MHz at IAT   0/ 03:42:00.0
# > FILLM1: Found MOL74H    :    0 50.000 MHz at IAT   0/ 03:44:50.0
# > FILLM1: Found MOL76H    :    0 50.000 MHz at IAT   0/ 03:49:20.0
# > FILLM1: Found MOL78H    :    0 50.000 MHz at IAT   0/ 03:53:50.0
# > FILLM1: Found 1821+107  :    0 50.000 MHz at IAT   0/ 03:58:40.0
# This script only images the source: MOL74H 
#=============================================================
# uc
#AIPS 1:    5 2160 19941004    .C BAND.    1 UV 08-SEP-2002 12:22:35
#AIPS 1:    6 2160 19941004    .U BAND.    1 UV 08-SEP-2002 12:12:47

# task 'fittp'; inp
# getn 5; outfi 'mol74h.uvf'; inp
# go fittp

# mv /home/sola/AIPS/DA01/FITS/MOL74H.UVF 
#	/home/sola/dss/projects.current/g34.4/vla/mol74h.uvf

 #=============================================================
 # Start AIPS++: 
 #=============================================================
source /aips++/stable/aipsinit.csh
aips++

 #=============================================================
 # Convert the fits file to an AIPS++ Measurement Set:
 #=============================================================
include 'ms.g'
mset:=fitstoms(msfile='mol74h.tst.ms', fitsfile='mol74h.uvf');
mset.summary(verbose=T);
mset.done();

 #=============================================================
 # Summary listing: 
 #=============================================================
 #           MeasurementSet Name:  mol74h.ms      MS Version 2
 #
 #   Observer: AM462     Project:   
 #Observation: VLA
 #Data records: 872730       Total integration time = 17810 seconds
 #   Observed from   04-Oct-1994/03:23:30   to   04-Oct-1994/08:20:20
 #
 #   ObservationID = 1         ArrayID = 1
 #  Date        Timerange                Scan  Field          DataDescIds
 #  04-Oct-1994/03:23:30.0 - 03:30:40.0     1  0134+329       [1, 2]
 #              03:37:00.0 - 03:41:10.0     2  WC1            [1, 2]
 #              03:42:00.0 - 03:44:00.0     3  1801+010       [1, 2]
 #              03:44:50.0 - 03:48:50.0     4  MOL74H         [1, 2]
 #              03:49:20.0 - 03:53:20.0     5  MOL76H         [1, 2]
 #              03:53:50.0 - 03:57:50.0     6  MOL78H         [1, 2]
 #              03:58:40.0 - 04:00:30.0     7  1821+107       [1, 2]
 #Fields: 55
 #  ID   Name          Right Ascension  Declination   Epoch   
 #  1    0134+329      01:34:49.83      +32.54.20.52  B1950   
 #  2    WC1           18:50:17.50      +00.51.45.80  B1950   
 #  3    1801+010      18:01:43.39      +01.01.18.80  B1950   
 #  4    MOL74H        18:50:45.20      +01.21.09.00  B1950   
 #  5    MOL76H        18:51:45.30      +04.37.42.00  B1950   
 #  6    MOL78H        18:53:18.00      +00.47.26.00  B1950   
 #  7    1821+107      18:21:41.66      +10.42.43.90  B1950   
 #Data descriptions: 2 (2 spectral windows and 1 polarization setups)
 #  ID    Ref.Freq    #Chans  Resolution  TotalBW     Correlations    
 #  1     4885.1 MHz  1       50000  kHz  50000  kHz  RR  RL  LR  LL  
 #  2     4835.1 MHz  1       50000  kHz  50000  kHz  RR  RL  LR  LL  
 #Antennas: 26:
 #  ID   Name  Station   Diam.    Long.         Lat.         
 #  1    1     VLA:N32   25.0 m   -107.37.22.0  +33.56.33.6  
 #  2    2     VLA:W10   25.0 m   -107.37.28.9  +33.53.48.9  
 #  3    3     VLA:W2    25.0 m   -107.37.07.4  +33.54.00.9  
 #  4    4     VLA:E2    25.0 m   -107.37.04.4  +33.54.01.1  
 #  5    5     VLA:E12   25.0 m   -107.36.31.7  +33.53.48.5  
 #  6    6     VLA:E18   25.0 m   -107.35.57.2  +33.53.35.1  
 #  7    7     VLA:E16   25.0 m   -107.36.09.8  +33.53.40.0  
 #  8    8     VLA:W8    25.0 m   -107.37.21.6  +33.53.53.0  
 #  10   10    VLA:W12   25.0 m   -107.37.37.4  +33.53.44.2  
 #  11   11    VLA:N24   25.0 m   -107.37.16.1  +33.55.37.7  
 #  12   12    VLA:W4    25.0 m   -107.37.10.8  +33.53.59.1  
 #  13   13    VLA:N12   25.0 m   -107.37.09.0  +33.54.30.0  
 #  14   14    VLA:N4    25.0 m   -107.37.06.5  +33.54.06.1  
 #  15   15    VLA:N20   25.0 m   -107.37.13.2  +33.55.09.5  
 #  16   16    VLA:E6    25.0 m   -107.36.55.6  +33.53.57.7  
 #  17   17    VLA:E8    25.0 m   -107.36.48.9  +33.53.55.1  
 #  18   18    VLA:W14   25.0 m   -107.37.46.9  +33.53.38.9  
 #  19   19    VLA:N28   25.0 m   -107.37.18.7  +33.56.02.5  
 #  20   20    VLA:W18   25.0 m   -107.38.08.9  +33.53.26.5  
 #  21   21    VLA:W6    25.0 m   -107.37.15.6  +33.53.56.4  
 #  22   22    VLA:E4    25.0 m   -107.37.00.8  +33.53.59.7  
 #  24   24    VLA:E10   25.0 m   -107.36.40.9  +33.53.52.0  
 #  25   25    VLA:N16   25.0 m   -107.37.10.9  +33.54.48.0  
 #  26   26    VLA:N36   25.0 m   -107.37.25.6  +33.57.07.6  
 #  27   27    VLA:N8    25.0 m   -107.37.07.5  +33.54.15.8  
 #  28   28    VLA:W16   25.0 m   -107.37.57.4  +33.53.33.0  
 #  

 #=============================================================
 # Get an antenna plot and flag bad data:
 #=============================================================
include 'msplot.g';
msplt:=msplot(msfile="mol74h.ms" , edit=F);
msplt.done();

 # flux and gcals:  ANT 2 has low flux, rest looks OK. 
 # no birdies on src. Don't flag anything for now.  

 # select region "antenna", click on spanner and then 
 #   "from MS" the Y config plot appears, choose file - print.
 # possible refants: 3, 4, 21, 13, 11

 #=============================================================
 # Set flux for 0134+329 (3c48) 
 #=============================================================
include 'mosaicwizard.g';
imagr:=imager(filename="mol74h.ms" );
 # initializing MODEL_DATA, CORRECTED_DATA and IMAGING_WEIGHT columns
ok:=imagr.setjy(fieldid=-1, spwid=-1, fluxdensity=-1.0);
 #     0134+329  spwid=  1  [I=5.405, Q=0, U=0, V=0] Jy, (Perley-Taylor 
99)
 #     0134+329  spwid=  2  [I=5.458, Q=0, U=0, V=0] Jy, (Perley-Taylor 
99)
 #     1801+010  spwid=  1  [I=1, Q=0, U=0, V=0] Jy, (default)
 #     1801+010  spwid=  2  [I=1, Q=0, U=0, V=0] Jy, (default)
 #       MOL74H  spwid=  1  [I=1, Q=0, U=0, V=0] Jy, (default)
 #       MOL74H  spwid=  2  [I=1, Q=0, U=0, V=0] Jy, (default)
 #     1821+107  spwid=  1  [I=1, Q=0, U=0, V=0] Jy, (default)
 #     1821+107  spwid=  2  [I=1, Q=0, U=0, V=0] Jy, (default)
imagr.done();

 #  catalog shows MODEL_DATA created with fluxes reported above, 
 #   CORRECTED_DATA = observed data & IMAGING_WEIGHT column exists.

 #  ID   Name          Right Ascension  Declination   Epoch   
 #  1    0134+329      01:34:49.83      +32.54.20.52  B1950   
 #  2    WC1           18:50:17.50      +00.51.45.80  B1950   
 #  3    1801+010      18:01:43.39      +01.01.18.80  B1950   
 #  4    MOL74H        18:50:45.20      +01.21.09.00  B1950   
 #  5    MOL76H        18:51:45.30      +04.37.42.00  B1950   
 #  6    MOL78H        18:53:18.00      +00.47.26.00  B1950   
 #  7    1821+107      18:21:41.66      +10.42.43.90  B1950   

 #=============================================================
 # Solve for the gains and apply
 # Remember  1=fluxcal, 3,7=gain cals, 4=src
 #=============================================================
include 'calibrater.g';
calib:=calibrater(filename="mol74h.ms" );
ok:=calib.setdata(mode="none", uvrange=[0,25], 
        msselect='FIELD_ID in [1,3,7] && SPECTRAL_WINDOW_ID in [2]');
 # solve for G soln's on a 2min timescale (one per obs on each cal)
ok:=calib.reset();
ok:=calib.setsolve(type="G" , t=120, preavg=0.0, phaseonly=F, 
        refant=3, table="mol74h.gcal" , append=F);
ok:=calib.solve();
ok:=calib.plotcal(tablename='mol74h.gcal');
 # ant 2 is low but consistent with rest of data...

 #=============================================================
 # Boot strap flux density scale from 0134+329 (3c48)  to the gcal:
 #=============================================================
ok:=calib.fluxscale(tablein="mol74h.gcal" , tableout="mol74h.flxcal" , 
        reference="0134+329" , transfer=["1801+010","1821+107"]);
 # Flux density for 1801+010 (spw=1) is:     0.861 +/-  0.000 Jy
 # Flux density for 1801+010 (spw=2) is:     0.860 +/-  0.000 Jy
 # Flux density for 1821+107 (spw=1) is:     0.890 +/-  0.000 Jy
 # Flux density for 1821+107 (spw=2) is:     0.892 +/-  0.000 Jy
 #	- flux is consistent with recent measured fluxes. 

ok:=calib.plotcal(tablename='mol74h.flxcal');

 #=============================================================
 # Select source uv data to be corrected with no restricted uv range
 #   (the soln's were derived for a restricted uv range but I want
 #   to apply the soln's to all data...):
 #=============================================================
ok:=calib.setdata(mode="none",
	msselect='FIELD_ID IN [1,3,4,7] AND SPECTRAL_WINDOW_ID in [1,2]' 
);

 #=============================================================
 # Select the flux-scaled gain cal solutions to be used in interpolation 
 #  to the source uv data:
 #=============================================================
ok:=calib.reset();
 #=============================================================
 # apply solutions derived from flux & gain cals (fields 1, 3 & 7):
 #=============================================================
ok:=calib.setapply(type="G" , t=0, table="mol74h.flxcal" , 
        select='FIELD_ID IN [1,3,4,7]' );

 #=============================================================
 # Apply the gcal: 
 #=============================================================
calib.correct()
calib.done();

- check the uv data amplitudes and phases on corrected data column 
include 'msplot.g';
msplt:=msplot(msfile="mol74h.ms" , edit=F);
msplt.done();
  # plot corrected data amplitude vs uv distance

 #=============================================================
 # Check the uv data amplitudes and phases on corrected data column 
 #=============================================================
include 'msplot.g';
msplt:=msplot(msfile="mol74h.ms" , edit=T);
msplt.done();
  # plot corrected data amplitude vs uv distance


 #=============================================================
 # Make Image of gcals & mol74h
 #=============================================================
include 'mosaicwizard.g';
im:=imager(filename="mol74h.ms" );
ok:=im.advise(takeadvice=F, amplitudeloss=0.05, 
        fieldofview=[value=9.0, unit="arcmin" ]);
 
 # Recommended cell size < 0.938626 arcsec
 # Recommended number of pixels = 576

ok:=im.setdata(mode="none" , nchan=1, start=1, step=1, 
        mstart=[value=0.0, unit="km/s" ], 
        mstep=[value=0.0, unit="km/s" ], spwid=[1,2] , 
        fieldid=4, msselect='');
ok:=im.setimage(nx=512, ny=512, cellx=[value=0.5, unit="arcsec" ], 
        celly=[value=0.5, unit="arcsec" ], stokes="I" , doshift=F, 
	mode="mfs" , spwid=[1, 2] , fieldid=4);
ok:=im.weight(type="natural" , rmode="norm" , 
        noise=[value=0.0, unit="Jy" ], robust=0.0, 
        fieldofview=[value=0.0, unit="rad" ], npixels=0);
ok:=im.clean(algorithm="clark" , niter=1000, gain=0.1, 
        threshold=[value=0.0, unit="Jy" ], displayprogress=F, 
        model="mol74h.clean", interactive=T, npercycle=500,
        mask="mol74h.mask" , image="mol74h.cln");
 # nice point near ir source 
 # rms = 2.8e-4, AIPS got 1.7e-4 (I did no editing, could be the 
difference). 
 # max = 8.75e-3Jy at psn 18 50 46.467 +01 21 02 - matches AIPS peak psn, 
		slightly higher peak flux. 
 # total flux = 9.341 mJy in the source. 
 # flux at the position of G34.4 MM = 5.3e-4
 # theory rms should be about 1e-4 and max should be 8.6e-3 Jy/bm
im.done();

 # The rms is almost twice what it should be...
 # I'd like to get a better limit on the flux density at the mm core. 
 # edit the data: 

include 'msplot.g';
msplt:=msplot(msfile="mol74h.ms" , edit=T);
 #  flagged src data above 0.6 Jy & some of the short spacings - there
 #  is extended emission in the map that is causing imaging problems. 
 #  Downweight sensitivity to extended structure. 
 #  Also ants 1 & 26 have poor phase correction and more widely
 #  scattered amplitudes on the gain and flux cals....
 #  killed ants 1 & 26 totally.  
msplt.done();

 #=============================================================
 # Reimage:
 #=============================================================
include 'mosaicwizard.g';
im:=imager(filename="mol74h.ms" );
ok:=im.setdata(mode="none" , nchan=1, start=1, step=1, 
        mstart=[value=0.0, unit="km/s" ], 
        mstep=[value=0.0, unit="km/s" ], spwid=[1,2] , 
        fieldid=4, msselect='');
ok:=im.setimage(nx=512, ny=512, cellx=[value=0.5, unit="arcsec" ], 
        celly=[value=0.5, unit="arcsec" ], stokes="I" , doshift=F, 
	mode="mfs" , spwid=[1, 2] , fieldid=4);
ok:=im.weight(type="natural" , rmode="norm" , 
        noise=[value=0.0, unit="Jy" ], robust=0.0, 
        fieldofview=[value=0.0, unit="rad" ], npixels=0);
ok:=im.clean(algorithm="clark" , niter=1000, gain=0.1, 
        threshold=[value=0.0, unit="Jy" ], displayprogress=F, 
        model="mol74h.clean2", interactive=T, npercycle=500,
        mask="mol74h.mask2" , image="mol74h.cln2");
im.done();

 # Beam : 5.65128 by 2.98381 (arcsec) at pa 60.1303 (deg) 
 # rms = 1.9 to 1.99e-4 OK, there is less data...
 # max = 8.72e-3Jy at psn 18 50 46.467 +01 21 01.5 - .5" from AIPS peak 
psn, 
 #                        B1950 coords. 
 # total flux = 9.22 mJy in the source. 
 # 
 # max flux at the position of G34.4 MM = 7.028e-4, total = 0.48mJy
 # good image, I'll stop here...

 #=============================================================
 # Just for fun:  See what robust imaging will give me:
 #=============================================================
include 'mosaicwizard.g';
im:=imager(filename="mol74h.ms" );
ok:=im.setdata(mode="none" , nchan=1, start=1, step=1, 
        mstart=[value=0.0, unit="km/s" ], 
        mstep=[value=0.0, unit="km/s" ], spwid=[1,2] , 
        fieldid=4, msselect='');
ok:=im.setimage(nx=512, ny=512, cellx=[value=0.5, unit="arcsec" ], 
        celly=[value=0.5, unit="arcsec" ], stokes="I" , doshift=F, 
	mode="mfs" , spwid=[1, 2] , fieldid=4);
ok:=im.weight(type="briggs" , rmode="norm" , 
        noise=[value=0.0, unit="Jy" ], robust=0.0, 
        fieldofview=[value=0.0, unit="rad" ], npixels=0);
ok:=im.clean(algorithm="clark" , niter=1000, gain=0.1, 
        threshold=[value=0.0, unit="Jy" ], displayprogress=F, 
        model="mol74h.clean3", interactive=T, npercycle=500,
        mask="mol74h.mask3" , image="mol74h.cln3");
im.done();

 # beam : 5.21546 by 2.36018 (arcsec) at pa 60.6233 (deg) 
 # rms = 1.9 to 2.e-4 OK, there is less data...
 # max = 8.565e-3Jy at psn 18 50 46.467 +01 21 02
 #                        B1950 coords. 
 # total flux = 9.37 mJy in the source. 
 # 
 # max flux at the position of G34.4 MM = 7.506e-4, total = 0.45mJy
 # nat weighting looks better...

 # Best image is with natural weighting, mol74h.cln5

 #=============================================================
 # Make a nice figure:
 #=============================================================

 # Create mol74n.olay file with header rows using emacs (each overlay
 # file can only have one symbol so if you want to use different
 # symbols for different sources they have to be in different overlay
 # files):

 # Region of interest is at position in B1950 
 #	(away from source found above):
 # Axis 1: Fitted RA---SIN  =  18:50:45.800
 # Axis 2: Fitted DEC--SIN  =   1:21:40.06

 # mol74n.olay file looks like:
   Name  RA           DEC           comment
   A     A            A             A
   G34.4_MM  18:50:45.80  +1:21:40.06   none

 # At glish command prompt type:
include 'skycatalog.g';
sca := skycatalog('mol74n.olay.tbl');
sca.fromascii(asciifile='mol74n.olay',hasheader=T,longcol='RA',
        latcol='DEC',dirtype='B1950');
sca.done();

 # Add labels:  Create a file mol74n.labels that looks like:
   Name                            RA           DEC         comment
   A                               A            A           A
   G34.4_MM                        18:50:45.0  +1:21:40.06  
filled_triangle
   contours_-3,3,5,10,15,...xsigma 18:50:45.0  +1:20:35.0
   rms=0.19_mJy/bm                 18:50:45.0  +1:20:40.0
   max=8.72_mJy/bm                 18:50:45.0  +1:20:45.0
   total=9.22_mJy/bm               18:50:45.0  +1:20:50.0

 # At glish command prompt type:
sca := skycatalog('mol74n.labels.tbl');
sca.fromascii(asciifile='mol74n.labels',hasheader=T,longcol='RA',
        latcol='DEC',dirtype='B1950');
sca.done();

 # Note, labels and names cannot have spaces, & they cannot be in
 # quotes.  Also, labels are plotted centered on the coordinate, 
 # you cannot right or left justify them.  The symbol is always 
 # plotted but if you choose symbol size=0 and/or make it white 
 # on a white background you will not see it.

 # In viewer bring in a raster image of mol74h
 # Then bring in the skycatalog tables just created
 # pull up the 'Adjust' panel for the skytables, 
 # choose marker type, size, and color as desired
 # or choose the label and label properties.  

 #=============================================================
 # OUTPUT image from the viewer is saved as 6cm.app.ps
 #=============================================================

 #=============================================================
 # Write to uvfits file:
 #=============================================================
im:=image(infile="mol74h.cln5" );
im.tofits(velocity=F, optical=F, bitpix=-32, 
	outfile="mol74h.im.fits" , overwrite=F);
im.done();

 #=============================================================
 # Cleanup:
 #=============================================================
rm -f-r mol74h.clean* mol74h.clean*.residual
rm -f-r mol74h.flxcal mol74h.flxcal2 mol74h.flxcal3 mol74h.flxcal4
rm -f-r mol74h.gcal*
rm -f-r mol74h.mask mol74h.mask2 mol74h.mask3 mol74h.mask4 mol74h.mask6
rm -f-r mol74h.cln mol74h.cln2 mol74h.cln3 mol74h.cln4 mol74h.cln6
rm -f-r mol74h.ms.flags*

 #=============================================================
 # End of script.
 #=============================================================

#SUBMITTER:  Debra Shepherd
#SUBMITAFFL: NRAO-Socorro
#SUBMITDATE: 2002-Sep-16
