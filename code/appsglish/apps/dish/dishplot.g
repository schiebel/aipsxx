# dishplot.g: single dish plotter.
#------------------------------------------------------------------------------
#   Copyright (C) 1997,1998,1999,2000,2001,2002,2003
#   Associated Universities, Inc. Washington DC, USA.
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
#    $Id: dishplot.g,v 19.3 2004/08/25 01:10:49 cvsmgr Exp $
#
#------------------------------------------------------------------------------

#pragma include once;

include 'coordsys.g';
include 'imageprofilesupport.g';
include 'popuphelp.g'

const dishpgplotter:=subsequence(title='dishplot.ps',ref itsdish)
{
#  self := [=];
  private := [=];

  private.rdcount:=0;
  private.menusexist:=F;
  private.pos:=[dragging=F];
  private.curs:=array(0,1,2);
  private.oldcolor:=1;
  private.range:='';
  private.rangeframe:=F;
  private.ci:=2;
  private.dish := itsdish;
  private.feed:=F;
  private.zoomflag:=T;
  private.zline:=F;
  private.ls:=1;
  private.currRefcode:='';

  tempimage := [=];
  self.ips := [=];
  self.pf := [=];

#
# define functions for the chalkboard drawing
#
  private.downcallback:=function(rec) {
	wider private;
	private.pos:=[dragging=T,xlast=rec.world[1],ylast=rec.world[2]];
  }
  private.motioncallback:=function(rec) {
	wider private;
	if (private.pos.dragging) {
		x:=rec.world[1];
		y:=rec.world[2];
		private.oldcolor:=self.qci();
		self.sci(5);
		self.line([private.pos.xlast,x], [private.pos.ylast,y]);
		private.pos.xlast := x;
		private.pos.ylast:=y;
	}
  }
  private.upcallback := function(rec) {
	wider private;
	private.pos.dragging:=F;
  }

#
# define functions for the range setting
#
  private.rdcallback := function(rec) {
	wider private,self;
	win:=self.qwin();
	if (private.rdcount==0) {
	   private.rdcount:=1; 
	   ok:=self.cursor('xrng');
	   private.curs[1]:=rec.world[1];
	} else if (private.rdcount==1) {
	   private.rdcount:=0;
	   ok:=self.move(rec.world[1],win[3]+0.2);
	   private.curs[2]:=rec.world[1];
	   xvec:=self.ips.getcurrentabcissa();
	   yvec:=self.ips.getordinate().data;
	   fvec:=self.ips.getmask();
	   if (is_complex(yvec)) yvec:=real(yvec);
	   stats:=self.compute_statistics(xvec,yvec,fvec,private.curs[1],
					  private.curs[2]);
	   ok:=self.sfs(2);
	   ok:=self.rect(private.curs[1],private.curs[2],
		(stats.mean-stats.stddev),(stats.mean+stats.stddev));
	   ok:=self.cursor('norm');
	   lbracket:='['
	   rbracket:=']'
	   colon:=':'
	   dum:=spaste(lbracket,as_string(private.curs[1]),colon,
		as_string(private.curs[2]),rbracket);
	   private.range:=spaste(private.range,dum);
	   if (!is_boolean(private.rangeframe)) {
		if (private.rangeframe.getentry()=='') {
			private.rangeframe.insertentry(private.range);
		} else {
			private.rangeframe.insertentry(private.range);
		};
	   }
	  return T;
	};
  };

# header info
  private.header := function(ref sddata) {
	if (self.header->state()) {
           self.ips.settitle('',1);
	   object :=sddata.header.source_name;
           scannum:=sddata.header.scan_number;
           exposure:=sddata.header.exposure;
	   exposure::print.precision:=5
           thetyme:=dq.time(dm.getvalue(sddata.header.time),form='dmy');
           delta  :=sddata.header.resolution;
	   delta::print.precision:=5
	   rf     :=sddata.data.desc.restfrequency;
	   rf::print.precision:=7;
           ra     :=dq.time(sddata.header.direction.m0);
           dec    :=dq.angle(sddata.header.direction.m1);
           oktime :=dm.doframe(sddata.header.time);
           okpos  :=dm.doframe(sddata.header.telescope_position);
           newdir :=dm.measure(sddata.header.direction,'AzEl');
           az     :=dq.angle(newdir.m0);
           el     :=dq.angle(newdir.m1);
           telescope:=sddata.header.telescope;
           tsys   :=sddata.header.tsys;
	   tsys::print.precision:=4
           trx    :=sddata.header.trx;
	   trx::print.precision:=4;
           tcal   :=sddata.header.tcal;
	   tcal::print.precision:=4;
#
           self.sch(1);
           self.sci(1);
           markedstring:=spaste('Source: ',object);
           self.mtxt('t',4.0,0,0,markedstring);
           markedstring:=spaste('Time: ',thetyme);
           self.mtxt('t',4.0,1,1,markedstring);
           self.mtxt('t',4.0,1,1,markedstring);
           markedstring:=spaste('RA: ',ra,' DEC: ',dec);
           self.mtxt('t',3,0,0,markedstring);
           markedstring:=spaste('Az: ',az,' El: ',el);
           self.mtxt('t',3,1,1,markedstring);
           markedstring:=spaste('Trx: ',trx,' Tcal: ',tcal,' Tsys: ',tsys);
           self.mtxt('t',2,0,0,markedstring);
           markedstring:=spaste('Delta: ',delta,' Freq: ',
		sddata.data.desc.restfrequency);
           self.mtxt('t',2,1,1,markedstring);
	   markedstring:=spaste('Scan: ',scannum);
	   self.mtxt('t',1,0,0,markedstring);
	   markedstring:=spaste('Expos: ',exposure);
	   self.mtxt('t',1,1,1,markedstring);
	   tmpie:=self.qci();
           if (is_boolean(private.dish.getfeed())) {
	      for (i in 1:len(sddata.data.desc.corr_type)) {
	        markedstring:=spaste('Ch: ',i,' ',sddata.data.desc.corr_type[i])
	        self.sci(i+1);
	        self.mtxt('t',-1*i,0.1,1,markedstring);
	      }
           } else {
                markedstring:=spaste('Ch: ',private.dish.getfeed(),' ',
			sddata.data.desc.corr_type[1])
                self.sci(1+private.dish.getfeed());
                self.mtxt('t',-1*1,0.1,1,markedstring);
           };
	   self.sci(tmpie);
        }
  }

  private.done := function ()
  {
     wider private, self;
#
     if (is_agent(self.ips)) self.ips.done();
     if (is_agent(self.pf)) self.pf.done();
     if (is_image(tempimage)) tempimage.done();
#
     ok := self.done();
     return ok;
  }

#
# Initialize the plotter 
#
  self := pgplotter(widgetset=dws);
  private.done := self.done;

  self.is_active:=T;
  self.pf:=F;
  self.index:=0;

# Start the plotter gui
#  self.gui();

  self.title('DISH Plotter')

# Initialize the image profile support
#  tmpcsys:=coordsys(direction=T,spectral=T);
  self.csys := coordsys(direction=T,spectral=T);
  tmpshp:=[1,1,128];
  self.ips:=imageprofilesupport(self.csys,tmpshp,dws,T,offset=T);
  if (is_fail(self.ips)) fail;
  self.ips.setprofileaxis(3);
  self.ips.setplotter(self);
  self.ips.makemenus();

  private.frame:=self.userframe();

  spacer := message(private.frame,'        ')

  self.header:=button(private.frame,'Head',type='check');
  self.header->state(T);
  popuphelp(self.header,hlp='Toggles on Header information at the top of each plot');

  self.overlay:=button(private.frame,'Overlay',type='check');
  popuphelp(self.overlay,hlp='Toggle on to overlay plots');

  private.opt:=button(private.frame,'Opt',type='menu');
  popuphelp(private.opt,hlp='Plotter options');
  
  self.reverse:=button(private.opt,'RevCol',type='check');
  popuphelp(self.reverse,
	hlp='Select to reverse foreground and background colors');

  self.chalkboard:=button(private.opt,'Chalk',type='check');
  popuphelp(self.chalkboard,hlp='When selected, use the Right Mouse Button to draw notes on the plot');

  private.autos:=button(private.frame,'AutoS',type='menu');
  popuphelp(private.autos,hlp='Autoscale toggle for X and Y axes');

  self.xauto:=button(private.autos,'XAuto',type='check');
  self.xauto->state(T);
  popuphelp(self.xauto,hlp='State of button determines persistence of zoom: 1) checked = x axis will autoscale for each spectrum; 2) unchecked = x axis will retain current zoom characteristics.');

  self.yauto:=button(private.autos,'YAuto',type='check');
  self.yauto->state(T);
  popuphelp(self.yauto,hlp='State of button determines persistence of zoom: 1) checked = y axis will autoscale for each spectrum; 2) unchecked = y axis will retain current zoom characteristics.');

#  This has been moved to the pgplotter itself
#
#  self.uzoom:=button(private.frame,'Unzoom');
#  popuphelp(self.uzoom,hlp='Iteratively unzoom - matches CNTRL-MB2');
#
#  whenever self.uzoom->press do {
#	wider private,self;
#	self.unzoom();
#  };

#  The GFit button will be removed until we get the opportunity to improve
#   its reliability.  Use d.gauss instead.  JB
#
#  self.gfit :=button(private.frame,'GFit');
#  popuphelp(self.gfit,hlp='Push button to call frame for gaussian fitting of active plot');

  self.lineidb :=button(private.frame,'LineID');
  popuphelp(self.lineidb,hlp='Currently only works when units are Hz--push to draw lines from the Poynter and Pickett catalog on the current plot');

  whenever self.xauto->press do {
	wider private,self;
	private.xzoom:=self.xauto->state();
  }

  whenever self.yauto->press do {
        wider private,self;
        private.yzoom:=self.yauto->state();
  }


#  whenever self.gfit->press do {
#	wider self;
## 	turn off any cursor setting
#	if (self.index!=0) {
#                self.deactivatecallback(self.index);
#                private.range:='';
#        };
#
###JPM	include 'dishpf.g'
#	include 'imageprofilefitter.g'
#	include 'coordsys.g';
#	include 'image.g';
##
#	sddata:=private.dish.rm().getlastviewed().value;
#	nativeunits:=sddata.data.desc.chan_freq.unit;
#        xaxis:=dq.quantity(sddata.data.desc.chan_freq.value,
#                nativeunits);
#        restfreq:=dq.quantity(sddata.data.desc.restfrequency,'Hz');
##
## 	csys:=coordsys(direction=T,spectral=T);
#        if (nativeunits ~ m/m/ ) {
#           self.csys.setspectral(velocities=xaxis,restfreq=restfreq,
#		refcode=sddata.data.desc.refframe,
#                doppler=sddata.header.veldef);
#        } else {
#           self.csys.setspectral(refcode=sddata.data.desc.refframe,
#		frequencies=xaxis,restfreq=restfreq,
#		doppler=sddata.header.veldef);
#        };
#        ok:=self.csys.se(sddata.header.time);
#        ok:=self.csys.settelescope(sddata.header.telescope);
#        ok:=self.csys.setreferencevalue(dm.getvalue(sddata.header.direction),
#                type='direction')
#        shp:=[1,1,sddata.data.arr::shape[2]];
#	resetRef := F;
#	if (sddata.data.desc.refframe != private.currRefcode) {
#	    resetRef := T;
#	    private.currRefcode := sddata.data.desc.refframe;
#	}
#        self.ips.setcoordinatesystem(self.csys,shp,resetRef);
#	data:=array(0,1,1,len(sddata.data.arr[1,]));
#	data[1,1,]:=[sddata.data.arr[1,]];
#	if (is_image(tempimage)) {
#		ok:=tempimage.done();
#	};
#	global tempimage:=imagefromarray(pixels=data,csys=self.csys,log=F);
#	ok:=tempimage.calcmask('!isnan($tempimage)');
#	
#        if (is_fail(tempimage)) {
#           note (tempimage::message, priority='SEVERE', origin='dishplotter.g');
#        } else {
#           if (is_agent(self.pf)) {
#              self.pf.setimage(tempimage);
#              self.pf.gui();
#           } else {
#              self.pf:=imageprofilefitter(infile=tempimage, plotter=self, showimage=F);
#              if (is_fail(self.pf)) {
#                 note (self.pf::message, priority='SEVERE', origin='dishplotter.g');
#              }
#           }
#        }
#  }
 
  whenever self.lineidb->press do {
	wider self;
	self.lineid();
  }

  whenever self.chalkboard->press do {
	wider self,private;
	if (self.chalkboard->state()) {
  	private.b3down:=self.setcallback('button3',private.downcallback);
  	private.b3move:=self.setcallback('motion',private.motioncallback);
  	private.b3up  :=self.setcallback('buttonup',private.upcallback);
	} else {
	ok:=self.deactivatecallback(private.b3down);
	ok:=self.deactivatecallback(private.b3move);
	ok:=self.deactivatecallback(private.b3up);
	ok:=self.sci(private.oldcolor);
	}
  }

  whenever self.reverse->press do {
	wider self;
	if (self.reverse->state()) {
        	# defines black to be white
        	self.scr(0,1,1,1)
        	# defines white as black
        	self.scr(1,0,0,0)
        	self.refresh()# redraws the screen
        } else {
		self.scr(0,0,0,0);
		self.scr(1,1,1,1);
		self.refresh();
	}
  }

  whenever self.ips->absrelchange do {
        wider private;
        rec:=private.dish.rm().getlastviewed().value;
        ok:=private.header(rec);
        private.range:='';
        #draw zline if wanted
        if (private.zline) {
           win:=self.qwin();
           ok:=self.move(win[1],0);
           ok:=self.draw(win[2],0);
        };

  }

  whenever self.ips->unitchange do {
        wider private;
        rec:=private.dish.rm().getlastviewed().value;
        ok:=private.header(rec);
	private.range:='';
        if (private.zline) {
           win:=self.qwin();
           ok:=self.move(win[1],0);
           ok:=self.draw(win[2],0);
        };
  }
 
  whenever self.ips->dopplerchange do {
	wider private;
	rec:=private.dish.rm().getlastviewed().value;
	ok:=private.header(rec);
	private.range:='';
        if (private.zline) {
           win:=self.qwin();
           ok:=self.move(win[1],0);
           ok:=self.draw(win[2],0);
        };
  }

  whenever self.ips->spectralrefchange do {
	wider private;
	rec:=private.dish.rm().getlastviewed().value;
	ok:=private.header(rec);
	private.range:='';
        if (private.zline) {
           win:=self.qwin();
           ok:=self.move(win[1],0);
           ok:=self.draw(win[2],0);
        };
  };

  private.clear:=self.clear;
  self.clear := function() {
        wider private;
        private.clear();
        self.ips.setnoprofile();
  }

#  self.range_cursor :=
#        sdTkPgplotter_range_cursor (ref self);#, ref self.ranges.current.debug);

# set button1 as the range setting
  self.setranges := function(outframe=F,state=T) {
	wider self,private;
	if (!is_boolean(outframe)) private.rangeframe:=outframe;
	if (state) {
           if (self.index!=0) {
		self.deactivatecallback(self.index);
		private.range:='';
	   };
  	   self.index:=self.setcallback('button1',private.rdcallback);
	} else {
	   ok:=self.deactivatecallback(self.index);
	   self.index:=0;
	};
  }

  self.compute_statistics := function(xvec,yvec,fvec,x1,x2) {
	stats:=[=];
	if (x1>x2) {
		tmp:=x1;
		x1:=x2;
		x2:=tmp;
	}
	yvecsegment:=yvec[(xvec>=x1 & xvec<=x2)&fvec];
	if (len(yvecsegment)<2) {
		return F;
	} else {
		stats.mean:=mean(yvecsegment);
		stats.stddev:=stddev(yvecsegment);
		stats.x1:=x1;
		stats.x2:=x2;
		return stats;
	}
  }

  self.setls := function(ls=1) {
	wider private,self;
	private.ls:=ls;
	return T;
  };

  self.zline := function(torF) {
	wider private;
	private.zline:=torF;
	return T;
  }

# MAIN PLOTTER WORKHORSE FUNCTION
  self.plotrec := function(sddata,overlay=F) {
     wider private,self;
 
     btime:=time();

     #if invoked clear incremental zoom counter
     ok:=self.resetzoom();

     #get zoom state
     private.xzoom:=self.xauto->state();
     private.yzoom:=self.yauto->state();

     private.feed:=private.dish.getfeed();
     #debug line
     if (self.overlay->state()) overlay:=T;
     thedata:=real(sddata.data.arr);
     if (is_complex(thedata)) thedata:=real(thedata);
     if (!overlay | !self.ips.hasprofile()) {
     #
        private.ci := 2;
#        csys:=coordsys(direction=T,spectral=T);
        nativeunits:=sddata.data.desc.chan_freq.unit;
        xaxis:=dq.quantity(sddata.data.desc.chan_freq.value,
			   nativeunits);
#	temporary fix since GBT data is missing rest frequency info
	restfreq:=sddata.data.desc.restfrequency;
	if (restfreq==0) {
		restfreq:=dq.quantity(sddata.data.desc.reffrequency,'Hz');
	} else {
        	restfreq:=dq.quantity(sddata.data.desc.restfrequency,'Hz');
	};
        if (nativeunits ~ m/m/ ) {
           self.csys.setspectral(velocities=xaxis,restfreq=restfreq,
		refcode=sddata.data.desc.refframe,
		doppler=sddata.header.veldef);
        } else {
           self.csys.setspectral(refcode=sddata.data.desc.refframe,
                frequencies=xaxis,restfreq=restfreq,
                doppler=sddata.header.veldef);
        };
	ok:=self.csys.se(sddata.header.time);
	ok:=self.csys.settelescope(sddata.header.telescope);
	ok:=self.csys.setreferencevalue(dm.getvalue(sddata.header.direction),
		type='direction')
        shp:=[1,1,sddata.data.arr::shape[2]];
        
        currentdoppler:=self.ips.getdoppler();
#        self.ips.setprofileaxis(3);
	resetRef := F;
	if (sddata.data.desc.refframe != private.currRefcode) {
	    resetRef := T;
	    private.currRefcode := sddata.data.desc.refframe;
	}
        self.ips.setcoordinatesystem(self.csys,shp,resetRef);
#        self.ips.makeabcissa([1]);
#	self.ips.setnoprofile();
	self.ips.setordinateunit(sddata.data.desc.units);
        if (is_boolean(private.feed)) {
          for (i in 1:sddata.data.arr::shape[1]) {
	      if (i != 1) private.ci +:= 1;
              if (private.ci>15) private.ci -:=14;
		 ok:=self.ips.setprofile(abcissa=sddata.data.desc.chan_freq.value,
		                         ordinate=thedata[i,],
                                         mask=!(sddata.data.flag[i,]),
                                  	 unit=sddata.data.desc.chan_freq.unit,
                                         doppler=sddata.header.veldef,
 		                         ci=private.ci, ls=private.ls);
          }
#	} else if (private.feed > sddata.data.arr::shape[1]) {
#	  dl.note('ERROR: No Matching Receptor; please run d.setfeed');
#	  return F;
        } else {
	  if (private.feed != 1) private.ci +:= 1;
          if (private.ci>15) private.ci -:=14;
                 ok:=self.ips.setprofile(abcissa=sddata.data.desc.chan_freq.value,
                                         ordinate=thedata[1,],
                                         mask=!(sddata.data.flag[1,]),
                                         unit=sddata.data.desc.chan_freq.unit,
                                         doppler=sddata.header.veldef,
                                         ci=private.ci,ls=private.ls);
        }
#    abscissa info - blinks and rescales! can't use this!
	#self.ips.setabcissaunit(self.ips.getabcissaunit(),currentdoppler)
#    header information
        object :=sddata.header.source_name;
        if (!self.header->state()) {
     	   self.ips.settitle(object,1);
        };
        self.ips.plot(xautoscale=private.xzoom,yautoscale=private.yzoom);
#
	#print out header information if necessary
	ok:=private.header(ref sddata);
     } else {
	   for (i in 1:sddata.data.arr::shape[1]) {
              private.ci:=private.ci+1;
              if (private.ci>15) private.ci -:=14;
                 ok:=self.ips.setprofile(abcissa=sddata.data.desc.chan_freq.value,
                                         ordinate=thedata[i,],
                                         mask=!(sddata.data.flag[i,]),
                                         unit=sddata.data.desc.chan_freq.unit,
                                         doppler=sddata.header.veldef,
                                         ci=private.ci,ls=private.ls);
	   }
           self.ips.plot(xautoscale=private.xzoom,yautoscale=private.yzoom);
        };

     self.active := T;
     #draw zline if wanted
     if (private.zline) {
     	win:=self.qwin();
     	ok:=self.move(win[1],0);
     	ok:=self.draw(win[2],0);
     };
  }; # END PLOTREC

  self.active := F;		# Start life dead.

  self.ranges := function() {
	wider private;
	return private.range;
  };
 
  self.putranges:=function(newranges) {
	wider private;
	private.range:=newranges;
  }

  # JAU: Need an unregister function too.  Coming soon to a theater near you...
  const self.register_range := function (rangeName, rangeInterface)
  {
    wider self;
    # JAU: This actually needs to register callbacks, etc.
    return self.registeredRanges[rangeName] := rangeInterface;
  }

    self.assert_range_cursor := function (rangeType)
  {
    wider self;
    self.rangeCursorType := rangeType;

    if (self.is_active ) {
      for (thisRange in field_names (self.registeredRanges)) {
        if (thisRange != rangeType) {
          self.registeredRanges[thisRange].set_cursor_state (F, F);
        } else {
          self.currentRange := ref self.registeredRanges[thisRange];
        }
      }
      self.range_cursor.make_all_inactive ();
      self.range_cursor.make_active ('buttonOneOn');
    }
    return T;
  }
  const self.assert_range_cursor := ref self.assert_range_cursor;

  self.deassert_range_cursor := function ()
  {
    wider self;
    self.rangeCursorType := F;

    if (self.is_active ) {
      self.range_cursor.make_all_inactive ();
      self.currentRange := F;
    }
    return T;
  }
  const self.deassert_range_cursor := ref self.deassert_range_cursor;
  
  self.create := function() {
	wider private;
	  self := pgplotter(plotfile=title,widgetset=dws);
	private.done:=self.done;
  }

  self.lineid := function() {
	wider private,self;
	aipsroot:=sysinfo().root();
	thedir:='/data/catalogs/lines/jpl';
	pathname:=spaste(aipsroot,thedir,'');
	linelist:=table(pathname);
	xvec:=self.ips.getabcissa().nativeworld.abs;
	xmin:=min(xvec);
	xmax:=max(xvec);
	ybegin:=self.qwin()[3];
	yend:=self.qwin()[4];
	currunits:=self.ips.getabcissaunit();
        freqfac := 1.0;
	if (currunits=='Hz') {
		freqfac:=1.E6;
	} else if (currunits=='kHz') {
		freqfac:=1.E3;
	} else if (currunits=='MHz') {
		freqfac:=1.0;
	} else if (currunits=='GHz') {
		freqfac:=1.E-3;
	}
	querystring:=spaste('Frequency > ',xmin/1.E6,' && Frequency < ',
		xmax/1.E6);
	subt:=linelist.query(querystring);
	mylen:=subt.nrows();
	lines:=subt.getcol('Molecule');
	trans:=subt.getcol('Transition');
	freqs:=subt.getcol('Frequency');
	for (i in 1:subt.nrows()) {
		self.sci(5);
		self.sch(1.0);
		self.move(freqs[i]*freqfac,0.8*yend);
		self.draw(freqs[i]*freqfac,yend);
		self.ptxt(freqs[i]*freqfac,ybegin,90,0,lines[i]);
	}
  } # END LINEID

#  self.debug := ref private;
#  return ref public;
  return;
}
