# GBT Imaging Utilities
#------------------------------------------------------------------------------
#
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
#    $Id: mydish_gbtim.gp,v 19.4 2005/10/24 20:03:25 bgarwood Exp $
#
#------------------------------------------------------------------------------

pragma include once

note('mydish_gbtim.gp included');

  include 'table.g';
  include 'progress.g';
  include 'gbtmsfiller.g';
  include 'matrix.g';

mydish_gbtim := [=];

mydish_gbtim.attach := function(ref public) {

  private:=[=];

const public.makeim :=function(scan,start,stop,step=1,
		imname='scanimage',spwid=F,nx=F,ny=F,cellx=F,celly=F,
		gridfn='SF',convsupport=F,center=F) {
        wider public;
        include 'imager.g';

	if (sum(['SF','BOX','PB'] == gridfn) == 0) {
	    gridfn := 'SF';
	    dl.log(message='Unrecognized gridfn, using SF', priority='WARN', postcli=T);
	}

	# set appropriate convsupport
	if (is_boolean(convsupport) || !is_numeric(convsupport)) {
	    # default for BOX - set it to 0.
	    if (gridfn == 'BOX') convsupport := 0;
	    else {
		if (gridfn == 'SF') convsupport := 1;
		else convsupport := F;
	    }
	} else if (!is_integer(convsupport)) {
	    convsupport := as_integer(convsupport+0.001);
	    dl.log(message=spaste('convsupport must be an integer - rounded to :',convsupport),
		   postcli=T,priority='WARN');
	}
	    
        sddata:=public.getscan(scan);
	if (is_boolean(sddata)) return F;
	rec:=ref sddata;
	tmp:=rec.other.data_description.SPECTRAL_WINDOW_ID+1;
	if (is_boolean(spwid)) {
		spwid:=tmp;
	};
        nativeunits:=sddata.data.desc.chan_freq.unit;
        xaxis:=dq.quantity(sddata.data.desc.chan_freq.value,
                nativeunits);
        restfreq:=dq.quantity(sddata.data.desc.restfrequency,'Hz');
        endscan:=scan+(rec.other.gbt_go.PROCSIZE-1);
	trysequence:=scan:endscan;
        mssequence:=public.listscans();
        realsequence:=mssequence[mssequence>=scan & mssequence<=endscan];
        if (len(trysequence)!=len(realsequence)) {
           print 'WARNING: Not all scans in the procedure are present';
           print 'WARNING: Calibrating only those present';
           trysequence:=realsequence;
        };

        msname:=eval(public.files(T).filein).name();

        #technique to avoid sticky table locking issues
        rmname:=eval(public.files(T).filein)
        ok:=rmname.unlock();

        tab:=table(msname,ack=F);
        if (is_fail(tab)) print 'table creation failed';
        global scanlist:=trysequence;
        subt:=tab.query('SCAN_NUMBER in $scanlist');
        fi:=unique(subt.getcol('FIELD_ID'))+1;
        ddi:=unique(subt.getcol('DATA_DESC_ID')+1);#needed for spec win id
        ddt:=table(tab.getkeyword('DATA_DESCRIPTION'),ack=F);
        swi:=(ddt.getcol('SPECTRAL_WINDOW_ID')[ddi])+1;
        mytimes:=subt.getcol('TIME');
        global _starttime:=min(mytimes);
        global _stoptime:=max(mytimes);
	ok:=subt.done();
	ok:=ddt.done();

	if (has_field(rec.other,'gbt_go')) {
	   gorec:=rec.other.gbt_go;
	} else {
	   ok:=rmname.lock();
	   dl.log(message='No Go record in scan data',priority='SEVERE',postcli=T);
	   ok:=tab.done();
	   return F;
	};
        gnames:=field_names(gorec);
        if (any(gnames=='RADECSYS')) {
                radecsys:=gorec.RADECSYS;
        } else {
                radecsys:=gorec.RADESYS;
        };
        if (any(gnames=='COORDSYS')) {
           mycoordsys:=gorec.COORDSYS;
        } else {
           mycoordsys:=radecsys;
        };
        if (!any(gnames=='EQUINOX')) {
                dl.note('No EQUINOX found; if coordinates are not Galactic, there will be errors',priority='WARN');
        } else {
                equinox :=gorec.EQUINOX;
        };
#
        if (mycoordsys=='RADEC') {
                if (equinox==2000) {
                        mycoordsys:='J2000';
                } else if (equinox==1950) {
                        mycoordsys:='B1950';
                };
        };

        ptab:=table(tab.getkeyword('POINTING'),ack=F);
        psubt:=ptab.query('TIME<=($_stoptime) && TIME>=($_starttime)');
        dirs:=psubt.getcol('DIRECTION');
	ok:=ptab.done();
	ok:=psubt.done();
	
	long:=dq.quantity(dirs[1,,],'rad');
	long:=dq.convert(long,'deg');

	lat:=dq.quantity(dirs[2,,],'rad');
	lat:=dq.convert(lat,'deg');

	minx:=min(long.value);maxx:=max(long.value);
	miny:=min(lat.value); maxy:=max(lat.value); meany:=mean(lat.value);
	mindir:=dm.direction('j2000',dq.quantity(minx,'deg'),
		dq.quantity(miny,'deg'));
	maxdir:=dm.direction('j2000',dq.quantity(maxx,'deg'),
		dq.quantity(maxy,'deg'));

	direc:=dm.direction('j2000',long,lat);
	dir_native:=dm.measure(direc,mycoordsys);
	maxnatx:=max(dir_native.m0.value);
	minnatx:=min(dir_native.m0.value);
	maxnaty:=max(dir_native.m1.value);
	minnaty:=min(dir_native.m1.value);

	mindir_nat:=dm.direction(mycoordsys,dq.quantity(minnatx,'rad'),
		dq.quantity(minnaty,'rad'));
	maxdir_nat:=dm.direction(mycoordsys,dq.quantity(maxnatx,'rad'),
		dq.quantity(maxnaty,'rad'));
	dq.setformat('long','hms');
	dq.setformat('lat','dms');
	print '----------- '
	print 'BLC of map: ',dm.dirshow(mindir);
	print 'TRC of map: ',dm.dirshow(maxdir);
	print '   Mapping coords:  ';
	if (mycoordsys!='J2000' && mycoordsys!='B1950') {
		dq.setformat('long','dms');
	} else {	
		dq.setformat('long','hms');
	};
	print 'BLC of map: ',dm.dirshow(mindir_nat);
	print 'TRC of map: ',dm.dirshow(maxdir_nat);
	print '----------- '
#	deltax:=abs(maxx-minx)*60.
#	deltax*:=cos(meany*pi/180.);	
#	deltay:=abs(maxy-miny)*60.
	if (maxdir_nat.m0.value < mindir_nat.m0.value) {
	    # x-coordinate wraps
	    deltax:=abs(maxdir_nat.m0.value+360.0-mindir_nat.m0.value)*(180./pi)*60.;
	} else {
	    deltax:=abs(maxdir_nat.m0.value-mindir_nat.m0.value)*(180./pi)*60.;
	}
	deltax:=deltax*cos(meany*pi/180.);
        deltay:=abs(maxdir_nat.m1.value-mindir_nat.m1.value)*(180./pi)*60.
	if (is_boolean(center) && center) {
	    if (maxdir_nat.m0.value < mindir_nat.m0.value) {
		# x-coordinate wraps
		ra := (180.0/pi)*(maxdir_nat.m0.value+360.0 + mindir_nat.m0.value)/2.0;
	    } else {
		ra := (180.0/pi)*(maxdir_nat.m0.value + mindir_nat.m0.value)/2.0;
	    }
	    dec := (180.0/pi)*(maxdir_nat.m1.value + mindir_nat.m1.value)/2.0;
	} else {
	    ra := rec.other.gbt_go.MAJOR;
	    dec := rec.other.gbt_go.MINOR;
	}
	ra:=spaste(ra,'deg');
	dec:=spaste(dec,'deg');
	if (is_fail(ra) | is_fail(dec)) {
	    print "ERROR: No map center position found";
	    ok:=tab.done();
	    return F;
	}
        dir:=dm.direction(mycoordsys,ra,dec);
        restf:=rec.data.desc.restfrequency;
        cellsize:=0.5*((2.9979e8/(100.*restf))*206265)/60.
	if (is_boolean(cellx) || is_boolean(celly)) {
           cellarcmin:=dq.quantity(cellsize,'arcmin');
	   cellx:=cellarcmin;
	   celly:=cellarcmin;
        } else {
	   if (is_string(cellx) && is_string(celly)) {
	      cellx:=cellx;
	      celly:=celly;
	   } else {
	      print 'ERROR: Bad values for cellx, celly';
	      ok:=tab.done();
              return F;
	   };
	};
        gridx:=as_integer(deltax/cellsize);
        if (gridx%2!=0) gridx +:=1;
        gridy:=as_integer(deltay/cellsize);
	if (is_boolean(nx) || is_boolean(ny)) {
	   nx:=gridx+3
	   ny:=gridy+3
	} else {
	   nx:=nx
	   ny:=ny
        };
	if (nx%2!=0) nx+:=1;
	if (ny%2!=0) ny+:=1;
        if (gridy%2!=0) gridy +:=1;
        dl.note('Cell size is ',cellx,' x ',celly);
        dl.note('Map size is ',deltax,' arcmin by ',deltay,' arcmin');
        dl.note('Grid sizes are ',nx,' ',ny);

	mynchan:=stop-start;
	myplane:=mynchan/step;
        myim:=imager(msname);
#
        myim.setdata(mode='channel',start=start,step=1,nchan=mynchan,fieldid=fi,
		spwid=swi[swi==spwid]);
	if (len(fi)>1) fi:=fi[1];
        myim.setimage(nx=nx,ny=ny,cellx=cellx,celly=celly,
                stokes='I',spwid=swi[swi==spwid],fieldid=fi,start=start,
		step=step, mode='channel',nchan=myplane,
		phasecenter=dir,doshift=T);
        myim.weight('natural');
        myim.setoptions(ftmachine='sd',gridfunction=gridfn);
	if (!is_boolean(convsupport)) myim.setsdoptions(convsupport=convsupport);
        myim.makeimage(image=imname,type='singledish');
	ok:=myim.done();
        im:=image(imname);
        im.setbrightnessunit('K');
        ok:=im.done();
	ok:=tab.done();
        ok:=rmname.lock(0);
	if (!ok) dl.note(spaste('Failed to re-acquire lock on ',
				public.files(T).filein),
			 priority='WARNING');
	return T;
};

const public.imagems := function(msname,start,stop,step=1,
                imname='scanimage',spwid=F,nx=F,ny=F,cellx=F,celly=F,
                gridfn='BOX',convsupport=F,center=F) {
        wider public;
        include 'imager.g';

	if (sum(['SF','BOX','PB'] == gridfn) == 0) {
	    gridfn := 'SF';
	    dl.log(message='Unrecognized gridfn, using BOX', priority='WARN', postcli=T);
	}

	# set appropriate convsupport
	if (is_boolean(convsupport) || !is_numeric(convsupport)) {
	    # default for BOX - set it to 0.
	    if (gridfn == 'BOX') convsupport := 0;
	    else {
		if (gridfn == 'SF') convsupport := 1;
		else convsupport := F;
	    }
	} else if (!is_integer(convsupport)) {
	    convsupport := as_integer(convsupport+0.001);
	    dl.log(message=spaste('convsupport needs to be an integer - rounded to :',convsupport),
		   postcli=T,priority='WARN');
	}
	    
	ok:=public.open(msname);
	scan:=public.listscans()[1];
	sddata:=public.getscan(scan);
	rec:=ref sddata;
        tmp:=rec.other.data_description.SPECTRAL_WINDOW_ID+1;
        if (is_boolean(spwid)) {
                spwid:=tmp;
        };
        nativeunits:=sddata.data.desc.chan_freq.unit;
        xaxis:=dq.quantity(sddata.data.desc.chan_freq.value,
                nativeunits);
        restfreq:=dq.quantity(sddata.data.desc.restfrequency,'Hz');
        msname:=eval(public.files(T).filein).name();

        #technique to avoid sticky table locking issues
        rmname:=eval(public.files(T).filein)
        ok:=rmname.unlock();
        tab:=table(msname,ack=F);
        if (is_fail(tab)) {
		print 'table creation failed';
		return F;
	};
        fi:=unique(tab.getcol('FIELD_ID'))+1;
        ddi:=unique(tab.getcol('DATA_DESC_ID')+1);#needed for spec win id
        ddt:=table(tab.getkeyword('DATA_DESCRIPTION'),ack=F);
        swi:=(ddt.getcol('SPECTRAL_WINDOW_ID')[ddi])+1;
        mytimes:=tab.getcol('TIME');
        global _starttime:=min(mytimes);
        global _stoptime:=max(mytimes);
        ok:=ddt.done();
        if (has_field(rec.other,'gbt_go')) {
           gorec:=rec.other.gbt_go;
        } else {
           ok:=rmname.lock();
           dl.log(message='No Go record in scan data',priority='SEVERE',postcli=T);
	   ok:=tab.done();
           return F;
        };
        gnames:=field_names(gorec);
        if (any(gnames=='RADECSYS')) {
                radecsys:=gorec.RADECSYS;
        } else {
                radecsys:=gorec.RADESYS;
        };
        if (any(gnames=='COORDSYS')) {
           mycoordsys:=gorec.COORDSYS;
        } else {
           mycoordsys:=radecsys;
        };
        if (!any(gnames=='EQUINOX')) {
                dl.note('No EQUINOX found; if coordinates are not Galactic, there will be errors',priority='WARN');
        } else {
                equinox :=gorec.EQUINOX;
        };
        if (mycoordsys=='RADEC') {
                if (equinox==2000) {
                        mycoordsys:='J2000';
                } else if (equinox==1950) {
                        mycoordsys:='B1950';
                };
        };
        ptab:=table(tab.getkeyword('POINTING'),ack=F);
        dirs:=ptab.getcol('DIRECTION');
        ok:=ptab.done();
        long:=dq.quantity(dirs[1,,],'rad');
        long:=dq.convert(long,'deg');

        lat:=dq.quantity(dirs[2,,],'rad');
        lat:=dq.convert(lat,'deg');
        minx:=min(long.value);maxx:=max(long.value);
	# watch for coordinate wrap in x
	if ((maxx - minx) > (360.0+minx - maxx)) {
	    tmp := maxx;
	    maxx := minx;
	    minx := tmp;
	}
        miny:=min(lat.value); maxy:=max(lat.value); meany:=mean(lat.value);
        mindir:=dm.direction('j2000',dq.quantity(minx,'deg'),
                dq.quantity(miny,'deg'));
        maxdir:=dm.direction('j2000',dq.quantity(maxx,'deg'),
                dq.quantity(maxy,'deg'));

        direc:=dm.direction('j2000',long,lat);
        dir_native:=dm.measure(direc,mycoordsys);
        maxnatx:=max(dir_native.m0.value);
        minnatx:=min(dir_native.m0.value);
        maxnaty:=max(dir_native.m1.value);
        minnaty:=min(dir_native.m1.value);

        mindir_nat:=dm.direction(mycoordsys,dq.quantity(minnatx,'rad'),
                dq.quantity(minnaty,'rad'));
        maxdir_nat:=dm.direction(mycoordsys,dq.quantity(maxnatx,'rad'),
                dq.quantity(maxnaty,'rad'));
        dq.setformat('long','hms');
        dq.setformat('lat','dms');
        print '----------- '
        print 'BLC of map: ',dm.dirshow(mindir);
        print 'TRC of map: ',dm.dirshow(maxdir);
        print '   Mapping coords:  ';
         if (mycoordsys!='J2000' && mycoordsys!='B1950') {
                dq.setformat('long','dms');
        } else {
                dq.setformat('long','hms');
        };
        print 'BLC of map: ',dm.dirshow(mindir_nat);
        print 'TRC of map: ',dm.dirshow(maxdir_nat);
        print '----------- ';
#       deltax:=abs(maxx-minx)*60.;
#       deltax*:=cos(meany*pi/180.);
#       deltay:=abs(maxy-miny)*60.;
	if (maxdir_nat.m0.value < mindir_nat.m0.value) {
	    # x-coordinate wraps
	    deltax:=abs(maxdir_nat.m0.value+360.0-mindir_nat.m0.value)*(180./pi)*60.;
	} else {
	    deltax:=abs(maxdir_nat.m0.value-mindir_nat.m0.value)*(180./pi)*60.;
	}
	deltax:=deltax*cos(meany*pi/180.);
        deltay:=abs(maxdir_nat.m1.value-mindir_nat.m1.value)*(180./pi)*60.
	if (is_boolean(center) && center) {
	    if (maxdir_nat.m0.value < mindir_nat.m0.value) {
		# x-coordinate wraps
		ra := (180.0/pi)*(maxdir_nat.m0.value+360.0 + mindir_nat.m0.value)/2.0;
	    } else {
		ra := (180.0/pi)*(maxdir_nat.m0.value + mindir_nat.m0.value)/2.0;
	    }
	    dec := (180.0/pi)*(maxdir_nat.m1.value + mindir_nat.m1.value)/2.0;
	} else {
	    ra := rec.other.gbt_go.MAJOR;
	    dec := rec.other.gbt_go.MINOR;
	}
	ra:=spaste(ra,'deg');
	dec:=spaste(dec,'deg');
	if (is_fail(ra) | is_fail(dec)) {
	    print "ERROR: No map center position found";
	    ok:=tab.done();
	    return F;
	}
        dir:=dm.direction(mycoordsys,ra,dec);
        restf:=rec.data.desc.restfrequency;
        cellsize:=0.5*((2.9979e8/(100.*restf))*206265.0)/60.;
        if (is_boolean(cellx) || is_boolean(celly)) {
           cellarcmin:=dq.quantity(cellsize,'arcmin');
           cellx:=cellarcmin;
           celly:=cellarcmin;
        } else {
           if (is_string(cellx) && is_string(celly)) {
              cellx:=cellx;
              celly:=celly;
           } else {
              print 'ERROR: Bad values for cellx, celly';
	      ok:=tab.done();
              return F;
           };
        };
        gridx:=as_integer(deltax/cellsize);
        if (gridx%2!=0) gridx +:=1;
        gridy:=as_integer(deltay/cellsize);
        if (is_boolean(nx) || is_boolean(ny)) {
           nx:=gridx+5
           ny:=gridy+5
        } else {
           nx:=nx
           ny:=ny
        };
        if (nx%2!=0) nx+:=1;
        if (ny%2!=0) ny+:=1;
        if (gridy%2!=0) gridy +:=1;
        dl.note('Cell size is ',cellx,' x ',celly);
        dl.note('Map size is ',deltax,' arcmin by ',deltay,' arcmin');
        dl.note('Grid sizes are ',nx,' ',ny);

        mynchan:=stop-start;
        myplane:=mynchan/step;
        myim:=imager(msname);
#

        myim.setdata(mode='channel',start=start,step=1,nchan=mynchan,fieldid=fi,
                spwid=swi[swi==spwid]);
	if (len(fi)>1) fi:=fi[1];
        myim.setimage(nx=nx,ny=ny,cellx=cellx,celly=celly,
                stokes='I',spwid=swi[swi==spwid],fieldid=fi,start=start,
                step=step, mode='channel',nchan=myplane,
                phasecenter=dir,doshift=T);
        myim.weight('natural');
        myim.setoptions(ftmachine='sd',gridfunction=gridfn);
	if (!is_boolean(convsupport)) {
	    myim.setsdoptions(convsupport=convsupport);
	}
        myim.makeimage(image=imname,type='singledish');
	ok:=myim.done();
	im:=image(imname);
	im.setbrightnessunit('K');
	ok:=im.done();
        ok:=tab.done();
        ok:=rmname.lock(0);
        if (!ok) dl.note(spaste('Failed to re-acquire lock on ',
                                public.files(T).filein),
                         priority='WARNING');
        return T;
};

const public.lkmap := function(csys='J2000',skycat=F,scan=F,proc=T) {
  wider public;
  msname:=public.files(T).filein;
  fullname:=eval(msname).name();
  if (is_boolean(msname)) {
        dl.log(priority='SEVERE',message='No file opened',postcli=T);
        return F;
  };
  if (!is_boolean(scan)) {
     ok:=any(public.listscans()==scan[1]);
     if (ok==F) {
        dl.log(message='No such scan',priority='SEVERE',postcli=T);
        return F;
     };
     sddata:=public.getscan(scan[1]);
     rec:=ref sddata;
     sname:=rec.header.source_name;
     if (has_field(rec.other,'gbt_go') & proc) {
        if (len(scan)>1) {
	   dl.log(priority='SEVERE',message='Scan must be scalar if operating on a procedure',postcli=T);
	   return F;
	};
        endscan:=scan+(rec.other.gbt_go.PROCSIZE-1);
        trysequence:=scan:endscan;
        mssequence:=public.listscans();
        realsequence:=mssequence[mssequence>=scan & mssequence<=endscan];
        if (len(trysequence)!=len(realsequence)) {
           print 'WARNING: Not all scans in the procedure are present';
           trysequence:=realsequence;
        };
     } else {
	trysequence:=scan;
     };
  } else {
     #do whole MS
     scan:=public.listscans()[1];
     sddata:=public.getscan(scan);
     rec:=ref sddata;
     sname:=rec.header.source_name;
     trysequence:=public.listscans();
  };

  #get times for indexing POINTING table
  main_tab:=table(fullname,ack=F);
  if (is_fail(main_tab)) print 'table creation failed';
  global scanlist:=trysequence;
  subt:=main_tab.query('SCAN_NUMBER in $scanlist');
  mytimes:=subt.getcol('TIME');
  global _starttime:=min(mytimes);
  global _stoptime:=max(mytimes);
  ok:=subt.done();

  ptab:=table(main_tab.getkeyword('POINTING'),ack=F);
  poi:=ptab.query('TIME<=($_stoptime+1) && TIME>=($_starttime-1)');
  dir:=poi.getcol('DIRECTION');
  ok:=ptab.done();
  ok:=poi.done();

  long:=dq.quantity(dir[1,,],'rad');
  lat:=dq.quantity(dir[2,,],'rad');

  direc:=dm.direction('J2000',long,lat);

  map_direc:=dm.measure(direc,csys);

  coords:=dm.getvalue(map_direc);

  if (csys!='GALACTIC') {
	longh:=dq.convert(coords[1],'s').value;
  	if (longh<0) longh+:=24*60*60;
  } else {
	longh:=dq.convert(coords[1],'deg').value;
  };
  latd:=dq.convert(coords[2],'deg').value;
  #custom unit ::: doesn't work - convert to angular seconds by hand
  xmin:=min(longh);
  xmax:=max(longh);
  ymin:=min(latd);
  ymax:=max(latd);
  xmin-:=0.05*(xmax-xmin);
  xmax+:=0.05*(xmax-xmin);
  ymin-:=0.05*(ymax-ymin);
  ymax+:=0.05*(ymax-ymin);

  #set up plotter
  overstate:=public.plotter.overlay->state();
  if (!overstate) {
	public.plotter.page();
  	public.plotter.svp(0.1,0.9,0.1,0.9);
  	public.plotter.swin(xmin,xmax,ymin,ymax);
        if (csys!='GALACTIC') {
	   public.plotter.tbox('zyxhbncsto',0,0,'xdbcnsto',0,0);
        } else {
 	   public.plotter.tbox('xdbcnsto',0,0,'xdbcnsto',0,0);
        };
  }; #end overlay conditional
  for (i in 1:len(longh)) {
      public.plotter.ptxt(longh[i],latd[i],0,0.5,'+');
  };

  public.plotter.lab(csys,csys,spaste('Look Map -- ',sname))

  if (skycat) {
# for output table and skycatalog
     dq.setformat('long','hms');
     dq.setformat('lat','dms');
     vals:=dm.dirshow(map_direc);
     lvals:=len(vals)-1;
     typename:='POINT';
     long_string:=vals[1:(lvals/2)];
     lat_string:=vals[((lvals/2)+1):lvals];
     diskfile:=spaste(msname,'_lm');
     fp:=open([">>",diskfile]);
     fprintf(fp,'%s \n','Name     X            Y');
     fprintf(fp,'%s \n','A        A            A  ');
     for (i in 1:(lvals/2)) {
          fprintf(fp,'%s %s %s \n',typename,long_string[i],lat_string[i]);
     };
     include 'skycatalog.g';
     sca := skycatalog(spaste(diskfile,'_tbl'));
     sca.fromascii(asciifile=diskfile,hasheader=T,longcol='X',latcol='Y',
          dirtype=csys);
     sca.done();
     ok:=main_tab.done();
  };

  return T;
};

const public.gridmap := function(csys='J2000',skycat=F,scan=F,proc=T) {
  wider public;
  msname:=public.files(T).filein;
  fullname:=eval(msname).name();
  if (is_boolean(msname)) {
        dl.log(priority='SEVERE',message='No file opened',postcli=T);
        return F;
  };
  if (!is_boolean(scan)) {
     ok:=any(public.listscans()==scan[1]);
     if (ok==F) {
        dl.log(message='No such scan',priority='SEVERE',postcli=T);
        return F;
     };
     sddata:=public.getscan(scan);
     rec:=ref sddata;
     sname:=rec.header.source_name;
     if (has_field(rec.other,'gbt_go') & proc) {
        endscan:=scan+(rec.other.gbt_go.PROCSIZE-1);
        trysequence:=scan:endscan;
        mssequence:=public.listscans();
        realsequence:=mssequence[mssequence>=scan & mssequence<=endscan];
        if (len(trysequence)!=len(realsequence)) {
           print 'WARNING: Not all scans in the procedure are present';
           trysequence:=realsequence;
        };
     } else {
        trysequence:=scan;
     };
  } else {
     #do whole MS
     scan:=public.listscans()[1];
     sddata:=public.getscan(scan);
     rec:=ref sddata;
     sname:=rec.header.source_name;
     trysequence:=public.listscans();
  };

  #get times for indexing POINTING table
  main_tab:=table(fullname,ack=F);
  if (is_fail(main_tab)) print 'table creation failed';
  global scanlist:=trysequence;
  subt:=main_tab.query('SCAN_NUMBER in $scanlist');
  mytimes:=subt.getcol('TIME');
  global _starttime:=min(mytimes);
  global _stoptime:=max(mytimes);
  ok:=subt.done();

  ptab:=table(main_tab.getkeyword('POINTING'),ack=F);
  poi:=ptab.query('TIME<=($_stoptime+1) && TIME>=($_starttime-1)');
  dir:=poi.getcol('DIRECTION');
  ok:=ptab.done();
  ok:=poi.done();

  long:=dq.quantity(dir[1,,],'rad');
  lat:=dq.quantity(dir[2,,],'rad');

  direc:=dm.direction('J2000',long,lat);

  map_direc:=dm.measure(direc,csys);

  coords:=dm.getvalue(map_direc);

  if (csys!='GALACTIC') {
        longh:=dq.convert(coords[1],'s').value;
        if (longh<0) longh+:=24*60*60;
  } else {
        longh:=dq.convert(coords[1],'deg').value;
  };
  latd:=dq.convert(coords[2],'deg').value;
  #custom unit ::: doesn't work - convert to angular seconds by hand
  xmin:=min(longh);
  xmax:=max(longh);
  ymin:=min(latd);
  ymax:=max(latd);
  xmin-:=0.05*(xmax-xmin);
  xmax+:=0.05*(xmax-xmin);
  ymin-:=0.05*(ymax-ymin);
  ymax+:=0.05*(ymax-ymin);

  #set up plotter
  overstate:=public.plotter.overlay->state();
  if (!overstate) {
        public.plotter.page();
        public.plotter.svp(0.1,0.9,0.1,0.9);
        public.plotter.swin(xmin,xmax,ymin,ymax);
        if (csys!='GALACTIC') {
           public.plotter.tbox('zyxhbncsto',0,0,'xdbcnsto',0,0);
        } else {
           public.plotter.tbox('xdbcnsto',0,0,'xdbcnsto',0,0);
        };
  }; #end overlay conditional
  for (i in 1:len(longh)) {
      public.plotter.ptxt(longh[i],latd[i],0,0.5,'+');
  };

  public.plotter.lab(csys,csys,spaste('Grid Map -- ',sname))
  ok:=main_tab.done();

  return T;
};

  return T;
}
