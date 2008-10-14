# iramcalutil.g: Helper tools for iramcalibrater.g
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
# $Id: iramcalutil.g,v 19.2 2004/06/10 22:49:43 gmoellen Exp $

include 'quanta.g'
include 'mathematics.g'
include 'ms.g'
include 'pgplotter.g'

fluxcal := function(msfile='', calibids, spwids, timerange='', gibb=1, drop=5){

  public:=[=];
  private:=[=];

  mytab:=table(spaste(msfile,'/ANTENNA'));
  private.numant:=mytab.nrows();
  print "Number of antennas: ", private.numant;
  mytab.done();
  numcal:=len(calibids);
  private.msfile:=msfile;
  private.calibids:=calibids;
  private.spwids:=spwids;
  private.ms:=ms(msfile, readonly=F);
  private.timerange:=split(timerange);
  private.gibb:=gibb;
  private.drop:=drop;
  private.pl:=F;

  ft:=table(spaste(msfile,'/FIELD'),ack=F)
  private.fldnames:=ft.getcol('NAME');
  ft.done()

  # ascertain full timerange
  private.fulltime:=private.ms.range(items="time").time;

  # process any user-specifed values
  ntimes:=len(private.timerange);

#  print ntimes, len(private.timerange), private.timerange;

  # must have even number of 
  if (ntimes%2 != 0) {
    note('Please specify start/stop times in pairs.',priority='SEVERE');
    return F;
  };

  nranges:=max(1,ntimes/2);
  private.timetaql:='';

#  print 'ntimes, nranges ',ntimes, nranges;

  if (ntimes > 0) {

    # MJD seconds count at midnite on day of beginning of observation:
    private.dateoff:=86400.0*as_integer(private.fulltime[1]/86400.0);

    private.timerangesec:=array(0.0,ntimes);

    # for each specified timerange
    for (i in 1:nranges) {
      i1:=2*i-1;
      i2:=2*i;

      # render user values in seconds
      private.timerangesec[i1]:=dq.getvalue(dq.convert(dq.quantity(private.timerange[i1]),'s'));
      private.timerangesec[i2]:=dq.getvalue(dq.convert(dq.quantity(private.timerange[i2]),'s'));

#      print 'TIME rangesec' , private.timerangesec[i1],private.timerangesec[i2] ; 
      
      # in case user specified relative to current day:
      if (private.timerangesec[i1] < private.dateoff) {
         private.timerangesec[i1]+:=private.dateoff;
      };
      if (private.timerangesec[i2] < private.dateoff) {
         private.timerangesec[i2]+:=private.dateoff;
      };

      # trap implausible time specifications:
      if ( private.timerangesec[i1] > private.timerangesec[i2] ||
           private.timerangesec[i1] > private.fulltime[2] ||
           private.timerangesec[i2] < private.fulltime[1] ) {
         note('Please check your timerange specification and try again.',
         priority='SEVERE');
         return F;
      };

      private.timetaql:=spaste(private.timetaql,'(TIME >= ',private.timerangesec[i1],' && TIME <= ',private.timerangesec[i2],')');      
      if (nranges > 1 && i !=nranges) {
        private.timetaql:=spaste(private.timetaql,' || ');
      };

    };

    private.timetaql:=spaste('(',private.timetaql,')');

    # count thru spwids and make sure we can see all fields
    calfldmask:=array(F,shape(private.calibids));
    for (ispw in [1:shape(private.spwids)] ) {
      for (ifld in [1:shape(private.calibids)] ) {
        private.ms.selectinit(datadescid=private.spwids[ispw]);
        EXT:=private.ms.select([field_id=private.calibids[ifld]]);
        if (EXT) {
          EXT:=private.ms.selecttaql(msselect=private.timetaql);
        };
        calfldmask[ifld]:=calfldmask[ifld] || EXT;
      };
    };

    if (all(!calfldmask)) {
      # found no fields!
      note('None of the specified fields are found in this timerange.',priority='SEVERE');
      note('Please check the field specification and try again.',priority='SEVERE');
      return F;
    };

    if (any(!calfldmask)) {
      # at least one field not found:
      note('Could not find the following fields in the specified timerange:',priority='WARN');
      note(spaste('  ',private.fldnames[private.calibids][!calfldmask]),priority='WARN');
      note('These fields will not be used in the flux scaling determination.',priority='WARN');
      private.calibids:=private.calibids[calfldmask];
    };

  } else {
    # user didn't specify anything, use full range:
    private.timerangesec:=private.fulltime;
    private.timetaql:=spaste(private.timetaql,'(TIME >= ',private.fulltime[1],' && TIME <= ',private.fulltime[2],')');      
  };

#  print 'private.timetaql = ',private.timetaql;

  # Report the timerange we are using
  note('Flux scaling will use data from the following timerange(s):');
  for (i in 1:nranges) {
    note(spaste('Begin-End:',dq.time(dq.quantity(private.timerangesec[(2*i-1)],'s'),form='ymd'),
                '-',dq.time(dq.quantity(private.timerangesec[(2*i)],'s'),form='ymd')));
  };


  public.findratio := function(fixedid, fixedflux='1mJy'){
    #spwid and fieldid is 1 based here

    wider public;
    wider private;

    private.fixedid:=fixedid;

    for (k in 1:length(fixedid)){
      thisflux:=dq.quantity(fixedflux[k]);
      if (thisflux.unit=='') thisflux.unit:='Jy';
      private.fixedflux[k]:=dq.convert(thisflux, 'Jy').value;
    }

    numwindows:=length(private.spwids)  ;

    sumamp:=0;
    sumwgt:=0;
    weighttotal:=0
    for (win in 1:numwindows){
      for(fix in 1:length(fixedid)){
	sumampid:=0;
	sumwgtid:=0;
	private.ms.selectinit(datadescid=private.spwids[win]);
	EXT:=private.ms.select([field_id=fixedid[fix]]);
        if (EXT) {
          EXT:=private.ms.selecttaql(msselect=private.timetaql);
        };
        if(EXT){
          d:=private.ms.getdata("corrected_amplitude weight flag");
          private.chanreject(d['flag']);

          # avoid flagged data
          data:=d['corrected_amplitude'];
          wgt:=d['weight'];
          flg:=d['flag'];

          # numpol should be 1 for IRAM data!
          numpol:=data::shape[1];
          numchan:=data::shape[2];
          numrow:=data::shape[3];

          # sum over rows (times/baselines)
          for (k in 1:numrow){

            thiswgt:=sum(wgt[,k])*sum(!flg[,,k])/(numpol*numchan);
            if (thiswgt > 0.0) {
              # accumulate row-mean of unflagged data
              sumampid:= sumampid + thiswgt*mean(data[,,k][!flg[,,k]])
              # accumulate row-weights (norm'd by fraction of unflagged channels)
              sumwgtid:= sumwgtid + thiswgt;
            }
          }

          if (sumwgtid > 0.0 ) {
            sumwgt:=sumwgt + sumwgtid*private.fixedflux[fix];
            sumamp:=sumamp + sumampid;
          }
        }           
      
      }
    }
    
    if (sumwgt > 0.0 && sumamp > 0.0 ) {
      private.ratio:= sumwgt/sumamp;
      note(paste('Factor to multiply is ', private.ratio));
    } else {
      note('Found insufficient unflagged data for fixed field',priority='SEVERE'); 
      note(' to determine flux scaling.',priority='SEVERE'); 
      note('Try again using a field with more data.',priority='SEVERE'); 
      return F;
    };

    d:=F;
    return private.ratio;
  }


  public.applyfluxscaling:=function(spwid=-1, ratio=-1){
    wider private, public;
    if(ratio <0){
      ratio:=private.ratio;
    }
    if(spwid< 0){
      spwid:=private.spwids;
    }
    note('If you change your mind to redo the flux cal,');
    note('have to apply the bp and phase cal over again');
   
    for(k in 1:length(spwid)){
      private.ms.selectinit(datadescid=spwid[k]);
      d:=private.ms.getdata("corrected_data");
      d['corrected_data']:=d['corrected_data']*ratio;  
      private.ms.putdata(d);
    }
    return private.foundflux; 
  }
   public.applyflux:=function(ratio=-1, caltable){
    wider private, public;
    include 'table.g';

    if(ratio <0){
      ratio:=private.ratio;
    }

    t:=table(caltable, readonly=F)
    nrows:=t.nrows();
    fac:=array(sqrt(1/(ratio)), nrows);
    t.putcol('SCALE_FACTOR',fac);
    t.done();
    return private.foundflux;
  }


  public.findfluxes:= function(){
   
    wider private, public;
    numwin:=length(private.spwids);
#    private.pl.clear();
    numsource:=len(private.calibids);
    srcmask:=array(T,numsource);
    for (n in 1:numsource){
      fluxid:=0
      for (k in 1:length(private.fixedid)){
	if(private.calibids[n]==private.fixedid[k]){
	  fluxid:=k;
	}
      }
      sumamp:=0;
      sumwgt:=0;
      if(fluxid==0){
	for(win in 1:numwin){
	  private.ms.selectinit(datadescid=private.spwids[win]);
	  EXT:=private.ms.select([field_id=private.calibids[n]]);
          if (EXT) {
            EXT:=private.ms.selecttaql(msselect=private.timetaql);
          };
          if(EXT){
            d:=private.ms.getdata("corrected_amplitude weight flag time");

            private.chanreject(d['flag']);

            data:=d['corrected_amplitude'];
            wgt:=d['weight'];
            flg:=d['flag'];

            numpol:=data::shape[1];
            numchan:=data::shape[2];
            numrow:=data::shape[3];

            for (k in 1:numrow){
              thiswgt:= sum(wgt[,k])*sum(!flg[,,k])/(numpol*numchan);
              if (thiswgt > 0.0) {
                sumamp:= sumamp + thiswgt*mean(data[,,k][!flg[,,k]]);
                sumwgt:= sumwgt + thiswgt;
              }  
            }
          }
        }

        if (sumamp > 0.0 && sumwgt > 0.0) {
          sumamp:=sumamp/sumwgt;
          private.foundflux[n]:=sumamp*private.ratio;
        } else {
          note(spaste('Could not find sufficient unflagged data for ',
                      private.fldnames[private.calibids[n]]),priority='WARNING');
          note(' to determine its flux density.');
          private.foundflux[n]:=0.0;
          srcmask[n]:=F;
        };
      }

      else{
        private.foundflux[n]:=private.fixedflux[fluxid];
      }

      if (srcmask[n]) {
        note(paste('Flux found: ', private.fldnames[private.calibids[n]],'=', private.foundflux[n],"Jy"));
      }
    }

    if (any(!srcmask)) {
      private.calibids:=private.calibids[!srcmask];
    };

    d:=F;
  }



  public.antefficies:= function(){
    
    wider private, public;

    seff:=array(0, private.numant);
    weff:=array(0, private.numant);
    numwin:=length(private.spwids);   
    numsource:=len(private.calibids);
    for (k in 1:numsource){
      for( win in 1:numwin){
	private.ms.selectinit(datadescid=private.spwids[win]);
	EXT:=private.ms.select([field_id=private.calibids[k]]);
        if (EXT) {
          EXT:=private.ms.selecttaql(msselect=private.timetaql);
        };
        numrow:=[];
        if(EXT){
	  d:=private.ms.getdata("amplitude weight flag antenna1 antenna2");
	  private.chanreject(d['flag']);

#	  data:=d['amplitude']* (!d['flag']);
	  data:=d['amplitude'];
          wgt:=d['weight'];
          flg:=d['flag'];

          numpol:=data::shape[1];
          numchan:=data::shape[2];
          numrow:=data::shape[3];

          if (win==1) {
            meanamp:=array(0,numrow);
            weight:=array(0,numrow);
          };

	  for (k1 in 1:numrow){
            thiswgt:= sum(wgt[,k1])*sum(!flg[,,k1])/(numpol*numchan);
            if (thiswgt > 0.0) {
              meanamp[k1] +:= thiswgt*mean(data[,,k1][!flg[,,k1]]);
              weight[k1]  +:= thiswgt;
            };
	  }
        }
      }

      for (k1 in 1:shape(meanamp)){
	if(weight[k1]>0){
	  meanamp[k1]:=meanamp[k1]/weight[k1];
	}
	else{
	  meanamp[k1]:=0;
	} 
      }
      private.indexaverdata(meanamp, weight,d['antenna1'], d['antenna2']) ;
      ampant:=array(0, private.numant);
      wgtant:=array(0, private.numant);
      private.ampant(ampant, wgtant);
      for (j in 1:(private.numant)){
	seff[j]:=seff[j]+ ampant[j]*wgtant[j]/private.foundflux[k];
	weff[j]:=weff[j]+ wgtant[j];
      }
    }
    
    for (j in 1:private.numant){
      private.seff[j]:=weff[j]/seff[j];
      private.sefferr[j]:=1/sqrt(weff[j])*private.seff[j]*private.seff[j];
      note(paste('Efficiency of antenna', j, 'is', private.seff[j], '+/-', private.sefferr[j],'Jy/K'));    
      
    }

  }

  private.ampant:=function( ref ampliant, ref weightant){
    
    wider private;

    for (k in 1:private.numant){
      ampliant[k]:=0;
      weightant[k]:=0;
      for (j in 1:private.numant){
	if (k != j){
	  for(m in j:private.numant){
	    if( k!=m && j!=m){
	      A_kj:=private.aver[private.basindex[min(j,k), max(j,k)]];
	      A_km:=private.aver[private.basindex[min(k,m), max(k,m)]];
	      A_jm:=private.aver[private.basindex[min(j,m), max(j,m)]];
	      W_kj:=private.weight[private.basindex[min(j,k), max(j,k)]];
	      W_km:=private.weight[private.basindex[min(k,m), max(k,m)]];
	      W_jm:=private.weight[private.basindex[min(j,m), max(j,m)]];
	      if( A_kj!=0 && A_km!=0 && A_jm!=0 && W_kj!=0 && W_km!=0 
		 && W_jm!=0  ){
		AA:= A_kj*A_km/A_jm;
		WA:= 1.0/(A_kj*A_kj*W_kj)+1.0/(A_km*A_km*W_km)+
		  1.0/(A_jm*A_jm*W_jm);
		WA:= 1/(AA*AA*WA);
		ampliant[k]:=ampliant[k]+ AA*WA;
		weightant[k]:=weightant[k]+WA;
	      }
	      
	    }

	  }
	}
	
      }
      
      if(weightant[k]!=0){
	ampliant[k]:=ampliant[k]/weightant[k];
      }
    }
    
    
  }


  private.indexaverdata:= function(amp, wgt, ant1, ant2){

    wider private;

    num:=len(ant1);
    numant:=private.numant;
    
    private.aver:=array(0,numant*(numant-1)/2);
    private.weight:=array(0, numant*(numant-1)/2);
    private.basindex:=array(0, private.numant, private.numant);

    for (k in 1:(numant-1)){
      for (j in (k+1):numant){
	private.basindex[k, j]:=(k-1)*numant-(k-1)*k/2+j-k;
      }
    }


    for (k in 1:num){

      if(ant1[k] > ant2[k]) print 'will have problem in indexing'
	myind :=
          (ant1[k]-1)*numant-ant1[k]*(ant1[k]-1)/2+ant2[k]-ant1[k];
      if(myind > numant*(numant-1)/2) print "k ", k, myind, ant1[k], ant2[k]
	private.aver[myind]:= private.aver[myind]+amp[k]*wgt[k];
      private.weight[myind]:=private.weight[myind]+wgt[k];


    }


    for (k in 1:(numant*(numant-1)/2)){
#print "baseline ", k, private.aver[k], private.weight[k]    
      if(private.weight[k]> 0){
	private.aver[k]:=private.aver[k]/private.weight[k];
      }
      else{
	private.aver[k]:=0;
      }

    }
    
    
  }

  public.plot:= function(){
    wider private;
    if(is_boolean(private.pl)){
      private.pl:=pgplotter();

    }
    private.pl.clear();
    numsource:=length(private.calibids);
    numwin:=length(private.spwids);   

    xmin:=1.0e+50; xmax:=0;
    ymin:=100000000; ymax:=0;
    newplot:=T
    private.pl.bbuf()
    for (n in 1:numsource){
      data:=F;
      for(win in 1:numwin){
	private.ms.selectinit(datadescid=private.spwids[win]);
	private.ms.select([field_id=private.calibids[n]]);
        private.ms.selecttaql(msselect=private.timetaql);
	d:=private.ms.getdata("corrected_amplitude weight flag time");   
	for (k in 1:length(d['time'])){
	  data[k]:=mean(d['corrected_amplitude'][,,k])*private.ratio/private.foundflux[n];
	}
	xdat:=(d['time']- floor(d['time']/3600/24)*3600*24)/3600;

	if(xmin> min(xdat))
	  xmin:=min(xdat);
	if(xmax < max(xdat))
	  xmax:=max(xdat);
	if(ymin> min(data))
	  ymin:=min(data);
	if(ymax < max(data))
	  ymax:=max(data);

	private.pl.plotxy(x=xdat, y=data, plotlines=F, 
			  newplot=newplot,
                          xtitle='Time (h)',
                          ytitle='Normalized Efficiency',
                          title='flux() Results',
			  linecolor=n, ptsymbol=n+2);
        newplot:=F;
      }
 
    }
    
    xmargin:=(xmax - xmin)/10.0
    ymargin:=(ymax - ymin)/10.0
    private.pl.setxscale(xmin-xmargin, xmax+xmargin) ;
    private.pl.setyscale(ymin-ymargin, ymax+ymargin) ;
    private.pl.ebuf()
    private.pl.psprinttofile(spaste(private.msfile, '.FLUX.ps'));

  }


  private.chanreject:=function(ref flag){


    wider private;
    numchan:=flag::shape[2];
    numrows:=flag::shape[3];
    numpol:=flag::shape[1];
    if(private.gibb>0){
      for (k in 1:private.gibb){
	
	flag[,numchan/2-(k-1),]:=array(T,numpol, numrows);
	flag[,numchan/2+(k),]:=array(T,numpol, numrows);
      }
    }
     
    if(private.drop >0){
      numedge:=as_integer(private.drop*numchan/100);
      for (k in 1:numedge){
	flag[,k,]:=array(T,numpol,numrows);
	flag[,numchan-(k-1),]:=array(T,numpol,numrows);
      }  
    }
  }



  public.done:= function(){
 
    wider private, public;
    private.ms.done();
    if(!is_boolean(private.pl))
      private.pl.done();
    private:=F;
    public:=F;


  }


return ref public ;

}

# iramphcor.g: The tool to select data from atmospheric corrected data

include 'table.g'
include 'mathematics.g'
include 'pgplotter.g'


### Typical run would be something like
## myphcor:=monitor('h22.ms')
## myphcor.findcalib()
## myphcor.findspwid()
## myphcor.pickdata()
## or
## myphcor.pickdata(dosel=T)


monitor := function(msname='', integ=0){

public:=[=];
private:=[=];

private.msname:=msname;
private.antscanflags:=[=];


if(integ !=0) {
# need to call the routine sim_phcor with all the right parameters.
#To calc \delta path and \delta phi as in equation 12.21 in IMISS2
#And redo the correction and have a new ALMA_PHAS_CORR column

}

#private.fincalib()
#private.pickdata()





###########The function find the data according to monitor criterion
## if dosel=T it will replace the data column with data from corrected
## or non-corrected column according to criteria matching
## if findcalib and findspwid are run prior the found sources and
## spectral windows will be used or else the user can overide manually
## by passing some the function below in calid and spw

public.pickdata :=function(calid=-1, spw=-1, dosel=F){


 wider public, private; 


 if (calid >=0){

   private.calfieldid:=calid;
 } 

if(spw != -1){
spwid:=spw
}
else{
spwid:=private.spwid;
}


 numcalids:= len(private.calfieldid) ; 
 anttab:=table(spaste(private.msname,'/ANTENNA'));
 private.numant:=anttab.nrows();
 anttab.done();
 maintab:=table(private.msname, readonly=F);
 fieldid:=maintab.getcol('FIELD_ID');
 timecol:=maintab.getcol('TIME');
 scans:=maintab.getcol('SCAN_NUMBER')
 corr_flag:=maintab.getcol('ALMA_PHAS_CORR_FLAG_ROW')
 min_scan:=min(scans);
 max_scan:=max(scans);
 nrowsall:=maintab.nrows();
 kounter:=0;
 kountertime:=0;
 calrow:=F; caltime:=F; calscan:=F
 

 for (k in 1:nrowsall){
   for(j in 1:numcalids){

    if(fieldid[k]==private.calfieldid[j]){
	kounter:=kounter+1
	calrow[kounter]:=k
	if(kountertime == 0){
            kountertime:=kountertime+1;
	    caltime[kountertime]:=timecol[k];
            calscan[1]:=scans[k];
        }
	else{
          if(timecol[k] != caltime[kountertime]){
	    kountertime:= kountertime+1;
            caltime[kountertime]:=timecol[k];
	    calscan[kountertime]:=scans[k];
          } 
        }
    }	
   }
 }

 if(scans[nrowsall] < scans[1]){
   numscan20:=as_integer((10000+scans[nrowsall]-scans[1])/(timecol[nrowsall]-timecol[1])*(20*60));
 }
 else{
   numscan20:=as_integer((scans[nrowsall]-scans[1])/(timecol[nrowsall]-timecol[1])*(20*60));
 }

#print 'number of scan for 20 mins', numscan20 


 
 
 fieldid:=F;                         # clearing that out of memory
 ant1:=maintab.getcol('ANTENNA1');
 ant2:=maintab.getcol('ANTENNA2');
 datdesc:=maintab.getcol('DATA_DESC_ID');
 sigma:=maintab.getcol('SIGMA');

 if(length(private.antscanflags) == 0){
   private.antscanflags:=array(F, private.numant,(max(scans)-min(scans)+1));
#WE HAVE TO LOOP OVER CALID // SPWID ARE THOSE WITH SINGLE CHANN
 for(m1 in 1:len(private.calfieldid)){

   max_nrows:=0
   for (m in 1:len(spwid)){
     
     selectString:=spaste("FIELD_ID==",
			  as_string(private.calfieldid[m1]),
			  " && DATA_DESC_ID==");
     selectString:=spaste(selectString,as_string(spwid[m]));
     

     subtab:=maintab.query(query=selectString, name='temp.table', 
			   sortlist="SCAN_NUMBER", 
			   columns="SCAN_NUMBER, ANTENNA1, ANTENNA2, ALMA_PHAS_CORR, ALMA_NO_PHAS_CORR, TIME, DATA_DESC_ID, WEIGHT");
     nrows:=subtab.nrows();
       if((max_nrows==0 && nrows !=0)){
	 avercorr:=array(0, nrows);
	 avernocorr:=array(0, nrows);
	 sumweight:=array(0,nrows);
	 a1:=subtab.getcol("ANTENNA1");
	 a2:=subtab.getcol("ANTENNA2");
	 tim1:=subtab.getcol('TIME');
	 scans1:=subtab.getcol('SCAN_NUMBER');
       }
     
     max_nrows:=max(nrows, max_nrows);
     if(nrows!=0){
       cordat:=subtab.getcol("ALMA_PHAS_CORR");
       nocordat:=subtab.getcol("ALMA_NO_PHAS_CORR");
       weight:=subtab.getcol("WEIGHT");
       avercorr:=avercorr+cordat*weight;
       avernocorr:=avernocorr+nocordat*weight;
       sumweight:=sumweight+weight;
     }
     subtab.done();
     shell('rm -rf temp.table');
   }

   avercorr:=avercorr/sumweight;
   avernocorr:=avernocorr/sumweight;  
   
#pl:=pgplotter();
#pl.plotxy(scans1,abs(avercorr)-abs(avernocorr),F, linecolor=2);
#pl.plotxy(scans1,sqrt(1/weight),F,F, linecolor=3);
#print "RMS: ", stddev(abs(avercorr)), stddev(abs(avernocorr))
     for (m in 1:max_nrows){
       tol:= 2*sqrt(1/weight[m])   # SHOULD be 2 sigma and we have 
                                 #to divide by weight above
#  print "AVERS:",avercorr[m], avernocorr[m]
	 if((abs(avercorr[m])+tol) < (abs(avernocorr[m])-tol)){
	   scanindex:=scans1[m]-min_scan+1;
	   private.antscanflags[(a1[m]+1),scanindex]:=T;   ###INTEGER corresponding to scan
	   private.antscanflags[(a2[m]+1),scanindex]:=T;
	 }
     }
   
 }
 } ###Loop for all calibrators


 for (kounterscan in 1:(max(scans)-min(scans)+1)){
   scannum[kounterscan]:=min(scans)+kounterscan-1;
 }




 calscancounter:=1;
 calscanBef:=calscan[1];
 calscanAft:=calscan[2];
 calindBef:=calscanBef-min_scan+1;
 calindAft:=calscanAft-min_scan+1;

for(scanNo in min_scan:max_scan){
   if((calscanAft <= scanNo) || scanNo==min_scan){
     calscancounter:=calscancounter+1;
     calscanBef:=calscanAft;
     if(calscancounter>=kountertime){
       calscanAft:=calscanBef;
     }
     else{
       calscanAft:=calscan[calscancounter+1];
     }
     calindBef:=calscanBef-min_scan+1;
     calindAft:=calscanAft-min_scan+1;
     
     for (anten in 1:private.numant){
       printflag:=F;
       flagstr:=spaste('Uncorr Flag for ant', as_string(anten), ' scan ')  
       if(private.antscanflags[anten, calindBef]){
	 calindlat:=calindBef+numscan20;
	 if(calindlat > (max_scan-min_scan+1)) calindlat:=max_scan-min_scan+1;
	 for (jj in calindBef:calindlat){
	   private.antscanflags[anten, jj]:=T;
	 }
	 flagstr:=spaste(flagstr, ' ', as_string(calindBef+min_scan), ' to ', 
			 as_string(calindlat+min_scan));
	 printflag:=T;

       }
       if(private.antscanflags[anten, calindAft]){
	 calindlat:=calindAft-numscan20;
	 if(calindlat <1) calindlat:=1;
	 for (jj in calindlat:calindAft){
	   private.antscanflags[anten, jj]:=T;
	 }
	 flagstr:=spaste(flagstr, ' ', 
			 as_string(calindlat+min_scan), 
			 ' to ', as_string(calindAft+min_scan));
	 printflag:=T;
       } 
       if(printflag)
	 note(flagstr);
     }
   }


 }


 
 timezone[1]:=timecol[1];
 for (k in 1:(kountertime-1)){
   timezone[k+1]:=(caltime[k+1]+caltime[k])/2.0;
 }
 timezone[kountertime+1]:=timecol[nrowsall];
##NOW changing the data in the table



 if(dosel){
   kountertime:=1;
   scanindex:=1;
   band:=private.band;
   public.findspwid(band, T);
   for (k in 1:nrowsall){
     scanindex:=scans[k]-min_scan+1;
     if(!prod(as_boolean(abs(private.spwid-datdesc[k]))) ){ 
       if(private.antscanflags[ant1[k]+1, scanindex] || 
	  private.antscanflags[ant2[k]+1, scanindex] ) {
	 data:=maintab.getcell("ALMA_NO_PHAS_CORR",k);
	 maintab.putcell("DATA",k, data);
	 corr_flag[k]:=T;
       }
#     else{
#       data:=maintab.getcell("ALMA_PHAS_CORR",k);
#       
#     }
#     maintab.putcell("DATA",k,data);
     }
   
   }
 }
 corrdata:=F; noncorr:=F; timecol:=F; sigma:=F; ant1:=F; ant2:=F;
   
 maintab.putcol('ALMA_PHAS_CORR_FLAG_ROW', corr_flag);
 
 data:=F;
 maintab.flush();
 maintab.done();
     
}

public.findcalib := function(){

wider private;



sourcetable:=spaste(private.msname,'/SOURCE')
t:=table(sourcetable);

sourcename:=t.getcol('NAME')
sourcecode:=t.getcol('CODE')
spwid:=t.getcol('SPECTRAL_WINDOW_ID')
sourceid:=t.getcol('SOURCE_ID')
t.done();

numrows:=max(sourceid::shape)
numcal:=0
for (k in 1:numrows){
     src:=split(sourcecode[k]) # get rid of blanks
				## NEED TO USE THE RIGHT SOURCE CODE
   if(src[1]=='PHAS' || src[1]=='phas' ||
      src[1]=='FLUX' || src[1]=="BAND"){

      numcal:=numcal+1;
      calname[numcal]:=sourcename[k];
      calspwid[numcal]:=spwid[k];
      calsid[numcal]:=sourceid[k];
   }
}



fieldtable:=spaste(private.msname,'/FIELD')
t:=table(fieldtable);

numrows:=t.nrows();
sourceid:=t.getcol('SOURCE_ID');
#print sourceid
t.done()

calfieldnum:=0

for (k in 1:numrows){

 for (j in 1:numcal){

   if(calsid[j]==sourceid[k]){
	calfieldnum:=calfieldnum+1;
	private.calfieldid[calfieldnum]:=k-1;
	private.calsid[calfieldnum]:=sourceid[k];
#print "CALSID ", calsid[j], j, sourceid[k], k

   }
 }

}


 for (k in 1:calfieldnum){
#  print "Calib field id ", private.calfieldid[k], " source  id", private.calsid[k]
 }

}


public.findspwid:=function(band="3mm", multichan=F){

wider private;
private.band:=band;
t:=table(spaste(private.msname, "/SPECTRAL_WINDOW"));
nrows:=t.nrows();
grp:=t.getcol("FREQ_GROUP_NAME")
channum:=t.getcol("NUM_CHAN");

k:=1
for(j in 1:nrows){
frqgrp:=split(grp[j],'-');
if(!multichan){
#  if((channum[j]==1)&& (split(band)==frqgrp[1])){
  if((channum[j]==1)&& (grp[j] ~ eval(spaste('m/',split(band),'/')))){
    private.spwid[k]:=j-1;
    k:=k+1;        
  }
}
else{
#  if((channum[j]>1)&& (split(band)==frqgrp[1])){
  if((channum[j]>1)&& (grp[j] ~ eval(spaste('m/',split(band),'/')))){
    private.spwid[k]:=j-1;
    k:=k+1;        
  }
}
}
t.done();

  print "Found spwid for band", band, " is ", private.spwid+1

}

public.phcorplt := function(type='TIME',spwid=3) {

  # 030219 (gmoellen): this is not yet called by iramcalibrater
  #  because it does not yet work quite right

  # spwid should be 64 chan 3mm

  include 'table.g'
  include 'pgplotter.g'

  spw:=spwid-1;
  shell('rm -rf phcorplot.plt');
  shell(spaste('rm -f ', msname, '.PHCOR.ps'));
  t:= table(tablename=private.msname,ack=T);
#  print t.nrows();

  selectString:=spaste('DATA_DESC_ID==',as_string(spw));
  subtab:=t.query(query=selectString, name='temp.tab',
                  sortlist="TIME, SCAN_NUMBER",
                  columns="TIME, SCAN_NUMBER, ALMA_PHAS_CORR_FLAG_ROW, FLAG_ROW");

#  print subtab.nrows();
  y := subtab.getcol('ALMA_PHAS_CORR_FLAG_ROW');
  yi := as_integer(!y)

  pg := pgplotter(plotfile='phcorplot.plt');
#  pg.screen();

  if (type=='TIME') {
    x := subtab.getcol('TIME');
    timeref:=86400.0*as_integer(x[1]/86400.0);
    x-:=timeref;
    xmin:=min(x);
    xmax:=max(x);
    pad:=0.05*(xmax-xmin);
    xmin-:=pad; xmax+:=pad;
    pg.page();
    pg.vstd();
    pg.swin(xmin,xmax,-0.1,1.1);
    pg.tbox('ZBCNXT',0.0,0,'BCNST',0.0,0)
    xlabel:=spaste('Time since ',dq.time(dq.quantity(timeref,'s'),form='ymd'));
    bpscan:=F
  } else {
    x := subtab.getcol('SCAN_NUMBER');
    xlabel:='Scan Number';
    byscan:=T;
  };

  pg.plotxy(x,yi,plotlines=F,linecolor=4,newplot=byscan);
  pg.lab(xlbl=xlabel, ylbl='FLAG_VALUE 1 = phase corrected',
         toplbl='ALMA_PHAS_CORR_FLAG_ROW Values');
  pg.psprinttofile(spaste(msname, '.PHCOR.ps'));
#  pg.done();
  subtab.done();
  t.done();

  shell('rm -rf temp.tab');

}

return ref public;

}
