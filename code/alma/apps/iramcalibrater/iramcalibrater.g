# iramcalibrater.g: Tool that performs the functionalities of IRAM's clic
# Copyright (C) 2002,2003
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
# $Id: iramcalibrater.g,v 19.2 2003/10/15 23:04:34 kgolap Exp $

pragma include once;

include 'table.g'
include 'mathematics.g'
include 'pgplotter.g'
include 'calibrater.g'
include 'ms.g'
include 'os.g'

const iramcalibrater:= function(msname='',initcal=F) {

  public:=[=];
  private:=[=];

  #===========================
  # private data and functions
  #===========================

  # private data
  private.ms:=msname;
  private.initcal:=initcal;
  private.freqgrpname:=[=];
  # No explicit initcal necessary if scratch cols don't exist yet
  if (private.initcal) {
    t:=table(private.ms,ack=F);
    private.initcal:=any(t.colnames() ~ m/CORRECTED_DATA/);
    t.done();
  };

  private.cal:=calibrater(msname);


  # findfldids - find fieldids (1-based) given fieldnames
  #--------------------------------------------
  private.findfldids := function (msname, fieldnames) {

    # drop any extra spaces:
    fieldnames:=split(fieldnames);

    # Open ms's FIELD subtable and get name list
    t:= table(spaste(msname,'/FIELD'), ack=F);
    if (!is_table(t)) {
      return throw(spaste('No FIELD subtable for msname: ',msname));
    }
    names:= split(t.getcol('NAME'));
    t.close();
    n:= len(names);

    # store output fieldids here
    fieldids:=[=]

    # Loop over input fieldnames
    nfieldnames:=len(fieldnames);
    for (ifld in [1:nfieldnames]) {

      # match names
      thisfldid:= seq(1:n)[names == fieldnames[ifld]];

      # catch errors
      nfldid:= len(thisfldid);
      if (nfldid == 0) {
        note(paste('Field: ', fieldnames[ifld], ' not found'), priority='SEVERE');    	
        return F;
      };
      if (nfldid > 1) {
         note(paste('More than one field named: ', 
               fieldnames[ifld]), priority='SEVERE')
	     return F;
      };

      # accumulate fieldids
      if (len(fieldids)==0) {
        fieldids:=thisfldid;
      } else {
        fieldids:=[fieldids,thisfldid]
      };
    }
    
    # return fieldid list as vector of integers  
    return fieldids;
  };

  # findspwid - find spwid (1-based) for band name
  #-----------------------------------------------
  private.findspwid:=function(band="3mm", numchan=64, multichan=F){

    wider private;
    
    t:=table(spaste(private.ms, "/SPECTRAL_WINDOW"));
    nrows:=t.nrows();
    grp:=t.getcol("FREQ_GROUP_NAME")
      channum:=t.getcol("NUM_CHAN");

    k:=1;
    for(j in 1:nrows){
      if(length(split(band,'-'))==1){   # eg band='3mm'
	frqgrp:=split(grp[j],'-');
      }
      else{
	frqgrp:=grp[j];                 # eg band='3mm-LSB'
      }

      if(multichan){    # if multi chan pick all spectral spwid 

	if((channum[j]>1)&& (split(band)==frqgrp[1])){
	  spwid[k]:=j;
	  k:=k+1;
	}
      } 
      else{
	if(numchan >0){  # pick a all spwid that has given numchan in freqgrp
	  if((channum[j]==numchan)&& (split(band)==frqgrp[1])){
	    spwid[k]:=j;
	    k:=k+1;
	    
	  }
	}
	else{        #pick all spwid in freqgrp
	  
	  if((split(band)==frqgrp[1])){
	    spwid[k]:=j;
	    k:=k+1;
	    
	  }
	}
      }  
    }
    t.done();
    return spwid;
  }

# findfreqgrpname - find spwid (1-based) for band name
  #-----------------------------------------------
  private.findfreqgrpname:=function(){

    wider private;
    
    t:=table(spaste(private.ms, "/SPECTRAL_WINDOW"));
    private.freqgrpname:=t.getcol('FREQ_GROUP_NAME');
    t.done();
  }

  #=================
  # public functions
  #=================


  # initcal - initialize calibration (need to add cal table deletions)
  #-------------------------------------------------------------
  const public.initcal:=function() {
    wider private,public;

    # reset the MODEL_DATA and CORRECTED_DATA columns
    return private.cal.initcalset(0);
  };


  # phcor - select phase corrected data or not using iramphcor.g
  #-------------------------------------------------------------
  const  public.phcor:=function(trial=T){
#
# use the following line when plotting and frqgrp selection are added
#  const  public.phcor:=function(frqgrp='3mm-LSB',plottype='TIME',trial=T){

    wider private, public;

    note('-----Beginning method: phcor')
    include 'iramcalutil.g';
    a:=monitor(private.ms);
    a.findcalib();
    a.findspwid("3mm");
#    a.findspwid(frqgrp);
    a.pickdata(dosel= !trial);
    a.findcalib();
    a.findspwid("1mm");
    a.pickdata(dosel= !trial);


#    plot:=(plottype!='NONE');
#    if (plot) {
#      spwid:=private.findspwid(band=frqgrp, numchan=64);
#      print 'plot spwids: ',spwid;  
#      a.phcorplt(type=plottype,spwid=spwid);
#    };
    note('-----Finished method: phcor')
  };


  # rf - poly bandpass calibration
  #-------------------------------
  const public.rf:=function(fieldname, freqgrp='3mm-LSB', visnorm=F, 
			    bpnorm=T, refant=1, degamp=6, degphase=12, gibb=2, drop=5){

    wider private, public;

    note('-----Beginning method: rf')

    # set the calibration table name
    private.caltableB := spaste(msname, '.', freqgrp, '.bcal');

    # assert only one fieldname
    fieldname:=split(fieldname);
    if (shape(fieldname)>1) {
       return throw('Please use only one field in rf.')
    }

    if(freqgrp=='1mm'){
      freqstr[1]:='1mm-LSB';
      freqstr[2]:='1mm-USB';
      numsb:=2
    } else {
      numsb:=1;
      freqstr[1]:=freqgrp
    }

    # store refant
    private.refant:=refant;

    # solve for each sub-band separately
    for(sb in 1:numsb){

      # form selection TaQL from fieldnames and freqgrp 
      fldids:=private.findfldids(private.ms,fieldname);
      if (!fldids) {
	note('Check the fieldnames and rerun rf', priority='WARN');
	return F;
      }
      fldsel:=paste("(FIELD_ID IN ",as_evalstr(fldids),")");
      spwids:=private.findspwid(band=freqstr[sb], multichan=T);
      spwsel:=paste('(SPECTRAL_WINDOW_ID IN ',as_evalstr(spwids),')');
      mssel:= paste(fldsel,' && ',spwsel);

      # reset any previous setsolve and setapplys
      private.cal.reset();

      # select the data
      private.cal.setdata(msselect=mssel);

      # if visnorm=T, use GPLINE to make coherent in time
      #   NB: Cannot rely on VisEquation because it normalizes per spw,
      #        not per sideband
      #  Here, we get GSPLINE solution for first sideband, and use
      #   for the BPOLY solution of _both_ sidebands
      if (visnorm) {
        
        # only solve GSPLINE if first sideband:
        if (sb==1) {

          # name of this temporary g(ph) table
          private.visnormtable:= spaste(msname, '.', freqstr[sb], '.visnorm');

          # delete this table, in case it exists
          dos.remove(pathname=private.visnormtable, mustexist=F);

          # arrange to solve for phase spline 
          private.cal.setsolvegainspline(table=private.visnormtable, mode='PHAS',
	        			       refant=private.refant);

          # solve!
          private.cal.solve();
          
          # rename visnorm plot
          dos.move(spaste(msname,'.PHAS.ps'),spaste(msname,'.',freqstr[sb],'.visnorm.PHAS.ps'),T);


          # reset solve/apply state
          private.cal.reset();

        };

        # arrange to apply phase spline for BPoly solution
        private.cal.setapply(type='GSPLINE', table=private.visnormtable);

      };

      # arrange to solve for bandpass poly (append=T for sb 2)
      #  N.B.: Force visnorm=F here; if user wanted visnorm it has been done
      #    above with GSPLINE (phase).
      if (sb==1){
        private.cal.setsolvebandpoly(table=private.caltableB, degamp=degamp, 
	  			     degphase=degphase, refant=private.refant,
                                     visnorm=F,
		  		     bpnorm=bpnorm, maskcenter=gibb, 
			  	     maskedge=drop );
      } else {
        private.cal.setsolvebandpoly(table=private.caltableB, degamp=degamp, 
	  		 	     degphase=degphase, refant=private.refant,
                                     visnorm=F,
		  		     bpnorm=bpnorm, maskcenter=gibb, 
			  	     maskedge=drop, append=T );
    
      }

      # solve!
      private.cal.solve();

      # Rename plots:
      dos.move(spaste(msname,'.RF_AMP.ps'),  spaste(msname,'.',freqstr[sb],'.bcal.RF_AMP.ps'),T);
      dos.move(spaste(msname,'.RF_PHASE.ps'),spaste(msname,'.',freqstr[sb],'.bcal.RF_PHA.ps'),T);


if((freqgrp ~ m/^3mm/)){
	visnorm3mm:=spaste(msname, '.3mm-LSB.visnorm');
	bp3mm:=spaste(msname, '.3mm-LSB.bcal');
	freq3mm:='3mm-LSB';
	visnormexist:=dos.fileexists(visnorm3mm);
	#Try USB
	if(!visnormexist){
	  visnorm3mm:=spaste(msname, '.3mm-USB.visnorm');
	  visnormexist:=dos.fileexists(visnorm3mm);
	  bp3mm:=spaste(msname, '.3mm-USB.bcal');
	  freq3mm:='3mm-USB';
	}
	if(dos.fileexists(visnorm3mm) && dos.fileexists(bp3mm)){
	
	  private.transferrefphase(visnorm3mm, bp3mm);
	}
      }
      # arrange to apply bandpass solution
      private.cal.reset();

### commenting the lines below for phase III comparisons...no need to apply 
### at this stage.

#      private.cal.setapply(type="BPOLY", table=private.caltableB);
    
      # re-select and correct the data
#      private.cal.setdata(msselect=spwsel);
#      private.cal.correct();
    }


    note('-----Finished method: rf')

  }



  # phase - splined phase calibration
  #----------------------------------
  const public.phase:=function(fieldnames, freqgrp='3mm-LSB', refant=1, phasetransfer='raw', rawspw=-1, npointaver=10, phasewrap='250.0deg' ){
    wider private, public;

    note('-----Beginning method: phase');

    # store refant
    private.refant:=refant;

    # set the calibration table names
    private.caltableB := spaste(msname, '.', freqgrp, '.bcal');
    private.caltableG := spaste(msname, '.', freqgrp, '.gcal');

    # avoid extra spaces and vectorize:
    fieldnames:=split(fieldnames);

    # form selection TaQL from fieldnames and freqgrp 
    fldids:=private.findfldids(private.ms,fieldnames);
    if (!fldids) {
      note('Check the fieldnames and rerun phase', priority='WARN');
      return F;
    }
    fldsel:=paste('(FIELD_ID IN ',as_evalstr(fldids),')');
    spwids:=private.findspwid(band=freqgrp, multichan=T);
    spwsel:=paste('(SPECTRAL_WINDOW_ID IN ',as_evalstr(spwids),')');
    mssel:= paste(fldsel,' && ',spwsel);

    # reset any previous setsolves or setapplys
    private.cal.reset(); 

    # select data
    private.cal.setdata(msselect=mssel);

    # transfer the ref phases to the BP table
    if((phasetransfer=='raw') && (freqgrp ~ m/^1mm/)){
      bp3mm:=spaste(msname, '.3mm-LSB.bcal');
      freq3mm:='3mm-LSB';
      bpexist:=dos.fileexists(bp3mm);
      #Try USB
      if(!bpexist){
	bp3mm:=spaste(msname, '.3mm-USB.bcal');
	bpexist:=dos.fileexists(bp3mm);
	freq3mm:='3mm-USB';
      }
      if(dos.fileexists(bp3mm)){
	
	spwid3mm:=private.findspwid(band=freq3mm, multichan=T);
	spwsel3mm:=paste('(SPECTRAL_WINDOW_ID IN ',as_evalstr(spwid3mm),')');
	mssel3mm:= paste(fldsel,' && ',spwsel3mm);
	private.cal.setdata(msselect=mssel3mm);
	private.cal.setapply(type="BPOLY", table=bp3mm);
	private.cal.correct();
	private.cal.reset();
	private.cal.setdata(msselect=mssel);
      }
    }
    # arrange to apply bandpass calibration before solving
    private.cal.setapply(type="BPOLY", table=private.caltableB);

    # arrange to solve for phase spline 
    private.cal.setsolvegainspline(table=private.caltableG, mode='PHAS',
				   refant=private.refant, 
				   npointaver=npointaver, 
				   phasewrap=dq.convert(phasewrap, 'deg').value);

    # pre-apply the scaled 3 mm phase solution if found
    caltable3mmG := spaste(msname, '.3mm-LSB', '.gcal');
    if(dos.fileexists(caltable3mmG) &&  
       dos.fileexists(spaste(msname, '.3mm-USB', '.gcal'))){
      note(' Both 3mm USB and LSB cal tables exist; will be transferring LSB', 
	   priority='WARN'); 
      note('Do make sure that rawspw corresponds to the LSB', priority='WARN');

    }
    #try USB
    if(!dos.fileexists(caltable3mmG))
      caltable3mmG := spaste(msname, '.3mm-USB', '.gcal');
    transfer:= dos.fileexists(caltable3mmG) && (freqgrp ~ m/^1mm/);
    

    if (transfer && (phasetransfer != 'none')) {
      if( (phasetransfer == 'curve')){
	note(spaste('Transferring 3 mm phase corrections from:', caltable3mmG));
	private.cal.setapply(type="GSPLINE", table=caltable3mmG);
      }
      if( (phasetransfer == 'raw')){
	if(rawspw[1]<0){ 
	  note('No Valid SPW for transfer given in raw transfer', 
	       priority='SEVERE');
	  return ;
	}
	note(spaste('Transferring 3mm data phases to 1mm data.'));
	private.cal.setapply(type="GSPLINE", table=caltable3mmG, rawspw=rawspw);
     }
    };
    
    # solve!
    private.cal.solve();    

    # Rename plot:
    dos.move(spaste(msname,'.PHAS.ps'),spaste(msname,'.',freqgrp,'.gcal.PHAS.ps'),T);
    dos.move(spaste(msname,'.phase.log'),spaste(msname,'.',freqgrp,'.phase.log'));


    # arrange to apply phase spline
    private.cal.reset(apply=T);

### Commenting the lines below as we don't need to apply at this stage
### for phase III comparisons

#    private.cal.setapply(type="BPOLY", table=private.caltableB);
#    private.cal.setapply(type='GSPLINE', table=private.caltableG);
    
    # re-select and correct the data
#    private.cal.setdata(msselect=spwsel);
#    private.cal.correct();

    note('-----Finished method: phase')

  }


  # flux - establish flux density scale
  #------------------------------------
  const public.flux:=function(fieldnames, freqgrp='3mm-LSB', 
                              timerange, plot=F, gibb=2, drop=5, fixed=[' '],
			      numchancont=64) {
    wider private, public;

    note('-----Beginning method: flux');

    private.caltableG := spaste(private.ms, '.', freqgrp, '.gcal');

    if(!dos.fileexists(private.caltableG)){
      note('Do not seem to find the phase cal table', priority='WARN');
      note('May be you might have to run phase first', priority='WARN');
      return ;
    }

    # avoid extra spaces and vectorize:
    fieldnames:=split(fieldnames);
    fixed:=split(fixed);

    # if any fixed flux densities specified, not interactive:
    dointer:=T
    if (len(fixed) > 0) {

      # Turn off interactive:
      dointer:=F;

      # extend fixed with '-1Jy' as necessary
      dfix:=len(fieldnames)-len(fixed);
      if (dfix > 0) {
         fixed:=[fixed,array('-1Jy',dfix)];
      };

      # Truncate fixed to length of fieldnames if necessary
      if (dfix < 0) {
         fixed:=fixed[1:len(fieldnames)];
      };         
    };

    apply:=F;

    spwid:=private.findspwid(freqgrp, numchancont);
    fldids:=private.findfldids(private.ms,fieldnames);
    if (!fldids) {
      note('Check the fieldnames and rerun flux', priority='WARN');
      return F;
    }
    # include and operate iramfluxcal tool
    include 'iramcalutil.g';

    fl:=fluxcal(msfile=private.ms, calibids=fldids, spwids=spwid, 
                timerange=timerange,
                gibb=gibb, drop=drop);

    if (is_boolean(fl) && !fl) {
      note('Could not procede with flux calibration.',priority='SEVERE');
      return F;
    };

    # user-controlled iteration over calibrator flux-fixing
    while(apply == F){
      
      if (dointer) {
        # query for fixed calibrators
        print "Operating in interactive mode:";
        print "Give the field names and fluxes of fixed calibrators";
        namestr:= readline(prompt='Field names       = ');
        fluxstr:= readline(prompt='Fluxes (e.g 1mJy) = ');
      } else {
        print "Operating in NON-interactive mode."
        fmask:=(dq.getvalue(dq.quantity(fixed)) > 0.0);
        namestr:=fieldnames[fmask];
        fluxstr:=as_string(fixed[fmask]);
      };

      fixedcalid:=private.findfldids(private.ms,namestr);
      if(!fixedcalid) {
        note('Rerun flux and check Field names for fixed calibrators.',priority='WARN');
        return F;
      }
      fixedflux:=as_string(split(fluxstr));

      ratio:=fl.findratio(fixedid=fixedcalid, 
			  fixedflux=fixedflux);
      if (is_boolean(ratio) && !ratio) {
         return F;
      };

      fl.findfluxes();
      fl.antefficies();
      if(plot) {
 	fl.plot();
        dos.move(spaste(msname,'.FLUX.ps'),spaste(msname,'.',freqgrp,'.FLUX.ps'),T);
      };

      if (dointer) {
        # Query for acceptance
        a:=split(readline(prompt='Apply (y/n) or Quit (q)' ));
	if(a=='q') return -1;
        if(a=='y') apply:=T;
      } else {
        apply:=T;
      };
    }


    # Apply the flux scaling to the gain table. 
    a:=fl.applyflux(caltable=private.caltableG);

    # finished with iramfluxcal tool
    fl.done();

    # update MODEL_DATA with new flux densities
    spwids:=private.findspwid(freqgrp,multichan=T);
    note(spaste('Updating model flux densities in band ',freqgrp,
                ', spectral windows=',as_evalstr(spwids)));
    include 'imager.g'
    myim:=imager(private.ms);
    for (j in 1:length(spwids)) {
      for (k in 1:length(fldids)){
        myim.setjy(fieldid=fldids[k], spwid=spwids[j], fluxdensity=[a[k]]);
      }
    }
    myim.done();

    note('-----Finished method: flux')

    return a; 
  };

  
  # amp - splined amplitude calibration
  #------------------------------------
  const public.amp:=function(fieldnames, freqgrp='3mm-LSB'){

    wider private, public;

    note('-----Beginning method: amp');

    # set the calibration table names
    private.caltableB := spaste(msname, '.', freqgrp, '.bcal');
    private.caltableG := spaste(msname, '.', freqgrp, '.gcal');

    # avoid extra spaces and vectorize:
    fieldnames:=split(fieldnames);

    # form selection TaQL from fieldnames and freqgrp
    fldids:=private.findfldids(private.ms,fieldnames);
    if (!fldids) {
      note('Check the fieldnames and rerun amp', priority='WARN');
      return F;
    }
    fldsel:=paste("(FIELD_ID IN ",as_evalstr(fldids),")");
    spwids:=private.findspwid(band=freqgrp, multichan=T);
    spwsel:=paste('(SPECTRAL_WINDOW_ID IN ',as_evalstr(spwids),')');
    mssel:= paste(fldsel,' && ',spwsel);

    # reset any previous setsolve and setapplys
    private.cal.reset(); 
                         
    # select the data
    private.cal.setdata(msselect=mssel);

    # arrange to apply bandpass poly and phase spline before solving
    private.cal.setapply(type="BPOLY", table=private.caltableB);
    private.cal.setapply(type="GSPLINE", table=private.caltableG);

    # arrange to solve for amplitude spline
    private.cal.setsolvegainspline(table=private.caltableG, mode='AMP',
				   refant=1);
    
    # solve!
    private.cal.solve();    

    # Rename plot:
    dos.move(spaste(msname,'.AMP.ps'),spaste(msname,'.',freqgrp,'.gcal.AMP.ps'),T);
    dos.move(spaste(msname,'.amp.log'),spaste(msname,'.',freqgrp,'.amp.log'));

    # select data for final correct (all fields implicit)
#    private.cal.setdata(msselect=spwsel);

    # final correct!
#    private.cal.correct();

    comstr:=spaste('cat ', spaste(msname,'.',freqgrp,'.phase.log '),' ',
                           spaste(msname,'.',freqgrp,'.amp.log'),' > ', 
                           spaste(msname,'.',freqgrp,'.splinefits.log'));
    a:=shell(comstr);
    a:=shell(spaste('rm -f ',spaste(msname,'.',freqgrp,'.phase.log '),' ',
                             spaste(msname,'.',freqgrp,'.amp.log')));

    note('-----Finished method: amp')
    
  }


  # uvt - extract a calibrated field and combine into another ms
  #-------------------------------------------------------------
  const public.uvt:=function(fieldname, spwid=1, filename='', option='new', nchan=-1, start=-1, width=-1){
    wider private, public;

    note('-----Beginning method: uvt');

    msname:=private.ms;
    if(length(private.freqgrpname) == 0)
      private.findfreqgrpname();
    freqgrp:=private.freqgrpname[spwid];
    private.caltableB := spaste(msname, '.', freqgrp, '.bcal');
    if(!dos.fileexists(private.caltableB)){
      freqgrp:=split(freqgrp, '-')[1];
      private.caltableB := spaste(msname, '.', freqgrp, '.bcal');
    }
    if(!dos.fileexists(private.caltableB)){
      return throw('Cannot find Band Pass cal table');
    }
    private.caltableG := spaste(msname, '.', freqgrp, '.gcal');
    if(!dos.fileexists(private.caltableG)){
      return throw('Cannot find Gain cal table');
    }

    # assert only one fieldname:
    fieldname:=split(fieldname);
    if (shape(fieldname)>1) {
       return throw('Please use only one field in uvt.')
    }

    if (option=='new' && dos.fileexists(filename)){
      dos.remove(filename);
    }

    fieldid:=private.findfldids(private.ms,fieldname);
    if (!fieldid) {
      note('Check the fieldnames and rerun uvt', priority='WARN');
      return F;
    }


    fldsel:=paste("(FIELD_ID IN ",as_evalstr(fieldid),")");
    spwsel:=paste('(SPECTRAL_WINDOW_ID IN ',as_evalstr(spwid),')');
    mssel:= paste(fldsel,' && ',spwsel);

    # reset any previous setsolve and setapplys
    private.cal.reset(); 
                         
    # select the data
#    private.cal.setdata(msselect=mssel);
    # arrange to apply bandpass poly and phase spline before solving
#    private.cal.setapply(type="BPOLY", table=private.caltableB);
#    private.cal.correct();


    myms1:=ms(private.ms, readonly=F);
#    for (spid in spwid){
      bla:=spaste('bla.ms');
#      myms1.tofits(fitsfile='bla.fits', fieldid=fieldid, spwid=spid, 
#		   nchan=nchan*width, start=start, width=1);
#      myms2:=fitstoms(bla, 'bla.fits');
#      myms2.done();
#      t:=table(spaste(bla,'/SPECTRAL_WINDOW'), readonly=F);
#      t.putcol('FREQ_GROUP_NAME', private.freqgrpname[spid]);
#      t.done();
      myms1.split(outputms=bla, fieldids=fieldid, spwids=spwid, 
		  nchan=nchan*width, start=start, step=1, whichcol='DATA');
      mcal:=calibrater(bla);
      mcal.setapply(type="BPOLY", table=private.caltableB);
      mcal.setapply(type="GSPLINE", table=private.caltableG);
      mcal.correct();
      mcal.done();
#      myms2:=ms(bla);
#      myms2.tofits(fitsfile='scratch.fits', fieldid=1, spwid=1, 
#		   nchan=nchan, start=1, width=width);
#      myms2.done();
#      shell(spaste('rm -rf ', bla));
#      shell('rm -rf bla.fits');

      if(width >1){
	shell(spaste('mv ', bla, ' tempo.ms'));
	muims:=ms('tempo.ms', readonly=F);
	muims.split(outputms=bla, fieldids=1, spwids=1:length(spwids), 
		    nchan=nchan, start=1, step=width, whichcol='CORRECTED_DATA');
	
	muims.done();
	shell('rm -rf tempo.ms');
	mcal:=calibrater(bla);
	mcal.done();

      }
    
#    myms.done();
      if(option=='new'){
#      myms:=fitstoms(filename, 'scratch.fits', obstype=1);
#      myms.done();
	shell(spaste('mv ', bla, ' ', filename));
	
	option:='old';
      }
      else{
	myms:=ms(filename, readonly=F);
#	mynewms:=fitstoms('iramcalscratch.ms', 'scratch.fits', obstype=1);
#	mynewms.done();
	myms.concatenate(msfile=bla, freqtol='10MHz', 
			 dirtol='1arcsec');
	myms.done();
	dos.remove(bla);
      }
#      dos.remove('scratch.fits');
#     }
   myms1.done(); 
# this is to palliate a bug in ms.concatenate for now on obsid
    t:=table(filename, readonly=F);
    obs:=t.getcol('OBSERVATION_ID');
    l:=length(obs);
    obs:=array(0, l);
    t.putcol('OBSERVATION_ID', obs);
    t.done()

    note('-----Finished method: uvt')

    }


# private function that transfers the mean of a phase soln to the 
# bp scale_factor

  private.transferrefphase:=function(visnormtable, bptable){
    
    bptab:=table(bptable, readonly=F);
    vistab:=table(visnormtable);
    
    
    knots:=vistab.getcol('SPLINE_KNOTS_PHASE');
    coeff:=vistab.getcol('POLY_COEFF_PHASE');  
    antvis:= vistab.getcol('ANTENNA1');
    
    
    scalefac:=bptab.getcol('SCALE_FACTOR');
    antbp:=bptab.getcol('ANTENNA1');
    
    for (k in 1:length(antbp)){
      j:=1;
      while(antvis[j] != antbp[k]){
	j:=j+1;
      }
      ncoeff:=length(coeff[1,1,1,,j]);
      phasefac:=sum(coeff[1,1,1,,j])/(ncoeff-4);
      scalefac[k]:=scalefac[k]*complex(cos(phasefac), sin(phasefac));
      
    }
    bptab.putcol('SCALE_FACTOR', scalefac);
    bptab.done();
    vistab.done();

  }

  # gui - using toolgui.g
  #----------------------
  const public.gui := function() {
    wider private, public;
    include 'toolgui.g';
    rules := [phcor=[=],
	      rf=[requires='phcor'],
	      phase=[requires='rf'],
	      flux=[requires='phase'],
	      amp=[requires='flux'],
	      uvt=[requires='amp']];
    private.clicgui := toolgui(public, "phcor rf phase flux amp uvt", T,
			       rules);
    return T;
  }

  # done - finish using iramcalibrater
  #-----------------------------------
  const public.done := function(){ 
   wider private;
   private.cal.done(); 
   return T;

  }


  const public.type := function() {
    return 'iramcalibrater';
  }


  if (private.initcal) {
    public.initcal();
  }

  return ref public;

}


####global functions

include 'table.g'
include 'logger.g'
include 'statistics.g'


####function resample will do a hanning on the channels of the measurement
####set. Its a 3 channel hanning 0.125 + 0.75 + 0.125
#### If outfile 

const resample:=function(infile='', outfile=''){
  if(outfile != ''){
    shell(spaste('cp -r ', infile, ' ', outfile));
    msname:=outfile;
  }
  else{
    note('No output MS given; will hanning smooth on input MS', 
	 priority='WARN');
    msname:=infile;
  }
  if(msname==''){
    note('No input MS given', priority='SEVERE');
    return F;
  }
  t:=table(msname, readonly=F);
  cols:=t.colnames();
  corr:=F;
  for (k in 1:length(cols)){
    if(cols[k]=='CORRECTED_DATA') corr:=T;
  }
  
  if(corr){
    col:=['DATA', 'CORRECTED_DATA'];
  }
  else{
    col:='DATA';
  }

  for (colnam in col){
    dat:=t.getcol(colnam);
    nchan:=dat::shape[2];
    v:=dat;
    for (chan in 2:(nchan-1)){
      v[1,chan,]:=0.125*dat[1,(chan-1),]+0.75*dat[1,chan,]+
	          0.125*dat[1,(chan+1),];
    }
    t.putcol(colnam, v);
  }

  t.done();
}



#####function shadow check for shasowing on each scan
#####minsep is minimum acceptable seperation in m

include 'table.g'
include 'statistics.g'

const shadow:=function(msname, trial=T, minsep=15){


  t:=table(msname, readonly=F);
  uvw:=t.getcol('UVW');
  flg:=t.getcol('FLAG_ROW');
  scans:=t.getcol('SCAN_NUMBER');
  ant1:=t.getcol('ANTENNA1');
  ant2:=t.getcol('ANTENNA2');
  numant:=max(ant2)+1;
  baseluvw:=array(0,numant, numant, 3);
  basefil:=array(F,numant, numant);
  numbas:=numant*(numant-1)/2;
  minscan:=min(scans);
  maxscan:=max(scans);
  flagantscan:=array(F, maxscan-minscan+1, numant);
  actualscan:=0;
  shadcal:=T
  filled:=T;
  for (k in 1:length(scans)){
    if(actualscan!=scans[k]) {

      if(!filled) print 'Problem with all baselines in scan', actualscan;
      if(!shadcal) print 'Problem with shadow cal in scan', actualscan;
      actualscan:=scans[k];
      filled:=F;
      shadcal:=F;
      basefil:=array(F,numant, numant);
    }
    if(!filled){
      baseluvw[ant1[k]+1, ant2[k]+1,]:=uvw[,k];
      basefil[ant1[k]+1, ant2[k]+1]:=T;
      if(sum(basefil)>=numbas) filled:=T;
    }

    if(filled && (!shadcal)){
#      print 'scan', actualscan, 'baseluvw', baseluvw[1,2,1], baseluvw[4,5,]

      for(k in 1:(numant-1)){
	for(j in (k+1):numant){
	  
	  seperation:=sqrt(baseluvw[k,j,1]*baseluvw[k,j,1]+
			   baseluvw[k,j,2]*baseluvw[k,j,2]);
	  if(seperation < minsep){
	    if(baseluvw[k,j,3] < 0){
	      #antenna1 is shadowed
	      flagantscan[actualscan-minscan+1, ant1[k]+1]:=T;
	      print 'scan', actualscan, 'antenna', ant1[k]+1, seperation;
	    }
	    else{
	      flagantscan[actualscan-minscan+1, ant2[k]+1]:=T;
	      print 'scan', actualscan, 'antenna', ant2[k]+1, seperation;
	    }

	  } 

	}
      }
      shadcal:=T
    }


  }


  for( k in 1:length(scans)){

    if(flagantscan[scans[k]-minscan+1, ant1[k]+1] || 
       flagantscan[scans[k]-minscan+1, ant2[k]+1]){
#     print 'Row', k , 'scan', scans[k], 'ant1', ant1[k], 'ant2', ant2[k], 'to be flagged due to shadow actual ', flg[k] ;
      if(!trial){
	if(!flg[k]){
	  flg[k]:=T;
	  flagg:=t.getcell('FLAG',k);
	  flagg:=as_boolean(!flagg + flagg);
	  t.putcell('FLAG',k,flagg);
	}
      }

    }

  }
  if(!trial){
    t.putcol('FLAG_ROW', flg);
  }
  t.done();

}




