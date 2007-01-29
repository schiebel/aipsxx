# ascii2complist.g: convert an ascii file into a component list
# Copyright (C) 1999,2000,2001,2002
# Associated Universities, Inc. Washington DC, USA.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
# License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation,
# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: ascii2complist.g,v 19.2 2004/08/25 01:06:04 cvsmgr Exp $

pragma include once
  
# This reads an ascii file and converts it into a AIPS++ component list.
# The only formats currently read are the AIPS ST format, WENSS, the
# Caltech format, and FIRST.
# To add a new format:
#  1. Add a new function private.readline['yourformat']
#  2. Add (defaulted) arguments as needed.
#  3. Write a test in ascii2complisttest.
#
include "serverexists.g"
include "componentlist.g";
include "quanta.g"
include "measures.g"
include "note.g";
include "table.g";
include 'unset.g'

const ascii2complist := function(complist, asciifile,
				 refer='j2000', 
				 format='ST',
				 flux=unset, direction=unset, spectrum=unset) {2

  # Check for servers
  if(!serverexists('dq', 'quanta', dq)) {
    return throw('Server dq (quanta) does not exist', origin='ascii2complist');
  }

  if(!serverexists('dm', 'measures', dm)) {
    return throw('Server dm (measures) does not exist', origin='ascii2complist');
  }

  # Preprocess inputs
  if(is_unset(refer)) {
    return throw('Need an input reference frame (refer)', origin='ascii2complist');
  }
  if(!is_string(complist)) {
    return throw('complist must be a string', origin='ascii2complist');
  }

  if(!is_string(asciifile)) {
    return throw('asciifile must be a string', origin='ascii2complist');
  }

  if(is_unset(flux)) {
    flux := [value=[0.0, 0.0, 0.0, 0.0], unit='Jy', polarisation="Stokes"]; 
  }
  if(is_unset(spectrum)) {
    spectrum := [type="Constant", frequency=[type="frequency" , refer="LSRK" ,
					     m0=[unit="MHz" , value=327.0]]];
  }

  # Various formats
  format := to_lower(format);
  if(format=='st') {
    note(paste('Reading AIPS ST file', asciifile), origin='ascii2complist');
  }
  else if(format=='caltech') {
    if(!is_measure(direction)) {
      return throw('Conversion of the Caltech format requires the direction to be specified');
    }
    note(paste('Reading Caltech model file', asciifile), origin='ascii2complist');
    if(!is_unset(refer)) {
      note('Ignoring specified input reference frame: using direction instead');
      refer:=unset;
    }
  }
  else if(format=='wenss') {
    note(paste('Reading WENSS catalog file', asciifile), origin='ascii2complist');
    spectrum.frequency.m0.value:=327.0;
  }
  else if(format=='first') {
    note(paste('Reading FIRST catalog file', asciifile), origin='ascii2complist');
    spectrum.frequency.m0.value:=1400.0;
  }
  else if(format=='first-search') {
    note(paste('Reading FIRST catalog file from search page', asciifile), origin='ascii2complist');
    spectrum.frequency.m0.value:=1400.0;
  }
  else if(format=='nvss') {
    note(paste('Reading NVSS catalog file', asciifile), origin='ascii2complist');
    note('Ignoring shape fields', origin='ascii2complist');
    spectrum.frequency.m0.value:=1400.0;
  }
  else if(format=='gb6') {
    note(paste('Reading GB6 catalog file', asciifile), origin='ascii2complist');
    spectrum.frequency.m0.value:=4850.0;
  }
  else {
    return throw(paste('Unknown format ', format), origin='ascii2complist');
  }

  private := [=];
  
  private.zeroaxiserror := dq.quantity('0.001arcsec');
  private.zeropaerror := dq.quantity('0.001deg');

  private.readline := [=];

  #######################
  # AIPS star file format
  private.readline['st'] := function(line, flux, spectrum, direction, refer) {

    line := split(line, ', ');
    if(length(line)<7) {
      return F;
    }

    # Initialize the component record
    rec := [=];
    rec.flux := flux;
    rec.spectrum := spectrum;
    rec.comment:=paste('star file: ', line);

    # Convert to a direction meaure
    ra  := spaste(line[1],':',line[2],':',line[3]);
    dec := spaste(line[4],'d',line[5],'m',line[6]);
    cdirection := dm.direction(refer, ra, dec); 
    if(!is_measure(cdirection)) {
      throw(paste('Direction invalid in :', line),
	    origin='ascii2complist');
      return F;
    }

    # Find the shape: note the bug in componentlist 
    # that we work around.
    if(length(line)>8) {
      bmaj := dq.quantity(as_float(line[7])*1.001, 'arcsec');
      bmin := dq.quantity(as_float(line[8])/1.001, 'arcsec');
      bpa  := dq.quantity(as_float(line[9]), 'deg');
      rec.shape := [type="Gaussian", direction=cdirection,
		    majoraxis=bmaj, minoraxis=bmin,
		    positionangle=bpa,
                    majoraxiserror=private.zeroaxiserror, minoraxiserror=private.zeroaxiserror, positionangleerror=private.zeropaerror];
    }
    else {
      rec.shape := [type="Point", direction=cdirection];
    }

    if(length(line)>9) {
      rec.label := line[10];
      rec.label ~:= s/\n//;
    }

    return rec;
  }

  ######################
  # Caltech model format
  # 1.0 10 43 20 20 0 0
  # 0.5 5 172 288 200 45 1
  # 0.23 100 63.2
    
  private.readline['caltech'] := function(line, flux, spectrum, direction, refer) {

    line := split(line, ', ');
    if(length(line)<3) {
      return F;
    }

    # Initialize the component record
    rec := [=];

    rec.comment:=paste('Caltech: ', line);

    rec.spectrum := spectrum;

    # Flux
    rec.flux := flux;
    rec.flux.value := array(0.0, 4);
    rec.flux.value[1] := as_float(line[1]);

    # Radius
    rad := dq.quantity(as_float(line[2]), 'marcsec')
    phi := dq.quantity(as_float(line[3]), 'deg')
    cosphi := dq.cos(phi); 
    sinphi := dq.sin(phi); 
    cosdec := dq.cos(direction.m1); 
    dra := dq.div(dq.mul(rad, cosphi), cosdec); 
    ddec := dq.mul(rad, cosphi); 

    # Convert to an absolute position
    ra  := dq.add(direction.m0, dra);
    dec := dq.add(direction.m1, ddec);

    cdirection := dm.direction(direction.refer, ra, dec); 
    if(!is_measure(cdirection)) {
      throw(paste('Direction invalid in :', line),
	    origin='ascii2complist');
      return F;
    }

    # Find the shape
    if(length(line)>5) {
      bmaj := dq.quantity(as_float(line[4]), 'marcsec');
      if(bmaj.value==0.0) {
	rec.shape := [type="Point", direction=cdirection];
      }
      else {
        ratio := dq.quantity(as_float(line[5])*0.999, '');
	bmin := dq.mul(bmaj, ratio);
	bpa  := dq.quantity(as_float(line[6]), 'deg');
	rec.shape := [type="Gaussian", direction=cdirection,
		      majoraxis=bmaj, minoraxis=bmin,
		      positionangle=bpa];
      }
      if(length(line)>6) {
	type := as_integer(line[7]);
        if(type==0) {
	}
        else if(type==1) {
	}
        else if(type==2) {
          rec.shape.type := 'Disk';
	}
	else {
          throw(paste('Cannot handle caltech component type ', type),
		origin='ascii2complist');
	  return F;
	}
      }
    }
    else {
      rec.shape := [type="Point", direction=cdirection];
    }

    return rec;
  }

  ######################
  # WENSS catalog format
  # e.g.
  # Dist. Name            Right Asc.   Decl.      T F Peak Int. Minor Major PA  Noise Frame
  # 1511  WNB1002.0+3952  10 02 05.96  39 52 44.4 S   26   17   0     0     0    2.9  WN40149H
  # 1531  WNB0957.8+4003   9 57 48.18  40 03 41.2 S * 17   23   0     0     0    3.1  WN40149H
  # 1584  WNB0957.7+3955   9 57 44.45  39 55 10.7 S   323  304  0     0     0    3.1  WN40149H
  private.readline['wenss'] := function(line, flux, spectrum, direction, refer) {
    line := split(line, ', ');
    if(length(line)<14) {
      return [=];
    }

    # Initialize the component record
    rec := [=];

    rec.label:=line[2];
    rec.label ~:= s/\n//;

    rec.comment:=paste('WENSS: ', line);

    rec.spectrum := spectrum;

    # Flux
    rec.flux := flux;
    offstar:=0;
    if(line[10]=='*') {
      offstar := 1;
    }
    # Use the integrated value
    rec.flux.value := array(0.0, 4);
    rec.flux.value[1] := as_float(line[11+offstar]);
    rec.flux.unit  := 'mJy';

    ra  := spaste(line[3],':',line[4],':',line[5]);
    dec := spaste(line[6],'d',line[7],'m',line[8]);
    cdirection := dm.direction(refer, ra, dec); 
    if(!is_measure(cdirection)) {
      throw(paste('Direction invalid in :', line),
	    origin='ascii2complist');
      return F;
    }

    # Find the shape
    bmaj := dq.quantity(as_float(line[13]), 'arcsec');
    if(bmaj.value==0.0) {
      rec.shape := [type="Point", direction=cdirection];
    }
    else {
      bmin := dq.quantity(as_float(line[12])/1.001, 'arcsec');
      bpa  := dq.quantity(as_float(line[14]), 'deg');
      rec.shape := [type="Gaussian", direction=cdirection,
		    majoraxis=bmaj, minoraxis=bmin,
		    positionangle=bpa,
                    majoraxiserror=private.zeroaxiserror, minoraxiserror=private.zeroaxiserror, positionangleerror=private.zeropaerror];
    }

    return rec;
  }

  # FIRST 
  # Do  Get Get  | Search     RA (2000)     Dec (2000)   Side  Peak     Int.     RMS   Deconv.  Deconv.  Deconv  Meas.     Meas.      Meas.    Field Name  
  # NED DSS FRST | Distance                              lobe  Flux     Flux            MajAx    MinAx   PosAng  MajAx     MinAx     PosAng                
  #SrchImg Img  | (arcsec)                              Flag (mJy/bm)  (mJy)   (mJy/b (arcsec) (arcsec) (deg)  (arcsec)  (arcsec)  (degrees)              
  # NED DSS FIMG |     0.4  10 50  7.261  +30 40 37.10     0     6.32    18.10  0.147    10.54     4.54   31.7     11.84      7.05       31.7 10510+30456E
  # NED DSS FIMG |     9.7  10 50  6.952  +30 40 46.36     0     2.94     8.77  0.147    13.90     2.17   80.0     14.91      5.82       80.0 10510+30456E
  # NED DSS FIMG |    16.8  10 50  6.025  +30 40 42.57     0     3.56     7.46  0.147     9.08     2.10   46.1     10.57      5.79       46.1 10510+30456E
  # NED DSS FIMG |    17.3  10 50  6.271  +30 40 25.98     0     6.79    26.24  0.147    10.37     7.97   57.3     11.69      9.63       57.3 10510+30456E

  private.readline['first-search'] := function(line, flux, spectrum, direction, refer) {

    line := split(line, ', ');
    if(length(line)<22) {
      return F;
    }

    # Initialize the component record
    rec := [=];

    rec.label:=line[22];
    rec.label ~:= s/\n//;

    rec.comment:=paste('FIRST: ', line);

    rec.spectrum := spectrum;

    # Flux
    rec.flux := flux;
    # Use the integrated value
    rec.flux.value := array(0.0, 4);
    rec.flux.value[1] := as_float(line[14]);
    rec.flux.unit  := 'mJy';

    ra  := spaste(line[6],':',line[7],':',line[8]);
    dec := spaste(line[9],'d',line[10],'m',line[11]);
    direction := dm.direction(refer, ra, dec); 

    cdirection := dm.direction(refer, ra, dec); 
    if(!is_measure(cdirection)) {
      throw(paste('Direction invalid in :', line),
	    origin='ascii2complist');
      return F;
    }

    # Find the shape
    bmaj := dq.quantity(as_float(line[15]), 'arcsec');
    if(bmaj.value==0.0) {
      rec.shape := [type="Point", direction=cdirection];
    }
    else {
      if(as_float(line[15])>as_float(line[16])) {
	bmin := dq.quantity(as_float(line[16])/1.001, 'arcsec');
	bpa  := dq.quantity(as_float(line[17]), 'deg');
      }
      else {
	if(as_float(line[15])==0) {
	  bmaj := dq.quantity(as_float(line[16]), 'arcsec');
 	  bmin := dq.quantity(as_float(line[16])/1.001, 'arcsec');
        }
        else {
	  bmaj := dq.quantity(as_float(line[16]), 'arcsec');
 	  bmin := dq.quantity(as_float(line[15])/1.001, 'arcsec');
        }
	bpa  := dq.quantity(as_float(line[17])+90.0, 'deg');
      }
      rec.shape := [type="Gaussian", direction=cdirection,
		    majoraxis=bmaj, minoraxis=bmin,
		    positionangle=bpa,
                    majoraxiserror=private.zeroaxiserror, minoraxiserror=private.zeroaxiserror, positionangleerror=private.zeropaerror];
    }

    return rec;
  }

  # FIRST 
#    RA  (2000)   Dec      W    Fpeak      Fint    Rms     Maj    Min    PA   fMaj   fMin   fPA Field Name
#06 50 44.043 +31 10 00.09       1.16      0.64   0.147   0.00   0.00  42.0   4.50   3.59  42.0 06510+31143E
#06 51 02.181 +31 11 13.33       1.58      2.66   0.139   4.99   3.94  91.6   7.35   6.69  91.6 06510+31143E
#06 51 03.826 +31 13 03.32 W     1.02      1.42   0.137   7.63   0.00   2.4   9.35   4.34   2.4 06510+31143E
#06 51 06.134 +31 19 02.00       7.29      9.64   0.145   4.09   1.82 131.3   6.77   5.70 131.3 06510+31143E
#06 51 10.784 +31 11 28.80      72.36    100.79   0.141   4.18   2.49   9.8   6.83   5.95   9.8 06510+31143E
# 1  2    3     4  5    6          7        8        9      10     11    12     13     14    15      16
  private.readline['first'] := function(line, flux, spectrum, direction, refer) {

#
# We do nothing with the warning flag
#
    if(line ~ m/ W /) {
      line ~:= s/ W /   /g;
    }

    line := split(line, ', ');
    if(length(line)<16) {
      return F;
    }

    # Initialize the component record
    rec := [=];

    rec.label:=line[16];
    rec.label ~:= s/\n//;

    rec.comment:=paste('FIRST: ', line);

    rec.spectrum := spectrum;

    # Flux
    rec.flux := flux;
    # Use the integrated value
    rec.flux.value := array(0.0, 4);
    rec.flux.value[1] := as_float(line[9]);
    rec.flux.unit  := 'mJy';

    ra  := spaste(line[1],':',line[2],':',line[3]);
    dec := spaste(line[4],'d',line[5],'m',line[6]);

    cdirection := dm.direction(refer, ra, dec); 
    if(!is_measure(cdirection)) {
      throw(paste('Direction invalid in :', line),
	    origin='ascii2complist');
      return F;
    }

    # Find the shape
    bmaj := dq.quantity(as_float(line[10]), 'arcsec');
    if(bmaj.value==0.0) {
      rec.shape := [type="Point", direction=cdirection];
    }
    else {
      if(as_float(line[10])>as_float(line[11])) {
	bmin := dq.quantity(as_float(line[11])/1.001, 'arcsec');
      }
      else {
	bmaj := dq.quantity(as_float(line[11]), 'arcsec');
	bmin := dq.quantity(as_float(line[10])/1.001, 'arcsec');
      } 
      if(bmin.value==0.0) bmin := bmaj;
      bpa  := dq.quantity(as_float(line[12]), 'deg');
     rec.shape := [type="Gaussian", direction=cdirection,
		    majoraxis=bmaj, minoraxis=bmin,
		    positionangle=bpa,
                    majoraxiserror=private.zeroaxiserror, minoraxiserror=private.zeroaxiserror, positionangleerror=private.zeropaerror];
    }

    return rec;
  }

#0.........1.........2.........3.........4.........5.........6.........7........
#1234567890123456789012345678901234567890123456789012345678901234567890123456789
#
#000004.7 0.7 +183324 11 -42.5 107.2    64    7      1.06 0.94  79   0  937  388
#
#Bytes (01--02).--- Hours of right ascension, format I2
#Bytes (03--04).--- Minutes of right ascension, format I2
#Bytes (05--08).--- Seconds of right ascension, format F4.1
#Bytes (09--12).--- RMS uncertainty in right ascension (s), format F4.1
#Byte  (14).    --- Sign of declination, format A1
#Bytes (15--16).--- Degrees of declination, format I2
#Bytes (17--18).--- Arcminutes of declination, format I2
#Bytes (19--20).--- Arcseconds of declination, format I2
#Bytes (22--23).--- RMS uncertainty in declination (arcsec), format I2
#Bytes (25--29).--- Galactic latitude (deg), format F5.1
#Bytes (31--35).--- Galactic longitude (deg), format F5.1
#Bytes (37--41).--- 4.85 GHz peak flux density (mJy), format I5
#Bytes (43--46).--- RMS uncertainty in peak flux density (mJy), format I4
#Byte  (49).    --- Flag "E" for significant extension, format A1
#Byte  (50).    --- Flag "W" for warning, format A1
#Byte  (51).    --- Flag "C" for confusion, format A1
#Bytes (53--56).--- Normalized FWHM major axis, format F4.2
#Bytes (58--61).--- Normalized FWHM minor axis, format F4.2
#Bytes (63--65).--- Fitted major-axis position angle (deg east of north),
#                   format I3
#Bytes (67--69).--- Local sky level (mJy), format I3
#Bytes (71--74).--- Map pixel column number counted from left, format I4
#Bytes (76--79).--- Map pixel row number counted from bottom, format I4

  private.readline['gb6'] := function(line, flux, spectrum, direction, refer) {

    bytes := as_byte(line);
    btos := function(index) {
      return as_string(bytes[index]);
    }

    # Initialize the component record
    rec := [=];

    rec.label:=line;
    rec.label ~:= s/\n//;

    rec.comment:=paste('gb6: ', line);

    rec.spectrum := spectrum;

    # Flux
    rec.flux := flux;
    # Use the integrated value
    rec.flux.value := array(0.0, 4);
    rec.flux.value[1] := as_float(btos(37:41));
    rec.flux.unit  := 'mJy';

    ra  := spaste(btos(1:2),':',btos(3:4),':',btos(5:8));
    dec := spaste(btos(14),btos(15:16),'d',btos(17:18),'m',btos(19:20),'.0');

    cdirection := dm.direction(refer, ra, dec); 
    if(!is_measure(cdirection)) {
      throw(paste('Direction invalid in :', line),
	    origin='ascii2complist');
      return F;
    }

    # Find the shape
    bmaj := dq.quantity(as_float(btos(53:56)), 'arcsec');
    if(bmaj.value==0.0) {
      rec.shape := [type="Point", direction=cdirection];
    }
    else {
      if(as_float(btos(53:56))>as_float(btos(58:61))) {
	bmin := dq.quantity(as_float(btos(58:61))/1.001, 'arcsec');
      }
      else {
	bmaj := dq.quantity(as_float(btos(58:61)), 'arcsec');
	bmin := dq.quantity(as_float(btos(53:56))/1.001, 'arcsec');
      } 
      if(bmin.value==0.0) bmin := bmaj;
      bpa  := dq.quantity(as_float(btos(63:65)), 'deg');
      rec.shape := [type="Gaussian", direction=cdirection,
		    majoraxis=bmaj, minoraxis=bmin,
		    positionangle=bpa,
                    majoraxiserror=private.zeroaxiserror,
                    minoraxiserror=private.zeroaxiserror,
                    positionangleerror=private.zeropaerror];
    }

    return rec;
  }

  # NVSS
  #     RA(2000)  Dec(2000) Dist(") Flux  Major Minor  PA  Res P_Flux P_ang  Field    X_pix  Y_pix
  # h  m    s    d  m   s   Ori     mJy   "     "     deg       mJy  deg
  # 09 55 16.67 +39 35 48.4  3573   12.2  31.7 <25.4  19.2     -0.13       C1000P40  730.30  417.67
  # 0.12         1.8  -114    1.0   5.3        10.6      0.62
  # 09 55 19.35 +40 23 12.0  3504    3.5 <51.3 <39.6           -0.27       C1000P40  725.75  607.19
  # 0.39         4.1   -66    0.5                        0.48
  # 09 55 27.34 +39 35 35.6  3467    3.6 <85.5 <40.1           -0.05       C1000P40  722.09  416.70
  # 0.48         6.8  -115    0.5                        0.84
  # 09 55 31.43 +39 36 58.1  3389    9.9  33.8 <33.0  89.2     -0.09       C1000P40  718.87  422.16
  # 0.20         1.8  -114    1.0   6.6        16.7      0.71
  # 09 55 31.50 +40 16 39.4  3237    3.7 <123. <40.8           -0.58       C1000P40  716.83  580.90
  # 0.64        10.1   -72    0.6                        1.38

  private.readline['nvss'] := function(line, flux, spectrum, direction, refer) {

    line := split(line, ', ');
    if(length(line)<8) {
      return F;
    }

    # Initialize the component record
    rec := [=];
    # Skip errors line

    rec.spectrum := spectrum;

    # Flux
    rec.flux := flux;
    # Use the integrated value
    rec.flux.value := array(0.0, 4);
    if(length(line)>7) rec.flux.value[1] := as_float(line[8]);
    rec.flux.unit  := 'mJy';

    ra  := spaste(line[1],':',line[2],':',line[3]);
    dec := spaste(line[4],'d',line[5],'m',line[6]);
    direction := dm.direction(refer, ra, dec); 

    cdirection := dm.direction(refer, ra, dec); 
    if(!is_measure(cdirection)) {
      throw(paste('Direction invalid in :', line),
	    origin='ascii2complist');
      return F;
    }

    # Strip the <
    for (i in 1:length(line)) {
      line[i]~:=s/\<//;
    }

    # Find the shape. Not sure what to do here with the
    # limits. For the moment, enter as real value.
    hasshape := F;
    if(hasshape&&as_float(line[9])>0.0) {
      if(as_float(line[9])>as_float(line[10])) {
	bmaj := dq.quantity(as_float(line[9]), 'arcsec');
	bmin := dq.quantity(as_float(line[10]), 'arcsec');
	bpa  := dq.quantity(as_float(line[11]), 'deg');
      }
      else {
	bmaj := dq.quantity(as_float(line[10]), 'arcsec');
	bmin := dq.quantity(as_float(line[9]), 'arcsec');
	bpa  := dq.quantity(as_float(line[11])+90.0, 'deg');
      }  
      rec.shape := [type="Gaussian", direction=cdirection,
		    majoraxis=bmaj, minoraxis=bmin,
		    positionangle=bpa,
                    majoraxiserror=private.zeroaxiserror, minoraxiserror=private.zeroaxiserror, positionangleerror=private.zeropaerror];
    }
    else {
      rec.shape := [type="Point", direction=cdirection];
    }

    trunc := function(s) {
      s:=split(s,'.');
      return s[1];
    }
    rec.label := spaste('NVSS',line[1],line[2],trunc(line[3]),line[4],line[5],trunc(line[6]));

    rec.comment:=paste('NVSS: ', line);

    return rec;
  }

  ######################
  # Start of reading loop

  # Create the empty component list
  cl := emptycomponentlist();

  if (format == 'wenss') {
    ok := cl.fromwenss(asciifile, refer);
  } else if (format == 'nvss') {
    ok := cl.fromnvss(asciifile, refer);
  }
  else {
    # Open the input file
    f:=open(paste("< ", asciifile));
    
    # Read lines until we reach the end
    ncomp := 0;
    while (T) {
      line := read(f);
      if(strlen(line)==0) break;
      component := private.readline[format](line, flux, spectrum, direction,
                   	refer);
      if(is_record(component)&&length(component)) {
	if(cl.add(component, iknow=T)) {
	  ncomp+:=1;
	}
	else {
	  throw(paste('Could not add ', format, 'component:\n', component),
		origin='ascii2complist');
	}
      }
      if(ncomp%1000==0) note('Component ', ncomp, ' filled');
    }
    f:=F;

    # Write the output componentlist and close
    if(ncomp>0) {
      note(paste('Found ', ncomp, ' components'));
    } else {
      cl.done();
      return throw('Found no components', origin='ascii2complist');
    }
  }
  nc := cl.length();
  ok := cl.rename(complist);
  ok := cl.done();
  return nc;
}

const ascii2complisttest := function() {

  haserrors := F;

  writeasciifile := function(line, asciifile) {
    f:=open(paste('> ', asciifile));
    for (i in 1:length(line)) {
      write(f, line[i]);
    }
    f:=F;
  }

  #############
  # AIPS star
  note('Testing AIPS star file conversion');

  line := r_array();
  line[1] := "19 45 34.0  +27 23 00.0   20 20 0 0";
  line[2] := "19 45 34.0  +27 23 00.0 288 288 0 1";
  line[3] := "19 45 31.750 +27 21 38.06 20 20 0 0";
    
  asciifile := 'ascii2complisttest.stfile';
  clfile  := spaste(asciifile, '.cl');
  tabledelete(clfile);

  writeasciifile(line, asciifile);
  ncomp := ascii2complist(clfile, asciifile, refer='j2000', format='ST');
  if(ncomp!=length(line)) {
    throw ('Some star file component conversions failed');
    haserrors := T;
  }

  #############
  # Caltech
  note('Testing Caltech model file conversion');

  line := r_array();
  line[1] := "1.0 10 43 20 0.94 0 0";
  line[2] := "0.5 5 172 288 0.63 45 1";
  line[3] := "0.23 100 63.2";
    
  direction := 

  asciifile := 'ascii2complisttest.caltech';
  clfile  := spaste(asciifile, '.cl');
  tabledelete(clfile);

  writeasciifile(line, asciifile);
  ncomp := ascii2complist(clfile, asciifile, format='Caltech',
			  direction=dm.direction('b1950', '19:45:34.0',
						 '+27d23m00.0'));

  if(ncomp!=length(line)) {
    haserrors := T;
    throw ('Some caltech model format component conversions failed');
  }

  #############
  # WENSS
  note('Testing WENSS catalog file conversion');

  line := r_array();
  line[1] := '75    WNB0959.9+3959   9 59 55.75  39 59 02.7 S   18   13   0     0     0    2.9  WN40149H';
  line[2] := '597   WNB0959.4+4007   9 59 27.00  40 07 40.5 S   147  157  0     0     0    2.9  WN40149H';
  line[3]:='670   WNB0959.4+3950   9 59 28.91  39 50 32.5 S   55   51   0     0     0    2.9  WN40149H';
  line[4]:='1081  WNB1001.1+4012  10 01 09.89  40 12 02.2 S   30   24   0     0     0    2.9  WN40149H';
  line[5]:='1531  WNB0957.8+4003   9 57 48.18  40 03 41.2 S * 17   23   0     0     0    3.1  WN40149H';

  asciifile := 'ascii2complisttest.wenss';
  clfile  := spaste(asciifile, '.cl');
  tabledelete(clfile);

  writeasciifile(line, asciifile);
  ncomp := ascii2complist(clfile, asciifile, refer='b1950', format='wenss');

  if(ncomp!=length(line)) {
    throw ('Some WENSS model format component conversions failed');
    haserrors := T;
  }

  #############
  # FIRST
  note('Testing FIRST catalog file conversion');

  line := r_array();
  line[1] := 'NED DSS FIMG |     0.4  10 50  7.261  +30 40 37.10     0     6.32    18.10  0.147    10.54     4.54   31.7     11.84      7.05       31.7 10510+30456E';
  line[2] := 'NED DSS FIMG |     9.7  10 50  6.952  +30 40 46.36     0     2.94     8.77  0.147    13.90     2.17   80.0     14.91      5.82       80.0 10510+30456E';
  line[3] := 'NED DSS FIMG |    16.8  10 50  6.025  +30 40 42.57     0     3.56     7.46  0.147     9.08     2.10   46.1     10.57      5.79       46.1 10510+30456E';
  line[4] := 'NED DSS FIMG |    17.3  10 50  6.271  +30 40 25.98     0     6.79    26.24  0.147    10.37     7.97   57.3     11.69      9.63       57.3 10510+30456E';


  asciifile := 'ascii2complisttest.first';
  clfile  := spaste(asciifile, '.cl');
  tabledelete(clfile);

  writeasciifile(line, asciifile);
  ncomp := ascii2complist(clfile, asciifile, refer='j2000', format='first');

  if(ncomp!=length(line)) {
    throw ('Some FIRST model format component conversions failed');
    haserrors := T;
  }

  #############
  # NVSS
  note('Testing NVSS catalog file conversion');

  line := r_array();
  line[1] := '09 55 16.67 +39 35 48.4  3573   12.2  31.7 <25.4  19.2     -0.13       C1000P40  730.30  417.67';
  line[2] := '0.12         1.8  -114    1.0   5.3        10.6      0.62';
  line[3] := '09 55 19.35 +40 23 12.0  3504    3.5 <51.3 <39.6           -0.27       C1000P40  725.75  607.19';
  line[4] := '0.39         4.1   -66    0.5                        0.48';
  line[5] := '09 55 27.34 +39 35 35.6  3467    3.6 <85.5 <40.1           -0.05       C1000P40  722.09  416.70';
  line[6] := '0.48         6.8  -115    0.5                        0.84';
  line[7] := '09 55 31.43 +39 36 58.1  3389    9.9  33.8 <33.0  89.2     -0.09       C1000P40  718.87  422.16';
  line[8] := '0.20         1.8  -114    1.0   6.6        16.7      0.71';
  line[9] := '09 55 31.50 +40 16 39.4  3237    3.7 <123. <40.8           -0.58       C1000P40  716.83  580.90';
  line[10] := '0.64        10.1   -72    0.6                        1.38';

  asciifile := 'ascii2complisttest.nvss';
  clfile  := spaste(asciifile, '.cl');
  tabledelete(clfile);

  writeasciifile(line, asciifile);
  ncomp := ascii2complist(clfile, asciifile, refer='b1950', format='nvss');

  if(ncomp!=length(line)/2) {
    throw ('Some NVSS model format component conversions failed');
    haserrors := T;
  }

  return !haserrors;  
}
