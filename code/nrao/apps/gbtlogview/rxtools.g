# rxtools.g: GBT receiver related functions
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
# $Id: rxtools.g,v 19.0 2003/07/16 03:42:29 aips2adm Exp $

# include guard
pragma include once
 
rxtool_gui := [=]

call_rx_gui := function()
{
	rg := ref rxtool_gui;
	rg.fm := dws.frame(title='Rx Tools');
	global sl := status_line(rg.fm);
	sl.show('Rx Utilities:Select from the following menus')
#
	gd.fm := dws.frame(rg.fm,side='left',expand='x');
#
	gd.weather:=[=];
	gd.xband:=[=];
	gd.kuband:=[=];
	gd.kband:=[=];
	gd.misc:=[=];
	wlist:="plottemp plotdewpt plotrh plotpressure plotwindvel plotwinddir"
	tlist:=" plotppsracktemp plotppsroomtemp plotrtpm140delay plotrtpmovlbidelay"
        xlist:="plotX15K plotX50K plotXamb plotXtemps plotXdewvac plotXpumpvac"
        kulist:="plotKu15K plotKu50K plotKuamb plotKutemps plotKudewvac plotKupumpvac"
        klist:="plotK15K plotK50K plotKamb plotKtemps plotKdewvac plotKpumpvac"
	mlist:="toticks plotticks findvect tryticks plotdeltas"
#
#
	messw:=as_string("")
	messw[1]:='Plot temp: plottemp(Y2[T,F],scale[C,F])'
	messw[2]:='Plot dew point: plotdewpt(Y2[T,F],scale[C,F])'
	messw[3]:='Plot RH: plotrh(Y2[T,F])'
	messw[4]:='Plot pressure: plotpressure(Y2[T,F],scale[mbar,mmHg,inHg])'
	messw[5]:='Plot wind velocity: windvel(Y2[T,F],scale[MPH,m/s])'
	messw[6]:='Plot wind direction: winddir(Y2[T,F])'
#
	messt:=as_string("");	
	messt[1]:='Plot ppsracktemp: plotppsracktemp(Y2[T,F],scale[C,F])'
	messt[2]:='Plot ppsroomtemp: plotppsroomtemp(Y2[T,F],scale[C,F])'
	messt[3]:='Plot rtpm140delay: plotrtpm140delay(Y2[T,F],scale[C,F])'
	messt[4]:='Plot rtpmovlbidelay: plotrtpmovlbidelay(Y2[T,F])'
#
	messx:=as_string("")
	messx[1]:='Plot X-band 15 K stage: plotX15K(Y2[T,F])'
	messx[2]:='Plot X-band 50 K stage: plotX50K(Y2[T,F])'
	messx[3]:='Plot X-band ambient temp: plotXamb(Y2[T,F])'
	messx[4]:='Plot X-band temps: plotXtemps(Y2[T,F])'
	messx[5]:='Plot X-band dewar vac temp: plotXdewvac(Y2[T,F])'
	messx[6]:='Plot X-band vaccuum pump temp: plotXpumpvac(Y2[T,F])'
#
        messku:=as_string("")
        messku[1]:='Plot Ku-band 15 K stage: plotKu15K(Y2[T,F])'
        messku[2]:='Plot Ku-band 50 K stage: plotKu50K(Y2[T,F])'
        messku[3]:='Plot Ku-band ambient temp: plotKuamb(Y2[T,F])'
        messku[4]:='Plot Ku-band temps: plotKutemps(Y2[T,F])'
        messku[5]:='Plot Ku-band dewar vac temp: plotKudewvac(Y2[T,F])'
        messku[6]:='Plot Ku-band vaccuum pump temp: plotKupumpvac(Y2[T,F])'
#
        messk:=as_string("")
        messk[1]:='Plot K-band 15 K stage: plotK15K(Y2[T,F])'
        messk[2]:='Plot K-band 50 K stage: plotK50K(Y2[T,F])'
        messk[3]:='Plot K-band ambient temp: plotKamb(Y2[T,F])'
        messk[4]:='Plot K-band temps: plotKtemps(Y2[T,F])'
        messk[5]:='Plot K-band dewar vac temp: plotKdewvac(Y2[T,F])'
        messk[6]:='Plot K-band vaccuum pump temp: plotKpumpvac(Y2[T,F])'
#
        messm:=as_string("")
        messm[1]:='returns diff between point and tick: totick(number,vector)'
        messm[2]:='Converts time vect. to tick offsets:plotticks(number,vector)'
        messm[3]:='findvect: Retrieves 1st DMJD vector from app.table'
        messm[4]:='tryticks(number)'
        messm[5]:='Plot Deltas for OnePps: plotdeltas(ticka,tickb)'
#
	gd.weather.button:=dws.button(gd.fm,'weather',type='menu')
	gd.timecenter.button:=dws.button(gd.fm,'timing center',type='menu')
	gd.xband.button:=dws.button(gd.fm,'X band',type='menu')
	gd.kuband.button:=dws.button(gd.fm,'Ku band',type='menu')
	gd.kband.button:=dws.button(gd.fm,'K band',type='menu')
	gd.misc.button:=dws.button(gd.fm,'miscellaneous',type='menu')	
#
	gd.weather.sel:=[=];
	gd.timecenter.sel:=[=];
	gd.xband.sel:=[=];
	gd.kuband.sel:=[=];
	gd.kband.sel:=[=];
	gd.misc.sel:=[=];
#
	gd.weather.list:=wlist;
	gd.timecenter.list:=tlist;
	gd.xband.list:=xlist;
	gd.kuband.list:=kulist;
	gd.kband.list:=klist;
	gd.misc.list:=mlist;
#
        gd.ent:=[=]
        lbl:='Function:'
        gd.ent.fm:=dws.frame(rg.fm,side='bottom',expand='x');
        gd.ent.ent:=dws.entry(gd.ent.fm);
#
	gd.efield:=[=]
	gd.efield.fm:=dws.frame(rg.fm,side='left');
	gd.efield.ent1:=dws.entry(gd.efield.fm,width=20);
#	gd.efield.lbl1:=dws.label(gd.efield.ent1,'Field 1');
	gd.efield.ent2:=dws.entry(gd.efield.fm,width=20);
	gd.efield.lbl2:=dws.label(gd.efield.fm,'Options');
#
        gd.but:=[=]
        gd.but.fm:=dws.frame(rg.fm,side='left');
        gd.but.fm.go:=dws.button(gd.but.fm,'Go', type='action');
        gd.but.fm.dismiss:=dws.button(gd.but.fm,'Dismiss',
				      type='dismiss');
#
        whenever gd.but.fm.dismiss->press do {
                val gd.fm := F
                val gd.but.fm := F
                val gd.ent.fm := F
		}
	whenever gd.but.fm.go->press, gd.ent.ent->return do {	
		tfunc:=request gd.ent.ent->get()
		input1:=request gd.efield.ent1->get()
		input2:=request gd.efield.ent2->get()
		print tfunc,input1,input2;
		print is_string(input1),is_string(input2);
		if (input1 == '' && input2 == '') {
#		print "case 1"
		xx:=rx[tfunc]();
		}
		if (input1 != '' && input2 == '') {
#		print "case 2"
		input1:=as_boolean(input1);
		xx:=rx[tfunc](input1);
		}
		if (input1 == '' && input2 != '') {
#		print "case 3",is_string(input2),input2;
		input2:=as_string(input2);
		xx:=rx[tfunc](F,input2);
		}
		if (input1 != '' && input2 != '') {
		print "case 4"
		if (tfunc == 'plotdeltas') {
		print 'here';
			input1:=as_string(input1);
			input2:=as_string(input2);
			}
		else {
			input1:=as_boolean(input1);
                	input2:=as_string(input2);
		}
		xx:=rx[tfunc](input1,input2);
		}
#		xx:=ru[tfunc](sel_scan);
		}
#
	for (i in 1:len(wlist)) {
		gd.weather.sel[i]:=dws.button(gd.weather.button,wlist[i]);
		gd.weather.sel[i].index:=i;
		}
	for (i in 1:len(tlist)) {
		gd.timecenter.sel[i]:=dws.button(gd.timecenter.button,tlist[i]);
		gd.timecenter.sel[i].index:=i;
		}
        for (i in 1:len(xlist)) {
                gd.xband.sel[i]:=dws.button(gd.xband.button,xlist[i]);
                gd.xband.sel[i].index:=i;
                }
        for (i in 1:len(kulist)) {
                gd.kuband.sel[i]:=dws.button(gd.kuband.button,kulist[i]);
                gd.kuband.sel[i].index:=i;
                }
	for (i in 1:len(klist)) {
		gd.kband.sel[i]:=dws.button(gd.kband.button,klist[i]);
		gd.kband.sel[i].index:=i;
		}
        for (i in 1:len(mlist)) {
                gd.misc.sel[i]:=dws.button(gd.misc.button,mlist[i]);
                gd.misc.sel[i].index:=i;
                }
# weather
       	whenever gd.weather.sel[1]->press do {
		gd.ent.ent->delete("start","end")
        	gd.ent.ent->insert(wlist[1])
	       	sl.show(messw[1])
                }
	whenever gd.weather.sel[2]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(wlist[2],'start')
                sl.show(messw[2])
                }
	whenever gd.weather.sel[3]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(wlist[3])
                sl.show(messw[3])
                }
	whenever gd.weather.sel[4]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(wlist[4])
                sl.show(messw[4])
                }
        whenever gd.weather.sel[5]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(wlist[5])
                sl.show(messw[5])
                }
        whenever gd.weather.sel[6]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(wlist[6])
                sl.show(messw[6])
                }
# timing center
        whenever gd.timecenter.sel[1]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(tlist[1])
                sl.show(messt[1])
                }
        whenever gd.timecenter.sel[2]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(tlist[2])
                sl.show(messt[2])
                }
        whenever gd.timecenter.sel[3]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(tlist[3])
                sl.show(messt[3])
                }
        whenever gd.timecenter.sel[4]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(tlist[4])
                sl.show(messt[4])
                }
# xband
        whenever gd.xband.sel[1]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(xlist[1])
                sl.show(messx[1])
                }
        whenever gd.xband.sel[2]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(xlist[2],'start')
                sl.show(messx[2])
                }
        whenever gd.xband.sel[3]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(xlist[3])
                sl.show(messx[3])
                }
        whenever gd.xband.sel[4]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(xlist[4])
                sl.show(messx[4])
                }
        whenever gd.xband.sel[5]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(xlist[5],'start')
                sl.show(messx[5])
                }
        whenever gd.xband.sel[6]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(xlist[6])
                sl.show(messx[6])
                }
# kuband
        whenever gd.kuband.sel[1]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(kulist[1])
                sl.show(messku[1])
                }
        whenever gd.kuband.sel[2]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(kulist[2],'start')
                sl.show(messku[2])
                }
        whenever gd.kuband.sel[3]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(kulist[3])
                sl.show(messku[3])
                }
        whenever gd.kuband.sel[4]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(kulist[4])
                sl.show(messku[4])
                }
        whenever gd.kuband.sel[5]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(kulist[5])
                sl.show(messku[5])
                }
        whenever gd.kuband.sel[6]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(kulist[6])
                sl.show(messku[6])
                }
# kband
        whenever gd.kband.sel[1]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(klist[1])
                sl.show(messk[1])
                }
        whenever gd.kband.sel[2]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(klist[2])
                sl.show(messk[2])
                }
        whenever gd.kband.sel[3]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(klist[3])
                sl.show(messk[3])
                }
        whenever gd.kband.sel[4]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(klist[4])
                sl.show(messk[4])
                }
        whenever gd.kband.sel[5]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(klist[5])
                sl.show(messk[5])
                }
        whenever gd.kband.sel[6]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(klist[6])
                sl.show(messk[6])
                }
# misc 
        whenever gd.misc.sel[1]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(mlist[1])
                sl.show(messm[1])
                }
        whenever gd.misc.sel[2]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(mlist[2],'start')
                sl.show(messm[2])
                }
        whenever gd.misc.sel[3]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(mlist[3])
                sl.show(messm[3])
                }
        whenever gd.misc.sel[4]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(mlist[4])
                sl.show(messm[4])
                }
        whenever gd.misc.sel[5]->press do {
                gd.ent.ent->delete("start","end")
                gd.ent.ent->insert(mlist[5])
                sl.show(messm[5])
                }
}

finddata := function()
{
global app,rtbl,rnames,rXtime,rXloaded,rKutime,rKuloaded;
global rKtime,rKloaded,Y1,y1,Y2,y2,rstart_label;
global rWT1time,rWT1loaded,MPH;
global rRtpm140time,rRtpm140loaded,rRtpmOvlbitime,rRtpmOvlbiloaded;
global rOnePpsStatustime,rOnePpsStatusloaded,rOnePpsDeltasloaded;
#Conveniences
Y1 := F
y1 := F
Y2 := T
y2 := T
mph := 'MPH'
f := 'F'
#Get table filled by newlogview GUI
rtbl := app.table
rnames := rtbl.colnames()
inttime := rtbl.getcol("Time")
rtime:=(inttime-as_integer(inttime[1]))*86400.
#Check for X-band data
if (len(rnames[rnames == 'RC08_10_DMJD'])!=0)
  {
    rXloaded := T
    intrxtime:=rtbl.getcol("RC08_10_DMJD")
    rXtime := (intrxtime-as_integer(intrxtime[1]))*86400.
    print" X-band data found"
  }
  else
    rXloaded := F;

#Check for Ku-band data
if (len(rnames[rnames == 'RC12_18_DMJD'])!=0)
  {
    rKuloaded := T
    intrkutime:=rtbl.getcol("RC012_18_DMJD")
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

#Check for OnePpsDeltas data
if (len(rnames[rnames == 'OnePpsDeltas_DMJD'])!=0)
  {
    rOnePpsDeltasloaded := T
    intrOtime:=rtbl.getcol("OnePpsDeltas_DMJD")
    rOnePpsDeltastime :=(intrOtime-as_integer(intrOtime[1]))*86400.
    print" OnePpsDeltas data found"
  }
  else
    rOnePpsDeltasloaded := F;

rstart_label := ["File Starts: ",toDate(rtime[1])]

if (!(rXloaded|rKuloaded|rKloaded|rWT1loaded|rRtpm140loaded|\
      rRtpmOvlbiloaded|rOnePpsStatusloaded|rOnePpsDeltasloaded)) 
  print" Sorry, no data found";
}

###############################################################################
 
const rxutils := function() {
 
self := [=]
public := [=]
 
#
# ----- private methods -----
#
 
#File:  rtools4.g
#Glish functions to assist in plotting GBT M/C log files.
#Currently supports only the GBT receivers at the 140,
#Weather1, Rtpm140, RtpmOvlbi, and OnePpsStatus.
 
#Function definitions:

#Function converts temps from C to F
self.temptoF := function (tC)
{
return (1.8 * tC + 32.0)
}

#Function calculates liquid water saturated pressure at given temp & pressure
#Ref:  Parker draft memo
self.satH2Opress := function(t_,p_)
{
return 6.1121*(1.0007+p_*3.46e-6)*exp(t_*17.502/(240.97+t_))
}

#Function converts velocity from meters/sec to miles/hour
self.veltoMPH := function(vel)
{
return (2.236936 * vel)
}

#Function converts pressures from mbar to mm mercury
self.mbartommHg := function (p)
{
return (p/1.3284)
}

#Function converts pressures from mbar to inches mercury
self.mbartoinHg := function (p)
{
return (p/(25.4*1.3284))
}

self.mjdtoseconds := function(vect,flg=F)
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

#
# ----- public methods -----
#

#Weather Functions
public.plottemp  := function(Y2flg=F,scale='C')
{
if(rWT1loaded)
 {
  t  := rtbl.getcol("Weather1_AMB_TEMP")
  if ((scale == 'F') | (scale == 'f')) t := self.temptoF(t);
  if(Y2flg) dset := timeY2(rWT1time,t,["Air Temp",scale])
    else dset := timeY(rWT1time,t,["Air Temp",scale]);
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, Weather1 data not found in table";
}

public.plotdewpt  := function(Y2flg=F,scale='C')
{
if(rWT1loaded)
 {
  t  := rtbl.getcol("Weather1_DEWP")
  if (scale == 'F' | scale == 'f') t := self.temptoF(t);
  if(Y2flg) dset := timeY2(rWT1time,t,["Dew Pt",scale])
    else dset := timeY(rWT1time,t,["Dew Pt",scale]);
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, Weather1 data not found in table";
}

public.plotrh  := function(Y2flg=F, dummy=F)
{
if(rWT1loaded)
 {
  t  := rtbl.getcol("Weather1_AMB_TEMP")
  dp  := rtbl.getcol("Weather1_DEWP")
  pressure := rtbl.getcol("Weather1_PRESSURE")
  rh := 100.0 * self.satH2Opress(dp,pressure)/self.satH2Opress(t,pressure)
  if(Y2flg) dset := timeY2(rWT1time,rh,"RH %")
    else dset := timeY(rWT1time,rh,"RH %");
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, Weather1 data not found in table";
}

public.plotpressure  := function(Y2flg=F,scale='mbar')
{
if(rWT1loaded)
 {
  t  := rtbl.getcol("Weather1_PRESSURE")
  if (scale == 'mmHg' | scale == 'mmhg') t := self.mbartommHg(t)
    else if (scale == 'inHg' | scale == 'inhg') t := self.mbartoinHg(t);
  if(Y2flg) dset := timeY2(rWT1time,t,["Pressure",scale])
    else dset := timeY(rWT1time,t,["Pressure",scale]);
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, Weather1 data not found in table";
}

public.plotwindvel  := function(Y2flg=F,scale='m/s')
{
if(rWT1loaded)
 {
  t  := rtbl.getcol("Weather1_WINDVEL")
  if (scale == 'MPH' | scale == 'mph') t := self.veltoMPH(t);
  if(Y2flg) dset := timeY2(rWT1time,t,["Wind Vel",scale])
    else dset := timeY(rWT1time,t,["WindVel",scale]);
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, Weather1 data not found in table";
}

public.plotwinddir  := function(Y2flg=F,dummy=F)
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
public.plotppsracktemp  := function(Y2flg=F,scale='C')
{
if(rOnePpsStatusloaded)
 {
  t  := rtbl.getcol("OnePpsStatus_RACKTEMPERATURE")
  if ((scale == 'F') | (scale == 'f')) t := self.temptoF(t);
  if(Y2flg) dset := timeY2(rOnePpsStatustime,t,["Timing Center Rack Temp",scale])
    else dset := timeY(rOnePpsStatustime,t,["Timing Center Rack Temp",scale]);
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, OnePpsStatus data not found in table";
}

public.plotppsroomtemp  := function(Y2flg=F,scale='C')
{
if(rOnePpsStatusloaded)
 {
  t  := rtbl.getcol("OnePpsStatus_ROOMTEMPERATURE")
  if ((scale == 'F') | (scale == 'f')) t := self.temptoF(t);
  if(Y2flg) dset := timeY2(rOnePpsStatustime,t,["ICB Basement Temp",scale])
    else dset := timeY(rOnePpsStatustime,t,["ICB Basement Temp",scale]);
  scratch := setXAxisLabel(rstart_label)
  return dset
 }
 else print" Sorry, OnePpsStatus data not found in table";
}

public.plotrtpm140delay  := function(Y2flg=F,dummy=F)
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

public.plotrtpmovlbidelay  := function(Y2flg=F,dummy=F)
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
public.plotX15K := function(Y2flg=F,dummy=F)
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

public.plotX50K := function(Y2flg=F,dummy=F)
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

public.plotXamb := function(Y2flg=F,dummy=F)
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

public.plotXtemps := function(Y2flg=F,dummy=F)
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

public.plotXdewvac := function(Y2flg=F,dummy=F)
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

public.plotXpumpvac := function(Y2flg=F,dummy=F)
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
public.plotKu15K := function(Y2flg=F,dummy=F)
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

public.plotKu50K := function(Y2flg=F,dummy=F)
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

public.plotKuamb := function(Y2flg=F,dummy=F)
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

public.plotKutemps := function(Y2flg=F,dummy=F)
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

public.plotKudewvac := function(Y2flg=F,dummy=F)
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

public.plotKupumpvac := function(Y2flg=F,dummy=F)
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
public.plotK15K := function(Y2flg=F,dummy=F)
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

public.plotK50K := function(Y2flg=F,dummy=F)
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

public.plotKamb := function(Y2flg=F,dummy=F)
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

public.plotKtemps := function(Y2flg=F,dummy=F)
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

public.plotKdewvac := function(Y2flg=F,dummy=F)
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

public.plotKpumpvac := function(Y2flg=F,dummy=F)
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

public.toticks := function(N=1,vect)
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

public.plotticks := function(N=1,vect)
#Converts time vector to tick offsets and plots on y1
{
new := self.mjdtoseconds(vect)
new := public.toticks(N,new)
clear()
plotxy([1:len(new)],new,label)
(scratch := setXAxisLabel(rstart_label));

return new;
}

public.findvect := function(dummy1=F,dummy2=F)
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

public.tryticks := function(N=1,flg=F)
{
t := public.findvect()
if(t) 
  {
    new := public.plotticks(N,t);
    return new
  }
else return F;
}

public.plotdeltas := function(ticka="Site1Hz",tickb="Site1Hz")
{
    if (rOnePpsDeltasloaded) {
	print ticka,tickb;
	tbl  := table('logtable');
	expa := spaste("OnePpsDeltas_CHANNELA == '",ticka,"'");
	expb := spaste("OnePpsDeltas_CHANNELB == '",tickb,"'");
	express  := spaste(expa," && ",expb);
    
	subtab := tbl.query(express);

	a := subtab.getcol("OnePpsDeltas_DMJD");
	tinseconds:=(a-as_integer(a[1]))*86400.;
	b := subtab.getcol("OnePpsDeltas_DELTAT");

	dp.plotxy(tinseconds,b,"OnePps Deltas");
	subtab.close();
	tbl.close();
    }
    else print" Sorry, OnePpsDeltas data not found in table";
}

return public;

}
const rx := rxutils();
#
rxutils();
finddata();
