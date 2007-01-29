# AOutils.g: Arecibo Observatory calibration utilities.
#------------------------------------------------------------------------------
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2 of the License, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#   more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Foundation, Inc.,
#   675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
#   Correspondence concerning AIPS++ should be addressed as follows:
#          Internet email: aips2-request@nrao.edu.
#          Postal address: AIPS++ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#
#------------------------------------------------------------------------------
#
#These files are designed for the import and calibration of
#data taken at Arecibo Observatory.
#
#A typical session for this may go something like:
#
#% aips++ -l naic_start.g
#- ao.import('U3564.sdfits')
#- aoname:='U3564_ms1'
#- ao.gaincorr()
#- ao.plot('average1')
#
#After the above commands, the calibrated data is shown in the dish pgplotter
#screen.
#
#------------------------------------------------------------------------------
#
# The following routines are included in this package.  Complete
# descriptions of the routines can be found in the README file in this
# directory.
#
# ao.avg(name=aoname,scan=0,weight="none")
# ao.base(basel, name=aoname, onscan=0, convert='T', temp=0, gain=0)
# ao.calmany(name=aoname,numpairs=1,pattern=4,onscan=0,calscan=0,tsys=0,gainval=0,
#                offscan=0, weight='none', convert='T')
# ao.calmany2(name=aoname,numpairs=1,pattern=4,onscan=0,calscan=0,tsys=0,gainval=0,
#                offscan=0, fitbase='F', weight='none',convert='T',order=2,range='F')
# ao.convertdate(day,month,year)
# ao.convertmjd(mjd)
# ao.converttime(tnow)
# ao.fixpnt(name=aoname)
# ao.gain(name=aoname,scan=0)
# ao.gaincorr(name=aoname,onscan=0,calscan=0,tsys=0,gainval=0,offscan=0,weight='none',convert='T')
# ao.gaincorr2(name=aoname,onscan=0,calscan=0,tsys=0,gainval=0,offscan=0,fitbase='F',weight='none',convert='T',order=2,range='F')
# ao.gainone(az,za,coef,zac)
# ao.gaintwo(az,za,coef,zac)
# ao.gainthree(az,za,coef,zac)
# ao.getcalval(rcvnum, freqin, calnum, day=-1, year=-1, pol=0, hyb=0)
# ao.getgainval(rcvnum, freqin, az=90, za=12, day=-1, year=-1, pol=0)
# ao.getscan(name=aoname)
# ao.import(sdfitsname)
# ao.numdumps(name=aoname,scan=0)
# ao.numscans(name=aoname,scan=0)
# ao.onoff(name=aoname,onscan=0,convert='T',temp=0,gain=0,offscan=0)
# ao.plot(name)
# ao.tsys(name=aoname,calscan=0)
#
#------------------------------------------------------------------------------
# CHANGES:
# 21 March, 2002: -Fixed bug which prevented ao.import from reading sdfits
#		   files which reside outside the current working directory.
#		  -Added baseline option to the gaincor2 and calmany2 routines
#		  -Removed baseline option from gaincor and calmany, since it 
#		   was silly.
#		  -Put derived tsys, tcal values into headers for
#		   gaincorr2, gaincorr
# 20 March, 2002: -Added in gaincor2 and calmany2 functions to allow for gain 
#		   correction using <on>-<off>/<off>
#------------------------------------------------------------------------------
#
#The Routines:
pragma include once;
#
#First, we need to make sure that there is a dish tool out there.
#For convenience, the tool will be named both "mydish" and "d".
  if (is_defined('d')) {
   if (is_const(d)) {
      print 'Cannot start AO utilities because you have a constant'
      print 'named \'d\' defined.  Remove it and try again.'
      exit
   }
   else {
      print 'You currently have a variable named \'d\', which must now be'
      print 'overwritten with the dish tool of the same name.'
   }
  }
  if (is_defined('mydish')) {
   if (is_const(mydish)) {
      print 'Cannot start AO utilities because you have a constant'
      print 'named \'mydish\' defined.  Remove it and try again.'
      exit
   }
   else {
      print 'You currently have a variable named \'mydish\', which must now be'
      print 'overwritten with the dish tool of the same name.'
   }
  }

#Make the dish tool
  dishflag := F
  include 'dish.g'
  include 'toolmanager.g';
  for (i in symbol_names())
     if (is_tool(eval(i)))
      if (tm.tooltype(i)=='dish' && i != '__dish__' && i != '_objpublic') {
         const d := ref eval(i)
         dishflag := T
         break
      }
  if (!dishflag) const d := dish();
  mydish := ref d;

include 'ms.g';
include 'statistics.g';

#Create AO tool.  This tool servesw two primary purposes - to 
#successfully import sdfits files made from AO data and to convert
#AO spectra line data into calibrated data.
#More functionality will be added in the future.

const AO := function() {
   private := [=];
   public  := [=];

# FIXPNT
# This routine corrects for the absence of a REF_FREQ, which enables viewing in msplot.
# It also adds a column entitled "NRAO_GBT_STATE_ID" which is required by the uni2.g 
# routines.  Note that this column (NRAO_GBT_STATE_ID) is simply a mirror of the DATA_DESC
# column.  This routine is called by the import command.
#
   public.fixpnt := function(msname=aoname) {
        ftab := table(spaste(msname, '/SPECTRAL_WINDOW'), readonly=F);
        nstab:= table(spaste(msname, '/NS_SDFITS'));
        f := ftab.getcol('REF_FREQUENCY');
        rf:= nstab.getcol('OBSFREQ');
        f:=array(rf[1], length(f));
        print ftab.putcol('REF_FREQUENCY',f);
        ftab.flush();
        ftab.done();
        nstab.done();
	ftab:=table(msname,readonly=F);
	newcol:=tablecreatescalarcoldesc('NRAO_GBT_STATE_ID',1);
	ok:=ftab.addcols(newcol);
	f:=ftab.getcol('DATA_DESC_ID');
	print ftab.putcol('NRAO_GBT_STATE_ID',f);
	ftab.flush();
        ftab.done();
        note(msname,' has been fixed for filler errors');
 }

# IMPORT        
# This routine loads in an sdfits file, converts to an AIPS++ Measurement
# Set, and corrects for the absence of a REF_FREQ (function
# fixpnt), which enables viewing in msplot.
#
   public.import := function(sdfitsname) {
	wider public;
	sdfname1:=split(sdfitsname,'/');
	tmp:=sdfname1[len(sdfname1)]
        sdfname:=split(tmp,'.');
        temp:=sdfitstoms(spaste(sdfname[1],'_ms'),sdfitsname);
        if (is_fail(temp)) return throw('SDFITS file not found')
        ok:=public.fixpnt(temp.name());
        d.open(spaste(sdfname[1],'_ms'));
	print 'Created file called: ',spaste(sdfname[1],'_ms');
	print 'Put file in results manager called',mydish.rm().getnames(mydish.rm().size());
        temp.done();
        return T;
  }

# CONVERTDATE
# This takes in a given day, month, and year, and determines
# the day number which the day & month correspond to.
#
   public.convertdate := function(day,month,year) {
	wider public;
	days:=array(0,12)
  	yearcheck:=(year/4) - (as_integer(year/4))
  	days[1]:=31
  	if (yearcheck == 0) {days[2]:=29}
  	else days[2]:=28
  	days[3]:=31
  	days[4]:=30
  	days[5]:=31
  	days[6]:=30
  	days[7]:=31
  	days[8]:=31
  	days[9]:=30
  	days[10]:=31
  	days[11]:=30
  	days[12]:=31
  	if (month ==1) retday:=day
  	else {
    	  retday:=0
    	  for (i in 1:(month-1)) {
             retday:=days[i] + retday
    	  }
   	  retday:=retday+day;
  	}
  	return retday;
  }

# CONVERTMJD
# This converts a given modified julian date to the appropriate
# dat, month, and year
#
   public.convertmjd := function(mjd) {
	wider public;
  	date:=array(0,3)
  	jd:=mjd + 2400000.5;
  	l:= jd + 68569
  	n:= as_integer (( 4 * l ) / 146097)
  	l:= l - as_integer (( 146097 * n + 3 ) / 4)
  	i:= as_integer(( 4000 * ( l + 1 ) ) / 1461001)
  	l:= l - as_integer(( 1461 * i ) / 4 )+ 31
  	j:= as_integer(( 80 * l ) / 2447)
  	d:= l - as_integer(( 2447 * j ) / 80)
  	l:= as_integer(j / 11)
  	m:= j + 2 - ( 12 * l )
  	y:= 100 * ( n - 49 ) + i + l
  	date[1]:=as_integer(d)
  	date[2]:=as_integer(m)
  	date[3]:=as_integer(y)
  	return date;
  }

# CONVERTTIME
# This program converts the value given by the time() command
# into useful numbers
#
   public.converttime := function(tnow) {
	wider public;
	days_left:=as_integer(tnow/86400)
	remain:=days_left
	year:=1970
	while (remain > 366 )
 	{
          year+:=1
          yearcheck:=(year/4) - (as_integer(year/4))
          no_days:=365
          if (yearcheck == 0) {no_days:=366}
          remain:=remain - no_days
 	}
 	if (remain==366) {
          yearcheck:=(year/4) - (as_integer(year/4))
          if (yearcheck != 0) {
            year+:=1
            remain-:=365
          }
  	}
 	date:=array(0,2)
 	date[1]:=remain+1
 	date[2]:=year
 	return date;
  }

# GETGAINVAL
# This function will read in the receiver number, frequencym azimuth, 
# zenith angle, date, and polarization, 
# and will output the value of the gain curve, obtained from tables.
# Azimuth and zenith angle are expected to be entered in degrees.
#
   public.getgainval := function(rcvnum, freqin, az=90, za=12, day=-1, year=-1, pol=0) {
	wider public;
# First, check that the receiver number makes sense
	if (rcvnum != 1 & rcvnum != 2 & rcvnum != 3 & rcvnum != 5 & 
            rcvnum != 6 & rcvnum != 7 & rcvnum != 9 & rcvnum != 12 &
	    rcvnum != 11)
        {
           print "Receiver Number makes no sense (rcvnum =",rcvnum,")"
           return gainval:=0
        }
# Now, make sure we have a file to read.
	aipspath:=split(environ.AIPSPATH)[1];
	temp:=spaste(aipspath,'/code/trial/apps/naic/AOgains/');
	if (is_fail(open(spaste('< ',temp,'gain.datR',rcvnum)))) {
           print "There is currently no gain info for this receiver. Returning value of 1"
           return gainval:=1;
        }
# Next, convert to current date if no date was entered
	if ((day == -1 ) | (year == -1) ) {date:=public.converttime(time())}
	if (day == -1 ) {day:=date[1]}
	if (year == -1) {year:=date[2]}
# Read in the coefficients for the gain curve 
        aipspath:=split(environ.AIPSPATH)[1];
        temp:=spaste(aipspath,'/code/trial/apps/naic/AOgains/');
	x := open(spaste('< ',temp,'gain.datR',rcvnum))
# Now, read through the file until you are at the correct date
	line := read(x);
	firstchar := sprintf("%.1s",line);
	parts := split(line)
	cday := as_integer(parts[2])
	parts2 := split(parts[1],"!")
	cyear := as_integer(parts2[1])
	while (sum(strlen(line)) > 0) 
        {
           if ((firstchar == '!') && ( (cyear < year) | ((cyear==year) & (cday <=day)))) break
           line := read(x)
           firstchar := sprintf("%.1s",line)
           parts := split(line)
           if (len(parts) >= 2) cday := as_integer(parts[2])
           else cday := 0
           parts2 := split(parts[1],"!")
           cyear := as_integer(parts2[1])
           }
# Now that correct date is chosen, load gain coefficients
	nlines := 0
	coef:=array(0,30,10)
	zac:=0
	line := read(x)
	firstchar := sprintf("%.1s",line)

	while( (sum(strlen(line)) > 0) & (firstchar != "#") & (firstchar != "!") & (firstchar != ";"))
	{
	   parts := split(line)
	   if ((as_string(parts[14]) == "I") | (as_string(parts[14]) == "A") |
   	   ((as_string(parts[14]) == "1") & pol ==1) | ((as_string(parts[14]) == 	   "0") & pol ==0)) {
        	nlines +:= 1
        	freq[nlines]:=as_float(parts[1])
		eqnt[nlines]:=as_integer(parts[2])
        	coef[nlines,1]:=as_float(parts[3])
        	coef[nlines,2]:=as_float(parts[4])
        	coef[nlines,3]:=as_float(parts[5])
        	coef[nlines,4]:=as_float(parts[6])
        	coef[nlines,5]:=as_float(parts[7])
        	coef[nlines,6]:=as_float(parts[8])
        	coef[nlines,7]:=as_float(parts[9])
        	coef[nlines,8]:=as_float(parts[10])
        	coef[nlines,9]:=as_float(parts[11])
        	coef[nlines,10]:=as_float(parts[12])
        	sigma[nlines]:=as_float(parts[13])
        	calA[nlines]:=as_float(parts[15])
        	calB[nlines]:=as_float(parts[16])
        	zac[nlines]:=as_float(parts[17])
           }
	line := read(x)
	firstchar := sprintf("%.1s",line)
	}
# Now, determine the gain correction
	if ((nlines == 1) | (freqin <= freq[1])) {
		if (eqnt[1]==1) gainval:=public.gainone(az,za,coef[1,],zac[1])
		if (eqnt[1]==2) gainval:=public.gaintwo(az,za,coef[1,],zac[1])
		if (eqnt[1]==3) gainval:=public.gainthree(az,za,coef[1,],zac[1])
	}
 	else if (freqin >= freq[nlines]) {
		if (eqnt[nlines]==1) gainval:=public.gainone(az,za,coef[nlines,],zac[nlines])
		if (eqnt[nlines]==2) gainval:=public.gaintwo(az,za,coef[nlines,],zac[nlines])
		if (eqnt[nlines]==3) gainval:=public.gainthree(az,za,coef[nlines,],zac[nlines])

        } 
	else {
           for (i in (1:nlines-1)) {
               if ((freqin > freq[i]) & (freqin <=freq[i+1])) {
		if (eqnt[i]==1) gainone:=public.gainone(az,za,coef[i,],zac[i])
		if (eqnt[i]==2) gainone:=public.gaintwo(az,za,coef[i,],zac[i])
		if (eqnt[i]==3) gainone:=public.gainthree(az,za,coef[i,],zac[i])
		if (eqnt[i+1]==1) gaintwo:=public.gainone(az,za,coef[i+1,],zac[i+1])
		if (eqnt[i+1]==2) gaintwo:=public.gaintwo(az,za,coef[i+1,],zac[i+1])
		if (eqnt[i+1]==3) gaintwo:=public.gainthree(az,za,coef[i+1,],zac[i+1])
               }
           }
        }
        return gainval
  }

# NUMDUMPS
# This determined the number of dumps (time records) in an AO scan
#
   public.numdumps := function(name=aoname,scan=0) {
	wider public;
#Choose the file of interest
        ok:=d.filein(name);
	size:=mydish.rm().size();
        names:=mydish.rm().getnames(1:size);
        test:=0
        for (i in 1:size) {
          if (names[i]==name) {
	   test:=1
	   break
          }
	}
	if (test==0) return throw('ERROR: Invalid ms file specified ')
        msname:=eval(d.files(T)[1]).name();
# Set scan number, if necesary
	if (scan==0) scan:=public.getscan(name);
#
        tab:=table(msname,readonly=F);
        if (is_fail(tab)) return throw('MS not found');
        ontab:=tab.query(spaste('SCAN_NUMBER == ',as_string(scan)));
        if (ontab.nrows() == 0) return throw('No Scans Found');
        ondata:=ontab.getcol('DATA_DESC_ID');
        numdumps:=length(ondata)
        numscans:=public.numscans(name,scan)
        tab.done();
        return  numdumps/numscans;
  }

#NUMSCANS
# This routine determines the number of (boards) X (polarizations)
# within a scan
#
   public.numscans := function(name=aoname,scan=0) {
	wider public;
#Choose the file of interest
        ok:=d.filein(name);
        size:=mydish.rm().size();
        names:=mydish.rm().getnames(1:size);
        test:=0
        for (i in 1:size) {
          if (names[i]==name) {
           test:=1
           break
          }
        }
        if (test==0) return throw('ERROR: Invalid ms file specified ')
        msname:=eval(d.files(T)[1]).name();
# Set scan number, if necesary
	if (scan==0) scan:=public.getscan(name);
#
        tab:=table(msname,readonly=F);
        if (is_fail(tab)) return throw('MS not found');
        ontab:=tab.query(spaste('SCAN_NUMBER == ',as_string(scan)));
        if (ontab.nrows() == 0) return throw('No Scans Found');
        ondata:=ontab.getcol('DATA_DESC_ID');
        numscans:=(max(ondata)-min(ondata))+1
        tab.done();
        return  numscans;
  }

# GETCALVAL
# This function will read in the receiver number, frequency, calvalue, date,
# and polarization and will output the value of the cal (noise diode).
#
   public.getcalval := function(rcvnum, freqin, calnum, day=-1, year=-1, pol=0, hyb=0){
	wider public;
# First, check that the receiver number makes sense
	if (rcvnum != 1 & rcvnum != 2 & rcvnum != 3 & rcvnum != 5 & 
           rcvnum != 6 & rcvnum != 7 & rcvnum != 9 & rcvnum != 12 &
	    rcvnum != 11)
        {
           print "Receiver Number makes no sense (rcvnum =",rcvnum,")"
           return tcal:=0
        }
# If the receiver is LBN, 610, or SBN, set the calnum to 0
	if (rcvnum == 6 | rcvnum == 3 | rcvnum == 12) calnum := 0
# If the receiver is 327 then calnum =1
	if (rcvnum == 1) calnum:=1
# Next, convert to current date if no date was entered
	if ((day == -1 ) | (year == -1) ) {date:=public.converttime(time())}
	if (day == -1 ) {day:=date[1]}
	if (year == -1) {year:=date[2]}
# Determine the correct cal value [assuming L-Narrow, current cals]
#
# First, read in the diode data (in K)
        aipspath:=split(environ.AIPSPATH)[1];
        temp:=spaste(aipspath,'/code/trial/apps/naic/AOgains/');
        x := open(spaste('< ',temp,'cal.datR',rcvnum))
# Now, read through the file until you are at the correct date
	line := read(x)
	firstchar := sprintf("%.1s",line)
	parts := split(line)
	cday := as_integer(parts[2])
	parts2 := split(parts[1],"!")
	cyear := as_integer(parts2[1])
	while (sum(strlen(line)) > 0) 
        {
          if ((firstchar == '!') && ( (cyear < year) | ((cyear==year) & 
		(cday <=day)))) break
          line := read(x)
          firstchar := sprintf("%.1s",line)
          parts := split(line)
          if (len(parts) >= 2) cday := as_integer(parts[2])
          else cday := 0
          parts2 := split(parts[1],"!")
          cyear := as_integer(parts2[1])
        }
# Now that correct date is chosen, load cal values
	nlines := 0
	calval := [=]
	calval.freq := []
	calval.val := []
	line := read(x)
	firstchar := sprintf("%.1s",line)
#
	while((sum(strlen(line)) > 0) & (firstchar != "#") & (firstchar != "!"))
	{
	  nlines +:= 1
	  parts := split(line)
	  calval.freq[nlines] := as_float(parts[1])
	  if ((pol == 0)&&(calnum ==0)) calval.val[nlines]:=as_float(parts[3])
	  else if ((pol==1)&&(calnum ==0)) calval.val[nlines]:=as_float(parts[5])
	  else if ((pol==0)&&(calnum ==1)) calval.val[nlines]:=as_float(parts[2])
	  else if ((pol==1)&&(calnum ==1)) calval.val[nlines]:=as_float(parts[4])
	  else if ((pol==0)&&(calnum ==2)) calval.val[nlines]:=as_float(parts[7])
	  else if ((pol==1)&&(calnum ==2)) calval.val[nlines]:=as_float(parts[5])
	  else if ((pol==0)&&(calnum ==3)) calval.val[nlines]:=as_float(parts[6])
	  else if ((pol==1)&&(calnum ==3)) calval.val[nlines]:=as_float(parts[4])
	  else if ((pol==0)&&(calnum ==4)) calval.val[nlines]:=as_float(parts[3])
	  else if ((pol==1)&&(calnum ==4)) calval.val[nlines]:=as_float(parts[9])
	  else if ((pol==0)&&(calnum ==5)) calval.val[nlines]:=as_float(parts[2])
	  else if ((pol==1)&&(calnum ==5)) calval.val[nlines]:=as_float(parts[8])
	  else if ((pol==0)&&(calnum ==6)) calval.val[nlines]:=as_float(parts[7])
	  else if ((pol==1)&&(calnum ==6)) calval.val[nlines]:=as_float(parts[9])
	  else if ((pol==0)&&(calnum ==7)) calval.val[nlines]:=as_float(parts[6])
	  else if ((pol==1)&&(calnum ==7)) calval.val[nlines]:=as_float(parts[8])
	  else if ((hyb==1)&&(calnum ==5)) {
		calval.val[nlines]:=(as_float(parts[2]) + as_float(parts[8]))/2.
		print "Using the hybrid for L-Wide."
		print "BE AWARE THAT CAL VALUES ARE LIKELY INCORRECT."
		}
	  else {
           print "Polarization, Cal Number or Hybrid value makes no sense (pol=",
		pol,"calnum=",calnum,"hybrid=",hyb,")"
           calval.val[nlines] := 0.
          }
	  line := read(x)
	  firstchar := sprintf("%.1s",line)
	  }
# Now, determine the correct value based off the frequencies
	i := 1
	while (i <= nlines) {
	   i +:= 1
	   if (freqin == calval.freq[i-1]) {
        	tcal:=calval.val[i-1]
        	break }
	   else if (freqin < calval.freq[1]) {
        	tcal := calval.val[1]
        	print "Frequency of observation ",freqin,
			" less than lowest freq. of measured cal value."
        	print "Used cal value for ",calval.freq[1]," MHz"
        	break }
	   else if (freqin > calval.freq[len(calval.freq)]) {
        	tcal := calval.val[len(calval.freq)]
        	print "Frequency of observation ",freqin,
			" higher than highest freq. of measured cal value."
        	print "Used cal value for ",calval.freq[len(calval.freq)]," MHz"
        	break }
	   else if ((freqin>=calval.freq[i-1])&&(freqin <= calval.freq[i])) {
             tcal:=(calval.freq[i-1]-freqin)/(calval.freq[i-1]-calval.freq[i])
             tcal:=tcal*(calval.val[i-1]-calval.val[i])
             tcal := calval.val[i-1] - tcal
             break
           }
	}
	return tcal
  }

# AVG
# This routine averages all the data with the same scan number
# of a given measurement set.  The user can set the weighting to
# none [default], rms, or tsys
#
   public.avg := function(name=aoname,scan=0,weight="none") {
	wider public;
#Tell logger where the program is.
   	ok:=dl.log('','NORMAL','Averaging the data');
#Choose the file of interest
        ok:=d.filein(name);
        size:=mydish.rm().size();
        names:=mydish.rm().getnames(1:size);
        test:=0
        for (i in 1:size) {
          if (names[i]==name) {
           test:=1
           break
          }
        }
        if (test==0) return throw('ERROR: Invalid ms file specified ')
        msname:=eval(d.files(T)[1]).name();
#If no scan given, use 1st scan
  	if (scan==0) scan:=public.getscan(name);
# Determine the (number of boards) x (number of polarizations)
  	sscans:=public.numscans(name,scan)
# Determine the number of dumps
  	dumps:=public.numdumps(name,scan)
# Average the appropriate scans
  	avscans:=array(0,dumps);
  	scan_no:=array(scan,1)
  	for (ii in 1:sscans) {
   	   avscans:=array(0,dumps);
   	   avscans[1]:=ii;
   	   for (i in 2:(dumps)) {
      	      avscans[i]:=avscans[i-1]+sscans
   	   };
   	   ok:=d.filein(name);
   	   result:=d.aver(scan,avscans,weighting=weight)
	   oname:=split(name,'_on')
	   d.rmadd(result,spaste(oname[1],'B',ii),spaste('Board ',ii,
		'; ',(length(avscans)),'averaged spectra'));
   	};
        size:=mydish.rm().size();
        print 'Created files in results manager: ',mydish.rm().getnames((size-sscans+1):size);
	names:=mydish.rm().getnames((size-sscans+1):size);
	return names ;
  }

# GAIN
# This routine determines the gain for a given record/scan
# by getting all relevent info (az, za, freq, pol, date) from
# the data header
#
   public.gain := function(name=aoname,scan=0){
	wider public;
# Tell logger where the program is.
   	ok:=dl.log('','NORMAL','Determining the gain','AOgain.g');
#Choose the file of interest
        ok:=d.filein(name);
        size:=mydish.rm().size();
        names:=mydish.rm().getnames(1:size);
        test:=0
        for (i in 1:size) {
          if (names[i]==name) {
           test:=1
           break
          }
        }
        if (test==0) return throw('ERROR: Invalid ms file specified ')
        msname:=eval(d.files(T)[1]).name();
# If no scan given, use 1st scan
  	if (scan==0) {
        scan:=public.getscan(name)
  	}
# Determine the (number of boards) x (number of polarizations)
  	sscan:=public.numscans(name,scan)
  	on := d.getscan(scan)
  	gain:=array(0,sscan,4)
# Get the on scan, determine header info, get gain:
	for (i in 1:sscan) {
	   on := d.getscan(scan, i);
	   arraylen := len(on.data.arr);
	   rcvnum:=on.other.ns_sdfits.RFNUM;
	   mjd:=on.header.time.m0.value;
	   date:=public.convertmjd(mjd);
	   retday:=public.convertdate(date[1],date[2],date[3]);
	   year:=date[3];
	   az:=(on.other.ns_sdfits.AZIMUTH)* pi / 180;
	   za :=on.other.ns_sdfits.ZEN_ANG;
	   gainv:=public.getgainval(rcvnum,
		on.data.desc.chan_freq.value[arraylen/2] / 1.0e06,
		az,za,retday,year,
		on.other.data_description.POLARIZATION_ID)
	   gain[i,1]:=as_integer(i)
	   gain[i,2]:=as_float(on.data.desc.chan_freq.value[arraylen/2]/1.0e06)
	   gain[i,3]:= as_integer(on.other.data_description.POLARIZATION_ID)
	   gain[i,4]:= as_float(gainv)
	}
	return gain;
  }

# GAINCORR
# This routine will read in data, do (on - off)/off
# for the individual scans, apply the gain curve to the
# individual scans, and then multiply the result by the
# tsys (obtained from the associated CAL observations.
# The output is then an array of calibrated data.
#
   public.gaincorr := function(name=aoname,onscan=0,calscan=0,tsys=0,gainval=0,offscan=0,weight='none',convert='T') {
	wider public;
#Choose the file of interest
        ok:=d.filein(name);
        size:=mydish.rm().size();
        names:=mydish.rm().getnames(1:size);
        test:=0
        for (i in 1:size) {
          if (names[i]==name) {
           test:=1
           break
          }
        }
        if (test==0) return throw('ERROR: Invalid ms file specified ')
        msname:=eval(d.files(T)[1]).name();
#If no scan given, use 1st scan
        if (onscan==0) onscan:=public.getscan(name)
# Determine the system temperature 
	if (convert != 'F') {
	if (tsys==0) {
    	   temp:=[=]
     	   if (calscan==0) calscan:=onscan+2
    	   temp:=public.tsys(name,calscan)
  	}
  	else temp:=tsys
	} else temp:=[=];
# Get the gain correction for each board/pol
# Should gain be calculated for each frequency???
	if ((convert != 'F') && (convert != 'Tsys') && (convert != 'tsys')) {
	 if (gainval==0) {
	  gain:=[=]
	  gain:=public.gain(name,onscan)
	 } else gain:=gainval
	} else gain:=[=];
#Get the (on-off)/off values, converted to K (if desired)
   	newdata:=[=]
   	if (offscan==0) offscan:=onscan+1
   	newdata:=public.onoff(name,onscan,convert,temp,gain,offscan)
	if ((convert == 'Tsys') | (convert == 'tsys')) {
		ok:=dl.log('','NORMAL','Calibrated the data & converted to Tsys','AOgaincorr.g');
	} else if (convert != 'F') {
   	  	ok:=dl.log('','NORMAL','Calibrated the data & converted to Jy','AOgaincorr.g');
	}
# Set up a working set for the (on-off)/off data
  	d.select(scans=onscan);
  	size:=d.rm().size();
  	ok:=d.rm().select(size);
  	oldname:=d.rm().getselectionnames();
  	parts:=split(msname,'_')
  	msname:=spaste(parts[1],'_ms');
  	ok:=d.filein(oldname)
	fn:=dos.dir();
	alen:=len(parts[1])
	ok:=any(fn==spaste(parts[1],"_on_off1"));
	if (ok) {
 	   mycount:=array(1,len(fn));
	   j:=0;
	   for (i in 1:len(fn)) {
	     newpart:=split(fn[i],'_')
	     if ((len(newpart)>=3)&&(newpart[1]==parts[1])&&(newpart[len(newpart)-1]=='on')){
	       newpart2:=split(newpart[len(newpart)],'');
	       if ((newpart2[1]=='o') && (newpart2[2]=='f') && (newpart2[3]=='f')) {
	        j+:=1;
	        mycount[j]:=as_integer(newpart2[4]);
	       }
	     }
	   }
	   vers:=max(mycount) +1;
	}
	else {vers:=1};
  	eval(spaste(oldname,".deepcopy('",parts[1],"_on_off",vers,"')"))
# Write the calibrated data into the new table
  	tab:=table(spaste(parts[1],"_on_off",vers),readonly=F)
  	if (is_fail(tab)) return throw('MS not found');
  	ontab:=tab.query(spaste('SCAN_NUMBER == ',as_string(onscan)));
  	print ontab.putcol('FLOAT_DATA',newdata);
  	ontab.flush();
  	ontab.done();
  	tab.done();
# Add in the temperature data to the ms
	caltab:=table(spaste(parts[1],"_on_off",vers,'/SYSCAL'),readonly=F);
	tsysvec:=caltab.getcol("TSYS");
	dumps:=public.numdumps(oldname,onscan)
        sscans:=public.numscans(oldname,onscan)
	a:=seq(1,dumps*sscans,sscans)
	ii:=1
	for (i in 1:sscans) {
	  tsysvec[a]:=temp[ii,5]
	  a+:=1
	  ii+:=1
	}
	ok:=caltab.putcol('TSYS',tsysvec);
	caltab.flush();
	caltab.done();
        caltab:=table(spaste(parts[1],"_on_off",vers,'/SYSCAL'),readonly=F);
	tsys:=caltab.getcol('TSYS')
        newcol:=tablecreatearraycoldesc('TCAL',as_float(0),1,1);
        ok:=caltab.addcols(newcol);
 	ok:=caltab.putcolkeyword('TCAL','QuantumUnits','K');
 	tcalvec:=tsys;
        a:=seq(1,dumps*sscans,sscans)
        ii:=1
        for (i in 1:sscans) {
           tcalvec[a]:=temp[ii,4]
           a+:=1
           ii+:=1
        }
        ok:=caltab.putcol('TCAL',tcalvec);
        caltab.flush();
        caltab.done();
	ok:=d.open(spaste(parts[1],"_on_off",vers))
  	ok:=dl.log('','NORMAL',(spaste('Wrote data to new table called ',
		parts[1],'_on_off',vers)),'AOgaincorr.g');
	tmp:=spaste(parts[1],'_on_off',vers)
	print 'Created measurement set : ',tmp
# Average the data (by board & pol) and send results to dish
  	size:=d.rm().size();
	print 'Created file in results manager : ',mydish.rm().getnames(size)
  	ok:=d.rm().select(size);
  	oldname:=d.rm().getselectionnames();
  	ok:=public.avg(oldname,onscan,weight)
#
	return T;
  }

# GAINCORR2
# This routine will read in data, average the on and off scans,
# do (on - off)/off, apply the gain curve, and then multiply 
# the result by the tsys (obtained from the associated CAL 
# observations.  The output is sent to the dish results
# manager as X records, where X is the number of boards x the
# number of polarizations of the scan.
#
   public.gaincorr2 := function(name=aoname,onscan=0,calscan=0,tsys=0,gainval=0,offscan=0,fitbase='F',weight='none',convert='T',order=2,range='F') {
	wider public;
#Choose the file of interest
        ok:=d.filein(name);
        size:=mydish.rm().size();
        names:=mydish.rm().getnames(1:size);
        test:=0
        for (i in 1:size) {
          if (names[i]==name) {
           test:=1
           break
          }
        }
        if (test==0) return throw('ERROR: Invalid ms file specified ')
        msname:=eval(d.files(T)[1]).name();
#If no scan given, use 1st scan
        if (onscan==0) onscan:=public.getscan(name)
        if (offscan==0) offscan:=onscan+1;
# Determine the system temperature 
	if (convert != 'F') {
	if (tsys==0) {
    	   temp:=[=]
     	   if (calscan==0) calscan:=onscan+2
    	   temp:=public.tsys(name,calscan)
  	}
  	else temp:=tsys
	} else temp:=[=];
# Get the gain correction for each board/pol
	if ((convert != 'F') && (convert != 'Tsys') && (convert != 'tsys')) {
	 if (gainval==0) {
	  gain:=[=]
	  gain:=public.gain(name,onscan)
	 } else gain:=gainval
	} else gain:=[=];
#Get the root name for the files
	oname:=split(name,'_');
#Average the on and the off scans
        ok:=dl.log('','NORMAL','Averaging ON scans','ao.gaincorr2');
	print "ON source files:"
        onnames:=public.avg(name=name,scan=onscan,weight="none");
	newnames:=onnames
	if ((fitbase  != 'T') && (fitbase != 't')) {
          ok:=dl.log('','NORMAL','Averaging OFF scans','ao.gaincorr2');
	  print "OFF source files:"
          offnames:=public.avg(name=name,scan=offscan,weight="none");
	}
#Get (ON-OFF)/OFF and gain.temp correct the data
        ok:=dl.log('','NORMAL','Gain/Temp correcting data','ao.gaincor2');
	for (i in 1:len(onnames)) {
	  d.rm().selectbyname(onnames[i])
	  on_new:=d.rm().getselectionvalues()
	  if ((fitbase =='T') | (fitbase == 't') | (fitbase == '1')) {
	    off_new:=d.base(on_new,order=order,range=range,action='show',autoplot=F)
	  } else {
	    d.rm().selectbyname(offnames[i])
	    off_new:=d.rm().getselectionvalues()
	  }
	    onoff:=on_new;
	    onoff.data.arr:=(on_new.data.arr - off_new.data.arr)/off_new.data.arr
#	    onoff:=d.scansrr(on_new,off_new) 
# Correct (on-off)/off by tsys. & gain if desired
          if ((convert == 'T') | (convert == 't') | (convert == '1')) {
            if (temp==0) {
                print 'No temperature entered'
                return newdata:=0
            }
            if (gain==0) {
                print 'No gain value entered'
                return newdata:=0
            }
#	    onoff1:=d.scanscale(onoff,temp[i,5]/gain[i,4])
	    onoff1:=onoff
	    onoff1.data.arr:=onoff.data.arr*temp[i,5]/gain[i,4]
	    onoff1.header.tsys:=temp[i,5]
	    onoff1.header.tcal:=temp[i,4]
          }
          else if ((convert=='Tsys') | (convert=='tsys')) {
            if (temp==0) {
                print 'No temperature entered'
                return newdata:=0
            }
#	    onoff1:=d.scanscale(onoff,temp[i,5])
	    onoff1:=onoff
	    onoff1.data.arr:=onoff.data.arr*temp[i,5]
	    onoff1.header.tsys:=temp[i,5]
	    onoff1.header.tcal:=temp[i,4]
          }
#
	  d.rmadd(onoff1,spaste(oname[1],'onoff_B',i),spaste('Board ',i,
                '; (ON-OFF)/OFF'));
	  newnames[i]:=spaste(oname[1],'onoff_B',i)
	}
	print "(ON - OFF)/OFF files (in results manager):"
	print newnames
	return T;
  }

# GETSCAN
# Return the first scan of the working sditerator
#
   public.getscan := function(name=aoname) {
	wider public;
	ok:=d.filein(name);
        return d.listscans()[1];
}

# ONOFF
# Determines (on - off)/off for each record within a scan,
# and converts that info into Jy (if desired).
#
   public.onoff := function(name=aoname,onscan=0,convert='T',temp=0,gain=0,offscan=0){
	wider public;
# Tell logger where the program is.
   	ok:=dl.log('','NORMAL','Determining (ON-OFF)/OFF','AOonoff.g');
# Set onscan & offscan number, if necesary
	if (onscan==0) onscan:=public.getscan(name);
        if (offscan==0) offscan:=onscan+1;
#Choose the file of interest
        ok:=d.filein(name);
        size:=mydish.rm().size();
        names:=mydish.rm().getnames(1:size);
        test:=0
        for (i in 1:size) {
          if (names[i]==name) {
           test:=1
           break
          }
        }
        if (test==0) return throw('ERROR: Invalid ms file specified ')
        msname:=eval(d.files(T)[1]).name();
#
        querystring1:=spaste('SELECT FROM ',msname,' WHERE SCAN_NUMBER == ',
                      as_string(onscan));
        querystring2:=spaste('SELECT FROM ',msname,' WHERE SCAN_NUMBER == ',
                      as_string(offscan));
#
        tab:=table(msname,readonly=F);
        if (is_fail(tab)) return throw('MS not found');
        ontab:=tab.query(spaste('SCAN_NUMBER == ',as_string(onscan)));
        if (ontab.nrows() == 0) return throw('No Scans Found');
        offtab:=tablecommand(querystring2);
#
        ondata:=ontab.getcol('FLOAT_DATA');
        offdata:=offtab.getcol('FLOAT_DATA');
	if (len(ondata) != len(offdata)) fail "ON and OFF data arrays of different length!"
# Determine the number of sub scans:
        sscans:=public.numscans(name,onscan)
# Get on-off/off for each row
        ondata:=(ondata-offdata)/offdata;
# Correct (on-off)/off by tsys. & gain if desired
        if ((convert == 'T') | (convert == 't') | (convert == '1')) {
          if (temp==0) {
                print 'No temperature entered'
                return newdata:=0
          }
          if (gain==0) {
                print 'No gain value entered'
                return newdata:=0
          }
          for (i in 1:ondata::shape[3]) {
                jj:=i%sscans;
                if (jj == 0) jj:=sscans
                ondata[,,i] := as_float(temp[jj,5]*ondata[,,i])/gain[jj,4];
          }
        }
	else if ((convert=='Tsys') | (convert=='tsys')) {
	  if (temp==0) {
                print 'No temperature entered'
                return newdata:=0
          }
	  for (i in 1:ondata::shape[3]) {
                jj:=i%sscans;
                if (jj == 0) jj:=sscans
                ondata[,,i] := as_float(temp[jj,5]*ondata[,,i])
	  }
	}
        tab.done();
        ontab.done();
        offtab.done();
	return ondata
  }

# TSYS
# Determines the system temperature from two cal (noise diode)
# scans.  Temperature is found by averaging across entire board.
#
   public.tsys := function(name=aoname,calscan=0) {
	wider public;
# Tell logger where the program is.
	ok:=dl.log('','NORMAL','Determining the system temperature','AOtsys.g');
#Choose the file of interest
        ok:=d.filein(name);
        size:=mydish.rm().size();
        names:=mydish.rm().getnames(1:size);
        test:=0
        for (i in 1:size) {
          if (names[i]==name) {
           test:=1
           break
          }
        }
        if (test==0) return throw('ERROR: Invalid ms file specified ')
        msname:=eval(d.files(T)[1]).name();
# If no scan given, use 1st scan
  	if (calscan==0) calscan:=public.getscan(name) + 2;
  	
# Determine the length of the on and off scans
  	on := d.getscan(calscan)
  	sscan:=public.numscans(name,calscan)
  	temperature:=array(0,sscan,6)
# Get the on and off scans
	for (i in 1:sscan) {
	   on := d.getscan(calscan, i);
	   off := d.getscan(calscan + 1, i);
	   tsys := on;
	   arraylen := len(on.data.arr)
	   offarray := len(off.data.arr)
	   if (arraylen != offarray) fail 'ON and OFF cal. data arrays of different length!'
# Get the tcal value
	   rcvnum:=on.other.ns_sdfits.RFNUM;
	   calnum:=on.other.ns_sdfits.CALNUM;
	   mjd:=on.header.time.m0.value
 	   date:=public.convertmjd(mjd)
	   retday:=public.convertdate(date[1],date[2],date[3])
	   year:=date[3]
# Check to see if a hybrid is in
	   hyb:=0;
	   if (has_field(on.other.ns_sdfits,'LBWHYB') | has_field(on.other.ns_sdfits,'UPDNHYB')) {hyb:=1};
	   tcal := public.getcalval(rcvnum, on.data.desc.chan_freq.value[arraylen/2]/1.0e06,
		calnum,retday,year, on.other.data_description.POLARIZATION_ID,hyb)
# Calculate the system temperature, doing some rfi exision in the process
	   tsys.data.arr:=(tcal/(on.data.arr - off.data.arr)) * (off.data.arr);
	   tsysdata:=tsys.data.arr
	   for (j in 1:6){
        	alen := len(tsysdata);
        	temp:= mean(tsysdata[as_integer(alen/5):as_integer(4*alen/5)]);
		stdres:=stddev(tsysdata[as_integer(alen/5):as_integer(4*alen/5)]);
        	mask:=((tsysdata < temp+3*stdres) & (tsysdata > temp-3*stdres))
        	new_tsysdata:=tsysdata[mask]
        	tsysdata:=[=]
        	tsysdata:=array(0,len(new_tsysdata))
        	tsysdata:=new_tsysdata
           }
	   alen := len(tsysdata);
	   temperature[i,1]:=as_integer(i)
	   temperature[i,2]:=as_float(on.data.desc.chan_freq.value[arraylen/2]/ 1.0e06)
	   temperature[i,3]:=as_integer(on.other.data_description.POLARIZATION_ID)
	   temperature[i,4]:= as_float(tcal)
	   temperature[i,5]:= as_float(mean(tsysdata[as_integer(alen/5):as_integer(4*alen/5)]));
	   temperature[i,6]:= as_float(stddev(tsysdata[as_integer(alen/5):as_integer(4*alen/5)]))
	   }
	return temperature;
  }

# GAINONE
# Obtains the gain for curves of type one
#
   public.gainone := function(az,za,coef,zac) {
        wider public;
	gainval:=0;
	gainval:= coef[1]+coef[2]*za+coef[5]*cos(az)+coef[6]*sin(az)+coef[7]*cos(2*az);
	gainval:= gainval+coef[8]*sin(2*az)+coef[9]*cos(3*az)+coef[10]*sin(3*az);
	if (za > zac) gainval +:= coef[3]*(za-zac)^2+coef[4]*(za-zac)^3;
   return gainval;
   }

# GAINTWO
# Obtains the gain for curves of type two
#
   public.gaintwo :=function(az, za, coef, zac) {
        wider public;
	gainval:=0
	gainval:= coef[1]+coef[5]*cos(az)+coef[6]*sin(az)+coef[7]*cos(2*az)
	gainval:= gainval+coef[8]*sin(2*az)+coef[9]*cos(3*az)+coef[10]*sin(3*az)
	if (za > zac) gainval +:= +coef[2]*(za-zac)+coef[3]*(za-zac)^2+coef[4]*(za-zac)^3
   return gainval;
   }

# GAINTHREE
# Obtains the gain for curves of type three
#
   public.gainthree :=function(az,za,coef,zac) {
        wider public;
	gainval:=0
	gainval:= coef[1]+coef[2]*(za-zac)+coef[3]*(za-zac)^2+coef[4]*(za-zac)^3+coef[5]*(za-zac)^4
   return gainval;
   }

# BASE
# This function will calcuate (ON-OFF)/OFF using an input baseline as the OFF.
# It can also convert the data into Tsys, or Jy if desired.
# This will be expanded in the near future to accomodate
# a much wider variety of baseline fitting options.
#
   public.base := function(basel, name=aoname, onscan=0, convert='T', temp=0, gain=0) {
        wider public;
# Tell logger where the program is.
        ok:=dl.log('','NORMAL','Determining (ON-OFF)/OFF','AObase.g');
# Make sure that the entered baseline is valid:
        size:=mydish.rm().size();
        names:=mydish.rm().getnames(1:size);
        tst:=0
        for (i in 1:size) {
          if (names[i]==basel) {
                tst:=1
                break
          }
        }
        if (tst==0) return throw('ERROR: Baseline not found');
# Make sure that entered name is valid
        size:=mydish.rm().size();
        names:=mydish.rm().getnames(1:size);
        test:=0
        for (i in 1:size) {
          if (names[i]==name) {
           test:=1
           break
          }
        }
        if (test==0) return throw('ERROR: Invalid ms file specified ')
        msname:=eval(d.files(T)[1]).name();
#If no scan given, use 1st scan
        if (onscan==0) onscan:=public.getscan(name)
#
        querystring1:=spaste('SELECT FROM ',msname,' WHERE SCAN_NUMBER == ',
                      as_string(onscan));
#
        tab:=table(msname,readonly='F');
        if (is_fail(tab)) return throw('MS not found');
        ontab:=tab.query(spaste('SCAN_NUMBER == ',as_string(onscan)));
        if (ontab.nrows() == 0) return throw('No Scans Found');
#
        ondata:=ontab.getcol('FLOAT_DATA');
# Determine the number of subscans
        sscans:=public.numscans(name,onscan)
# Get on-off/off for each row
       ok:=eval(spaste('basedata:=',basel,'.data.arr'))
       for (i in 1:ondata::shape[3]) {
           ondata[,,i]:=ondata[,,i]-basedata
        }
# Correct on-off/off by tsys. & gain if desired
        if ((convert == 'T') | (convert == 't') | (convert == '1')) {
          if (temp==0) {
                print 'No temperature entered'
                return newdata:=0
          }
          if (gain==0) {
                print 'No gain value entered'
                return newdata:=0
          }
          for (i in 1:ondata::shape[3]) {
                jj:=i%sscans;
                if (jj == 0) jj:=sscans
                ondata[,,i] := as_float(temp[jj,5]*ondata[,,i])/gain[jj,4];
          }
        } else if ((convert == 'Tsys') | (convert == 'tsys')) {
          if (temp==0) {
                print 'No temperature entered'
                return newdata:=0
          }
          for (i in 1:ondata::shape[3]) {
                jj:=i%sscans;
                if (jj == 0) jj:=sscans
                ondata[,,i] := as_float(temp[jj,5]*ondata[,,i]);
          }
         }
#
        ok:=tab.done();
        ok:=ontab.done();
    return ondata
    };
#
# CALMANY
# This routine lets the user calibrate a series of datasets,
# provided they are all contained within one measurement set.
#
   public.calmany :=function(name=aoname,numpairs=1,pattern=4,onscan=0,calscan=0,tsys=0,gainval=0,
		offscan=0, weight='none', convert='T'){
        wider public;
#Choose the file of interest
        ok:=d.filein(name);
        size:=mydish.rm().size();
        names:=mydish.rm().getnames(1:size);
        test:=0
        for (i in 1:size) {
          if (names[i]==name) {
           test:=1
           break
          }
        }
        if (test==0) return throw('ERROR: Invalid ms file specified ')
        msname:=eval(d.files(T)[1]).name();
# If no scan given, use 1st scan
        if (onscan==0)  onscan:=public.getscan(name);
# Go through patno iterations of the gaincorr routine
	for (patno in 1:numpairs) {
		public.gaincorr(name,onscan,calscan,tsys,gainval,offscan, weight, convert)
		onscan+:=pattern
	}
   return;
   };

#
# CALMANY2
# This routine lets the user calibrate a series of datasets,
# provided they are all contained within one measurement set.
# This routine uses gaincorr2 
   public.calmany2 :=function(name=aoname,numpairs=1,pattern=4,onscan=0,calscan=0,tsys=0,gainval=0,
		offscan=0, fitbase='F', weight='none',convert='T',order=2,range='F'){
        wider public;
#Choose the file of interest
        ok:=d.filein(name);
        size:=mydish.rm().size();
        names:=mydish.rm().getnames(1:size);
        test:=0
        for (i in 1:size) {
          if (names[i]==name) {
           test:=1
           break
          }
        }
        if (test==0) return throw('ERROR: Invalid ms file specified ')
        msname:=eval(d.files(T)[1]).name();
# If no scan given, use 1st scan
        if (onscan==0)  onscan:=public.getscan(name);
# Go through patno iterations of the gaincorr routine
	for (patno in 1:numpairs) {
		public.gaincorr2(name,onscan,calscan,tsys,gainval,offscan, fitbase, weight, convert,order,range)
		onscan+:=pattern
	}
   return;
   };

#PLOT
# This routine just calls the d.plotscan() routine.
#
public.plot := function(name) {
   d.plotscan(eval(name));
   return; 
   };

#
   return public;
}; #end of AO tool constructor;

const ao:=AO();

ok:=dl.note('DISH tool is --> d');
ok:=dl.note('AO   tool is --> ao');
