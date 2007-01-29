# gbtcalutils: GBT calibration utilities (temporary only)
#
#   Copyright (C) 1998,1999,2000,2001,2002,2003
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
#   $Id: gbtcalutils.g,v 19.3 2004/06/15 16:35:39 bgarwood Exp $

#
#Available beam map test data
#
#gbtmsfiller project=zeroSpacing01 minscan=401 maxscan=441 msrootname='oriona1_' fillrawpointing=True
#gbtmsfiller project=zeroSpacing01 minscan=501 maxscan=541 msrootname='oriona2_'
#       fillrawpointing=True
#gbtmsfiller project=zeroSpacing01 minscan=601 maxscan=642 msrootname='oriona3_'
#       fillrawpointing=True
#gbtmsfiller project=zeroSpacing01 minscan=101 maxscan=301 msrootname='oriona4_'
#       fillrawpointing=True
#gbtmsfiller project=/home/aips++/data/nrao/GBT/pnt_prime_13 minscan=2350
#       maxscan=2424 msrootname='test_' fillrawpointing=True
#
#/aips++/data/demo/dishdemo/pnt_lowgreg_11_DCR = cygnus a
#gbtmsfiller help=prompt

#pragma include once

gbtcalutils := function() {

  include 'table.g';
  include 'image.g';
  include 'mathematics.g';
  include 'logger.g';
  include 'scripter.g';
  include 'polyfitter.g';

  private := [=];

  private.msname:=F;
  private.cellarcmin:=0;
  private.deltax:=0;
  private.deltay:=0;
  private.receptor:=99;
  private.poly:=polyfitter();

#
# Smooth a function using a running median filter
# (expensive but robust)
#
  private.smooth := function(x, width=5) {
    include 'statistics.g';
    newx := array(0.0, length(x));
    for (i in 1:length(x)) {
      newx[i] := median(x[max(1,(i-width)):min(length(x), (i+width))]);
      if(i%100==1) {
        print i, 'of ', length(x), ':', x[i], '->', newx[i];
      }
    }
    return newx;
  }

  public.checkms := function(msname) {
    wider private;	
    private.msname:=msname;
    corrt:=array(0,2,1);
    mstab := table(msname, ack=F);
    mskwds := mstab.keywordnames();
    gltabkw := 'GBT_GO';
    if (!any(mskwds==gltabkw)) {
	gltabkw := 'NRAO_GBT_GLISH';
    }
    gltab:=table(mstab.getkeyword(gltabkw), ack=F);
    if (is_fail(gltab)) {
	print 'ERROR: no GO information found';
	return F;
    };
    proc:=gltab.getcol('PROCTYPE')[1];
    gltab.done();
    if (proc!='map' && proc!='MAP') {
                print 'ERROR: Unrecognized procedure type';
    };
    iftab:=table(mstab.getkeyword('NRAO_GBT_IF'), ack=F);
    ifnames:=iftab.colnames();
    if (any(ifnames=='BANDWDTH')) {
       freq:=iftab.getcol('CENTER_SKY')[1];
       bw:=iftab.getcol('BANDWDTH')[1];
       pol:=iftab.getcol('POLARIZE')[1];
       private.old:=F;
    } else {
       freq:=iftab.getcol('center_sky')[1];
       bw:=iftab.getcol('bandwidth')[1];
       pol:=iftab.getcol('polarize')[1];
        private.old:=T;
    };
    iftab.done();

    if (pol=='R') {
	corrt := array([5,8],2,1);
	pol2:='L';
#        ptype:=array(["RR","LL"],2,1);
	 ptype:=pol;
    };
    if (pol=='L') {
	corrt := array([8,5],2,1);
	pol2:='R';
#        ptype:=array(["LL","RR"],2,1);
	 ptype:=pol;
    };
    if (pol=='X') {
	corrt := array([9,12],2,1);
	pol2:='Y';
#        ptype:=array(["XX","YY"],2,1);
	 ptype:=pol;
    }
    if (pol=='Y') {
	corrt := array([12,9],2,1);
	pol2:='X';
#        ptype:=array(["YY","XX"],2,1);
	 ptype:=pol;
    }

    if (sum(corrt) == 0) {
	print 'No correlation type -- can not reduce';
	return F;
    };

    ftab := table(mstab.getkeyword('FEED'), readonly=F, ack=F);
    pt := ftab.getcol('POLARIZATION_TYPE');
    if (pt[1] == '') {
#    pt[1:length(pt)%2==1]:=pol;
#    pt[1:length(pt)%2==0]:=pol2;
     pt[1:length(pt)]:=ptype;
     ok:= ftab.putcol('POLARIZATION_TYPE', pt);
     ok:=ftab.flush();
     private.msname:=msname;
     private.frequency:=freq;
#     return T;
    }
    ok:=ftab.done();


    ptab := table(mstab.getkeyword('POLARIZATION'), readonly=F, ack=F);
    ct := ptab.getcol('CORR_TYPE');
    if (ct[1] == 0) {
     ct[,]:=corrt;
     ptab.putcol('CORR_TYPE', ct);
     ptab.flush();
    }
    ptab.done();


    frtab := table(mstab.getkeyword('SPECTRAL_WINDOW'), readonly=F, ack=F);
    f := frtab.getcol('CHAN_FREQ');
    if (f[1]==0) {
     f[,]:=freq;
     f := frtab.getcol('REF_FREQUENCY');
     f:=array(freq, length(f));
     print frtab.putcol('REF_FREQUENCY', f);
     for (col in "RESOLUTION CHAN_WIDTH EFFECTIVE_BW") {
       r := frtab.getcol(col);
       r[r==r]:=bw;
       print frtab.putcol(col, r);
     }
     frtab.flush();
    }
    frtab.done();

    private.cellarcmin:=0.25*((2.9979e8/(100.*freq))*206265)/60

    poitab:=table(mstab.getkeyword('POINTING'), ack=F);
    dirs:=poitab.getcol('DIRECTION');
    poitab.done();
    private.deltax:=(max(dirs[1,,])-min(dirs[1,,]))*(180./pi)*60.;
    private.deltay:=(max(dirs[2,,])-min(dirs[2,,]))*(180./pi)*60.;
    mstab.done();

    return T;

  }

  public.setdata:=function(msname) {
        wider public;
        return public.checkms(msname);
  }

  public.contcal:=function(tcal=1.0,average=T,baseline=F,nfit=0,range=20) {
    wider private;
    include 'imager.g';
    msname:=private.msname;
    if (is_boolean(msname)) {
        print 'ERROR: No data set; setdata must be run first!';
        return F;
    };
    tab := table(msname, readonly=F, ack=F);
    scans:=tab.getcol('SCAN_NUMBER');
    scanlist:=unique(scans);
    private.tabnames:=tab.colnames();
    data:=tab.getcol('FLOAT_DATA');
    rowlength:=data::shape[3]/len(scanlist);
    bestate:=tab.getcol('NRAO_GBT_STATE_ID');
    if (any(private.tabnames=='NRAO_GBT_RECEIVER_ID')) {
       rxstate:=tab.getcol('NRAO_GBT_RECEIVER_ID');
    } else {
       rxstate:=tab.getcol('NRAO_GBT_SAMPLER_ID');
    };
    bigindex:=1:data::shape[3];
    phase1:=(rxstate==0 & bestate==0);
    index1:=bigindex[phase1];
    phase2:=(rxstate==0 & bestate==1);
    index2:=bigindex[phase2];
    phase3:=(rxstate==1 & bestate==0);
    index3:=bigindex[phase3];
    phase4:=(rxstate==1 & bestate==1);
    index4:=bigindex[phase4];
    data1:=tcal * ( ((data[index1]+data[index2])/2.)/(mean(data[index2]-data[index1])) - 1/2.);
    data2:=tcal * ( ((data[index3]+data[index4])/2.)/(mean(data[index4]-data[index3])) - 1/2.);
    if (average) {
       data1:=(data1+data2)/2.;
       data2:=data1;
    };
    data[index1]:=data1;
    data[index2]:=data1;
    data[index3]:=data2;
    data[index4]:=data2;
    if (range > 0 ) {
	bl:=100*(1/range);
    } else {
	dl.note('ERROR: Bad range');
	return F;
    };
    if (baseline) {
	bigarray:=array(0.0,rowlength,len(scanlist));
	for (i in 1:len(scanlist)) {
		bigarray[,i]:=data[scans==scanlist[i]];
        };
        nbeg1:=5;
        nend1:=(rowlength)/bl
        nbeg2:=(rowlength - nend1);
        nend2:=(rowlength)-5;
        range:=[5:nend1,nbeg2:nend2];
        ok:=private.poly.multifit(coeff=coeff,coefferrs=coefferrs,
	    chisq=chisq,x=range,y=bigarray[range,],order=nfit);
        ok:=private.poly.eval(y,1:rowlength,coeff);
	print '*** ',y::shape,len(y),(as_integer(rowlength)*len(scanlist));
        data[1:(as_integer(rowlength)*len(scanlist))] -:= y;
    };
#
    ok:=tab.putcol('CORRECTED_DATA',complex(data));
    tab.flush();
    tab.done();
    return T;
  };



#original calibration - replaced with above cal which is much faster
  public.contcal2:= function(tcal=1.0,receptor=1,baselinerm=F) {
    wider private;
    include 'imager.g';
    msname:=private.msname;
    private.receptor:=receptor;
    if (is_boolean(msname)) {
	print 'ERROR: No data set; setdata must be run first!';
	return F;
    };
#    im:=imager(msname);im.done();
    tab := table(msname, readonly=F, ack=F);
    private.tabnames:=tab.colnames();
    scanlist:=unique(tab.getcol('SCAN_NUMBER'));
    for (i in scanlist) {
        subt:=tab.query(spaste('SCAN_NUMBER==',i));
        phases := [=];
        if (any(private.tabnames=='NRAO_GBT_RECEIVER_ID')) {
        phases[1] :=subt.query('NRAO_GBT_RECEIVER_ID==0&&NRAO_GBT_STATE_ID==0');
        phases[2] :=subt.query('NRAO_GBT_RECEIVER_ID==0&&NRAO_GBT_STATE_ID==1');
        phases[3] :=subt.query('NRAO_GBT_RECEIVER_ID==1&&NRAO_GBT_STATE_ID==0');
        phases[4] :=subt.query('NRAO_GBT_RECEIVER_ID==1&&NRAO_GBT_STATE_ID==1');
        } else {
        phases[1] :=subt.query('NRAO_GBT_SAMPLER_ID==0&&NRAO_GBT_STATE_ID==0');
        phases[2] :=subt.query('NRAO_GBT_SAMPLER_ID==0&&NRAO_GBT_STATE_ID==1');
        phases[3] :=subt.query('NRAO_GBT_SAMPLER_ID==1&&NRAO_GBT_STATE_ID==0');
        phases[4] :=subt.query('NRAO_GBT_SAMPLER_ID==1&&NRAO_GBT_STATE_ID==1');
        };

        times := [=];
        data := [=];
        for (j in 1:4) {
          times[j]  := phases[j].getcol('TIME');
          times[j] -:= min(times[j]);
          data[j]   := phases[j].getcol('FLOAT_DATA');
        }
#	kludge in the proper phase for now;
	if (receptor==1) {
	  recphase:=1;
          data[recphase]:= (data[recphase+1]+ data[recphase]) / 2;
          data[recphase]:= data[recphase]/mean(data[recphase+1]-data[recphase]);
          data[recphase]:= data[recphase] - 1.0/2.0;
	  data[recphase]*:= tcal;
	} else if (receptor==2) {
	  recphase:=3;
          data[recphase]:= (data[recphase+1]+ data[recphase]) / 2;
          data[recphase]:= data[recphase]/mean(data[recphase+1]-data[recphase]);
          data[recphase]:= data[recphase] - 1.0/2.0;
          data[recphase]*:= tcal;
	} else if (receptor=='b') {
          recphase:=1;
          data[recphase]:= (data[recphase+1]+ data[recphase]) / 2;
          data[recphase]:= data[recphase]/mean(data[recphase+1]-data[recphase]);
          data[recphase]:= data[recphase] - 1.0/2.0;
          data[recphase]*:= tcal;
          recphase2:=3;
          data[recphase2]:= (data[recphase2+1]+ data[recphase2]) / 2;
          data[recphase2]:=data[recphase2]/mean(data[recphase2+1]-
		data[recphase2]);
          data[recphase2]:= data[recphase2] - 1.0/2.0;
          data[recphase2]*:= tcal;
	  bothpols:=(data[recphase]+data[recphase2])/2.
	  data[recphase]:=data[recphase2]:=bothpols;
	};



#       do a baseline fit
        if (baselinerm) {
           nbeg1:=5;
           nend1:=(data[recphase]::shape[3])/5
           nbeg2:=(data[recphase]::shape[3] - nend1);
           nend2:=(data[recphase]::shape[3])-5;
           #print 'ns ',nbeg1,nend1,nbeg2,nend2;
           y:=[data[recphase][nbeg1:nend1],data[recphase][nbeg2:nend2]];
           x:=[[5:nend1],[nbeg2:nend2]];
           ok:=private.poly.fit(coeff,coefferrs,chisq,x,y,order=2);
           ok:=private.poly.eval(y2,1:data[recphase]::shape[3],coeff);
           data[recphase][1,1,] -:= y2;
        }


        ok:=phases[recphase].putcol('CORRECTED_DATA',complex(data[recphase]));
	subt.flush();
	subt.done();
   };
   tab.flush();
   tab.done();
   return T;
  }
       

  public.makeimage := function(iname='scanimage',gridfn='SF',receptor=1) {
	wider private;
	include 'imager.g';
	msname:=private.msname;
   	if (is_boolean(msname)) {
      		print 'ERROR: No data set; setdata must be run first!';
        	return F;
  	};
	tab:=table(msname, ack=F);
	private.tabnames:=tab.colnames();
	myim:=imager(msname);
	dum:=dos.dir();
	if (any(dum==iname)) {
		ok:=shell(spaste('rm -r ',iname));
	};

	if (any(private.tabnames=='NRAO_GBT_RECEIVER_ID')) {
	msselector:=spaste('NRAO_GBT_RECEIVER_ID==',(receptor-1),
			' && NRAO_GBT_STATE_ID==0');
	} else { 
	msselector:=spaste('NRAO_GBT_SAMPLER_ID==',(receptor-1),
                       ' && NRAO_GBT_STATE_ID==0');
	}
 	ok:=myim.setdata(fieldid=1,spwid=1,msselect=msselector);
	kwnames := tab.keywordnames();
	gtabkw := 'GBT_GO';
	if (!any(kwnames==gtabkw)) {
	    # try older name
	    gtabkw := 'NRAO_GBT_GLISH';
	}
	gtab:=table(tab.getkeyword(gtabkw), ack=F);
	if (is_fail(gtab)) {
	    print "ERROR: There is no GO FITS file for this data";
	    tab.done();
	    myim.done();
	    return F;
	}
#
	gnames:=gtab.colnames();
	if (any(gnames=='RADECSYS')) {
		radecsys:=gtab.getcol('RADECSYS')[1];
	} else {
		radecsys:=gtab.getcol('RADESYS')[1];
	};
	if (any(gnames=='COORDSYS')) {
	   mycoordsys:=gtab.getcol('COORDSYS')[1];
	} else {
	   mycoordsys:=radecsys;
	};
	if (!any(gnames=='EQUINOX')) {
		dl.note('WARNING: No EQUINOX found; if coordinates are not Galactic, there will be errors');
	} else {
		equinox :=gtab.getcol('EQUINOX')[1];
	};
#
	if (mycoordsys=='RADEC') {
		if (equinox==2000) {
			mycoordsys:='J2000';
		} else if (equinox==1950) {
			mycoordsys:='B1950';
		};
	};
	if (!any(gnames=='MAJOR')) {
           ra:=spaste(gtab.getcol('RAJ2000')[1],'deg');
           dec:=spaste(gtab.getcol('DECJ2000')[1],'deg');
	} else {
	   ra:=spaste(gtab.getcol('MAJOR')[1],'deg');
           dec:=spaste(gtab.getcol('MINOR')[1],'deg');
	};
        if (is_fail(ra) | is_fail(dec)) {
             print "ERROR: No map center position found";
	     tab.done();
	     gtab.done();
	     myim.done();
             return F;
        };
        gtab.done();
	dir:=dm.direction(mycoordsys,ra,dec);
#
	cellsize:=spaste(private.cellarcmin,'arcmin');
	gridx:=as_integer(private.deltax/private.cellarcmin);
	if (gridx%2!=0) gridx +:=1;
	gridy:=as_integer(private.deltay/private.cellarcmin);
	if (gridy%2!=0) gridy +:=1;
	dl.note('Cell size is ',cellsize);
	dl.note('Map size is ',private.deltax,' by ',private.deltay);
	dl.note('Grid sizes are ',gridx,' ',gridy);
   	ok:=myim.setimage(nx=gridx,ny=gridy,cellx=cellsize,celly=cellsize,
			stokes='I',doshift=T,phasecenter=dir,spwid=1);
	ok:=myim.setoptions(ftmachine='sd',gridfunction=gridfn);
	ok:=myim.weight('natural');
	myim.makeimage(image=iname,type='singledish');
#	myim.makeimage(image=spaste(iname,'_weight'),type='coverage');
        private.imname:=iname;
#	private.wname:=spaste(iname,'_weight');
	tab.done();
	ok:=myim.done();
#	im:=image(iname);
#	im.stats();
#	im.view(raster=T);
	return ok;
  }

  public.covercorr := function(imname=F,wname=F) {
	#normalize the image, threshold coverage image to avoid
	#non-sampled points
#	wider private;
#	if (is_boolean(imname)&is_boolean(wname)) {
#		imname:=private.imname;
#		wname:=private.wname;
#	};
#	if (is_boolean(imname)) {
#		print 'ERROR: image not found';
#		return F;
#	}
#	outname:=spaste(imname,'_corr');
#        imcov:=image(wname);
#	s:=0;
#	ok:=imcov.statistics(s);
#	threshold:=s.max/10.;
#	mystring:=spaste(imname,'[',wname,'>',threshold,']/',wname,'[',wname,
#		'>',threshold,']');
#	im:=imagecalc(outname,pixels=mystring);
	print 'No longer necessary - deprecated';
	return T;
   }
	
  public.plotsource := function(imname,nsource=1) {
	wider private;
        #adding a source position
	include 'table.g';
	include 'image.g';
	im:=image(imname);
	tcol1 := tablecreatescalarcoldesc("Annotation","typeisstring");
	tcol2 := tablecreatescalarcoldesc("Type","J2000");
	tcol3 := tablecreatescalarcoldesc("Long",as_float(0.0));
	tcol4 := tablecreatescalarcoldesc("Lat",as_float(0.0));
	shell('rm -r tst.tbl');
	td:=tablecreatedesc(tcol1,tcol2,tcol3,tcol4);
	tbl:=table("tst.tbl", tabledesc=td, readonly=F, ack=F);
	

	cl:=im.findsources(nsource,0.1);
	if (is_fail(cl) || cl.length() == 0) {
		fail 'no sources found';
	}
	rec:=[=]
	for (i in 1:cl.length()) {
	   rec[i].dirref := dm.getref(cl.getrefdir(1));
	   rec[i].long := as_float(cl.getrefdirra(1,'deg'));
 	   rec[i].lat := as_float(cl.getrefdirdec(1,'deg'));
	   rec[i].unit := 'deg';
	   # give each source an name with increment
	   rec[i].annotation := spaste('Source',i);
        }

	longunit:=rec[1].unit;
	latunit:=rec[1].unit;
 	tbl.putcolkeyword('Long','UNIT',longunit);
	tbl.putcolkeyword('Lat','UNIT',latunit);
	#Now fill in skeleton table with found sources
	for (i in 1:length(rec)) {
	   tbl.addrows();
	   tbl.putcell('Annotation',i,rec[i].annotation);
	   tbl.putcell('Type',i,rec[i].dirref);
	   tbl.putcell('Long',i,rec[i].long);
	   tbl.putcell('Lat',i,rec[i].lat);
	}

	dp := dv.newdisplaypanel(); # create a Display Panel
	dd := dv.loaddata(im,'raster'); # load our image
	dd2:= dv.loaddata(im,'contour');
	dt := dv.loaddata(tbl,'skycatalog'); # load our table
	## register the image and table
	dp.register(dd);
	dp.register(dd2);
	dp.register(dt);
	# make the Annotation string visible and make the font bigger
	# This can also be done in the Adjust gui
        dt.setoptions([namecolumn=[value="Annotation"],
		labelcharsize=[value=1.5]]);
	tbl.done();
	return T;

  }

  public.debug := function() {
	wider private;
	return private;
  }

  return ref public;

}

const gc := gbtcalutils();

dl.note('gbtcalutils (gc) is ready for use');
dl.note('gc tools: setdata');
dl.note('        : contcal');
dl.note('        : makeimage');
dl.note('        : covercorr');
dl.note('        : plotsource');
