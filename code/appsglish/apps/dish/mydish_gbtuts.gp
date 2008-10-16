# GBT Cal Utilities	
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
#    $Id: mydish_gbtuts.gp,v 19.4.10.1 2006/11/28 18:48:00 bgarwood Exp $
#
#------------------------------------------------------------------------------

pragma include once

note('mydish_gbtuts.gp included');
#need:
#	Tsys spectrum calculator

  include 'table.g';
  include 'progress.g';
  include 'gbtmsfiller.g';
  include 'matrix.g';

#gbtuts_standard := [=];
mydish_gbtuts := [=];

#gbtuts_standard.attach := function(ref public) {
mydish_gbtuts.attach := function(ref public) {

  private:=[=];
  private.poly:=F;
  private.fftserver:=F;
  include 'polyfitter.g'
  private.poly:=polyfitter();
  private.tau:=F;
  public.uniput('tau',F);
  public.uniput('factor',1.0);
  private.etal:=1.0;
  private.eta:=1.0;
  private.etabeam:=1.0;

#non-decimating gaussian
    public.gaussian := function(myvec, fwhm, extent=5)
    {
        wider private,public;
        if (is_boolean(private.fftserver)) private.fftserver := fftserver();
        mystddev := fwhm / (sqrt(8.0*ln(2.0)));
        gxlimit := as_integer(extent*mystddev+0.5);
        g := array(0.,myvec::shape[1],(2*gxlimit+1));
        g[1,] := 1.0;
        g[1,] := [-gxlimit:gxlimit] / mystddev;
        g[1,] *:= g[1,];
        g[1,] /:= -2.;
        g[1,] := exp(g[1,]);
        g[1,] /:= (mystddev * sqrt(2. * pi));
        if (g::shape[1] > 1) for (i in 2:g::shape[1]) g[i,] := g[1,];
        result := myvec;
        # it should be possible to do this in one call to convolve,
        # but there appears to be a bug which make that impossible
        # do each stokes separately
        for (i in 1:myvec::shape[1])
            result[i,] :=  private.fftserver.convolve(myvec[i,], g[i,]);
#        if (g::shape[2] > myvec::shape[2]) {
            # just return the central portion of the result
            # the return vector is always of equal length to the input
            # vector - this may not be the most appropriate thing
            # to do
            # I believe this must always be an integer
#            offset := (g::shape[2] - myvec::shape[2])/2;
#            result := result[,(1+offset):(myvec::shape[1]+offset)];
#        }
        return result;
    }                                                                          

#non-decimating boxcar function
  public.boxcar := function(myvec, n) {
	wider public;
	nin:=myvec::shape[2];
	if (n>nin) {
		print 'FAIL: The width of boxcar is larger than data array';
		return F;
	};
	nstokes:=myvec::shape[1];
	if (n ==1) return myvec;
	nout:=nin;
	left:=as_integer((n-1)/2) + 1;
	right:=nin-left+1;
	if ((n-1)%2) {
		right -:= 1;
	};
	inc:=1;
	loc:=1;
	result:=array(0.0,myvec::shape[1],myvec::shape[2]);
	oloc:=loc;
	if (left <= right) {
            for (i in 1:myvec::shape[1]) {
                loc := oloc;
                for (j in left:right) {
                    result[i,j] := sum(myvec[i,loc:(loc+n-1)]);
                    loc +:= inc;
                }
            }
        }
        if (left>1) {
            for (i in 1:myvec::shape[1]) {
                for (j in 1:(left-1)) {
                 result[i,j]:=((left-j)*myvec[i,1]+sum(myvec[i,1:(left+j-1)]));
                }
            }
        }                                                                               if (right < nout) {
            for (i in 1:myvec::shape[1]) {
                for (j in (right+1):nout) {
                 result[i,j]:=((j-right)*myvec[i,nin]+
                                             sum(myvec[i,(right+j-nin):nin]));
                }
            }
        }
        result /:= n;
 
        return result;
    }                                                                           
  
# Needed for unijr - obtains information on scan
  public.qdumps := function(scan) {
	wider public;
        msname:=eval(public.files(T).filein).name();
        tab:=table(msname,ack=F);
        if (is_fail(tab)) print 'table creation failed';
	subt:=tab.query(spaste('SCAN_NUMBER==',scan));
	nsubscans:=subt.nrows();
	nphases:=len(unique(subt.getcol('NRAO_GBT_STATE_ID')));
	nspwin:=len(unique(subt.getcol('DATA_DESC_ID')));
	nfield:=len(unique(subt.getcol('FIELD_ID')));
	if (nspwin==1) nspwin:=0;
	if (nfield==1) nfield:=0;
#	need to deal with case of multiple spwins
	subt.done();
	tab.done();
	return [nsubscans, nphases, nspwin, nfield, (nsubscans/(nphases))];
  };

# Record based version of qdumps (better implementation)
  public.qscan := function(scan=F) {
        wider public;
	dum:=[=];
	qsprec:=public.qsp(scan);
	dum.rows:=len(qsprec.rownumbers);
	dum.phases:=len(qsprec.uphases);
	dum.ifs:=len(qsprec.uspwin);
	dum.field:=1.
	dum.ints:=qsprec.ints;
	dum.rownumbers:=qsprec.rownumbers;
        return dum;
  };

   public.import := function(projdir,outms=F,outmsdir=F,startscan=F,stopscan=F,backend=F,
			     calflag=F,vv=F,window=F,oneacsms=T,fixbadlags=F) {
       wider public,private;

       if (!dos.fileexists(projdir)) {
	   dl.log(message='That project directory does not exist',priority='SEVERE',postcli=T);
	   return F;
       }

       if (!(is_boolean(outms) || is_string(outms)) ||
	   !(is_boolean(outmsdir) || is_string(outmsdir)) ||
	   !(is_boolean(startscan) || is_integer(startscan)) ||
	   !(is_boolean(stopscan) || is_integer(stopscan)) ||
	   !is_boolean(oneacsms) || !is_boolean(fixbadlags)) {
	   dl.log(message='Inputs are invalid',priority='SEVERE',postcli=T);
	   return F;
       }

       # close any already open MSs that look like they are related to the
       # thing about to be filled.
       # This will currently miss selections, but most users aren't doing
       # that right now.  Ultimately the problem in sditerator that 
       # requires this needs to be found and fixed.
       removed := as_string([]);
       trueNames := as_string([]);
       if (public.rm().size() > 0) {
	   msroot := dos.basename(projdir);
	   if (!is_boolean(outms)) { msroot := outms;}
	   msroot := eval(spaste('m/',msroot,'/'));
	   # first pass, get the names, don't delete here since
	   # that changes the meaningn of "i"
	   for (i in 1:public.rm().size()) {
	       if (is_sditerator(public.rm().getvalues(i))) {
		   if (dos.basename(public.rm().getvalues(i).name()) ~ msroot) {
		       removed[len(removed)+1] := public.rm().getnames(i);
		       trueNames[len(trueNames)+1] :=
			   public.rm().getvalues(i).name();
		   }
	       }
	   }
	   if (len(removed) > 0) {
	       for (i in 1:len(removed)) {
		   public.close(removed[i]);
	       }
	   }
       }
       
       gmf:=gbtmsfiller();
       ok:=gmf.setproject(projdir);
       if (!is_boolean(outms)) ok:=gmf.setmsrootname(spaste(outms,'_'));
       if (!is_boolean(outmsdir)) ok:=gmf.setmsdirectory(outmsdir);
       if (!is_boolean(backend)) ok:=gmf.setbackend(backend);
       if (!is_boolean(startscan)) ok:=gmf.setminscan(startscan);
       if (!is_boolean(stopscan))  ok:=gmf.setmaxscan(stopscan);
       ok:=gmf.setoneacsms(oneacsms);
       ok:=gmf.setfixbadlags(fixbadlags);
       #vv options: "schwab", "old", "none"
       if (!is_boolean(vv)) ok:=gmf.setvv(vv);
       #window options: "hanning", "hamming", "none"
       if (!is_boolean(window)) ok:=gmf.setsmooth(window);
       ok:=gmf.fillall();
       if (is_fail(ok)) 
	   return throw(paste('The filler on project directory ',projdir,'failed'));
       mystatus:=gmf.status();
       # preference to single ACS MS or acs bank A or SP
       msname := '';
       if (mystatus.acs.ABCD.nrows > 0) {
	   msname := mystatus.acs.ABCD.ms;
       } else {
	   if (mystatus.acs.A.nrows > 0) {
	       msname := mystatus.acs.A.ms;
	   } else {
	       if (mystatus.sp.nrows > 0) {
		   msname := mystatus.sp.ms;
	       }
	   }
       }
       private.msname:=msname;
       # needs to do something more intelligent if msname is empty
       dl.note('Using ',msname);
	   
       gmf.done();
       ok:=public.open(msname,corrdata=T);
       if (calflag==T) {
	   ok:=public.mscal();
       };
       # open things that were removed
       if (len(trueNames) > 0) {
	   for (msname in trueNames) {
	       public.open(msname,filein=F);
	   }
       }
       return T;
   }

#fashion an SDRecord
  private.makesdr := function(x,y,myscan) {
                wider private;
                # create a temporary sditerator
                __ack__ := newsditerator('__ack__')
                # create an empty sdrecord
                ok:=__ack__.getempty(mytempsdr,len(x),1);
                if (!ok) return throw('FAILED: Can not create record');
                tempsdr:=ref mytempsdr;
                tempsdr.data.desc.chan_freq.value:=x;
		print 'x ',tempsdr.data.desc.chan_freq.value[1:5]
		tempsdr.data.desc.chan_freq.unit:="GHz"
                tempsdr.data.arr[1,]:=y;
 		tempsdr.data.flag[1,]:=F;
		tempsdr.data.weight[1,]:=1.0;
		tempsdr.header.direction:=myscan.header.direction
		tempsdr.header.source_name:='skydip'
		tempsdr.header.scan_number:=myscan.header.scan_number;
		tempsdr.header.resolution:=myscan.header.resolution 
		tempsdr.header.time:=myscan.header.time
	tempsdr.header.telescope_position:=myscan.header.telescope_position
		tempsdr.header.telescope:=myscan.header.telescope
                __ack__.done(); # get rid of __ack__ on disk;
                __ack__:=F;     # get rid of __ack__ in glish;
                return tempsdr;
  }

# Perform a tip measurement; use least-squares to derive opacity
# Initial plotting will be fine but if you return to it through the results
# manager - the scaling is off because DISH plotter fundamentally expects
# linear axis and we're plotting logs
# works only for a 4 phase TPwC scan
  public.tip1:=function(scan,cal_value=1.0) {
     wider private;
     msname:=eval(public.files(T).filein).name();
     tab:=table(msname,ack=F);
     if (is_fail(tab)) {
	print 'table creation failed';
	return F;
     };
     myscan:=public.getscan(scan);
     if (myscan.other.gbt_go.PROCNAME=='tipping') {
	print 'DCR tipping scan';
     } else {
	print 'Not a DCR tipping scan';
        return F;
     };

     scans:=tab.getcol('SCAN_NUMBER');
     scanmask:=scans==scan;

     poitab:=table(tab.getkeyword('POINTING'),ack=F);
     poitime:=poitab.getcol("TIME");
     subt:=tab.query(spaste('SCAN_NUMBER == ',as_string(scan)));
     if (subt.nrows() == 0) return throw('No Scans Found');
     ok:=tab.done(); #don't need this anymore
     subtime:=subt.getcol("TIME");
     tmask:=poitime>=min(subtime) & poitime<=max(subtime);
     direction:=poitab.getcol('DIRECTION');
     direction:=direction[,,tmask];
     ptime:=poitime[tmask];
     oktime:=dm.doframe(myscan.header.time);
     okpos:=dm.doframe(myscan.header.telescope_position);
     dec:=direction[2,]*180/pi;
     phases := [=];
     phases[1] :=subt.query('NRAO_GBT_RECEIVER_ID==0 && NRAO_GBT_STATE_ID==0');
     phases[2] :=subt.query('NRAO_GBT_RECEIVER_ID==0 && NRAO_GBT_STATE_ID==1'); 
     phases[3] :=subt.query('NRAO_GBT_RECEIVER_ID==1 && NRAO_GBT_STATE_ID==0');
     phases[4] :=subt.query('NRAO_GBT_RECEIVER_ID==1 && NRAO_GBT_STATE_ID==1');
     ok:=subt.done();
     data := [=];
     for (i in 1:4) {	
	data[i]:=phases[i].getcol('FLOAT_DATA');
     };
     counts_per_K1:= sum((data[2]-data[1])/cal_value) / length(data[2]);
     counts_per_K2:= sum((data[4]-data[3])/cal_value) / length(data[4]);
     cal_data1:=data[1]/counts_per_K1;
     cal_data2:=data[3]/counts_per_K2;
     rows:=(1:len(scans))[scanmask];
     nrows:=rows[rows%4==0];
     for (i in 1:len(nrows)) {
         standard_DCR2.setlocation(nrows[i]);  
         tmp:=standard_DCR2.get();      
         elev_deg[i]:=tmp.header.azel.m1.value*180./pi; 
     }
     myfit:=polyfitter();
     secz := 1.0 / sin(elev_deg / 57.2958)
ok := myfit.fit(coeff,coefferrs,chisq,secz,ln(cal_data1[1,1,]),order=1,sigma=1);
     newyarray:=coeff[2]*secz+coeff[1];
     note( '*** Tip Results                  ***',origin='tip');
     note( 'intercept is',coeff[1],' slope is ',coeff[2],origin='tip');
     ok:=public.uniput('tauz',coeff[2]);
     note( '************************************',origin='tip');
     temprec:=private.makesdr(secz,ln(cal_data1[1,1,]),myscan);
     temprec2:=private.makesdr(secz,newyarray,myscan);
     ok:=public.plotscan(temprec);
     ok:=public.plotscan(temprec2,overlay=T);
     ok:=public.rmadd(temprec,'skydip','A skydip observation');
     return;
  }

# Perform a tip measurement; use least-squares to derive opacity
# Initial plotting will be fine but if you return to it through the results
# manager - the scaling is off because DISH plotter fundamentally expects
# linear axis and we're plotting logs
# works only for a 4 phase TPwC scan
  public.tip:=function(scan,cal_value=1.0) {
     wider private;
     msname:=eval(public.files(T).filein).name();
     tab:=table(msname,ack=F);
     if (is_fail(tab)) {
        print 'table creation failed';
        return F;
     };
     myscan:=public.getscan(scan);
     if (myscan.other.gbt_go.PROCNAME=='tipping') {
        print 'DCR tipping scan';
     } else {
        print 'Not a DCR tipping scan';
        return F;
     };

     scans:=tab.getcol('SCAN_NUMBER');
     scanmask:=scans==scan;

     poitab:=table(tab.getkeyword('OINTING'),ack=F);
     poitime:=poitab.getcol("TIME");
     subt:=tab.query(spaste('SCAN_NUMBER == ',as_string(scan)));
     if (subt.nrows() == 0) return throw('No Scans Found');
     subtime:=subt.getcol("TIME");
     tmask:=poitime>=min(subtime) & poitime<=max(subtime);
     oktime:=dm.doframe(myscan.header.time);
     pos:=dm.observatory('GBT');
     okpos:=dm.doframe(pos);
     direction:=poitab.getcol('DIRECTION');
     direction:=direction[,,tmask];
     lat:=dq.quantity(direction[1,],'rad');
     long:=dq.quantity(direction[2,],'rad');
     latlon_meas:=dm.direction('J2000',lat,long);
     azel_meas:=dm.measure(latlon_meas,'azel');
     elev_deg1:=azel_meas.m1.value*180./pi;
#
#     rows:=(1:len(scans))[scanmask];
#     nrows:=rows[rows%4==0];
#     for (i in 1:len(nrows)) {
#         standard_DCR2.setlocation(nrows[i]);
#         tmp:=standard_DCR2.get();
#         elev_deg[i]:=tmp.header.azel.m1.value*180./pi;
#     }
#	print 'fast slow ',elev_deg1[1:10],elev_deg[1:10]
#
     phases := [=];
     phases[1] :=subt.query('NRAO_GBT_RECEIVER_ID==0 && NRAO_GBT_STATE_ID==0');
     phases[2] :=subt.query('NRAO_GBT_RECEIVER_ID==0 && NRAO_GBT_STATE_ID==1');
     phases[3] :=subt.query('NRAO_GBT_RECEIVER_ID==1 && NRAO_GBT_STATE_ID==0');
     phases[4] :=subt.query('NRAO_GBT_RECEIVER_ID==1 && NRAO_GBT_STATE_ID==1');
     data := [=];
     for (i in 1:4) {
        data[i]:=phases[i].getcol('FLOAT_DATA');
     };
     counts_per_K1:= sum((data[2]-data[1])/cal_value) / length(data[2]);
     counts_per_K2:= sum((data[4]-data[3])/cal_value) / length(data[4]);
     cal_data1:=data[1]/counts_per_K1;
     cal_data2:=data[3]/counts_per_K2;
     rows:=(1:len(scans))[scanmask];
     myfit:=polyfitter();
     secz := 1.0 / sin(elev_deg1[1:1000] / 57.2958)
ok := myfit.fit(coeff,coefferrs,chisq,secz,ln(cal_data1[1,1,1:1000]),order=1,sigma=1);
     newyarray:=coeff[2]*secz+coeff[1];
     note( '*** Tip Results                  ***',origin='tip');
     note( 'intercept is',coeff[1],' slope is ',coeff[2],origin='tip');
     ok:=public.uniput('tauz',coeff[2]);
     note( '************************************',origin='tip');
     temprec:=private.makesdr(secz,ln(cal_data1[1,1,]),myscan);
     temprec2:=private.makesdr(secz,newyarray,myscan);
     #print 'x here ',temprec.data.desc.chan_freq.value[1:5];
     ok:=public.plotscan(temprec);
     ok:=public.plotscan(temprec2,overlay=T);
     ok:=public.rmadd(temprec,'skydip','A skydip observation');
     return;
  }

public.adms:=function(msname=F,outname=F,scanlist=F) {
	wider public,private;
	if (is_boolean(scanlist)) {
		dl.log(message='Using all scans in MS',
		priority='NORMAL',postcli=T);
		scan:=public.gms(scans=T);
	} else {
		scan:=scanlist;
	};
	ok:=dl.log(message='Assuming all data is calibrated',
		priority='NORMAL',postcli=T);
        msname:=eval(public.files(T).filein).name();
        if (is_boolean(outname)) {
                outname:=spaste(msname,'_out');
        };
        rmname:=eval(public.files(T).filein)
        tab:=table(msname,readonly=F,ack=F);
	startrows:=F;
	ctr:=0;
	#average
	for (i in scan) {
            ctr +:= 1;
            #technique to avoid sticky table locking issues
            scanstats:=public.qscan(i);
            ok:=rmname.unlock(); #has a getscan so it locks it again!
            startrows[ctr]:=(scanstats.rownumbers[1])-1;
            global scanlist:=i;
            subtab:=tab.query('SCAN_NUMBER in $scanlist');
            mydata:=subtab.getcol('CORRECTED_DATA');
            myaver:=public.aver(i,spaste(1,'/',scanstats.ifs*scanstats.phases));
            mydata[,,1]:=myaver.data.arr;
            ok:=rmname.unlock();
            ok:=subtab.putcol('CORRECTED_DATA',mydata);
            subtab.flush();
            subtab.done();
        };
        tab.done();
	#decimate
	global rowids:=startrows;
	tab:=table(msname,ack=F);
	subt:=tab.query('rowid() in $rowids');
	subt.copy(outname,deep=T);
	subt.flush();
	subt.done();
	tab.done();
        ok:=rmname.lock(0);
	return T;
}; #end of average and decimate measurementset function

public.gms:=function(verbose=F,scans=F) {
        wider public,private;

	#need to deal with 3 cases: 1) GBT data, 2) flat table data, 3) other

        if (is_boolean(public.files(T).filein)) {
                dl.log(message='No MS specified - use filein,open or import',priority='SEVERE',postcli=T);
                return F;
        };

        msname:=eval(public.files(T).filein).name();
	rmname:=eval(public.files(T).filein);
	ok:=rmname.unlock();
	# new filler makes GBT_GO
 
	mstab := table(msname, ack=F);
	goTabKeyword := 'GBT_GO';
	if (!any(mstab.keywordnames()==goTabKeyword)) {
	    # old filler made NRAO_GBT_GLISH
	    goTabKeyword := 'NRAO_GBT_GLISH';
	}
        tabl:=table(mstab.getkeyword(goTabKeyword),ack=F);
	mstab.done();
        if (!is_fail(tabl)) {
	   #GBT data
           scancol:=tabl.getcol('SCAN');
           objcol:=tabl.getcol('OBJECT');
           timecol:=tabl.getcol('TIME');
           procname:=tabl.getcol('PROCNAME');
           swstate:=tabl.getcol('SWSTATE');
           swtchsig:=tabl.getcol('SWTCHSIG');
           procseqn:=tabl.getcol('PROCSEQN');
           procsize:=tabl.getcol('PROCSIZE');
           tabl.done();
	} else {
	   tabl:=F;
	   tmp:=shell('ls');#somehow the disk isn't updated until this
	   tabl:=table(as_string(msname),ack=F);
	   colnames:=tabl.colnames();
	   if (any(colnames=='SDMS{state}OBS_MODE')) {
	      #this is a flat table sditerator
              procname:=F;
	      scancol:=tabl.getcol('SCAN');
	      objcol:=tabl.getcol('OBJECT');
	      obsmode:=tabl.getcol('SDMS{state}OBS_MODE');
	      procseqn:=tabl.getcol('SDMS{state}SUB_SCAN');
	      if (any(colnames=='SDMS{state}NRAO_GBT_PROCSIZE')) {
	         procsize:=tabl.getcol('SDMS{state}NRAO_GBT_PROCSIZE');
	      } else {
	         procsize:=procseqn;
              };
	   } else {
	     #this is a non-GBT MS
                print 'ERROR: unrecognized observatory';
		print 'use d.summary() to obtain basic information';
                return F;
           };
        };
        ch:=['Scan','Object','Obs_mode','Procseqn', 'Procsize'];
#
        print sprintf("%4s %10s %30s %10s %10s",ch[1],ch[2],ch[3],
                ch[4],ch[5]);
#
        ctr:=0;
	x:=public.listscans();
        for (i in 1:len(scancol)) {
	    if (len(x)==len(scancol) || any(scancol[i]==x)) {
                   if (!verbose) {
                      if (procseqn[i]==1) {
                         ctr+:=1;
                         calscans[ctr]:=scancol[i];
		         if (!is_boolean(procname)) {
		            obsmode[i]:=spaste(procname[i],':',swstate[i],
				':',swtchsig[i]);
		         };
                         print sprintf("%4d %10s %30s %10d %10d",scancol[i],
                         objcol[i],obsmode[i],procseqn[i],
                         procsize[i]);
                      };
                   } else {
                         if (!is_boolean(procname)) {
                            obsmode[i]:=spaste(procname[i],':',swstate[i],
                                ':',swtchsig[i]);
                         };
                         ctr+:=1;
                         calscans[ctr]:=scancol[i];
                         print sprintf("%4d %10s %30s %10d %10d",scancol[i],
                         objcol[i],obsmode[i],procseqn[i],
                         procsize[i]);
                   };
            };
        };
	if (scans) {
		return calscans;
	} else {
        	return T;
	};
};


# Project summary function, modified by J. Braatz from a function
# originally written by F. Ghigo -- 12/17/2002
#

public.gbtsum := function(projname,source='',bscan=F,escan=F,verbose=F,filename=F) {

  # fang: function to format an angle in sexagesimal
  fang := function( xx ) {
    sgn := "+";
    d  := dd := as_double(xx)
    if( d < 0.0 ) { sgn := "-"; dd := -d; }
    dd +:= 0.0001;
    id := as_integer(dd)
    rmin := 60.0*(dd - id);
    imin := as_integer(rmin);
    ssec := 60.0*(rmin-imin);
    if(sgn=='-') zz := sprintf('-%02d:%02d:%02.0f', id, imin, ssec)
    else         zz := sprintf('%02d:%02d:%02.0f', id, imin, ssec)
    return zz;
    }

  writetofile := F
  if (!is_boolean(filename)) {
    if (is_string(filename)) {
      if (dos.fileexists(filename)) {
        dl.log(message='That file exists.  Choose another name.',priority='SEVERE',postcli=T)
	return F
        }
      fileid := open(paste('>',filename))
      if (is_fail(fileid)) {
        dl.log(message='Problem opening file.',priority='SEVERE',postcli=T)
        return F
        } 
      writetofile := T
      }
    }

  llg := 0;
  while (llg<=0) {
    if (len(split(projname,'/'))==1)
      pdir  := spaste( "/home/gbtdata/", projname, "/GO" )
    else
      pdir := spaste(projname, "/GO" )
    if (!dos.fileexists(pdir)) {
      dl.log(message=spaste('Project ',pdir,' does not exist'),priority='SEVERE',postcli=T)
      return F
      }
    print "DIR=", pdir
    glist := sort(dos.dir(pdir))
    llg := len(glist);
    print "Reading", llg, " GO fits files ..."
    print paste("Project Summary for", projname)
    if (writetofile)
      fprintf(fileid,paste("Project Summary for", projname,'\n'))

    if (verbose)
      print ' Scan       Source  Procedure    ObsType    SWState      SWSig   Eq     RA       DEC     VDEF-SYS   VEL   RESTFREQ'
    else
      print ' Scan       Source         RA       DEC     VEL          RESTFREQ'
    if (writetofile)
      if (verbose)
        fprintf(fileid,' Scan       Source  Procedure    ObsType    SWState      SWSig   Eq     RA       DEC     VDEF-SYS   VEL   RESTFREQ\n')
      else
        fprintf(fileid,' Scan       Source         RA       DEC     VEL          RESTFREQ\n')

    # now read through all the GO files.
    for( i in 1:llg) {
      fname := spaste( pdir, '/', glist[i])
      ff := open( paste("<", fname))
      zline := 0;
      obname   := 'unknown'
      scanno := procname := obstype := swstate := swsig := equin := veldef := rra :=  ddc :=  restf := veloc := '??'
      while (1) {
        fline := read(ff,80,'c')
	if (len(fline)==0) break ;
        ssline := split(fline, '')
        if(ssline[1] > ' ') {
          ppline := split(fline, ' ');
          zline +:=1;
  
          if(ppline[1]=='OBJECT')    obname   := split(fline, '\'')[2]
          if(ppline[1]=='SCAN')      scanno   := split(ppline[3], '\'')[1]
          if(ppline[1]=='PROCNAME=') procname := split(ppline[2], '\'')[1]
          if(ppline[1]=='OBSTYPE')   obstype  := split(ppline[3], '\'')[1]
          if(ppline[1]=='SWSTATE')   swstate  := split(ppline[3], '\'')[1]
          if(ppline[1]=='VELDEF')    veldef   := split(ppline[3], '\'')[1]
          if(ppline[1]=='SWTCHSIG=') swsig    := split(ppline[2], '\'')[1]
          if(ppline[1]=='EQUINOX')   {
            equin    := ppline[3]
            eeq := as_double(equin)
            equin := sprintf("%.0f", eeq);
            }
          if(ppline[1]=='RA')   {
            rra := ppline[3]
            rrr := as_double(rra)/15.0
            rra := fang(rrr)
            }
          if(ppline[1]=='DEC')   {
            ddc := ppline[3]
            ddd := as_double(ddc)
            ddc := fang(ddd)
            }
          if(ppline[1]=='RESTFRQ')   {
            restf    := ppline[3]
            rff := as_double(restf)*1.0E-9;
            restf := sprintf("%.5f", rff);
            }
          if(ppline[1]=='VELOCITY=')   {
            veloc    := ppline[2]
            vvl := as_double(veloc)*0.001;
            veloc := sprintf("%.2f", vvl);
            }
          }
        }
      if (is_boolean(bscan)) bscan:=1
      if (is_boolean(escan)) escan:=999999999
      if (as_integer(scanno)>=bscan && as_integer(scanno)<=escan && 
          obname ~ eval(spaste('m/',source,'/'))) {
        if (verbose)
          printf('%5s %12s %10s %10s %10s %10s %5s %8s %9s %9s %8s %9s\n',scanno, obname, procname, obstype, swstate, swsig, equin, rra, ddc, veldef, veloc, restf);
        else
          printf('%5s %16s %8s %9s %8s %12s\n',scanno, obname, rra, ddc, veloc, restf);
        if (writetofile)
          if (verbose)
            fprintf(fileid,'%5s %12s %10s %10s %10s %10s %5s %8s %9s %9s %8s %9s\n',scanno, obname, procname, obstype, swstate, swsig, equin, rra, ddc, veldef, veloc, restf);
          else
            fprintf(fileid,'%5s %16s %8s %9s %8s %12s\n',scanno, obname, rra, ddc, veloc, restf);
	  }
      ff := F
      }
    }
  return T
}

  return T;
}
