# rtools3.g: Glish functions to assist in plotting GBT M/C log files
# Copyright (C) 1999
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
# $Id: rtools4.g,v 19.0 2003/07/16 03:42:28 aips2adm Exp $

#include guard
pragma include once;

#Currently supports only the GBT receivers at the 140,
#Weather1, Rtpm140, RtpmOvlbi, and OnePpsStatus.

helpLogs := function()
{
  print '';
  print '----------------GBT M/C Logs Plotting Functions-------------';
  print '';
  print 'These functions are made available by  include \"rtools3.g\"';
  print '';
  print 'NOTE:  GLISH is case sensitive!  Also, you must include the';
  print '       open and close parenthesis () when calling the';
  print '       functions below.';
  print '       See related help functions \'helpPlot()\' and \'helpTable()\'';
  print '';
  print 'findData()';
  print '  Provides access to the data table opened by gbtlogview.';
  print '  The data is copied into a variable named rtbl.';
  print '  The following vectors are defined from columns of the table:';
  print '    rnames - Each element is the name of one column of rtbl.';
  print '    rtime  - The \'Time\' column from rtbl.';
  print '  Then rtbl is checked for columns RC08_10_DMJD, RC12_18_DMJD,';
  print '  RC18_26_DMJD, Weather1_DMJD, Rtpm140_DMJD, RtpmOlvbi_DMJD,';
  print '  and OnePpsStatus_DMJD.  If any of these are found,';
  print '  then vectors rXtime, rKutime, rKtime, rWT1time,';
  print '  rRtpm140time, rRtpmOvlbitime, and rOnePpsStatustime are set';
  print '  equal to the respective DMJD column.';
  print '  Call findData() after each new fill by gbtlogview.';
  print '  Note:  The call to findData() should follow clicking the Fill';
  print '         button on the GBT Log Data control screen.';
  print '';
  print 'The functions will work only after findData() is run.';
  print 'The following return the dataset number of the vector or';
  print 'vectors plotted.';
  print 'Each data vector is plotted wrt its associated DMJD vector.';
  print '';
  print 'plotXtemps()';
  print '  Clears the plot screen using clear() and plots the X-band rx';
  print '  15K on the Y1 axis and 50K on the Y2 axis.';
  print 'plotKutemps()';
  print '  Similar to plotXtemps(), but for the Ku-band rx.';
  print 'plotKtemps()';
  print '  Similar to plotXtemps(), but for the K-band rx.';
  print '';
  print 'None of the following clear the screen first.';
  print 'If flg is omitted or is Y1, the data is plotted on the Y1 axis;';
  print 'if Y2, the data is plotted on the Y2 axis.';
  print ' (y1 or y2 works too).';
  print 'Currently, you must plot something to the Y1 axis before.';
  print 'using the Y2 axis.';
  print '';
  print 'plotXdewvac(flg)';
  print '  Plots the X-band Dewar Vacuum reading.';
  print 'plotKudewvac(flg)';
  print '  Plots the Ku-band Dewar Vacuum reading.';
  print 'plotKdewvac(flg)';
  print '  Plots the K-band Dewar Vacuum reading.';
  print 'plotXpumpvac(flg)';
  print '  Plots the X-band Pump Vacuum reading.';
  print 'plotKupumpvac(flg)';
  print '  Plots the Ku-band Pump Vacuum reading';
  print 'plotKpumpvac(flg)';
  print '  Plots the K-band Pump Vacuum reading';
  print 'plotX15K(flg)';
  print '  Plots just the X-band 15K temperature';
  print 'plotX50K(flg)';
  print '  Plots just the X-band 50K temperature.';
  print 'plotXamb(flg)';
  print '  Plots the X-band Ambient Temperature reading';
  print 'plotKu15K(flg)';
  print '  Plots just the Ku-band 15K temperature.';
  print 'plotKu50K(flg)';
  print '  Plots just the Ku-band 50K temperature.';
  print 'plotKuamb(flg)';
  print '  Plots the Ku-band Ambient Temperature reading';
  print 'plotK15K(flg)';
  print '  Plots just the K-band 15K temperature.';
  print 'plotK50K(flg)';
  print '  Plots just the K-band 50K temperature.';
  print 'plotKamb(flg)';
  print '  Plots the K-band Ambient Temperature reading.';
  print '';
  print 'plotTemp(flg,scale)';
  print '  Plots the Air Temperature from WT1.';
  print '  If scale == \'F\' or \'f\', plot is in Farenheit,';
  print '    if scale is anything else or is omitted, in Celsius.';
  print 'plotDewpt(flg,scale)';
  print '  Plots the Dew Point from WT1.';
  print '  If scale == \'F\' or \'f\', plot is in Farenheit,';
  print '    if scale is anything else or is omitted, in Celsius.';
  print 'plotRH(flg)';
  print '  Plots the relative humidity calculated from temperature,';
  print '  dew point, and pressure.';
  print 'plotPressure(flg,scale)';
  print '  Plots the pressure data from WT1.';
  print '  If scale == \'mmHg\' or \'mmhg\', plot is in mmHg,';
  print '  If scale == \'inHg\' or \'inhg\', plot is in inches Hg,';
  print '    if scale is anything else or is omitted, in mbar.';
  print 'plotWindvel(flg,scale)';
  print '  Plots the wind velocity from WT1.';
  print '  If scale == \'MPH\' or \'mph\', plot is in miles/hour,';
  print '    if scale is anything else or is omitted, in meters/sec.';
  print 'plotWinddir(flg)';
  print '  Plots the wind direction from WT1 in degrees.';
  print '\n\n';
  print 'plotPpsRackTemp(flg,scale)';
  print '  Plots the Rack Temperature from OnePpsStatus.';
  print '  If scale == \'F\' or \'f\', plot is in Farenheit,';
  print '    if scale is anything else or is omitted, in Celsius.';
  print 'plotPpsRoomTemp(flg,scale)';
  print '  Plots the Room Temperature from OnePpsStatus.';
  print '  If scale == \'F\' or \'f\', plot is in Farenheit,';
  print '    if scale is anything else or is omitted, in Celsius.';
  print 'plotRtpm140Delay(flg)';
  print '  Plots the Delay column from Rtpm140.';
  print 'plotRtpmOvlbiDelay(flg)';
  print '  Plots the Delay column from RtpmOvlbi.';
  print '\n\n';
}

#Function definitions:

findData := function()
{
global app,rtbl,rnames,rXtime,rXloaded,rKutime,rKuloaded;
global rKtime,rKloaded,Y1,y1,Y2,y2,rstart_label;
global rWT1time,rWT1loaded,MPH;
global rRtpm140time,rRtpm140loaded,rRtpmOvlbitime,rRtpmOvlbiloaded;
global rOnePpsStatustime,rOnePpsStatusloaded;

#Conveniences
Y1 := F
y1 := F
Y2 := T
y2 := T
mph := 'MPH'
f := 'F'

#Configure plot1d
#junk := setLegendGeometry("horizontal")


#Get table filled by newlogview GUI
rtbl := app.table
rnames := rtbl.colnames()
inttime := rtbl.getcol("Time")
rtime:=(inttime-as_integer(inttime[1]))*86400.

#Check for X-band data
if (len(rnames[rnames == 'RC08_10_DMJD'])!=0)
  {
    rXloaded := T
    intrxtime:= rtbl.getcol("RC08_10_DMJD")
    rXtime := (intrxtime-as_integer(intrxtime[1]))*86400.
    print" X-band data found"
  }
  else
    rXloaded := F;


#Check for Ku-band data
if (len(rnames[rnames == 'RC12_18_DMJD'])!=0)
  {
    rKuloaded := T
    intrkutime:= rtbl.getcol("RC012_18_DMJD")
    rKutime := (intrkutime-as_integer(intrkutime[1]))*86400.
    print" Ku-band data found"
  }
  else
    rKuloaded := F;

#Check for K-band data
if (len(rnames[rnames == 'RC18_26_DMJD'])!=0)
  {
    rKloaded := T
    intrktime:=rtbl.getcol("RC18_26_DMJD")
    rKtime := (intrktime-as_integer(intrktime[1]))*86400.
    print" K-band data found"
  }
  else
    rKloaded := F;

#Check for Weather1 data
if (len(rnames[rnames == 'Weather1_DMJD'])!=0)
  {
    rWT1loaded := T
    intrwtime:=rtbl.getcol("Weather1_DMJD")
    rWT1time:=(intrwtime-as_integer(intrwtime[1]))*86400.
    print" Weather1 data found"
  }
  else
    rWT1loaded := F;

#Check for RTPM140 data
if (len(rnames[rnames == 'Rtpm140_DMJD'])!=0)
  {
    rRtpm140loaded := T
    intrtpmtime:=rtbl.getcol("Rtpm140_DMJD")
    rRtpm140time :=(intrtpmtime-as_integer(intrtpmtime[1]))*86400.
    print" Rtpm140 data found"
  }
  else
    rRtpm140loaded := F;

#Check for RTPMOvlbi data
if (len(rnames[rnames == 'RtpmOvlbi_DMJD'])!=0)
  {
    rRtpmOvlbiloaded := T
    intrtpmOtime:=rtbl.getcol("RtpmOvlbi_DMJD")
    rRtpmOvlbitime :=(intrtpmOtime-as_integer(intrtpmOtime[1]))*86400.
    print" RtpmOvlbi data found"
  }
  else
    rRtpmOvlbiloaded := F;

#Check for OnePpsStatus data
if (len(rnames[rnames == 'OnePpsStatus_DMJD'])!=0)
  {
    rOnePpsStatusloaded := T
    intrOtime:=rtbl.getcol("OnePpsStatus_DMJD")
    rOnePpsStatustime :=(intrOtime-as_integer(intrOtime[1]))*86400.
    print" OnePpsStatus data found"
  }
  else
    rOnePpsStatusloaded := F;

rstart_label := ["File Starts: ",toDate(rtime[1])]

if (!(rXloaded|rKuloaded|rKloaded|rWT1loaded|rRtpm140loaded|\
      rRtpmOvlbiloaded|rOnePpsStatusloaded)) 
  print" Sorry, no data found";
}



#Function converts temps from C to F
tempToF := function (tC)
{
return (1.8 * tC + 32.0)
}

#Function calculates liquid water saturated pressure at given temp & pressure
#Ref:  Parker draft memo
satH2Opress := function(t_,p_)
{
return 6.1121*(1.0007+p_*3.46e-6)*exp(t_*17.502/(240.97+t_))
}

#Function converts velocity from meters/sec to miles/hour
velToMPH := function(vel)
{
return (2.236936 * vel)
}

#Function converts pressures from mbar to mm mercury
mbarTommHg := function (p)
{
return (p/1.3284)
}

#Function converts pressures from mbar to inches mercury
mbarToinHg := function (p)
{
return (p/(25.4*1.3284))
}


#Weather Functions
plotTemp  := function(Y2flg=F,scale='C')
{
if(rWT1loaded)
 {
  t  := rtbl.getcol("Weather1_AMB_TEMP")
  if ((scale == 'F') | (scale == 'f')) t := tempToF(t);
  if(Y2flg) dset := timeY2(rWT1time,t,["Air Temp",scale])
    else dset := timeY(rWT1time,t,["Air Temp",scale]);
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, Weather1 data not found in table";
}

plotDewpt  := function(Y2flg=F,scale='C')
{
if(rWT1loaded)
 {
  t  := rtbl.getcol("Weather1_DEWP")
  if (scale == 'F' | scale == 'f') t := tempToF(t);
  if(Y2flg) dset := timeY2(rWT1time,t,["Dew Pt",scale])
    else dset := timeY(rWT1time,t,["Dew Pt",scale]);
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, Weather1 data not found in table";
}

plotRH  := function(Y2flg=F)
{
if(rWT1loaded)
 {
  t  := rtbl.getcol("Weather1_AMB_TEMP")
  dp  := rtbl.getcol("Weather1_DEWP")
  pressure := rtbl.getcol("Weather1_PRESSURE")
  rh := 100.0 * satH2Opress(dp,pressure)/satH2Opress(t,pressure)
  if(Y2flg) dset := timeY2(rWT1time,rh,"RH %")
    else dset := timeY(rWT1time,rh,"RH %");
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, Weather1 data not found in table";
}

plotPressure  := function(Y2flg=F,scale='mbar')
{
if(rWT1loaded)
 {
  t  := rtbl.getcol("Weather1_PRESSURE")
  if (scale == 'mmHg' | scale == 'mmhg') t := mbarTommHg(t)
    else if (scale == 'inHg' | scale == 'inhg') t := mbarToinHg(t);
  if(Y2flg) dset := timeY2(rWT1time,t,["Pressure",scale])
    else dset := timeY(rWT1time,t,["Pressure",scale]);
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, Weather1 data not found in table";
}

plotWindvel  := function(Y2flg=F,scale='m/s')
{
if(rWT1loaded)
 {
  t  := rtbl.getcol("Weather1_WINDVEL")
  if (scale == 'MPH' | scale == 'mph') t := velToMPH(t);
  if(Y2flg) dset := timeY2(rWT1time,t,["Wind Vel",scale])
    else dset := timeY(rWT1time,t,["WindVel",scale]);
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, Weather1 data not found in table";
}

plotWinddir  := function(Y2flg=F)
{
if(rWT1loaded)
 {
  t  := rtbl.getcol("Weather1_WINDDIR")
  if(Y2flg) dset := timeY2(rWT1time,t,"Wind Dir")
    else dset := timeY(rWT1time,t,"Wind Dir");
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, Weather1 data not found in table";
}


#RTPM and OnePpsStatus Functions
plotPpsRackTemp  := function(Y2flg=F,scale='C')
{
if(rOnePpsStatusloaded)
 {
  t  := rtbl.getcol("OnePpsStatus_RACKTEMPERATURE")
  if ((scale == 'F') | (scale == 'f')) t := tempToF(t);
  if(Y2flg) dset := timeY2(rOnePpsStatustime,t,["Timing Center Rack Temp",scale])
    else dset := timeY(rOnePpsStatustime,t,["Timing Center Rack Temp",scale]);
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, OnePpsStatus data not found in table";
}

plotPpsRoomTemp  := function(Y2flg=F,scale='C')
{
if(rOnePpsStatusloaded)
 {
  t  := rtbl.getcol("OnePpsStatus_ROOMTEMPERATURE")
  if ((scale == 'F') | (scale == 'f')) t := tempToF(t);
  if(Y2flg) dset := timeY2(rOnePpsStatustime,t,["ICB Basement Temp",scale])
    else dset := timeY(rOnePpsStatustime,t,["ICB Basement Temp",scale]);
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, OnePpsStatus data not found in table";
}

plotRtpm140Delay  := function(Y2flg=F)
{
if(rRtpm140loaded)
 {
  t  := rtbl.getcol("Rtpm140_DELAY")
  if(Y2flg) dset := timeY2(rRtpm140time,t,["Rtpm140 Delay, ps"])
    else dset := timeY(rRtpm140time,t,["Rtpm140 Delay, ps"]);
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, Rtpm140 data not found in table";
}

plotRtpmOvlbiDelay  := function(Y2flg=F)
{
if(rRtpmOvlbiloaded)
 {
  t  := rtbl.getcol("RtpmOvlbi_DELAY")
  if(Y2flg) dset := timeY2(rRtpmOvlbitime,t,["RtpmOvlbi Delay, ps"])
    else dset := timeY(rRtpmOvlbitime,t,["RtpmOvlbi Delay, ps"]);
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, RtpmOvlbi data not found in table";
}



#X-band Functions
plotX15K := function(Y2flg=F)
{
if(rXloaded)
 {
  x15K := rtbl.getcol("RC08_10_PLATE15K")
  if(Y2flg) dset := timeY2(rXtime,x15K,"X 15K")
    else dset := timeY(rXtime,x15K,"X 15K");
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, X-band data not found in table"
}

plotX50K := function(Y2flg=F)
{
if(rXloaded)
 {
  x50K := rtbl.getcol("RC08_10_PLATE50K")
  if(Y2flg) dset := timeY2(rXtime,x50K,"X 50K")
   else dset := timeY(rXtime,x50K,"X 50K");
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, X-band data not found in table"
}

plotXamb := function(Y2flg=F)
{
if(rXloaded)
 {
  xamb := rtbl.getcol("RC08_10_AMBIENT")
  if(Y2flg) dset := timeY2(rXtime,xamb,"X Ambient Temp")
   else dset := timeY(rXtime,xamb,"X Ambient Temp");
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, X-band data not found in table"
}

plotXtemps := function(Y2flg=F)
{
if(rXloaded)
 {
  scratch := clear()
  dset[1] := timeY(rXtime,rtbl.getcol("RC08_10_PLATE15K"),"X 15K")
  dset[2] := timeY2(rXtime,rtbl.getcol("RC08_10_PLATE50K"),"X 50K")
  scratch := setYAxisLabel('X-band Cryo Temps')
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, X-band data not found in table"
}

plotXdewvac := function(Y2flg=F)
{
if(rXloaded)
 {
  xdewvac := rtbl.getcol("RC08_10_DEWARVAC")
  if(Y2flg) dset := timeY2(rXtime,xdewvac,"X Dewar Vac")
   else dset := timeY(rXtime,xdewvac,"X Dewar Vac");
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, X-band data not found in table"
}

plotXpumpvac := function(Y2flg=F)
{
if(rXloaded)
 {
  xpumpvac := rtbl.getcol("RC08_10_PUMPVAC")
  if(Y2flg) dset := timeY2(rXtime,xpumpvac,"X Pump Vac")
   else dset := timeY(rXtime,xpumpvac,"X Pump Vac");
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, X-band data not found in table"
}

#Ku-band Functions
plotKu15K := function(Y2flg=F)
{
global Ku15K

if(rKuloaded)
 {
  Ku15K := rtbl.getcol("RC12_18_PLATE15K")
  if(Y2flg) dset := timeY2(rKutime,Ku15K,"Ku 15K")
    else dset := timeY(rKutime,Ku15K,"Ku 15K");
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, Ku-band data not found in table"
}

plotKu50K := function(Y2flg=F)
{
if(rKuloaded)
 {
  Ku50K := rtbl.getcol("RC12_18_PLATE50K")
  if(Y2flg) dset := timeY2(rKutime,Ku50K,"Ku 50K")
   else dset := timeY(rKutime,Ku50K,"Ku 50K");
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, Ku-band data not found in table"
}

plotKuamb := function(Y2flg=F)
{
if(rKuloaded)
 {
  Kuamb := rtbl.getcol("RC12_18_AMBIENT")
  if(Y2flg) dset := timeY2(rKutime,Kuamb,"Ku Ambient Temp")
   else dset := timeY(rKutime,Kuamb,"Ku Ambient Temp");
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, Ku-band data not found in table"
}

plotKutemps := function(Y2flg=F)
{
if(rKuloaded)
 {
  scratch := clear()
  dset[1] := timeY(rKutime,rtbl.getcol("RC12_18_PLATE15K"),"Ku 15K")
  dset[2] := timeY2flg(rKutime,rtbl.getcol("RC12_18_PLATE50K"),"Ku 50K")
  scratch := setYAxisLabel('Ku-band Cryo Temps')
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, Ku-band data not found in table"
}

plotKudewvac := function(Y2flg=F)
{
if(rKuloaded)
 {
  Kudewvac := rtbl.getcol("RC12_18_DEWARVAC")
  if(Y2flg) dset := timeY2(rKutime,Kudewvac,"Ku Dewar Vac")
   else dset := timeY(rKutime,Kudewvac,"Ku Dewar Vac");
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, Ku-band data not found in table"
}

plotKupumpvac := function(Y2flg=F)
{
if(rKuloaded)
 {
  Kupumpvac := rtbl.getcol("RC12_18_PUMPVAC")
  if(Y2flg) dset := timeY2(rKutime,Kupumpvac,"Ku Pump Vac")
   else dset := timeY(rKutime,Kupumpvac,"Ku Pump Vac");
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, Ku-band data not found in table"
}

#K-band Functions
plotK15K := function(Y2flg=F)
{
if(rKloaded)
 {
  K15K := rtbl.getcol("RC18_26_PLATE15K")
  if(Y2flg) dset := timeY2(rKtime,K15K,"K 15K")
    else dset := timeY(rKtime,K15K,"K 15K");
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, K-band data not found in table"
}

plotK50K := function(Y2flg=F)
{
if(rKloaded)
 {
  K50K := rtbl.getcol("RC18_26_PLATE50K")
  if(Y2flg) dset := timeY2(rKtime,K50K,"K 50K")
   else dset := timeY(rKtime,K50K,"K 50K");
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, K-band data not found in table"
}

plotKamb := function(Y2flg=F)
{
if(rKloaded)
 {
  Kamb := rtbl.getcol("RC18_26_AMBIENT")
  if(Y2flg) dset := timeY2(rKtime,Kamb,"K Ambient Temp")
   else dset := timeY(rKtime,Kamb,"K Ambient Temp");
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, K-band data not found in table"
}

plotKtemps := function(Y2flg=F)
{
if(rKloaded)
 {
  scratch := clear()
  dset[1] := timeY(rKtime,rtbl.getcol("RC18_26_PLATE15K"),"K 15K")
  dset[2] := timeY2(rKtime,rtbl.getcol("RC18_26_PLATE50K"),"K 50K")
  scratch := setYAxisLabel('K-band Cryo Temps')
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, K-band data not found in table"
}

plotKdewvac := function(Y2flg=F)
{
if(rKloaded)
 {
  Kdewvac := rtbl.getcol("RC18_26_DEWARVAC")
  if(Y2flg) dset := timeY2(rKtime,Kdewvac,"K Dewar Vac")
   else dset := timeY(rKtime,Kdewvac,"K Dewar Vac");
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, K-band data not found in table"
}

plotKpumpvac := function(Y2flg=F)
{
if(rKloaded)
 {
  Kpumpvac := rtbl.getcol("RC18_26_PUMPVAC")
  if(Y2flg) dset := timeY2(rKtime,Kpumpvac,"K Pump Vac")
   else dset := timeY(rKtime,Kpumpvac,"K Pump Vac");
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, K-band data not found in table"
}



#Glish functions to help check the periodicity of data time stamps.

helpTicks := function()
{
  print '';
  print '----------------GBT M/C Log Ticks Functions-------------';
  print '';
  print 'These functions are made available by  include \"rtools2.g\"';
  print '';
  print 'NOTE:  GLISH is case sensitive!  Also, you must include the';
  print '       open and close parenthesis () when calling the';
  print '       functions below.';
  print '       See related help function \'helpLogs()\'';
  print '';
  print 'These functions will work only after findData() is run.';
  print '(see helpLogs()).'
  print '';
  print 'tryTicks(N,label,flg)';
  print '  This function searches the table, filled by newlogview,'
  print '  for the first column whose name ends in DMJD.'
  print '  It takes this column, subtracts the whole day number of'
  print '  the first point from each point, and multiplies by'
  print '  86400 to convert the units to seconds.  It then subtracts'
  print '  the whole seconds of the first point from each point.'
  print '  Finally, the value of (i-1)*N is subtracted from each'
  print '  data point, where i is the index to the data points.'
  print '  The resulting data is then plotted versus the data indices.'
  print '  If the DMJD column is perfectly sampled at N second'
  print '  intervals, one should see a constant offset from zero'
  print '  for all samples.'
  print '  N is the expected sampling interval in seconds;'
  print '    defaults to 1.  N need not be an integer.'
  print '  label is an ID string for the plot; defaults to: \'Ticks\''
  print '  flg, when T, causes the data vector to be printed'
  print '    at each step; defaults to F.'
  print '  tryTicks returns the plotted data vector.'
  print ''
  print '  Note:  There are other functions called by tryTicks'
  print '         which could be used directly.  See rtools2.g'
  print '\n'
}

toTicks := function(N=1,vect,flg=F)
#Returns vector with difference between each point and second tick
{
#Calc offset of each point from N one-second ticks
i := 1;
while (i <= len(vect))
 {
  new[i] := vect[i] - (i-1)*N
  i := i + 1
 }
print '\nCalculated offset from ',N,' second tick for each point'
if(flg)print new;
return new;
}

mjdToSeconds := function(vect,flg=F)
#Convert units of time vector to seconds and offset
#to nearest whole second of first point.
{
print '\nConverting time vector to seconds and offsetting'

if(flg)print '\nInput vector:';
if(flg)print vect;
#Offset to day number of first time
new := vect - as_integer(vect[1]);
print '\nSubtracted whole days'
if(flg)print new;
#Convert fractional days to seconds
new := new * 86400;
print '\nConverted units to seconds'
if(flg)print new;
#Finally, Offset to whole second part of first point
new := new - as_integer(new[1]);
print '\nSubtracted whole seconds of first point'
if(flg)print new;
return new;
}

plotTicks := function(N=1,vect,label="Ticks",flg=F)
#Converts time vector to tick offsets and plots on y1
{
new := mjdToSeconds(vect,flg)
new := toTicks(N,new,flg)
clear()
plotxy([1:len(new)],new,label)
(scratch := setXAxisLabel(rstart_label));

return new;
}

findVect := function()
#Retrieves first DMJD vector from app.table
{

global app;

#if(!legitimateTable(app.table)) 
#  { print 'Sorry, no table found';
#    return F;
#  }

names := app.table.colnames()
found := F

#Try to find a XXXX_DMJD column.
#Use 'split' to break name into substrings to confirm.
for(i in 1:len(names))
{
 dividedTitle := split(names[i],'_');
 for(j in 1:len(dividedTitle))
  if(dividedTitle[j]=='DMJD')found := T;
 if(found)break   #Stop at first found
}    
if(!found){print'Sorry, DMJD not found'; return F}
 else
  {
    vect := app.table.getcol(names[i])
    print '\n Found ',names[i];
  }
return vect;
}

tryTicks := function(N=1,label='Ticks',flg=F)
{
t := findVect()
if(t) 
  {
    new := plotTicks(N,t,label,flg);
    return new
  }
else return F;
}











