pragma include once

include 'misc.g'
include 'note.g'
include 'ms.g'
include 'serverexists.g'


atcacalibrater := subsequence (msname)
{
   if (!serverexists('dms', 'misc', dms)) {
      return throw('The misc server "dms" is either not running or not valid', 
                    origin='atcacalibrater.g');
   }


# Private

   its:=[=]
   its.as := [=];                  # ATCA Support tool
   its.cal := [=];                 # Calibrater tool
# 
   its.msname := msname;           # MeasurementSet name
   its.dir := '';                  # Directory for MS and new files
#
   its.primary := '';
   its.secondaries := "";
#
   its.tables := [=];              # Calibration Table names
   its.tables.G := [=];
   its.tables.B := [=];
   its.tables.D := [=];
#
   its.solved := [=]               # Which spwids did we solve for ?
#
   its.intervals := [=];           # Calibration intervals in seconds
   its.intervals.P := 10.0
   its.intervals.G := 10.0
   its.intervals.D := 1.0e8;
   its.intervals.B := 1.0e8;
   its.refant := -1
#
   its.what := [=];
   its.what.G := T;               # What will we solve for ?
   its.what.D := T;
   its.what.B := T;
#
   its.idrec := [=];               # Record holding field names and IDs


###
   const its.makeCalibraterTool := function ()
   {
      wider its;
#
      include 'calibrater.g'
      its.cal := calibrater (its.msname);
      if (is_fail(its.cal)) fail;
      return T;
   }


###
   const its.setJy := function (sources)
   {
      wider its;

# Avoid locking conflicts

      if (is_record(its.cal) && length(its.cal)>0) {
         ok := its.cal.done();
         its.cal := [=];
      }      

# Create Imager tool

      include 'imager.g'
      imgr := imager(filename=its.msname);
      if (is_fail(imgr)) fail;

# Initialize known sources  (probably should specify calibrators only)

      note ('Initializing MS');
#
      if (is_unset(sources)) {
         ok := imgr.setjy ();
         if (is_fail(ok)) fail;
      } else {
         t := dms.tovector (sources, 'string');
         if (is_fail(t)) fail;
         sID := its.as.findID (its.idrec, to_upper(t));
         if (is_fail(sID)) fail;
#
         for (i in sID) {
            ok := imgr.setjy (fieldid=i);
            if (is_fail(ok)) fail;
         }
      }
#
      ok := imgr.done();
      if (is_fail(ok)) fail;

# Remake calibrater tool

      return its.makeCalibraterTool();
   }


###
   const its.setTableNames := function ()
#
# Version handling looping over spwID
#
   {
      wider its;
#
      spwids := its.idrec.spwids;
#
      its.tables.G := [=];
      its.tables.B := [=];        
      its.tables.D := [=];
      for (i in spwids) {
        f := spaste(i);
        its.tables.G[f] := spaste(its.dir, '/calG-', f);
        its.tables.B[f] := spaste(its.dir, '/calB-', f);
        its.tables.D[f] := spaste(its.dir, '/calD-', f);
      }
#
      return T;
   }


### 
   const its.solveForPrimary := function (spwid, pid)
   {
      wider its;
#
      fspwid := spaste(spwid);
      tG := its.tables.G[fspwid];
      tB := its.tables.B[fspwid];
      tD:=  its.tables.D[fspwid];

# Select spwid and source

      msSelect := spaste('FIELD_ID in ', as_evalstr(pid), 
                         ' && SPECTRAL_WINDOW_ID in ', as_evalstr(spwid));
      ok := its.cal.setdata (msselect=msSelect);
      if (is_fail(ok)) fail;
#
      if (its.what.G) {
         its.cal.reset();
         ok := its.cal.setapply (type='P', t=its.intervals.P);
         if (is_fail(ok)) fail;
#
         ok := its.cal.setsolve (type='G', t=its.intervals.G, 
                                 table=tG, refant=its.refant);
         if (is_fail(ok)) fail;
#
         ok := its.cal.solve();
         if (is_fail(ok)) fail;
      }
#
      if (its.what.B) {
         its.cal.reset();
         ok := its.cal.setapply (type='P', t=its.intervals.P);
         if (is_fail(ok)) fail;
#
         if (its.what.G) {
            ok := its.cal.setapply (type='G', table=tG);
            if (is_fail(ok)) fail;
         }
#
         ok := its.cal.setsolve (type='B', t=its.intervals.B, 
                                 table=tB, refant=its.refant);
         if (is_fail(ok)) fail;
#
         ok := its.cal.solve();
         if (is_fail(ok)) fail;
      }
#
      if (its.what.D) {
         its.cal.reset();
         ok := its.cal.setapply (type='P', t=its.intervals.P);
         if (is_fail(ok)) fail;
#
         if (its.what.G) {
            ok := its.cal.setapply (type='G', table=tG);
            if (is_fail(ok)) fail;
         }
#
         if (its.what.B) {
            ok := its.cal.setapply (type='B', table=tB);
            if (is_fail(ok)) fail;
         }
#
         ok := its.cal.setsolve (type='D', t=its.intervals.D, 
                                 table=tD, refant=its.refant);
         if (is_fail(ok)) fail;
#
         ok := its.cal.solve();
         if (is_fail(ok)) fail;
      }
#
      return T;
   }



### 
   const its.solveForSecondary := function (spwid, sid)
   {
      wider its;
#
      fspwid := spaste(spwid);
      msSelect := spaste('FIELD_ID in ', as_evalstr(sid), 
                         ' && SPECTRAL_WINDOW_ID in ', as_evalstr(spwid));
      ok := its.cal.setdata (msselect=msSelect);
      if (is_fail(ok)) fail;
#
      its.cal.reset();
      ok := its.cal.setapply (type='P', t=its.intervals.P);
      if (is_fail(ok)) fail;
#
      if (its.what.B) {
         ok := its.cal.setapply (type='B', table=its.tables.B[fspwid]);
         if (is_fail(ok)) fail;
      }
#
      if (its.what.D) {
         ok := its.cal.setapply (type='D', table=its.tables.D[fspwid]);
         if (is_fail(ok)) fail;
      }
#
      if (its.what.G) {
         ok := its.cal.setsolve (type='G', t=its.intervals.G, table=its.tables.G[fspwid],
                                 append=T, refant=its.refant);
         if (is_fail(ok)) fail;
#
         ok := its.cal.solve();
         if (is_fail(ok)) fail;
      }
#
      return T;
   }


###
   const its.solve := function (primary, secondaries, spwids, leakage, bandpass, 
                                interval, refant)
#
# Version handling looping over spwids (bugs in calibrater)
# and with solving for each component separately (bugs in calibrater)
# rather than multiple set solves
#
   {
      wider its;

# Set parameters

      its.what.D := leakage;
      its.what.B := bandpass;
#
      if (!is_unset(refant) && refant > 0) its.refant := refant
      if (!is_unset(interval)) its.intervals.G := interval;

# Work out field IDs of sources

      pID  := its.as.findID (its.idrec, primary);
      if (is_fail(pID)) fail;
      its.primary := pID;
#
      t := dms.tovector (secondaries, 'string');
      if (is_fail(t)) fail;
#
      sID := its.as.findID (its.idrec, to_upper(t));
      if (is_fail(sID)) fail;
      its.secondaries := sID;

# Get spwIDs

      if (is_unset(spwids)) spwids := its.idrec.spwids;

# Indicate none of the spwids have been solved for yet

      for (spwid in its.idrec.spwids) {
         fspwid := spaste(spwid);
         its.solved[fspwid] := F;
      }

#print 'refant = ', its.refant
#print 'intervals = ', its.intervals
#print 'its.what = ', its.what
#print 'tables = ', its.tables

# Loop over spwids

      for (spwid in spwids) {

# Solve D, B and G for Primary

         ok := its.solveForPrimary (spwid, pID);
         if (is_fail(ok)) fail;

# Apply D and B, solve for G for secondaries

         ok := its.solveForSecondary (spwid, sID);
         if (is_fail(ok)) fail;

# Correct the gains for the calibrator polarization

         if (its.what.G) {
            ok := its.cal.reset();
            fspwid := spaste(spwid)
            ok := its.cal.linpolcor (tablein=its.tables.G[fspwid], 
                                     fields=secondaries);
            if (is_fail(ok)) fail;
      
# Establish flux density scale

            ok := its.cal.fluxscale (tablein=its.tables.G[fspwid], reference=primary,
                                     transfer=secondaries);
            if (is_fail(ok)) fail;
         }

# This one is now solved for

         its.solved[fspwid] := T;
      }
#
      return T;
   }



# Public functions


###
   const self.correct := function (interval=unset, vector=T)
#
# Version looping over spwids because of bugs in calibrater
#
   {
      wider its;
      if (length(its.solved)==0) {
         return throw ('You must run function solve first', 
                        origin='atcacalibrater.correct');
      }
#
# Apply calibration to all calibraters (no averaging)
#
      ids := [its.primary, its.secondaries];
      msSelect1 := spaste('FIELD_ID in ', as_evalstr(ids));
#
      spwids := its.idrec.spwids;
      for (spwid in spwids) {

# Have we solved for this spwid  ?

         fspwid := spaste(spwid);
         if (its.solved[fspwid]) { 

# Select fields and spwid from data

            its.cal.reset();
            msSelect2 := spaste('SPECTRAL_WINDOW_ID in ', as_evalstr(spwid));
            msSelect := spaste (msSelect1, ' && ', msSelect2);
            ok := its.cal.setdata (msselect=msSelect);
#
            ok := its.cal.setapply (type='P', t=its.intervals.P);
            if (is_fail(ok)) fail;
#
            if (its.what.G) {
               ok := its.cal.setapply (type='G', table=its.tables.G[fspwid]);
               if (is_fail(ok)) fail;  
            }
#
            if (its.what.D) {
               ok := its.cal.setapply (type='D', table=its.tables.D[fspwid]);
               if (is_fail(ok)) fail;
            }
#
            if (its.what.B) {
               ok := its.cal.setapply (type='B', table=its.tables.B[fspwid]);
               if (is_fail(ok)) fail;
            }
#
            ok := its.cal.correct();
            if (is_fail(ok)) fail;
         }
      }

# Now the targets (non-calibraters)

      allIDs := its.idrec.fields.ids;              # All IDs
      calIDs := [its.primary, its.secondaries];    # Calibrator IDs
      otherIDs := [];                              # IDs other than calibrators
      k := 1;
      for (i in allIDs) {
         found := F;
         for (j in calIDs) {
            if (i == j) {
              found := T;
              break;
            }
         }
#
         if (!found) {
            otherIDs[k] := i;
            k +:= 1;
         }
      }
      msSelect1 := spaste('FIELD_ID in ', as_evalstr(otherIDs));
      mode := 'RI';
      if (!vector) mode := 'AP';
#
      spwids := its.idrec.spwids;
      for (spwid in spwids) {

# Have we solved for this spwid  ?

         fspwid := spaste(spwid);
         if (its.solved[fspwid]) { 

# Select fields and spwid from data

            its.cal.reset();
            msSelect2 := spaste('SPECTRAL_WINDOW_ID in ', as_evalstr(spwid));
            msSelect := spaste (msSelect1, ' && ', msSelect2);
            ok := its.cal.setdata (msselect=msSelect);
#
            ok := its.cal.setapply (type='P', t=its.intervals.P);
            if (is_fail(ok)) fail;

# Smooth G table and apply

            tG := its.tables.G[fspwid];
            if (its.what.G) {
               if (!is_unset(interval)) {
                  tG := spaste (its.tables.G[fspwid], '-smooth');
                  ok := dos.remove(tG, mustexist=F);
                  ok := its.cal.calave (tablein=its.tables.G[fspwid], tableout=tG,
                                        fldsin=calIDs, fldsout=calIDs,
                                        spwsin=spwid, spwout=spwid, t=interval, 
                                        mode=mode, verbose=F);
                  if (is_fail(ok)) fail;  
               }
#
               ok := its.cal.setapply (type='G', table=tG);
               if (is_fail(ok)) fail;  
            }
#
            if (its.what.D) {
               ok := its.cal.setapply (type='D', table=its.tables.D[fspwid]);
               if (is_fail(ok)) fail;
            }
#
            if (its.what.B) {
               ok := its.cal.setapply (type='B', table=its.tables.B[fspwid]);
               if (is_fail(ok)) fail;
            }
#
            ok := its.cal.correct();
            if (is_fail(ok)) fail;
         }
      }
#

      return T;
   }

###
   const self.done := function ()
   {
      wider its;
      wider self;
#
      ok := its.as.done();
      ok := its.cal.done();
#
      val its := F;
      val self := F;
      return T;
   }


###
   const self.plotOld := function (gain=T, bandpass=F, leakage=F, spwids=[],
                                sources=unset, polarization=1, antennas=[])
   {
      wider its;
#
      n := 0;
      if (gain) n +:= 1;
      if (bandpass) n +:= 1;
      if (leakage) n +:= 1;
      if (n==0) return T;
#
      fields := [];
      if (!is_unset(sources)) {
         t := dms.tovector (sources, 'string');
         if (is_fail(t)) fail;
#
         fields := its.as.findID (its.idrec, to_upper(t));
         if (is_fail(fields)) fail;
      }

# Make plots

       ff := frame();
       bb := button(ff, 'Press to continue')
       if (n == 1)  ff->unmap();
#
       if (gain) {
          ok := its.cal.plotcal(tablename=its.tables.G, spwids=spwids, fields=fields,
                                antennas=antennas, polarization=polarizations);
          if (is_fail(ok)) fail;
          if (n > 1) await bb->press;
       }
#
       if (bandpass) {
          ok := its.cal.plotcal(tablename=its.tables.B, spwids=spwids, fields=fields,
                                antennas=antennas, polarization=polarizations);
          if (is_fail(ok)) fail;
          if (n > 1) await bb->press;
       }
#
       if (leakage) {
          ok := its.cal.plotcal(plottype='RI', tablename=its.tables.D, 
                                spwids=spwids, fields=fields,
                                antennas=antennas, polarization=polarizations);
          if (is_fail(ok)) fail;
          if (n > 1) await bb->press;
       }
#
       ff := F;
#
       return T;
   }


###
   const self.plot := function (gain=T, bandpass=F, leakage=F, spwids=[],
                                sources=unset, polarization=1, antennas=[])
   {
      wider its;
#
      n := 0;
      if (gain) n +:= 1;
      if (bandpass) n +:= 1;
      if (leakage) n +:= 1;
      if (n==0) return T;
#
      fields := [];
      if (!is_unset(sources)) {
         t := dms.tovector (sources, 'string');
         if (is_fail(t)) fail;
#
         fields := its.as.findID (its.idrec, to_upper(t));
         if (is_fail(fields)) fail;
      }

# Make plots

       ff := frame();
       bb := button(ff, 'Press to continue')
       if (n == 1)  ff->unmap();
#
       if (length(spwids)==0) spwids := its.idrec.spwids;
       for (spwid in spwids) {
          fspwid := spaste(spwid);
#
          if (gain) {
             ok := its.cal.plotcal(tablename=its.tables.G[fspwid], fields=fields,
                                antennas=antennas, polarization=polarizations);
             if (is_fail(ok)) fail;
             if (n > 1) await bb->press;
          }
#
          if (bandpass) {
             ok := its.cal.plotcal(tablename=its.tables.B[fspwid], fields=fields,
                                antennas=antennas, polarization=polarizations);
             if (is_fail(ok)) fail;
             if (n > 1) await bb->press;
          }
#
          if (leakage) {
             ok := its.cal.plotcal(plottype='RI', tablename=its.tables.D[fspwid], 
                                   fields=fields,
                                   antennas=antennas, polarization=polarizations);
             if (is_fail(ok)) fail;
             if (n > 1) await bb->press;
          }
       }
#
       return T;
   }


###
   const self.setjy := function (sources=unset)
   {
      wider its;
      return its.setJy(sources);
   }


###
   const self.solve := function (primary='1934-638', secondaries,
                                 spwids=unset, leakage=T, bandpass=T,
                                 interval=unset, refant=unset)
   {
      wider its;

# Clean up old tables

      ok := its.as.deletefiles([its.tables.G, its.tables.B, its.tables.D]);
      if (is_fail(ok)) fail;

# Find calibration components

      ok := its.solve (primary, secondaries, spwids, leakage, bandpass, 
                       interval, refant);
      if (is_fail(ok)) fail;
#
      return T;
   }


###
   self.summary := function ()
   {
      wider its;
#
      include 'ms.g'
      x := ms(its.msname, readonly=T);
      if (is_fail(x)) fail;
      ok := x.summary();
      ok := x.done();
#
      return T;
   }



# Constructor

# Make support tool

   include 'atcasupport.g'
   its.as := atcasupport();
   if (is_fail(its.as)) fail;

# Find directory that MS file is living in

   its.dir := its.as.directoryname(its.msname);
   if (is_fail(its.dir)) fail;

# Find MS description record

   its.idrec := its.as.createMSRec (its.msname); 
   if (is_fail(its.idrec)) fail;
 
# Set Table names

   ok := its.setTableNames ();
   if (is_fail(ok)) fail;

# Make calibrater tool

   ok := its.makeCalibraterTool();
   if (is_fail(ok)) fai;l
}
