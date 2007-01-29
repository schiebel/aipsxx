# calutil.g: Glish closure for calibration table utilities
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003,2005
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
#   $Id: 
#

pragma include once

include "table.g"
include "catalog.g"
include "mathematics.g"
include 'functionals.g'
include "misc.g"
include "note.g"

##############################################################################
# Function to define the calutil interface, and private and public functions
#
const _define_calutil := function(msfile) {
   self:= [=];
   public:= [=];

   self.msfile:= msfile;
   self.pgplotter:= F;


#-----------------------------------------------------------------------------
# Private functions:
#-----------------------------------------------------------------------------
# Getid function - obtain the field_id for a given field name
#
   self.getid := function (msname, fieldname) {
      t:= table(spaste(msname,'/FIELD'), ack=F);
      if (!is_table(t)) fail;
      names:= t.getcol('NAME');
      n:= len(names);
      fieldname:= fieldname ~ s/\+/\\+/;
      fieldids:= seq(1:n)[names ~ eval(spaste('m/',fieldname,'/'))];
      nfldid:= len(fieldids);
      if (nfldid == 0) {
         t.close();
         return throw(paste('Field: ', fieldname, ' not found'))
      };
      if (nfldid > 1) {
         t.close();
         return throw(paste('More than one field name matches ',fieldname,
                            ': ', names[fieldids]))
      };
      t.close();
      return fieldids[1];
   };

#-----------------------------------------------------------------------------
# Public functions:
#-----------------------------------------------------------------------------
# Getfldidlist function - obtain the field_id for a given field name
#
   public.getfldidlist := function (fieldnames) {

      nflds:=len(fieldnames);

      # empty output list, to start
      fieldids:=[];

      t:= table(spaste(self.msfile,'/FIELD'), ack=F);
      if (!is_table(t)) fail;;
      names:= t.getcol('NAME');
      n:= len(names);


      # for each specified fieldname, find matching indices
      for (ifld in 1:nflds) {
	
	thisfield:= fieldnames[ifld] ~ s/\+/\\+/;
	thisfieldid:= seq(1:n)[names ~ eval(spaste('m/',thisfield,'/'))];
	nfldid:= len(thisfieldid);

	# accumulate this field id(s), or abort
	if (nfldid > 0) {
	  fieldids:=[fieldids,thisfieldid];
	} else {
	  t.done();
	  return throw(paste('Field: ', thisfield, ' not found'));
	}
      }
      t.done();
      return fieldids;
   };

# Fluxscale - bootstrap the flux density scale from std. amplitude calibrators
#
   public.fluxscale := function (tablein, tableout, reference, transfer) {
      
      wider self;
      note('Setting the flux density scale using reference calibrators',
         origin='calutil.g');

      # Make sure tablein is specified as string:
      if (is_string(tablein)) {
        # Make sure tablein is a cal table:
        if (dc.whatis(tablein).type == 'Calibration') {
          # Open it
          ctab:= table (tablein, ack=F);
        } else {
          return throw(paste('Input calibration table',tablein,'does not exit'));
        } 
      } else {
        return throw('tablein must be specified as a string');
      }

      # Prevent duplicate field names, which may cause the
      # flux scaling to be performed multiple times.
      refuniq:= unique(split(reference));
      transuniq:= unique(split(transfer));
      
      # Get field_id's of the reference and transfer fields
      ndim:= len(refuniq);
      fldid['ref']:= array(0,ndim);
      for (i in [1:ndim]) {
         if (is_string(refuniq[i])) {
            refuniq[i]:= dms.stripleadingblanks(refuniq[i]);
            refuniq[i]:= dms.striptrailingblanks(refuniq[i]);
            id:= self.getid (self.msfile, refuniq[i]);
            if (!is_fail(id)) fldid['ref'][i]:= id;
	    else return throw(spaste('Failed to uniquely match reference fieldname: ',refuniq[i]));
         };
      };
      ndim:= len(transuniq);
      fldid['trf']:= array(0,ndim);
      for (i in [1:ndim]) {
         if (is_string(transuniq[i])) {
            transuniq[i]:= dms.stripleadingblanks(transuniq[i]);
            transuniq[i]:= dms.striptrailingblanks(transuniq[i]);
            id:= self.getid (self.msfile, transuniq[i]);
            if (!is_fail(id)) fldid['trf'][i]:= id;
	    else return throw(spaste('Failed to uniquely match transfer fieldname: ',transuniq[i]));
         };
      };
      nfld['ref']:= len(fldid['ref']);
      nfld['trf']:= len(fldid['trf']);
      if (nfld['ref'] == 0) 
         return throw ('No reference fields specified');
      if (nfld['trf'] == 0) 
         return throw ('No transfer fields specified');

      maxant:= max (ctab.getcol('ANTENNA1'))+1;
      maxspw:= max (ctab.getcol('GAIN')::shape[3]);

      # Compute the mean gain modulus for all reference and transfer 
      # fields per field, antenna, spectral window and polarization
      for (typ in ['ref', 'trf']) {
         mgm[typ]:= array(0,nfld[typ],maxant,maxspw,2);
         for (ifld in [1:nfld[typ]]) {
            taql:= spaste('FIELD_ID==', fldid[typ][ifld]-1);
            cref:= ctab.query (taql);
            gains:= cref.getcol ('GAIN');
            ant:= cref.getcol ('ANTENNA1')+1;
            solutionok := cref.getcol ('SOLUTION_OK');
            fwt:=cref.getcol('FIT_WEIGHT');
            cref.close();

            numspw:= gains::shape[3];
            numpol:= gains::shape[1];
   
            for (iant in [1:maxant]) {
              amask:= (ant == iant);
              for (ispw in [1:numspw]) {
                wtmask:=(fwt[ispw,]>0.0);
                tmask:=amask;   # & wtmask;  (wts not right!)
#                tmask:=amask & wtmask;
                if (sum(tmask)>0) {
                  for (ipol in [1:numpol]) {
                    tmp:= gains[ipol,ipol,ispw,tmask][solutionok[ispw,tmask]];
                    mgm[typ][ifld,iant,ispw,ipol]:= mean (abs(tmp)^2);
                  };
                };
              };
            };
         };
      };

      # Average over all reference fields
      refshape:= mgm['ref']::shape;
      numspw:= refshape[3];
      numpol:= refshape[4];
      calmgm:= array(0,maxant,numspw,numpol);
      for (iant in [1:maxant]) {
         for (ispw in [1:numspw]) {
            for (ipol in [1:numpol]) {
               calmgm[iant,ispw,ipol]:= mean(1.0/mgm['ref'][,iant,ispw,ipol]);
            };
         };
      };

      # Compute the mean scaling ratio per spectral window for
      # each transfer field (which equals the field flux density,
      # if unit initial flux density is assumed for the transfer
      # fields, as it is here).
      refshape:= mgm['trf']::shape;
      numspw:= refshape[3];
      numpol:= refshape[4];
      sfluxd:= array(1.0,nfld['trf'],numspw);
      srms:= array(1.0,nfld['trf'],numspw);
      sqrfluxd:= array(1.0,nfld['trf'],numspw);
      for (ifld in [1:nfld['trf']]) {
         for (ispw in [1:numspw]) {
            tmp:= calmgm[,ispw,] * mgm['trf'][ifld,,ispw,];
            mask:= !is_nan(tmp);
            sfluxd[ifld,ispw]:= mean (tmp[mask]);
            sqrfluxd[ifld,ispw]:= mean (tmp[mask]^2);
            # Compute rms
            n:= len(tmp);
            if (n > 3) { 
               srms[ifld,ispw]:= 
                  sqrt (sqrfluxd[ifld,ispw] - sfluxd[ifld,ispw]^2) / (n - 1);
            };
            # Report values
            pflx:= sfluxd[ifld,ispw];
            prms:= srms[ifld,ispw];
            formpflx:= sprintf ("%9.3f", pflx);
            formprms:= sprintf ("%6.3f", prms);
            note ('Flux density for ', transuniq[ifld], ' (spw=', ispw, ') ',
               'is: ', formpflx, ' +/- ', formprms, ' Jy', 
               origin='calutil.g');
         };
      };

      # Done with input table, so done it
      ctab.done();         

      # Scale the gain corrections in the output calibration table
      if (length(tableout) == 0 || strlen(tableout) == 0) tableout:= tablein;
      if (tablein == tableout) {
         ctabout:= table (tablein, readonly=F, ack=F);
      } else {
         tablecopy (tablein, tableout);
         ctabout:= table (tableout, readonly=F, ack=F);
      };
      for (ifld in [1:nfld['trf']]) {
         coutref:= ctabout.query(spaste('FIELD_ID==', fldid['trf'][ifld]-1));
         gains:=coutref.getcol('GAIN');
         numspw:= gains::shape[3];
         for (ispw in [1:numspw]) {
            if ((!is_nan(sfluxd[ifld,ispw])) & (sfluxd[ifld,ispw] != 0)) {
               gains[,,ispw,]:= gains[,,ispw,] / sqrt (sfluxd[ifld,ispw]);
            };
         };
         coutref.putcol ('GAIN', gains);
         coutref.close();
      };

      # Done with output table so done it
      ctabout.done();

      return T;

   };
#-----------------------------------------------------------------------------
# LinPolCor - correct the antenna gains for linear polarization of the
# calibrator. Handles multiple spectral windows and calibrators.
# Use only for arrays with linear feeds and Alt-Az mounts (e.g., ATCA).
   public.linpolcor:=function(tablein,tableout,fields) {
     wider self;
     note('Correct the antenna gains for linear polarization of the secondary calibrators',
	  origin='calutil.g');
#  fit a sin curve to g22/g11 & deduce Q/I & U/I from that
#  abs(g22/g11)-1 ~ Q/I cos(2*PA) - U/I sin(2*PA), PA= position angle
# Open the calibration table  
     if (is_string(tablein)) {
       ctab:= table (tablein, ack=F);
     } else {
       return throw ('Invalid input calibration table specified');
     };
     include 'measures.g';
     include 'fitting.g';
     include 'statistics.g';
     maxant:= max (ctab.getcol('ANTENNA1'));
     numspw:= max (ctab.getcol('GAIN')::shape[3]);
     cdesc:=ctab.getcol('CAL_DESC_ID');
     cdesclist:=unique(cdesc);
     
     G:=ctab.getcol("GAIN");
     ant1col:=ctab.getcol("ANTENNA1");
     solutionok := ctab.getcol ('SOLUTION_OK');
     timcol := ctab.getcol("TIME");
     fieldidcol := ctab.getcol("FIELD_ID");
     ctab.done();

     
     fieldid := unique(fieldidcol);
     fieldtab := table(spaste(self.msfile,"/FIELD"),ack=F);
     fielddir := fieldtab.getcol("PHASE_DIR");
     fieldname := fieldtab.getcol("NAME");
     fieldtab.done();
     # figure out which fields to process
     if (length(fields)>0) {
       selmask :=array(F,length(fieldid));
       fields:=unique(fields);
       for (fld in fields) {
	 i:=0;
	 for (ifld in fieldid) {
	   i+:=1;
	   if (fieldname[ifld+1]==fld) selmask[i]:=T;
	 }
       }
       fieldid:=fieldid[selmask];
     }
     feedtab := table(spaste(self.msfile,"/FEED"),ack=F);
     receptor_angle := feedtab.getcol("RECEPTOR_ANGLE");
     feedtab.done();
     obstab := table(spaste(self.msfile,"/OBSERVATION"),ack=F);
     # NOTE: we may have >1 telescope, we ASSUME they're all the same
     telname :=obstab.getcol("TELESCOPE_NAME");
     obstab.done();
     pos:=dm.observatory(telname[1]);
     dm.doframe(pos);
     
     for (icdesc in cdesclist) {

       # spw selection now row-wise via CAL_DESC_ID
       spwsel:= (cdesc==icdesc)
       
       for (ifld in fieldid) {
	 ra := fielddir[1,1,ifld+1]; dec := fielddir[2,1,ifld+1];
	 d1:=dm.direction('j2000',dq.quantity(ra,'rad'),dq.quantity(dec,'rad'));
	 d2:=dm.direction('j2000',dq.quantity(0,'deg'),dq.quantity(90,'deg')); # NCP

	 #  accumulate net selection
	 sel := (ifld == fieldidcol) & spwsel & solutionok[1,1,];
	 if (sum(sel)>0) {

	   tim := timcol[sel]/86400.0;
#	   ant1 := ant1col[sel];
#          calculate X feed position angle on the sky
	   pa :=array(0,length(tim));
	   lasttm:=0; lastpa:=0;
	   ep := dm.epoch('UTC');
	   for (i in 1:length(tim)) {
	     if (tim[i] == lasttm) pa[i] := lastpa;
	     else {
	       lasttm:=tim[i];
	       ep.m0.value:=tim[i];
	       dm.doframe(ep);
	       d1azel:=dm.measure(d1,'azel');
	       d2azel:=dm.measure(d2,'azel');
#                  calculate posangle of X feed (assume all antennas identical)
	       pa[i]:=dm.posangle(d1azel,d2azel).value/180*pi+
		 receptor_angle[1,1];
	       lastpa:=pa[i];
	     }
	   }
	   ant1:=ant1col[sel];
	   g11:=G[1,1,1,1,sel];
	   g22:=G[2,2,1,1,sel];
	   ratio := abs(g22/g11)-1;
#  NOTE - The following solution disagrees with miriad which has opposite U
#  However, this solution makes the gain curve go flat if applied with setJy
#  in imager, so the problem must be elsewhere.
	   f:=dfs.compiled('-p0*cos(2*x)+p1*sin(2*x)+p2');
	   # remove offsets (x/y gain differences)
	   rat2:=ratio;
	   for (i in unique(ant1)) rat2[ant1==i]-:=mean(rat2[ant1==i]);;
	   dfit.linear(f,pa,rat2);
	   sol := dfit.solution();
	   err := dfit.error();
	   note ('Polarization for ',fieldname[ifld+1],
		 ' (spw=',ispw,') is (%Q,%U): ',
		 sprintf('(%5.2f,%5.2f) +/- (%5.2f,%5.2f)',
			 sol[1]*100,sol[2]*100,err[1]*100,err[2]*100),
		 origin='calutil.g');
#              correct gains - remove polarization signature
	   corr:=-sol[1]*cos(2*pa2)+sol[2]*sin(2*pa2);
	   g11*:=(1+0.5*corr);
	   g22*:=(1-0.5*corr);
	   G[1,1,1,1,sel]:=g11;
	   G[2,2,1,1,sel]:=g22;
	 }
       }
     }
     if (length(tableout) == 0 || strlen(tableout) == 0) tableout:= tablein;
     if (tablein == tableout) {
       ctabout:= table (tablein, readonly=F, ack=F);
     } else {
       tablecopy (tablein, tableout);
       ctabout:= table (tableout, readonly=F, ack=F);
     };
     ctabout.putcol("GAIN",G);
     ctabout.done();
     return T;
   }
   
#-----------------------------------------------------------------------------
# Plot function
#
   public.plotcal := function ( plottype, tablename, antennas, fields, 
      polarization, spwids, multiplot, nx, ny, psfile='') {
      #
      wider self;  
      prvt := [=];

      psfile := paste(psfile);
      if (strlen(psfile) == 0) {

	  # Create a pgplotter if one does not yet exist
	  if (!is_record(self.pgplotter)) {
	      include "pgplotter.g";
	      self.pgplotter := pgplotter();
          };
	  prvt.pgp := ref self.pgplotter;


	  # Ensure gui is present (in case user dismissed it before)
	  self.pgplotter.gui();

	  # clear any previous plotting commands:
	  self.pgplotter.clear();

          # manually reset the plot number (clear doesn't!)
          prvt.pgp.resetplotnumber();

	  # assume non-iteractive plot
	  if (! multiplot) self.pgplotter.ask(F);
      }
      else {
	  # write plot directly to file
	  include 'pgplotmanager.g';
	  prvt.pgp := pgplotps(psfile);
      }

      prvt.pgp.clear();

      # If multiplot, Set number of plots per page
      if (multiplot) {
        prvt.pgp.ask(T);
        prvt.pgp.subp(nx,ny);
      }

      # set big timeref, will be adjusted
      prvt.timeref:=1.0e64;

      # 
      # Define functions private to plotcal

      # Open the calibration tablename and load the data
      const prvt.open := function (tablename) {
         wider prvt;
         if ((strlen(tablename) == 0) || !tableexists(tablename)) {
            return throw ('No input calibration table specified');
         };

         ctab := table (tablename);
         ctabinfo := tableinfo (tablename);
    
         prvt.fulltype := ctabinfo.subType;
         subtype := split (prvt.fulltype);
         prvt.type := subtype[1];
         prvt.antenna1 := ctab.getcol ('ANTENNA1') + 1;
         prvt.fields := ctab.getcol('FIELD_ID') + 1;
	 prvt.cdesc:=ctab.getcol('CAL_DESC_ID')+1;
         prvt.time := ctab.getcol ('TIME');
         prvt.gain := ctab.getcol ('GAIN');
	 prvt.nchan:= shape(prvt.gain)[4];
         if (is_fail(prvt.gain)) {
            return throw ('Invalid data in calibration table');
         };

	 cdtab:=table(spaste(tablename,'/CAL_DESC'));
	 prvt.spws:=cdtab.getcol('SPECTRAL_WINDOW_ID')[1,]+1;
         prvt.npol := cdtab.getcol('N_JONES');
	 prvt.chrange:=cdtab.getcol('CHAN_RANGE')+1;
	 cdtab.done();

#         prvt.nspw := prvt.gain::shape[3];

         if (prvt.type == 'B') {
            prvt.nslot := prvt.gain::shape[5];
         } else {
            prvt.nslot := prvt.gain::shape[4];
         };
         prvt.solutionok := ctab.getcol ('SOLUTION_OK');
         prvt.fit := ctab.getcol ('FIT');
         prvt.fitwgt := ctab.getcol ('FIT_WEIGHT');
         prvt.totalsolutionok := ctab.getcol ('TOTAL_SOLUTION_OK');
         prvt.totalfit := ctab.getcol ('TOTAL_FIT');
         ctab.done();

         return T;
      };

      # Return the x-ordinate array for the specified plot type, with
      # sub-selection on spectral window id. and antenna.
      const prvt.getxarray := function (selectspw, selectant, selectfld) {
         wider prvt;

         prvt.xlabel := '';

         # Set mask based on antenna/timeslot selection
         tmask := rep (F, prvt.nslot);
         for (i in 1:len(selectant)) {
            antmask := (prvt.antenna1 == selectant[i]);
            tmask := (tmask | antmask);
         };
         antmask:=tmask;

         tmask := rep (F, prvt.nslot);
         for (i in 1:len(selectfld)) {
            fldmask := (prvt.fields == selectfld[i]);
            tmask := (tmask | fldmask);

         };
         fldmask:=tmask;

         tmask := rep (F, prvt.nslot);
         for (i in 1:len(selectspw)) {
            spwmask := (prvt.spws[prvt.cdesc] == selectspw[i]);
            tmask := (tmask | spwmask);

         };
         spwmask:=tmask;

         tmask:=spwmask&fldmask&antmask&prvt.timemask;

         # Set mask for bad solutions
	 mask := ((prvt.solutionok[1,,tmask]) & (prvt.fitwgt[1,,tmask]>0.0));

	 if (sum(mask)<1) return [];;


         # Set polarization indices
         p1 := prvt.pindex;
         p2 := prvt.pindex;
         if (prvt.type == 'D') p2 := -p1 + 3;

         # set default x-axis plotting options:
         prvt.xaxisopt:='BCNST';

         # case plottype of:
         #
         # TIME OR FREQUENCY AXIS:
         if (plottype == 'AMP' || plottype == 'amp' || 
             plottype == '1/AMP' || plottype == '1/amp' || 
             plottype == 'PHASE' || plottype == 'phase' ||
             plottype == 'RLPHASE' || plottype == 'rlphase' ||
             plottype == 'XYPHASE' || plottype == 'xyphase' ||
             plottype == 'DAMP' || plottype == 'damp' ||
             plottype == 'DPHASE' || plottype == 'dphase' ||
             plottype == 'FIT' || plottype == 'fit' ||
             plottype == 'FITWGT' || plottype == 'fitwgt' ||
             plottype == 'TOTALFIT' || plottype == 'totalfit') {
            if (prvt.type == 'B') {
	      chrange:=prvt.chrange[1,1,1,1]+ [1:prvt.nchan]
	      x := array(chrange,prvt.nchan,sum(tmask))[mask];
	      prvt.xlabel := 'Channel number';
            } else {
               x := prvt.time[tmask][mask];
               x0 := min (x);
               prvt.timeref:=min(prvt.timeref, 86400.0*floor(x0/86400.0));
               x := x - prvt.timeref;
               prvt.xlabel := 'Time';
               # make nice time plot:
               prvt.xaxisopt:='ZHBCNST';
            };

         #
         # REAL-IMAGINARY:
         } else if ( ( (plottype == 'RI' || plottype == 'ri' ) && 
                       (prvt.type != 'B')) ||
                     ( (plottype=='DRI' || plottype=='dri') && 
                       (prvt.type=='D') ) ) {
            prvt.xlabel := 'Real part';
            x := real (prvt.gain[p1, p2, 1,, tmask][mask]);
         #
         } else {
            return throw ('Invalid plot type in plotcal()');
         };
         return x;
      };
       
      # Return the y-ordinate array for the specified plot type, with
      # sub-selection on spectral window id. and antenna.
      const prvt.getyarray := function (selectspw, selectant, selectfld) {
         wider prvt;

         r2d := 180.0 / pi;
         prvt.ylabel := '';

         # Set mask based on antenna/timeslot selection
         tmask := rep (F, prvt.nslot);
         for (i in 1:len(selectant)) {
            antmask := (prvt.antenna1 == selectant[i]);
            tmask := (tmask | antmask);
         };
         antmask:=tmask;
         tmask := rep (F, prvt.nslot);
         for (i in 1:len(selectfld)) {
            fldmask := (prvt.fields == selectfld[i]);
            tmask := (tmask | fldmask);
         };
         fldmask:=tmask;

         tmask := rep (F, prvt.nslot);
         for (i in 1:len(selectspw)) {
            spwmask := (prvt.spws[prvt.cdesc] == selectspw[i]);
            tmask := (tmask | spwmask);

         };
         spwmask:=tmask;

         tmask:=spwmask&fldmask&antmask&prvt.timemask;

         # Set mask for bad solutions
	 mask := ((prvt.solutionok[1,,tmask]) & (prvt.fitwgt[1,,tmask]>0.0));

         # Set polarization indices
         p1 := prvt.pindex;
         p2 := prvt.pindex;
         if (prvt.type == 'D') p2 := -p1 + 3;


	 if (sum(mask)<1) return [];;


         # case plottype of:
         #
         # 'AMP':
         if (plottype == 'AMP' || plottype == 'amp') {
            prvt.ylabel := 'Amplitude';
	    y := abs (prvt.gain[p1, p2, 1,, tmask][mask]);
         #
         # '1/AMP':
         } else if (plottype == '1/AMP' || plottype == '1/amp') {
            prvt.ylabel := '1/Amplitude';
	    y := abs (prvt.gain[p1, p2, 1,, tmask][mask]);
            y[y!=0.0]:=1/y[y!=0.0];

         #
         # 'PHASE':
         } else if (plottype == 'PHASE' || plottype == 'phase') {
            prvt.ylabel := 'Phase (degrees)';
	    y := arg (prvt.gain[p1, p2, 1,, tmask][mask]) * r2d;

         #
         #
         # 'RLPHASE', 'XYPHASE':
         } else if (plottype == 'RLPHASE' || plottype == 'rlphase' ||
                    plottype == 'XYPHASE' || plottype == 'xyphase') {
            prvt.ylabel := 'Phase (degrees)';
	    y := (arg (prvt.gain[1, 1, 1,,tmask][mask]) - 
                  arg (prvt.gain[2, 2, 1,,tmask][mask])) * r2d;

         # 'DAMP':
         } else if ((plottype == 'DAMP' || plottype == 'damp') &&
                     prvt.type == 'D') {
            prvt.ylabel := 'Amplitude of D(1,2)+conj(D(2,1))';
            y := abs (prvt.gain[1,2,1,,tmask][mask] + 
               conj (prvt.gain[2,1,1,,tmask][mask]));
         #
         # 'DPHASE':
         } else if ((plottype == 'DPHASE' || plottype == 'dphase') &&
                     prvt.type == 'D') {
            prvt.ylabel := 'Phase of D(1,2)+conj(D(2,1))';
            y := arg (prvt.gain[1,2,1,,tmask][mask] + 
               conj (prvt.gain[2,1,1,,tmask][mask]));
         #
         # 'RI':
         } else if ((plottype == 'RI' || plottype == 'ri') &&
                    (prvt.type != 'B')) {
            prvt.ylabel := 'Imaginary part';
            y := imag (prvt.gain[p1, p2, 1,, tmask][mask]);
         #
         # 'DRI':
         } else if ((plottype == 'DRI' || plottype == 'dri') &&
                     prvt.type == 'D') {
            prvt.ylabel := 'Imaginary part';
            y := imag(prvt.gain[p1,p2,1,,tmask][mask]);

         #
         # 'FIT':
         } else if (plottype == 'FIT' || plottype == 'fit') {
            prvt.ylabel := 'Fit per spwid';
	    y := prvt.fit[1,1,tmask][mask];
         #
         # 'FITWGT':
         } else if (plottype == 'FITWGT' || plottype == 'fitwgt') {
            prvt.ylabel := 'Fit weight per spwid';
	    y := prvt.fitwgt[1,1,tmask][mask];
         #
         # 'TOTALFIT':
         } else if ((plottype == 'TOTALFIT' || plottype == 'totalfit') &&
                    (prvt.type != 'B')) {
            prvt.ylabel := 'Total fit';
            y := prvt.totalfit[1,1,tmask][mask];
         } else {
            return throw ('Invalid plot type in plotcal()');
         };
         return y;
      };

      const prvt.stretch := function (ref range) {
        delta := (range[2] - range[1]) * 0.05;
        absmax := max(abs(range));
        if (is_double(range)) {
           if (delta <= 1.0e-10*absmax) delta := 0.01 * absmax;
        } else {
           if (delta <= 1.0e-5*absmax) delta := 0.01 * absmax;
        }
        if (delta == 0.0) delta := 1;
        range[1] -:= delta;
        range[2] +:= delta;
      }

      #
      # Start of plotcal() main
      # 
      
      # Open the calibration table
      if (is_fail (prvt.open (tablename))) return F;

      # Do some consistency checks:

      # D* types only appropriate for Jones types with off-diag terms:
      if ( ( plottype=='DAMP'   || plottype=='damp' ||
             plottype=='DPHASE' || plottype=='dphase' || 
             plottype=='DRI'    || plottype=='dri' ) &&
           (prvt.type=='G' || prvt.type=='B' || prvt.type=='T') ) {
         return throw('Specified plottype inappropriate for Calibration table type.');
      }

      # Set the polarization index (1 or 2)
      prvt.pindex := max (polarization, 1);
      prvt.pindex := min (prvt.pindex, prvt.npol);

      # if 'B', check for more than one timeslot (chunk), then loop over them
      nchunk:=1;
      timelist:=unique(prvt.time);
      if (prvt.type=='B') {
	nchunk:=len(timelist);
	if (nchunk > 1) prvt.pgp.ask(T);;
	note(spaste('Found ',nchunk,' timestamps; will loop over them'));
      }

      for (timeslot in [1:nchunk]) {

	# Make timemask:
	if (prvt.type=='B') {
	  prvt.timemask:=rep(F,prvt.nslot);
	  prvt.timemask[prvt.time==timelist[timeslot]]:=T;
	} else {
	  prvt.timemask:=rep(T,prvt.nslot);
	}
	
	# Process the spectral window, antenna, field selection
	if (len(spwids) == 0) {
	  spw := prvt.spws;
	} else {
	  spw:=spwids;
	}
	
	if (len(antennas) == 0) {
	  listofants := unique(prvt.antenna1);
	} else {
	  listofants := antennas;
	};
	
	if (len(fields) == 0) {
	  listofflds := unique(prvt.fields);
	} else {
	  listofflds := fields;
	};
	
	
	# assume single plot, for the moment
	nplots:=1;
	ant:= ref listofants;
	fld:= ref listofflds;
	
	# Make field label:
	fldtxt:= spaste('Fields = ',fld);
	
	# process desire for multiple plots
	if (multiplot) {
#         nplots:=shape(listofants)*shape(listofflds);
	  nplots:=shape(listofants);
#         prvt.pgp.ask(T);
	} 
	
	# Find the overall (xmin,ymin) and (xmax,ymax)
	x := prvt.getxarray (spw, ant, fld);
	if (is_fail(x)) return F;
#
	range:= [min(x), max(x)];
	prvt.stretch (range);
	xmin := range[1]; xmax := range[2];
#
	y := prvt.getyarray (spw, ant, fld);
	if (is_fail(y)) return F;
#
	range:= [min(y), max(y)];
	prvt.stretch (range);
	ymin := range[1]; ymax := range[2];
	
	# only if overall selection yields points to plot
	if (shape(x)>0 && shape(y)>0) {
	  
	  for (iplt in seq(nplots) ) {
	    # select antenna if doing multiple plots
	    if (nplots > 1) {
#            fld:=listofflds[1+as_integer((iplt-1)/shape(listofants))];
#            ant:=listofants[1+(iplt-1)%shape(listofants)];
	      ant:=listofants[iplt];
	    }
	    
	    # only proceed if something to plot for this iplt:
	    if (shape(prvt.getxarray(spw,ant,fld))>0) {
	      
	      # Create the pgplotter frame
	      prvt.pgp.sch(1.0);
	      prvt.pgp.sci (1);
	      prvt.pgp.page();
	      # construct viewport with space for legend
	      prvt.pgp.svp(0.075,0.825,0.1,0.9);
	      prvt.pgp.swin(xmin,xmax,ymin,ymax);
	      prvt.pgp.tbox(prvt.xaxisopt,0.0,0,'BCNST',0.0,0)
		
		title := spaste ('Table= ', tablename, '   Type= ', prvt.fulltype,
				 '   Polarization= ', prvt.pindex);
	      prvt.pgp.lab (prvt.xlabel, prvt.ylabel, title);      
	      
	      # For B, add timestamp info to plot
	      if (prvt.type=='B') {
		timestring:=dq.time(dq.quantity(timelist[timeslot],'s'),form='ymd');
		timestamp:=spaste('Time=',timestring);
		prvt.pgp.mtxt('T',0.5,0.005,0.0,timestamp);
	      }
	      
	      prvt.pgp.mtxt('T',0.5,0.5,0.5,fldtxt);
	      prvt.pgp.slw (5);
	      
	      # Loop over spectral window id. and antenna
	      legend := [=];
	      ientry := 1;
	      ncolor := 8;    # prvt.pgp.qcir()[1];
	      
	      for (iant in ant) {
		for (ispw in spw) {
		  # Find out how many points for this spw, ant (all fields)
		  x := prvt.getxarray (ispw, iant, fld);
		  if (len(x) > 0) {
		    # Set color index
		    ci := 1+ (ientry % (ncolor-1));
		    if (ci == 0) ci := ncolor - 1;
		    # Add legend table entries
		    legend[ientry] := [=];
		    legend[ientry].ant := iant;
		    legend[ientry].spw := ispw;
		    legend[ientry].color := ci;
		    ientry := ientry + 1;
		    prvt.pgp.sci (ci);
		    for (ifld in fld) {
		      x := prvt.getxarray (ispw, iant, ifld);
		      if (is_fail(x)) return F;
		      y := prvt.getyarray (ispw, iant, ifld);
		      if (is_fail(y)) return F;
		      if (len(x) > 0) {
			prvt.pgp.pt (x, y, 1);
		      };
		    };
		  };
		};
	      };
	      
	      
	      # Draw legend
	      
	      if (len(legend) > 0) {
		prvt.pgp.slw (1);
		# Adjust character height so legend fits
		charh:=min(1.0, 40.0/1.25/len(legend));
		prvt.pgp.sch(charh);
		
		#  should use 'mtxt' instead of 'txt' here so that
		#  zoomed plots show legend, too
		
		# vertical spacing for legend
		deltay := 1.25 * (ymax - ymin) * prvt.pgp.qch() / 40.0;
		for (i in 1:len(legend)) {
		  x:=xmax + 0.02*(xmax-xmin);
		  y := ymax - (i-0.4) * deltay;
		  prvt.pgp.sci (legend[i].color);
		  txt := spaste ('Ant_', legend[i].ant, ' Spw_', legend[i].spw);
		  prvt.pgp.text (x, y, txt);
		};
	      };
	    }  # if something to plot for one of many plots
	    
	    
	  };  # loop over antenna plots
	} else {
	  return throw ('Nothing to plot for specified selection.');
	}
	
      }  # chunks
      
      if (strlen(psfile) > 0) {
	prvt.pgp.done();
      }
      
      return T;
    };

#-----------------------------------------------------------------------------
# Method: calave
#
   public.calave:=function(tablein=F,tableout=F,
                           fldsin=F,spwsin=F,
                           fldsout=F,spwout=F,
                           t=0.0,
                           append=F,
                           mode='RI',verbose=T) {

     local cpriv:=[=];

     include 'table.g'
     include 'quanta.g'

     # Check inputs:
     if (is_boolean(fldsout)) {
       return throw('An output field id must be specified.');
     }
     if (is_boolean(spwout)) {
       return throw('An output spectral window id must be specified.');
     }
     
     if (!is_string(tablein)) {
       return throw('Please specify an input table name as a string.')
     } else {
       if (!tableexists(tablein) || tableinfo(tablein).type!='Calibration') {
	 return throw(spaste(tablein,' does not exist or is not a Calibration table.'));
       }
     }
     
     if (!is_string(tableout)) { 
       return throw('Please specify an output table name as a string.')
     } else {
       if (tableexists(tableout) && !append) {
	 return throw(spaste(tableout,' already exists. Please specify a new name or append=T.'));
       }
       if (tableout == tablein) {
	 return throw('Please specify new name for tableout!');
       }
     }
     
  # Required parameters ok, process them
     cpriv.fldsout:=fldsout;
     cpriv.spwout:=spwout;
     cpriv.tablein:=tablein;
     cpriv.tableout:=tableout;
     cpriv.avetime:=t;
     cpriv.mode:=mode;
  
     if (cpriv.avetime > 0) {
        note(spaste('Averaging solutions on timescale (seconds) = ',cpriv.avetime));
     } else {
        cpriv.avetime:=0.0;
        note('Averaging timescale <= 0.0; only copying solutions.');
     };

     cpriv.spwinout:=unique([spwsin,spwout]);

     # Get some info from CAL_DESC:
     ctdesc:=table(spaste(tablein,'/CAL_DESC'),ack=F);
     cpriv.nspw:=unique(ctdesc.getcol('NUM_SPW'));

     # Catch complicated tables
     if (shape(cpriv.nspw)>1) {
       return throw('Found more than one count of spectral windows! Sorry!');
     }

     cpriv.nchan:=ctdesc.getcol('NUM_CHAN');
     if (prod(shape(cpriv.nchan))> 1) {
       cpriv.nchan:=unique(cpriv.nchan[cpriv.spwinout]);
     } else {
       cpriv.nchan:=unique(cpriv.nchan);
     };

     # Catch faulty consideration of varying shape windows
     if (shape(cpriv.nchan)>1) {
       return throw('Found more than one count of chan_num in selected spectral windows! Sorry!');
     }
     cpriv.allspws:=ctdesc.getcol('SPECTRAL_WINDOW_ID')
     ctdesc.done();

     # Open/create in/out tables
     cpriv.ctin:=table(tablein);
     if (!append) tablecopy(tablein,tableout,deep=T);
     cpriv.ctout:=table(tableout,readonly=F);
     if (append) {
       note(spaste('Appending solution averages to table=',tableout));
       cpriv.startrow:=cpriv.ctout.nrows()+1;
     }
     else {
     # remove all (copied) rows
       cpriv.ctout.removerows(rownrs=[1:cpriv.ctout.nrows()]);
       cpriv.startrow:=1;
     }

     # Finish processing parameters
     if (is_boolean(spwsin)) {
       cpriv.spwsin:=[1:cpriv.nspw];
     } else {
       cpriv.spwsin:=spwsin;
     }
     if (is_boolean(fldsin)) {
       cpriv.fldsin:=unique(cpriv.ctin.getcol('FIELD_ID'));
     } else {
       cpriv.fldsin:=fldsin;
     }

     # if only one fldsout specified, replicate to shape of fldsin
     if (shape(cpriv.fldsout)==1) cpriv.fldsout:=rep(cpriv.fldsout,shape(cpriv.fldsin));

     # All parameters and tables ready at this point

     note('Field processing will be: ');
     for (i in 1:shape(fldsin)) {
       note(spaste('   ',fldsin[i],' -> ',fldsout[i]));
     }

     note('Spectral window processing will be: ');
     for (i in 1:shape(spwsin)) {
       note(spaste('   ',spwsin[i],' -> ',spwout));
     }

     # Select relevant part of input table: 
     cpriv.st:=cpriv.ctin.query(spaste('FIELD_ID IN ',as_evalstr(cpriv.fldsin-1)));

     # Get full list of antennas in selected part of table:
     cpriv.allants:=sort(unique(cpriv.st.getcol('ANTENNA1')));
     cpriv.nallants:=shape(cpriv.allants);

     # set up iterator over TIME
     cpriv.stiter:=tableiterator(cpriv.st,"TIME")
     cpriv.stiter.reset();

     cpriv.newgain:=F;
     cpriv.ngfull:=F;
     cpriv.newtimeslot:=T;
     cpriv.thisfldsout:=-1;
     cpriv.lastfldsout:=-1;
     cpriv.done:=F;
     while (!cpriv.done) {

       cpriv.done:=!cpriv.stiter.next();

       cpriv.lastfldsout:=cpriv.thisfldsout;

       cpriv.thischunk:=[=];
       if (!cpriv.done) {
	 cpriv.thischunk:=cpriv.stiter.table();
	 cpriv.chrows:=cpriv.thischunk.nrows();

         # Get antenna list for this timestamp and index list
         thisants:=cpriv.thischunk.getcol('ANTENNA1');
         thisnants:=shape(thisants);
         thisantidx:=array(0,thisnants);
	 for (i in 1:thisnants) {
	   cpriv.thisantidx[i]:=ind(cpriv.allants)[cpriv.allants==thisants[i]];
	 }
	 
         # Get fieldid info for this chunk:
	 cpriv.thisfld:=unique(cpriv.thischunk.getcol('FIELD_ID'))+1;
	 if (shape(cpriv.thisfld)>1) {
	   return throw('More than one field in a single timestamp!');
	 }
	 cpriv.thisfldsout:=cpriv.fldsout[ind(cpriv.fldsin)[cpriv.fldsin==cpriv.thisfld]];

         # this time stamp
	 cpriv.thistime:=cpriv.thischunk.getcol('TIME',1,1);

         # check this time against interval and fldsout changes
	 if (!cpriv.newtimeslot) {
	   cpriv.newtimeslot:=((cpriv.thistime-cpriv.mintime) > cpriv.avetime) || (cpriv.thisfldsout != cpriv.lastfldsout);
	 } 
	 
         # store minimum time 
	 if (cpriv.newtimeslot) {
	   cpriv.mintime:=cpriv.thistime;
	   cpriv.newtimeslot:=F;
	   
           # set cpriv.ngfull (to trigger process and write)
	   if (!is_boolean(cpriv.newgain)) cpriv.ngfull:=T;
	 }
       }

       # if previous timeslot full, or past end of input table
       #   process and write this cpriv.newgain slot
       if (cpriv.ngfull | cpriv.done ) {

       # accumulate into cpriv.spwout
	 for (ispw in cpriv.spwsin) {
	   if (ispw!=cpriv.spwout & cpriv.spwwt[ispw]>0) {
             # accumulate this ispw into cpriv.spwout slot
             #   (maybe something there already)
	     cpriv.newgain[,,cpriv.spwout,,]+:=cpriv.newgain[,,ispw,,];
	     if (cpriv.mode=='AP') {
	       cpriv.newgainamp[,,cpriv.spwout,,]+:=cpriv.newgainamp[,,ispw,,];
	       cpriv.newgainpha[,,cpriv.spwout,,]+:=cpriv.newgainpha[,,ispw,,];
	     }
	     cpriv.newfwt[cpriv.spwout,,]+:=cpriv.newfwt[ispw,,];
	     cpriv.spwtime[cpriv.spwout]+:=cpriv.spwtime[ispw];
	     cpriv.spwwt[cpriv.spwout]+:=cpriv.spwwt[ispw];

             # normalize this (input) ispw:
	     for (ipol in [1,2]) {
	       cpriv.newgain[ipol,ipol,ispw,,]/:=cpriv.newfwt[ispw,,];
	       if (cpriv.mode=='AP') {
		 cpriv.newgainamp[ipol,ipol,ispw,,]/:=cpriv.newfwt[ispw,,];
		 cpriv.newgainpha[ipol,ipol,ispw,,]/:=cpriv.newfwt[ispw,,];
		 cpriv.newgain[ipol,ipol,ispw,,]:=cpriv.newgainamp[ipol,ipol,ispw,,]*cpriv.newgainpha[ipol,ipol,ispw,,]/abs(cpriv.newgainpha[ipol,ipol,ispw,,]);
	       }
	     }
	     cpriv.spwtime[ispw]/:=cpriv.spwwt[ispw];
	   }
	 }

         # normalize cpriv.spwout:
	 for (ipol in [1,2]) {
	   cpriv.newgain[ipol,ipol,cpriv.spwout,,]/:=cpriv.newfwt[cpriv.spwout,,];
	   if (cpriv.mode=='AP') {
	     cpriv.newgainamp[ipol,ipol,cpriv.spwout,,]/:=cpriv.newfwt[cpriv.spwout,,];
	     cpriv.newgainpha[ipol,ipol,cpriv.spwout,,]/:=cpriv.newfwt[cpriv.spwout,,];
	     cpriv.newgain[ipol,ipol,cpriv.spwout,,]:=cpriv.newgainamp[ipol,ipol,cpriv.spwout,,]*cpriv.newgainpha[ipol,ipol,cpriv.spwout,,]/abs(cpriv.newgainpha[ipol,ipol,cpriv.spwout,,]);

	   }
	 };

	 cpriv.spwtime[cpriv.spwout]/:=cpriv.spwwt[cpriv.spwout];
	 
         if (verbose) {
	    note('---------------------------------------------------');	
	    note(spaste('Writing solutions at time=',dq.time(dq.quantity(cpriv.spwtime[cpriv.spwout],'s'))));	
	    note(spaste('                for field=',cpriv.lastfldsout));
	    note(spaste('                   in spw=',cpriv.spwout));
            note('===================================================');
         }
	   
         # restore proper shape for gain:
	 cpriv.newgain::shape := cpriv.sg;
	 cpriv.newfwt::shape := cpriv.sw;
         sok:=(cpriv.newfwt>0);
         fit:=as_integer(sok);

         # how many rows to append?
         nrowout:=cpriv.sg[shape(cpriv.sg)];

         # add (empty) rows to output table
	 cpriv.ctout.addrows(nrowout);

         # write out relevant columns
	 cpriv.ctout.putcol('GAIN',cpriv.newgain,cpriv.startrow,nrowout,1);
	 cpriv.ctout.putcol('FIT_WEIGHT',cpriv.newfwt,cpriv.startrow,nrowout,1);
	 cpriv.ctout.putcol('TIME',rep(cpriv.spwtime[spwout],nrowout),cpriv.startrow,nrowout,1);
	 cpriv.ctout.putcol('FIELD_ID',rep(cpriv.lastfldsout-1,nrowout),cpriv.startrow,nrowout,1);
	 cpriv.ctout.putcol('ANTENNA1',cpriv.allants,cpriv.startrow,nrowout,1);
	 cpriv.ctout.putcol('SOLUTION_OK',sok,cpriv.startrow,nrowout,1);
	 cpriv.ctout.putcol('TOTAL_SOLUTION_OK',rep(T,nrowout),cpriv.startrow,nrowout,1);
	 cpriv.ctout.putcol('TOTAL_FIT_WEIGHT',rep(1.0,nrowout),cpriv.startrow,nrowout,1);
	 cpriv.ctout.putcol('INTERVAL',rep(cpriv.avetime,nrowout),cpriv.startrow,nrowout,1);
	 cpriv.ctout.putcol('FIT',fit,cpriv.startrow,nrowout,1);
	 cpriv.ctout.putcol('TOTAL_FIT',rep(1.0,nrowout),cpriv.startrow,nrowout,1);

         # Adjust startrow for next batch
	 cpriv.startrow+:=nrowout;

         # Trigger accumulation of next batch
	 cpriv.ngfull:=F;
	 cpriv.newgain:=F;
       }

       if (!cpriv.done) {

         if (verbose) {
	    note(spaste('Reading solutions at time=',dq.time(dq.quantity(cpriv.thistime,'s'))));
	    note(spaste('                for field=',cpriv.thisfld));
         }

         # get gains and weights
	 cpriv.thisgain:=cpriv.thischunk.getcol('GAIN');
	 cpriv.fwt:=cpriv.thischunk.getcol('FIT_WEIGHT');

	 cpriv.sg:=shape(cpriv.thisgain);
	 cpriv.sw:=shape(cpriv.fwt);
	 cpriv.sgch:= ref cpriv.sg;
	 cpriv.swch:= ref cpriv.sw;
         # Add degenerate channel axis so indexing uniform throughout
	 if (shape(cpriv.sg)==4) {
	   cpriv.sgch:=[cpriv.sg[1:3],1,cpriv.sg[4]];
	   cpriv.swch:=[cpriv.sw[1],1,cpriv.sw[2]];
	   cpriv.thisgain::shape := cpriv.sgch;
	   cpriv.fwt::shape := cpriv.swch;
	 }

	 if (is_boolean(cpriv.newgain)) {

           # refresh all accumulating vars
	   cpriv.newgain:=array(0+0i,2,2,cpriv.nspw,cpriv.nchan,cpriv.nallants);
	   if (cpriv.mode=='AP') {
	     cpriv.newgainamp:=array(0,2,2,cpriv.nspw,cpriv.nchan,cpriv.nallants);
	     cpriv.newgainpha:=array(0+0i,2,2,cpriv.nspw,cpriv.nchan,cpriv.nallants);
	   }
	   cpriv.newfwt:=array(0.0,cpriv.nspw,cpriv.nchan,cpriv.nallants);
	   cpriv.spwtime:=array(0.0,cpriv.nspw);
	   cpriv.spwwt:=array(0,cpriv.nspw);
	 }

	 for (ispw in cpriv.spwsin) {
	   spwwt:=sum(cpriv.fwt[ispw,,]);
	   if (spwwt>0.0) {
             if (verbose) {
	        note(spaste('                   in spw=',ispw));
             }
             # accumulate weighted gains (each pol) and weights
	     for (ipol in [1,2]) {
	       cpriv.newgain[ipol,ipol,ispw,,[cpriv.thisantidx]]+:=cpriv.fwt[ispw,,]*cpriv.thisgain[ipol,ipol,ispw,,];
	       if (cpriv.mode=='AP') {
		 cpriv.newgainamp[ipol,ipol,ispw,,[cpriv.thisantidx]]+:=cpriv.fwt[ispw,,]*abs(cpriv.thisgain[ipol,ipol,ispw,,]);
		 cpriv.newgainpha[ipol,ipol,ispw,,[cpriv.thisantidx]]+:=cpriv.fwt[ispw,,]*cpriv.thisgain[ipol,ipol,ispw,,]/abs(cpriv.thisgain[ipol,ipol,ispw,,]);
	       }
	     }
	     cpriv.newfwt[ispw,,]+:=cpriv.fwt[ispw,,];

             # accumulate per-spw weight and time for this chunk
	     cpriv.spwwt[ispw]+:=spwwt;
	     cpriv.spwtime[ispw]+:=spwwt*cpriv.thistime;
	   }
	 }
       }

       if(is_table(cpriv.thischunk)) cpriv.thischunk.done();

     } # while (!done);

     # Clean up
     cpriv.stiter.done();
     if (is_table(cpriv.st)) cpriv.st.done();
     if (is_table(cpriv.ctin)) cpriv.ctin.done();
     if (is_table(cpriv.ctout)) cpriv.ctout.done();

     return T;
			   
   }

#-----------------------------------------------------------------------------
# Method: posangcal
#
   public.posangcal:=function(tablein='',
                              tableout='',
                              posangcor=[]) {

     include 'ms.g';
     include 'table.g';
     include 'matrix.g';

     local papriv:=[=];

     papriv.tablein:=tablein
     papriv.tableout:=tableout
     papriv.posangcor:=posangcor;

     note('Beginning position angle calibration.');

     # Check inputs:
     if (len(papriv.posangcor)==0 || all(papriv.posangcor==0.0)) {
        return throw('Please specify non-zero posangcor value(s).');
     };
     
     if (!is_string(papriv.tablein) || strlen(papriv.tablein)==0) {
       return throw('Please specify an input table name as a string.')
     };
     if (!tableexists(papriv.tablein) || tableinfo(papriv.tablein).type!='Calibration') {
	 return throw(spaste(papriv.tablein,' does not exist or is not a Calibration table.'));
     };


     if (!is_string(papriv.tableout)) {
       # non-string specified
       return throw('Please specify an output table name as a string.')
     } else {
       # string specified
       if (strlen(papriv.tableout)==0 || (papriv.tableout==papriv.tablein)) { 
         # empty or same string specified, use input table
         papriv.tableout:=papriv.tablein;
         note('Performing correction in place on input table.');
       } else {
         # unique non-empty string specified
         if (tableexists(papriv.tableout)) {
             # output table already exists, exit to avoid overwrite
	     return throw(spaste(papriv.tableout,' already exists. Please specify a new name.'));
         } else {
           # copy input table to output table 
           tablecopy(papriv.tablein,papriv.tableout,deep=T);
         };
       } 
     };

     # discern polarization setup from MS
     papriv.ms:=ms(self.msfile);
     papriv.pols:=paste(papriv.ms.range("corr_names").corr_names);
     papriv.ms.done();
     papriv.docirc:=papriv.pols ~ m/R|L/;
     papriv.dolin:=papriv.pols ~ m/X|Y/;
     
     # Avoid case of mixed polarizations for now
     if (papriv.docirc & papriv.dolin) {
       return throw('Found both circulars and linears. Cannot handle this yet.');     
     };

     if (papriv.docirc) {
       note('Performing correction for circularly polarized basis.');
     };

     if (papriv.dolin) {
       note('Performing correction for linearly polarized basis.');
     };

     # Open output cal table
     papriv.table:=table(papriv.tableout,readonly=F,ack=F);

     # Discern structure of gain column:
     papriv.g:=papriv.table.getcol('GAIN');
     papriv.gshp:=shape(papriv.g);
     papriv.ndim:=shape(papriv.gshp);
     papriv.nrow:=papriv.gshp[papriv.ndim];
     papriv.nspw:=papriv.gshp[papriv.ndim-1];

     if (len(papriv.posangcor)==1 && papriv.nspw>1) {
       papriv.posangcor:=array(papriv.posangcor,papriv.nspw);
     };

     if (len(papriv.posangcor) != papriv.nspw) {
       return throw('Please specify one posangcor value for each spectral window.');
     };

     note(spaste('Rotating position angle by ',as_evalstr(papriv.posangcor),'degrees in spw ',as_evalstr(seq(papriv.nspw))));

     # Change angles to radians
     papriv.posangcor*:=pi/180;

     # Form pos angle Jones matrix:
     papriv.pacor:=array(0+0i,2,2,papriv.nspw);
     for (ispw in [1:papriv.nspw]) {
       if (papriv.docirc) {
         papriv.pacor[1,1,ispw]:=complex(cos(-papriv.posangcor[ispw]),sin(-papriv.posangcor[ispw]));
         papriv.pacor[2,2,ispw]:=conj(papriv.pacor[1,1,ispw]);
       };
       if (papriv.dolin) {
         papriv.pacor[1,1,ispw]:=cos(-papriv.posangcor[ispw]);
         papriv.pacor[1,2,ispw]:=-sin(-papriv.posangcor[ispw]);
         papriv.pacor[2,2,ispw]:=papriv.pacor[1,1,ispw];
         papriv.pacor[2,1,ispw]:=-papriv.pacor[1,2,ispw];
       };
     };

     # apply correction to each row and spw
     for (irow in [1:papriv.nrow]) {
       for (ispw in [1:papriv.nspw]) {
         papriv.g[,,ispw,irow]:=mx.mult(papriv.g[,,ispw,irow],papriv.pacor[,,ispw]);
       };
     };

     # Write corrected column into gain table
     note(spaste('Writing corrections to table=',papriv.tableout));
     papriv.table.putcol('GAIN',papriv.g);

     # Clean up:
     papriv.table.done();
     papriv:=[=];

     note('Finished position angle calibration.');

     return T;

  };  # end of posangcal


#-----------------------------------------------------------------------------
# Method: close
#
   public.close := function () {
      wider self;
      return T;
    };

#-----------------------------------------------------------------------------
# Method: type
#
    public.type := function() {
	return 'calutil';
    };

#-----------------------------------------------------------------------------
# Method: done
#
    public.done := function() {
       wider self, public;

       # if exists, done pgplotter
       if (!is_boolean(self.pgplotter) ) self.pgplotter.done();

       self := F;
       val public := F;
       return T;
    };

#-----------------------------------------------------------------------------

   return public;

} #_define_calutil()

##############################################################################
# Constructor for calutil object
#
const calutil:= function (msfile) {
   return _define_calutil (msfile);
};

##############################################################################
# Test script
#
const calutiltest:= function () {
   fail "Not yet implemented"
};

##############################################################################
# Demo script
#
const calutildemo:= function () {
   fail "Not yet implemented"
};

##############################################################################


