#-----------------------------------------------------------------------------
# atcaCalib.g: Calibration class for the ATCA pipeline
#-----------------------------------------------------------------------------
# Copyright (C) 1996-2004
# Associated Universities, Inc. Washington DC, USA.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id:
#-----------------------------------------------------------------------------
#

pragma include once

include 'calibrater.g'
include 'imager.g'
include 'atcapl.g'
include 'configCalib.g'

atcacalibrater := subsequence(config){

# Private variables and functions

  its := [=]
  its.cal := [=]     # AIPS++ calibrater tool

  const its.make_calibrater := function(config){
    wider its
    its.cal := calibrater(config.get_msname())
    if(is_fail(its.cal)) return fatal(PARMERR, 'Error creating calibrator', its.cal::)

    fprintf(config.get_pidfile(), '%d calibrater\n', its.cal.id().pid)
    return T
  }

  const its.getpids := function(config){
    # get the process IDs of all the default servers started
    servers := ['drc', 'dq', 'dm']
    for(s in servers){
      if(is_record(eval(s))){
        pid := eval(s).id().pid
        fprintf(config.get_pidfile(), '%d %s\n', pid, s)
      }
    }
    return T
  }

  const its.setJy := function(config, ddescid){
    logic := config.get_logicvars()
    c := config.get_vars()

    ddesc := c.ddesc[spaste(ddescid)]
    pID := ddesc.pID.val
    sIDs := ddesc.sIDs.val

    imgr := imager(config.get_msname())
    if(is_fail(imgr)) return fatal(PARMERR, 'Error initialising imager for setJy', imgr::)

    if(logic.setjy1[ddescid] == T){
      note('Running setJy for primary calibrator')
      ok := imgr.setjy(fieldid=pID, spwid=ddescid)
      if(is_fail(ok)) return fatal(PARMERR, 'Error in setJy for primary calibrator', ok::)

      for(i in sIDs){
        note(spaste('Running setJy for secondary calibrator ', i))
        ok := imgr.setjy(fieldid=i, spwid=ddescid)
        if(is_fail(ok)) 
          return fatal(PARMERR, 'Error in setJy for secondary calibrators', ok::)
      }
    }
    else if(logic.setjy2[ddescid] == T){
      note('Running setJy for primary calibrator')
      note('Setting flux density explicitly for source')
      imgr.setjy(fieldid=pID, spwid=ddescid, fluxdensity=ddesc.fluxdensity.val) 
      if(is_fail(ok)) return fatal(PARMERR, 'Error in setJy for primary calibrator', ok::)
    }
    else
      return fatal(PARMERR, 'Error: no values for logic.setjy set')

    ok := imgr.done()
    if(is_fail(ok)) return fatal(PARMERR, 'Error closing imager tool', ok::)
    return T
  }

  const its.solve_for_primary := function(config, ddescid){
    logic := config.get_logicvars()
    c := config.get_vars()
    note('Solving for primary calibrator')
    ddesc := c.ddesc[spaste(ddescid)]
    select_str := spaste('FIELD_ID in ', as_evalstr(ddesc.pID.val), 
                         ' && DATA_DESC_ID in ', as_evalstr(ddescid-1), 
                         ' && ANTENNA2 in ', as_evalstr(c.antennas.val))

    ok := its.cal.setdata(msselect=select_str)
    if(is_fail(ok))
      return fatal(PARMERR, 'Error running setdata in solveforprimary', ok::)

    if(logic.pG[ddescid] == T){
      its.cal.reset()

      ok := its.cal.setapply(type='P', t=c.intervalP.val)
      if(is_fail(ok)) 
        return fatal(PARMERR, 'Error running setapply in solveforprimary', ok::)

      ok := its.cal.setsolve(type='G', t=c.intervalG.val, 
                             table=c.tables.G.val[ddescid], refant=c.refant.val)
      if(is_fail(ok))
        return fatal(PARMERR, 'Error running setsolve in solveforprimary', ok::)

      ok := its.cal.solve()
      if(is_fail(ok))
        return fatal(PARMERR, 'Error solving for primary calibrator', ok::)
    }

    if(logic.pB[ddescid] == T){
      its.cal.reset()

      ok := its.cal.setapply(type='P', t=c.intervalP.val)
      if(is_fail(ok)) 
        return fatal(PARMERR, 'Error running setapply in solveforprimary', ok::)

      if(logic.pG[ddescid] == T){
        ok := its.cal.setapply(type='G', table=c.tables.G.val[ddescid])
        if(is_fail(ok))
          return fatal(PARMERR, 'Error running setapply in solveforprimary', ok::)
      }

      ok := its.cal.setsolve(type='B', t=c.intervalB.val, 
                             table=c.tables.B.val[ddescid], refant=c.refant.val)
      if(is_fail(ok))
        return fatal(PARMERR, 'Error running setsolve in solveforprimary', ok::)

      ok := its.cal.solve()
      if(is_fail(ok)) return fatal(PARMERR, 'Error solving for primary calibrator', ok::)
    }

    if(logic.pD[ddescid] == T){
      its.cal.reset()

      ok := its.cal.setapply(type='P', t=c.intervalP.val)
      if(is_fail(ok))
        return fatal(PARMERR, 'Error running setapply in solveforprimary', ok::)

      if(logic.pG[ddescid] == T){
        ok := its.cal.setapply(type='G', table=c.tables.G.val[ddescid])
        if(is_fail(ok))
          return fatal(PARMERR, 'Error running setapply in solveforprimary', ok::)
      }

      if(logic.pB[ddescid] == T){
        ok := its.cal.setapply(type='B', table=c.tables.B.val[ddescid])
        if(is_fail(ok))
          return fatal(PARMERR, 'Error running setapply in solveforprimary', ok::)
      }
      ok := its.cal.setsolve(type='D', t=c.intervalD.val, 
                             table=c.tables.D.val[ddescid], refant=c.refant.val)
      if(is_fail(ok))
        return fatal(PARMERR, 'Error running setsolve in solveforprimary', ok::)

      ok := its.cal.solve()
      if(is_fail(ok))
        return fatal(PARMERR, 'Error solving for Primary calibrator', ok::)
    }

    if(logic.pG[ddescid] == F && logic.pD[ddescid] == F && logic.pB[ddescid] == F)
      return fatal(PARMERR, 'Error logic.primary not set - get_logic not run')

    return T
  }

  const its.filter_secondaries := function(pID, sIDs){
    # remove primary source from list of secondaries
    # as it doesn't need to be fluxscaled

    newIDs := []
    for(s in sIDs){
      if(pID == s)
        continue
      newIDs[len(newIDs)+1] := s
    }
    return newIDs
  }

  const its.solve_for_secondaries := function(config, ddescid){
    logic := config.get_logicvars()
    c := config.get_vars()

    ddesc := c.ddesc[spaste(ddescid)]
    pName := ddesc.pName.val
    sNames := ddesc.sNames.val
    pID := ddesc.pID.val
    sIDs := its.filter_secondaries(pID, ddesc.sIDs.val)

    note('Solving for secondary calibrators')

    select_str := spaste('FIELD_ID in ', as_evalstr(sIDs), 
                         ' && DATA_DESC_ID in ', as_evalstr(ddescid-1),
                         ' && ANTENNA2 in ', as_evalstr(c.antennas.val))
    ok := its.cal.setdata(msselect=select_str)
    if(is_fail(ok))
      return fatal(PARMERR, 'Error running setdata in solve_for_secondaries', ok::)

    its.cal.reset()

    ok := its.cal.setapply(type='P', t=c.intervalP.val)
    if(is_fail(ok)) 
      return fatal(PARMERR, 'Error running setapply in solve_for_secondaries', ok::)

    if(logic.pB[ddescid] == T){
      ok := its.cal.setapply(type='B', table=c.tables.B.val[ddescid])
      if(is_fail(ok))
        return fatal(PARMERR, 'Error running setapply in solve_for_secondaries', ok::)
    }

    if(logic.sG[ddescid] == T){
      if(logic.pD[ddescid]){
        ok := its.cal.setapply(type='D', table=c.tables.D.val[ddescid])
        if(is_fail(ok))
          return fatal(PARMERR, 'Error running setapply in solve_for_secondaries', ok::)
      }
      if(logic.pG[ddescid]){
        ok := its.cal.setsolve(type='G', t=c.intervalG.val, append=T,
                               table=c.tables.G.val[ddescid], refant=c.refant.val)
        if(is_fail(ok))
          return fatal(PARMERR, 'Error running setsolve in solve_for_secondaries', ok::)

        ok := its.cal.solve()
        if(is_fail(ok))
          return fatal(PARMERR, 'Error solving for Secondary calibrators', ok::)
      }
    }
    else if(logic.sGD[ddescid] == T){
      ok := its.cal.setsolve(type='G', t=c.intervalG.val, table=c.tables.G.val[ddescid],
                               append=T, refant=c.refant.val)
      if(is_fail(ok))
        return fatal(PARMERR, 'Error running setsolve in solve_for_secondaries', ok::)
 
      ok := its.cal.setsolve(type='D', t=c.intervalD.val, 
                         table=c.tables.D.val[ddescid])
      if(is_fail(ok))
        return fatal(PARMERR, 'Error running setsolve in solve_for_secondaries', ok::)

      ok := its.cal.solve()
      if(is_fail(ok))
        return fatal(PARMERR, 'Error solving for Secondary calibrators', ok::)
    }
    else
      return fatal(PARMERR, 'Error: logic.secondary not set')

    # Correct gains for polarization of the calibrators
    if(logic.linpol == T){
      ok := its.cal.linpolcor(tablein=c.tables.G.val[ddescid], fields=sNames)
      if(is_fail(ok))
        return fatal(PARMERR, 'Error correcting gains for polarization', ok::)
    }

    # Establish the flux density scale
    if(logic.fluxscale[ddescid] == T){
      ok := its.cal.fluxscale(tablein=c.tables.G.val[ddescid], reference=pID,
                              transfer=sIDs)
      if(is_fail(ok)) return fatal(PARMERR, 'Error setting flux density scale', ok::)
    }
    return T
  }

  const its.correct_cals := function(config, ddescid){
    # Apply calibration to all calibraters (no averaging)
    note('Correcting calibrators')
    c := config.get_vars()

    calids := c.ddesc[spaste(ddescid)].calIDs.val
    its.cal.reset()

    select_str := spaste('FIELD_ID in ', as_evalstr(calids), 
                         ' && DATA_DESC_ID in ', as_evalstr(ddescid-1),
                         ' && ANTENNA2 in ', as_evalstr(c.antennas.val))

    ok := its.cal.setdata(msselect=select_str)
    if(is_fail(ok)) return fatal(PARMERR, 'Error running setdata in correct_cals', ok::)

    ok := its.cal.setapply(type='P', t=c.intervalP.val)
    if(is_fail(ok)) return fatal(PARMERR, 'Error running setapply in correct_cals', ok::)

    ok := its.cal.setapply(type='G', table=c.tables.G.val[ddescid])
    if(is_fail(ok)) return fatal(PARMERR, 'Error running setapply in correct_cals', ok::)

    ok := its.cal.setapply(type='D', table=c.tables.D.val[ddescid])
    if(is_fail(ok)) return fatal(PARMERR, 'Error running setapply in correct_cals', ok::)

    ok := its.cal.setapply(type='B', table=c.tables.B.val[ddescid])
    if(is_fail(ok)) return fatal(PARMERR, 'Error running setapply in correct_cals', ok::)

    ok := its.cal.correct()
    if(is_fail(ok)) return fatal(PARMERR, 'Error correcting calibrators', ok::)
    return T
  }


  const its.correct_source := function(config, ddescid, targetid){
    # Apply calibration to a target source (with averaging)
    c := config.get_vars()
    its.cal.reset()

    ddesc := c.ddesc[spaste(ddescid)]
    calids := ddesc.calsForTargetIDs.val[spaste(targetid)]
    select_str := spaste('FIELD_ID in ', as_evalstr(targetid), 
                         ' && DATA_DESC_ID in ', as_evalstr(ddescid-1),
                         ' && ANTENNA2 in ', as_evalstr(c.antennas.val))

    ok := its.cal.setdata(msselect=select_str)
    if(is_fail(ok))
      return fatal(PARMERR, 'Error running setdata in correct_source', ok::)

    ok := its.cal.setapply(type='P', t=c.intervalP.val)
    if(is_fail(ok))
      return fatal(PARMERR, 'Error running setapply in correct_source', ok::)

    # average G solutions in time and apply
#XX This should be put back in once bug has been fixed.
#XX    tG := spaste(c.tables.G.val[ddescid], '-smooth')
#XX    ok := dos.remove(tG, mustexist=F)
#XX    if(is_fail(ok)) return fatal(PARMERR, 'Error deleting calibration tables', ok::)

#XX    ok := its.cal.calave(tablein=c.tables.G.val[ddescid], tableout=tG, fldsin=calids,
#XX                     fldsout=calids, spwsin=ddescid, spwout=ddescid, 
#XX                     t=c.average.val, mode=c.avmode.val, verbose=F, append=F)
#XX    if(is_fail(ok))
#XX      return fatal(PARMERR, 'Error running calave in correct_source', ok::)

#XX    select_str := spaste('FIELD_ID in ', as_evalstr(calids)) 
#XX    ok := its.cal.setapply(type='G', table=tG, select=select_str)
#XX    if(is_fail(ok))
#XX      return fatal(PARMERR, 'Error running setapply in correct_source', ok::)

    ok := its.cal.setapply(type='G', table=c.tables.G.val[ddescid])
    if(is_fail(ok))
      return fatal(PARMERR, 'Error running setapply in correct_source', ok::)
    
    ok := its.cal.setapply(type='D', table=c.tables.D.val[ddescid])
    if(is_fail(ok))
      return fatal(PARMERR, 'Error running setapply in correct_source', ok::)

    ok := its.cal.setapply(type='B', table=c.tables.B.val[ddescid])
    if(is_fail(ok))
      return fatal(PARMERR, 'Error running setapply in correct_source', ok::)

    ok := its.cal.correct()
    if(is_fail(ok))
      return fatal(PARMERR, 'Error correcting sources', ok::)
    return T
  }

  const its.check_solutions_exist := function(config, ddescid){
    note('Checking solutions exist')
    c := config.get_vars()
    d := ddescid
    exist := F
    tables := [c.tables.G.val[d], c.tables.B.val[d], c.tables.D.val[d]]
    for(caltable in tables){
      t := table(caltable)
      if(is_table(t)){
        exist := T
        t.done()
      }
    }
    return exist
  }


# Public variables and function

  const self.calibrate := function(config){
    # Run calibration process

    c := config.get_vars()

    for(ddescid in c.ddesctoProcess.val){
      ddesc := c.ddesc[spaste(ddescid)]

## XXX modifying this to include spectral for testing purposes
##      if(ddesc.mode != CONTINUUM && ddesc.mode != SPECTRAL){
      if(ddesc.mode != CONTINUUM){
        print 'Cant calibrate non-continuum data, skipping Spectral Window ', ddescid
        continue
      }
      print 'Calibrating DDESC ', ddescid

      print 'Compute the model visibility for calibrators'
      ok := its.setJy(config, ddescid) 
      if(is_fail(ok)) return fatal(PARMERR, 'Error running setJy', ok::)

      printf('\nSolving for primary calibrator \n\n')
      ok := its.solve_for_primary(config, ddescid)
      if(is_fail(ok)) return fatal(PARMERR, 'Error solving for primary source', ok::)

      printf('\nSolving for secondary sources \n\n')
      ok := its.solve_for_secondaries(config, ddescid)
      if(is_fail(ok)) return fatal(PARMERR, 'Error solving for secondary sources', ok::)

      exist := its.check_solutions_exist(config, ddescid)
      if(is_fail(exist)) return fatal(PARMERR, 'Error checking for solutions', exist::)
      if(!exist){
        print 'No solutions exist for this Dataset, skipping correction'
        continue
      }

      print 'Correcting calibrators ', config.idstoNames(ddesc.calIDs.val)
      ok := its.correct_cals(config, ddescid)
      if(is_fail(ok)) return fatal(PARMERR, 'Error correcting calibrators', ok::)

      for(targetid in ddesc.targetIDs.val){
        print 'Correcting target source ', config.idtoName(targetid)
        ok := its.correct_source(config, ddescid, targetid)
        if(is_fail(ok)) return fatal(PARMERR, 'Error correcting target source', ok::)
      }
    }
    return T
  }

  const self.done := function(config){
    ok := its.getpids(config)
    if(is_fail(ok)) return fatal(PARMERR, 'Error getting server pids', ok::)

    ok := its.cal.done()
    if(is_fail(ok)) return fatal(PARMERR, 'Error closing calibrator object', ok::)
  }


# Constructor
  ok := its.make_calibrater(config)
  if(is_fail(ok)) return fatal(PARMERR, 'Error initialising calibrator', ok::)
}












