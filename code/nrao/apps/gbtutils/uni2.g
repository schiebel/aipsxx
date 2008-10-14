# The dish state sometimes causes problems with dish startup.
# For now, clear it explicity on startup of unijr.
# This only will work in GB.

if (dos.fileexists('~/aips++/dishstate/default')) {
 printf('Clearing dishstate ...')
 dos.remove('~/aips++/dishstate/default')
 printf(' done\n')
}

print 'To start the dish GUI use: d.gui()'

print ''
print '==================================================='
print 'The uni2.g file will soon be removed.'
print 'All functionality is now in the standard dish tool.'
print 'Please start using that instead!'
print '==================================================='

if (is_defined('d')) {
   if (is_const(d)) {
      print 'Cannot start uni-jr properly because you have a const variable'
      print 'named \'d\' defined.  Remove it and try again.'
      exit
   }
   else {
      print 'You currently have a variable named \'d\', which must now be'
      print 'overwritten with the dish tool of the same name.'
   }
}

dishflag := F
include 'dish.g'
for (i in symbol_names())
   if (is_tool(eval(i)))
      if (tm.tooltype(i)=='dish' && i != '__dish__' && i != '_objpublic') {
         const d := ref eval(i)
	 dishflag := T
	 break
      }
if (!dishflag) const d := dish()

d.nogui()

# Dish remains a tool.  To access some of the dish functions without invoking
# the tool explicitly, these aliases are needed.  We hope to alter this
# aspect of uni-jr sometime soon.

const uniput := ref d.uniput
const uniget := ref d.uniget
const dsummary := ref d.summary
const files := ref d.files

param := uniget()
if (!has_field(param,'astack')) {
 uniput('astack',F)
 uniput('acount',0)
 uniput('edrop',0)
 uniput('bdrop',0)
 uniput('echan',0)
 uniput('bchan',0)
 uniput('emoment',0)
 uniput('bmoment',0)
 uniput('nfit',0);
 uniput('numaccum',0);
 uniput('vref',F);
 uniput('vsig',F);
 uniput('globalscan1',F);
 uniput('nregion','[1,100000]')
 uniput('nregionArr',[1,100000])
 }

d.clearrm()
filenames := d.files(T)

const dopen := function(filename) {
   global data_numints
   global data_numphases
   global data_scannums
   d.open(filename,corrdata=T)
   data_scannums := lscans()
   for (i in 1:len(data_scannums)) data_numints[i] := d.qdumps(data_scannums[i])[5]
   for (i in 1:len(data_scannums)) data_numphases[i] := d.qdumps(data_scannums[i])[1]
   return T
}

const import := function(projdir,outms=F,outmsdir=F,startscan=F,stopscan=F,backend=F) {
   global data_numints
   global data_numphases
   global data_scannums
   if (!dos.fileexists(projdir)) {
    print 'That project directory does not exist.'
    return F
    }
   if (!is_boolean(backend)) 
    if ((backend != 'SP') && (backend != 'SPECTROMETER') &&
	(backend != 'ACS')) {
     print 'backend must be either SP, ACS, or SPECTROMETER'
     return F
     }
   if (!is_boolean(outms) && !is_string(outms)) {
    print 'outms must be a string'
    return F
    }
   if (!is_boolean(outmsdir) && !is_string(outmsdir)) {
    print 'outmsdir must be a string'
    return F
    }
   if (!is_boolean(startscan) && !is_integer(startscan)) {
    print 'startscan must be a string'
    return F
    }
   if (!is_boolean(stopscan) && !is_integer(stopscan)) {
    print 'stopscan must be a string'
    return F
    }
   if ((is_integer(startscan) && startscan<1) || 
       (is_integer(stopscan) && stopscan<1)) {
    print 'positive scan numbers only'
    return F
    }
   d.import(projdir,outms,outmsdir,startscan,stopscan,backend)
   data_scannums := lscans()
   for (i in 1:len(data_scannums)) data_numints[i] := d.qdumps(data_scannums[i])[5]
   for (i in 1:len(data_scannums)) data_numphases[i] := d.qdumps(data_scannums[i])[1]
   return T
}

const dgetscan := function(scan,nphase) {
    if (nphase > data_numphases[ind(data_scannums)[data_scannums==scan]]) {
     print 'dgetscan Error: Tried to access phase beyond the available range'
     return F
     }
    scanrec := d.getscan(scan,nphase)
    scanrec.data.arr := real(scanrec.data.arr)
    scanrec.other.numints := data_numints[ind(data_scannums)[data_scannums==scan]]
    if (any(is_nan(scanrec.data.arr))) {
     print 'Bad data.  Check for hardware problems.'
     return F
     }
    return scanrec
}

const ugetscan := function(scan,nphase=1) {
#    if (nphase > data_numphases[ind(data_scannums)[data_scannums==scan]]) {
#     print 'dgetscan Error: Tried to access phase beyond the available range'
#     return F
#     }
    scanrec := d.getscan(scan,nphase)
    scanrec.data.arr := real(scanrec.data.arr)
#    scanrec.other.numints := data_numints[ind(data_scannums)[data_scannums==scan]]
    scanrec.other.numints := 1
    uniput('globalscan1',scanrec)
    return T
}



##########################################################################
# Routines from Ron's m33.g script, which include calibration fundamentals
##########################################################################
#const avrgrec := function(scan,nphase,numphases,numints) {
#    vphase := dgetscan(scan,nphase)
#    if (is_fail(vphase) | is_boolean(vphase)) {
#     print 'Error: Bad data.'
#     return F
#     }
#    if (len(vphase.data.arr::shape)==2)
#     numfeeds := vphase.data.arr::shape[1]
#    else {
#     print 'I do not understand this data'
#     return
#    }
#    for (nfeed in 1:numfeeds) {
#     meanv := mean(vphase.data.arr[nfeed,])
#     weight := vphase.header.exposure / meanv^2
#     vphase.data.arr[nfeed,] *:= weight
#     sumweight[nfeed] := weight
#     }
#    if (numints>1)
#     for (integration in 2:numints) {
#      vtemp := dgetscan(scan,(integration-1)*numphases+nphase)
#      if (is_fail(vtemp) | is_boolean(vtemp) | 
#          vtemp.data.arr::shape[1]!=numfeeds) {
#       print 'Error: Bad data.'
#       return
#       }
#      for (nfeed in 1:numfeeds) {
#       meanv := mean(vtemp.data.arr[nfeed,])
#       weight := vtemp.header.exposure / meanv^2
#       vphase.data.arr[nfeed,] +:= (vtemp.data.arr[nfeed,]*weight)
#       vphase.header.exposure +:= vtemp.header.exposure
#       vphase.header.duration +:= vtemp.header.duration
#       sumweight[nfeed] +:= weight
#       }
#      }
#    for (nfeed in 1:numfeeds)
#     vphase.data.arr[nfeed,] /:= sumweight[nfeed]
#    return vphase
#}


# This version does no weighting between integrations

const avrgrec := function(scan,nphase,numphases,numints) {
    vphase := dgetscan(scan,nphase)
    if (is_fail(vphase) | is_boolean(vphase)) {
     print 'Error: Bad data.'
     return F
     }
    if (len(vphase.data.arr::shape)==2)
     numfeeds := vphase.data.arr::shape[1]
    else {
     print 'I do not understand this data'
     return
    }
    if (numints>1)
     for (integration in 2:numints) {
      vtemp := dgetscan(scan,(integration-1)*numphases+nphase)
      if (is_fail(vtemp) | is_boolean(vtemp) | 
          vtemp.data.arr::shape[1]!=numfeeds) {
       print 'Error: Bad data.'
       return
       }
      for (nfeed in 1:numfeeds) {
       vphase.data.arr[nfeed,] +:= vtemp.data.arr[nfeed,]
       vphase.header.exposure +:= vtemp.header.exposure
       }
      vphase.header.duration +:= vtemp.header.duration
      }
    for (nfeed in 1:numfeeds)
     vphase.data.arr[nfeed,] /:= numints
    return vphase
}

const combineOnOff := function(von,voff) {
    # Get weights from header
    won := 1
    woff := 1
    von.data.arr *:= won
    voff.data.arr *:= woff
    von.data.arr +:= voff.data.arr
    von.data.arr /:= (won + woff)
    # Need to calculate t=ton+toff, w=won+woff, maphase=K/sqrt(delfreq*wphase)
#    von.header.duration +:= voff.header.duration
    return von
}

const calcTsys := function(v,von,voff,tcal,numBox) {
    # How to get TCAL array?
    von_off := von
    von_off.data.arr := von.data.arr-voff.data.arr
    tsys := von.data.arr
    if (numBox <= 1) 
      for (i in 1:(v.data.arr::shape[1])) 
        tsys[i,] := v.data.arr[i,]*tcal[i,]/von_off.data.arr[i,]
    else if (numBox>len(v.data.arr[1,])) {
      for (i in 1:(v.data.arr::shape[1])) {
        vmean := mean(v.data.arr[i,]*tcal[i,])
        on_offmean := mean(von_off.data.arr[i,])
	tsys[i,] := vmean/on_offmean
        }
      }
    else {
      for (i in 1:(v.data.arr::shape[1]))
        v.data.arr[i,] *:= tcal[i,]
#      vsmooth := d.smooth(v,'BOXCAR',numBox,,F,F)
      vsmooth := v
      for (i in 1:v.data.arr::shape[1])
       vsmooth.data.arr[i,]:=boxsmooth(v.data.arr[i,],numBox)
#      on_offsmooth := d.smooth(von_off,'BOXCAR',numBox,,F,F)
      on_offsmooth := von_off
      for (i in 1:von_off.data.arr::shape[1])
       on_offsmooth.data.arr[i,]:=boxsmooth(von_off.data.arr[i,],numBox)
      tsys := vsmooth.data.arr/on_offsmooth.data.arr
      }
    return tsys
}

 const calcNumBox := function(von,voff,p) {
# calculates for ifeed=1 only right now.  Needs to be fixed.
    avg_von := mean(von.data.arr[1,])
    avg_voff := mean(voff.data.arr[1,])
    ton := von.header.exposure
    toff := voff.header.exposure
    delf := abs(von.header.resolution)
    n := (1/(p^2*delf*ton))*(1+(avg_von^2/(avg_von-avg_voff)^2)+(ton/toff)*(avg_voff^2/(avg_von-avg_voff)^2))
    return n
}

const rfiExcise := function(v) {
    # what do we do here?
    return v
}

const signal := function(scan,tcal_in=unset,pctTsys=0.01,verbose=F) {
# Pull out 'feed #' from fractional part of scan number
# If number of phases is NOT 2, we have a problem

 if (!any(scan==data_scannums)) {
  print 'Invalid scan number.  Use lscans() to show available scans.'
  return F
  }
 numints := data_numints[ind(data_scannums)[data_scannums==scan]]
 vsigon := avrgrec(scan,2,2,numints)
 if (vsigon.other.state.CAL==0) {
  vsigoff := vsigon
  vsigon := avrgrec(scan,1,2,numints)
  }
 else
  vsigoff := avrgrec(scan,1,2,numints)
 if (is_boolean(vsigon)|is_boolean(vsigoff)) return F
 vsig := combineOnOff(vsigon,vsigoff)

 numBox := calcNumBox(vsigon,vsigoff,pctTsys)
 if (verbose) print 'numBox = ',numBox

 tcal := getTcalSpec(tcal_in, vsigon.data.arr::shape[1], 
		     vsigon.data.arr::shape[2], vsigon.other.syscal,
		     vsigon.other.polarization);
 if (is_boolean(tcal) || is_fail(tcal)) return tcal;

 tsys := calcTsys(vsig,vsigon,vsigoff,tcal,numBox)
# Write tsys into header
 vsig.other.tsysArray := tsys
 for (i in 1:vsig.other.tsysArray::shape[1])
  vsig.header.tsys[i] := mean(vsig.other.tsysArray[i,])
 uniput('globalscan1',vsig)
 uniput('vsig',vsig)
 return T
}

const reference := function(scan,tcal_in=unset,pctTsys=0.01,verbose=F) {
 if (!any(scan==data_scannums)) {
  print 'Invalid scan number.  Use lscans() to show available scans.'
  return F
  }
 numints := data_numints[ind(data_scannums)[data_scannums==scan]]
 vrefon := avrgrec(scan,2,2,numints)
 if (vrefon.other.state.CAL==0) {
  vrefoff := vrefon
  vrefon := avrgrec(scan,1,2,numints)
  }
 else
  vrefoff := avrgrec(scan,1,2,numints)
 if (is_boolean(vrefon)|is_boolean(vrefoff)) return F
 vref := combineOnOff(vrefon,vrefoff)

 numBox := calcNumBox(vrefon,vrefoff,pctTsys)
 if (verbose) print 'numBox = ',numBox

 tcal := getTcalSpec(tcal_in,vrefon.data.arr::shape[1],vrefon.data.arr::shape[2],
		     vrefon.other.syscal,vrefon.other.polarization);
 if (is_boolean(tcal) || is_fail(tcal)) return tcal;

 tsys := calcTsys(vref,vrefon,vrefoff,tcal,numBox)
 vref.other.tsysArray := tsys
 for (i in 1:vref.other.tsysArray::shape[1])
  vref.header.tsys[i] := mean(vref.other.tsysArray[i,])
 uniput('vref',vref)
 return T
}

const get := function(scan,rec=F,pctTsys=0.01,verbose=F) {
   record1 := d.getscan(scan,1)
   if (is_boolean(rec)) {
    if (record1.other.gbt_go.SWSTATE=='FSWITCH') {
     if (record1.other.processor.TYPE=='ACS' | 
         record1.other.processor.TYPE=='SPECTRALPROCESSOR' |
         record1.other.processor.TYPE=='SPECTROMETER') {
      print 'Retrieving ',record1.other.processor.TYPE,' freq-switched scan'
      getfs(scan,pctTsys=pctTsys,verbose=verbose)
      }
     else {
      print 'Unrecognized backend'
      return F
      }
     }
    else if (record1.other.gbt_go.SWSTATE=='PSWITCHOFF') {
     print 'Retrieving position-switched ref scan'
     reference(scan,pctTsys=pctTsys,verbose=verbose)
     }
    else if (record1.other.gbt_go.SWSTATE=='PSWITCHON') {
     print 'Retrieving position-switched sig scan'
     signal(scan,pctTsys=pctTsys,verbose=verbose)
     }
    else {
     print 'FAIL: Unrecognized SWSTATE = ',record1.other.gbt_go.SWSTATE
     return F
     }
    }
   else {
    if (record1.other.gbt_go.SWSTATE=='FSWITCH') {
     if (record1.other.processor.TYPE=='ACS' | 
         record1.other.processor.TYPE=='SPECTRALPROCESSOR' |
         record1.other.processor.TYPE=='SPECTROMETER') {
      print 'Retrieving freq-switched scan; integration',rec
      getfsint(scan,rec,pctTsys=pctTsys,verbose=verbose)
      }
     }
    else if (record1.other.gbt_go.SWSTATE=='PSWITCHOFF') {
     print 'Not yet capable of handling individiual integrations in this mode.'
     print 'Averaging all integrations.'
     print 'Retrieving position-switched ref scan'
     reference(scan,pctTsys=pctTsys,verbose=verbose)
     }
    else if (record1.other.gbt_go.SWSTATE=='PSWITCHON') {
     print 'Not yet capable of handling individiual integrations in this mode.'
     print 'Averaging all integrations.'
     print 'Retrieving position-switched sig scan'
     signal(scan,pctTsys=pctTsys,verbose=verbose)
     }
    else {
     print 'FAIL: Unrecognized SWSTATE = ',record1.other.gbt_go.SWSTATE
     return F
     }
    }

   return T
}


const getbs := function(basems,scan,tcal_in=unset,flipsigref=F,pctTsys=0.01,verbose=F) {
 dopen(spaste(basems,'_A'))
 if (!any(scan==data_scannums) | !any(scan+1==data_scannums)) {
  print 'Invalid scan number.  Use lscans() to show available scans.'
  return F
  }
 numints := data_numints[ind(data_scannums)[data_scannums==scan]]
 offbeam_vrefonL1 := avrgrec(scan,2,4,numints)
 offbeam_vrefoffL1 := avrgrec(scan,1,4,numints)
 offbeam_vsigonL1 := avrgrec(scan,4,4,numints)
 offbeam_vsigoffL1 := avrgrec(scan,3,4,numints)
 onbeam_vrefonL1 := avrgrec(scan+1,2,4,numints)
 onbeam_vrefoffL1 := avrgrec(scan+1,1,4,numints)
 onbeam_vsigonL1 := avrgrec(scan+1,4,4,numints)
 onbeam_vsigoffL1 := avrgrec(scan+1,3,4,numints)
 dopen(spaste(basems,'_B'))
 offbeam_vrefonL2 := avrgrec(scan,2,4,numints)
 offbeam_vrefoffL2 := avrgrec(scan,1,4,numints)
 offbeam_vsigonL2 := avrgrec(scan,4,4,numints)
 offbeam_vsigoffL2 := avrgrec(scan,3,4,numints)
 onbeam_vrefonL2 := avrgrec(scan+1,2,4,numints)
 onbeam_vrefoffL2 := avrgrec(scan+1,1,4,numints)
 onbeam_vsigonL2 := avrgrec(scan+1,4,4,numints)
 onbeam_vsigoffL2 := avrgrec(scan+1,3,4,numints)

 numBox := calcNumBox(onbeam_vsigonL1,onbeam_vsigoffL1,pctTsys)
 if (verbose) print 'numBox = ',numBox

 tcal := getTcalSpec(tcal_in,vsigon.data.arr::shape[1],vsigon.data.arr::shape[2],
		     vsigon.other.syscal,vsigon.other.polarization);
 if (is_boolean(tcal) || is_fail(tcal)) return tcal;

 onbeam_vsigL1 := combineOnOff(onbeam_vsigonL1,onbeam_vsigoffL1)
 onbeam_vrefL1 := combineOnOff(onbeam_vrefonL1,onbeam_vrefoffL1)
 onbeam_vsigL2 := combineOnOff(onbeam_vsigonL2,onbeam_vsigoffL2)
 onbeam_vrefL2 := combineOnOff(onbeam_vrefonL2,onbeam_vrefoffL2)
 onbeam_vsigL1_tsys := calcTsys(onbeam_vsigL1,onbeam_vsigonL1,onbeam_vsigoffL1,tcal,numBox)
 onbeam_vrefL1_tsys := calcTsys(onbeam_vrefL1,onbeam_vrefonL1,onbeam_vrefoffL1,tcal,numBox)
 onbeam_vsigL2_tsys := calcTsys(onbeam_vsigL2,onbeam_vsigonL2,onbeam_vsigoffL2,tcal,numBox)
 onbeam_vrefL2_tsys := calcTsys(onbeam_vrefL2,onbeam_vrefonL2,onbeam_vrefoffL2,tcal,numBox)
 offbeam_vsigL1 := combineOnOff(offbeam_vsigonL1,offbeam_vsigoffL1)
 offbeam_vrefL1 := combineOnOff(offbeam_vrefonL1,offbeam_vrefoffL1)
 offbeam_vsigL2 := combineOnOff(offbeam_vsigonL2,offbeam_vsigoffL2)
 offbeam_vrefL2 := combineOnOff(offbeam_vrefonL2,offbeam_vrefoffL2)
 offbeam_vsigL1_tsys := calcTsys(offbeam_vsigL1,offbeam_vsigonL1,offbeam_vsigoffL1,tcal,numBox)
 offbeam_vrefL1_tsys := calcTsys(offbeam_vrefL1,offbeam_vrefonL1,offbeam_vrefoffL1,tcal,numBox)
 offbeam_vsigL2_tsys := calcTsys(offbeam_vsigL2,offbeam_vsigonL2,offbeam_vsigoffL2,tcal,numBox)
 offbeam_vrefL2_tsys := calcTsys(offbeam_vrefL2,offbeam_vrefonL2,offbeam_vrefoffL2,tcal,numBox)

 onbeam_sigL1 := onbeam_vsigL1
 onbeam_refL1 := onbeam_vrefL1
 onbeam_sigL2 := onbeam_vsigL2
 onbeam_refL2 := onbeam_vrefL2
 offbeam_sigL1 := offbeam_vsigL1
 offbeam_refL1 := offbeam_vrefL1
 offbeam_sigL2 := offbeam_vsigL2
 offbeam_refL2 := offbeam_vrefL2
 onbeam_sigL1.data.arr  *:= onbeam_vsigL1_tsys
 onbeam_refL1.data.arr  *:= onbeam_vrefL1_tsys
 onbeam_sigL2.data.arr  *:= onbeam_vsigL2_tsys
 onbeam_refL2.data.arr  *:= onbeam_vrefL2_tsys
 offbeam_sigL1.data.arr *:= offbeam_vsigL1_tsys
 offbeam_refL1.data.arr *:= offbeam_vrefL1_tsys
 offbeam_sigL2.data.arr *:= offbeam_vsigL2_tsys
 offbeam_refL2.data.arr *:= offbeam_vrefL2_tsys

 bigsig := onbeam_sigL1
 bigref := onbeam_refL1
 bigsig.data.arr := (onbeam_sigL1.data.arr+offbeam_sigL2.data.arr+offbeam_refL1.data.arr+onbeam_refL2.data.arr)/4
 bigref.data.arr := (offbeam_sigL1.data.arr+onbeam_sigL2.data.arr+onbeam_refL1.data.arr+offbeam_refL2.data.arr)/4

 caldata := bigsig
# caldata.data.arr := (bigsig.data.arr-bigref.data.arr)/bigref.data.arr
 caldata.data.arr := bigsig.data.arr-bigref.data.arr
 uniput('globalscan1',caldata)
 return T
}

const getfs := function(scan,tcal_in=unset,flipsigref=F,pctTsys=0.001,verbose=T) {
 if (!any(scan==data_scannums)) {
  print 'Invalid scan number.  Use lscans() to show available scans.'
  return F
  }
 numints := data_numints[ind(data_scannums)[data_scannums==scan]]
 tempavg := [=]
 vsigon := vsigoff := vrefon := vrefoff := F
 tempscan := d.getscan(scan,1)
#
# Always interpret first two phases as sig until the proper info is
# passed from m&c
#
 if (tempscan.other.state.CAL==0) {
  vsigoff := avrgrec(scan,1,4,numints)
  vsigon := avrgrec(scan,2,4,numints)
  vrefoff := avrgrec(scan,3,4,numints)
  vrefon := avrgrec(scan,4,4,numints)
  }
 else {
  vsigon := avrgrec(scan,1,4,numints)
  vsigoff := avrgrec(scan,2,4,numints)
  vrefon := avrgrec(scan,3,4,numints)
  vrefoff := avrgrec(scan,4,4,numints)
  }
  
 if (is_boolean(vsigon)|is_boolean(vsigoff)|is_boolean(vrefon)|is_boolean(vsigoff)) return F

 tcal := getTcalSpec(tcal_in,vsigon.data.arr::shape[1],vsigon.data.arr::shape[2],
		     vsigon.other.syscal, vsigon.other.polarization);
 if (is_boolean(tcal) || is_fail(tcal)) return tcal;

 vref := combineOnOff(vrefon,vrefoff)
 vsig := combineOnOff(vsigon,vsigoff)
 if (!flipsigref) {
  numBox := calcNumBox(vrefon,vrefoff,pctTsys)
  if (verbose) print 'numBox = ',numBox
  tsys := calcTsys(vref,vrefon,vrefoff,tcal,numBox)
  tsys2 := calcTsys(vsig,vsigon,vsigoff,tcal,numBox)
  vref.other.tsysArray := tsys
  vsig.other.tsysArray := tsys2
  bchan := len(vref.other.tsysArray[1,])/10
  echan := len(vref.other.tsysArray[1,])/10*9
  for (i in 1:vref.other.tsysArray::shape[1]) {
    vref.header.tsys[i] := mean(vref.other.tsysArray[i,bchan:echan])
    vsig.header.tsys[i] := mean(vref.other.tsysArray[i,bchan:echan])
    }
  uniput('vsig',vsig)
  uniput('vref',vref)
  }
 else {
  numBox := calcNumBox(vsigon,vsigoff,pctTsys)
  if (verbose) print 'numBox = ',numBox
  tsys := calcTsys(vsig,vsigon,vsigoff,tcal,numBox)
  tsys2 := calcTsys(vref,vrefon,vrefoff,tcal,numBox)
  vsig.other.tsysArray := tsys
  vref.other.tsysArray := tsys2
  bchan := len(vref.other.tsysArray[1,])/10
  echan := len(vref.other.tsysArray[1,])/10*9
  for (i in 1:vsig.other.tsysArray::shape[1]) {
    vsig.header.tsys[i] := mean(vsig.other.tsysArray[i,bchan:echan])
    vref.header.tsys[i] := mean(vref.other.tsysArray[i,bchan:echan])
    }
  uniput('vsig',vref)
  uniput('vref',vsig)
  }
 temp()
 return T
}

const getfsint := function(scan,intNo=1,tcal_in=unset,flipsigref=F,pctTsys=0.01,verbose=F) {
 if (!any(scan==data_scannums)) {
  print 'Invalid scan number.  Use lscans() to show available scans.'
  return F
  }
 if (intNo>data_numints[ind(data_scannums)[data_scannums==scan]]) {
  print 'getfsint Error: There are only ',
        data_numints[ind(data_scannums)[data_scannums==scan]],' integrations'
  return T
  }
 tempscan := dgetscan(scan,1)
 if (tempscan.other.state.CAL==0) {
  vsigoff := dgetscan(scan,(intNo-1)*4+1)
  vsigon := dgetscan(scan,(intNo-1)*4+2)
  vrefoff := dgetscan(scan,(intNo-1)*4+3)
  vrefon := dgetscan(scan,(intNo-1)*4+4)
  }
 else {
  vsigon := dgetscan(scan,(intNo-1)*4+1)
  vsigoff := dgetscan(scan,(intNo-1)*4+2)
  vrefon := dgetscan(scan,(intNo-1)*4+3)
  vrefoff := dgetscan(scan,(intNo-1)*4+4)
  }

 if (is_boolean(vrefon)|is_boolean(vrefoff)|is_boolean(vsigon)|is_boolean(vsigoff)) return F
 vref := combineOnOff(vrefon,vrefoff)
 vsig := combineOnOff(vsigon,vsigoff)

 tcal := getTcalSpec(tcal_in,vsigon.data.arr::shape[1],vsigon.data.arr::shape[2],
		     vsigon.other.syscal,vsigon.other.polarization);
 if (is_boolean(tcal) || is_fail(tcal)) return tcal;

 if (!flipsigref) {
  numBox := calcNumBox(vrefon,vrefoff,pctTsys)
  if (verbose) print 'numBox = ',numBox
  tsys := calcTsys(vref,vrefon,vrefoff,tcal,numBox)
  vref.other.tsysArray := tsys
  for (i in 1:vref.other.tsysArray::shape[1])
    vref.header.tsys[i] := mean(vref.other.tsysArray[i,])
  uniput('vsig',vsig)
  uniput('vref',vref)
  }
 else {
  numBox := calcNumBox(vsigon,vsigoff,pctTsys)
  if (verbose) print 'numBox = ',numBox
  tsys := calcTsys(vsig,vsigon,vsigoff,tcal,numBox)
  vsig.other.tsysArray := tsys
  for (i in 1:vsig.other.tsysArray::shape[1])
    vsig.header.tsys[i] := mean(vsig.other.tsysArray[i,])
  uniput('vsig',vref)
  uniput('vref',vsig)
  }
 temp()
 return T
}

const temp := function() {
    vsig :=  uniget('vsig')
    vref := uniget('vref')
    if (!is_sdrecord(vsig) | !is_sdrecord(vref)) {
     print 'Invalid signal/reference data'
     return F
     }
    tsysref := vref.other.tsysArray
    vsig.data.arr := tsysref*(vsig.data.arr-vref.data.arr)/vref.data.arr
    vsig.other.tsysArray := tsysref
    for (i in 1:vsig.other.tsysArray::shape[1])
     vsig.header.tsys[i] := mean(vsig.other.tsysArray[i,])
    vsig.data.desc.units := 'Ta'
    vsig.header.duration +:= vref.header.duration
    uniput('globalscan1',vsig)
    uniput('vsig',vsig)
    return T
}

const getir := function(scan,phase) {
 if (!any(scan==data_scannums)) {
  print 'Invalid scan number.  Use lscans() to show available scans.'
  return F
  }
    uniput('globalscan1',dgetscan(scan,phase))
    return T
}

const accum := function() {
    numaccum := uniget('numaccum')
    gl := uniget('globalscan1')
    if (numaccum>0) {
        ac := uniget('accumed')
	wgt := gl.header.exposure/gl.header.tsys^2
	for (i in 1:ac.data.arr::shape[1])
         ac.data.arr[i,]:=ac.data.arr[i,]+gl.data.arr[i,]*wgt[i]
	ac.header.exposure +:= gl.header.exposure
	ac.header.duration +:= gl.header.duration
	global accum_sumwgt := accum_sumwgt + wgt
        uniput('accumed',ac)
        uniput('numaccum',numaccum+1)
    } else {
	for (i in 1:gl.data.arr::shape[1])
         gl.data.arr[i,] *:= gl.header.exposure/gl.header.tsys[i]^2
        uniput('accumed',gl)
        uniput('numaccum',1)
	global accum_sumwgt := gl.header.exposure/gl.header.tsys^2
    }
    return T
}

const sclear := function() {
    uniput('numaccum',0)
    global accum_sumwgt := 0
    return T
}

const ave := function() {
    numaccum := uniget('numaccum')
    if (numaccum>0) {
        ac := uniget('accumed')
	for (i in 1:ac.data.arr::shape[1])
         ac.data.arr[i,] /:= accum_sumwgt[i]
        uniput('globalscan1',ac)
    } else {
        print 'Nothing to average'
    }
#    sclear()
    return T
}

const stats := function(quiet=F,feed=0,bchan=0,echan=0) {
    gl := uniget('globalscan1')
    if (bchan==0) {
      bchan := uniget('bchan')
      if (bchan==0)
        bchan := 1
      }
    else
      uniput('bchan',bchan)
    if (echan==0) {
      echan := uniget('echan')
      if (echan==0)
        echan := gl.data.arr::shape[2]
      }
    else
      uniput('echan',echan)
    if (feed==0) {
     begin := 1 
     end := gl.data.arr::shape[1]
     }
    else {
     begin := feed
     end := feed
     }
    for (ifeed in begin:end) {
     data := gl.data.arr[ifeed,bchan:echan]
     data_mean := mean(data)
     rms := stddev(data)
     printf('Feed : %-5d   bchan: %-6d   rms  : %-12.6f   min  : %-12.6f\n',
      ifeed,bchan,rms,min(data))
     printf('Npts : %-5d   echan: %-6d   mean : %-12.6f   max  : %-12.6f\n',
      len(data),echan,data_mean,max(data))
     printf('\n')
     }
    return T
}

##########################################################################

const getc := function(scan) {
 if (!any(scan==data_scannums) || !any((scan+1)==data_scannums)) {
  print 'Invalid scan number.  Use lscans() to show available scans.'
  return F
  }
 print 'First scan ...'
 ok:=reference(scan);
 rec:=uniget('vref');
 if (rec.other.gbt_go.PROCNAME=='offon') {
   if (rec.other.gbt_go.PROCSEQN==1) {
        print 'Second scan ...'
	ok := signal(scan+1);
	ok := temp();
   } else if (rec.other.gbt_go.PROCSEQN==2) {
 	uniput('globalscan1',rec);
        print 'Second scan ...'
	ok := reference(scan-1);
	ok := temp();
   }
 } else {
   print 'FAIL: unrecognized procedure name ';
   return F;
 }
 return T;
}

const page := function() {
 d.plotter.clear()
 return T
}

const show := function() {
 globalscan1 := uniget('globalscan1')
 bdrop := uniget('bdrop')
 edrop := uniget('edrop')
 if (bdrop==0 && edrop==0)
  d.plotscan(globalscan1)
 else {
  print 'Plot using bdrop = ',bdrop, 'and edrop = ',edrop
  if (bdrop==0) begin := 1
  else begin := bdrop
  if (edrop==0) end := globalscan1.data.arr::shape[2]
  else end := globalscan1.data.arr::shape[2]-edrop
  temp := globalscan1
  temp.data.desc.chan_freq.value := globalscan1.data.desc.chan_freq.value[begin:end];
  temp.data.flag := globalscan1.data.flag[,begin:end];
  temp.data.weight := globalscan1.data.weight[,begin:end];
  temp.data.sigma := globalscan1.data.sigma[,begin:end];
  temp.data.arr:=globalscan1.data.arr[,begin:end];
  d.plotter.plotrec(temp)
  }
 return T;
}

const show1 := function(ifeed) {
 gl := uniget('globalscan1')
 if ((ifeed < 1) || (ifeed > gl.data.arr::shape[1])) {
  print 'feed number out of range'
  return F
  }
 for (i in 1:gl.data.arr::shape[1])
  if (i!=ifeed)
   gl.data.arr[i,] := 0
 bdrop := uniget('bdrop')
 edrop := uniget('edrop')
 if (bdrop==0 && edrop==0)
  d.plotscan(gl)
 else {
  print 'Plot using bdrop = ',bdrop, 'and edrop = ',edrop
  if (bdrop==0) begin := 1
  else begin := bdrop
  if (edrop==0) end := gl.data.arr::shape[2]
  else end := gl.data.arr::shape[2]-edrop
  temp := gl
  temp.data.desc.chan_freq.value := gl.data.desc.chan_freq.value[begin:end];
  temp.data.flag := gl.data.flag[,begin:end];
  temp.data.weight := gl.data.weight[,begin:end];
  temp.data.sigma := gl.data.sigma[,begin:end];
  temp.data.arr:=gl.data.arr[,begin:end];
  d.plotter.plotrec(temp)
  }
 return T;
}

const showref := function() {
 refscan := uniget('vref')
 bdrop := uniget('bdrop')
 edrop := uniget('edrop')
 if (bdrop==0 && edrop==0)
  d.plotscan(refscan)
 else {
  print 'Plot using bdrop = ',bdrop, 'and edrop = ',edrop
  if (bdrop==0) begin := 1
  else begin := bdrop
  if (edrop==0) end := refscan.data.arr::shape[2]
  else end := refscan.data.arr::shape[2]-edrop
  temp := refscan
  temp.data.desc.chan_freq.value := refscan.data.desc.chan_freq.value[begin:end];
  temp.data.flag := refscan.data.flag[,begin:end];
  temp.data.weight := refscan.data.weight[,begin:end];
  temp.data.sigma := refscan.data.sigma[,begin:end];
  temp.data.arr:=refscan.data.arr[,begin:end];
  d.plotter.plotrec(temp)
  }
 return T;
}

const nregion := function(...) {
 if (num_args(...)== 0) {
  nr := uniget('nregion')
  print 'nregion currently set to: ',nr
  print 'To modify these values, use this function as follows:'
  print 'nregion(1,256,850,1023)'
  return T
  }
 if (num_args(...)%2 != 0) {
  print 'An even number of arguments is required for nregion'
  return T
  }
 for (i in 1:num_args(...))
  limit[i] := nth_arg(i,...)
 if (limit != sort(limit)) {
  print 'Error: the arguments must be sorted from lowest to highest'
  return T
  }
 nr := ''
 for (i in 1:(len(limit)/2))
  nr := spaste(nr,'[',limit[i*2-1],',',limit[i*2],']')
 uniput('nregion',nr)
 uniput('nregionArr',limit)
 return T
}

const baseline := function() {
 # Set global unipops-like variables nfit and nregion prior to calling this.
 # e.g. nfit(2)
 #      nregion(1,256,512,1024)
 #      baseline()
 nf := uniget('nfit')
 nr := uniget('nregion')
 globalscan1 := uniget('globalscan1')
 globalscan1 := d.base(scanrec=globalscan1,order=nf,action='subtract',range=nr,
                       autoplot=F)
 uniput('globalscan1',globalscan1)
 rms(F)
 return T
}

const rms := function(printFlag=T) {
 gl := uniget('globalscan1')
 if (!is_sdrecord(gl)) {
  print 'No data available for rms'
  return F
  }
 nr := uniget('nregionArr')
 if (nr[1] < 1) {
  note('First entry in nregion must be > 0 to calculate baseline stats.')
  note('Calculating stats starting at pixel 1.')
  nr[1] := 1
  }
 if (nr[len(nr)] > gl.data.arr::shape[2]) {
  note('Last entry in nregion too large.')
  note('Using ',gl.data.arr::shape[2],' for calculating baseline stats.')
  nr[len(nr)] := gl.data.arr::shape[2]
  }
 return_val := T
 if (!printFlag) return_val := [=]
 for (feed in 1:(gl.data.arr::shape[1])) {
  data := F
  for (i in 1:(len(nr)/2))
   data := [data,gl.data.arr[feed,nr[i*2-1]:nr[i*2]]]
  data := data[2:len(data)]
  data_mean := mean(data)
  rms := stddev(data)
  if (printFlag) {
   print '== Feed ',feed,' ==='
   print 'RMS   = ',rms,'   Mean = ',data_mean,'   Num points = ',len(data)
   print 'max   = ',max(data),'  min = ',min(data)
   print 'nregion = ',nr
   }
  else {
   note('== Feed ',feed,' ===')
   note('RMS   = ',rms,'   Mean = ',data_mean,'   Num points = ',len(data))
   note('max   = ',max(data),'  min = ',min(data))
   note('nregion = ',nr)
   return_val.rms[feed] := rms
   return_val.max[feed] := max(data)
   return_val.min[feed] := min(data)
   return_val.mean[feed] := data_mean
   }
  }
 return return_val
}

const dcbase := function() {
 # Set global unipops-like variable nregion prior to calling dcbase.
 # e.g. nregion(1,256,512,1024)
 #      dcbase()
 nr := uniget('nregion')
 globalscan1 := uniget('globalscan1')
 d.base(scanrec=globalscan1,order=0,action='subtract',range=nr)
 globalscan1 := d.rm().getvalues(d.rm().size()) 
 uniput('globalscan1',globalscan1)
 return T
}

const bshape := function() {
 nf := uniget('nfit')
 nr := uniget('nregion')
 globalscan1 := uniget('globalscan1')
 d.base(scanrec=globalscan1,order=nf,action='show',range=nr)
 return T
}

const uscale := function(factor) {
 globalscan1 := uniget('globalscan1')
 if (len(factor)==1) factor := array(factor,globalscan1.data.arr::shape[1])
 if ((len(factor)==globalscan1.data.arr::shape[1]))
  for (i in 1:globalscan1.data.arr::shape[1])
   globalscan1.data.arr[i,] *:= factor[i]
 else {
  print 'length of factor does not match data shape.'
  return F
  }
 uniput('globalscan1',globalscan1)
 return T
}

const bias := function(factor) {
 globalscan1 := uniget('globalscan1')
 if (len(factor)==1 || (len(factor)==globalscan1.data.arr::shape[1]))
  for (i in 1:globalscan1.data.arr::shape[1])
   globalscan1.data.arr[i,] +:= factor[i]
 else {
  print 'length of factor does not match data shape.'
  return F
  }
 uniput('globalscan1',globalscan1)
 return T
}

const addstack := function(beg,end=beg,inc=1) {
 astack := uniget('astack')
 acount := uniget('acount')
 if (!is_boolean(astack) && acount != len(astack))
  print 'Error: acount lost track of astack'
 for (i in seq(beg,end,inc)) {
  acount := acount + 1
  astack[acount] := i
  }
 uniput('astack',astack)
 uniput('acount',acount)
 return T
}

const empty := function() {
 uniput('acount',0)
 uniput('astack',F)
 return T
}

const delete := function(value) {
 astack := uniget('astack')
 acount := 0
 for (i in 1:len(astack))
  if (astack[i] != value) {
   acount +:= 1
   newastack[acount] := astack[i]
   }
 uniput('astack',newastack)
 uniput('acount',acount)
 return T
}

const tellstack := function() {
 astack := uniget('astack')
 acount := uniget('acount')
 if (is_boolean(astack))
  print 'No entries currently in the stack.'
 else {
  print acount,' entries in the stack.'
  print astack
  }
 return T
}

const utable := function() {
 bdrop := uniget('bdrop')
 edrop := uniget('edrop')
 globalscan1 := uniget('globalscan1')
 if (bdrop==0) begin := 1
 else begin := bdrop
 if (edrop==0) end := globalscan1.data.arr::shape[2]
 else end := edrop
 for (i in begin:end)
  print i,globalscan1.data.arr[,i]
 return T
}

const header := function() {
 g := uniget('globalscan1')
 if (!is_sdrecord(g)) {
  print 'No data in memory'
  return F
  }
 dq.setformat('long','hms')
 dq.setformat('lat','dms')
 printf('Proj : %-15s    Src  : %-15s    Proc : %-15s\n',
  g.other.gbt_go1.PROJID,
  g.other.gbt_go.OBJECT,
  g.other.gbt_go.PROCNAME)
 printf('Obs  : %-15s    RA   : %-15s    PType: %-15s\n',
  g.other.gbt_go.OBSERVER,
  dm.dirshow(g.header.direction)[1],
  g.other.gbt_go.PROCTYPE)
 printf('Scan : %-15d    Dec  : %-15s    OType: %-15s\n',
  g.other.gbt_go.SCAN,
  dm.dirshow(g.header.direction)[2],
  g.other.gbt_go.OBSTYPE)
 printf('Seq  : %-15s    Epoch: %-15s    Swtch: %-15s\n',
  spaste(g.other.gbt_go.PROCSEQN,'/',g.other.gbt_go.PROCSIZE),
  dm.dirshow(g.header.direction)[3],
  g.other.gbt_go.SWSTATE)
 dateStr := dq.time(dm.getvalue(dm.measure(g.header.time, 'utc'))[1],form='ymd')
 dateStr =~ s/\/+/$$/g
 printf('Date : %-15s    Az   : %-15.3f    Swsig: %-15s\n',
  spaste(dateStr[1],'-',dateStr[2],'-',dateStr[3]),
  g.header.azel.m0.value*180/pi,
  g.other.gbt_go.SWTCHSIG)
 printf('Time : %-12s UT    El   : %-15.3f    Ints : %-15d\n',
  dq.time(dm.getvalue(dm.measure(g.header.time, 'utc'))[1]),
  g.header.azel.m1.value*180/pi,
  g.other.numints)
 printf('\n')
 printf('Tsys : %-15s    Trx  : %-15s    Tcal : %-15s\n',
  sprintf('%-6.2f',g.header.tsys),
  sprintf('%-6.2f',g.header.trx),
  sprintf('%-6.2f',g.header.tcal))
 printf('\n')
 printf('BW   : %-8.3f (MHz)     Res  : %-8.3f (kHz)\n',
  abs(g.header.bandwidth)/1e6,
  abs(g.header.resolution)/1e3)
 printf('Expos: %-15.3f    Durat: %-15.3f\n',
  g.header.exposure,
  g.header.duration)
 return T
}

const saxis := function(strval) {
 if (any(strval==['GHz','MHz','kHz','Hz','km/s','m/s','pix']))
  d.plotter.ips.setabcissaunit(strval)
 else
  print 'Error: invalid units type'
 return T
}

set_int := function(param,value) {
 if (is_boolean(value))
   return uniget(param)
 else if (is_integer(value))
   uniput(param,value)
 else
   print 'Integer value required.'
 return T
}

set_float := function(param,value) {
 if (is_boolean(value))
   return uniget(param)
 else if (is_integer(value) || is_float(value))
   uniput(param,value)
 else
   print 'Real value required.'
 return T
}
   
const bgauss := function(value=T) { set_int('bgauss',value) }
const egauss := function(value=T) { set_int('egauss',value) }
const center := function(value=T) { set_float('center',value) }
const hwidth := function(value=T) { set_float('hwidth',value) }
const height := function(value=T) { set_float('height',value) }
const bmoment := function(value=T) { set_int('bmoment',value) }
const emoment := function(value=T) { set_int('emoment',value) }
const bdrop := function(value=T) { set_int('bdrop',value) }
const edrop := function(value=T) { set_int('edrop',value) }
const nfit := function(value=T) { set_int('nfit',value) }

const moment := function(quiet=F) {
 bmoment := uniget('bmoment')
 emoment := uniget('emoment')
 globalscan1 := uniget('globalscan1')
 if (bmoment==0) bmoment := 1
 if (emoment==0) emoment := len(globalscan1.data.arr[1,])

 xval := 1:len(globalscan1.data.arr[1,])
 yval := globalscan1.data.arr

# not currently supported ... only channels are.
 unit := d.plotter.ips.getabcissaunit()

 globalscan1 := uniget('globalscan1')
 if (emoment==len(globalscan1.data.arr[1,])) emoment -:= 1
 for (ipol in 1:(globalscan1.data.arr::shape[1])) {
  moment1 := 0
  moment2 := 0
  sumweights := 0
  for (i in bmoment:emoment) {
   moment1 +:= (xval[i+1]-xval[i])*yval[ipol,i]
   moment2 +:= xval[i]*yval[ipol,i]*(xval[i+1]-xval[i])
   }
  moment2 /:= moment1
  if (!quiet) print 'Integrated Intensity = ', moment1, 'Centroid = ', moment2
  uniput('mom_int',moment1)
  uniput('mom_cent',moment2)
 }
 return T
}

const push := function() {
 uniput('offscan1',uniget('globalscan1'))
 return T
}

const minus := function() {
 globalscan1 := uniget('globalscan1')
 offscan1 := uniget('offscan1')
 globalscan1.data.arr := globalscan1.data.arr-offscan1.data.arr
 uniput('globalscan1',globalscan1)
 return T
}

const plus := function() {
 globalscan1 := uniget('globalscan1')
 offscan1 := uniget('offscan1')
 globalscan1.data.arr := globalscan1.data.arr+offscan1.data.arr
 uniput('globalscan1',globalscan1)
 return T
}

const multiply := function() {
 globalscan1 := uniget('globalscan1')
 offscan1 := uniget('offscan1')
 globalscan1.data.arr := globalscan1.data.arr * offscan1.data.arr
 uniput('globalscan1',globalscan1)
 return T
}

const divide := function() {
 globalscan1 := uniget('globalscan1')
 offscan1 := uniget('offscan1')
 globalscan1.data.arr := globalscan1.data.arr / offscan1.data.arr
 uniput('globalscan1',globalscan1)
 return T
}

const copy := function(fromhere,tohere) {
 uniput(tohere,uniget(fromhere))
 return T
}

const upr := function(...) {
 if (num_args(...)==0) {
  print 'Error: supply a list of parameter names for printing, or\'all\''
  return T
  }
 if (nth_arg(1,...)=='all') {
  allparams := uniget()
  for (i in field_names(allparams))
   if (is_record(allparams[i]))
    print i,' = a record'
   else
    print i,' = ',allparams[i]
 } else {
  for (i in 1:num_args(...)) {
   if (!is_fail(uniget(nth_arg(i,...)))) {
    value := uniget(nth_arg(i,...))
    print nth_arg(i,...),' = ',value
   } else
    print nth_arg(i,...),' = not available'
   }
  }
 return T
}

peak := function(quiet=F) {
 globalscan1 := uniget('globalscan1')
 start := uniget('bdrop')
 stop := len(globalscan1.data.arr[1,]) - uniget('edrop')
 if (start<=0) start := 1
 if (stop>len(globalscan1.data.arr[1,])) stop := len(globalscan1.data.arr[1,])

# not currently supported ... only channels are.
 unit := d.plotter.ips.getabcissaunit()
 yval := globalscan1.data.arr
 for (ipol in 1:(globalscan1.data.arr::shape[1])) {
  height := -1.e-20
  sumweights := 0
  for (i in start:stop) {
   if (yval[ipol,i]>height) {
       height:=yval[ipol,i]
       center:=i
   }
  }
  for (i in start:center)
   if (yval[ipol,i]<=height/2)
       hw1:=i
  for (i in center:stop)
   if (yval[ipol,i]>=height/2)
       hw2:=i
  hwidth:=abs(hw2-hw1)
  egauss:=center-hwidth
  bgauss:=center+hwidth
  if (!quiet) print 'Center=',center, 'Hwidth=', hwidth, 'Height=', height
  uniput('center',center)
  uniput('height',height)
  uniput('bgauss',egauss)
  uniput('egauss',bgauss)
  uniput('hwidth',hwidth)
  }
 return T
}

const lscans := ref d.listscans

const chngfile := function(outfile=F) {
 if (is_boolean(outfile))
   outfile := readline('Enter the name of the new keep file -> ')
 if (outfile=='') {
  print 'No change in keep file.'
  return T
  }
 exists := dos.fileexists(outfile)
 origfile := files(T)
 if (exists) {
  print 'File exists.  Scans will be appended.'
  d.open(outfile,access='w')
  d.fileout(outfile)
  }
 else {
  print 'New file will be created for writing.'
  d.open(outfile,new=T,access='w')
  d.fileout(outfile)
  }
 uniput('outfile',outfile)
 if (!is_boolean(origfile.filein))
  d.filein(origfile.filein)
 return T
}

const keep := function() {
 gs1 := uniget('globalscan1')
 origfile := d.files(T)
 if (is_boolean(origfile.fileout)) {
  print 'No fileout specified.  Use chngfile before keep'
  return F
  }
# d.save(gs1,origfile.fileout)
 d.save(gs1)
 print 'scan saved to ',origfile.fileout
 return T
}

const kget := function(scan,nphase=F) {
 jfiles := d.files(T)
 d.filein(jfiles.fileout)
 kscans := lscans()
 if (!any(scan==kscans)) {
  print 'Scan not found.  Use klscans() to list available keep scans.'
  d.filein(jfiles.filein)
  return F
  }
 if (nphase)
  gs1 := d.getscan(scan,nphase)
 else
  gs1 := d.getscan(scan)
 if (is_fail(gs1)) {
  print 'Scan not found.  Use klscans() to list available keep scans.'
  d.filein(jfiles.filein)
  return F
  }
 gs1.data.arr := real(gs1.data.arr)
 gs1.other.numints := 0
 uniput('globalscan1',gs1)
 d.filein(jfiles.filein)
 return T
}

const klscans := function() {
 jfiles := d.files(T)
 if (is_boolean(jfiles.fileout)) {
  print 'No output file is declared.'
  return 
  }
 d.filein(jfiles.fileout)
 print 'Keep scans = ', lscans()
 print ''
 if (!is_boolean(jfiles.filein))
  d.filein(jfiles.filein)
 return T
}

const hanning := function() {
 gs1 := uniget('globalscan1')
 gs2 := d.smooth(gs1,'HANNING',,,T,F)
 uniput('globalscan1',gs2)
 return T
}

const boxcar := function(smooth_width) {
 gs1 := uniget('globalscan1')
 gs2 := d.smooth(gs1,'BOXCAR',smooth_width,,T,F)
 uniput('globalscan1',gs2)
 return T
}

const chngres := function(smooth_width) {
 gs1 := uniget('globalscan1')
 gs2 := d.smooth(gs1,'GAUSSIAN',smooth_width,,T,F)
 uniput('globalscan1',gs2)
 return T
}

const setYUnit := function(unit) {
 gs1 := uniget('globalscan1')
 gs1.data.desc.units := unit
 uniput('globalscan1',gs1)
 return T
}

const calibTaStar := function(tau=0.012,eta_l=0.99) {
 Ta := uniget('globalscan1')
 elev := Ta.header.azel.m1.value
 factor := exp(tau/sin(elev))/eta_l
 Ta.data.arr *:= factor
 Ta.data.desc.units := 'Ta* in K'
 uniput('globalscan1',Ta)
 return T
}

const calibTmb := function(tau=0.012,eta_m=0.98) {
 Ta := uniget('globalscan1')
 elev := Ta.header.azel.m1.value
 factor := exp(tau/sin(elev))/eta_m
 Ta.data.arr *:= factor
 Ta.data.desc.units := 'Tmb in K'
 uniput('globalscan1',Ta)
 return T
}

const calibSnu := function(tau=0.012,eta_a=0.7) {
 Ta := uniget('globalscan1')
 elev := Ta.header.azel.m1.value
 factor := 2*1.381e-23/pi/2500*exp(tau/sin(elev))/eta_a*1e26
 Ta.data.arr *:= factor
 Ta.data.desc.units := 'Jy'
 uniput('globalscan1',Ta)
 return T
}

const avgFeeds := function() {
 Ta := uniget('globalscan1')
 sum := F
 for (i in 1:Ta.data.arr::shape[1])
  sum +:= Ta.data.arr[i,]
 Ta.data.arr[1,] := sum/Ta.data.arr::shape[1] 
 if (Ta.data.arr::shape[1] > 1)
  for (i in 2:Ta.data.arr::shape[1])
   Ta.data.arr[i,] := 0
 uniput('globalscan1',Ta)
 return T
}

const galactic := function(quiet=F) {
 dq.setformat('long','+deg')
 dq.setformat('lat','deg')
 gl := uniget('globalscan1')
 dm.doframe(gl.header.time)
 dm.doframe(dm.observatory('GBT'))
 position := gl.header.direction
 gal := dm.measure(position,'GALACTIC')
 galrec.lon := gal.m0.value*180/pi
 galrec.lat := gal.m1.value*180/pi
 if (galrec.lon < 0) galrec.lon := galrec.lon+360
 if (quiet)
  return galrec
 else
  print dm.dirshow(gal)
 return T
}

const ls := function()
{
 maximum := 0
 flds := sort(shell('ls'))
 for (i in flds)
  if ((strlen(i)+1)>maximum) maximum := strlen(i)+1
 ncols := min(as_integer(80/maximum),len(flds))
 nrows := as_integer((len(flds)-1)/ncols) + 1
 strformat := spaste('%-',maximum,'s')
 if (len(flds)!=nrows*ncols) {
  for (i in (len(flds)+1):nrows*ncols)
    flds[i] := ' '
  }
 for (i in 1:nrows) {
  for (j in 1:ncols)
   printf(strformat,flds[(j-1)*nrows+i])
  printf('\n')
  } 
 return T
}

const getvf := function(chan) {
 gs1 := uniget('globalscan1')
 max := len(gs1.data.arr[1,])
 if (!is_integer(chan)) {
  print 'only integer specification for channel number is allowed'
  return F
  }
 if (chan<1 || chan>max) {
  print 'channel out of range.'
  return F
  }
 print chan,d.plotter.csys.ftv(gs1.data.desc.chan_freq.value[chan]),
       gs1.data.desc.chan_freq.value[chan]
 return T
}

const getvfarray := function() {
 ret := [=]
 gs1 := uniget('globalscan1')
 max := len(gs1.data.arr[1,])
# for (chan in 1:max) {
#  ret.v[chan] := d.plotter.csys.ftv(gs1.data.desc.chan_freq.value[chan])
#  ret.f[chan] := gs1.data.desc.chan_freq.value[chan]
#  }
 ret.v := d.plotter.csys.ftv(gs1.data.desc.chan_freq.value)
 ret.f := gs1.data.desc.chan_freq.value
 return ret
}

const store := function() {
 params := uniget()
 write_value(params,spaste(shell('echo $HOME'),'/.uni2params'))
}

const restore := function() {
 tst := dos.fileexists('~/.uni2params')
 if (tst) {
  params := read_value(spaste(shell('echo $HOME'),'/.uni2params'))
# should modify uniput so that all these can be entered at once
  uniput('astack',params.astack)
  uniput('acount',params.acount)
  uniput('edrop',params.edrop)
  uniput('bdrop',params.bdrop)
  uniput('echan',params.echan)
  uniput('bchan',params.bchan)
  uniput('emoment',params.emoment)
  uniput('bmoment',params.bmoment)
  uniput('nfit',params.nfit);
  uniput('numaccum',params.numaccum);
  uniput('vref',params.vref);
  uniput('vsig',params.vsig);
  uniput('globalscan1',params.globalscan1);
  uniput('nregion',params.nregion)
  uniput('nregionArr',params.nregionArr)
  return T
  }
 else {
  print 'Parameters are not available.'
  return F
  }
}

const setregion := function() {
 region := ''
 saxis('pix')
 show()
 print 'Use the left button to set location, right button to exit'
 inc := 0
 plot_limits := d.plotter.qwin()
 while(T) {
  curs_val := d.plotter.curs()
  if (curs_val.ch=='X') break;
  if (curs_val.ch=='A') {
   inc +:= 1
   val1[inc] := as_integer(curs_val.x+0.5)
   d.plotter.line([val1[inc],val1[inc]],[plot_limits[3],plot_limits[4]])
   }
  }
 val1 := sort(val1)
 if (inc%2!=0) 
  val2[1:inc-1] := val1[inc-1]
 else 
  val2 := val1
 for (i in 1:(len(val2)/2))
  region := spaste(region,'[',val2[i*2-1],',',val2[i*2],']')
 uniput('nregion',region)
 uniput('nregionArr',val2)
 print 'region = ',val2
 show()
 meanval := (plot_limits[3]+plot_limits[4])/2
 d.plotter.sci(1)
 for (i in seq(1,len(val2),2)) 
  d.plotter.line([val2[i],val2[i+1]],[meanval,meanval])
 return T
}



const bs := function(s) {
 getfs(s)
 a := uniget('globalscan1')
 getfs(s+1)
 b := uniget('globalscan1')
 a.data.arr := (a.data.arr-b.data.arr)/2
 a.header.exposure +:= b.header.exposure
 a.header.duration +:= b.header.duration
 uniput('globalscan1',a)
}

const bsflip := function(s) {
 getfs(s,flipsigref=T)
 a := uniget('globalscan1')
 getfs(s+1,flipsigref=T)
 b := uniget('globalscan1')
 a.data.arr := (a.data.arr-b.data.arr)/2
 a.header.exposure +:= b.header.exposure
 a.header.duration +:= b.header.duration
 uniput('globalscan1',a)
}

boxsmooth := function(arr,width) {
 if (len(arr::shape) != 1 ) {
  print 'Error in boxsmooth'
  return F
  }

 smooth := array(0,len(arr))
 width := as_integer(width+0.5)
 if (!(width%2)) width +:= 1

 first := as_integer(width/2)+1
 last := len(arr)-first+1

 for (i in 1:first)
  smooth[i] := sum(arr[1:i])/i
 for (i in len(arr):last)
  smooth[i] := sum(arr[i:len(arr)])/(len(arr)-i+1)
 smooth[first] := sum(arr[1:width])/width
 for (i in (first+1):(last-1))
  smooth[i] := smooth[i-1]+(arr[i+as_integer(width/2)]-arr[i-as_integer(width/2)-1])/width
 return smooth
}

# utility function used in a number of the above.
# fish the appropriate tcal as a vector out of the
# syscal record given the polarization record and the
# number of correlations (ncorr) and number of channels
# nchan in the data
const getTcalSpec := function(tcal_in,ncorr,nchan,syscal,polarization)
{
    result := array(as_float(0.0),ncorr,nchan);
    if (is_unset(tcal_in)) {
	if (ncorr != polarization.CORR_PRODUCT::shape[2]) {
	    print 'Error!  Shapes of arrays differ in getfs';
	    return F;
	}
	for (corr in 1:ncorr) {
	    rcpt1 := polarization.CORR_PRODUCT[1,corr];
	    if (polarization.CORR_PRODUCT::shape[1] > 1) {
		rcpt2 := polarization.CORR_PRODUCT[2,corr];
	    } else {
		# bug in earlier fillers
		rcpt2 := rcpt1;
	    }
	    if (rcpt1==rcpt2) {
		result[corr,] := syscal.TCAL_SPECTRUM[rcpt1,];
	    } else {
		result[corr,] := sqrt(syscal.TCAL_SPECTRUM[rcpt1,] *
				      syscal.TCAL_SPECTRUM[rcpt2,]);
	    }
	}
    } else {
	if (len(tcal_in) != 1) {
	    print 'Problem with tcal in getfs';
	    return F;
	}
	result := array(tcal_in, ncorr, nchan);
    }
    return result;
}
