#
# ATCA Calibration test script
# Tara Murphy 
# 
# Tests that calibration works for ATCA data
# Also tests that accuracy of calibration is
# acceptable, by comparison with Miriad results
#

include 'ms.g'
include 'sysinfo.g'
include 'calibrater.g'
include 'imager.g'
include 'quanta.g'

include 'miriadCompare.g'

atcaCalibrationTests := subsequence(msname, ddescid, pName='1934-638', pid=1){
  its := [=]
  its.msname := msname
  its.ddescid := ddescid
  its.pName := pName
  its.pid := pid

  const its.printTime := function(stime){
    etime := time()
    print spaste('## Finished in run time = ', (etime - stime), ' seconds')
    print '## --------------------------------------------'
  }

  const its.compare_flux1934 := function(){
    # Flux density (Jy) of 1934-638
    flux1384 := 14.94
    flux2496 := 11.14
    flux4800 := 5.83
    flux8640 := 2.84


  }

  const its.setJy := function(fieldid, spwid){
    wider its
    imgr := imager(its.msname)
    if(is_fail(imgr)) fail

    ok := imgr.setjy(fieldid=fieldid, spwid=spwid)
    if(is_fail(ok)) fail

    imgr.done()
    return T
  }

  const its.solveforPrimary := function(spwid, selectstr){
    wider its
    ok := its.setJy(its.pid, spwid)
    if(is_fail(ok)) fail

    cal := calibrater(its.msname)
    if(is_fail(cal)) fail

    cal.setdata(msselect=selectstr)
    cal.setapply(type='P', t=10.0)
    cal.setsolve(type='G', t=5.0, table='tabG', refant=3)
    ok := cal.solve()
    if(is_fail(ok)) fail

    cal.reset()
    cal.setapply(type='P', t=10.0)
    cal.setapply(type='G', t=5.0, table='tabG')
    cal.setsolve(type='B', t=1.e6, table='tabB', refant=3)
    ok := cal.solve()
    if(is_fail(ok)) fail

    cal.reset()
    cal.setapply(type='G', t=5.0, table='tabG')
    cal.setapply(type='B', t=1.e6, table='tabB')
    cal.setsolve(type='D', t=1.e6, table='tabD', refant=3)
    ok := cal.solve()
    if(is_fail(ok)) fail
    cal.done()          
    return T
  }

  const its.multisolveforPrimary := function(spwid, selectstr){
    wider its
    ok := its.setJy(its.pid, spwid)
    if(is_fail(ok)) fail

    cal := calibrater(its.msname)
    if(is_fail(cal)) fail

    cal.setdata(msselect=selectstr)
    cal.setapply(type='P', t=10.0)
    cal.setsolve(type='G', t=5.0, table='tabG', refant=3)
    cal.setsolve(type='B', t=1.e6, table='tabB', refant=3)
    cal.setsolve(type='D', t=1.e6, table='tabD', refant=3)
    ok := cal.solve()
    if(is_fail(ok)) fail
    cal.done()          
    return T
  }

  const its.solveforSecondary := function(selectstr, linpol=F, fluxscale=F, fluxscalealt=F, pName=F, sName=F, sid=F, append=F){
    wider its
    cal := calibrater(its.msname)
    if(is_fail(cal)) fail

    cal.setdata(msselect=selectstr)
    cal.setapply(type='P', t=10.0)
    cal.setapply(type='B', table='tabB')
    cal.setapply(type='D', table='tabD')
    cal.setsolve(type='G', t=60.0, table='tabG', refant=3, append=append)
    ok := cal.solve()
    if(is_fail(ok)) fail

    if(linpol){
      ok := cal.linpolcor(tablein='tabG', fields=sName)
      if(is_fail(ok)) fail
    }

    if(fluxscale){
      print pName, sName
      ok := cal.fluxscale(tablein='tabG', reference=its.pName, transfer=sName)
      if(is_fail(ok)) fail
    }

    if(fluxscalealt){
      print its.pid, sid
      ok := cal.fluxscale(tablein='tabG', reference=its.pid, transfer=sid)
      if(is_fail(ok)) fail
    }

    cal.done()          
  }


  const its.correctCalibrators := function(calids){
    wider its
    cal := calibrater(its.msname)
    if(is_fail(cal)) fail

    select_str := spaste('FIELD_ID in ', as_evalstr(calids), ' && DATA_DESC_ID==', its.ddescid)
    print select_str
    ok := cal.setdata(msselect=select_str)
    if(is_fail(ok)) fail

    cal.setapply(type='P', t=10.0)
    cal.setapply(type='G', table='tabG')
    cal.setapply(type='D', table='tabD')
    cal.setapply(type='B', table='tabB')
    ok := cal.correct()
    if(is_fail(ok)) fail
    cal.done()
    return T
  }

  const its.correctTarget := function(selectstr){
    wider its
    cal := calibrater(its.msname)
    if(is_fail(cal)) fail

    cal.setdata(msselect=selectstr)
    cal.setapply(type='P', t=10.0)

    cal.setapply(type='G', table='tabG')
    cal.setapply(type='D', table='tabD')
    cal.setapply(type='B', table='tabB')
    ok := cal.correct()
    if(is_fail(ok)) fail
    cal.done()
    return T
  }

  const its.correctTargetCalave := function(spwid, targetid, calids){
    wider its
    cal := calibrater(its.msname)
    if(is_fail(cal)) fail

    selectstr := spaste('FIELD_ID==', targetid, ' && DATA_DESC_ID==', its.ddescid)
    cal.setdata(msselect=selectstr)
    cal.setapply(type='P', t=10.0)

    # average G solutions in time and apply
    ok := cal.calave(tablein='tabG', tableout='tabGsmooth', fldsin=calids, 
                     fldsout=calids, spwsin=spwid, spwout=spwid, t=300.0, 
                     mode='RI', verbose=F, append=F)
    if(is_fail(ok)) fail

    select_str := spaste('FIELD_ID in ', as_evalstr(calids)) 
    cal.setapply(type='G', table='tabGsmooth', select=select_str)
    cal.setapply(type='D', table='tabD')
    cal.setapply(type='B', table='tabB')
    ok := cal.correct()
    if(is_fail(ok)) fail
    cal.done()
    return T
  }

  const self.done := function(){
    dos.remove('tabD', mustexist=F)
    dos.remove('tabB', mustexist=F)
    dos.remove('tabG', mustexist=F)
    dos.remove('tabGsmooth', mustexist=F)
  }

  const self.create_selectstr := function(fieldid, time1=F, time2=F){
    wider its
    d := its.ddescid
    if(time1 && time2){
      t1 := dq.convert(dq.quantity(time1)).value
      t2 := dq.convert(dq.quantity(time2)).value
      return spaste('FIELD_ID==', fieldid, ' && DATA_DESC_ID==', d, ' && TIME>', t1, ' && TIME<', t2)
    }
    else if(time1){
      t1 := dq.convert(dq.quantity(time1)).value
      return spaste('FIELD_ID==', fieldid, ' && DATA_DESC_ID==', d, ' && TIME>', t1)
    }
    else if(time2){
      t2 := dq.convert(dq.quantity(time2)).value
      return spaste('FIELD_ID==', fieldid, ' && DATA_DESC_ID==', d, ' && TIME<', t2)
    }
    else
      return spaste('FIELD_ID==', fieldid, ' && DATA_DESC_ID==', d)
  }


  const self.primaryCalibrationTest := function(mirleak, mirgain, testname, spwid, selectstr){
    stime := time()

    while(T){
      pass := its.solveforPrimary(spwid, selectstr)
      if(!pass){
        print spaste('## ', testname, '............. fail (operation)')
        break
      }
  
      pass := compare_leakages('tabD', mirleak)
      if(!pass){
        print spaste('## ', testname, '............. fail (leakages)')
        break
      }

      pass := compare_gains('tabG', mirgain)
      if(!pass){
        print spaste('## ', testname, '............. fail (gains)') 
        break
      }
      else{
        print spaste('## ', testname, '............. pass')
        break
      }
    }      

    print "## --------------------------------------------"
    print "##   The pass criteria of this test are:"
    print "##   - that the amplitude of the polarization leakages"
    print "##     are within 0.002 of the Miriad values"
    print "##   - that the amplitude of the polarization leakages"
    print "##     are less than 0.05 in absolute terms" 
    print "##   - that the average absolute difference in the"
    print "##     gains are less than 0.2"

    its.printTime(stime)
  }

  const self.primaryCalibMultisolveTest := function(mirleak, mirgain, testname, selectstr){
    stime := time()

    while(T){
      pass := its.solveforPrimary(spwid, selectstr)
      if(!pass){
        print spaste('## ', testname, '.. fail (operation)')
        break
      }
  
      pass := compare_leakages('tabD', mirleak)
      if(!pass){
        print spaste('## ', testname, '.. fail (leakages)')
        break
      }

      pass := compare_gains('tabG', mirgain)
      if(!pass){
        print spaste('## ', testname, '.. fail (gains)') 
        break
      }
      else{
        print spaste('## ', testname, '.. pass')
        break
      }
    }      

    print "## --------------------------------------------"
    print "##   The pass criteria of this test are:"
    print "##   - that the amplitude of the polarization leakages"
    print "##     are within 0.002 of the Miriad values"
    print "##   - that the amplitude of the polarization leakages"
    print "##     are less than 0.05 in absolute terms" 
    print "##   - that the average absolute difference in the"
    print "##     gains are less than 0.2"

    its.printTime(stime)
  }

  const self.secondaryCalibTest := function(testname, sid, spwid, pselect){
    stime := time()

    while(T){
      pass := its.solveforPrimary(spwid, pselect)
      print pass
      if(!pass){
        print spaste('## ', testname, '........... fail (primary)')
        break
      }
      s := self.create_selectstr(sid)
      pass := its.solveforSecondary(s)
      if(!pass){
        print spaste('## ', testname, '........... fail (operation)')
        break
      }
      else{
        print spaste('## ', testname, '........... pass')
        break
      }
    }

    print "## --------------------------------------------"
    print "##   The pass criterion of this test is that"
    print "##   - secondary calibration runs"

    its.printTime(stime)
  }

  const self.secondaryCalibLinpolTest := function(testname, sid, spwid, sName){
    wider its
    stime := time()

    while(T){
      s := self.create_selectstr(its.pid)
      pass := its.solveforPrimary(spwid, s)
      print pass
      if(!pass){
        print spaste('## ', testname, '........... fail (primary)')
        break
      }
      s := self.create_selectstr(sid)
      pass := its.solveforSecondary(s, linpol=T, sName=sName)
      if(!pass){
        print spaste('## ', testname, '........... fail (operation)')
        break
      }
      else{
        print spaste('## ', testname, '........... pass')
        break
      }
    }

    print "## --------------------------------------------"
    print "##   The pass criterion of this test is that"
    print "##   - secondary calibration runs, using linpolcor"

    its.printTime(stime)
  }

  const self.secondaryCalibFluxscaleTest := function(testname, sid, spwid, pName, sName){
    wider its
    stime := time()

    while(T){
      s := self.create_selectstr(its.pid)
      pass := its.solveforPrimary(spwid, s)
      print pass
      if(!pass){
        print spaste('## ', testname, '........... fail (primary)')
        break
      }
      s := self.create_selectstr(sid)
      pass := its.solveforSecondary(s, fluxscale=T, pName=pName, sName=sName, append=T)
      if(!pass){
        print spaste('## ', testname, '........... fail (operation)')
        break
      }
      else{
        print spaste('## ', testname, '........... pass')
        break
      }
    }

    print "## --------------------------------------------"
    print "##   The pass criterion of this test is that"
    print "##   - secondary calibration runs, using fluxscale"

    its.printTime(stime)
  }

  const self.secondaryCalibFluxscaleAltTest := function(testname, sid, spwid, pName, sName){
    wider its
    stime := time()

    while(T){
      s := self.create_selectstr(its.pid)
      pass := its.solveforPrimary(spwid, s)
      print pass
      if(!pass){
        print spaste('## ', testname, '. fail (primary)')
        break
      }
      s := self.create_selectstr(sid)
      pass := its.solveforSecondary(s, fluxscalealt=T, pName=pName, sName=sName, sid=sid, append=T)
      if(!pass){
        print spaste('## ', testname, '. fail (operation)')
        break
      }
      else{
        print spaste('## ', testname, '. pass')
        break
      }
    }

    print "## --------------------------------------------"
    print "##   The pass criterion of this test is that"
    print "##   - secondary calibration runs, using fluxscale"
    print "##     with multiple sIDs (using IDs not Names)"

    its.printTime(stime)
  }


  const self.targetCalibTest := function(testname, sid, targetid, spwid){
    wider its
    stime := time()

    calids := [sid, its.pid]

    while(T){
      s := self.create_selectstr(its.pid)
      pass1 := its.solveforPrimary(spwid, s)
      s := self.create_selectstr(sid)
      pass2 := its.solveforSecondary(s)
      if(!pass1 || !pass2){
        print spaste('## ', testname, '.............. fail (P or S calibration)')
        break
      }

      pass := its.correctCalibrators(calids)
      if(!pass){
        print spaste('## ', testname, '.............. fail (correctCalibrators)')
        break
      } 

      s := self.create_selectstr(targetid)
      pass := its.correctTarget(s)
      if(!pass){
        print spaste('## ', testname, '.............. fail (correctTarget)')
        break
      }
      else{
        print spaste('## ', testname, '.............. pass')
        break
      }
    }

    print "## --------------------------------------------"
    print "##   The pass criterion of this test is that"
    print "##   - the full calibration process runs"

    its.printTime(stime)
  }

  const self.targetCalibCalaveTest := function(testname, sid, targetid, spwid){
    stime := time()

    calids := [sid, its.pid]
    s := self.create_selectstr(its.pid)
    pass1 := its.solveforPrimary(spwid, s)
    s := self.create_selectstr(sid)
    pass2 := its.solveforSecondary(s)
    pass3 := its.correctCalibrators(calids)

    s := self.create_selectstr(targetid)
    pass4 := its.correctTargetCalave(spwid, targetid, calids)

    if(pass1 && pass2 && pass3 && pass4)
      print spaste('## ', testname, '..... pass')
    else if(pass1 && pass2 && pass3)
      print spaste('## ', testname, '..... fail (calave)')
    else if(pass1 && pass2)
      print spaste('## ', testname, '..... fail (correctCals)')
    else 


    print "## --------------------------------------------"
    print "##   The pass criterion of this test is that"
    print "##   - the full calibration process runs, with calave"

    its.printTime(stime)
  }

  self.testfunction := function(mirleak, mirgain, testname, spwid, selectstr){
    stime := time()

    while(T){
      pass1 := its.solveforPrimary(spwid, selectstr)
      pass2 := its.correctCalibrators([its.pid])
      if(!pass1 || !pass2){
        print spaste('## ', testname, '............. fail (operation)')
        break
      }
  
      pass := compare_leakages('tabD', mirleak)
      if(!pass){
        print spaste('## ', testname, '............. fail (leakages)')
        break
      }

      pass := compare_gains('tabG', mirgain)
      if(!pass){
        print spaste('## ', testname, '............. fail (gains)') 
        break
      }
      else{
        print spaste('## ', testname, '............. pass')
        break
      }
    }      

    print "## --------------------------------------------"
    print "##   The pass criteria of this test are:"
    print "##   - that the amplitude of the polarization leakages"
    print "##     are within 0.002 of the Miriad values"
    print "##   - that the amplitude of the polarization leakages"
    print "##     are less than 0.05 in absolute terms" 
    print "##   - that the average absolute difference in the"
    print "##     gains are less than 0.2"

    its.printTime(stime)
  }

}

const test1 := function(){
  msname := 'testdata/C972.ms'
  mirleak := 'testdata/C972.1384.prim.leak.amp.atnf'
  mirgain := 'testdata/C972.1384.prim.gain.amp.atnf'
  testname := 'ATCA primary calibration (1.384 GHz)'
  ddescid := 0
  spwid := 1
  pid := 1
  time1 := '26august2001/12:15:00'
  time2 := '26august2001/13:00:00'

  a := atcaCalibrationTests(msname, ddescid)
  s := a.create_selectstr(pid, time1, time2)
  a.testfunction(mirleak, mirgain, testname, spwid, s)
#  a.done()
}

const primaryCalib1384 := function(){
  msname := 'testdata/C972.ms'
  mirleak := 'testdata/C972.1384.prim.leak.amp.atnf'
  mirgain := 'testdata/C972.1384.prim.gain.amp.atnf'
  testname := 'ATCA primary calibration (1.384 GHz)'
  ddescid := 0
  spwid := 1
  pid := 1
  time1 := '26august2001/12:15:00'
  time2 := '26august2001/13:00:00'

  a := atcaCalibrationTests(msname, ddescid)
  s := a.create_selectstr(pid, time1, time2)
  a.primaryCalibrationTest(mirleak, mirgain, testname, spwid, s)
  a.done()
}

const primaryCalib2496 := function(){
  msname := 'testdata/C972.ms'
  mirleak := 'testdata/C972.2496.prim.leak.amp.atnf'
  mirgain := 'testdata/C972.2496.prim.gain.amp.atnf'
  testname := 'ATCA primary calibration (2.496 GHz)'
  ddescid := 1
  spwid := 2
  pid := 1
  time1 := '26august2001/12:15:00'
  time2 := '26august2001/13:00:00'

  a := atcaCalibrationTests(msname, ddescid)
  s := a.create_selectstr(pid, time1, time2)
  a.primaryCalibrationTest(mirleak, mirgain, testname, spwid, s)
  a.done()
}

const primaryCalib4800 := function(){
  msname := 'testdata/C1026.ms'
  mirleak := 'testdata/C1026.4800.prim.leak.amp.atnf'
  mirgain := 'testdata/C1026.4800.prim.gain.amp.atnf'
  testname := 'ATCA primary calibration (4.800 GHz)'
  ddescid := 0
  spwid := 1
  pid := 1

  a := atcaCalibrationTests(msname, ddescid)
  s := a.create_selectstr(pid)
  a.primaryCalibrationTest(mirleak, mirgain, testname, spwid, s)
  a.done()
}

const primaryCalib8640 := function(){
  msname := 'testdata/C1026.ms'
  mirleak := 'testdata/C1026.8640.prim.leak.amp.atnf'
  mirgain := 'testdata/C1026.8640.prim.gain.amp.atnf'
  testname := 'ATCA primary calibration (8.640 GHz)'
  ddescid := 1
  spwid := 2
  pid := 1

  a := atcaCalibrationTests(msname, ddescid)
  s := a.create_selectstr(pid)
  a.primaryCalibrationTest(mirleak, mirgain, testname, spwid, s)
  a.done()
}

const primaryCalib1384multi := function(){
  msname := 'testdata/C972.ms'
  mirleak := 'testdata/C972.1384.prim.leak.amp.atnf'
  mirgain := 'testdata/C972.1384.prim.gain.amp.atnf'
  testname := 'ATCA primary calibration multisolve (1.384 GHz)'
  ddescid := 0
  pid := 1
  time1 := '26august2001/12:15:00'
  time2 := '26august2001/13:00:00'

  a := atcaCalibrationTests(msname, ddescid)
  s := a.create_selectstr(pid, time1, time2)
  a.primaryCalibMultisolveTest(mirleak, mirgain, testname, s)
  a.done()
}

const primaryCalib2496multi := function(){
  msname := 'testdata/C972.ms'
  mirleak := 'testdata/C972.2496.prim.leak.amp.atnf'
  mirgain := 'testdata/C972.2496.prim.gain.amp.atnf'
  testname := 'ATCA primary calibration multisolve (2.496 GHz)'
  ddescid := 1
  pid := 1
  time1 := '26august2001/12:15:00'
  time2 := '26august2001/13:00:00'

  a := atcaCalibrationTests(msname, ddescid)
  s := a.create_selectstr(pid, time1, time2)
  a.primaryCalibMultisolveTest(mirleak, mirgain, testname, s)
  a.done()
}

const primaryCalib4800multi := function(){
  msname := 'testdata/C1026.ms'
  mirleak := 'testdata/C1026.4800.prim.leak.amp.atnf'
  mirgain := 'testdata/C1026.4800.prim.gain.amp.atnf'
  testname := 'ATCA primary calibration multisolve (4.800 GHz)'
  ddescid := 0
  pid := 1

  a := atcaCalibrationTests(msname, ddescid)
  s := a.create_selectstr(pid)
  a.primaryCalibMultisolveTest(mirleak, mirgain, testname, s)
  a.done()
}

const primaryCalib8640multi := function(){
  msname := 'testdata/C1026.ms'
  mirleak := 'testdata/C1026.8640.prim.leak.amp.atnf'
  mirgain := 'testdata/C1026.8640.prim.gain.amp.atnf'
  testname := 'ATCA primary calibration multisolve (8.640 GHz)'
  ddescid := 1
  pid := 1

  a := atcaCalibrationTests(msname, ddescid)
  s := a.create_selectstr(pid)
  a.primaryCalibMultisolveTest(mirleak, mirgain, testname, s)
  a.done()
}

const secondaryCalib1384 := function(){
  msname := 'testdata/C972.ms'
  testname := 'ATCA secondary calibration (1.384 GHz)'
  ddescid := 0
  spwid := 1
  pid := 1
  sid := 3
  time1 := '26august2001/12:15:00'
  time2 := '26august2001/13:00:00'

  a := atcaCalibrationTests(msname, ddescid)
  s := a.create_selectstr(pid, time1, time2)
  a.secondaryCalibTest(testname, sid, spwid, s)
  a.done()
}

const secondaryCalib2496 := function(){
  msname := 'testdata/C972.ms'
  testname := 'ATCA secondary calibration (2.496 GHz)'
  ddescid := 1
  spwid := 2
  pid := 1
  sid := 3
  time1 := '26august2001/12:15:00'
  time2 := '26august2001/13:00:00'

  a := atcaCalibrationTests(msname, ddescid)
  s := a.create_selectstr(pid, time1, time2)
  a.secondaryCalibTest(testname, sid, spwid, s)
  a.done()
}

const secondaryCalib4800 := function(){
  msname := 'testdata/C1026.ms'
  testname := 'ATCA secondary calibration (4.800 GHz)'
  ddescid := 0
  spwid := 1
  pid := 1
  sid := 2

  a := atcaCalibrationTests(msname, ddescid)
  s := a.create_selectstr(pid)
  a.secondaryCalibTest(testname, sid, spwid, s)
  a.done()
}

const secondaryCalib8640 := function(){
  msname := 'testdata/C1026.ms'
  testname := 'ATCA secondary calibration (8.640 GHz)'
  ddescid := 1
  spwid := 2
  pid := 1
  sid := 2

  a := atcaCalibrationTests(msname, ddescid)
  s := a.create_selectstr(pid)
  a.secondaryCalibTest(testname, sid, spwid, s)
  a.done()
}

const secondaryCalib1384flux := function(){
  msname := 'testdata/C972.ms'
  testname := 'ATCA secondary + fluxscale (1.384 GHz)'
  ddescid := 0
  spwid := 1
  sid := 3
  pName := '1934-638'
  sName := '0332-403'

  a := atcaCalibrationTests(msname, ddescid)
  a.secondaryCalibFluxscaleTest(testname, sid, spwid, pName, sName)
  a.done()
}

const secondaryCalib1384fluxalt := function(){
  msname := 'testdata/C972.ms'
  testname := 'ATCA secondary + fluxscale using IDs (1.384 GHz)'
  ddescid := 0
  spwid := 1
  sid := 3
  pName := '1934-638'
  sName := '0332-403'

  a := atcaCalibrationTests(msname, ddescid)
  a.secondaryCalibFluxscaleAltTest(testname, sid, spwid, pName, sName)
  a.done()
}

const secondaryCalib2496linpol := function(){
  msname := 'testdata/C972.ms'
  testname := 'ATCA secondary + linpolcor (2.496 GHz)'
  ddescid := 1
  spwid := 2
  sid := 3
  pName := '1934-638'
  sName := '0332-403'

  a := atcaCalibrationTests(msname, ddescid)
  a.secondaryCalibLinpolTest(testname, sid, spwid, sName)
  a.done()
}

const secondaryCalib4800flux := function(){
  msname := 'testdata/C1026.ms'
  testname := 'ATCA secondary + fluxscale (4.800 GHz)'
  ddescid := 0
  spwid := 1
  sid := 2
  pName := '1934-638'
  sName := '1718-649'

  a := atcaCalibrationTests(msname, ddescid)
  a.secondaryCalibFluxscaleTest(testname, sid, spwid, pName, sName)
  a.done()
}

const secondaryCalib8640linpol := function(){
  msname := 'testdata/C1026.ms'
  testname := 'ATCA secondary + linpolcor (8.640 GHz)'
  ddescid := 1
  spwid := 2
  sid := 2
  pName := '1934-638'
  sName := '1718-649'

  a := atcaCalibrationTests(msname, ddescid)
  a.secondaryCalibLinpolTest(testname, sid, spwid, sName)
  a.done()
}

const targetCalib1384 := function(){
  msname := 'testdata/C972.ms'
  testname := 'ATCA target calibration (1.384 GHz)'
  ddescid := 0
  spwid := 1
  sid := 3
  tid := 2

  a := atcaCalibrationTests(msname, ddescid)
  a.targetCalibTest(testname, sid, tid, spwid)
  a.done()
}

const targetCalib2496 := function(){
  msname := 'testdata/C972.ms'
  testname := 'ATCA target calibration (2.496 GHz)'
  ddescid := 1
  spwid := 2
  sid := 3
  tid := 2

  a := atcaCalibrationTests(msname, ddescid)
  a.targetCalibTest(testname, sid, tid, spwid)
  a.done()
}

const targetCalib4800 := function(){
  msname := 'testdata/C1026.ms'
  testname := 'ATCA target calibration (4.800 GHz)'
  ddescid := 0
  spwid := 1
  sid := 2
  tid := 3

  a := atcaCalibrationTests(msname, ddescid)
  a.targetCalibTest(testname, sid, tid, spwid)
  a.done()
}

const targetCalib8640 := function(){
  msname := 'testdata/C1026.ms'
  testname := 'ATCA target calibration (8.640 GHz)'
  ddescid := 1
  spwid := 2
  sid := 2
  tid := 3

  a := atcaCalibrationTests(msname, ddescid)
  a.targetCalibTest(testname, sid, tid, spwid)
  a.done()
}

const targetCalib1384calave := function(){
  msname := 'testdata/C972.ms'
  testname := 'ATCA target calibration (calave) (1.384 GHz)'
  ddescid := 0
  spwid := 1
  sid := 3
  tid := 2

  a := atcaCalibrationTests(msname, ddescid)
  a.targetCalibCalaveTest(testname, sid, tid, spwid)
  a.done()
}

const targetCalib2496calave := function(){
  msname := 'testdata/C972.ms'
  testname := 'ATCA target calibration (calave) (2.496 GHz)'
  ddescid := 1
  spwid := 2
  sid := 3
  tid := 2

  a := atcaCalibrationTests(msname, ddescid)
  a.targetCalibCalaveTest(testname, sid, tid, spwid)
  a.done()
}

const targetCalib4800calave := function(){
  msname := 'testdata/C1026.ms'
  testname := 'ATCA target calibration (calave) (4.800 GHz)'
  ddescid := 0
  spwid := 1
  sid := 2
  tid := 3

  a := atcaCalibrationTests(msname, ddescid)
  a.targetCalibCalaveTest(testname, sid, tid, spwid)
  a.done()
}

const targetCalib8640calave := function(){
  msname := 'testdata/C1026.ms'
  testname := 'ATCA target calibration (calave) (8.640 GHz)'
  ddescid := 1
  spwid := 2
  sid := 2
  tid := 3

  a := atcaCalibrationTests(msname, ddescid)
  a.targetCalibCalaveTest(testname, sid, tid, spwid)
  a.done()
}



