# calibrater.g: Glish proxy for calibrater DO 
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
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
#   $Id: calibrater.g,v 19.19 2006/02/14 19:47:17 gmoellen Exp $
#

pragma include once

include "servers.g"
include "table.g"
include "calutil.g"

#defaultservers.suspend(T)
#defaultservers.trace(T)

##############################################################################
# Private function used by constructor
#
const _define_calibrater := function(msfile, compress, ref agent, id) {
   self:= [=];
   public:= [=];

   self.agent:= ref agent;
   self.id:= id;
   self.calutil:= calutil (msfile);
   self.msfile:= msfile;

#-----------------------------------------------------------------------------
# Private function to convert synthesis selection strings to TAQL
#
   const self.synthselect := function (synth='') {
#
      taql := synth;
      if (strlen(synth) > 0) {
         # Check for '0-rel' or '0-REL'
         zerorel := synth ~ m/0-REL/i;
         if (zerorel) {
	    synth := synth ~ s/0-REL//gi;
         } else {
            # Check for '1-rel' or '1-REL'
            synth := synth ~ s/1-REL//gi;
            # Adjust all relevant MS/calibration indices by 1
            synth := synth ~ s/ANTENNA1/(ANTENNA1+1)/gi;
            synth := synth ~ s/ANTENNA2/(ANTENNA2+1)/gi;
            synth := synth ~ s/FEED1/(FEED1+1)/gi;
            synth := synth ~ s/FEED2/(FEED2+1)/gi;
            synth := synth ~ s/ARRAY_ID/(ARRAY_ID+1)/gi;
            synth := synth ~ s/CORRELATOR_ID/(CORRELATOR_ID+1)/gi;
            synth := synth ~ s/FIELD_ID/(FIELD_ID+1)/gi;
            synth := synth ~ s/OBSERVATION_ID/(OBSERVATION_ID+1)/gi;
            synth := synth ~ s/PULSAR_ID/(PULSAR_ID+1)/gi;
            # Temporary 10/2000; replace with DATA_DESC_ID directly for now
            synth := synth ~ s/SPECTRAL_WINDOW_ID/(DATA_DESC_ID+1)/gi;
            synth := synth ~ s/ANTENNA_ID/(ANTENNA_ID+1)/gi;
            synth := synth ~ s/ORBIT_ID/(ORBIT_ID+1)/gi;
            synth := synth ~ s/PHASED_ARRAY_ID/(PHASED_ARRAY_ID+1)/gi;
            synth := synth ~ s/FEED_ID/(FEED_ID+1)/gi;
            synth := synth ~ s/BEAM_ID/(BEAM_ID+1)/gi;
            synth := synth ~ s/PHASED_FEED_ID/(PHASED_FEED_ID+1)/gi;
            synth := synth ~ s/SOURCE_ID/(SOURCE_ID+1)/gi;
            taql := synth;
         };
      };
      return taql;
   };

#----------------------------------------------------------------------------
# Private function to look up DATA_DESC_ID's for a given SPW_ID
# 
   const self.ddid := function (msfile, spwid) {
#
      # Open the DATA_DESCRIPTION sub-table
      ddtab:= table (spaste (msfile,'/','DATA_DESCRIPTION'));
      ddspwid:= ddtab.getcol ('SPECTRAL_WINDOW_ID');
      ddflagrow:= ddtab.getcol ('FLAG_ROW');
      nddrow:= ddtab.nrows();
      ddtab.close();

      # Iterate through non-flagged rows, to find SPW_ID matches
      if (nddrow > 0) {
         dd:= [];
         ndd:= 0;
         for (i in 1:nddrow) {
            if (!ddflagrow[i] && (ddspwid[i]+1)==spwid) {
               ndd:= ndd + 1;
               dd[ndd]:= i;
            };
         };
      };	
      return dd;
   };

#-----------------------------------------------------------------------------
# Private function to generate uv-range TAQL selection strings
# 
   const self.uvtaql := function (uvrange, ref noselect) {
#
      wider self;

      val noselect:= T;
      uvsel:= '';
      uvlim:= sort (uvrange);
      if (len(uvrange) == 1) {
         uvlim[2]:= uvlim[1];
         uvlim[1]:= 0;
      };
      uvlim:= uvlim * 1000.0;
      if (max (uvlim) > 0) {
         # Extract the reference frequencies
         spwtab:= table (spaste (self.msfile,'/','SPECTRAL_WINDOW'));
         reffreq:= spwtab.getcol ('REF_FREQUENCY');
         spwtab.close();

         uvsel:= '(';
         nfreq:= len (reffreq);
         c:= dq.constants('c').value;
         ffact:= reffreq / c;

         for (ispw in 1:nfreq) {
            # Look up the DATA_DESC_ID's for this SPW_ID
            dd:= self.ddid (self.msfile, ispw);
            ndd:= len (dd);
            for (idd in 1:ndd) {
               uvsel:= spaste (uvsel, '((DATA_DESC_ID==', dd[idd]-1, ' ) && (',
                  'SQRT(UVW[1]^2 + UVW[2]^2) > ', 
                  uvlim[1] / ffact[ispw],
                  ' && SQRT(UVW[1]^2 + UVW[2]^2) < ', 
                  uvlim[2] / ffact[ispw], '))');
               if (!(ispw == nfreq && idd == ndd)) uvsel:= paste(uvsel,' || ');
            };
         };
         uvsel:= spaste (uvsel, ')');
         val noselect:= F;
	 note (spaste('Applying a uv-range selection of ', uvlim[1]/1000.0, 
            ' to ', uvlim[2]/1000.0, ' klambda'));
      };
      return uvsel;
   };

#-----------------------------------------------------------------------------
# Private function to pre-process input selection strings
# 
   const self.validstring := function (inputstring) {
#
      outputstring := inputstring;
      # Guard against "" or " "
      if (shape(outputstring) == 0) {
         outputstring:= ' ';
      } else {
         # Convert Glish string arrays 
         outputstring := paste (outputstring);
         # Strip spurious start and end quotes (
         outputstring := outputstring ~ s/^'(.*)'$/$1/;
         outputstring := outputstring ~ s/^"(.*)"$/$1/;
      };
      return outputstring;
   };

#-----------------------------------------------------------------------------
# Method: setdata
#
   self.setdataRec:= [_method = "setdata", _sequence = self.id._sequence];
   public.setdata:= function (mode = 'none', nchan = 1, start = 1,
      step = 1, mstart = '0km/s', mstep = '0km/s', uvrange = 0, 
      msselect = ' ') {
#
      wider self;
      self.setdataRec.mode:= mode;
      self.setdataRec.nchan:= nchan;
      self.setdataRec.start:= start;
      self.setdataRec.step:= step;
      self.setdataRec.mstart:= mstart;
      self.setdataRec.mstep:= mstep;

      # Pre-process input select string and convert to TAQL
      self.setdataRec.msselect:= self.synthselect (self.validstring(msselect));

      # Generate a uv-range TAQL selection string and add to msselect
      uvsel:= self.uvtaql (uvrange, noselect);
      if (!noselect) {
         if (len (self.setdataRec.msselect) == 0 ||
            (self.setdataRec.msselect ~ m/\S/g) == 0) 
            self.setdataRec.msselect:= uvsel;
         else {
            self.setdataRec.msselect:= spaste ('(', self.setdataRec.msselect,
            ') && ', uvsel);
         };
      };
      return defaultservers.run (self.agent, self.setdataRec);
    }

#-----------------------------------------------------------------------------
# Method: setapply
#
   self.setapplyRec:= [_method = "setapply", _sequence = self.id._sequence];
   public.setapply:= function (type, t = 0.0, table = ' ', interp='nearest', 
      select = ' ', spwmap=-1, opacity=0.0, unset = F, rawspw=-1) {

      wider self;
      self.setapplyRec.type:= type;
      self.setapplyRec.t:= t;
      self.setapplyRec.unset:=unset;
      self.setapplyRec.opacity:=opacity;
      self.setapplyRec.rawspw:=rawspw;
      self.setapplyRec.table:= table;
      self.setapplyRec.spwmap:=spwmap-1;
      self.setapplyRec.interp:=interp;

      # Pre-process input select string and convert to TAQL
      self.setapplyRec.select:= self.synthselect (self.validstring(select));

      if (unset) {
        return defaultservers.run (self.agent, self.setapplyRec);
      }

      # if !unset:
      
      # Disallow non-zero interpolation interval until all interpolation
      # infrastructure is complete; not applicable to pre-computed
      # Jones matrices.
      if (type != 'P' && 
          type!='TOPAC' && 
          type!='GAINCURVE') self.setapplyRec.t:= 0;

      # If not TOPAC, ensure opacity=0.0
      if (type!='TOPAC') self.setapplyRec.opacity:=0.0

      # Must specify type and/or table
      if (type==' ' && (table==' ' || table=='')) {
        note('Please specify a valid calibration Table or Type',
             priority='WARN',origin='calibrater.setapply');
        return F;
      };

      # If needed, ensure table exists, is a cal table, and type is ok
      needtable:= !(type=='P' || type=='TOPAC' || type=='GAINCURVE');
      if (needtable) {
        # need table
        if (is_string(table) && dos.fileexists(table)) {
          # table exists
          if (tableinfo(table).type=='Calibration') {
            # table is cal table
            calfiletype:=split(tableinfo(table).subType)[1];
            if (!is_fail(calfiletype)) {
              # cal type in table
              if (type==' ') {
                # type not specified, adopt from table
                self.setapplyRec.type:=calfiletype;
              } else {
                # type specified, does it match table?
                if (type!=calfiletype) {
                  # no match, so quit
                  note(paste('Specified type,',type,
                              'does not match table type,',calfiletype,'.'),
                       priority='WARN',origin='calibrater:setapply');
                  note('Check inputs and run setapply again.',
                       priority='WARN',origin='calibrater:setapply');
                  return F;
                };                
              };
            } else {
              # no cal type in table
              if (type==' ') {
                # type not specified, and not in table, so quit
                note('Calibration table has unknown type.',
                     priority='WARN',origin='calibrater.setapply');
                note('Please specify the Type explicitly and run setapply again.',
                     priority='WARN',origin='calibrater:setapply');
                return F;
              };
            };
          } else {
            # is not cal table, so quit
            note(spaste('Table ',table,' is not a Calibration table.'),
                 priority='WARN',origin='calibrater:setapply');
            note('Please check the name and run setapply again.',
                 priority='WARN',origin='calibrater:setapply');
            return F;
          };
        } else {
          # table does not exist
          note(spaste('Table ',table,' does not exist.'),
               priority='WARN',origin='calibrater:setapply');
          note('Please check the name and run setapply again.',
               priority='WARN',origin='calibrater:setapply');
          return F;
        };
      } else {
        # table not required
        self.setapplyRec.table:='';
      };

      # if reach here, all ok
      return defaultservers.run (self.agent, self.setapplyRec);

    };

#-----------------------------------------------------------------------------
# Method: setsolve
#
   self.setsolveRec:= [_method = "setsolve", _sequence = self.id._sequence];
   public.setsolve:= function (type, t = 60.0, preavg = 60.0, 
      phaseonly = F, refant = -1, table, append = F, unset = F) {
#
      wider self;
      self.setsolveRec.type:= type;
      self.setsolveRec.t:= t;
      self.setsolveRec.preavg:= preavg;
      self.setsolveRec.phaseonly:= phaseonly;
      self.setsolveRec.refant:= refant;
      if (refant > 0) {
         self.setsolveRec.refant:= refant-1;
      };
      self.setsolveRec.table:= table;
      self.setsolveRec.append:= append;
      self.setsolveRec.unset:=unset;

      if (self.setsolveRec.type ~ m/B|G|T/) {
        self.setsolveRec.preavg:=self.setsolveRec.t;
        note('NB: For B, G, and T solving, the preavg parameter is now being ');
        note(' forced to equal the solution interval, t, because the calibrater ');
        note(' tool is now smart enough to avoid decorrelating averages in time ');
        note(' for these types.  This should also provide significant');
        note(' improvements in performance for longer solution intervals.')
      };
      # check on cal file existence
      if (!unset && (is_string(table) && dos.fileexists(table))) {   
        if ( dc.whatis(table).type=='Calibration' ) {
          if (!append) {
            note(spaste('Calibration table ',table,' exists, and append=F.'),
                 priority='WARN',origin='calibrater:setsolve');
            note('Therefore, this table will be overwritten.',
                 priority='WARN',origin='calibrater:setsolve');
            note('Consider re-running setsolve with append=T.',
                 priority='WARN',origin='calibrater:setsolve');
          } else {
            note(spaste('New solutions will be appended to ',table));
          };
        } else {  # exists, but not a calibration table
          note(spaste('File ',table,' exists and is not a Calibration table.'),
               priority='WARN',origin='calibrater:setsolve');
          note('Please check the name and run setsolve again.',
               priority='WARN',origin='calibrater:setsolve');
	  return F;
        };
      };       

      # All ok, so forward this setsolve to server
      return defaultservers.run (self.agent, self.setsolveRec);
    };

#-----------------------------------------------------------------------------
# Method: setsolvebandpoly
#
   self.setsolvebandpolyRec:= [_method = "setsolvebandpoly",
                               _sequence = self.id._sequence];
   public.setsolvebandpoly:= function (table = ' ', append = F, 
                                       degamp = 3, degphase = 3,
                                       visnorm = F, bpnorm = T,
                                       maskcenter = 1, maskedge = 5,
                                       refant = -1, unset = F) {
#
      wider self;
      self.setsolvebandpolyRec.table:= table;
      self.setsolvebandpolyRec.append:= append;
      self.setsolvebandpolyRec.degamp:= degamp;
      self.setsolvebandpolyRec.degphase:= degphase;
      self.setsolvebandpolyRec.visnorm:= visnorm;
      self.setsolvebandpolyRec.bpnorm:= bpnorm;
      self.setsolvebandpolyRec.maskcenter:= maskcenter;
      self.setsolvebandpolyRec.maskedge:= maskedge;
      self.setsolvebandpolyRec.refant:= refant;
      if (refant > 0) {
         self.setsolvebandpolyRec.refant:= refant-1;
      };
      self.setsolvebandpolyRec.unset:=unset;

      # check on cal file existence
      if (!unset && (is_string(table) && dos.fileexists(table)) ) {   
        if ( dc.whatis(table).type=='Calibration' ) {
          if (!append) {
            note(spaste('Calibration table ',table,' exists, and append=F.'),
                 priority='WARN',origin='calibrater:setsolvebandpoly');
            note('Therefore, this table will be overwritten.',
                 priority='WARN',origin='calibrater:setsolvebandpoly');
            note('Consider re-running setsolvebandpoly with append=T.',
                 priority='WARN',origin='calibrater:setsolvebandpoly');
          } else {
            note(spaste('New solutions will be appended to ',table));
          };
        } else {  # exists, but not a calibration table
          note(spaste('File ',table,' exists and is not a Calibration table.'),
               priority='WARN',origin='calibrater:setsolvebandpoly');
          note('Please check the name and run setsolvebandpoly again.',
               priority='WARN',origin='calibrater:setsolvebandpoly');
	  return F;
        };
      };       

      # All ok, so forward this setsolvebandpoly to server
      return defaultservers.run (self.agent, self.setsolvebandpolyRec);
    };


#-----------------------------------------------------------------------------
# Method: setsolvegainpoly
#
   self.setsolvegainpolyRec:= [_method = "setsolvegainpoly",
                               _sequence = self.id._sequence];
   public.setsolvegainpoly:= function (table = ' ', append = F, mode = 'PHAS', 
                                       degree=3, refant = -1, unset = F) {
#
      wider self;
      self.setsolvegainpolyRec.table:= table;
      self.setsolvegainpolyRec.append:= append;
      self.setsolvegainpolyRec.mode:= mode;
      self.setsolvegainpolyRec.degree:= degree;
      self.setsolvegainpolyRec.refant:= refant;
      if (refant > 0) {
         self.setsolvegainpolyRec.refant:= refant-1;
      };
      self.setsolvegainpolyRec.unset:=unset;

      # check on cal file existence
      if (!unset && (is_string(table) && dos.fileexists(table)) ) {   
        if ( dc.whatis(table).type=='Calibration' ) {
          if (!append) {
            note(spaste('Calibration table ',table,' exists, and append=F.'),
                 priority='WARN',origin='calibrater:setsolvegainpoly');
            note('Therefore, this table will be updated.',
                 priority='WARN',origin='calibrater:setsolvegainpoly');
          } else {
            note(spaste('New solutions will be appended to ',table));
          };
        } else {  # exists, but not a calibration table
          note(spaste('File ',table,' exists and is not a Calibration table.'),
               priority='WARN',origin='calibrater:setsolvegainpoly');
          note('Please check the name and run setsolvegainpoly again.',
               priority='WARN',origin='calibrater:setsolvegainpoly');
	  return F;
        };
      };       

      # All ok, so forward this setsolvegainpoly to server
      return defaultservers.run (self.agent, self.setsolvegainpolyRec);
    };

#-----------------------------------------------------------------------------
# Method: setsolvegainspline
#
   self.setsolvegainsplineRec:= [_method = "setsolvegainspline",
                                 _sequence = self.id._sequence];
   public.setsolvegainspline:= function (table = ' ', append = F,  
                                         mode = 'PHAS', preavg = 0,
                                         splinetime=10800,
                                         refant = -1, npointaver=10, 
					 phasewrap=250, unset = F) {
#

     phasewrap:=phasewrap*pi/180;
     wider self;
      self.setsolvegainsplineRec.table:= table;
      self.setsolvegainsplineRec.append:= append;
      self.setsolvegainsplineRec.mode:= mode;
      self.setsolvegainsplineRec.preavg:= preavg;
      self.setsolvegainsplineRec.splinetime:= splinetime;
      self.setsolvegainsplineRec.refant:= refant;
      if (refant > 0) {
         self.setsolvegainsplineRec.refant:= refant-1;
      };
     self.setsolvegainsplineRec.npointaver:= npointaver;
     self.setsolvegainsplineRec.phasewrap:= phasewrap;
      self.setsolvegainsplineRec.unset:=unset;

      # check on cal file existence
      if (!unset && (is_string(table) && dos.fileexists(table) ) ) {   
        if ( dc.whatis(table).type=='Calibration' ) {
          if (!append) {
            note(spaste('Calibration table ',table,' exists, and append=F.'),
                 priority='WARN',origin='calibrater:setsolvegainspline');
            note('Therefore, this table will be updated.',
                 priority='WARN',origin='calibrater:setsolvegainspline');
          } else {
            note(spaste('New solutions will be appended to ',table));
          };
        } else {  # exists, but not a calibration table
          note(spaste('File ',table,' exists and is not a Calibration table.'),
               priority='WARN',origin='calibrater:setsolvegainspline');
          note('Please check the name and run setsolvegainspline again.',
               priority='WARN',origin='calibrater:setsolvegainspline');
	  return F;
        };
      };       

      # All ok, so forward this setsolvegainspline to server
      return defaultservers.run (self.agent, self.setsolvegainsplineRec);
    };
#-----------------------------------------------------------------------------
# Method: state
#
   self.stateRec:= [_method = "state", _sequence = self.id._sequence];
   public.state:= function () {
      wider self;
      return defaultservers.run(self.agent, self.stateRec);
   };

#-----------------------------------------------------------------------------
# Method: reset
#
   self.resetRec:= [_method = "reset", _sequence = self.id._sequence];
   public.reset:= function ( apply=T, solve=T ) {
      wider self;
      self.resetRec.apply:=apply;
      self.resetRec.solve:=solve;
      return defaultservers.run(self.agent, self.resetRec);
   };

#-----------------------------------------------------------------------------
# Method: initcalset
#
   self.initcalsetRec:= [_method = "initcalset", _sequence = self.id._sequence];
   public.initcalset:= function ( calset=1 ) {
      wider self;
      self.initcalsetRec.calset:=calset;
      return defaultservers.run(self.agent, self.initcalsetRec);
   };


#-----------------------------------------------------------------------------
# Method: solve
#
   self.solveRec:= [_method = "solve", _sequence = self.id._sequence];
   public.solve:= function () {
      wider self;
      return defaultservers.run (self.agent, self.solveRec);
    };

#-----------------------------------------------------------------------------
# Method: modelfit
#
   self.modelfitRec:= [_method = "modelfit", _sequence = self.id._sequence];
   public.modelfit:= function (niter=0,type="P",par=[1,0,0],vary=[],file="") {
      wider self;
      self.modelfitRec.niter:=niter;
      self.modelfitRec.type:=type;
      self.modelfitRec.par:=par;
      self.modelfitRec.vary:=vary;
      self.modelfitRec.file:=file;
      return defaultservers.run (self.agent, self.modelfitRec);
    };

#-----------------------------------------------------------------------------
# Method: correct
#
   self.correctRec:= [_method = "correct", _sequence = self.id._sequence];
   public.correct:= function () {
      wider self;
      return defaultservers.run (self.agent, self.correctRec);
    };

#-----------------------------------------------------------------------------
# Method: smooth
#
   self.smoothRec:= [_method = "smooth", _sequence = self.id._sequence];
   public.smooth:= function (infile,
                             outfile,append,
                             select,
                             smoothtype='mean',smoothtime=0,
                             interptype='spline',interptime=0) {
      wider self;

      return throw('The smooth function has been disabled while some calibrater infrastructural work is completed.');

      self.smoothRec.infile:=infile;
      self.smoothRec.outfile:=outfile;
      self.smoothRec.append:=append;
      self.smoothRec.select:= self.synthselect (self.validstring(select));
      self.smoothRec.smoothtype:=smoothtype;
      self.smoothRec.smoothtime:=smoothtime;
      self.smoothRec.interptype:=interptype;
      self.smoothRec.interptime:=interptime;

      return defaultservers.run (self.agent, self.smoothRec);
    };

#-----------------------------------------------------------------------------
# Method: close
#
   self.closeRec:= [_method = "close", _sequence = self.id._sequence];
   public.close:= function () {
      wider self;
      return defaultservers.run (self.agent, self.closeRec);
    };

#-----------------------------------------------------------------------------
# Method: type
#
    public.type := function() {
	return 'calibrater';
    };

#-----------------------------------------------------------------------------
# Method: id
#
    public.id := function() {
       wider self;
       return self.id.objectid;
    };

#-----------------------------------------------------------------------------
# Method: done
#
    public.done := function() {
       wider self, public;
       ok := defaultservers.done(self.agent, public.id());
       if (ok) {

           # Done the calutil interface:
           self.calutil.done();

           self := F;
           val public := F;
       }
       return ok;
    };

#-----------------------------------------------------------------------------
# Plot function
#
    public.plotcal:= function (plottype = 'AMP', tablename = '', 
       antennas = [], fields = [], polarization = 1, spwids = [], 
       multiplot = F, nx=1, ny=1, psfile='') {
#
       wider self;
       return self.calutil.plotcal (plottype, tablename, antennas, fields,
          polarization, spwids, multiplot, nx, ny, psfile);
    };

#-----------------------------------------------------------------------------
# Method: fluxscale (new c++ version)
#
   self.fluxscaleRec:= [_method = "fluxscale", _sequence = self.id._sequence];
   public.fluxscale:= function (tablein,tableout='',
				reference,transfer=-1,
				append=F, refspwmap=-1,
				ref fluxd=[]) {

#
      wider self;

      # outfile=infile
      if ( length(tableout)==0 || strlen(tableout)==0 ) tableout:=tablein;

      # ensure ref/trans are unique
      reference:=unique(reference);
      transfer:=unique(transfer);

      # convert string to indices
      if (is_string(reference)) reference:=self.calutil.getfldidlist(reference);;
      if (is_string(transfer))  transfer:=self.calutil.getfldidlist(transfer);;

      self.fluxscaleRec.infile:=tablein;
      self.fluxscaleRec.outfile:=tableout;
      self.fluxscaleRec.reference:=reference-1;
      self.fluxscaleRec.transfer:=transfer-1;;
      self.fluxscaleRec.append:= append;
      self.fluxscaleRec.refspwmap:=refspwmap-1;

      returnval:=defaultservers.run (self.agent, self.fluxscaleRec);
      val fluxd := self.fluxscaleRec.fluxd;

      return returnval;
    }
#-----------------------------------------------------------------------------
# Method: accumulate
#
   self.accumulateRec:= [_method = "accumulate", _sequence = self.id._sequence];
   public.accumulate:= function (tablein="",incrtable="",tableout="",
				 field=-1,calfield=-1,
				 interp="linear",
				 t=-1.0) {
#
      wider self, public;

      # ensure field lists are unique
      field:=    unique(field);
      calfield:= unique(calfield);

      # convert string to indices
      if (is_string(field))     field:=   self.calutil.getfldidlist(field);;
      if (is_string(calfield))  calfield:=self.calutil.getfldidlist(calfield);;

      # If no table specified, accumulate in place
#      if (tableout=="") tableout:=tablein;;

      # Have to refresh data selection if creating cumulative
      # table from scratch
      if (t > 0.0) public.setdata();;

      self.accumulateRec.intab:=tablein;
      self.accumulateRec.incrtab:=incrtable;
      self.accumulateRec.outtab:=tableout;
      self.accumulateRec.field:=field-1;
      self.accumulateRec.calfield:=calfield-1;
      self.accumulateRec.interp:=interp;
      self.accumulateRec.t:=t;

      return defaultservers.run (self.agent, self.accumulateRec);

    }
#-----------------------------------------------------------------------------
# Flux density scale (glish version)
#
    public.oldfluxscale:= function (tablein, tableout='', reference = "",
       transfer = "") {
#
       wider self;
       return self.calutil.fluxscale (tablein, tableout, reference, transfer);
    };

#-----------------------------------------------------------------------------
# Position angle calibrater
#
    public.posangcal:= function (tablein, tableout =unset, posangcor=[]) {
#
       wider self;
       if (is_unset(tableout)) tableout:='';
       return self.calutil.posangcal (tablein, tableout, posangcor);
    };


#-----------------------------------------------------------------------------
# Cal solution averaging
#
    public.calave:= function (tablein, tableout,
                              fldsin=F, spwsin=F,
                              fldsout=F, spwout=F,
                              t=-1.0,
                              append=F,
                              mode='RI', verbose=T) {
#

      return throw('The calave function has been temporarily disabled while some calibrater infrastructural work is completed.');

       wider self;
       return self.calutil.calave (tablein, tableout,
                                   fldsin, spwsin,
                                   fldsout, spwout,
                                   t,append,mode,verbose);
    }

#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
# Linear Polarization correction
#
    public.linpolcor:= function (tablein= '', tableout = '', fields = "") {
#
       wider self;
       return self.calutil.linpolcor (tablein, tableout, fields);
    };

#-----------------------------------------------------------------------------

   return public;

} #_define_calibrater()

##############################################################################
# Constructor: create a new server for each invocation
#
   const calibrater:= function (filename, compress = F, host = '', 
                                forcenewserver = T) {
#      defaultservers.suspend(T);
      agent:= defaultservers.activate ("calibrater", host, forcenewserver);
      id:= defaultservers.create (agent, "calibrater", "calibrater", 
         [msfile = filename, compress = compress]);
#      defaultservers.suspend(F);
      return _define_calibrater (filename, compress, agent, id);
    };

##############################################################################
# Test script
#
   const calibratertest:= function () {
#
      # Create a calibratertester tool
      include 'calibratertester.g';
      caltester := calibratertester();   
      
      # Conduct the basic tests
      ok := caltester.testcorrect ('G.1CH2SP4P3S');
      ok := caltester.testcorrect ('G.1CH2SP4P3SB');
      caltester.done();
      return ok;
    };

##############################################################################
# Demo script
#
   const calibraterdemo:= function () {
      fail "Not yet implemented"
    };

##############################################################################



