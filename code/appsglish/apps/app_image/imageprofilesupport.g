# imageprofilesupport.g: profile plotting support
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003,2004
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
#   $Id: imageprofilesupport.g,v 19.9 2004/08/25 00:59:29 cvsmgr Exp $
#


pragma include once

include 'coordsys.g'
include 'note.g'
include 'pgplotter.g'
include 'pgplotwidget.g'
include 'quanta.g'
include 'quantumentry.g'
include 'serverexists.g'
include 'unset.g'
include 'widgetserver.g'


const imageprofilesupporttest := function(which=unset, destroy=T)
{
    include 'imageprofilesupport_test.g'
    return imageprofilesupport_test(which=which, destroy=destroy)
}



const imageprofilesupport := subsequence (csys, shp, widgetset=dws,
                                          multiabcissa=F, offset=F)
{
    if (!serverexists('dq', 'quanta', dq)) {
       return throw('The quanta server "dq" is not running',
                    origin='imageprofilesupport.g');
    }

# Define pixel units for quanta

    ok := dq.define('pix', "100%");
    if (is_fail(ok)) fail;
#
    its := [=];
#
    its.lists := [=];
    its.lists.doppler := "RADIO OPTICAL TRUE";
    its.lists.specRef := "LSRK LSRD BARY GEO TOPO GALACTO";
#
    its.csys := [=];                    # Coordinate system
    its.yRangeCallback := [=];          # Function to provide a y min/max
    its.multi := multiabcissa;          # Indicates whether we are in multi abcissa 
                                        # mode  (1 abcissa per ordinate per mask)
                                        # or not (1 abcissa but many ordinates & masks)
    its.hasOffset := offset;            # Do we present the offset entry capability ?
#
    its.hiddenRec := [=];               # Holds hidden Tk agents; the offset widgets
                                        # may not be required.  We handle that by
                                        # building and hiding them rather than
                                        # squillions of 'if' statements
#
    its.rec := [=];                     # Holds Tk agents
    its.madeWidgets := F;                 # Have we made the x-unit menus ?
    its.xAxisUnit := [=];               # X-unit menu
    its.absrelMenu := [=];              # Absrel type menu
    its.dopplerMenu := [=];             # Doppler type menu
    its.dopplerMenuIsDisabled := T;
    its.spectralRefMenu := [=];             # Velocity reference frame menu
    its.spectralRefMenuIsDisabled := T;     # T if permanently disabled
#
    its.offsetValueEntry := [=];        # Offset value entry
    its.offsetValueEntryIsDisabled := T;      
    its.offsetDopplerMenu := [=];       # Offset doppler type menu
    its.offsetDopplerMenuIsDisabled := T;
#
    its.plot.title := [=];
    its.plot.title.text := "";          # Text for plot title
    its.plot.title.ci := [];            # Colour indices for each string
    its.plot.charsize := 1.7;           # PGPlot character size
#
    its.plotter := [=];                 # PGPlotter
    its.pgframe := [=];                 # Frame from within pgplotter
    its.standAlone := T;                # Is plotter pgplotter (T) or pgplotwidget (F)
    its.canDestroyPlotter := T;         # F if user provided plotter via setplotter
#
    its.profile := [=];
    its.profile.axis := -1;             # The current profile pixel axis
    its.profile.oldaxis := -1;          # The previous profile pixel axis
#
    its.profile.npoints := [=];         # How many points in each profile
                                        # Either npoints[1] (multi=F) or npoints[1:n] (multi=T)
#
    its.profile.x := [=];               # Profile abcissa
    its.profile.x.data := [=];          # Either data[1] (multi=F) or data[1:n] (multi=T)
#    its.profile.x.data[i].pixel := [=];         # Abcissa, pixels
#    its.profile.x.data[i].pixel.abs := [];      #    Absolute
#    its.profile.x.data[i].pixel.rel := [];      #    Relative
#    its.profile.x.data[i].nativeworld := [=];   # Abcissa, native world coordinates
#    its.profile.x.data[i].nativeworld.abs := [];#   Absolute
#    its.profile.x.data[i].nativeworld.rel := [];#   Relative
#    its.profile.x.data[i].current := [];        # Abcissa actually plotted
#
    its.profile.x.name := '';              # Axis name of abcissa
    its.profile.x.nativeunit := '';        # Native units of abcissa
#
    its.profile.x.currentunit := '';       # Unit of current abcissa
    its.profile.x.currentdoppler := '';    # Velocity type of current abcissa
    its.profile.x.currentSpecRef := '';    # Spectral reference frame of current abcissa
    its.profile.x.currentabs := T;         # Abs/rel type of current abcissa
    its.profile.x.currentOffValue := dq.quantity('0');         # Offset value of current plot
    its.profile.x.currentOffDoppler := its.lists.doppler[1];   # Offset doppler of current plot
#
    its.profile.x.prevPlotUnit := '';    # Unit of previous plot abcissa
    its.profile.x.prevPlotDoppler := ''; # Doppler of previous plot
    its.profile.x.prevPlotSpecRef := ''; # Spectral reference frame of previous plot
    its.profile.x.prevPlotAbs := T;      # Abs/rel type of previous plot
    its.profile.x.prevPlotOffsetValue := 0.0;    # Offset value of previous plot
    its.profile.x.prevPlotOffsetDoppler := '';   # Offset doppler of previous plot
#
    its.profile.x.isSpectral := F;      # Is the coordinate of the x-axis Spectral
#
    its.profile.y := [=];               # Profile ordinates
    its.profile.y.unit := '';           # Brightness units
    its.profile.y.data := [=];          # Profiles. can have many data[1], data[2]
    its.profile.y.err := [=];           # Profiles errors. Can have many err[1], err[2]
    its.profile.y.ci := [];             # Colour index for each y profile
    its.profile.y.ls := [];             # Line style for each y profile
#
    its.profile.mask := [=];            # Profile masks, one per ordinate.
#
    its.profile.xrange := [];
    its.profile.yrange := [];
    its.profile.autoscale := [F,T];
    its.profile.which := unset;         # Which profiles were plotted last time
#

### Private methods

   const its.absPixToAbsWorld := function (n=unset, pix=unset, pos)
   {
      wider its;
#
      local absPix;
      if (!is_unset(n)) {
         absPix := array(pos, length(pos), n);
         absPix[its.profile.axis,] := 1:n;
      } else if (!is_unset(pix)) {
         absPix := array(pos, length(pos), length(pix));
         absPix[its.profile.axis,] := pix;
      } 
#
      return its.csys.toworldmany(absPix);
   }      

###
   const its.absWorldToRelWorld := function (nativeAbsWorld)
   {
      wider its;
#
      p2w := its.csys.axesmap(T);      # Map from pixel to world 
      worldprofileaxis := p2w[its.profile.axis];
      rv := its.csys.referencevalue();
#      
      n := length(nativeAbsWorld);
      t := array(rv, length(rv), n);
      t[worldprofileaxis,] := nativeAbsWorld;
      r := its.csys.torelmany(t, T);
      if (is_fail(r)) fail;
      return r[worldprofileaxis,];
   }


###
   const its.checkWhich := function (which, abcissa)
   {
      wider its;
#
      if (is_unset(which)) which := 1;
#
      n := self.nprofiles();
      if (n==0) {
         return throw ('There are no profiles available',  
                      origin='imageprofilesupport.checkWhich');
     }
#
      if (its.multi) {
         if (which<1 || which>n) {
            note ('Illegal profile requested - returning first',  priority='WARN',
                  origin='imageprofilesupport.checkWhich');
            which := 1;
         }
      } else {
         if (abcissa) {
            if (which!=1) {
               note ('Illegal profile requested - only one is available',  priority='WARN',
                     origin='imageprofilesupport.checkWhich');
            }
            which := 1;
         } else {
            if (which<1 || which>n) {
               note ('Illegal profile requested - returning first',  priority='WARN',
                     origin='imageprofilesupport.checkWhich');
            }
            which := 1;
         }
      }
#
      return which;
   }

###
   const its.convert := function (ref doTime, ref xOpt, ref xLab)
#
# This is the main workhorse function.  It assesses whether the requested
# plot is different from the previous plot.  If it is, it computes
# the requested abcissa vectors.  
#
   {
      wider its;      

# Find out what we want to plot

      profileAxis := its.profile.axis;
      xUnitCurr := its.profile.x.currentunit;           # Current abcissa unit
      xUnitCurr2 := to_upper(xUnitCurr);                
#
      xUnitReq := its.xAxisUnit.getlabel();             # Required abcissa unit
      xUnitReq2 := to_upper(xUnitReq);            
      xUnitNative := its.profile.x.nativeunit;          # Native abcissa unit
#
      xUnitIsVelocity := dq.check(xUnitReq) &&          # 'units' like DMS are not legal
                         dq.compare(xUnitReq,'km/s');   # quanta units
      if (is_fail(xUnitIsVelocity)) fail;
      xUnitIsFrequency := dq.check(xUnitReq) && 
                         dq.compare(xUnitReq,'Hz');
      if (is_fail(xUnitIsFrequency)) fail;
#
      offsetValueCurr := its.profile.x.currentOffValue;        # Current offset
      offsetValueReq := its.offsetValueEntry.get(reread=T);    # Required 
      if (is_illegal(offsetValueReq) || is_unset(offsetValueReq)) {
         note ('Invalid value in offset entry box; using 0', priority='SEVERE',
               origin='imageprofilesupport.convert');
         its.offsetValueEntry.insert(0.0, emit=F);
         offsetValueReq := its.offsetValueEntry.get();      # Required 
      }
#
      specRefCurr := ''; specRefReq := '';
      dopplerCurr := ''; dopplerReq := ''; 
      offsetDopplerCurr := ''; offsetDopplerReq := '';
      if (its.profile.x.isSpectral) {
         dopplerCurr := its.profile.x.currentdoppler;     # Current doppler
         dopplerReq := its.dopplerMenu.getlabel();        # Required 
#
         specRefCurr := its.profile.x.currentSpecRef;     # Current spectral reference 
         specRefReq := its.spectralRefMenu.getlabel();    # Required 
#
         offsetDopplerCurr := its.profile.x.currentOffDoppler;            # Current offset doppler
         offsetDopplerReq  := to_upper(its.offsetDopplerMenu.getlabel()); # Required
      }
#
      doAbsCurr := its.profile.x.currentabs;
      doAbsReq := its.absrelMenu.getvalue();
#
      val doTime := F;
      val xOpt := 'BCNST';
      val xLab := spaste(its.profile.x.name, ' (',
                         its.profile.x.nativeunit, ')');

# See if anything changed since we last drew the plot. 
# First look at the units and abs/rel

      unitChanged := xUnitReq!=xUnitCurr;
      absRelChanged := doAbsCurr!=doAbsReq;

# Now the spectral reference and doppler

      specChanged := F;
      if (its.profile.x.isSpectral) {
        if ( (its.isLabelVelocity() && dopplerCurr!=dopplerReq) ||
             (specRefCurr!=specRefReq)) specChanged := T;
      }

# Now the offset value and doppler (spectral only)

      offsetChanged := F;
      offsetIsVelocity := F;
      offsetIsFrequency := F;
#
      if (its.profile.x.isSpectral) {
         offsetIsFrequency := its.isOffsetValueFrequency();
         if (!offsetIsFrequency) offsetIsVelocity :=  its.isOffsetValueVelocity();
         if (offsetDopplerCurr!=offsetDopplerReq) offsetChanged := T;
#
         if (offsetIsFrequency) {
            if (dq.checkfreq(offsetValueCurr)) {                # Frequency
               t1 := dq.convert(offsetValueCurr, 'Hz');
               if (is_fail(t1)) fail;
               t2 := dq.convert(offsetValueReq, 'Hz');
               if (is_fail(t2)) fail;
               if (abs(dq.getvalue(t2)-dq.getvalue(t1))>1e-6) offsetChanged := T;
            } else {
               offsetChanged := T;
            }
         } else {                                               # Velocity
            t1 := dq.convert(offsetValueCurr, 'km/s');
            if (is_fail(t1)) fail;
            t2 := dq.convert(offsetValueReq, 'km/s');
            if (is_fail(t2)) fail;
            if (abs(dq.getvalue(t2)-dq.getvalue(t1))>1e-6) offsetChanged := T;
         }
      } else {
         t1 := dq.convert(offsetValueCurr, xUnitNative);
         if (is_fail(t1)) fail;
         t2 := dq.convert(offsetValueReq, xUnitNative);
         if (is_fail(t1)) fail;
         if (abs(dq.getvalue(t2)-dq.getvalue(t1))>1e-6) offsetChanged := T;
      }

# Do we need to recompute stuff ?

      reCompute := unitChanged || absRelChanged || specChanged || offsetChanged;

# (Re)set the spectral reference conversion layer in the SpectralCoordinate if needed

      doSpecRefCon := its.profile.x.isSpectral && specRefCurr!=specRefReq;
      p2w := its.csys.axesmap (T);
      worldAxis := p2w[its.profile.axis];
#
      if (doSpecRefCon) {
         ok := its.csys.setconversiontype(spectral=specRefReq);

# Handle reference conversion failure by disabling reference conversion menu

         if (is_fail(ok) || (is_boolean(ok) && !ok)) {
            note ('Disabling reference frame conversions', priority='WARN',
                 origin='imageprofilesupport.convert')
            note ('The CoordinateSystem needs to be set more fully', priority='WARN',
                 origin='imageprofilesupport.convert')

# Put back native reference code

            type := to_upper(its.csys.referencecode(type='spectral'));
            ok := its.csys.setconversiontype(spectral=type);
            its.spectralRefMenu.selectlabel(type);
            its.profile.x.currentSpecRef := type;
#
            ok := its.spectralRefMenu.disabled(T);
            its.spectralRefMenuIsDisabled := T;
         }
      }

# Find number of profiles

      nAbc := length(its.profile.x.data);
      if (nAbc==0) fail 'Internal error'
#
      p2w := its.csys.axesmap(T);                   # Map from pixel to world 
      worldprofileaxis := p2w[its.profile.axis];

# Loop over profiles

      doOffset := abs(dq.getvalue(offsetValueReq)) > 0;    # No point offsetting by 0...
      for (i in 1:nAbc) {
         if (doSpecRefCon) {

# We are making a new spectral reference frame conversion. So we must reconvert from pixel 
# to world (where this conversion layer is active). It doesn't matter what units we want 
# to actually see (pixels/GHz/km/s) we must get everything consistent in the new frame first

            rp := its.csys.referencepixel();
            absWorld := its.absPixToAbsWorld (pix=its.profile.x.data[i].pixel.abs, pos=rp);
            if (is_fail(absWorld)) fail;
            its.profile.x.data[i].nativeworld.abs := absWorld[worldprofileaxis,];             
            its.profile.x.data[i].nativeworld.rel := [];                 # Compute as needed
            its.profile.x.data[i].pixel.rel := 
               its.profile.x.data[i].pixel.abs - rp[its.profile.axis];   # Should really use 
                                                                         # coordsys.makerel(...)
         }

# Now deal with units and offsets

         if (xUnitReq2=='PIX') {
            if (reCompute) {
               if (doAbsReq) {
                  its.profile.x.data[i].current := its.profile.x.data[i].pixel.abs;
               } else {
                  its.profile.x.data[i].current := its.profile.x.data[i].pixel.rel;
               }
            }
            if (i==1) {
               val xLab := spaste(its.profile.x.name, ' (pixels)');
            }
         } else if (xUnitReq2=='INDEX') {
            if (reCompute) {
               if (doAbsReq) {
                  its.profile.x.data[i].current := 1:length(its.profile.x.data[i].pixel.abs);
               } else {
                  its.profile.x.data[i].current := 1 - (1:length(its.profile.x.data[i].pixel.rel));
               }
            }
            if (i==1) {
               val xLab := spaste(its.profile.x.name, ' (index)');
            }
         } else if (its.profile.x.isSpectral) {
            if (reCompute) {
               t0 := its.profile.x.data[i].nativeworld.abs;

# Convert frequency to frequency with given offset if its non-zero
# Don't bother for relative abcissa as the offset will cancel out
# After this block 't0' is in native units

               if (doOffset && doAbsReq) {
                  if (offsetIsVelocity) {
		     # velocity argument here has opposite sign from offsetValueReq
		     offsetVel := dq.quantity(-dq.getvalue(offsetValueReq),dq.getunit(offsetValueReq));
                     t0 := its.csys.frequencytofrequency (value=its.profile.x.data[i].nativeworld.abs,
                                                          frequnit=xUnitNative,
                                                          doppler=offsetDopplerReq,
                                                          velocity=offsetVel);
                     if (is_fail(t0)) fail;
                  } else {
                     tt := dq.convert(offsetValueReq, xUnitNative);
                     if (is_fail(tt)) fail;
                     t0 +:= dq.getvalue(tt);
                  }
               }

# Now convert to velocity or desired units and handle abs/rel

               if (xUnitIsVelocity) {

# Convert to velocity

                  t0 := its.csys.frequencytovelocity(t0, frequnit=xUnitNative,
                                                     doppler=dopplerReq, velunit=xUnitReq);
                  if (is_fail(t0)) fail;

# Handle abs/rel

                  if (doAbsReq) {
                     its.profile.x.data[i].current := t0;
                  } else {
                     rv := its.csys.referencevalue()[worldAxis];
                     t1 := its.csys.frequencytovelocity(rv, frequnit=xUnitNative,
                                                        doppler=dopplerReq,
                                                        velunit=xUnitReq);
                     if (is_fail(t1)) fail;
                     its.profile.x.data[i].current := t0 - t1;   # rel = abs - ref
                  }
               } else {

# Find scale factor for unit conversion.

                  q := dq.quantity(1.0, xUnitNative);
                  if (is_fail(q)) fail;
                  fac0 := dq.convert(q, xUnitReq);
                  if (is_fail(fac0)) fail;
                  fac := fac0.value;

# Handle abs/rel

                  if (doAbsReq) {
                     its.profile.x.data[i].current := t0 * fac;
                  } else {

# We compute the rel vector as needed

                     if (length(its.profile.x.data[i].nativeworld.rel)==0) {    
                        its.profile.x.data[i].nativeworld.rel := its.absWorldToRelWorld(t0);
                        if (is_fail(its.profile.x.data[i].nativeworld.rel)) fail;
                     }
                     its.profile.x.data[i].current := its.profile.x.data[i].nativeworld.rel * fac;
                  }
               }
            }

# Label

            if (i==1) {
               if (xUnitIsVelocity) {
                  val xLab := spaste(dopplerReq, ' velocity (', xUnitReq, ')');
               } else {
                  val xLab := spaste(its.profile.x.name, ' (', xUnitReq, ')');
               }
            }
         } else if (xUnitReq2=='HMS' || xUnitReq2=='DMS') {          # For abs only
            if (reCompute) {
               q := dq.quantity(1.0, xUnitNative);
               if (is_fail(q)) fail;
               fac0 := dq.convert(q, 's');
               if (is_fail(fac0)) fail;
               fac := fac0.value;

# The radian to sec time conversion is appropriate for a Longitude
# For a Latitude, multiply by fiddle factor

               if (xUnitReq2=='DMS') fac *:= 180.0 / 12.0;
#
               t0 := its.profile.x.data[i].nativeworld.abs;

# Handle offset if its non-zero.  

               if (doOffset) {
                  q := dq.getvalue(dq.convert(offsetValueReq, xUnitNative));
                  if (is_fail(q)) fail;
                  t0 +:= q;
               }
#
               its.profile.x.data[i].current := t0 * fac;
             }
             if (i==1) {
                val doTime := T;
                val xOpt := 'BCNSTZYH';
                if (xUnitReq2=='DMS') val xOpt := 'BCNSTZYD';
                val xLab := its.profile.x.name;
             }
         } else {
            if (reCompute) {

# Find scale factor for unit conversion

               q := dq.quantity(1.0, xUnitNative);
               if (is_fail(q)) fail;
               fac0 := dq.convert(q, xUnitReq);
               if (is_fail(fac0)) fail;
               fac := dq.getvalue(fac0);
#
               if (doAbsReq) {

# Handle offset if its non-zero.  

                  if (doOffset) {
                     q := dq.getvalue(dq.convert(offsetValueReq, xUnitNative));
                     if (is_fail(q)) fail;
                     its.profile.x.data[i].current := 
                        (its.profile.x.data[i].nativeworld.abs + q) * fac;
                  } else {
                     its.profile.x.data[i].current := its.profile.x.data[i].nativeworld.abs * fac;
                  }
               } else {

# We compute native rel world only as needed. 

                  if (length(its.profile.x.data[i].nativeworld.rel)==0) {    
                     its.profile.x.data[i].nativeworld.rel := 
                        its.absWorldToRelWorld(its.profile.x.data[i].nativeworld.abs);
                     if (is_fail(its.profile.x.data[i].nativeworld.rel)) fail;
                  }
                  its.profile.x.data[i].current := its.profile.x.data[i].nativeworld.rel * fac;
               }
            }
            if (i==1) {
               val xLab := spaste(its.profile.x.name, ' (', xUnitReq, ')');
            }
         }
      }

# Get reference code. Will be empty other than for direction and spectral

      xRefCode := '';
      ct := to_upper(its.csys.axiscoordinatetypes(world=F)[its.profile.axis]);
      if (!is_fail(ct)) {
         if (its.profile.x.isSpectral) {
            val xLab := spaste(to_upper(specRefReq), ' ', xLab);
         } else {
            xRefCode := its.csys.referencecode(ct);
            if (!is_fail(xRefCode) && length(xRefCode)>0) {
              val xLab := spaste (xRefCode, ' ', xLab);
            }
         }
      }

# Fill in 'current' fields with new information

      its.profile.x.currentSpecRef := specRefReq;
      its.profile.x.currentdoppler := '';
      if (xUnitIsVelocity) its.profile.x.currentdoppler := dopplerReq;
#
      its.profile.x.currentunit := xUnitReq;
      if (xUnitReq2=='HMS' || xUnitReq2=='DMS') its.profile.x.currentunit := '';
#
      its.profile.x.currentOffValue := offsetValueReq;
      its.profile.x.currentOffDoppler := offsetDopplerReq;
#
      if (!doAbsReq) val xLab := spaste('Relative ', xLab);
      its.profile.x.currentabs := doAbsReq;

# Add offset to x-label

      offset := its.offsetValueEntry.get();
      value := dq.getvalue(offset);
      unit := dq.getunit(offset);
      if (abs(value)>0) {
         val xLab := spaste(xLab, '    \\gD=', value, ' ', unit);
      }
#
      return reCompute;
   }


###
   const its.diff := function (x, y)
   {
      tol := as_double(1e-6);
      if (length(x) != length(y)) return T;
#
      n := length(x);
      for (i in 1:n) {
        if (x[i] != y[i]) {
           return T;
        }
        d := tol * abs(max(x[i], y[i]));
        if (abs(x[i]-y[i]) > d) {
           return T;
        }
      }
      return F;
   }

###
   const its.disableWidgets := function (disable=T, offset=T)
   {
      wider its;
#
      if (is_agent(its.absrelMenu)) {
         its.absrelMenu.disabled(disable);
      }
#
      if (is_agent(its.xAxisUnit)) {
         its.xAxisUnit.disabled(disable);
      }
#
      if (is_agent(its.spectralRefMenu)) {
         if (!its.spectralRefMenuIsDisabled) {
            its.spectralRefMenu.disabled(disable);
         }
      }
#
      if (is_agent(its.dopplerMenu)) {
         if (!its.dopplerMenuIsDisabled) {
            its.dopplerMenu.disabled(disable);
         }
      }
#
      if (offset) {
         if (is_agent(its.offsetValueEntry)) {
            if (!its.offsetValueEntryIsDisabled) {
               its.offsetValueEntry.disable(disable);
            }
         }
      }
#
      if (is_agent(its.offsetDopplerMenu)) {
         if (!its.offsetDopplerMenuIsDisabled) {
            its.offsetDopplerMenu.disabled(disable);
         }
      }
#
      return T;
   }



###
   const its.donePlotter := function () 
   {
      wider its;
#
      if (its.isPlotter(its.plotter)) {
         its.plotter.done();
         its.plotter := [=];
         its.madeWidgets := F;
      }
      return T;
   }

###
   const its.doneWidgets := function ()
   {
      wider its;
      if (is_agent(its.absrelMenu)) {
        ok := its.absrelMenu.done();
        if (is_fail(ok)) fail;
      }
      if (is_agent(its.xAxisUnit)) {
        ok := its.xAxisUnit.done();
        if (is_fail(ok)) fail;
      }
      if (is_agent(its.dopplerMenu)) {
        ok := its.dopplerMenu.done();
        if (is_fail(ok)) fail;
      }
      if (is_agent(its.spectralRefMenu)) {
        ok := its.spectralRefMenu.done();
        if (is_fail(ok)) fail;
      }
      if (is_agent(its.offsetValueEntry)) {
        ok := its.offsetValueEntry.done();
        if (is_fail(ok)) fail;
      }
      if (is_agent(its.offsetDopplerMenu)) {
        ok := its.offsetDopplerMenu.done();
        if (is_fail(ok)) fail;
      }
#
      its.madeWidgets := F;
#
      return T;
   }


###
   const its.isAxisCoupled := function (axis)
   {
      if (axis <= 0) {
         return F;
      } else {
         types := to_upper(its.csys.axiscoordinatetypes(world=F));
         if (types[axis]=='DIRECTION') {
            return T;
         } else {
            return F;
         }
      }
   }


###
   const its.isAxisThisType := function (axis, type)
   {
      if (axis <= 0) {
         return F;
      } else {
         type := to_upper(type);
         types := to_upper(its.csys.axiscoordinatetypes(world=F));
         if (types[axis]==type) {
            return T;
         } else {
            return F;
         }
      }
   }

###
   const its.isLabelVelocity := function ()
#
# Is the label velocity and is the axis from a spectral
# coordinate (so we can make conversions). It might
# be a linear coordinate
#
   {  
      wider its;
      if (!its.profile.x.isSpectral) return F;
#
      lab := its.rec.f0.xAxisUnit.getlabel();
#
      if (!is_string(lab)) return F;
      ok := dq.check(lab);
      if (is_fail(ok)) fail;
      if (!ok) return F;
#
      ok := dq.compare(lab, 'km/s')
      return ok;
   }

###
   const its.isOffsetValueFrequency := function ()
   {
      wider its;
#
      if (!its.profile.x.isSpectral) return F;
#
      unit := its.offsetValueEntry.getunit();
      if (!dq.compare(unit,'Hz')) return F;
#
      return T;
   }

###
   const its.isOffsetValueVelocity := function ()
   {
      wider its;
#
      if (!its.profile.x.isSpectral) return F;
#
      unit := its.offsetValueEntry.getunit();
      if (!dq.compare(unit,'m/s')) return F;
#
      return T;
   }


###
   const its.isPlotter := function (thing)
   {
      return length(thing)!=0 && is_record(thing) &&
             has_field(thing, 'done');
   }

###
   const its.makeAbsRelMenu := function (ref parent, ref menu)
   {
      wider its;
#
      val menu := widgetset.optionmenu(parent, labels="Abs Rel", values=[T,F],
                                       hlp='Select absolute or relative coordinates')
      if (is_fail(menu)) fail;
#
      whenever menu->select do {

# We have to change the units menu for some axis types
# The offset things are disabled for relative

         idx := its.xAxisUnit.getindex();
         ok := its.updateWidgets ();
         if (is_fail(ok)) {
            note(ok::message, origin='imageprofilesupport.makeAbsRelMenu',
                 priority='SEVERE');
            its.disableWidgets(F);
         } else {
            its.xAxisUnit.selectindex(idx); 
#
            its.disableWidgets(T);
            ok := self.plot(which=its.profile.which);
            its.disableWidgets(F);
            if (is_fail(ok)) {
               note(ok::message, origin='imageprofilesupport.makeAbsRelMenu',
                    priority='SEVERE');
            }
#
            self->absrelchange(menu.getvalue());
         }
      }
#
      return T;
   }

###
   const its.makeUnitMenu := function (ref parent, ref menu, axis)
   {
      wider its;
#
# Set units for profile axis.  
#
       list := its.xAxisUnitsList (axis, its.profile.x.currentabs);
#
       val menu := widgetset.optionmenu(parent, labels=list,
                                        hlp='Select x-axis label type')
       if (is_fail(menu)) fail;
       if (length(list)==0) menu.disabled(T);
#
       whenever menu->select do {
          its.disableWidgets(T);
          ok := self.plot(which=its.profile.which);
          its.disableWidgets(F);
          if (is_fail(ok)) {
             note(ok::message, origin='imageprofilesupport.makeUnitMenu',
                  priority='SEVERE');
          }

# Turn on doppler menu as needed

          if (its.isLabelVelocity()) {
             its.rec.f0.dopplerType.disabled(F);
             its.dopplerMenuIsDisabled := F;
          } else {
             its.rec.f0.dopplerType.disabled(T);
             its.dopplerMenuIsDisabled := T;
          }
#
          self->unitchange(menu.getlabel());
       }
#
       return T;
   }


 ###
   const its.makeDopplerMenu := function (ref parent=unset, ref menu)
   {
       wider its;
#
       list := its.lists.doppler;
       val menu := widgetset.optionmenu(parent, labels=list, hlp='Select doppler type')
       if (is_fail(menu)) fail;
#
       whenever menu->select do {
          its.disableWidgets(T);
          ok := self.plot(which=its.profile.which);
          its.disableWidgets(F);
          if (is_fail(ok)) {
             note(ok::message, origin='imageprofilesupport.makeDopplerMenu',
                 priority='SEVERE');
          }
#
          self->dopplerchange(menu.getvalue());
       }

# Enable/disable as appropriate

       if (its.isLabelVelocity()) {
          menu.disabled(F);
          its.dopplerMenuIsDisabled := F;
       } else {
          menu.disabled(T);
          its.dopplerMenuIsDisabled := T;
       }
#
       return T;
   }


###
   const its.makeSpectralRefMenu := function (ref parent=unset, ref menu)
   {
       wider its;
#
       local pa, wa;
       list := its.lists.specRef;
       val menu := widgetset.optionmenu(parent, labels=list, hlp='Select reference frame')
       if (is_fail(menu)) fail;
#
       whenever menu->select do {
          its.disableWidgets(T);
          ok := self.plot(which=its.profile.which);
          its.disableWidgets(F);
          if (is_fail(ok)) {
             note(ok::message, origin='imageprofilesupport.makeProfilespectralRefMenu',
                 priority='SEVERE');
          }
#
          self->spectralrefchange(menu.getvalue());
       }
#
       if (its.profile.x.isSpectral) {
          menu.disabled(F);
          its.spectralRefMenuIsDisabled := F;
       } else {
          menu.disabled(T);
          its.spectralRefMenuIsDisabled := T;
       }
#
       return T;
   }


###
   const its.makeOffsetValueMenu := function (ref parent, ref menu, axis)
   {
      wider its;
#
# Set units for profile axis.  
#
       list := its.xAxisUnitsList (axis, its.profile.x.currentabs, T);
#
       hlp := spaste ('Enter an offset to be added to the abcissa\n',
                      'Spectral axes - if the offset is in velocity units,\n',
                      '   it is handled by scaling the native frequency abcissa\n',
                      '   vector appropriately.  After this scaling, if the plot \n',
                      '   units are also velocity, conversion to velocity is\n',
                      '   then done (which will shift the velocity scale oppositely\n',
                      '   to if we converted to velocity first and then added\n',
                      '   a velocity offset).   Presently, only velocity offsets \n',
                      '   smaller the speed of light will give meaningful results.\n',
                      '   If the offset is in frequency units, it is added \n',
                      '   directly to the native frequency abcissa vector and \n',
                      '   then abcissa unit conversions (e.g. to velocity) are done.\n',
                      '   The offset is assumed to be in the same reference frame\n',
                      '   as selected from the reference frame menu. \n\n',
                      'Other axes - the offset is added to the abicssa \n',
                      '   vector and then any unit conversions are done.\n\n',
                      '   The offset is not applied for relative units or when \n',
                      '   "pixel" or "index" plotting is requested.');
       val menu := quantumentry (parent, list=list, help=hlp,
                                 havespanner=F, widgetset=widgetset);
       menu.insert(0.0, emit=F);
       if (is_fail(menu)) fail;
       menu.setwidth(8);
       its.offsetValueEntryIsDisabled := F;
#
       whenever menu->value do {
          its.disableWidgets(T, offset=F);
          if (is_illegal($value) || is_unset($value)) {
            note ('Illegal value in offset entry box; re-enter',
                  origin='imageprofilesupport.makeOffsetValueMenu',
                  priority='SEVERE');
          } else {
             ok := self.plot(which=its.profile.which);
             its.disableWidgets(F);
             if (is_fail(ok)) {
                note(ok::message, origin='imageprofilesupport.makeOffsetValueMenu',
                     priority='SEVERE');
             }
             self->offsetvaluechange($value);
          }
       }
#
       whenever menu->unitchange do {
          absRel := its.absrelMenu.getvalue();
          if (absRel) {                         # Offset disabled for rel. units
             if (its.isOffsetValueVelocity()) {
                its.offsetDopplerMenu.disabled(F);
                its.offsetDopplerMenuIsDisabled := F;
             } else {
                its.offsetDopplerMenu.disabled(T);
                its.offsetDopplerMenuIsDisabled := T;
             }
          }
       }
#
       return T;
   }


###
   const its.makeOffsetDopplerMenu:= function (ref parent=unset, ref menu)
   {
       wider its;

# We only want this if the axis is spectral

       local pa, wa;
       list := its.lists.doppler;
       val menu := widgetset.optionmenu(parent, labels=list, hlp='Select spectral offset doppler type for velocity units')
       if (is_fail(menu)) fail;
#
       whenever menu->select do {
          its.disableWidgets(T);
          ok := self.plot(which=its.profile.which);
          its.disableWidgets(F);
          if (is_fail(ok)) {
             note(ok::message, origin='imageprofilesupport.makeOffsetDopplerMenu',
                  priority='SEVERE');
          }
#
          self->offsetdopplerchange($value);
       }
#
       if (its.isOffsetValueVelocity()) {
          menu.disabled(F);
          its.offsetDopplerMenuIsDisabled := F;
       } else {
          menu.disabled(T);
          its.offsetDopplerMenuIsDisabled := T;
       }
#
       return T;
   }


###
   const its.plotProfiles := function (which=unset)
   {
      wider its;
#
      nAbc := length(its.profile.x.data);
      if (nAbc==0) return T;                        # No abcissa
      if (length(its.profile.y.data)==0) return T;  # No ordinates
#
      allZero := T;
      for (i in 1:nAbc) {
         n := its.profile.npoints[i];
         if (n>0) allZero := F;
      }
      if (allZero) {
         note ('There is no profile to plot yet', priority='WARN',
                origin='imageprofilesupport.plotProfiles');
         return T;
      }

# Convert abcissa(s) to desired unit and apply offsets

      local xOpt, doTime, xLab;
      converted := its.convert (doTime, xOpt, xLab);
      if (is_fail(converted)) fail;

# Did the x-unit/doppler/ref/offset change in any way from the last plot ?
# We need to know if we have to rescale the plots or not...

      currPlotUnit := its.xAxisUnit.getlabel();
      currPlotSpecRef := its.spectralRefMenu.getlabel();
      currPlotDoppler := its.dopplerMenu.getlabel();   
      currPlotAbs := its.absrelMenu.getvalue();
      currPlotOffsetValue := dq.getvalue(its.offsetValueEntry.get());  # Bit lazy
      currPlotOffsetDoppler := its.offsetDopplerMenu.getvalue();
#
      xChanged := (currPlotUnit!=its.profile.x.prevPlotUnit) ||
                  (currPlotSpecRef!=its.profile.x.prevPlotSpecRef) ||
                  (currPlotDoppler!=its.profile.x.prevPlotDoppler) ||
                  (currPlotAbs != its.profile.x.prevPlotAbs) ||
                  (currPlotOffsetValue != its.profile.x.prevPlotOffsetValue) ||
                  (currPlotOffsetDoppler != its.profile.x.prevPlotDoppler);

# If autoscaling we have some more work to do

      xAutoScale := its.profile.autoscale[1];
      yAutoScale := its.profile.autoscale[2];
      oldxr := its.profile.xrange;
      oldyr := its.profile.yrange;
      drawAxes := F;
      pgRange := its.plotter.qwin();

# Preserve the x-range (perhaps from a zoom)

      if (xAutoScale || xChanged || length(its.profile.xrange)==0) {
         its.profile.xrange := its.xRangeOfProfiles();         
         its.stretch (its.profile.xrange);
      } else {     
         its.profile.xrange[1] := pgRange[1];
         its.profile.xrange[2] := pgRange[2];
      }
#
      if (yAutoScale || length(its.profile.yrange)==0) {
         r := its.yRangeOfProfiles(its.profile.xrange, which=which);
         if (r[1] > r[2]) {
            return F;                  # No valid profiles
         }
#
         its.profile.yrange := r;
         its.stretch (its.profile.yrange);
      } else {
         if (is_function(its.yRangeCallback)) {
            its.profile.yrange := its.yRangeCallback();
            its.stretch (its.profile.yrange);
         } else {
            its.profile.yrange[1] := pgRange[3];
            its.profile.yrange[2] := pgRange[4];
         }
      }

# Do it

      drawAxes := T;
      if (drawAxes) {
         its.plotter.clear();        # Clears display list

# This is very subtle.  I would like to just remain on the current page
# and clear/erase it.  However, in the absence of the page() call,
# the plots remain at the initial size of the pgplotwidget. i.e.
# they don't get redrawn to fill the full frame size. I was trying
# to avoid multi-pages in 'saved' postscipt plots by not having
# this call to page; but i seem to have it working somehow.

         its.plotter.page()
#
         its.plotter.sch(its.plot.charsize);
         its.plotter.vstd();
         its.plotter.swin(its.profile.xrange[1], 
                          its.profile.xrange[2], 
                          its.profile.yrange[1], 
                          its.profile.yrange[2])
#
         if (doTime) {
            its.plotter.tbox (xOpt, 0.0, 0, 'BCNST', 0.0, 0);
         } else {
            its.plotter.box(xOpt, 0.0, 0, 'BCNST', 0.0, 0);
         }
#
         yLab := spaste('Intensity (', its.profile.y.unit, ')');
         tLab := 'Profile';
         if (length(its.plot.title.text)==0) {
            its.plotter.lab(xLab, yLab, tLab);
         } else {
            its.plotter.lab(xLab, yLab, '');

# Write fancy multicolour title

            oci := its.plotter.qci();
            x := 0.0;
            l0 := its.plotter.len(5, 'XX');
            for (i in 1:length(its.plot.title.text)) {
               its.plotter.sci(its.plot.title.ci[i]);
               its.plotter.mtxt ('T', 1.5, x, 0.0, its.plot.title.text[i]);
#
               l := its.plotter.len(5, its.plot.title.text[i]);
               x +:= l[1] + l0[1];
            }
            its.plotter.sci(oci);
         }
      }

# Draw profiles.  If we have to redraw the axes, then draw
# all profiles, regardless of which one was requested

      nProfiles := self.nprofiles();
      oci := its.plotter.qci();
      list := 1:nProfiles;
      if (!is_unset(which)) {
         if (which < 1 || which > nProfiles) {
            note('Illegal profile; will plot all', 
                 origin='imageprofilesupport.plotProfiles',
                 priority='SEVERE');
         } else {
            list := which;
         }
      }
#    
      ols := its.plotter.qls();
      local xVal;

# Plot each requested profile.  It may be that the requested
# profile does not exist.   Just ignore those ones.

      nP := length(its.profile.y.data);
      for (i in list) {         
         if (i <= nP) {                               # Profile is available
            ls := its.profile.y.ls[i];
            its.plotter.sci(its.profile.y.ci[i]);      
            if (ls>0) its.plotter.sls(ls);
            if (nAbc==1) {
               xVal := its.profile.x.data[1].current;
            } else {
               xVal := its.profile.x.data[i].current;
            }
#
            if (ls > 0) {

# Draw connected lines

               if (length(its.profile.mask[i])==0) {
                 ok := its.plotter.line(xVal, its.profile.y.data[i]);
               } else {
                 ok := its.plotter.maskline(xVal, 
                                            its.profile.y.data[i], 
                                            its.profile.mask[i]);
               }
            } else {

# Draw marker and errors

               if (length(its.profile.mask[i])==0) {
                  ok := its.plotter.pt (xVal, its.profile.y.data[i], abs(ls));
               } else {
                  xx := xVal[its.profile.mask[i]==T];
                  yy := its.profile.y.data[i][its.profile.mask[i]==T];
                  ok := its.plotter.pt (xx, yy, abs(ls));
               }
            }

# Draw errors

            if (length(its.profile.y.err[i]) > 0) {
               if (length(its.profile.mask[i])==0) {
                  yLow := its.profile.y.data[i] - its.profile.y.err[i];
                  yHigh := its.profile.y.data[i] + its.profile.y.err[i];
                  ok := its.plotter.erry (xVal, yLow, yHigh, 1.0);                     
               } else {
                  y := its.profile.y.data[i][its.profile.mask[i]==T];
                  yErr := its.profile.y.err[i][its.profile.mask[i]==T];
                  yLow := y - yErr;
                  yHigh := y + yErr;
                  ok := its.plotter.erry (xVal, yLow, yHigh, 1.0);                     
               }
            }
         }
      }
      its.plotter.sci(oci);
      its.plotter.sls(ols);
      if (its.standAlone) its.plotter.gui();
#
      its.profile.x.prevPlotUnit := its.xAxisUnit.getlabel();             
      its.profile.x.prevPlotDoppler := its.dopplerMenu.getlabel();
      its.profile.x.prevPlotSpecRef := its.spectralRefMenu.getlabel();
      its.profile.x.prevPlotAbs := its.absrelMenu.getvalue();
      its.profile.x.prevPlotOffsetValue := currPlotOffsetValue;
      its.profile.x.prevPlotDoppler := currPlotOffsetDoppler;
      its.profile.which := list;                      # Save plot list
#
      return T;
   }


###
   const its.stretch := function (ref range)
   {
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

###
    const its.updateMenus := function ()
    {
       wider its;
#
       if (!its.madeWidgets) {
#          return throw ('You must create the menus (function makemenus) before you can update them',
#                        origin='imageprofilesupport.updateMenus');
          return T;
       }
#
       if (its.profile.axis < 1) {
          return throw ('Profile axis must be positive to update menus',
                        origin='imageprofilesupport.updateMenus');
       }
#
       ok := its.updateWidgets ();
       if (is_fail(ok)) fail;
       ok := self.clearplotter();
#
       return ok;
    }


###
   const its.updateWidgets := function ()
#
# Update widgets because abs/rel status, or axis may have changed.
#
   {
      wider its;
#
# The menu might not be made yet
#
      if (!is_agent(its.xAxisUnit)) return F;

# Abs/rel status

       absRel := its.absrelMenu.getvalue();
#
# Set units for given profile axis.  The units list may change when we go from abs<->rel
#
       oldlist := its.xAxisUnit.getlabels();
       list := its.xAxisUnitsList (its.profile.axis, absRel);
#
       changed := (length(oldlist)!=length(list) || !all(oldlist==list));
       if (changed) {    
          if (is_agent(its.xAxisUnit)) {
             its.xAxisUnit.replace(list);
             if (length(list)==0) {
                its.xAxisUnit.disabled(T);
             } else {
                its.xAxisUnit.disabled(F);
             }
          } else {
             return throw ('Axis label optionmenu is not valid. cannot replace',
                           origin='imageprofilesupport.updateWidgets');
          }
       }

# Deal with spectral menus.  If the axis changed, we need to disable/enable
# the widgets.  If the widgets are already disabled, we re-enable them
# here if the axis changed (might want to revisit this decision...)

       if (its.profile.axis != its.profile.oldaxis && its.profile.oldaxis!=-1) {
          if (its.profile.x.isSpectral) {

# The new axis is spectral - enable the Doppler and frame menus

             if (its.isLabelVelocity()) {
                ok := its.dopplerMenu.disabled(F);
                its.dopplerMenuIsDisabled := F;
             } else {
                ok := its.dopplerMenu.disabled(T);
                its.dopplerMenuIsDisabled := T;
             }
             ok := its.dopplerMenu.selectindex(1);
#
             ok := its.spectralRefMenu.disabled(F);
             its.spectralRefMenuIsDisabled := F;
             ok := its.spectralRefMenu.selectindex(1);
             if (is_fail(ok)) fail;
          } else {
             ok := its.dopplerMenu.disabled(T);
             its.dopplerMenuIsDisabled := T;
#
             ok := its.spectralRefMenu.disabled(T);
             its.spectralRefMenuIsDisabled := T;
          }
       }

# Update offset menu units list if needed

       oldlist := its.offsetValueEntry.getunitlist();
       list := its.xAxisUnitsList (its.profile.axis, absRel, T);
       if (is_fail(list)) fail;
       changed := (length(oldlist)!=length(list) || !all(oldlist==list));
#
       if (changed) {
          ok := its.offsetValueEntry.replaceunitmenu(list);
          if (is_fail(ok)) fail;
          its.offsetValueEntry.insert(0.0, emit=F);
          its.offsetValueEntryIsDisabled := F;
       }

# Enable/disable offset menus for abs/rel condition

       if (absRel) {
          its.offsetValueEntry.disable(F);
          its.offsetValueEntryIsDisabled := F;
#
          if (its.isOffsetValueVelocity()) {
             its.offsetDopplerMenu.disabled(F);
             its.offsetDopplerMenuIsDisabled := F;
          }
       } else {
          its.offsetValueEntry.disable(T);
          its.offsetValueEntryIsDisabled := T;
#
          its.offsetDopplerMenu.disabled(T);
          its.offsetDopplerMenuIsDisabled := T;
       }
#
       return T;
   }


###
   const its.xAxisUnitsList := function (axis, doAbs, forOffset=F)
   {
       wider its;
#
       local list;
       if (axis<=0) {      
          list := "";
       } else if (its.isAxisThisType(axis, 'spectral')) {
          if (forOffset) {
             list := "km/s m/s GHz MHz Hz";
          } else {   
             list := "GHz MHz kHz Hz km/s m/s pix index";
          }
       } else if (its.isAxisThisType(axis, 'direction')) {
          if (forOffset) {
             list := "deg rad arcsec";
          } else {
            local pa, wa;
            ok := its.csys.findcoordinate(pa, wa, 'direction', 1);
            if (axis==pa[1]) {
               if (doAbs) {
                  list := "deg rad arcsec hms h pix index";
               } else {
                  list := "arcsec deg rad h pix index";
               }
            } else if (axis==pa[2]) {
               if (doAbs) {
                  list := "deg rad arcsec dms pix index";
               } else {
                  list := "arcsec deg rad pix index";
               }
            } else {
               return throw ('Internal failure',
                             origin='imageprofilesupport.makeAxisUnitsList');
            }
         }
       } else if (axis <= its.csys.naxes(F)) {
          p2w := its.csys.axesmap (T);
          units := its.csys.units()[p2w];
          if (forOffset) {
             list := [units[axis]];
           } else {
             list := [units[axis], 'pix', 'index'];
           }
       } else {
          return throw ('Illegal axis', 
                        origin='imageprofilesupport.makexAxisUnitsList');
       }
       return list;
   }


###
   const its.xRangeOfProfiles := function ()
   {
      wider its;
#
      r := [1e99, -1e99];
      nAbc := length(its.profile.x.data);
      for (i in 1:nAbc) {
         r[1] := min(r[1], min(its.profile.x.data[i].current));
         r[2] := max(r[2], max(its.profile.x.data[i].current));
      }
      return r;
   }

###
   const its.yRangeOfProfiles := function (xrange=unset, which=unset)
   {
      wider its;
#
      r := [1e99, -1e99];

# Any requested profiles that don't actually exist we ignore

      profiles := which;
      if (is_unset(which)) profiles  := self.nprofiles();
      nY := length(its.profile.y.data);
#
      local yy, yLow, yHigh;
      if (is_unset(xrange)) {

# We don't worry about the xrange so we don't have to worry about multiabcissasss.   

         for (i in profiles) {
            if (i <= nY) {                                   # Profile exists
               if (length(its.profile.mask[i]) > 0) {
                  r[1] := min(r[1], min(its.profile.y.data[i][its.profile.mask[i]]));
                  r[2] := max(r[2], max(its.profile.y.data[i][its.profile.mask[i]]));
               } else {
                  r[1] := min(r[1], min(its.profile.y.data[i]));
                  r[2] := max(r[2], max(its.profile.y.data[i]));
               }
#
               if (length(its.profile.y.err[i]) > 0) {       # y error exists
                  if (length(its.profile.mask[i]) > 0) {
                     yy := its.profile.y.data[i][its.profile.mask[i]];
                     yLow := yy - its.profile.y.err[i][its.profile.mask[i]];
                     yHigh := yy + its.profile.y.err[i][its.profile.mask[i]];
                  } else {
                     yy := its.profile.y.data[i];
                     yLow := yy - its.profile.y.err[i];
                     yHigh := yy + its.profile.y.err[i];
                  }
                  r[1] := min(r[1], min(yLow));
                  r[2] := max(r[2], max(yHigh));
               }
            }
         } 
      } else {

# We want the yrange in the specified x-range.

         if (its.multi) {

# Multi abcissa mode.  One abcissa per ordinate per mask

            if (is_unset(which)){ 
               profiles := 1:length(its.profile.x.data);
            }
            nP := length(its.profile.x.data);         
#
            for (i in profiles) {
               if (i <= nP) {                                 # Profile exists

# Find the range mask

                  m := its.profile.x.data[i].current > xrange[1] &
                       its.profile.x.data[i].current < xrange[2];
#
                  if (length(its.profile.mask[i])>0) {       # Is there an actual mask for this profile
                     m := m & its.profile.mask[i];
                  }      
#
                  yy := its.profile.y.data[i][m];
                  r[1] := min(r[1], min(yy));
                  r[2] := max(r[2], max(yy));
#
                  if (length(its.profile.y.err[i]) > 0) {     # Y error exists
                     yLow := yy - its.profile.y.err[i][m];
                     yHigh := yy + its.profile.y.err[i][m];
                     r[1] := min(r[1], min(yLow));
                     r[2] := max(r[2], max(yHigh));
                  }
               }
            }
         } else {

# Single abcissa mode.  One abcissa per many ordinate/masks

            if (is_unset(which)){ 
               profiles := 1:length(its.profile.y.data);
            }            
            nP := length(its.profile.y.data);         
#
            for (i in profiles) {
               if (i <= nP) {                                 # Profile exists
                  foundOne := T;

# Find the range mask

                  m := its.profile.x.data[1].current > xrange[1] &
                       its.profile.x.data[1].current < xrange[2];
#
                  if (length(its.profile.mask[i])>0) {     # Has an actual mask
                     m := m & its.profile.mask[i];
                  }      
#
                  yy := its.profile.y.data[i][m];
                  r[1] := min(r[1], min(yy));
                  r[2] := max(r[2], max(yy));
#
                  if (length(its.profile.y.err[i]) > 0) {     # Y error exists
                     yLow := yy - its.profile.y.err[i][m];
                     yHigh := yy + its.profile.y.err[i][m];
                     r[1] := min(r[1], min(yLow));
                     r[2] := max(r[2], max(yHigh));
                  }
               }
            }
         }
      }
#
      return r;                      # min > max if no profiles found
   }



### Public methods


###
   const self.clearplotter := function ()
   {
      wider its;
      if (self.hasplotter()) {
         return its.plotter.eras();
      }
      return T;
   }   

###
   const self.disablespectralrefmenu := function ()
   {
      wider its;

# This permanently disables the spectral reference menu

      if (is_agent(its.spectralRefMenu)) {
         its.spectralRefMenuIsDisabled := T;
         return its.spectralRefMenu.disabled(T);
      }
#
      return T;
   }


###
    const self.done := function()
    {
        wider its, self;
#
# Done internal copy of Coordinate System
#
        ok := its.csys.done();
        if (is_fail(ok)) {
           note (ok::message, priority='SEVERE', origin='imageprofilesupport.done');
        }
#
# Done plotter 
#
        ok := its.donePlotter();
        if (is_fail(ok)) {
           note (ok::message, priority='SEVERE', origin='imageprofilesupport.done');
        }
#
# Done widgets
#
        ok := its.doneWidgets();
        if (is_fail(ok)) {
           note (ok::message, priority='SEVERE', origin='imageprofilesupport.done');
        }
#
        val its := F;
        val self := F;
#
        return ok;
     }

###
   const self.getabcissa := function (which=1)
   {
      wider its;
#
      w := its.checkWhich(which, T);
      if (is_fail(w)) fail;
#
      return its.profile.x.data[w];
   }

###
   const self.getcurrentabcissa := function (which=1)
   {
      wider its;
#
      w := its.checkWhich(which, T);
      if (is_fail(w)) fail;
#
      return its.profile.x.data[w].current;
   }

###
   const self.getabcissaunit := function () 
   {
       return  its.xAxisUnit.getlabel(); 
   }

###
   const self.getabcissaunits := function () 
   {
       return  its.xAxisUnit.getlabels(); 
   }

###
   const self.getdoppler := function () 
   {
      return its.dopplerMenu.getvalue();
   }

###
   const self.getisabs := function ()
   {
      wider its;
      return its.absrelMenu.getvalue();
   }


###
   const self.getmask := function (which=1)
   {
      wider its;
#
      w := its.checkWhich(which, F);
      if (is_fail(w)) fail;
      return its.profile.mask[w];
   }

###
   const self.getoffsetvalue := function ()
   {
      wider its;
#
      return its.offsetValueEntry.get();
   }

###
   const self.getoffsetdoppler := function ()
   {
      wider its;
#
      return its.offsetDopplerMenu.getvalue();
   }

###
   const self.getordinate := function (which=1)
   {
      wider its;
#
      w := its.checkWhich(which, F);
      if (is_fail(w)) fail;
#
      r := [=];
      r.unit := its.profile.y.unit;
      r.data := its.profile.y.data[w];
      r.error := its.profile.y.err[w];
      return r;
   }

###
   const self.getordinateunit := function ()
   {
      return its.profile.y.unit;
   }

###
   const self.getrefframe := function() 
   {
      wider its;
#
      local f;
      if (its.profile.x.isSpectral && length(its.profile.x.currentSpecRef)>0) {
         f := its.profile.x.currentSpecRef;
      } else {

# There is as yet no menu/selected frame. So use whatever is set in the
# CS (may be the conversion layer or native). For Direction coordinate, where 
# we don't yet offer frame conversions, we will end up here as well.

         if (its.profile.axis > 0) {
            ct := its.csys.axiscoordinatetypes(world=F)[its.profile.axis];
            if (!is_fail(ct)) {
               f := its.csys.conversiontype(type=ct);
            }
         }
      }
#
      return f;
   }


###
   const self.getx := function (color=7)
   {
      wider its;
#
      w := its.plotter.qwin();
      ci := its.plotter.qci();
#
      its.plotter.sci(color);
      r := its.plotter.curs((w[1]+w[2])/2.0, (w[3]+w[4])/2.0);
#
      x[1] := r.x[1];
      x[2] := r.x[1];
      y[1] := w[3];
      y[2] := w[4];
#
      its.plotter.line(x, y);
      its.plotter.sci(ci);
#
      return x[1];
   }


###
   const self.getxy := function (symbol=2, color=7)
   {
      wider its;
#
      w := its.plotter.qwin();
      ch := its.plotter.qch();
      ci := its.plotter.qci();
#
      its.plotter.sci(color);
      its.plotter.sch(2.0);
      r := its.plotter.curs((w[1]+w[2])/2.0, (w[3]+w[4])/2.0);
      its.plotter.pt(r.x, r.y, symbol);
#
      its.plotter.sch(ch);
      its.plotter.sci(ci);
#
      return [r.x[1], r.y[1]];
   }

###
   const self.hasplotter := function ()
   {
      wider its;
      return its.isPlotter(its.plotter);
    }


### 
   const self.hasprofile := function ()
   {
      wider its;
#
      return (self.nprofiles() > 0);
   }


###
   const self.insertoffset := function (offset=unset, doppler=unset)
   {
      wider its;
#
      oldOffset := self.getoffsetvalue();
#
      ok := T;
      if (!is_unset(offset)) {
         ok := its.offsetValueEntry.insert(offset, emit=F);
         if (is_fail(ok) || !ok) {
            ok2 := its.offsetValueEntry.insert(oldOffset, emit=F);
#
            if (is_fail(ok)) fail;
            return F;
         }
      }
#
      if (!is_unset(doppler)) {
         ok := its.offsetDopplerMenu.selectvalue(to_upper(doppler));
         if (is_fail(ok)) fail;
         if (!ok) return F;
      }
#
      return self.plot(which=its.profile.which);
   }


###
   const self.makeplotter := function (parent=unset, size=[295,215])
#
# Use dws instead of widgetset because a bug in pgplotter
# prevents use of ddlws presently
# 
   {
      wider its;
#
      if (!its.isPlotter(its.plotter)) {

# The user might destroy the plotter with the 'done' button
# This is the only way I can reset this variable (there are
# no events from pgplotters)

         its.madeWidgets := F;
         its.profile.xrange := [];
         its.profile.yrange := [];
#
         if (is_unset(parent)) {
            plotterName := spaste('imageprofilesupport_', as_string(random()));
            its.plotter := pgplotter(plotfile=plotterName, size=size, widgetset=dws);
            its.standAlone := T;
            its.pgframe := its.plotter.userframe();
         } else {
            its.plotter := pgplotwidget (parent, size=size, havemessages=F, 
                                         widgetset=widgetset);
            its.standAlone := F;
            its.pgframe := ref parent;
         }
         if (is_fail(its.plotter)) fail;
         its.plotter.page();
         its.canDestroyPlotter := T;
      }
      return T;
   }


###
    const self.makemenus := function (parent=F)
    {
       wider its;
#
# Plot x-axis labels
#
       if (its.madeWidgets) return T;
#
       widgetset.tk_hold();
#
       its.hiddenRec.f0 := widgetset.frame(side='left', expand='none');
       its.hiddenRec.f0->unmap();
#
       if (is_boolean(parent)) {
          if (is_agent(its.pgframe)) {
            its.rec.f0 := widgetset.frame(its.pgframe, side='left');
          } else {
             txt := spaste('You must call function makeplotter first since you \n',
                           'have not given a parent frame.');
             widgetset.tk_release();
             return throw (txt, origin='imageprofilesupport.makemenus');
          }
       } else {
          its.rec.f0 := widgetset.frame(parent, side='left');
       }
       its.rec.f0.space := widgetset.frame(its.rec.f0, expand='x', height=1, width=1);
#
       its.rec.f0.absrel := [=];
       ok := its.makeAbsRelMenu (its.rec.f0, its.rec.f0.absrel);
       if (is_fail(ok)) {widgetset.tk_release(); fail;}
       its.absrelMenu := its.rec.f0.absrel;                  # Easy copy
#
       its.rec.f0.xAxisUnit := [=];
       ok := its.makeUnitMenu (its.rec.f0, its.rec.f0.xAxisUnit, its.profile.axis);
       if (is_fail(ok)) {widgetset.tk_release(); fail;}
       its.xAxisUnit := its.rec.f0.xAxisUnit;                # Easy copy
#
       its.rec.f0.dopplerType := [=];
       ok := its.makeDopplerMenu (its.rec.f0, its.rec.f0.dopplerType);
       if (is_fail(ok)) {widgetset.tk_release(); fail;}
       its.dopplerMenu := its.rec.f0.dopplerType;            # Easy copy
#
       its.rec.f0.spectralRef := [=];
       ok := its.makeSpectralRefMenu (its.rec.f0, its.rec.f0.spectralRef);
       if (is_fail(ok)) {widgetset.tk_release(); fail;}
       its.spectralRefMenu := its.rec.f0.spectralRef;            # Easy copy
#
       its.rec.f0.space2 := widgetset.frame(its.rec.f0, expand='none', height=1, width=10);
#
       where := its.rec.f0;
       if (!its.hasOffset) where := its.hiddenRec.f0;
#
       its.rec.f0.offsetValueType := [=];
       ok := its.makeOffsetValueMenu (where, its.rec.f0.offsetValueType, 
                                      its.profile.axis);
       if (is_fail(ok)) {widgetset.tk_release(); fail;}
       its.offsetValueEntry := its.rec.f0.offsetValueType;       # Easy copy
#
       its.rec.f0.offsetDopplerType := [=];
       ok := its.makeOffsetDopplerMenu(where, its.rec.f0.offsetDopplerType);
       if (is_fail(ok)) {widgetset.tk_release(); fail;}
       its.offsetDopplerMenu := its.rec.f0.offsetDopplerType;    # Easy copy

# Select current spectral reference frame in cSys
# The coordinate system may have a spectral conversion already
# active, so fish that out.

       local pa, wa;
       found := its.csys.findcoordinate(pa, wa, 'spectral');
       if (is_fail(found)) {widgetset.tk_release(); fail;}
       if (found) {       
          type := its.csys.conversiontype(type='spectral');
          ok := its.spectralRefMenu.selectlabel(to_upper(type));
          if (is_fail(ok)) {widgetset.tk_release(); fail;}
       }
#
       its.madeWidgets := T;
       widgetset.tk_release();
#
       return T;
    }


###
   const self.makeabcissa := function (pixel)
#
# pixel is the absolute pixel coordinate of the position
#  the profile axis coordinate is irrelevant
#
# This function makes the abcissa in the native units
# of the coordinate
#
   {
      wider its;
#
      if (its.multi) {
         return throw ('makeabicissa can only be called in single abcissa mode',
                       origin='imageprofilesupport.makeabcissa');
      }
#
      if (its.profile.axis<0) {
         return throw ('The profile axis has not yet been set. Use function setprofileaxis',
                        origin='imageprofilesupport.makeabcissa');
      }
      if (length(pixel) != length(its.shape)) {
         return throw ('Pixel coordinate has wrong dimension',
                       origin='imageprofilesupport.makeabcissa');
      }
#
      coupled := its.isAxisCoupled(its.profile.axis);

# See if we need to remake abcissa; either axis is coupled
# or the profile axis changed

      if (!coupled) {
         if (its.profile.axis==its.profile.oldaxis) {
            if (self.nprofiles()>0 && self.npoints() > 0) return T;
         }
      }
      p2w := its.csys.axesmap(T);      # Map from pixel to world 
      worldprofileaxis := p2w[its.profile.axis];
#
      n := its.shape[its.profile.axis];
      its.profile.npoints[1] := n;
      p := as_double(pixel);
      its.profile.x.data[1] := [=];
      its.profile.x.data[1].pixel := [=];
      its.profile.x.data[1].nativeworld := [=];
      its.profile.x.data[1].current := [=];
#
      its.profile.x.data[1].nativeworld.abs := [];
      its.profile.x.data[1].pixel.abs := [];
#
      absWorld := its.absPixToAbsWorld (n=n, pos=pixel);
      if (is_fail(absWorld)) fail;
#
      relWorld := its.csys.torelmany(absWorld, T);
      if (is_fail(relWorld)) fail;
#
      rp := as_double(its.csys.referencepixel()[its.profile.axis]);
      its.profile.x.data[1].nativeworld.abs := absWorld[worldprofileaxis,];    # Native abs world
      its.profile.x.data[1].nativeworld.rel := [];                             # Native rel world
      its.profile.x.data[1].pixel.abs := as_double(1:n);                       # Abs pixel
      its.profile.x.data[1].pixel.rel := its.profile.x.data[1].pixel.abs - rp; # Rel pixel
#
      its.profile.x.name := its.csys.names()[worldprofileaxis];
      its.profile.x.nativeunit := its.csys.units()[worldprofileaxis];

# When we first make the abcissa, the current profile is in native units

      its.profile.x.data[1].current := its.profile.x.data[1].nativeworld.abs;  
      its.profile.x.currentunit := its.profile.x.nativeunit;  
      its.profile.x.currentabs := T;

# The next line is important.  If any offset is currently being applied
# to the plots, setting it to 0 will make sure that function 'convert' 
# notices that for this profile, it has not yet been applied (so .current is wrong)
# Function convert will recompute .current for us

      its.profile.x.currentOffValue := dq.quantity(0.0, its.profile.x.nativeunit);
#
      return T;
   }


###
   const self.makeordinate := function (im, region=unset, ci=1, ls=1, which=unset)
#
# region is either a region tool or a record with fields 'blc' and 'trc'
# in absolute pixel coordinates
#
   {
      wider its;
#
      if (its.multi) {
         return throw ('makeordinate can only be called in single abcissa mode',
                       origin='imageprofilesupport.makeordinate');
      }
#
      if (its.profile.axis<0) {
         return throw ('The profile axis has not yet been set. Use function setprofileaxis',
                       origin='imageprofilesupport.makeordinate');
      }

# I don't like that there is no guarentee this image's cSys is the same
# as the construction one.  Bad interface.

      include 'image.g'
      bb := [=];
      isRegion := T;
      if (is_unset(region) || is_region(region)) {
         bb := im.boundingbox(region=region)
         if (is_fail(bb)) fail;
      } else {
         if (is_record(region) && has_field(region, 'blc') &&
             has_field(region, 'trc')) {
            bb := region;
            bb.bbShape := bb.trc - bb.blc + 1;
         } else {
            return throw ('Invalid region', origin='imageprofilesupport.makeordinate');
         }
         isRegion := F;
      }
#
# Set the axes to average over. These are all of them apart from 
# the profile axis.  However, if the region actually is only
# of width 1 pixel for the non-profile axes, use that
# information in the call to getregion as it will speed it up.
#
      naxes := its.csys.naxes(world=F);
      axes := [];
      j := 1;
      average := F;
      for (i in 1:naxes) {
         if (i != its.profile.axis) {
            axes[j] := i;
            j +:= 1;
            if (bb.bbShape[i] !=1) average := T;
         }
      }      
      if (!average) axes := unset;
# 
# Get the profile
#
      local p, m;
      if (!isRegion) {

# getchunk is much faster than getregion 

         r := im.getchunk(blc=bb.blc, trc=bb.trc, axes=axes, getmask=T);
         if (is_fail(r)) fail;
         p := r.pixels;
         m := r.pixelmask;
      } else {
         ok := im.getregion(pixels=p, pixelmask=m, region=region, axes=axes);
         if (is_fail(ok)) fail;
      }
      n := prod(bb.bbShape);
#
      p::shape := n;
      m::shape := n;
#
      local idx;
      np := self.nprofiles();
      if (is_unset(which)) {
         idx := np + 1;
      } else {
         if (which==(np+1) || which>=1 || which<=np) {
            idx := which;
         } else {
            return throw ('Illegal profile index', 
                          origin='imageprofilesupport.makeordinate');
         }         
      }
#
      its.profile.mask[idx] := m;
#
      its.profile.y.unit := im.brightnessunit();
      its.profile.y.data[idx] := p;
      its.profile.y.err[idx] := [];                    # No errors
      its.profile.y.ci[idx] := ci;
      its.profile.y.ls[idx] := ls;
#
      return idx;
   }

###
   const self.npoints := function (which=1)
   {
      wider its;
#
      w := its.checkWhich(which, F);
      if (is_fail(w)) fail;
#
      return its.profile.npoints[w];
   }

###
   const self.nprofiles := function ()
   {
      wider its;
#
      return length(its.profile.y.data);
   }



###
   const self.plot := function (xautoscale=T, yautoscale=T, which=unset)
   {
      wider its;
#
      its.profile.autoscale := [xautoscale, yautoscale];
#
      ok := self.makeplotter();      # Will make standalone if not already done
      if (is_fail(ok)) fail;
      return its.plotProfiles(which=which);
   }

###
   const self.plotter := function ()
   {
      wider its;
      if (self.hasplotter()) {
         return its.plotter;
      } else {
         return throw('No plotter available', 
                      origin='imageprofilesupport.hasplotter')
      }
   }


###
   const self.point := function (x, y, errx=-1, erry=-1, symbol=2, ci=1)
#
# We better do something about offsets here...
#
   {
      wider its;
      oci := its.plotter.qci();
      its.plotter.sci(ci);
      its.plotter.pt(x, y, symbol);
      if (errx > 0) {
         its.plotter.errx (x-errx, x+errx, y, 0.0);
      }
      if (erry > 0) {
         its.plotter.erry (x, y-erry, y+erry, 0.0);
      }
      its.plotter.sci(oci);
      return T;
   }

###
   const self.postscript := function (file, color=T, landscape=T)
   {
      return its.plotter.postscript(file, color, landscape)
   }

###
   const self.plotfile := function (file)
   {
      return its.plotter.plotfile(file)
   }

###
   const self.setabcissaunit := function (unit, doppler=unset)
   {
      wider its;
#
      if (!its.madeWidgets) {
         return throw ('You must call function makemenus first',
                       origin='imageprofilesupport.setabcissaunit');
      }
#
      list := its.xAxisUnit.getlabels();
      found := F;
      for (l in list) {
         if (unit==l) {
            found := T;
            break;
         }
      }
#
      if (!found) {
         t := spaste('Specified unit is not in available list:', list);
         return throw (t, origin='imageprofilesupport.setabcissaunit');
      }
      its.xAxisUnit.selectlabel(unit);
#
      found := F;
      ok := its.updateMenus();
      if (is_fail(ok)) fail;
#
      if (!is_unset(doppler)) {
	  for (m in its.lists.doppler) {
	      if (to_upper(doppler) == m) {
		  found := T;
		  break;
	      }
	  }
	  if (!found) {
	      t := spaste('Specified doppler is not in available list:',
			  its.lists.doppler);
	      return throw (t, origin='imageprofilesupport.setabcissaunit');
	  }
#
	  if (is_agent(its.dopplerMenu)) {
	      its.dopplerMenu.selectlabel(doppler);
	  }
      }
#
      ok := self.plot(which=its.profile.which);
      if (is_fail(ok)) fail;
#
      return T;
   }

###
   const self.setcoordinatesystem := function (csys, shp, resetref=F)
   {
      wider its;
#
      if (is_coordsys(csys)) {
         if (is_coordsys(its.csys)) {
            ok := its.csys.done();
            if(is_fail(ok)) fail;
         }
#
         its.csys := csys.copy();
         if(is_fail(its.csys)) fail;
      } else {
         return throw('Supplied Coordsys tool is invalid',
                      origin='imageprofilesupport.setcoordinatesystem');
      }
#
      its.shape := shp;
      if (its.csys.naxes(world=F) != length(its.shape)) {
         return throw('Supplied shape is inconsistent with the number of pixel axes in the Coordinate System',
                      origin='imageprofilesupport.setcoordinatesystem');
      }

# Initial spectral reference frame must be the native one (or the one
# set by the user into the coordinate system conversion layer)

      local pa, wa;
      hasSpec := its.csys.findcoordinate(pa, wa, 'spectral', 1);
      if (hasSpec) {
          if (resetref) {
             stype := its.csys.conversiontype (type='spectral');
             its.spectralRefMenu.selectlabel(stype);
          }

# Force conversion in its.convert to new label type

          its.profile.x.currentSpecRef := '';

# This menu might have been disabled because the conversions failed.
# Re-enable it now

         if (is_agent(its.spectralRefMenu)) {
            ok := its.spectralRefMenu.disabled(F);
            its.spectralRefMenuIsDisabled := F;
         }
      }

# Update the menus

      ok := its.updateMenus();
      if (is_fail(ok)) fail;

# See if we have a spectral axis

      its.profile.x.isSpectral := its.isAxisThisType (its.profile.axis, 'spectral');
      if (is_fail(its.profile.x.isSpectral)) fail;
#
      ok := self.setnoprofile();
      return ok;
   }

### 
   const self.setnoprofile := function ()
   {
      wider its;
#
      its.profile.npoints := [=];
      its.profile.x.data := [=];
#
      its.profile.y.data := [=];          # Sets number of profiles to 0 
      its.profile.y.err := [=];       
      its.profile.y.unit := '';
      its.profile.mask := [=];   

# Clear display list but hang on to character size

      if (self.hasplotter()) {
         ch := its.plotter.qch()
         its.plotter.clear();        # CLear display list
         its.plotter.sch(ch);
      }
#
      return T;
   }


###
   const self.setordinate := function (data, mask=unset, err=unset, ci=1, ls=1, which=unset)
   {
      wider its;
#
      if (its.multi) {
         return throw ('setordinate can only be called in single abcissa mode',
                       origin='imageprofilesupport.setordinate');
      }
#
      s := shape(data);
      if (length(s)!=1) {
         return throw ('Data must be a vector', 
                        origin='imageprofilesupport.setordinate');
      }
#
      if (s != its.profile.npoints[1]) {
         return throw ('Data must be of length of the current abcissa', 
                        origin='imageprofilesupport.setordinate');
      }
# 
      local idx;
      if (is_unset(which)) {
         idx := self.nprofiles() + 1;
      } else {
         if (which <=0 || which > self.nprofiles()+1) {
            return throw ('Specified profile index is illegal',
                          origin='imageprofilesupport.setordinate');
         }
         idx := which;
      }

# Data and error

      its.profile.y.data[idx] := data;
      if (is_unset(err)) {
         its.profile.y.err[idx] := [];
      } else {
         s := shape(err);
         if (s != its.profile.npoints[1]) {
            return throw ('Error must be of length of the current abcissa', 
                          origin='imageprofilesupport.setordinate');
         }
#
         its.profile.y.err[idx] := abs(err);
      }

# Mask

      if (is_unset(mask)) {
         its.profile.mask[idx] := [];
      } else {
         s := shape(mask);
         if (length(s)!=1) {
            return throw ('Mask must be a vector', 
                          origin='imageprofilesupport.setordinate');
         }
#
         if (s != its.profile.npoints[1]) {
            return throw ('Mask must be of length of the current abcissa', 
                          origin='imageprofilesupport.setordinate');
         }
#
         its.profile.mask[idx] := mask;
      }
      its.profile.y.ci[idx] := ci;
      its.profile.y.ls[idx] := ls;
#
      return idx;
   }

###
   const self.setordinateunit := function (unit)
   {
      wider its;
#
      its.profile.y.unit := unit;
      return T;
   }

###
   const self.setprofile := function (abcissa, ordinate, orderr=unset, mask=unset, unit='pix', 
                                      doppler='radio', ci=1, ls=1, which=unset)
   {
      wider its;
#
      if (!its.multi) {
         return throw ('setprofile an only be called in multi-abcissa mode',
                       origin='imageprofilesupport.setprofile');
      }
#
      sa := shape(abcissa);
      if (length(sa)!=1) {
         return throw ('Abcissa must be a vector', 
                        origin='imageprofilesupport.setprofile');
      }
      so := shape(ordinate);
      if (length(so)!=1) {
         return throw ('Ordinate must be a vector', 
                        origin='imageprofilesupport.setprofile');
      }
      if (so!=sa) {
         return throw ('Abcissa and ordinate must same shape', 
                        origin='imageprofilesupport.setprofile');
      }
      if (!is_unset(orderr)) {
         if (shape(orderr) != sa) {
            return throw ('Abcissa and ordinate error must same shape', 
                          origin='imageprofilesupport.setprofile');
         }
      }
#
      local sm;
      if (!is_unset(mask)) {  
         sm := shape(mask);
         if (length(sm)!=1) {
            return throw ('Mask must be a vector', 
                           origin='imageprofilesupport.setprofile');
         }
         if (sm != sa) {
            return throw ('Mask, abcissa and ordinate must be the same shape', 
                           origin='imageprofilesupport.setprofile');
         }
      }
#
      local idx;
      if (is_unset(which)) {
         idx := self.nprofiles() + 1;
      } else {
         if (which <=0 || which > self.nprofiles()+1) {
            return throw ('Specified profile index is illegal',
                          origin='imageprofilesupport.setprofile');
         }
         idx := which;
      }

# Profile axis

      p2w := its.csys.axesmap(T);      # Map from pixel to world 
      worldprofileaxis := p2w[its.profile.axis];
      profileAxisUnit := its.csys.units()[worldprofileaxis];

# Set abcissa.  We convert from whatever we have got to absolute pixels.

      its.profile.npoints[idx] := sa;
      its.profile.x.data[idx] := [=];
      its.profile.x.data[idx].pixel := [=];
      its.profile.x.data[idx].nativeworld := [=];
      its.profile.x.data[idx].current := [=];
#
      local pa, wa;
      hasSpec := its.csys.findcoordinate(pa, wa, 'spectral');
      isSpectral := hasSpec && pa[1]==its.profile.axis;
      u := to_upper(unit);
#
      havePixel := F;            # We set pixel or native world
      if (u=='PIX') {
         its.profile.x.data[idx].pixel.abs := as_double(abcissa);
         havePixel := T;
      } else {
         havePixel := F;
         if (isSpectral) {
            if (!dq.compare(unit, 'km/s') && !dq.compare(unit, 'Hz')) {
               return throw ('The abcissa must be specified in velocity or frequency units',
                             origin='imageprofilesupport.setprofile');
            }

# Handle spectral axis

            if (dq.compare(unit, 'km/s')) {

# The native units of a SpectralCoordinate are consistent with Hz. So we must 
# convert to frequency

               freq := its.csys.velocitytofrequency(value=abcissa, frequnit=profileAxisUnit, 
                                                    doppler=doppler, velunit=unit);
               if (is_fail(freq)) fail;
               its.profile.x.data[idx].nativeworld.abs := freq;
            } else if (dq.compare(unit, 'Hz')) {

# The native units of a SpectralCoordinate are consistent with Hz. So  all we 
# need is a scale factor

               q := dq.quantity(1.0, unit);
               q2 := dq.convertfreq(q, profileAxisUnit);
               fac := dq.getvalue(q2) / dq.getvalue(q);
               its.profile.x.data[idx].nativeworld.abs := fac * abcissa;
            }
         } else {

# Handle non spectral axis.  Just need a scale factor.

            q := dq.quantity(1.0, unit);
            q2 := dq.convert(q, profileAxisUnit);
            fac := dq.getvalue(q2) / dq.getvalue(q);
            its.profile.x.data[idx].nativeworld.abs := fac * abcissa;
         }
      }

# Now make the other abcissa unit conversions

      rp := its.csys.referencepixel();
      if (havePixel) {

# We have absolute pixel to start with

         its.profile.x.data[idx].pixel.rel := its.profile.x.data[idx].pixel.abs - rp[its.profile.axis];

# Now convert to world

         absPix := array(rp, length(rp), sa);
         absPix[its.profile.axis,] := abcissa;
         absWorld := its.csys.toworldmany(absPix);
         if (is_fail(absWorld)) fail;
#
         relWorld := its.csys.torelmany(absWorld, T);
         if (is_fail(relWorld)) fail;
#
         its.profile.x.data[idx].nativeworld.abs := absWorld[worldprofileaxis,];   
         its.profile.x.data[idx].nativeworld.rel := [];
      } else {

# We have absolute world to start with

         rv := its.csys.referencevalue();
         absWorld := array(rv, length(rv), sa);
         absWorld[worldprofileaxis,] := its.profile.x.data[idx].nativeworld.abs;
         relWorld := its.csys.torelmany(absWorld, T);
         if (is_fail(relWorld)) fail;
         its.profile.x.data[idx].nativeworld.rel := [];

# Now convert to pixel

         absPix := its.csys.topixelmany(absWorld);
         if (is_fail(absPix)) fail;
         its.profile.x.data[idx].pixel.abs := absPix[its.profile.axis,];
         its.profile.x.data[idx].pixel.rel := its.profile.x.data[idx].pixel.abs - rp[its.profile.axis];
      }
#
      its.profile.x.name := its.csys.names()[worldprofileaxis];
      its.profile.x.nativeunit := its.csys.units()[worldprofileaxis];
#
      its.profile.x.data[1].current := its.profile.x.data[1].nativeworld.abs;  
      its.profile.x.currentunit := its.profile.x.nativeunit;  
      its.profile.x.currentabs := T;
      its.profile.x.currentOffValue := dq.quantity(0.0, its.profile.x.nativeunit);
#
      its.profile.y.data[idx] := ordinate;
      if (is_unset(orderr)) {
         its.profile.y.err[idx] := [];
      } else {
         its.profile.y.err[idx] := abs(orderr);
      }
#
      if (is_unset(mask)) {
         its.profile.mask[idx] := [];
      } else {
         its.profile.mask[idx] := mask;
      }
      its.profile.y.ci[idx] := ci;
      its.profile.y.ls[idx] := ls;
#
      return idx;
   }




###
   const self.setplotter := function (plotter)
   {
      wider its;
#
      if (!its.isPlotter(plotter)) {
         return throw ('Given plotter is not valid', origin='imageprofilesupport.setplotter');
      }

# Destroy old plotter if we can

      if (self.hasplotter() &&  its.canDestroyPlotter) {
         ok := its.plotter.done();      
         if (is_fail(ok)) {
            note (ok::message, priority='WARN', origin='imageprofilesupport.setplotter');
         }
      }
#
      its.plotter := plotter;
      its.pgframe := its.plotter.userframe();
      its.standAlone := T;
      its.plotter.clear();
      its.plotter.page();
#
      its.canDestroyPlotter := T;
      its.madeWidgets := F;
      self.setnoprofile();
#
      return T;
   }




###
    const self.setprofileaxis := function (profileaxis=unset)
    {
       wider its;
#
       its.profile.oldaxis := its.profile.axis;
       if (is_unset(profileaxis)) profileaxis := -1;
       its.profile.axis := profileaxis;
#
       its.profile.x.isSpectral := its.isAxisThisType (its.profile.axis, 'spectral');
#
       ok := T;
       if (its.madeWidgets) {
          ok := its.updateMenus();
       }
       return ok;
    }

###
   const self.setspectralref := function (value)
   {
       wider its;
#
       if (!is_agent(its.spectralRefMenu)) {
          note ('Spectral menu not yet created', priority='WARN', 
                 origin='imageprofilesupport.setSpectralRef');
          return T;
       }
#
       if (its.spectralRefMenuIsDisabled) {
          note ('Spectral menu is disabled', priority='WARN', 
                 origin='imageprofilesupport.setSpectralRef');
          return T;
       }
#
       ok := its.spectralRefMenu.selectlabel(value);
       if (is_fail(ok)) fail;
       if (!ok) return F;
#
       its.disableWidgets(T);
       ok := self.plot(which=its.profile.which);
       its.disableWidgets(F);
       if (is_fail(ok)) fail;
#
       self->spectralrefchange(its.spectralRefMenu.getvalue());
#
       return T;
   }


###
   const self.setyrangecallback := function (callback)
   {
      wider its;
#
      if (!is_function(callback)) {
         return throw ('You must set a valid function',
                       origin='setyrangecallback');
      }
#
      its.yRangeCallback := callback;
      return T;
   }

###
   const self.settitle := function (text, ci)
   {
      wider its;
      if (length(text)==length(ci)) {
         its.plot.title.text := text;
         its.plot.title.ci := ci;
      }  else {
         note ('text and ci must be same length',
               origin='imageprofilesupport.g',
               priority='WARN'); 
      }
#
      return T;
   }

###
   const self.which := function ()
   {
      return its.profile.which;
   }


### Constructor

    ok := self.setcoordinatesystem (csys, shp);
    if (is_fail(ok)) fail;
}
