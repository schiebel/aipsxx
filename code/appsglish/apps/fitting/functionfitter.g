# functionfitter.g: Easy fitting of data arrays
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
#   $Id: functionfitter.g,v 1.15 2004/11/30 06:01:04 nkilleen Exp $
#

pragma include once
include 'functionals.g'
include 'fitting.g'
include 'note.g'

functionfitter := subsequence ()
{

# Private data

   its:=[=]
#
   its.fitter := [=];                          # Fitter
#
   its.data := [=];                            # Data to fit
   its.data.x := unset;                        # Filled in once data set
   its.data.y := unset;
   its.data.yerr := unset;
   its.data.mask := unset;                     # Filled in once data set
#
   its.hasFit := F;                            # Do we have a solution for these data
#
   its.hasFunctional := F;                     # Have we set a functional yet ?
   its.fl := [=];                              # The functional to fit
   its.parametersSet := F;                     # Has the user set parameters to functional ?
#
   its.xunit := '';
   its.cs := [=];                              # Coordsys tool
   its.ips := [=];                             # Imageprofilesupport tool (only for plotting)
   its.axis := 1;
#
   its.f0 := [=];                              # Frame for plotter
   its.lastPlotMask := [];
#
   its.whenevers := [];

### Private functions

   const its.checkData := function ()
   {
      wider its;
#
      if (is_unset(its.data.x)) {
         return throw ('No data have been set yet', origin='functionfitter.checkData');
      }
      return T;
   }


###
   const its.checkDataShapes := function (x, y, yerr, mask)
   {
      wider its;
#
      if (length(shape(x)) != 1 && length(shape(y)) !=1) {
         return throw ('Data vectors must be 1-Dimensional',
                       origin='functionfitter.checkDataShapes');
      }
#
      nx := length(x);
      ny := length(y);
      n := as_integer(nx/ny);
      r := nx - n*ny;
      if (r != 0) {
         return throw ('Length of abcissa vector must be an integer times length of data',
                        origin='functionfitter.checkDataShapes');
      }
#
      if (!is_unset(yerr)) {
        if (length(yerr) != ny) {
           return throw ('Y error array is not the same length as the y data array',
                          origin='functionfitter.checkDataShapes');
        }
      }
#
      if (!is_unset(mask)) {
         if (length(mask) != ny) {
            return throw ('Mask array is not the same length as the y data array',
                           origin='functionfitter.checkDataShapes');
         }
      }
#
      return T;
   }

###
   const its.deactivateWhenevers := function ()
   {
      wider its;
#
      if (length(its.whenevers) == 2) {
         deactivate its.whenevers[1];
         deactivate its.whenevers[2];
      }
#
      return T;
   }


###   
   const its.destroyFunctional := function ()
   {
      wider its;
#
      ok := T;
      if (is_functional(its.fl)) {
         its.parametersSet := F;
         its.hasFunctional := F;
         ok := its.fl.done();
         its.fl := [=]; 
      }
      return ok;
   }

###   
   const its.destroyPlotter := function ()
   {
      wider its;
#
      ok := its.deactivateWhenevers();
#
      ok := T;
      if (length(its.ips)>0) {
         ok := its.ips.done();
         its.ips := [=];
         its.f0 := F;
      }
#
      return ok;
   }

###
   const its.done  := function () 
   {
      wider its;
      wider self;
#
      ok := its.deactivateWhenevers();
      ok := its.destroyFunctional();
      ok := its.destroyPlotter();
      if (length(its.fitter)>0) ok := its.fitter.done();
      if (length(its.cs)>0) ok := its.cs.done();
#
      val its := F;
      val self := F;
#
      return T;
   }

###
   const its.makeCoordSys := function (xunit)
   {
      wider its;
#
      include 'coordsys.g'
      if (is_coordsys(its.cs)) return T;
#
      its.cs := coordsys(tabular=T);
      if (is_fail(its.cs)) fail;
#
      n := length(its.data.x);
      p := 1:n;
      ok := its.cs.settabular(p,its.data.x)
      if (is_fail(ok)) fail;
#
      if (is_unset(xunit)) xunit := 'm';
      ok := its.cs.setunits(value=xunit, type='tabular', overwrite=T);
      if (is_fail(ok)) fail;
      return its.cs.setnames (value='x-axis', type='tabular');
   }

###
   const its.makePlotter := function (n)
   {
      wider its;

# We already have one...

      if (length(its.ips)>0) return T;

# Clean up frame

      its.f0 := F;
      dws.tk_hold();
      its.f0 := dws.frame();
      its.f0->unmap();
      dws.tk_release();
#
      include 'imageprofilesupport.g'
      its.ips := imageprofilesupport(its.cs, n); 
      if (is_fail(its.ips)) fail;
      ok := its.ips.setprofileaxis(its.axis)
      if (is_fail(ok)) fail;
#
      its.f0.f1 := dws.frame (its.f0);
      ok := its.ips.makeplotter(its.f0.f1, size=[450,320]);
      if (is_fail(ok)) fail;
#
      its.f0.f2 := dws.frame (its.f0, expand='x', height=1, side='left');
      ok := its.ips.makemenus(its.f0.f2);
      if (is_fail(ok)) fail;
      ok := its.ips.setabcissaunit('pix');
      if (is_fail(ok)) fail;
#
      its.f0.f2.f0 := dws.frame (its.f0.f2, height=1, width=10, expand='none');
      its.f0.dismiss := dws.button (its.f0.f2, text='Dismiss', type='dismiss');
      whenever its.f0.dismiss->press do {
         its.f0->unmap();
      }
      its.whenevers[1] := last_whenever_executed();
#
      ok := its.ips.makeabcissa([1]);
      if (is_fail(ok)) fail;

# Redraw if user resizes

      whenever its.f0->resize do {
         if (length(its.lastPlotMask)==4) {
            self.plot(its.lastPlotMask[1], its.lastPlotMask[2],
                      its.lastPlotMask[3], its.lastPlotMask[4]);
         }
      }
      its.whenevers[2] := last_whenever_executed();
#
      return T;
   }

###
   const its.updateFunctionalWithSolution := function ()
   {
      wider its;
#
      oldPars := its.fl.parameters();
      sol := its.fitter.solution();
      ok := its.fl.setparameters(sol);
      if (is_fail(ok)) fail;
      return oldPars;
   }


### Public functions

   const self.done := function ()
   {
      wider its;
#
      return its.done();
   }

###
   const self.filter := function (method='mean', width=5, progress=100)
   {
      wider its;
#
      if (is_fail(its.checkData())) fail;

# What to do about the input mask ?

      note ('The input data mask is ignored in computing the filtered data',
            priority='WARN', origin='functionfitter.filter');
      include 'datafilter.g';
      df := datafilter();
      y2 := df.filter (its.data.y, method=method, width=width, progress=progress)
      ok := df.done();
      if (is_fail(y2)) fail;
#
      its.data.y := y2;
      return T;
   }

###
   const self.fit := function (linear=T, fixed=unset)
   {
      wider its;

# Check functional set

      if (!is_functional(its.fl)) {
         return throw ('You must use setfunction to set the function to fit first',
                       origin='functionfitter.fit');
      }

# Check it has some parameters

      if (!linear && !its.parametersSet) {
         note ('Function parameters have not been set; all will be zero',
               priority='WARN', origin='functionfitter.fit');
      }

# See if we have any data

      if (is_fail(its.checkData())) fail;

# Check that the dimensionality of functional and data are the same.
# The data dimensionality has already been checked to be 
# consistent with itself

      dimF := its.fl.ndim();
      nx := length(its.data.x);
      ny := length(its.data.y);
      dimD := nx / ny;
      if (dimF==0) dimD := 0;
#
      if (dimF != dimD) {
         note (spaste ('Dimensionality of data =', dimD),
               priority='SEVERE', origin='functionfitter.fit');     
         note (spaste ('Dimensionality of functional = ', dimF),
               priority='SEVERE', origin='functionfitter.fit');     
         return throw ('Dimensions must be equal', origin='functionfitter.fit');
      }

# Pick out data masked good

      y := its.data.y[its.data.mask==T];

# Pick out abcissa masked good.  Bit of fiddling because of tuplet packing

      local x;
      if (dimF==0) {                # Catch special case and swet abcissa to empty
         x := [];
      } else if (dimF==1) {
         x := its.data.x[its.data.mask==T];
      } else {

# Deal with the fact that the x-data are stored in dim-tuplets

         x2 := its.data.x;
         x2::shape := [dimF,ny];
         x := x2[1:dimF, its.data.mask]
         x::shape := prod(shape(x));
     }
 
# Set parameter mask
 
      np := its.fl.npar()     
      if (np > 0) {
         pMask := array(T, np);
         if (!is_unset(fixed)) {
            nm := length(fixed);
            if (nm <=0 || nm>np) {
               return throw ('Fixed parameter mask is wrong length',
                             origin='functionfitter.fit');
            }
            pMask := !fixed;
         }
#
         ok := its.fl.setmasks(pMask);
         if (is_fail(ok)) fail;
      }

# Fit

      local ok;
      if (is_unset(its.data.yerr)) {
         if (linear) {
            ok := its.fitter.linear (its.fl, x, y);
         } else {
            ok := its.fitter.functional (its.fl, x, y);
         }
      } else {
         if (linear) {
            ok := its.fitter.linear (its.fl, x, y, its.data.yerr);
         } else {
            ok := its.fitter.functional (its.fl, x, y, its.data.yerr);
         }
      }
      if (is_fail(ok)) fail;
#
      its.hasFit := T;
      return its.fitter.solution();
   }


###
   const self.getchisq := function ()
   {
      wider its;
#
      if (!its.hasFit) {
         return throw ('You have not done a fit yet for these data',
                       origin='functionfitter.getchisq');
      }
#
      return its.fitter.chi2();
   }

###
   const self.getdata := function ()
   {
      wider its;
#
      r := [=];
      r.x := its.data.x;
      r.y := its.data.y;
      r.yerr := its.data.yerr;
      r.mask := its.data.mask;
#
      return r;
   }
     

###
   const self.getfunctionstate := function ()
   {
      wider its;
#
      return its.fl.state();
   }

###
   const self.geterror := function ()
   {
      wider its;
#
      if (!its.hasFit) {
         return throw ('You have not done a fit yet for these data',
                       origin='functionfitter.geterror');
      }
#
      return its.fitter.error();
   }

###
   const self.getmodel := function (fit=T)
   {
      wider its;
#
      if (!its.hasFunctional) {
         return throw ('You have not yet set a functional',
                       origin='functionfitter.getmodel');
      }
#
      local m;
      if (fit) {
         if (!its.hasFit) {
            return throw ('You have not done a fit yet for these data',
                          origin='functionfitter.getmodel');
         }

# Get old parameters and update functional with solution vector

         oldPars := its.updateFunctionalWithSolution();
         if (is_fail(oldPars)) fail;

# Generate model and set functional back the way it was

         m := its.fl.f(its.data.x);
         ok := its.fl.setparameters(oldPars);
         if (is_fail(ok)) fail;
      } else {
         m := its.fl.f(its.data.x);
      }
      if (is_fail(m)) fail;

# Return model

      return m;
   }

###
   const self.getresidual := function ()
   {
      wider its;
#
      if (!its.hasFit) {
         return throw ('You have not done a fit yet for these data',
                       origin='functionfitter.getresidual');
      }

# Get model

      m := self.getmodel ();
      if (is_fail(m)) fail;
#
      return its.data.y - m;
   }

###
   const self.getsolution := function ()
   {
      wider its;
#
      if (!its.hasFit) {
         return throw ('You have not done a fit yet for these data',
                       origin='functionfitter.getsolution');
      }
#
      return its.fitter.solution();
   }

###
   const self.medianclip := function (width=5, clip=5, progress=100)
   {
      wider its;
#
      if (is_fail(its.checkData())) fail;

# What to do about the input mask ?

      note ('The input data mask is ignored in computing the median clip mask',
            priority='WARN', origin='functionfitter.medianclip');
      include 'datafilter.g'
      df := datafilter();
      m := df.medianclip (its.data.y, width=width, clip=clip, progress=progress);
      df.done();
      if (is_fail(m)) fail;

# Replace mask

      its.data.mask := its.data.mask & m;
#
      return T;
   }


###
   const self.plot := function (data=T, model=T, fit=T, resid=F)
#
# Try to make all image/coordsys functions so that the image.g, coordsys.g
# scripts are only loaded if plotting is required.  This makes the logic a
# bit complicated.
#
# Plotting is only available for 1-D data
#
   {

      wider its;

# Any data ?  Without the data we don't have an abcissa (nPts required)

      if (is_unset(its.data.x)) {
         return throw ('Nothing to plot yet', origin='functionfitter.plot');
      }

# Now if the dimensionality of the data is not the same, we are not
# dealing with 1-D data.  I might have the functional available
# at this point, else we could look at its.fl.ndim()
#
      nx := length(its.data.x);
      ny := length(its.data.y);
      if (nx != ny) {
         return throw ('Can only plot 1-Dimensional data', origin='functionfitter.plot');
      }

# Make Coordinate System if needed

      ok := its.makeCoordSys (its.xunit);
      if (is_fail(ok)) fail;

# Make new plotter if needed

      n := length(its.data.x);
      ok := its.makePlotter (n);
      if (is_fail(ok)) fail;

# Let's see it !

      its.f0->map()

# Plot data

      ci := [];
      title := "";
      which := [];
      idx := 0;
      if (data) {
         idx +:= 1;
         which := [idx]
         ci := [1];
         title := ['Data'];
#
         ok := its.ips.setordinate (data=its.data.y, mask=its.data.mask, 
                                    err=its.data.yerr, 
                                    ls=-1, ci=ci[idx], which=idx);         
#         if (is_fail(ok)) fail;
         its.lastPlotMask[1] := T;
      } else {
         its.lastPlotMask[1] := F;
      }

# Plot model

      if (model) {
         d := self.getmodel (fit=F); 
         if (is_fail(d)) fail;
#
         idx +:= 1;
         ci := [ci, 7];
         title := [title, 'Model'];
#
         ok := its.ips.setordinate (data=d, mask=its.data.mask, 
                                    ls=2, ci=ci[idx], which=idx);
         if (is_fail(ok)) fail;
         which := [which, idx]
         its.lastPlotMask[2] := T;
      } else {
         its.lastPlotMask[2] := F;
      }

# Plot fit

      if (fit) {
         if (!its.hasFit) {
            note ('You have not done a fit yet for these data', priority='WARN',
                  origin='functionfitter.plot');
         } else {
            d := self.getmodel (fit=T);
            if (is_fail(d)) fail;
#
            idx +:= 1;
            ci := [ci, 9];
            title := [title, 'Fit'];
#
            ok := its.ips.setordinate (data=d, mask=its.data.mask, 
                                       ls=3, ci=ci[idx], which=idx);
            if (is_fail(ok)) fail;
            which := [which, idx];
            its.lastPlotMask[3] := T;
         }
      } else {
         its.lastPlotMask[3] := F;
      }

# Plot residual

      if (resid) {
         if (!its.hasFit) {
            note ('You have not done a fit yet for these data', priority='WARN',
                  origin='functionfitter.plot');
         } else {
            d := self.getresidual ();
            if (is_fail(d)) fail;
#
            idx +:= 1;
            ci := [ci, 2];
            title := [title, 'Resid'];
#
            ok := its.ips.setordinate (data=d, mask=its.data.mask, 
                                       ls=4, ci=ci[idx], which=idx);         
            if (is_fail(ok)) fail;
            which := [which, idx];
            its.lastPlotMask[4] := T;
         }
      } else {
         its.lastPlotMask[4] := F;
      }

# Find chi sq and put in title

      if (its.hasFit) {
         n := length(title);
         title[n+1] := spaste ('  ChiSq = ', self.getchisq());
         ci[n+1] := 1;
      }

# Draw title

      ok := its.ips.settitle (title, ci);
      if (is_fail(ok)) fail;

# Draw plot

      ok := its.ips.plot(which=which)
      if (is_fail(ok)) fail;
#
      return T;
   }


###
   const self.setcoordsys := function (csys, axis=1)
#
# Try to make all image/coordsys functions so that the image.g, coordsys.g
# scripts are only loaded if plotting is required.  This makes the logic a
# bit complicated.
#
   {
      wider its;
#
      include 'coordsys.g'
      if (is_coordsys(csys)) {
         if (is_coordsys(its.cs)) its.cs.done();
         its.cs := csys.copy();
         if (is_fail(its.cs)) fail;
      } else {
         return throw ('Invalid coordinate system supplied', 
                        origin='functionfitter.setcoordsys');
      }

# Set new profile axis

      its.axis := axis;

# Destroy the existing plotter which will force all if its internals
# to get re-made

      return its.destroyPlotter();
    }

###   
      const self.setdata := function (x, y, yerr=unset, mask=unset, xunit='m')
#
# We don't check dimensionality until we know what the dimensionality of
# the functional is.
#
# x,y and m are all stored as 1-d vectors
# x is packed in tuplets.  So if the functional is 2d, then
# x := ( [x1,x2], [x1,x2], ...)  and so on.   
#
   {
      wider its;

# Check data types

      ok := is_numeric(x) && is_numeric(y) &&
            !is_boolean(x) && !is_boolean(y);
      if (!ok) {
         return throw ('Input data are not numeric', 
                        origin='functionfitter.setdata');
      }
      if (!is_unset(yerr)) {
        ok := is_numeric(yerr) && !is_boolean(yerr);
        if (!ok) {
           return throw ('Input y errors are not numeric', 
                          origin='functionfitter.setdata');
        }
      }

# Check data shapes

      ok := its.checkDataShapes (x, y, yerr, mask);
      if (is_fail(ok)) fail;

# Set data

      its.data.x := x;
      its.data.y := y;
      its.data.yerr := yerr;
      if (is_unset(mask)) {
         its.data.mask := array(T, length(its.data.y));
      } else {
         its.data.mask := mask; 
      }

# Trigger new Coordsys creation if need be

      if (its.xunit != xunit) {
         if (length(its.cs)>0) {
            ok := its.cs.done();
            its.cs := [=];
         }
      }
      its.xunit := xunit;
      its.hasFit := F;

# Destroy old plotter and force it to be remade

      return its.destroyPlotter();
   }


###
   const self.setdatafromtable := function (name, cold=unset, cole=unset, colm=unset, xunit='m',
                                            autoheader=F)
   {
      wider its;

# Does the file exist

      include 'os.g'
      ok := dos.fileexists(name);
      if (!ok) {
         return throw ('Input file does not exist', origin='setdatafromtable');
      }

# Is the table aips++ or ascii ?
   
      include 'table.g'
      ascii := !tableexists (name);

# Open file

      local t;
      local tName;
      if (ascii) {
         note ('Assuming input file is an ascii table', priority='NORMAL',
               origin='functionfitter.setdatafromtable');
#     
         tName := 'functionfitter.temptable';
         ok := dos.remove(pathname=tName, follow=T, mustexist=F);
         t := tablefromascii (tablename=tName, asciifile=name,  autoheader=autoheader, 
                              readonly=T, ack=F);
      } else {
         t := table(tablename=name, ack=F, readonly=T);
      }
      if (is_fail(t)) fail;

# Get size

      nCol := t.ncols();
      if (nCol < 2) {
         return throw ('Table must have at least 2 columns',
                       origin='functionfitter.setdatafromtable');
      }
      names := t.colnames();

# Get data columns

      local n1, n2;
      if (is_unset(cold)) {
        n1 := names[1];
        n2 := names[2];
      } else {
        if (length(cold) != 2) {
           return throw ('Data column index array "cold" must be of length 2 or unset',
                        origin='functionfitter.setdatafromtable');
        }
        n1 := names[cold[1]];
        n2 := names[cold[2]];
      }
      its.data.x := t.getcol(n1);
      if (is_fail(its.data.x)) fail;

# Fiddle shape in case coordinates are N-D where N > 1

      s := prod(shape(its.data.x));
      its.data.x::shape := s;
#
      its.data.y := t.getcol(n2);
      if (is_fail(its.data.y)) fail;

# Now error column

      local n1, n2;
      if (is_unset(cole)) {
         its.data.yerr := unset;
      } else {
        if (length(cole) != 1) {
           return throw ('Data error column index array "cold" must be of length 1 or unset',
                         origin='functionfitter.setdatafromtable');
        }
#
        its.data.yerr := t.getcol(names[cole]);
        if (is_fail(its.data.yerr)) fail;
      }

# Now mask

      if (is_unset(colm)) {
         its.data.mask := array(T, length(its.data.y));
      } else {
        if (length(colm) != 1) {
           return throw ('Mask column index array "colm" must be of length 1 or unset',
                        origin='functionfitter.setdatafromtable');
        }
        its.data.mask := as_boolean(t.getcol(names[colm]));
        if (is_fail(its.data.mask)) fail;
      }
#
      ok := t.done();
      if (ascii) ok := dos.remove(tName, T);


# Check data shapes

      ok := its.checkDataShapes (its.data.x, its.data.y, 
                                 its.data.yerr, its.data.mask);
      if (is_fail(ok)) fail;


# Trigger new Coordsys creation if need be

      if (its.xunit != xunit) {
         if (length(its.cs)>0) {
            ok := its.cs.done();
            its.cs := [=];
         }
      }
      its.xunit := xunit;
      its.hasFit := F;

# Destroy old plotter and force it to be remade

      return its.destroyPlotter();
   }


###
   const self.setfunction := function (fn)
   {
      wider its;
#
      if (is_string(fn)) {
         if (is_fail(its.destroyFunctional())) fail;
         its.fl := dfs.compiled (fn);
         if (is_fail(its.fl)) fail;
      } else if (is_functional(fn)) {
         if (is_fail(its.destroyFunctional())) fail;

# Copy functional (not horrid Glish reference)

         its.fl := dfs.compiled('p0');            # Temporary
         if (is_fail(its.fl)) fail;
         ok := its.fl.copyfrom(fn);
         if (is_fail(ok)) fail;
      } else {
         return throw ('The function must be a string or functional',
                       origin='functionfitter.setfunction');
      }

# Needs new parameters to be set

      its.parametersSet := F;
      its.hasFunctional := T;
#
      return T;
   }


###
   const self.setparameters := function (pars) 
   {
      wider its;
#
      if (!is_numeric(pars) && !is_boolean(pars)) {
         return throw ('Parameters must be numeric',
                       origin='functionfitter.setparameters');
      }
#
      its.parametersSet := T;
      return its.fl.setparameters (pars);
   }

###
   const self.type := function ()
   {
      return 'functionfitter';
   }


# Constructor
 
   its.fitter := fitter();
   if (is_fail(its.fitter)) fail;
}


# Default tool

const defaultfunctionfitter := functionfitter();
const dff := ref defaultfunctionfitter;
note ('defaultfunctionfitter (dff) ready for use',
      priority='NORMAL', origin='functionfitter.g');
