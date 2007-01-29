# GBT Calibration Utilities	
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
#   $Id: mydish_gbtcal.gp,v 19.27 2006/01/26 19:53:34 bgarwood Exp $
#
#------------------------------------------------------------------------------

pragma include once

note('mydish_gbtcal.gp included');
#need:
#	Tsys spectrum calculator

include 'table.g';
include 'progress.g';
include 'gbtmsfiller.g';
include 'matrix.g';
include 'gbtcalibrator.g';
include 'functionfitter.g';

mydish_gbtcal := [=];

mydish_gbtcal.attach := function(ref public) {

  private:=[=];
  private.poly:=F;
  private.fftserver:=F;
  include 'polyfitter.g'
  private.poly:=polyfitter();
  private.tau:=F;
  private.ffitter:=F;
  public.uniput('tau',F);
  public.uniput('factor',1.0);
  private.etal:=1.0;
  private.eta:=1.0;
  private.etabeam:=1.0;

# Function to query a table based on SCAN_NUMBER
#  Returns the selected table.
  private.scanQuery := function(maintab, scan, nif=-1) {
      wider private;
      if (len(scan) > 1) {
	  global __query_scan_list__ := scan;
	  queryString := spaste('SCAN_NUMBER in $__query_scan_list__');
      } else {
	  queryString := spaste('SCAN_NUMBER == ',scan);
      }
      if (nif != -1) {
	  ddids := as_integer([])
	  for (i in 1:len(scan)) {
	      thisScan := scan[i];
	      info := public.qsp(thisScan);
	      if (any(nif > len(info.uspwin))) {
		  dl.log(message=paste('nif(s) larger than number of spectral windows in scan', thisScan),
			 priority='SEVERE',postcli=T);
		  # this will result in an empty table being returned, which will
		  # be interpreted correctly
		  ddids := -1;
		  break;
	      } 
	      for (thisIf in nif) {
		  ddids[len(ddids)+1] := info.uspwin[thisIf];
	      }
	  }
	  ddids := unique(ddids);
	  if (len(ddids) > 1) {
	      global __ddids__ := ddids;
	      queryString := spaste(queryString,' and DATA_DESC_ID in $__ddids__');
	  } else {
	      queryString := spaste(queryString,' and DATA_DESC_ID == ', ddids);
	  }
      }
      return maintab.query(queryString);
  }

  public.scanQuery := private.scanQuery;

# Function to obtain efficiency/scaling information 
# for a given scan
  private.geteff := function(scan,units=0,calceffs=T) {
      wider public;
      rec:=public.getscan(scan);
      if (is_boolean(rec)) next;
#  get efficiencies
      elev:=rec.header.azel.m1.value*180/pi;
      # use the frequency at the mid-point of this band
      # should really do this separately for each IF being calibrated.
      nchan := len(rec.data.desc.chan_freq.value);
      midPt := nchan/2;
      if (midPt < 1) midPt := 1;
      freq := rec.data.desc.chan_freq.value[midPt];
      return public.geteffonsky(freq,elev,units,calceffs);
  }

# Function to obtain efficiency/scaling information
# for a given frequency and elevation
  private.geteffonsky := function(freq, elev, units, calceffs) {
      wider private,public;
      if (calceffs) {
	  effs:=public.eff(freq,elev);
	  ok:=public.uniput('tau',effs.tau);
	  ok:=public.uniput('etal',effs.etal);
	  ok:=public.uniput('eta',effs.eta);
	  ok:=public.uniput('etabeam',effs.etabeam);
      } else {
	  # get previously put values
	  tau := public.uniget('tau');
	  etal := public.uniget('etal');
	  eta := public.uniget('eta');
	  etabeam := public.uniget('etabeam');
	  # if these are ok (not booleans) use them to set the private
	  # copies here.
	  # if they ARE booleans, see if the private copies are okay to
	  # use here
	  # if nothing is okay to use here, emit warning and return F.
	  if (!is_boolean(tau)) private.tau := tau;
	  else {
	      if (!is_boolean(private.tau)) {
		  ok:=public.uniput('tau',private.tau);
	      } else {
		  if (units > 0) {
		      dl.log(message='No valid tau has been set.  Using 1.0',
			     priority='WARN',postcli=T);
		      private.tau := 1.0;
		      ok := public.uniput('tau',1.0);
		  }
	      }
	  }
	  if (!is_boolean('etal')) private.etal := etal;
	  else {
	      if (!is_boolean(private.etal)) {
		  ok := public.uniput('etal', private.etal);
	      } else {
		  if (units == 1) {
		      dl.log(message='No valid etal has been set.  Using 1.0',
			     priority='WARN',postcli=T);
		      private.etal := 1.0;
		      ok := public.uniput('etal',1.0);
		  }
	      }
	  }
	  if (!is_boolean('etabeam')) private.etabeam := etabeam;
	  else {
	      if (!is_boolean(private.etabeam)) {
		  ok := public.uniput('etabeam', private.etabeam);
	      } else {
		  if (units == 2) {
		      dl.log(message='No valid etabeam has been set.  Using 1.0',
			     priority='WARN',postcli=T);
		      private.etabeam := 1.0;
		      ok := public.uniput('etabeam',1.0);
		  }
	      }
	  }
      }
      if (!is_boolean('eta')) private.eta := eta;
      else {
	  if (!is_boolean(private.eta)) {
	      ok := public.uniput('eta', private.eta);
	  } else {
	      if (units == 3) {
		  dl.log(message='No valid eta has been set.  Using 1.0',
			 priority='WARN',postcli=T);
		  private.eta := 1.0;
		  ok := public.uniput('eta',1.0);
	      }
	  }
      }
      #  Get factor to scale data for chosen units
      #  unit number is out of logical order for historical reasons
      if (units==0) {
	  factor := 1.0;
	  thisUnits := 'TA';
      } else {
	  # everything starts with TA prime
	  factor := exp(public.uniget('tau')*(1/sin(elev*pi/180.)));
	  if (units == 4) {
	      thisUnits := 'TA\'';
	  } else if (units==1) {
	      factor := factor/public.uniget('etal');
	      thisUnits := 'TA*';
	  } else if (units==2) {
	      factor := factor/public.uniget('etabeam');
	      thisUnits := 'TMB';
	  } else if (units==3) {
	      # 0.351582 = 2k/Area for GBT, r=50m, k=1380.6578 Jy m^2/K
	      factor := factor/(public.uniget('eta')/0.351582);
	      thisUnits := 'Jy';
	  } else {
	      print 'ERROR: Unrecognized unit';
	      return F;
	  };
      }
      ok := public.uniput('factor',factor);
      ok := public.uniput('units',thisUnits);
      return T;
  };

  public.geteffonsky := ref private.geteffonsky;

  public.geteff:=ref private.geteff;

  public.eff := function(frequency,elevation) {
      #for a scan get RESTFRQ from GBT_GO table
      #sets the values for:
      #       private.tau     == opacity
      #       private.etal    == spillover efficiency
      #       private.eta     == aperture efficiency
      #       private.etabeam == beam efficiency
      # should put these into the uni record
      wider private,public;
      #check to make sure the polyfitter is there
      if (!is_record(private.poly) | !has_field(private.poly,'eval')) {
	  include 'polyfitter.g';
	  private.poly:=polyfitter();
      };
      #opacity
      tau_coeff:=[0.0106068311,-1.14338059e-05,0.000439403729,-2.7270654e-05,
		  7.62801551e-07,-8.01529201e-09];
      ok := private.poly.eval(tauvalue,frequency/1.e9,tau_coeff);
      private.tau := tauvalue;
      #
      private.etal := 0.99;
      # these are parameterized based on values in an e-mail from Ron to Joe.
      if (frequency <= 6.e9) {
	  private.eta  := 0.71;
      } else if (frequency > 6.e9   & frequency < 10.e9) {
	  #X Band coefficients
	  xband_coeff:=[0.619412587,0.00214319347,3.19638695e-05,-1.39102564e-06,
			9.73193473e-09,-1.28205128e-11];
	  ok :=private.poly.eval(myvalue,elevation,xband_coeff);
	  private.eta := myvalue;
      } else if (frequency > 10.e9 & frequency <= 18.e9) {
	  #Ku Band coefficients
	  kuband_coeff:=[0.520293706,0.00682729604,-0.00011284965,1.754662e-06,
			 -2.97785548e-08,1.66666667e-10];
	  ok :=private.poly.eval(myvalue,elevation,kuband_coeff);
	  private.eta  := myvalue;
      } else if (frequency > 18.e9 & frequency <= 26.e9) {
	  #K Band coefficients
	  kband_coeff:=[0.251496503,0.0126724242,-1.11013986e-05,-3.4020979e-06,
                        2.63986014e-08 -5.12820513e-11];
	  ok :=private.poly.eval(myvalue,elevation,kband_coeff);
	  private.eta := myvalue;
      } else {
	  # Q band - unknown so go with 0.35 for now
	  private.eta := 0.35;
      };
      # beam efficiency is a scaling of the aperture efficiency for nu<50GHz
      private.etabeam := 1.4 * private.eta;
      rec:=[=];
      rec.tau:=private.tau;
      rec.etal:=private.etal;
      rec.eta:=private.eta;
      rec.etabeam:=private.etabeam;
      return rec;
  }; # end of eff

  private.firstSpwin := function(spwin, swstate, sigstate) {
      # we need to put uspwin in the order they each first appear in spwin
      # this does that
      # for FSWITCH data, need to do sig=T and sig=F separately
      if (swstate == 'FSWITCH' && len(sigstate) == len(spwin) &&
          sum(sigstate) == len(sigstate)/2) {
          sigFspw := private.firstSpwin(spwin[sigstate==T],'',F);
          refFspw := private.firstSpwin(spwin[sigstate==F],'',F);
          
          # and merge them - starting with whatever sig comes first
          
          if (!sigstate[1]) {
             tmp := refFspw;
             refFspw := sigFspw;
             sigFspw := tmp;
          }
          result := array(1,2*len(sigFspw));
          for (i in 1:len(sigFspw)) {
             result[i*2-1] := sigFspw[i];
             result[i*2] := refFspw[i];
          }
          return result;
      } else {
         uspwin := unique(spwin);
         fspw := array(0,len(uspwin));
         ispw := ind(spwin);
         for (i in 1:len(fspw)) {
            fspw[i] := (ispw[spwin==uspwin[i]])[1];
         }
         # fspw now holds the locations of spwin where each uspwin first occurs
         # so that when fspw is sorted, it will record the locations where a
         # a new spwin first occured - which indicates what the order of spwins
         # encountered was.

         sfspw := sort(fspw);
         ifspw := ind(fspw);
         ospw := array(0,len(fspw));
         for (i in 1:len(sfspw)) {
            ospw[i] := spwin[fspw[fspw==sfspw[i]]];
         } 
         return ospw;
      }
      return F;
  }

  # Record based version of qdumps (better implementation)
  public.qsp := function(scan=F) {
        wider public;
	wider private;
	if (is_boolean(scan)) {
		print 'ERROR: No scan specified';
		return F;
	};
	tmp:=public.files(T).filein;
	if (is_boolean(tmp)) {
		print 'ERROR: No filein specified ';
		return F;
	};
        msname:=eval(tmp).name();
        tab:=table(msname,ack=F);
        if (is_fail(tab)) {
		print 'ERROR: could not open table.';
		return F;
	};
	names:=tab.colnames();
	swstate := '';
	sigstate := F;
	if (any(names=='SCAN_NUMBER')) {
	   subt := tab.query(spaste('SCAN_NUMBER==',scan));
           nsubscans:=subt.nrows();
	   if (nsubscans==0) {
		print 'ERROR: No matching scans found in filein';
		return F;
	   };
	   utimes := unique(subt.getcol('TIME'));
	   phases:=subt.getcol('NRAO_GBT_STATE_ID');
	   uphases:=unique(phases);
           nphases:=len(uphases);
           spwin :=subt.getcol('DATA_DESC_ID');
	   uspwin:=unique(spwin);
           nspwin:=len(uspwin);
           feeds :=subt.getcol('FEED1');
           ufeeds:=unique(feeds);
           nfeeds:=len(ufeeds);
	   rownumbers:=subt.rownumbers();
	   statetab := table(tab.getkeyword('STATE'),ack=F);
	   stateid := subt.getcell('STATE_ID',1) + 1;
	   swstate := '';
	   if (stateid > 0 && stateid <= statetab.nrows()) {
	       obsmode := statetab.getcell('OBS_MODE',stateid);
	       swstate := split(obsmode,':');
	       if (len(swstate) >= 3) {
		   swstate := swstate[2];
	       } else {
		   swstate := obsmode;
	       }
	   }
	   if (strlen(swstate) <= 0) {
	       # fall back and try and get this from the GO table
	       # new filler makes GBT_GO subtable
	       goTabKeyword := 'GBT_GO';
	       gtab := T;
	       if (!has_field(tab.getkeywords(),goTabKeyword)) {
		   goTabKeyword := 'NRAO_GBT_GLISH';
		   if (!has_field(tab.getkeywords(),goTabKeyword)) {
		       print 'GO table is missing';
		       gtab := F;
		   }
	       }
	       if (gtab) {
		   gtab:=table(tab.getkeyword(goTabKeyword),ack=F);
		   gsub:=gtab.query(spaste('SCAN==',as_string(scan)));
		   swstate:=gsub.getcol('SWSTATE')[1];
		   ok:=gsub.done();
		   ok:=gtab.done();
	       } else {
		   swstate := '';
	       }
	   }	   if (swstate == "FSWITCH") {
	       sigcol := statetab.getcol('SIG');
	       statecol := subt.getcol('STATE_ID');
	       ustate := unique(statecol);
	       sigstate := statecol;
	       for (thisState in ustate) {
		   if (thisState >= 0 && thisState < len(sigcol)) {
		       sigstate[statecol==thisState] := sigcol[thisState+1];
		   } else {
		       # in the abscence of anything, assume its all signal
		       sigstate[thisState] := T;
		   }
	       }
	   }	       
	   ok:=subt.done();
	   ok := statetab.done();
	} else if (any(names=='SCAN')) {
	   subt:=tab.query(spaste('SCAN==',scan));
           nsubscans:=subt.nrows();
           if (nsubscans==0) {
                print 'ERROR: No scans found in filein';
                return F;
           };
	   utimes := unique(subt.getcol('TIME'));
           phases:=subt.getcol('NRAO_GBT_STATE_ID');
           uphases:=unique(phases);
           nphases:=len(uphases);
           spwin :=subt.getcol('DATA_DESC_ID');
           uspwin:=unique(spwin);
           nspwin:=len(uspwin);
           feeds :=subt.getcol('FEED1');
           ufeeds:=unique(feeds);
           nfeeds:=len(ufeeds);
           rownumbers:=subt.rownumbers();
	   ok:=subt.done();
	} else {
	   print 'Unrecognized data type ';
	   return F;
        };

#       need to deal with case of multiple spwins
        ok:=tab.done();
	dum:=[=];
	dum.phases:=phases;
	dum.uphases:=uphases;
	dum.nphases:=nphases;
	dum.spwin:=spwin;
        dum.uspwin := private.firstSpwin(spwin, swstate, sigstate);
	dum.nspwin:=nspwin;
	dum.feeds:=feeds;
	dum.ufeeds:=ufeeds;
	dum.nfeeds:=nfeeds;
	dum.rownumbers:=rownumbers;
	# number of integration, just count the unique times
        dum.ints:=len(utimes);
        return dum;
  };

  private.getSubind := function(scan, phase, int, pol, nif, nfeed, allIFs)
  {
      wider private, public;

      if (!any(public.listscans()==scan)) {
	  dl.log(message='Scan not found in currently opened file',
		 priority='SEVERE',postcli=T);
	  return F;
      };

      #setfeed - really set polarization
      ok:=public.setfeed(pol);      #toggle to raw data;
      #query state properties
      qsp:=public.qsp(scan);
      #initialize values
      indices:=1:len(qsp.rownumbers);
      spwinmask:=[indices==indices];
      feedmask := spwinmask;
      phasemask := spwinmask;
      intmask := spwinmask;
      
      if (nif>qsp.nspwin) {
	  dl.log(message='nif larger than number of spectral windows',
		 priority='SEVERE',postcli=T);
	  return F;
      };
      if (nfeed>qsp.nfeeds) {
	  dl.log(message='nfeed larger than number of feeds',
		 priority='SEVERE',postcli=T);
	  return F;
      };
      
      if (len(indices)==1) {
	  dl.log(message='Only 1 row in data',priority='WARNING',postcli=T);
	  return F;
      };
      if (!is_boolean(phase) && phase>qsp.nphases) {
	  dl.log(message='Phase larger than number of phases in scan',
		 priority='SEVERE',postcli=T);
	  return F;
      };
      
      if (!is_boolean(int)) {
	  if (!(int<=qsp.ints)) {
	      dl.log(message=spaste('Integration not found, there are ',qsp.ints,' integrations'),
		     priority='SEVERE',postcli=T);
	      return F;
	  };
      };
      #set up mask
      qsp.phases -:= (min(qsp.phases)-1);	#normalize
      qsp.feeds  -:= (min(qsp.feeds)-1);
      normspwin := qsp.spwin - (min(qsp.spwin)-1);  # only used for check against feed below
      if (!is_boolean(phase)) {
	  phasemask:=[phase==qsp.phases];
      }
      if (!is_boolean(nif)) {
	  spwinmask:=[qsp.spwin==qsp.uspwin[nif]];
      } else {
	  if (!allIFs) {
	      spwinmask:=[qsp.spwin==qsp.uspwin[1]];
	  }
      };

      if (!is_boolean(int)) {
	  #   there are len(phasemask) rows and qsp.ints integrations
	  #   so everything repeats every len(phasemask)/qsp.ints rows
	  intmask := array(F,len(phasemask));
	  nRowPerInt := len(phasemask)/qsp.ints;
	  for (thisInt in int) {
	      firstRow := nRowPerInt*(thisInt-1) + 1;
	      lastRow := firstRow + nRowPerInt - 1;
	      intmask[firstRow:lastRow] := T;
	  }
      } else {
	  intmask := array(T,len(phasemask));
      }

      feedmask:=[nfeed==qsp.feeds];
      # for non-phase selected data, other feed has same information but
      # never matches first phase
      if (is_boolean(phase)) {
	  if (sum(phasemask & feedmask) == 0) {
	      phasemask:=[qsp.phases==max(qsp.phases)];
	  }
      }
      #historically filled data has feeds tracking spwins
      if (all(normspwin==qsp.feeds)) feedmask:=[qsp.feeds==qsp.feeds];
      subind:=indices[phasemask & spwinmask & feedmask & intmask];
      if (len(subind)==0) {
	  dl.log(message='No rows matching parameters - try again',
		 priority='SEVERE',postcli=T);
	  return F;
      };
      return subind;
  }

const public.getr:=function(scan=F,phase=F,int=F,pol=F,nif=F,nfeed=1)
{
   wider private,public;

   if (is_boolean(scan) || is_boolean(phase)) {
       dl.log(message='Must specify a scan and phase',
	      priority='SEVERE',postcli=T);
       return F;
   };

   # toggle off use of corrected data
   ok:=eval(public.files(T).filein).usecorrecteddata(F);

   subind := private.getSubind(scan, phase, int, pol, nif, nfeed, F);

   if (len(subind)>1) {
       ok:=public.unlock();
       avgrec:=public.aver(scan,subind);
   } else {
       avgrec:=public.getscan(scan,subind,resync=T);
   };
   ok:=public.unlock();	
   if (!is_boolean(pol)) avgrec:=public.getpol(avgrec,pol);
 
   #toggle back
   ok:=eval(public.files(T).filein).usecorrecteddata(T);
   
   public.uniput('globalscan1',avgrec);
   return avgrec;		# 
}; #end of getr

const public.getc:=function(scan=F,int=F,pol=F,nif=F,nfeed=1) 
{   
   wider private,public;

   subind := private.getSubind(scan, F, int, pol, nif, nfeed, F);

   if (len(subind)>1) {
        ok:=public.unlock();
	avgrec:=public.aver(scan,subind);
   } else {
        avgrec:=public.getscan(scan,subind,resync=T);
   };
   if (!is_boolean(pol)) avgrec:=public.getpol(avgrec,pol);


   public.uniput('globalscan1',avgrec);
   return avgrec;
}; #end of getc

# function to plot uncalibrated data with optional averaging
const public.plotr := function(scan=F,phase=F,int=F,pol=F,nif=F,nfeed=1)
{
   wider public,private;

   tmp:=public.getr(scan,phase,int,pol,nif,nfeed)
   if (!is_sdrecord(tmp)) {
        print 'ERROR: Not an SDRecord';
        return F;
   };
   ok:=public.plotscan(tmp);
   return T;
}

# function to plot calibrated data with optional averaging
const public.plotc := function(scan,int=F,pol=F,nif=F,nfeed=1)
{
   wider public,private;

   tmp:=public.getc(scan,int,pol,nif,nfeed);
   if (!is_sdrecord(tmp)) {
        print 'ERROR: No SDRecord found';
        return F;
   };
   ok:=public.plotscan(tmp);
   return T;
}

const public.setsigma := function(sigma, scan,int=F,pol=F,nif=F,nfeed=1)
{
    wider private, public;
    subind := private.getSubind(scan, F, int, pol, nif, nfeed, F);
    msname:=eval(public.files(T).filein).name();
    #technique to avoid sticky table locking issues
    ok:=public.unlock();
    mytab:=table(msname,readonly=F,ack=F);
    if (is_fail(mytab)) print 'table creation failed';
    
    subtab:=private.scanQuery(mytab,scan);
    result := T;
    if (subtab.nrows()==0) {
	dl.log(message='No matching scans found',priority='SEVERE',postcli=T);
	subtab.done();
	mytab.done();
	public.lock();
	result := F;
    } else {
	sigmaCol := subtab.getcol('SIGMA');
	# pol is handled here
	polMask := array(T,sigmaCol::shape[1]);
	if (!is_boolean(pol)) {
	    polMask := array(F, len(polMask));
	    polMask[pol] := T;
	}
	for (i in ind(polMask)) {
	    if (polMask[i]) sigmaCol[i,subind] := sigma;
	}
	ok := subtab.putcol('SIGMA',sigmaCol);
	ok:=subtab.flush();
    }
    ok:=subtab.done();
    ok:=mytab.done();
    ok:=public.lock();
    return result;
}

const public.msbase := function(scan,range=F,order=1,nif=-1) 
{
    wider public;
    wider private;

    if (len(range) < order) {
	dl.log(message='Not enough points in range for the desired order fit',postcli=T,priority='WARN');
	return T;
    }

    if (is_boolean(private.ffitter)) private.ffitter := functionfitter();

    ok := public.uniput('baseline',T);
    ok := public.uniput('order', order);

    ok := public.unlock();

    scansFound := F
    for (thisScan in scan) {
	scansFound := any(public.listscans()==thisScan);
	if (scansFound) break;
    }
    if (!scansFound) {
        dl.log(message='No such scan(s)',priority='SEVERE',postcli=T);
        return F;
    };
    msname:=eval(public.files(T).filein).name();
    mytab:=table(msname,readonly=F,ack=F);
    if (is_fail(mytab)) print 'table creation failed';

    pf := dfs.poly(order);
    private.ffitter.setfunction(pf);

    for (thisScan in scan) {
	subtab:=private.scanQuery(mytab,scan,nif);
	if (subtab.nrows()>0) {
	    dl.log(message=spaste('fitting scan: ', thisScan), postcli=T, priority='NORM');
	    # loop over data_desc_id
	    ddid := unique(subtab.getcol("DATA_DESC_ID"));
	    for (thisDD in ddid) {
		ddsub := subtab.query(spaste("DATA_DESC_ID=",thisDD));
		if (ddsub.nrows() > 0) {
		    mydata := real(ddsub.getcol('CORRECTED_DATA'));
		    flags := ddsub.getcol('FLAG');
		    fullrange := as_double(1:mydata::shape[2]);
		    # need to scale x-axis values for high-order accuracy
		    if (!range) {
			range:=fullrange;
		    } else {
			# makes sure everything is in bounds
			range[range<1] := 1;
			range[range>len(fullrange)] := len(fullrange);
			range := unique(range);
		    }
		    maxrange := max(fullrange);
		    fullrange /:= maxrange;
		    rangeMask := array(F,mydata::shape[2]);
		    rangeMask[range] := T;
		    anyFlags := sum(flags) > 0;
		    for (k in 1:mydata::shape[1]) {
			for (j in 1:mydata::shape[3]) {
			    if (anyFlags) {
				thisMask := rangeMask & !flags[k,,j];
			    } else { 
				thisMask := rangeMask;
			    }
			    if (sum(thisMask) > 0) {
				if (sum(thisMask) < order) {
				    dl.log(message=spaste('Not enough data found in range for a fit of the desired order for scan ',thisScan),
					   postcli=T,priority='WARN');
				} else {
				    private.ffitter.setdata(fullrange[thisMask], mydata[k,thisMask,j]);
				    # There may be a bug in linear here, but linear=F behaves
				    # the way I expect it to and linear=T does not
				    # but that means setparameters needs to be called to avoid
				    # an error message
				    private.ffitter.setparameters(pf.parameters());
				    private.ffitter.fit(linear=F);
				    pf.setparameters(private.ffitter.getsolution());
				    mydata[k,,j] -:= pf.f(fullrange);
				} # else all is flagged, nothing to fit
			    }
			}
		    }
		    ok := ddsub.putcol('CORRECTED_DATA',mydata);
		} # don't warn if one was missing, although it should never happen
		ddsub.done();
	    }
	} else {
	    dl.log(message=spaste('No data found for scan ',thisScan),postcli=T,priority='WARN');
	}
	subtab.done();
    }
    mytab.done();

    ok := public.lock();
}

const public.calib:=function(scan,baseline=F,range=F,order=1,units=0,flipsr=F,
        fold=F,flipfold=F,calceffs=T)
{
   wider public;
 
   ok := public.uniput('baseline', baseline);
   ok := public.uniput('order', order);

   ok:=any(public.listscans()==scan[1]);
   if (ok==F) {
        dl.log(message='No such scan',priority='SEVERE',postcli=T);
        return F;
   };

   rec:=public.getscan(scan[1],1);

   #technique to avoid sticky table locking issues
   ok:=public.unlock();

   procseqn:=rec.other.state.NRAO_GBT_PROCSEQN;
   procsize:=rec.other.state.NRAO_GBT_PROCSIZE;
   if ((procsize <= 0 || procseqn <= 0) && has_field(rec.other,'gbt_go')) {
       # fall back to getting these from the GO subtable, if present
       procseqn:=rec.other.gbt_go.PROCSEQN;
       procsize:=rec.other.gbt_go.PROCSIZE;
   }
   if (procsize <= 0) procsize := 1;
   if (len(scan)==1) {
       # reconstruct the likely sequence
       startscan := scan - procseqn + 1;
       endscan := startscan + procsize - 1;
       scans := startscan:endscan;
       # are those scans all available
       # this could be better - since its possible the sequence was
       # interrupted prematurely which would not be caught here if a new
       # sequence was started at the expected next scan number in the sequence
       allScans := public.listscans();
       scansInSequence := allScans[allScans>=startscan & allScans<=endscan];
       if (len(scans) != len(scansInSequence)) {
	   print 'WARNING: Not all scans in the procedure are present';
	   print 'WARNING: Calibrating only those present';
	   scans := scansInSequence;
       }

       msname:=eval(public.files(T).filein).name();
       ok := gbtcalscans(msname, scans, baseline, range, order, units, flipsr,
			 fold, flipfold, calceffs);
   } else {
       for (i in scan) {
	   # recursively call calib on each scan
	   ok:=public.calib(i,baseline,range,order,units,flipsr,fold,
			    flipfold,calceffs);
	   if (!ok) {
	       public.lock();
	       return F;
	   }
       };
   }; #end scan length condition

   ok:=public.lock();

   return ok;
}; #end calib procedure;

#provide links to attempt to force certain types of calibration

# frequency switched
const public.FScal:=function(scan,baseline=F,range=F,order=1,units=0,flipsr=F,
			     fold=F,flipfold=F,calceffs=T) 
{
   wider public;
   msname:=eval(public.files(T).filein).name();
   ok:=gbtcalscans(msname,scan,baseline,range,order,units,flipsr,fold,flipfold,calceffs=calceffs,type="FS");
   return ok;
};


const public.BScal:=function(scan,baseline=F,range=F,order=1,units=0,flipsr=F,
			     fold=F,flipfold=F,calceffs=T)
{
   wider public;
   msname:=eval(public.files(T).filein).name();
   ok:=gbtcalscans(msname,scan,baseline,range,order,units,flipsr,fold,flipfold,calceffs=calceffs,type="Nod");
   return ok;
};

const public.TPcal:=function(scan,baseline=F,range=F,order=1,units=0,flipsr=F,
			     fold=F,flipfold=F,calceffs=T)
{
    wider public;
    msname:=eval(public.files(T).filein).name();
    ok:=gbtcalscans(msname,scan,baseline,range,order,units,flipsr,fold,flipfold,calceffs=calceffs, type="TP");
    return ok;
};

const public.SRcal := function(scans,refscans,baseline=F,range=F,order=1,
			       units=0, calceffs=T, nif=-1){
    wider public;
    wider private;
    
    #technique to avoid sticky table locking issues
    ok:=public.unlock();

    msname:=eval(public.files(T).filein).name();
    mytab:=table(msname,readonly=F,ack=F);
    if (is_fail(mytab)) print 'table creation failed';

    #  test if refscans is an SDRecord
    if (!is_sdrecord(refscans)) {
	#not an sdrecord - must be a vector of scans
	if (!is_integer(refscans)) {
	    dl.log(message='refscans parameter not integers',priority='SEVERE',
		   postcli=T);
	    return F;
	};
	dl.note('Assumes all scans have been calibrated...');
	# now average refscans
	scanstats:=public.qscan(refscans[1]);
	refaverage:=[=];
	for (i in 1:scanstats.ifs) {
	    refaverage[i]:=public.aver(refscans,
				       spaste(i,'/',scanstats.ifs*scanstats.phases));
	};
	tsys_ref:=refaverage[1].header.tsys;
	refda:=refaverage[1].data.arr;
	if (len(refaverage)!=1) {
	    refda:=array(refda,refda::shape[1],refda::shape[2],scanstats.ifs);
	    for (i in 2:scanstats.ifs) {
		refda[,,i]:=refaverage[i].data.arr;
	    };
	};
	if (nif != -1) {
	    dl.log(message='nif parameter is ignored when vector of scans is given',
		   priority='WARN',postcli=T);
	    nif:=-1;
	}
    } else {
	#it is an SDRecord
	refaverage:=ref refscans;
	tsys_ref:=refaverage.header.tsys;
	refda:=refaverage.data.arr;
	if (nif == -1) nif := 1;
    }; #end refscans check

    ok:=public.unlock();
    
    ok:=public.geteff(scans[1],units=units, calceffs=calceffs);
    ok:=public.unlock();
    
    # now perform the sig - ref / ref;
    # need to put checks on data array shapes
    
    subtab:=private.scanQuery(mytab,scans,nif);
    subscans:=1:subtab.nrows();
    if (subtab.nrows()==0) {
	dl.log(message='No scans found',priority='SEVERE',postcli=T);
	ok:=subtab.done();
	ok:=mytab.done();
	ok:=public.lock();
	return F;
    };
    # get info to obtain SYSCAL table
    expos:=subtab.getcol('EXPOSURE');
    times:=subtab.getcol('TIME');
    global _btime:=min(times);
    global _etime:=max(times);
    subscans:=1:subtab.nrows();
    tabsyscal:=table(subtab.getkeyword('SYSCAL'),readonly=F,ack=F);
    subsyscal:=tabsyscal.query('TIME<=($_etime+1) && TIME>=($_btime-1)');
    if (subsyscal.nrows()==0) {
	dl.log(message='No times in range for SYSCAL table',priority='SEVERE',
	       postcli=T);
	ok:=subsyscal.done();
	ok:=tabsyscal.done();
	ok:=subtab.done();
	ok:=mytab.done();
	ok:=public.lock();
	return F;
    };
    syscalnames:=tabsyscal.colnames();
    if (any(syscalnames=='TSYS')) { # 
	tsys:=subsyscal.getcol('TSYS');
    } else {
	dl.note('No TSYS column found; will not store TSYS',priority='WARN')
	};
    tsys_sig:=tsys;
    for (i in 1:len(tsys_ref)) {
	tsys_sig[i,]:=tsys_ref[i];
    };
    subsyscal.putcol('TSYS',tsys_sig);
    subsyscal.flush();
    subsyscal.done();
    tabsyscal.done();

    mydata:=subtab.getcol('CORRECTED_DATA');
    myweight:=subtab.getcol('WEIGHT');
    mysigma:=subtab.getcol('SIGMA');
    mytexp := subtab.getcol('EXPOSURE');
    mydd := subtab.getcol('DATA_DESC_ID') + 1;
    # translate to spw id
    ddtab := table(subtab.getkeyword('DATA_DESCRIPTION'));
    spwid := ddtab.getcol('SPECTRAL_WINDOW_ID')+1;
    for (dd in unique(mydd)) {
	if (dd > 0) {
	    mydd[mydd==dd] := spwid[dd];
	}
    }
    ddtab.done();
    # translate it to channel width at center
    spwtab := table(subtab.getkeyword('SPECTRAL_WINDOW'));
    nmid := as_integer(mydata::shape[2]/2.0+0.5);
    chwid := array(1.0,len(mydd));
    for (spw in spwid) {
	chwid[mydd==spw] := abs(spwtab.getcell('CHAN_WIDTH',spwid)[nmid]);
    }
    denom := sqrt(mytexp * chwid);
    spwtab.done();
    
    myrefarray:=array(refda,refda::shape[1],refda::shape[2],mydata::shape[3]);
    #do each pol separately
    if (!all(myrefarray::shape==mydata::shape)) {
	dl.log(message='Sig/Ref shapes incompatible',priority='SEVERE',postcli=T);
	#done all
	subtab.done();
	mytab.done();
	return F;
    };
    for (i in 1:mydata::shape[1]) {
	tsys_sig:=mean(tsys[i,]);
	mydata[i,,]:=(tsys_ref[i])*(mydata[i,,]-myrefarray[i,,])/
	    myrefarray[i,,];
       mysigma[i,] := tsys_sig / denom;
    };
    #       Correct for tau/eff
    mydata *:= public.uniget('factor');
    if (baseline) {
	if (!range) range:=1:mydata::shape[2];
	for (k in 1:mydata::shape[1]) {
	    ok:=private.poly.multifit(coeff=coeff,coefferrs=coefferrs,
				      chisq=chisq,x=range,y=mydata[k,range,subscans],order=order);
	    ok:=private.poly.eval(y,1:mydata::shape[2],coeff);
	    mydata[k,,subscans]-:=y;
	};			# 
    };
    dl.note('Writing data back to MS...');
    ok:=subtab.putcol('CORRECTED_DATA',mydata);
    if (is_boolean(units)) {
	myunits:='TA*';
    } else {
	myunits:=public.uniget('units');
    };
    ok:= subtab.putcolkeyword('CORRECTED_DATA','QuantumUnits',myunits);
    ok:=subtab.putcol('SIGMA',mysigma);
    subtab.flush();
    subtab.done();
    mytab.done();
    ok:=public.lock();
    if (!ok) dl.note(spaste('Failed to re-acquire lock on ',
			    public.files(T).filein), priority='WARNING');
    return T;
}

const public.getdbs := function(scan,int=F,pol=F) {
 wider private;
 s1 := d.getc(scan,int,pol)
 s2 := d.getc(scan+1,int,pol)
 s2.data.arr -:= s1.data.arr
 s2.data.arr /:= -2
 s2.header.exposure +:= s1.header.exposure
 s2.header.duration +:= s1.header.duration
 ok:=d.uniput('globalscan1',s2)
 return ok;
}

#function to calibrate an MS
public.mscal := function(baseline=F,range=F,order=1,units=0,calceffs=T) {
        wider public;
        scans:=public.gms(scans=T);
	result := T;
	for (scan in scans) {
	    result := public.calib(scan,baseline,range,order,units,calceffs=calceffs);
	    if (!result) break;
	}
	return result;
};

  return T;
}
