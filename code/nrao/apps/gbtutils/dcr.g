## dcr tool for the GBT
# Copyright (C) 1999,2000,2002,2003
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

#pragma include once
include 'statistics.g'
include 'quanta.g'
include 'polyfitter.g'
myfit := polyfitter()
include 'pgplotter.g'
dcrpg := pgplotter()
include 'measures.g'

dcr:=subsequence(filename=unset)
{
 include 'gfitgauss.g'
 if (is_unset(filename))
  return throw('A MS must be provided to start the DCR tool.')
 self.maintable:=table(filename,lockoptions='usernoread',ack=F);
 if (is_fail(self.maintable)) 
  return throw('Fatal error: Table not loaded');

 self.stateTable := table(self.maintable.getkeyword('GBT_DCR_STATE'),
			  lockoptions='usernoread', ack=F)
 self.procTable := table(self.maintable.getkeyword('PROCESSOR'),
			 lockoptions='usernoread', ack=F)
 self.GBT_DCR_table := table(self.maintable.getkeyword('GBT_DCR'),
			     lockoptions='usernoread', ack=F)
 self.GBT_DCR_STATE_table := table(self.maintable.getkeyword('GBT_DCR_STATE'),
				   lockoptions='usernoread', ack=F)
 mainKWs := self.maintable.keywordnames();
 if (any(mainKWs=='GBT_GO')) {
     self.GOSubTable := table(self.maintable.getkeyword('GBT_GO'),
			      lockoptions='usernoread', ack=F);
 } else {
     if (any(mainKWs == "NRAO_GBT_GO")) {
	 self.GOSubTable := table(self.maintable.getkeyword('NRAO_GBT_GO'),
				  lockoptions='usernoread', ack=F);
     } else {
	 self.GOSubTable := table(self.maintable.getkeyword('NRAO_GBT_GLISH'),
				  lockoptions='usernoread', ack=F);
         # give up at this point - either it works or it doesn't
     }
 }
 self.pointTable := table(self.maintable.getkeyword('POINTING'),
			  lockoptions='usernoread', ack=F)
 self.fieldTable:=table(self.maintable.getkeyword('FIELD'),
			lockoptions='usernoread', ack=F)
 self.sourceTable:=table(self.maintable.getkeyword('SOURCE'),
			 lockoptions='usernoread', ack=F)
 self.focusTable := table(self.maintable.getkeyword('NRAO_GBT_MEAN_FOCUS'),
			  lockoptions='usernoread', ack=F)
 self.pModelTable := table(self.maintable.getkeyword('NRAO_GBT_POINTING_MODEL'),
			   lockoptions='usernoread', ack=F)
 self.calTable := table(self.maintable.getkeyword('SYSCAL'),
			lockoptions='usernoread', ack=F)
 self.dataDescTable := table(self.maintable.getkeyword('DATA_DESCRIPTION'),
			     lockoptions='usernoread', ack=F)
 self.polTable := table(self.maintable.getkeyword('POLARIZATION'),
			lockoptions='usernoread', ack=F)

##############

# Begin private functions
private:=[=];
private.scanNum := -1
private.rcvrNum := -1
private.phaseNum := -1

private.getAllMask := function(rcvr,phase) 
{
 wider private,self;
 receivers:=self.maintable.getcol("NRAO_GBT_SAMPLER_ID");
 phases:=self.maintable.getcol("NRAO_GBT_STATE_ID");
 mask:=(receivers==rcvr) & (phases==phase);
 return mask;
}

private.get_sr_cal_mask := function(rcvr,sigref,cal)
{
 wider private,self;
 datadesc := self.scantable.getcol("NRAO_GBT_SAMPLER_ID");
 state := self.scantable.getcol("NRAO_GBT_STATE_ID");
 global datadescIds := unique(datadesc)+1
 global stateIds := unique(state)+1
 stateTable := self.stateTable.query('rownumber() in $stateIds')

 dataDescMask:=-1
 stateMask:=-1
 rcvrId := unique(datadesc)
 cnt := 0
 for (i in (datadescIds-1))
  {
  cnt +:= 1
  if (rcvrId[cnt]==rcvr) dataDescMask := i
  }

 sigrefId := stateTable.getcol('SIGREF')
 calId := stateTable.getcol('CAL')
 cnt := 0
 for (i in (stateIds-1))
  {
  cnt +:= 1
  if ((sigrefId[cnt]==sigref) && (calId[cnt]==cal)) stateMask := i
  }

 if ((dataDescMask==-1) || (stateMask==-1))
  return throw('Error in finding masks',dataDescMask,stateMask)

 allDataDesc := self.scantable.getcol('NRAO_GBT_SAMPLER_ID')
 allState := self.scantable.getcol('NRAO_GBT_STATE_ID')
 mask := (allDataDesc==dataDescMask)&(allState==stateMask)
 return mask
}

private.getmask := function(scan,rcvr,sigref,cal)
{
 wider private,self;
 oneScanTable:=self.maintable.query(paste('SCAN_NUMBER==',scan))
 datadesc := oneScanTable.getcol("NRAO_GBT_SAMPLER_ID");
 state := oneScanTable.getcol("NRAO_GBT_STATE_ID");
 global datadescIds := unique(datadesc)+1
 global stateIds := unique(state)+1
 stateTable := self.stateTable.query('rownumber() in $stateIds')

 dataDescMask:=-1
 stateMask:=-1
 rcvrId := unique(datadesc)
 cnt := 0
 for (i in (datadescIds-1))
  {
  cnt +:= 1
  if (rcvrId[cnt]==rcvr) dataDescMask := i
  }

 sigrefId := stateTable.getcol('SIGREF')
 calId := stateTable.getcol('CAL')
 cnt := 0
 for (i in (stateIds-1))
  {
  cnt +:= 1
  if ((sigrefId[cnt]==sigref) && (calId[cnt]==cal)) stateMask := i
  }

 if ((dataDescMask==-1) || (stateMask==-1))
  return throw('Error in finding masks')

 allScan := self.maintable.getcol('SCAN_NUMBER')
 allDataDesc := self.maintable.getcol('NRAO_GBT_SAMPLER_ID')
 allState := self.maintable.getcol('NRAO_GBT_STATE_ID')
 mask := (allScan==scan)&(allDataDesc==dataDescMask)&(allState==stateMask)
 return mask
}

private.getsrpmask:=function(scan,rcvr,phase)
{
 wider private,self;
 scans:=self.maintable.getcol('SCAN_NUMBER');
 allrcvrs := self.maintable.getcol("NRAO_GBT_SAMPLER_ID")
 allphases := self.maintable.getcol("NRAO_GBT_STATE_ID")
 oneScanTable:=self.maintable.query(paste('SCAN_NUMBER==',scan))
 rcvrs := oneScanTable.getcol("NRAO_GBT_SAMPLER_ID")
 phases := oneScanTable.getcol("NRAO_GBT_STATE_ID")
 uniquercvrs := unique(rcvrs)
 uniquephases := unique(phases)
 scanmask:=scan==scans 
 rcvrmask:=uniquercvrs[as_integer(rcvr)+1]==allrcvrs
 phasemask:=uniquephases[as_integer(phase)+1]==allphases
 mask := scanmask&rcvrmask&phasemask
 return mask
}

private.getRPmask := function(rcvr,phase) 
{
 wider private,self;
 allrcvrs := self.scantable.getcol("NRAO_GBT_SAMPLER_ID")
 allphases := self.scantable.getcol("NRAO_GBT_STATE_ID")
 uniquercvrs := unique(allrcvrs)
 uniquephases := unique(allphases)
 rcvrmask:=uniquercvrs[as_integer(rcvr)+1]==allrcvrs
 phasemask:=uniquephases[as_integer(phase)+1]==allphases
 mask := rcvrmask&phasemask
 return mask
}

self.listscans:=function() 
{
 wider self,private;
 return unique(self.maintable.getcol('SCAN_NUMBER'));
}

private.scanlist:=function() 
{
 wider self,private;
 return unique(self.maintable.getcol('SCAN_NUMBER'));
}

# necessary for the toolmanager
self.type := function() {return 'dcr'};
 
# necessary for the toolmanager
self.done:=function()
{
 wider self, private;
# pg.done()
 for (field in self) {
     if (is_table(field)) field.done();
 }
 val self:=F;
 private.cgui.main := F ;
 note('DCR tool closed properly',origin='DCR')
 return T;
}

private.getDcrTcalValues := function()
{
    wider self, private;
    # returns the vector of tcal values appropriate for the current
    # self.scantable (already selected on the indicated scan)
    # one value per CHANNELID in the DCR FITS file.
    # In the MS, NRAO_GBT_SAMPLER_ID corresponds to CHANNELID

    samplerIds := self.scantable.getcol('NRAO_GBT_SAMPLER_ID')+1;
    dataDescIds := self.scantable.getcol('DATA_DESC_ID')+1;
    uChanIds := unique(samplerIds);
    result := array(1.0, len(uChanIds));

    caltime := self.calTable.getcol('TIME');
    timemask := self.scantable.getcol('TIME')[1]==caltime;

    global calRows := [1:self.calTable.nrows()][timemask];
    calQuery := self.calTable.query('rownumber() in $calRows');
    if (calQuery.nrows() < 1) {
	dl.log(message='Error in Tcal retrieval',priority='SEVERE',postcli=T);
	dl.log(message='Using Tcal = 1',priority='SEVERE',postcli=T);
	dl.log(message='Contact Jim Braatz about this.',priority='SEVERE',postcli=T);
	print len(calRows), private.info.nrcvrs, len(uChanIds);
    } else {
	# ddids and feedids for each unique CHANNELID
	ddids := array(-1,len(uChanIds));
	feedids := array(-1,len(uChanIds));
	feedCol := self.scantable.getcol('FEED1');
	ddidCol := self.scantable.getcol('DATA_DESC_ID')+1;
	for (chanid in uChanIds) {
	    repRow := (ind(samplerIds)[samplerIds==chanid])[1];
	    ddids[chanid] := ddidCol[repRow];
	    feedids[chanid] := feedCol[repRow];
	}
	# it might make sense to just cache the pol IDs and data 
	# desc IDs from the main table
	polidCol := self.dataDescTable.getcol('POLARIZATION_ID');
	spwidCol := self.dataDescTable.getcol('SPECTRAL_WINDOW_ID');
	tcalErrorGiven := False;
	for (ddrow in unique(ddids)) {
	    theseFeeds := unique(feedids[ddids==ddrow]);
	    thisSpwId := spwidCol[ddrow];
	    # DCR always has rcpt1==rcpt2, no cross-corr and currently there's just one corr
	    # per row of the MS
	    thisCorrProd := self.polTable.getcell('CORR_PRODUCT',(polidCol[ddrow]+1));
	    rcpt1 := thisCorrProd[1,1]+1;
	    for (thisFeed in theseFeeds) {
		# final selection - time was already done in calQuery
		thisCalQuery := calQuery.query(spaste('FEED_ID==',thisFeed,' && SPECTRAL_WINDOW_ID==',
						      thisSpwId));
		tcalMask := (feedids == thisFeed) & (ddids==ddrow);
		if ((len(tcalMask) < 1 ||  thisCalQuery.nrows() != 1) && !tcalErrorGiven) {
		    dl.log(message='Partial error in Tcal retrieval',priority='SEVERE',postcli=T);
		    dl.log(message='Using Tcal = 1 for some feeds',priority='SEVERE',postcli=T);
		    dl.log(message='Contact Jim Braatz about this.',priority='SEVERE',postcli=T);
		    print thisFeed, ddrow, len(tcalMask), thisCalQuery.nrows();
		    tcalErrorGiven := True; # only emit that once
		} else {
		    # all these rows should now have the same shape, pull off rcpt1 from them
		    result[tcalMask] := thisCalQuery.getcell('TCAL',1)[rcpt1];
		}
		thisCalQuery.done();
	    }
	}
	calQuery.done();
    }
    print 'getDcrTcalValues returns with :', result;
    return result;
}

########################################
# Begin list of returned functions/tools
########################################

private.scaninfo:=function(scan)
{
 wider self,private;
 private.info := [=]
 private.scantype := self.guessmode(scan);
 thetime := self.currentscan.time[1]
 starttime:=dq.unit(thetime[1],'s');
 startdate:=dq.time(starttime,form='dmy');

 global stateIds := unique(self.scantable.getcol('NRAO_GBT_STATE_ID'))+1;
 if (len(stateIds)==1) stateIds[2] := -1
 global processorIds := unique(self.scantable.getcol('PROCESSOR_ID'))+1;
 if (len(processorIds)==1) processorIds[2] := -1
 else return throw('Problem in scaninfo!')
 global typeIds := unique((self.procTable.query('rownumber() in $processorIds')).getcol('TYPE_ID'))+1;
 if (len(typeIds)==1) typeIds[2] := -1
 else return throw('Problem in scaninfo!!')
 global fieldids:=unique(self.scantable.getcol('FIELD_ID'))+1;
 #		tablequery demands an array on the right side of an 'in' so
 #		oblige with a dummy variable in instances of len(phaseids)=1
 if (len(fieldids)==1) fieldids[2]:=-1;
 else return throw('greater than 1 fieldid for this scan?  Check on it.')

 GBT_DCR_table := self.GBT_DCR_table.query('rownumber() in $typeIds')
 private.info.cycletim:=GBT_DCR_table.getcol('CYCLETIM');
 private.info.cycles:=GBT_DCR_table.getcol('CYCLES');
 private.info.nphases:=GBT_DCR_table.getcol('NPHASES');
 private.info.inpbnk:=GBT_DCR_table.getcol('INPBNK');
 private.info.nrcvrs:=GBT_DCR_table.getcol('NRCVRS');
 rcvrs:=(1:private.info.nrcvrs)-1
 private.info.rcvrs := rcvrs

 GBT_DCR_STATE_table := self.GBT_DCR_STATE_table.query('rownumber() in $stateIds')
 private.info.blanktim:=GBT_DCR_STATE_table.getcol("BLANKTIM")[1];
 private.info.phasetim:=GBT_DCR_STATE_table.getcol("PHASETIM")[1];
 tmp_tsys[private.info.rcvrs+1] := F
 if (private.scantype=='SWwC' || private.scantype=='SymTPwC' || 
     private.scantype=='TPwC')
  for (ii in private.info.rcvrs)
   tmp_tsys[ii+1] := private.tsys(ii)
 srcRA := self.currentscan.GO_header.RA
 srcDEC := self.currentscan.GO_header.DEC
 private.info.procseqn := as_integer(self.currentscan.GO_header.PROCSEQN)
 private.info.procsize := as_integer(self.currentscan.GO_header.PROCSIZE)
 private.info.proctype := self.currentscan.GO_header.PROCTYPE
 if (srcDEC < 0) {signDec := '-'; srcDEC := abs(srcDEC); }
 else signDec := ' '
 srcRA1 := as_integer(srcRA/360*24)
 srcRA2 := as_integer((srcRA - srcRA1/24*360)/360*24*60)
 srcRA3 := (srcRA - srcRA1/24*360 - srcRA2/60/24*360)/360*24*60*60
 srcDEC1 := as_integer(srcDEC)
 srcDEC2 := as_integer((srcDEC - srcDEC1)*60)
 srcDEC3 := as_integer((srcDEC - srcDEC1 - srcDEC2/60)*60*60)

 private.info.srcName := self.currentscan.GO_header.OBJECT
 private.cgui.textWin->append('\n\n****************** Scan Info *****************\n');
 private.cgui.textWin->append(sprintf('Scan     : %5d     Blanktime (s) : %7.5f\n',scan,private.info.blanktim));
 private.cgui.textWin->append(sprintf('Phases   : %5d     Phasetime (s) : %7.5f\n',private.info.nphases,private.info.phasetim));
 private.cgui.textWin->append(sprintf('Rcvrs    : %5d     Cycletime (s) : %7.5f\n',private.info.nrcvrs,private.info.cycletim));
 private.cgui.textWin->append(sprintf('ProcSeq  :   %1d/%1d     Proc Type     : %-s\n',private.info.procseqn,private.info.procsize,private.info.proctype))
 private.cgui.textWin->append(sprintf('DCR Bank :     %-s     Scan Type     : %s\n',private.info.inpbnk,private.scantype))
 private.cgui.textWin->append('\n');
 private.cgui.textWin->append(sprintf('Time     : %s (UT)  \n',startdate));
 private.cgui.textWin->append('\n');
 private.cgui.textWin->append(sprintf('Source   : %s   RA: %2d %02d %04.1f  Dec: %1s%2d %02d %02d\n',private.info.srcName,srcRA1,srcRA2,srcRA3,signDec,srcDEC1,srcDEC2,
 srcDEC3));
 private.cgui.textWin->append('\n');
 private.cgui.textWin->append(sprintf('Tsys     : '))
 for (ii in private.info.rcvrs)
  if (tmp_tsys[ii+1] == F)
   private.cgui.textWin->append('n/a     ')
  else
   private.cgui.textWin->append(sprintf('%6.2f   ',tmp_tsys[ii+1]))
 private.cgui.textWin->append('\n')
 private.cgui.textWin->append(sprintf('Tcal     : '))
 for (ii in private.info.rcvrs)
   private.cgui.textWin->append(sprintf('%6.2f   ',private.tcalvalues[ii+1]))
 private.cgui.textWin->append('\n')
 private.cgui.textWin->append('**********************************************');
 private.info.rcvrlist:=0:(private.info.nrcvrs-1);
 private.info.phaselist := 0:(private.info.nphases-1);
 return private.info;
}
 
self.getGO := function(scan)
{
 wider self,private;
 rec := [=]
 test:=private.sl
 if (len(test[test==scan])==0)
  return throw('FAILED: Scan not found');

 GOSubTable := self.GOSubTable.query(paste('SCAN == ',scan,sep=""));
 if (is_fail(GOSubTable)) 
  return throw ('Error in getGO -- no GO info found');
 if (GOSubTable.nrows() == 0) 
  return throw ('Error in getGO -- no GO info found: nrows=0');
 if (GOSubTable.nrows() != 1) 
  note('WARNING!  >1 entry in GO subtable.  Using the first.',
  priority='WARN')
 trow := tablerow(GOSubTable)
 rec := trow.get(1)
 GOSubTable.close()
 trow.close()
 if (rec.COORDSYS != 'RADEC' & rec.COORDSYS != 'AZEL') {
  print 'Cannot handle coordinate systems other than RADEC and AZEL yet.'
  print 'Results for this scan will likely fail.'
  return throw ('Error in getGO')
  }
 if (!has_field(rec,'RA')) {
  rec.RA := rec.MAJOR
  rec.DEC := rec.MINOR
  }
 if (rec.EQUINOX == 1950) {
  b1950_position := dm.direction('B1950',paste(rec.RA,'deg',sep=""),
                    paste(rec.DEC,'deg',sep=""))
  j2000_position := dm.measure(b1950_position,'J2000')
  rec.RA := j2000_position.m0.value/pi*180
  rec.DEC := j2000_position.m1.value/pi*180
  }
 else if (rec.EQUINOX != 2000) {
  print 'GOpoint cannot handle the Equinox specified in this scan.'
  return throw('Error in getGO')
  }
 return rec
}

# Makes a guess at the DCR mode of the first subscan in a scan
# Cal OFF == 0          Cal ON == 1
# Sig     == 0          Ref    == 1
# This is a bit of monkey business that should hopefully go away once
# the scan log is in place and provides a tag to what type of observation
# each scan is.
self.guessmode:=function(scan)
{
 wider self,private;
 test:=private.sl
 if (len(test[test==scan])==0)
  return throw('FAILED: Scan not found');
 global stateids:=unique(self.scantable.getcol('NRAO_GBT_STATE_ID'))+1;
 if (len(stateids)==1) stateids[2]:=-1;
 #this selection crashes when there is only 1 element (!= array)
 stateSubTable:=self.stateTable.query("rownumber() in $stateids");
 sigref_:=stateSubTable.getcol("SIGREF");
 cal_ := stateSubTable.getcol("CAL");
 nphases_:=len(sigref_)

 c:=cal_[1]==0;
 sr:=sigref_[1]==0;
 if (nphases_ == 1)
  {
  if (c & sr)
   {
   note( "DCR mode: Total Power without Cal",origin='guessmode')
   return "TPnoC"
   }
  }
 if (nphases_ == 2)
  {
  c  := cal_[1:2]    == [0, 1]
  sr := sigref_[1:2] == [0, 0]
  if ((min(c) == 1) & (min(sr) == 1))
   {
   note( "DCR mode: Total Power with Cal",origin='guessmode')
   return "TPwC"
   }
  c  := cal_[1:2]    == [0, 0]
  sr := sigref_[1:2] == [0, 1]
  if ((min(c) == 1) & (min(sr) == 1))
   {
   note( "DCR mode: Switched Power without Cal",origin='guessmode')
   return "SWnoC"
   }
  }
 if (nphases_ == 3) 
  {
  c  := cal_[1:3]    == [0, 1, 0]
  sr := sigref_[1:3] == [0, 0, 0]
  if ((min(c) == 1) & (min(sr) == 1))
   {
   note( "DCR mode: Symmetric Total Power with Cal",origin='guessmode')
   return "SymTPwC"
   }
  c  := cal_[1:3]    == [0, 0, 0]
  sr := sigref_[1:3] == [0, 1, 0]
  if ((min(c) == 1) & (min(sr) == 1))
   {
   note( "DCR mode: Symmetric Switched Power without Cal",origin='guessmode')
   return "SymSWnoC"
   }
  }
 if (nphases_ == 4)
  {
  c  := cal_[1:4]    == [0, 1, 0, 1]
  sr := sigref_[1:4] == [0, 0, 1, 1]
  if ((min(c) == 1) & (min(sr) == 1))
   {
   note( "DCR mode: Switched Power with Cal",origin='guessmode')
   return "SWwC"
   }
  }
 if (nphases_ == 9)
  {
  c  := cal_[1:9]    == [0, 1, 0, 0, 1, 0, 0, 1, 0]
  sr := sigref_[1:9] == [0, 0, 0, 1, 1, 1, 0, 0, 0]
  if ((min(c) == 1) & (min(sr) == 1))
   {
   note( "DCR mode: Symmetric Switched Power with Cal",origin='guessmode')
   return "SymSWwC"
   }
  }
 note( "Unknown DCR mode",origin='guessmode')
 return "Undef" 
}

private.tsys:=function(receiver) 
{
 wider self,private;

 tcal := private.tcalvalues[receiver+1]
 if (private.scantype!='SWwC' && private.scantype!='SymTPwC'&& 
     private.scantype!='TPwC')
  {
  note( 'Insufficient information for Tsys calc',origin='tsys');
  return 0;
  }
  
  if (private.info.nphases==2) {
   refmask:=private.get_sr_cal_mask(receiver,0,0);
   refcalmask:=private.get_sr_cal_mask(receiver,0,1);
   alldata:=self.scantable.getcol('FLOAT_DATA');
   refdata:=sum(alldata[refmask])/len(alldata[refmask]);
   refcaldata:=sum(alldata[refcalmask])/len(alldata[refmask]);
   tsys:=tcal*(refdata/(refcaldata-refdata));
   }
  else if (private.info.nphases==4) {
   refmask:=private.get_sr_cal_mask(receiver,1,0);
   refcalmask:=private.get_sr_cal_mask(receiver,1,1);
   alldata:=self.scantable.getcol('FLOAT_DATA');
   refdata:=sum(alldata[refmask])/len(alldata[refmask]);
   refcaldata:=sum(alldata[refcalmask])/len(alldata[refmask]);
   tsys := tcal*(refdata/(refcaldata-refdata));
   }
  else {
   dl.log(message='Cannot calculate Tsys for this data',priority='WARNING',postcli=T)
   tsys := 0
   }
 return tsys
 }

self.tsys:=function(scan,receiver) 
{
 wider self,private;
 if (scan != private.scanNum)
  self.getscan(scan)
 if (self.test_srp(scan,receiver,0) || self.test_srp(scan,receiver,1))
  return throw('tsys error - illegal scan, receiver, or phase')
 if (private.scantype!='SWwC' && private.scantype!='SymTPwC'&& 
     private.scantype!='TPwC') {
   dl.log(message='Insufficient information for Tsys calc',priority='SEVERE',postcli=T)
  return F
  }
 return private.tsys(receiver)
}

 self.gauss:=function(xarray,yarray,ht,wd,ctr,plotflag=1) {
  wider self, private;
  ok:=setState([height=ht,width=wd,center=ctr]);
  ok:=setMaxIter(15);
  ymax := max(yarray)
  x2 := xarray[yarray>(ymax/2.5)]
  y2 := yarray[yarray>(ymax/2.5)]
  result:=fitGauss(x2,y2);
  yfit:=evalGauss(xarray);
  resid:=yarray-yfit;
  xarrayplot := seq(xarray[1],xarray[len(xarray)],
                (xarray[len(xarray)]-xarray[1])/200)
  yfitplot := evalGauss(xarrayplot)
  result.x := xarrayplot
  result.y := yfitplot
  if (plotflag)
   dcrpg.plotxy(xarrayplot,yfitplot,T,F,,,,3)
  result.chisq2 := sum(((yarray-yfit)^2/yfit))/(len(yarray)-3)
  return result;
 }

self.plot_tsrc_time:=function(scan,receiver,cal_value=1)
{ 
 wider self,private;
 if (scan != private.scanNum)
  self.getscan(scan)
 if (self.test_srp(scan,receiver,0))
  return throw('FAILED: scan or receiver not found')
 if (private.scantype != 'SWwC')
  return throw('Source Temp only available for Switched Power with Cal')
 dcrpg.clear()
 tyme:=self.currentscan.time-self.currentscan.time[1]
 data_ph1 := self.currentscan.data[receiver+1,1,]
 data_ph2 := self.currentscan.data[receiver+1,2,]
 data_ph3 := self.currentscan.data[receiver+1,3,]
 data_ph4 := self.currentscan.data[receiver+1,4,]
 counts_per_K1 := sum((data_ph2 - data_ph1) / cal_value) / length(data_ph2)
 counts_per_K2 := sum((data_ph4 - data_ph3) / cal_value) / length(data_ph2)
 cal_data1 := data_ph1 / counts_per_K1
 cal_data2 := data_ph3 / counts_per_K2
 bigcal_data:=(cal_data2-cal_data1);  
 private.cgui.textWin->append('\n\n********** Source Temperature Result **********\n');
 private.cgui.textWin->append(sprintf('Mean T(A) = %9.3f\n',mean(bigcal_data)));
 private.cgui.textWin->append('************************************************');
 dcrpg.plotxy(tyme,bigcal_data,T,T,'Time','Tsrc','Antenna Temp')
 return;
}

self.plot_focus_time := function(scan,param='SR_XP')
{
 wider private,self
 ok := self.getscan(scan,param)
 if (is_fail(ok)) return;
 foc := self.currentscan.FOCUS
 dcrpg.clear()
 if (min(foc)==max(foc))
  print 'Constant focus value = ',foc[1]
 else
  dcrpg.plotxy(self.currentscan.time-self.currentscan.time[1],foc,T,T,
            'Time',paste('Focus',param),'Focus')
}

self.focusScan := function(scan,receiver=0,cal_value=1,param='SR_XP',order=2,
                  archive=F)
{
 wider private,self
 ok := self.getscan(scan,param)
 if (is_fail(ok)) return;
 receiver := as_integer(receiver)
 foc := self.currentscan.FOCUS
 dcrpg.clear()
 data_ph1 := self.currentscan.data[receiver+1,1,]
 data_ph2 := self.currentscan.data[receiver+1,2,]
 counts_per_K := sum((data_ph2-data_ph1)/cal_value)/len(data_ph2)
 cal_data := data_ph1 / counts_per_K 

 az := self.currentscan.az
 el := self.currentscan.el

 if (min(foc)==max(foc))
  print 'Constant focus value = ',foc[1]
 else
  {
  dcrpg.sch(1.5)
  title := sprintf('Focus; Scan %d ; Rx %d ; Src %s ; Elv %6.2f',
           self.currentscan.scan,
           receiver,self.currentscan.GO_header.OBJECT,el)
  dcrpg.plotxy(foc,cal_data,T,T,param,'Intensity',title)
  dcrpg.sci(3)
  ok := myfit.fit(coeff, coefferr, chisq, foc, cal_data, order=order, sigma=1.)
  ok := myfit.eval(fit, foc, coeff)
  dcrpg.line(foc,fit)
  msk := fit==max(fit)
  if (order==2)
   peak := -coeff[2]/2/coeff[3]
  else
   if (sum(msk)!=1) 
    {
    print 'Problem detecting peak ... sum(mask) = ',sum(msk)
    note('Problem detecting peak!',priority='WARN')
    peak := 0
    }
   else
    peak := foc[msk]
  dcrpg.mtxt('T',-2,.03,0,sprintf('Peak: %5.3f',peak))
  dcrpg.mtxt('T',-3.5,.03,0,sprintf('Chi2: %5.3f',chisq))
  }
 if (archive)
  {
  focArchive := open('>> focus.dat')
  fprintf(focArchive,'%d %d %s %s %6.2f %6.2f %6.2f %d %5.3f\n',
          self.currentscan.scan, receiver, self.currentscan.GO_header.OBJECT,
	  param,az,el,peak,order,chisq)
  }
}

self.focus := function(tablename)
{
 t := tablefromascii('remove_me',tablename,,T)
 if (is_fail(t)) return;
 x := t.getcol('Column1')
 y := t.getcol('Column2')
 dcrpg.sci(1)
 dcrpg.sch(1.5)
 ok := myfit.fit(coeff, coefferr, chisq, x, y, order=2, sigma=1.)
 xarray := 0:100
 xarray := xarray/100*(x[len(x)]-x[1])+x[1]
 ok := myfit.eval(fit, xarray, coeff)
 dcrpg.plotxy(x,y,F,T,'Focus Position','Power','Focus Plot',2,2)
 dcrpg.line(xarray,fit)
 dcrpg.mtxt('T',-2,.03,0,sprintf('Peak: %5.3f',-coeff[2]/2/coeff[3]))
 t.done()
 shell('rm -r remove_me')
}

# Perform a tip measurement; use least-squares to derive opacity
# Initial plotting will be fine but if you return to it through the results
# manager - the scaling is off because DISH plotter fundamentally expects
# linear axis and we're plotting logs
 	self.tip:=function(scan,receiver) {
                wider self,private;
                test:=private.sl
                if (len(test[test==scan])==0)
                        return throw('FAILED: Scan not found');
	# change this when have data with actual values!
        	cal_value:=private.tcalvalues[receiver]
        	mask1 := private.getsrpmask(scan,receiver, 0)
        	mask2 := private.getsrpmask(scan,receiver, 1)
        	bigdata1:=self.maintable.getcol('FLOAT_DATA');
        	bigelev1:=self.maintable.getcol("GBT_AZEL")[2,];
        	bigelev1 *:= 57.2957795;
        	elev := (bigelev1[mask1] + bigelev1[mask2]) / 2.0
	# correct elevations to 0-90; 140 ft. appears to go 'over the top'
        	for (i in 1:len(elev)) {
                	if (elev[i]>90.) {
                       	 elev[i]:=90.-(elev[i]-90);
                	}
        	}
        	data_ph1 := bigdata1[mask1]
        	data_ph2 := bigdata1[mask2]
        	counts_per_K := sum((data_ph2 - data_ph1) / cal_value) /
                                                        length(data_ph2)
        	cal_data := data_ph1 / counts_per_K
        	secz := 1.0 / sin(elev / 57.2958)
         	ok := myfit.fit(coeff,coefferrs,chisq,secz,
			ln(cal_data),order=1,sigma=1);
        	newyarray:=coeff[2]*secz+coeff[1];
		note( '*** Tip Results                  ***',origin='tip');
        	note( 'intercept is',coeff[1],' slope is ',coeff[2],origin='tip');
		note( '************************************',origin='tip');
                return;
        }


self.radec_to_azel := function(mjd,ra2000='0h0m0s',dec2000='0d0m0s')
{
 cmd_position := dm.direction('J2000',ra2000,dec2000)
 j_time := [=]
 j_time.m0.value := mjd
 j_time.m0.unit := 'd'
 j_time.refer:='UTC'
 j_time.type:='epoch'
 j_pos := dm.observatory('GBT')
 dm.doframe(j_time)
 dm.doframe(j_pos)
 azel := dm.measure(cmd_position,'azel')
 return azel
}


 self.point1:=function(scan,receiver,xaxis=0,cal_value=1,basepct=10,plotflag=1)
 {
  wider self, private;
  if (scan != private.scanNum) {
   ok := self.getscan(scan)
   if (is_boolean(ok)) return F
   }
  if (private.info.nphases!=2 & private.info.nphases!=4) {
   dl.log(message='Bad number of phases.',priority='SEVERE',postcli=T)
   return F
   }
  if (self.test_srp(scan,receiver,0)) {
   dl.log(message='Scan or receiver not found',priority='SEVERE',postcli=T)
   return F
   }
  maintime := self.scantable.getcol('TIME')
  data1 := self.scantable.getcol("FLOAT_DATA")[1,1,]
  receiver := as_integer(receiver)
  mask1 := private.getRPmask(receiver, 0)
  mask2 := private.getRPmask(receiver, 1)
  maintime := maintime[mask1]

  cal_value := private.tcalvalues[receiver+1]  
 
 if (xaxis==0)
  {
  ra_range := abs(self.currentscan.ra[len(self.currentscan.ra)]- self.currentscan.ra[1])
  dec_range := abs(self.currentscan.dec[len(self.currentscan.dec)]- self.currentscan.dec[1])
  if (ra_range > dec_range) xaxis:=1
  else xaxis := 2
  }
 
  pointdir := array(0,2,len(maintime))
  pointdir[1,]:=self.currentscan.ra
  pointdir[2,]:=self.currentscan.dec
 
 cmd_position := dm.direction('J2000','0h0m0s','0d0m0s')

#
#  This will have problems if the scan crosses the meridian
#

 if (self.currentscan.GO_header.RA > 180)
  cmd_position.m0.value := self.currentscan.GO_header.RA/180*pi-2*pi
 else
  cmd_position.m0.value := self.currentscan.GO_header.RA/180*pi
 cmd_position.m1.value := self.currentscan.GO_header.DEC/180*pi
  
 # calculate Az, El for the commanded position
 
 j_time := [=]
 j_time.m0.value := maintime[as_integer(len(maintime)/2)]
 j_time.m0.unit := 's'
 j_time.refer:='UTC'
 j_time.type:='epoch'
 j_pos := dm.observatory('GBT')
 dm.doframe(j_time)
 dm.doframe(j_pos)
 azel1 := dm.measure(cmd_position,'azel')
 
  pointdir[1,] -:= cmd_position.m0.value
  pointdir[2,] -:= cmd_position.m1.value
  pointdir[1,] *:= (180/pi)*60*cos(cmd_position.m1.value)
  pointdir[2,] *:= (180/pi)*60
 
  if (private.info.nphases==2) {
   data_ph1 := data1[mask1]
   data_ph2 := data1[mask2]
   counts_per_K := sum((data_ph2 - data_ph1) / cal_value) / length(data_ph2)
   cal_data := data_ph1 / counts_per_K
   }
  else if (private.info.nphases==4) {
   if (self.currentscan.GO_header.SKYFREQ < 12e9) {
    dl.log(message='Frequency not in the expected range for beam switched data.',priority='SEVERE',postcli=T)
    return F
    }
   data_ph1 := data1[mask1]
   data_ph2 := data1[mask2]
   mask3 := private.getRPmask(receiver, 2)
   mask4 := private.getRPmask(receiver, 3)
   data_ph3 := data1[mask3]
   data_ph4 := data1[mask4]
   counts_per_K1 := sum((data_ph2 - data_ph1) / cal_value) / length(data_ph2)
   counts_per_K2 := sum((data_ph4 - data_ph3) / cal_value) / length(data_ph4)
#   cal_data_ref := data_ph1 / counts_per_K1
#   cal_data_sig := data_ph3 / counts_per_K2
   cal_data_sig := data_ph1 / counts_per_K1
   cal_data_ref := data_ph3 / counts_per_K2
   cal_data := cal_data_sig - cal_data_ref
   }
  if (xaxis==1) 
   {
   xval := pointdir[1,]
   dirstring := 'RA'
   }
  else 
   {
   xval := pointdir[2,]
   dirstring := 'Dec'
   }
  basefit := as_integer(basepct/100*len(cal_data)+0.5)
  suby[1:basefit]:=cal_data[1:basefit];
  suby[(basefit+1):(2*basefit)]:=cal_data[(len(cal_data)+1-basefit):len(cal_data)];
  subx[1:basefit] := xval[1:basefit]
  subx[(basefit+1):(2*basefit)] := xval[(len(xval)+1-basefit):len(xval)]
  ok:=myfit.fit(coeff,coefferrs,chisq,subx,suby,order=1,sigma=1);
  bfit_y:=coeff[2]*xval + coeff[1];
  flat_y:=cal_data - bfit_y;
  if (plotflag==1)
   {
   dcrpg.clear()
   dcrpg.plotxy(xval,flat_y,T,T,'Offset (min)','Power',
     paste(scan,":",receiver,":",self.currentscan.GO_header.OBJECT,
     ":",dirstring))
   }
  peak_guess := max(flat_y)
  xval_peak := xval[flat_y==peak_guess]
  if (len(xval_peak)==0) {
   dl.log(message='Cannot reduce this data.',priority='SEVERE',postcli=T)
   return F
   }

  if (!has_field(self.currentscan.GO_header,'SKYFREQ')) {
    dl.log(message='Cannot determine guess at FWHM because freq is missing from GO info.',priority='WARNING',postcli=T)
    dl.log(message='Guessing FWHM=1',priority='WARNING',postcli=T)
    fwhm_guess := 1
    }
  else
   fwhm_guess := 1.3*3.0E8/self.currentscan.GO_header.SKYFREQ/100*180/pi*60
  res := self.gauss(xval,flat_y,peak_guess,fwhm_guess,xval_peak,plotflag)
  obs_position := cmd_position
  if (xaxis==1) 
   obs_position.m0.value := cmd_position.m0.value + 
 	  res.center/((180/pi)*60*cos(cmd_position.m1.value))
  else
   obs_position.m1.value := cmd_position.m1.value + res.center/((180/pi)*60)
  azel2 := dm.measure(obs_position,'azel')
  rec := [=]
  rec.d_az := (azel2.m0.value - azel1.m0.value)*(180/pi)*60*cos(azel2.m1.value)
  rec.d_el := (azel2.m1.value - azel1.m1.value)*(180/pi)*60
  rec.x := xval
  rec.data := flat_y
  rec.fitx := res.x
  rec.fit := res.y
  rec.center := res.center
  rec.width := res.width
  rec.height := res.height
  rec.chisq := res.chisq2
  rec.title := paste(scan,':',receiver,':',
    self.currentscan.GO_header.OBJECT,':',dirstring)
  rec.az := azel1.m0.value
  rec.el := azel1.m1.value
  rec.xaxis := xaxis
  rec.src_name := self.currentscan.GO_header.OBJECT
  if (private.info.nphases==2) rec.tsys := mean(bfit_y)
  else rec.tsys := mean(cal_data_ref)
  return rec
 }
 
 self.point2:=function(scan,receiver,cal_value=1)
 {
  wider self, private
  p2_rec := [=]
  twoscan:=scan:(scan + 1)
  j:=0; az_sum := 0; el_sum := 0
  for (nscan in twoscan) {
   j +:= 1
   p1_rec := self.point1(nscan,receiver,plotflag=0,cal_value=cal_value)
   if (is_boolean(p1_rec)) return F
   az_sum +:= p1_rec.d_az
   el_sum +:= p1_rec.d_el
   if (j==1) {
    plot_x := array(0,2,len(p1_rec.x))
    plot_data := array(0,2,len(p1_rec.x))
    plot_fitx := array(0,2,len(p1_rec.fitx))
    plot_fit := array(0,2,len(p1_rec.fitx))
    }
   plot_x[j,]    := p1_rec.x
   plot_data[j,] := p1_rec.data
   plot_fitx[j,] := p1_rec.fitx
   plot_fit[j,]  := p1_rec.fit
   plot_d_az[j] := p1_rec.d_az
   plot_d_el[j] := p1_rec.d_el
   plot_lab[j] := p1_rec.title
   plot_center[j] := p1_rec.center
   plot_width[j] := p1_rec.width
   plot_height[j] := p1_rec.height
   plot_tsys[j] := p1_rec.tsys
   p2_rec.full_az := p1_rec.az
   p2_rec.full_el := p1_rec.el
   p2_rec.chisq[j] := p1_rec.chisq
   ok := (p1_rec.center < 1e4) & (p1_rec.center > -1e4) &
         (p1_rec.width  > 0  ) & (p1_rec.width  < 100 ) &
         (p1_rec.height > 0  ) & (p1_rec.height < 1e4 )
   if (!ok) {
     plot_center[j] := 0
     plot_width[j]  := 0
     plot_height[j] := 0
     plot_fit[j,]   := 0
     plot_d_az[j]   := 0
     plot_d_el[j]   := 0
     }
  }
  dcrpg.clear()
  dcrpg.subp(2,1)
  dcrpg.sch(1.5)
  for (i in 1:j) {
   dcrpg.sci(1)
   dcrpg.plotxy(plot_x[i,],plot_data[i,])
   dcrpg.lab('Offset (min)','T',plot_lab[i])
   dcrpg.sci(3)
   dcrpg.line(plot_fitx[i,],plot_fit[i,])
   dcrpg.sci(1)
   dcrpg.mtxt('T',-2,.03,0,sprintf('Ctr: %4.3f',plot_center[i]))
   dcrpg.mtxt('T',-3,.03,0,sprintf('Wid: %4.3f',plot_width[i]))
   dcrpg.mtxt('T',-4,.03,0,sprintf('Hgt: %4.3f',plot_height[i]))
   dcrpg.mtxt('T',-2,.6,0,sprintf('dAz:  %7.3f',plot_d_az[i]))
   dcrpg.mtxt('T',-3,.6,0,sprintf('dEl:  %7.3f',plot_d_el[i]))
   dcrpg.mtxt('T',-4,.6,0,sprintf('Tsys: %7.3f',plot_tsys[i]))
   dcrpg.sls(2)
   dcrpg.sci(15)
   dcrpg.line([-1000,1000],[0,0])
   dcrpg.line([0,0],[-1000,1000])
   dcrpg.sls(1)
   }
  p2_rec.az := az_sum/2
  p2_rec.el := el_sum/2
  p2_rec.center := plot_center
  p2_rec.width := plot_width
  p2_rec.height := plot_height
  return p2_rec;
 }

# Pointing scan : Expects data as +RA, -RA, +DEC, -DEC
self.point4:=function(scan,receiver,cal_value=1,plotflag=1)
{
 wider self,private;
 if (self.test_srp(scan,receiver,0))
  return throw('FAILED: scan or receiver not found')
 if (self.test_srp(scan+1,receiver,0)||self.test_srp(scan+2,receiver,0)||
     self.test_srp(scan+3,receiver,0))
  return throw('FAILED: 4-scan pointing not found');
 fourscan:=scan:(scan + 3)
 j:=0; az_sum := 0; el_sum := 0
 for (nscan in fourscan) 
  {
  j +:= 1
  rec := self.point1(nscan,receiver,plotflag=plotflag,cal_value=cal_value)
  az_sum +:= rec.d_az
  el_sum +:= rec.d_el
  if (j==1)
   {
   plot_x := array(0,4,len(rec.x))
   plot_data := array(0,4,len(rec.x))
   plot_fitx := array(0,4,len(rec.fitx))
   plot_fit := array(0,4,len(rec.fitx))
   }
  plot_x[j,]    := rec.x
  plot_data[j,] := rec.data
  plot_fitx[j,] := rec.fitx
  plot_fit[j,]  := rec.fit
  plot_d_az[j] := rec.d_az
  plot_d_el[j] := rec.d_el
  plot_lab[j] := rec.title
  plot_center[j] := rec.center
  plot_width[j] := rec.width
  plot_height[j] := rec.height
  }
 printf( '-------------------------------------------------------\n');
 printf( '|\n')
 printf( '| 4-Scan Correction (min)  Az: %7.3f   El: %7.3f\n',az_sum/2,el_sum/2)
 printf( '|\n')
 printf( '-------------------------------------------------------\n');
 if (plotflag)
  {
  dcrpg.clear()
  dcrpg.subp(2,2)
  dcrpg.sch(2.5)
  for (i in 1:j)
   {
   dcrpg.sci(1)
   dcrpg.plotxy(plot_x[i,],plot_data[i,])
   dcrpg.lab('Offset (min)',' ',plot_lab[i])
   dcrpg.mtxt('T',-2,.03,0,sprintf('%4.3f',plot_center[i]))
   dcrpg.mtxt('T',-3,.03,0,sprintf('%4.3f',plot_width[i]))
   dcrpg.mtxt('T',-4,.03,0,sprintf('%4.3f',plot_height[i]))
   dcrpg.mtxt('T',-2,.75,0,sprintf('%7.3f',plot_d_az[i]))
   dcrpg.mtxt('T',-3,.75,0,sprintf('%7.3f',plot_d_el[i]))
   dcrpg.sci(3)
   dcrpg.line(plot_fitx[i,],plot_fit[i,])
   dcrpg.sls(2)
   dcrpg.sci(15)
   dcrpg.line([-1000,1000],[0,0])
   dcrpg.line([0,0],[-1000,1000])
   dcrpg.sls(1)
   }
  dcrpg.subp(1,1)
  dcrpg.sch(1)
  }
 return;
}

self.test_srp := function(s,r,p)
{
 test := private.sl
 if (len(test[test==s])==0)
  return T
 if (len(private.info.rcvrlist[private.info.rcvrlist==r])==0)
  return T
 if (len(private.info.phaselist[private.info.phaselist==p])==0)
  return T
 return F
}

self.plot_phase_time:=function(scan,receiver,phase) 
{
 wider self,private;
 if (scan != private.scanNum)
  self.getscan(scan)
 if ((phase >= 0) && (self.test_srp(scan,receiver,phase)))
  return throw('FAILED: Scan, Receiver, or Phase not found');
 if (self.test_srp(scan,receiver,0))
  return throw('FAILED: Scan or Receiver not found');
 dcrpg.clear()
 dcrpg.sch(1.5)
 if (phase<0)
  for (i in private.info.phaselist)
   {
   data := self.currentscan.data[receiver+1,i+1,]
   tyme := self.currentscan.time-self.currentscan.time[1]
   if (i==private.info.phaselist[1])
    {
    dcrpg.plotxy1(tyme,data,'Time','Phase Counts','Phase vs Time')
    dcrpg.sci(2)
    dcrpg.mtxt('T',-(i+1),0.75,0.0,paste('Phase',i))
    }
   else
    {
    dcrpg.plotxy1(tyme,data)
    dcrpg.sci(2+i)
    dcrpg.mtxt('T',-(i+1),0.75,0.0,paste('Phase',i))
    }
   }
 else
  {
  data := self.currentscan.data[receiver+1,phase+1,]
  tyme := self.currentscan.time-self.currentscan.time[1]
  dcrpg.plotxy(tyme,data,T,T,'Time','Phase Counts','Phase vs Time')
  }
 dcrpg.sci(1)
 dcrpg.sch(1)
 return;
}

self.plot_phase_ra:=function(scan,receiver,phase)
{
 wider self,private;
 if (scan != private.scanNum)
  self.getscan(scan)
 if (self.test_srp(scan,receiver,phase))
  return throw('Scan, Receiver, or Phase not found');
 dcrpg.clear()
 dcrpg.plotxy(self.currentscan.ra,self.currentscan.data[receiver+1,phase+1,],
	   T,T,'RA','Counts','PhaseRA')
 return;
}

self.plot_phase_dec:=function(scan,receiver,phase)
{
 wider self,private;
 if (scan != private.scanNum)
  self.getscan(scan)
 if (self.test_srp(scan,receiver,phase))
  return throw('Scan, Receiver, or Phase not found');
 dcrpg.clear()
 dcrpg.plotxy(self.currentscan.dec,self.currentscan.data[receiver+1,phase+1,],
	   T,T,'DEC','Counts','PhaseDec')
 return;
}

self.plot_RA_Dec:=function(scan)
{
 wider self,private;
 test:=private.sl
 if (len(test[test==scan])==0)
  return throw('FAILED: Scan not found');
 if (scan != private.scanNum)
  self.getscan(scan)
 dcrpg.clear()
 dcrpg.plotxy(self.currentscan.ra,self.currentscan.dec,T,T,'RA','DEC','RADec')
 return;
}

# Return tant
self.get_tant:=function(scan,receiver=1,cal_value=1)
{
 wider self,private;
 if (scan != private.scanNum)
  self.getscan(scan)
 if (self.test_srp(scan,receiver,0))
  return throw('FAILED: Scan or receiver not found')
 if (private.info.nphases<2) 
  return throw('T(ant) requires 2 phases')
 tyme := self.currentscan.time-self.currentscan.time[1]
 data_ph1 := self.currentscan.data[receiver+1,1,]
 data_ph2 := self.currentscan.data[receiver+1,2,]
 counts_per_K := sum((data_ph2-data_ph1)/cal_value)/len(data_ph2)
 cal_data := data_ph1 / counts_per_K 
 return cal_data;
}

# Plots calibrated Total Power with Cal data for a specified scan and 
# receiver as a function of UT
self.plot_tant_time:=function(scan,receiver=1,cal_value=1)
{
 wider self,private;
 if (scan != private.scanNum)
  self.getscan(scan)
 if (self.test_srp(scan,receiver,0))
  return throw('FAILED: Scan or receiver not found')
 if (private.info.nphases<2) 
  return throw('T(ant) requires 2 phases')
 dcrpg.clear()
 tyme := self.currentscan.time-self.currentscan.time[1]
 data_ph1 := self.currentscan.data[receiver+1,1,]
 data_ph2 := self.currentscan.data[receiver+1,2,]
 counts_per_K := sum((data_ph2-data_ph1)/cal_value)/len(data_ph2)
 cal_data := data_ph1 / counts_per_K 
 dcrpg.plotxy(tyme,cal_data,T,T,'Time','Tant','Antenna Temperature')
 return;
}

self.plot_sidelobe:=function(scan,receiver=1,basepct=10,bottom=-70)
{
 wider self,private;
 cal_value := private.tcalvalues[receiver+1]
 if (scan != private.scanNum)
  self.getscan(scan)
 if (self.test_srp(scan,receiver,0))
  return throw('FAILED: Scan or receiver not found')
 if (private.info.nphases<2) 
  return throw('T(ant) requires 2 phases')
 dcrpg.clear()
 tyme := self.currentscan.time-self.currentscan.time[1]
 data_ph1 := self.currentscan.data[receiver+1,1,]
 data_ph2 := self.currentscan.data[receiver+1,2,]
 counts_per_K := sum((data_ph2-data_ph1)/cal_value)/len(data_ph2)
 cal_data := data_ph1 / counts_per_K 
 basefit := as_integer(basepct/100*len(cal_data)+0.5)
 if (basefit<=1)
  {
  print 'Warning: Fitting baseline with only the 1 sample on each end'
  basefit := 1
  }
 suby[1:basefit]:=cal_data[1:basefit];
 suby[(basefit+1):(2*basefit)]:=cal_data[(len(cal_data)+1-basefit):len(cal_data)];
 subx[1:basefit] := tyme[1:basefit]
 subx[(basefit+1):(2*basefit)] := tyme[(len(tyme)+1-basefit):len(tyme)]
 ok:=myfit.fit(coeff,coefferrs,chisq,subx,suby,order=1,sigma=1);
 bfit_y:=coeff[2]*tyme + coeff[1];
 flat_y:=cal_data - bfit_y;
 norm := flat_y/max(flat_y)
 norm[norm<(10^(bottom/10))] := 10^(bottom/10)
 norm := log(norm)*10
 dcrpg.plotxy(tyme,norm,T,T,'Time','dB','Normalized Antenna Temp')
 return;
}

# Plots calibrated Total Power with Cal data for a specified scan and 
# receiver as a function of RA
self.plot_tant_RA:=function(scan,receiver=1,cal_value=1)
{
 wider self,private;
 if (scan != private.scanNum)
  self.getscan(scan)
 if (self.test_srp(scan,receiver,0))
  return throw('FAILED: Scan or receiver not found')
 if (private.info.nphases<2) 
  return throw('T(ant) requires 2 phases')
 dcrpg.clear()
 data_ph1 := self.currentscan.data[receiver+1,1,]
 data_ph2 := self.currentscan.data[receiver+1,2,]
 counts_per_K := sum((data_ph2-data_ph1)/cal_value)/len(data_ph2)
 cal_data := data_ph1 / counts_per_K 
 dcrpg.plotxy(self.currentscan.ra,cal_data,T,T,'RA','Tant','Antenna Temperature')
 return;
}

# Plots calibrated Total Power with Cal data for a specified scan and 
# receiver as a function of RA
self.plot_tant_Dec:=function(scan,receiver=1,cal_value=1)
{
 wider self,private;
 if (scan != private.scanNum)
  self.getscan(scan)
 if (self.test_srp(scan,receiver,0))
  return throw('FAILED: Scan or receiver not found')
 if (private.info.nphases<2) 
  return throw('T(ant) requires 2 phases')
 dcrpg.clear()
 data_ph1 := self.currentscan.data[receiver+1,1,]
 data_ph2 := self.currentscan.data[receiver+1,2,]
 counts_per_K := sum((data_ph2-data_ph1)/cal_value)/len(data_ph2)
 cal_data := data_ph1 / counts_per_K 
 dcrpg.plotxy(self.currentscan.dec,cal_data,T,T,'DEC','Tant','Antenna Temperature')
 return;
}

# Plots relative gain (normalized counts/K) in Total Power with Cal mode
# for a specified scan and receiver as a function of UT
self.plot_gain_time:=function(scan,receiver) 
{
 wider self,private;
 if (scan != private.scanNum)
  self.getscan(scan)
 if (self.test_srp(scan,receiver,0))
  return throw('FAILED: Scan or receiver not found')
 dcrpg.clear()
 tyme := self.currentscan.time-self.currentscan.time[1]
 data_ph1 := self.currentscan.data[receiver+1,1,]
 data_ph2 := self.currentscan.data[receiver+1,2,]
 cts_per_K := data_ph2 - data_ph1
 cts_per_K := cts_per_K / mean(cts_per_K)
print 'put it in'
 return;
}

private.getDapScan := function(colName,timearray)
{
 wider self,private;
 dapTime := self.dapTable.getcol('TIME')
 dapData := self.dapTable.getcol(colName)
 for (i in 1:len(timearray))
  {
  mask := dapTime>=timearray[i]
  d := dapData[mask]
  ret_val[i] := d[1]
  }
 if (len(ret_val)!=len(timearray)) return throw('Error in getDapScan')
 return ret_val
}

# Plots a DAP parameter as a function of time for a given scan
self.plot_dap_time:=function(scan,colName)
{
 wider self,private;
 test:=private.sl
 if (len(test[test==scan])==0 && scan != -1)
  return throw('FAILED: Scan not found');
 dcrpg.clear()
 thetime:=self.maintable.getcol('TIME');
 mask1 := private.getsrpmask(scan,0,0);
 tyme := thetime[mask1];
 dapTime := self.dapTable.getcol('TIME')
 dapData := self.dapTable.getcol(colName)
 if (scan==-1)
  {
  plotTime := dapTime 
  dapD := dapData
  }
 else
  { 
  mask := (dapTime>tyme[1])&(dapTime<tyme[len(tyme)])
  dapD := dapData[mask]
  plotTime := dapTime[mask]
  }
 if (len(dapD)==0)
  return throw('No DAP data available for the specified scan.')
 else if (is_numeric(dapD))
  {
  if (scan ==-1) private.info.srcName := 'All Sources'
  plotTime -:= plotTime[1]
print 'put it in'
  }
 else
  print dapD
 return
}

self.baselinefit:= function(xarray,yarray,ord,range,plotflag=T)
{
 wider private,self
 if (len(range)%2 != 0 || len(range)==0 ) 
    return throw('bad number of range parameters')
 if (range != sort(range)) return throw('bad order of range parameters')
 cnt := 0
 for (i in 1:len(xarray))
  for (j in 0:(len(range)/2-1))
   if ((xarray[i]>=range[j*2+1]) && (xarray[i]<=range[j*2+2]))
    {
    cnt +:= 1
    fitx[cnt] := xarray[i]
    fity[cnt] := yarray[i]
    }
 ok := myfit.fit(coeff, coefferr, chisq, fitx, fity, order=ord, sigma=1.)
 ok := myfit.eval(fit, xarray, coeff)
 resid := yarray - fit
 if (plotflag)
  {
  dcrpg.plotxy(xarray,yarray,T,T,,,,2)
  dcrpg.plotxy(xarray,fit,T,F,,,,3)
  }
 return resid
}

# Get a record so that users can manipulate the data in the glish environment
self.getscan := function(scan,getFocus=F)
{
 wider private,self
 slist := private.sl
 if (len(slist[slist==scan])==0) {
    dl.log(message='Scan not found',priority='SEVERE',postcli=T)
    return F
    }
 private.busy()
 self.currentscan := [=]
# if (has_field(self,'scantable')) self.scantable.close()
 self.scantable:=self.maintable.query(paste('SCAN_NUMBER == ',scan));
 mask1 := private.getRPmask(0,0)
 thetime:=self.scantable.getcol('TIME');
 self.currentscan.time := thetime[mask1];
 self.currentscan.GO_header := self.getGO(scan);
 private.tcalvalues := private.getDcrTcalValues()
 print 'tcalvalues : ', private.tcalvalues
 private.scaninfo(scan)
 self.currentscan.scan := scan
 data  := self.scantable.getcol('FLOAT_DATA')
 self.currentscan.data := array(0,len(private.info.rcvrlist),
      len(private.info.phaselist), len(self.currentscan.time))
 if (len(self.currentscan.time)<2) 
  {
  private.ready()
  dl.log(message='The data file appears out of synch.',priority='SEVERE',postcli=T)
  return F
  }
 for (i in (private.info.rcvrlist+1))
  for (j in (private.info.phaselist+1))
   {
   mask1 := private.getRPmask(i-1,j-1)
   self.currentscan.data[i,j,] :=data[mask1];
   }
 begin_time := self.currentscan.time[1]-10
 end_time := self.currentscan.time[len(self.currentscan.time)]+10
 sub_pointTable := self.pointTable.query(spaste('TIME<',end_time,' && TIME>',
                   begin_time))
 pointtime:= sub_pointTable.getcol('TIME')
 big_pointdir := sub_pointTable.getcol('DIRECTION')
 big_pModelId := sub_pointTable.getcol('POINTING_MODEL_ID')
 mask := pointtime==self.currentscan.time[1]
 pModelIndex := big_pModelId[mask]+1
 if (len(pModelIndex) != 1) {
  dl.log(message='There is an apparent error in getting the pointing model info',priority='SEVERE',postcli=T)
  return F
  }
 pModelRow := tablerow(self.pModelTable)
 pModelRec := pModelRow.get(pModelIndex)
 pModelRow.close()
 self.currentscan.lpc_az1 := pModelRec.LPC_AZ1
 self.currentscan.lpc_az2 := pModelRec.LPC_AZ2
 self.currentscan.lpc_el := pModelRec.LPC_EL
 self.currentscan.pmodel := pModelRec

# Calculate Az, El for the commanded position at the midpoint
 cmd_position := dm.direction('J2000','0h0m0s','0d0m0s')
 if (self.currentscan.GO_header.RA > 180)
  cmd_position.m0.value := self.currentscan.GO_header.RA/180*pi-2*pi
 else
  cmd_position.m0.value := self.currentscan.GO_header.RA/180*pi
 cmd_position.m1.value := self.currentscan.GO_header.DEC/180*pi
  
 j_time := [=]
 j_time.m0.value := 
  self.currentscan.time[as_integer(len(self.currentscan.time)/2)]
 j_time.m0.unit := 's'
 j_time.refer:='UTC'
 j_time.type:='epoch'
 j_pos := dm.observatory('GBT')
 dm.doframe(j_time)
 dm.doframe(j_pos)
 azel := dm.measure(cmd_position,'azel')
 self.currentscan.az := azel.m0.value*180/pi
 self.currentscan.el := azel.m1.value*180/pi

 if (getFocus)
  {
  if (any(self.focusTable.colnames()=='PF_FOCUS') &&
      any(self.focusTable.colnames()=='SR_XP')) {
   dl.log(message='This MS appears to have both gregorian and prime focus data, and the dcr tool cannot currently handle this.',priority='SEVERE',postcli=T)
   return F
   }
  if (!is_boolean(getFocus) && 
     (getFocus=='PF_FOCUS' || getFocus=='PF_ROTATION' || getFocus=='PF_X') &&
      any(self.focusTable.colnames()=='SR_XP')) {
   dl.log(message='You specified a focus parameter not available in this MS',priority='SEVERE',postcli=T)
   return F
   }
  if (!is_boolean(getFocus) &&
     (getFocus=='SR_XP' || getFocus=='SR_YP' || getFocus=='SR_ZP' ||
       getFocus=='SR_XT' || getFocus=='SR_YT' || getFocus=='SR_ZT') &&
      any(self.focusTable.colnames()=='PF_X')) {
   dl.log(message='You specified a focus parameter not available in this MS',priority='SEVERE',postcli=T)
   return F
   }
  big_focusID := sub_pointTable.getcol('NRAO_GBT_MEAN_FOCUS_ID')
  if (!is_boolean(getFocus))
   {
   self.currentscan.focusparam := getFocus
   if (getFocus=='PF_FOCUS'||getFocus=='PF_ROTATION'||getFocus=='PF_X')
    self.currentscan.optics := 'ANTPOSPF'
   else
    self.currentscan.optics := 'ANTPOSGR'
   if (any(self.focusTable.colnames()==getFocus))
    big_focus_FOCUS := self.focusTable.getcol(getFocus)
   else {
    dl.log(message=spaste('Error in getscan - ',getFocus,' not recognized'),priority='SEVERE',postcli=T)
    return F
    }
  }
  else
   {
   self.currentscan.focusparam := 'all'
   if (any(self.focusTable.colnames()=='PF_FOCUS'))
    {
    self.currentscan.optics := 'ANTPOSPF'
    big_focus_PF_FOCUS := self.focusTable.getcol('PF_FOCUS')
    big_focus_PF_ROTATION := self.focusTable.getcol('PF_ROTATION')
    big_focus_PF_X := self.focusTable.getcol('PF_X')
    }
   if (any(self.focusTable.colnames()=='SR_XP'))
    {
    self.currentscan.optics := 'ANTPOSGR'
    big_focus_SR_XP := self.focusTable.getcol('SR_XP')
    big_focus_SR_YP := self.focusTable.getcol('SR_YP')
    big_focus_SR_ZP := self.focusTable.getcol('SR_ZP')
    big_focus_SR_XT := self.focusTable.getcol('SR_XT')
    big_focus_SR_YT := self.focusTable.getcol('SR_YT')
    big_focus_SR_ZT := self.focusTable.getcol('SR_ZT')
    }
   }
  }
 pointdir := array(0,2,len(self.currentscan.time))
 for (i in 1:len(self.currentscan.time))
  {
  mask := pointtime==self.currentscan.time[i]
  if (sum(mask)!=1) 
   {
   private.ready()
   dl.log(message='Error in TIME masking',priority='SEVERE',postcli=T)
   return F
   }
  pointdir[,i] := big_pointdir[,1,mask]
#
# The following code should be further optimized by setting focusID to an
# array equal to the appropriate elements, and then using that array as
# a mask to set the focus constituents of the currentscan record
#
  if (getFocus)
   {
   focusID := big_focusID[mask]+1
   if (!is_boolean(getFocus))
    self.currentscan.FOCUS[i] := as_float(big_focus_FOCUS[focusID])
   else
    if (self.currentscan.optics=='ANTPOSPF')
     {
     self.currentscan.PF_FOCUS[i] := as_float(big_focus_PF_FOCUS[focusID])
     self.currentscan.PF_ROTATION[i] := as_float(big_focus_PF_ROTATION[focusID])
     self.currentscan.PF_X[i] := as_float(big_focus_PF_X[focusID])
     }
    else
     {
     self.currentscan.SR_XP[i] := as_float(big_focus_SR_XP[focusID])
     self.currentscan.SR_YP[i] := as_float(big_focus_SR_YP[focusID])
     self.currentscan.SR_ZP[i] := as_float(big_focus_SR_ZP[focusID])
     self.currentscan.SR_XT[i] := as_float(big_focus_SR_XT[focusID])
     self.currentscan.SR_YT[i] := as_float(big_focus_SR_YT[focusID])
     self.currentscan.SR_ZT[i] := as_float(big_focus_SR_ZT[focusID])
     }
   }
  }
 self.currentscan.ra := pointdir[1,]
 self.currentscan.dec := pointdir[2,]
 private.cgui.lb1->clear('start','end')
 for (i in 1:len(slist)) 
  if ((as_integer(private.cgui.lb1->get(as_string(i-1))))==scan)
   {
   private.cgui.lb1->select(as_string(i-1))
   private.cgui.lb1->see(as_string(i-1))
   }
 private.scanNum := scan
 private.rcvrNum:=-2
 private.phaseNum:=-2
 private.ready()
 private.cgui.lb2->delete('start','end')
 private.cgui.lb3->delete('start','end')
 private.cgui.lb2->insert(as_string(private.info.rcvrlist))
 private.cgui.lb3->insert(as_string(private.info.phaselist))
 return self.currentscan;
}

self.plotscans:= function(bscan,escan,rcvr=0,phase=0)
{
 wider private,self;
 x := F
 alldata:=self.maintable.getcol('FLOAT_DATA');
 thetime:=self.maintable.getcol('TIME');
 for (i in bscan:escan)
  {
  mask := private.getsrpmask(i,rcvr,phase);
  subdata := alldata[mask];
  tyme:=thetime[mask];
  if (i==bscan) t0 := tyme[1]
  tyme := tyme - t0;
  offset := len(x)
  for (j in 1:len(subdata))
   {
   x[j+offset-1] := tyme[j]
   y[j+offset-1] := subdata[j]
   }
  }
 dcrpg.plotxy1(x,y,,,
    sprintf("Scans %d - %d   RX %d   Phs %d",bscan,escan,rcvr,phase))
 return;
}

self.scanSummary := function() {
  wider private, self
  scans := self.listscans()
  private.cgui.textWin->append('\n')
  for (i in scans) {
    go := self.getGO(i)
    str := sprintf('%4d %10s %10s %1d/%1d %7.4f\n',go.SCAN, go.OBJECT,
           go.PROCNAME, go.PROCSEQN, go.PROCSIZE, go.SKYFREQ/1e9)
    private.cgui.textWin->append(str)
  }
}

#self.scanSummary := function()
#{
#
##
## The TIME column should be useful as an index between the main table
## and the POINTING subtable for GBT 
##
# wider private,self;
# private.cgui.textWin->append('\n\n**************** Scan Summary ***************\n');
# maintime := self.maintable.getcol('TIME')
# sl := self.maintable.getcol('SCAN_NUMBER');
# fid := self.maintable.getcol('FIELD_ID');
# mask := private.getAllMask(0,0)
# maintime := maintime[mask]
# zz := [=]
# zz.value := maintime/60/60/24
# zz.unit:='d'
# atime := dq.time(zz,6,'dmy')
# sl := sl[mask]
# fid := fid[mask]
# pointtime:=self.pointTable.getcol('TIME')
# big_pointdir := self.pointTable.getcol('DIRECTION')
# pointdir := array(0,2,len(sl))
# for (i in 1:len(sl))
#  {
#  mask := pointtime==maintime[i]
#  if (sum(mask)!=1) 
#    return throw(paste('Error in TIME masking',maintime[i],i,sum(mask)))
#  pointdir[,i] := big_pointdir[,1,mask]
#  }
# ra := [=]; dec := [=]
# ra.value := pointdir[1,]
# ra.unit := 'deg'
# a_ra := dq.angle(ra,,'time')
# dec.value := pointdir[2,]
# dec.unit := 'deg'
# a_dec := dq.angle(dec)
# srcid := self.fieldTable.getcol('SOURCE_ID')
# src := self.sourceTable.getcol('NAME')
# for (i in 1:len(sl))
#  private.cgui.textWin->append(paste(sl[i],atime[i], src[srcid[fid[i]+1]+1],
#			a_ra[i], a_dec[i], '\n'));
#}

###
#
# JB -- Begin GUI stuff here
#
###

include 'widgetserver.g'
dws.setmode('app')
dws.tk_hold()

private.sl := private.scanlist()

###
# Set up Scans Listbox
###
private.cgui.main := dws.frame(title='DCR Tool')
private.cgui.f := dws.frame(private.cgui.main,side='left')
private.cgui.f1 := dws.frame(private.cgui.f)
private.cgui.l1 := dws.label(private.cgui.f1,'Scan:')
private.cgui.lbf1 := dws.frame(private.cgui.f1,side='left')
private.cgui.lb1 := dws.listbox(private.cgui.lbf1,width=15)
private.cgui.sb1 := dws.scrollbar(private.cgui.lbf1)
whenever private.cgui.sb1->scroll do
 private.cgui.lb1->view($value)
whenever private.cgui.lb1->yscroll do
 private.cgui.sb1->view($value)
private.cgui.lb1->insert(as_string(private.sl))

###
# Set up RX Listbox
###
private.cgui.f2 := dws.frame(private.cgui.f)
private.cgui.l2 := dws.label(private.cgui.f2,'Receiver:')
private.cgui.lbf2 := dws.frame(private.cgui.f2,side='left')
private.cgui.lb2 := dws.listbox(private.cgui.lbf2,width=15)
private.cgui.sb2 := dws.scrollbar(private.cgui.lbf2)
whenever private.cgui.sb2->scroll do
 private.cgui.lb2->view($value)
whenever private.cgui.lb2->yscroll do
 private.cgui.sb2->view($value)
whenever private.cgui.lb2->select do 
 private.rcvrNum := as_integer(private.cgui.lb2->get($value))

###
# Set up Phases Listbox
###
private.cgui.f3 := dws.frame(private.cgui.f)
private.cgui.l3 := dws.label(private.cgui.f3,'Phase:')
private.cgui.lbf3 := dws.frame(private.cgui.f3,side='left')
private.cgui.lb3 := dws.listbox(private.cgui.lbf3,width=15)
private.cgui.sb3 := dws.scrollbar(private.cgui.lbf3)
whenever private.cgui.sb3->scroll do
 private.cgui.lb3->view($value)
whenever private.cgui.lb3->yscroll do
 private.cgui.sb3->view($value)
whenever private.cgui.lb3->select do
 private.phaseNum := as_integer(private.cgui.lb3->get($value))

###
# Operations to execute when a scan is chosen
###
whenever private.cgui.lb1->select do {
 self.getscan(as_integer(private.cgui.lb1->get($value)))
}

####
## Cal value entry box
####
#calValue := 1
#private.cgui.h := dws.frame(private.cgui.main,side='left')
#private.cgui.calLabel := dws.label(private.cgui.h,'Cal Value:',padx=15)
#private.cgui.calEntry:= dws.entry(private.cgui.h,width=6)
#private.cgui.calEntry->insert(as_string(calValue),'start')
#whenever private.cgui.calEntry->return do
# calValue := private.cgui.getCalValue()
#TPnCCalValue := 1
#private.cgui.calLabel2 := dws.label(private.cgui.h,'       TPnC Cal:',padx=15)
#private.cgui.calEntry2:= dws.entry(private.cgui.h,width=6)
#private.cgui.calEntry2->insert(as_string(TPnCCalValue),'start')
#whenever private.cgui.calEntry2->return do
# TPnCCalValue := private.cgui.getTPnCCalValue()

private.cgui.getCalValue := function()
{
wider self,private
calValue := as_float(private.cgui.calEntry->get())
if (calValue==0) 
 {
 calValue := 1; 
 private.cgui.calEntry->delete('start'); 
 private.cgui.calEntry->insert(as_string(calValue))
 }
return calValue
}

private.cgui.getTPnCCalValue := function()
{
wider self,private
cal := as_float(private.cgui.calEntry2->get())
if (cal==0) 
 {
 calValue := 1; 
 private.cgui.calEntry->delete('start'); 
 private.cgui.calEntry->insert(as_string(calValue))
 }
return cal
}

private.busy := function(dodisable=F)
{
 private.cgui.b2->background('red')
 private.cgui.b2->text('Busy')
 dws.busy(private.cgui.main,disable=dodisable,busycursor='watch')
}

private.ready := function(doenable=F)
{
 private.cgui.b2->background('green')
 private.cgui.b2->text('Ready')
 dws.notbusy(private.cgui.main,enable=doenable,normalcursor='')
}

private.wait := function(dodisable=F)
{
 private.cgui.b2->background('yellow')
 private.cgui.b2->text('Waiting')
 dws.busy(private.cgui.main,disable=dodisable,busycursor='watch')
}

###
# Buttons for plotting
###
private.cgui.g := dws.frame(private.cgui.main,side='left')
private.cgui.lPlots := dws.label(private.cgui.g,'Plot v. Time:',padx=5)
private.cgui.bPlot1 := dws.button(private.cgui.g,'   Phase  ') 
private.cgui.bPlot2 := dws.button(private.cgui.g,'  T(ant)  ') 
private.cgui.bPlot3 := dws.button(private.cgui.g,'  T(src)  ') 
#
# The following line only pulls columns from the skyPosition sampler
#
#tmpTable := table(self.maintable.getkeyword('NRAO_GBT_DAP_ANTENNA'),lockoptions='usernoread', ack=F)
#self.dapTable := tmpTable.query(query='MANAGER=\'AntennaManager\' && SAMPLER=\'skyPosition\'',columns=paste(tmpTable.getkeyword('AntennaManager_skyPosition_COLUMNS'),sep=','))
#if (is_fail(self.dapTable)) 
# private.cgui.bPlot4 := dws.button(private.cgui.g,' no DAP   ',relief='flat') 
#else
# {
# private.cgui.bPlot4 := dws.button(private.cgui.g,'   DAP    ',type='menu', relief='raised') 
# dapCols := self.dapTable.colnames()
# for (ii in dapCols)
#  private.cgui.bP4[ii] := dws.button(private.cgui.bPlot4,ii,value=ii)
# }
whenever private.cgui.bPlot1->press do
 {
 private.busy()
 self.plot_phase_time(private.scanNum,private.rcvrNum,private.phaseNum)
 private.ready()
 }
whenever private.cgui.bPlot2->press do
 {
 private.busy()
 calValue := private.tcalvalues[private.rcvrNum+1]
 self.plot_tant_time(private.scanNum,private.rcvrNum,calValue)
 private.ready()
 }
whenever private.cgui.bPlot3->press do
 {
 private.busy()
 calValue := private.tcalvalues[private.rcvrNum+1]
 self.plot_tsrc_time(private.scanNum,private.rcvrNum,calValue)
 private.ready()
 }
#for (ii in dapCols)
# whenever private.cgui.bP4[ii]->press do
#  {
#  private.busy()
#  self.plot_dap_time(private.scanNum,$value)
#  private.ready()
#  }

###
# More Buttons for plotting
###
private.cgui.plots2 := dws.frame(private.cgui.main,side='left')
private.cgui.dum99 := dws.label(private.cgui.plots2,'Plot:',padx=33)
private.cgui.ph_RA := dws.button(private.cgui.plots2,' Phs v. RA') 
private.cgui.ph_Dec := dws.button(private.cgui.plots2,'Phs v. Dec') 
private.cgui.tant_RA := dws.button(private.cgui.plots2,' Ta v. RA ') 
private.cgui.tant_Dec := dws.button(private.cgui.plots2,' Ta v. Dec') 
whenever private.cgui.ph_RA->press do
 {
 private.busy()
 self.plot_phase_ra(private.scanNum,private.rcvrNum,private.phaseNum)
 private.ready()
 }
whenever private.cgui.ph_Dec->press do
 {
 private.busy()
 self.plot_phase_dec(private.scanNum,private.rcvrNum,private.phaseNum)
 private.ready()
 }
whenever private.cgui.tant_RA->press do
 {
 private.busy()
 calValue := private.tcalvalues[private.rcvrNum+1]
 self.plot_tant_RA(private.scanNum,private.rcvrNum,calValue)
 private.ready()
 }
whenever private.cgui.tant_Dec->press do
 {
 private.busy()
 calValue := private.tcalvalues[private.rcvrNum+1]
 self.plot_tant_Dec(private.scanNum,private.rcvrNum,calValue)
 private.ready()
 }

###
# Other Functions
###
private.cgui.func := dws.frame(private.cgui.main,side='left')
private.cgui.dum98 := dws.label(private.cgui.func,'Procedures:',padx=12)
private.cgui.point1 := dws.button(private.cgui.func,'  Point1  ') 
private.cgui.point2 := dws.button(private.cgui.func,'  Point2  ') 
private.cgui.point4 := dws.button(private.cgui.func,'  Point4  ') 
private.cgui.foc := dws.button(private.cgui.func,'  Focus   ') 
whenever private.cgui.foc->press do
 {
 private.wait(T)
 print 'Enter name of ASCII table with focus data:'
 tableName := readline()
 private.busy()
 self.focus(tableName)
 private.ready(T)
 }
whenever private.cgui.point1->press do
 {
 private.busy()
 calValue := private.tcalvalues[private.rcvrNum+1]
 self.point1(private.scanNum,private.rcvrNum,cal_value=calValue)
 private.ready()
 }
whenever private.cgui.point2->press do
 {
 private.busy()
 calValue := private.tcalvalues[private.rcvrNum+1]
 self.point2(private.scanNum,private.rcvrNum,calValue)
 private.ready()
 }
whenever private.cgui.point4->press do
 {
 private.busy()
 calValue := private.tcalvalues[private.rcvrNum+1]
 self.point4(private.scanNum,private.rcvrNum,calValue)
 private.ready()
 }

###
# Analysis
###
#private.cgui.analy := dws.frame(private.cgui.main,side='left')
#private.cgui.dum97 := dws.label(private.cgui.analy,'Analysis:',padx=19)
#private.cgui.base := dws.button(private.cgui.analy,' Baseline ') 
#private.cgui.gauss := dws.button(private.cgui.analy,'  Gauss   ') 
#whenever private.cgui.gauss->press do
# {
# private.wait(T)
# print 'Enter center:'
# c := as_float(readline())
# print 'Enter width:'
# w := as_float(readline())
# print 'Enter height:'
# h := as_float(readline())
# private.busy()
# self.gauss(h,w,c)
# private.ready(T)
# }
#whenever private.cgui.base->press do
# {
# private.wait(T)
# print 'Enter order of fit:'
# ord := as_integer(readline())
# print 'Enter ranges to fit (in pairs):'
# c_ran := readline()
# private.busy()
# self.baselinefit(ord,c_ran)
# private.ready(T)
# }

###
# Text Box
###
private.cgui.textFrame := dws.frame(private.cgui.main,side='left')
private.cgui.textWin := dws.text(private.cgui.textFrame,relief='sunken',wrap='none',width=40,height=15)
private.cgui.textVBar := dws.scrollbar(private.cgui.textFrame)
private.cgui.bTextFrame := dws.frame(private.cgui.main,side='right')
private.cgui.pad := dws.frame(private.cgui.bTextFrame,expand='none',width=23,height=23,relief='groove')
private.cgui.textHBar := dws.scrollbar(private.cgui.bTextFrame,orient='horizontal')
whenever private.cgui.textVBar->scroll, private.cgui.textHBar->scroll do
 private.cgui.textWin->view($value)
whenever private.cgui.textWin->yscroll do
 private.cgui.textVBar->view($value)
whenever private.cgui.textWin->xscroll do
 private.cgui.textHBar->view($value)

###
# Bottom buttons
###
private.cgui.bFrame := dws.frame(private.cgui.main,side='left')
private.cgui.b1 := dws.button(private.cgui.bFrame,'Update Scans')
whenever private.cgui.b1->press do
 {
 print self.maintable.haslock(),self.maintable.ismultiused(),
       self.maintable.lockoptions(),self.maintable.ok()
 self.maintable.resync()
 self.stateTable.resync()
 self.procTable.resync()
 self.GBT_DCR_table.resync()
 self.GBT_DCR_STATE_table.resync()
 self.GOSubTable.resync()
 self.pointTable.resync()
 self.fieldTable.resync()
 self.sourceTable.resync()
 private.sl := private.scanlist()
 private.cgui.lb1->delete('start','end')
 private.cgui.lb1->insert(as_string(private.sl))
 private.cgui.lb1->see(as_string(private.sl[len(private.sl)]))
 }
private.cgui.bct := dws.button(private.cgui.bFrame,'Clear Text')
whenever private.cgui.bct->press do
 private.cgui.textWin->delete('start','end')
private.cgui.bss := dws.button(private.cgui.bFrame,'Summary')
whenever private.cgui.bss->press do
 {
 private.busy()
 self.scanSummary()
 private.ready()
 }
private.cgui.sp1 := dws.frame(private.cgui.bFrame,width=50)
private.cgui.b2 := dws.button(private.cgui.bFrame,'Ready',background='green')
private.cgui.b3 := dws.button(private.cgui.bFrame,'Dismiss',type='dismiss')
whenever private.cgui.b3->press do
 self.done()
dws.tk_release()

###
#
# JB -- End GUI stuff here
#
###

}	


