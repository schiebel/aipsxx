# viewerimageanalysis.g: Viewer support for image analysis
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
# $Id: viewerimageanalysis.g,v 19.11 2005/07/27 18:50:52 dking Exp $
#

pragma include once

include 'coordsys.g'
include 'clipboard.g'
include 'guientry.g'
include 'image.g'
include 'measures.g';
include 'misc.g';
include 'note.g'
include 'os.g'
include 'pgplotter.g'
include 'quanta.g'
include 'regionmanager.g'
include 'serverexists.g'
include 'unset.g'
include 'widgetserver.g'
#
include 'viewerimagestatistics.g'
include 'viewerimagepositions.g'
include 'viewerimageregions.g'
include 'viewerimagesummaries.g'
include 'viewerimageslices.g'
include 'viewerddprofile.g'

const viewerimageanalysis := subsequence (panel, widgetset=dws)
{
    if (!serverexists('dos', 'os', dos)) {
       return throw('The os server "dos" is not running',
                     origin='viewerimageanalysis.g');
    }
    if (!serverexists('drm', 'regionmanager', drm)) {
       return throw('The regionmanager server "drm" is not running',
                     origin='viewerimageanalysis.g');
    }
    if (!serverexists('dq', 'quanta', dq)) {
       return throw('The quanta server "dq" is not running',
                    origin='viewerimageanalysis.g');
    }
    if (!serverexists('dcb', 'clipboard', dcb)) {
       return throw('The clipboard server "dcb" is not running',
                     origin='viewerimageanalysis.g');
    }
    if (!serverexists('dms', 'misc', dms)) {
       return throw('The misc server "dms" is not running',
                     origin='viewerimageanalysis.g');
    }
#
    its := [=];
    its.ws := widgetset;
    its.ge := its.ws.guientry();           # Guientry tool
    if (is_fail(its.ge)) fail;
#
    its.panel := panel;                    # Reference to calling displaypanel
    its.viewer := its.panel.viewer();
    its.animator := its.panel.animator();
    if (is_fail(its.animator)) fail;

# Callback functions

    its.getDDOptions2 := [=];               # Get options record for named DD

# GUI elements

    its.roll := [=]                        # The rollups
    its.vis := [=];                        # Viewerimagestatistics tool
    its.vip := [=];                        # Viewerimagepositions tool
    its.vir := [=];                        # Viewerimageregions tool
    its.vid := [=];                        # Viewerimageslices tool
    its.visu := [=];                       # Viewerimagesummaries tool

    its.ddnames := "";                     # List of viewer DD names
    its.children := [=];                   # Child DD names used for real/imag, indexed by DDname
    its.parents := [=];                    # Parent ddname of children, indexed by child name
#
    its.imagetools := [=];                 # List of image tools, indexed by DDname
    its.coordsys := [=];                   # List of coordsys tools, indexed by DDname
    its.axisnames := [=];                  # World and pixel axis names indexed by DDname

    its.index := [=];                      # Index into its.ddnames of ddname
    its.active := as_boolean([]);          # List of whether active or not

#
    its.gui := [=];                        # Record to hold gui elements
#

### Private methods

###
   const its.add := function (ddname)
   {
      wider its;

# Statistics

      ok := its.vis.add (ddname);
      if (is_fail(ok)) fail;

# Position

      dds := its.panel.getdisplaydatas();
      ok := its.vip.add (ddname, dds[its.parents[ddname]]);
      if (is_fail(ok)) fail;

# Regions

      ok := its.vir.add (ddname);
      if (is_fail(ok)) fail;

# Distances

      ok := its.vid.add (ddname);
      if (is_fail(ok)) fail;

# Summaries

      ok := its.visu.add (ddname);
      if (is_fail(ok)) fail;
#
      return ok;
   }

###
   const its.delete := function (child)
   {
      wider its;

# Statistics

      ok := its.vis.delete (child);
      if (is_fail(ok)) fail;

# Position

      ok := its.vip.delete (child);
      if (is_fail(ok)) fail;

# Regions
      
      ok := its.vir.delete (child);
      if (is_fail(ok)) fail;

# Slices
      ok := its.vid.delete (child);
      if (is_fail(ok)) fail;


# Summaries 
      
      ok := its.visu.delete (child);
      if (is_fail(ok)) fail;
#
      return ok;
   }


###
   const its.find := function (ddname) 
   {
       if (has_field(its.index, ddname)) {
          return its.index[ddname];
       } else {
          return -1;
       }
   }

###
   its.getDisplayAxes := function (ddname)
   {
      wider its;
#
      rec := [=];

# Get DD options

      rec.ddOptions := its.getDDOptions(ddname);
      if (is_fail(rec.ddOptions)) fail; 

# Get axis names

      worldAxisNames := its.axisnames[ddname].world;
      pixelAxisNames := its.axisnames[ddname].pixel;
#
# Find first three display axes in CS are the first two display axes
#
      xAxisName := rec.ddOptions.xaxis.value;
      yAxisName := rec.ddOptions.yaxis.value;
#
      idxVec := ind(pixelAxisNames);
      xPixelAxis := idxVec[pixelAxisNames==xAxisName];
      yPixelAxis := idxVec[pixelAxisNames==yAxisName];
      if (length(xPixelAxis)==0 || length(yPixelAxis)==0) {
         return throw('Could not determine display pixel axes',
                      origin='imagevieweranalysis.getDisplayAxes');
      }
#
      idxVec := ind(worldAxisNames);
      xWorldAxis := idxVec[worldAxisNames==xAxisName];
      yWorldAxis := idxVec[worldAxisNames==yAxisName];
      if (length(xWorldAxis)==0 || length(yWorldAxis)==0) {
         return throw('Could not determine display world axes',
                      origin='imagevieweranalysis.getDisplayAxes');
      }
#
      rec.xAxisName := xAxisName;
      rec.yAxisName := yAxisName;
#
      rec.xPixelAxis := xPixelAxis;
      rec.yPixelAxis := yPixelAxis;
      rec.xWorldAxis := xWorldAxis;
      rec.yWorldAxis := yWorldAxis;
#
      rec.pixelAxisNames := pixelAxisNames;
      rec.worldAxisNames := worldAxisNames;
#
      return rec;
   }


###
    const its.getDDOptions := function (child) 
    {

# The dd name may have be a real/imag child. Find the parent

       parent := its.parents[child];
       return its.getDDOptions2(parent);
    }
    
###
   const its.getImageTool := function (ddname)
   {
      wider its;
      return its.imagetools[ddname];
   }


###    
   const its.getMovieAxis := function (ddname, ddOptions=unset)
   {
      wider its;
#
# If caller already knows ddOptions, save some time

      if (is_unset(ddOptions)) {
         ddOptions := its.getDDOptions(ddname); 
         if (is_fail(ddOptions)) fail;
      }
#
      movieAxis := -1;   
      if (has_field(ddOptions, 'zaxis')) {
         zAxisName := ddOptions.zaxis.value;
         axisNames := its.axisnames[ddname].pixel;      # Pixel axis order
#
         idxVec := ind(axisNames);
         movieAxis := idxVec[axisNames==zAxisName];
         if (length(movieAxis)==0) movieAxis := -1;
      }
#
      return movieAxis;    
   }


###    
   const its.getMoviePixel := function ()
   {
      wider its;
      return its.animator.currentzframe();
   }


###
   const its.getOtherPixels := function (ddname)
#
# Find the pixel coordinate for all non-display axes
# 
   {
#
# Find first two display axes
#
      rec := its.getDisplayAxes (ddname);
      if (is_fail(rec)) fail;
#
# Find movie axis
#
      val zAxis := its.getMovieAxis(ddname, rec.ddOptions);
      if (is_fail(zAxis)) fail;
#
# Create empty position
#
      csys := its.coordsys[ddname];
      pos := csys.referencepixel();
      const n := csys.naxes(world=F);
#
# Fill in the pixel coordinate for the z-axis (movie) axis and any hidden axes
#
#
      const nHidden := n - 3;
      if (n>2) {
         pos[zAxis] := its.getMoviePixel();
#
         if (nHidden>0) {
            for (k in 1:nHidden) {
               fn := spaste('haxis', k);
               hop := rec.ddOptions[fn];
#
               idxVec := ind(rec.pixelAxisNames);
               j := idxVec[rec.pixelAxisNames==hop.listname];
               if (length(j)>0) {
                  pos[j] := hop.value;       # Does the displayed region have any bearing on this value ?
               }
            }
         }
      }
#
      return pos;
   }


###
   const its.getZoomedRegion := function (ddname)
   {
      wider its;

# Get panel status 

      status := its.panel.status();
      if (is_fail(status)) fail;

# Create a pseudoregion record.  The blc/trc reflects the zoom

      r := [=];
      r.type := 'box';
      r.world.blc := status.paneldisplay.worldblc;
      r.world.trc := status.paneldisplay.worldtrc;  
      r.units := status.paneldisplay.axisunits;
      r.zindex := its.animator.currentzframe();

# Now convert to a true region

      rr := its.pseudoToWorldRegion(ddname, r, T);
#
      return rr;
   }



###
   const its.pixelToProfileBox := function (pixel, xAxis, yAxis, zAxis, shp, width, csys, asregion=T)
   {
#
# Set blc/trc of box holding profile centered on abs pix location 'pixel'
# which reflects movie and hidden axes
#
      p := csys.referencepixel();
      nIn := min(length(pixel), length(p));
      p[1:nIn] := pixel[1:nIn]
#
      blc := p;
      trc := blc;
#
      if (width>0) {
        blc[xAxis] -:= width;
        blc[yAxis] -:= width;
        blc[xAxis] := max(1,blc[xAxis]);
        blc[yAxis] := max(1,blc[yAxis]);
#
        trc[xAxis] +:= width;
        trc[yAxis] +:= width;
        trc[xAxis] := min(shp[xAxis],trc[xAxis]);
        trc[yAxis] := min(shp[yAxis],trc[yAxis]);   
      }
#
      blc[zAxis] := 1;
      trc[zAxis] := shp[zAxis];
#
      if (asregion) {
         return drm.box(blc=blc, trc=trc);
      } else {
         return [blc=blc, trc=trc];
      }
   }


###
   const its.pseudoPositionToAbsolutePixel := function (ref box, pseudoposition, 
                                                        width, ddname, asregion=T)
#
# Convert psuedo-position event to absolute pixel.  Also returns
# a record holding blc and trc for a profile extraction  at that pixel
# including the profile averaging width
# 
   {
#
# Find first two display axes
#
      rec := its.getDisplayAxes (ddname);
      if (is_fail(rec)) fail;
#
# Find movie axis
#
      val zAxis := its.getMovieAxis(ddname, rec.ddOptions);
      if (is_fail(zAxis)) fail;
#
# Create empty position
#
      im := its.imagetools[ddname]; 
      csys := its.coordsys[ddname];
      shp := im.shape();  
      pos := csys.referencepixel();
      const n := csys.naxes(world=F);
      blc := array(1,n);
      trc := shp;
#
# Fill in the pixel coordinate for the z-axis (movie) axis
#
      if (zAxis>0) {
         pos[zAxis] := pseudoposition.zindex;
#
# There may be hidden axes too.  Find them and their pixel values
#
         const nHidden := n - 3;
         if (nHidden>0) {
            for (k in 1:nHidden) {
               fn := spaste('haxis', k);
               hop := rec.ddOptions[fn];
#
               idxVec := ind(rec.pixelAxisNames);
               j := idxVec[rec.pixelAxisNames==hop.listname];
               if (length(j)>0) {
                  pos[j] := hop.value;       # Does the displayed region have any bearing on this value ?
                  blc[j] := hop.value;
                  trc[j] := hop.value;
               }
            }
         }
      }
#
# Convert position to world.  We use world because if a region
# is applied to the image, the linear coordinates do  not
# reflect that and I can't find out the blc of the region
#
      wpos := csys.toworld(pos, 'q');
      if (is_fail(wpos)) fail;
#   
# Fill in displayed plane position
#
      xypos := pseudoposition.world;
      xyposunits := pseudoposition.units;
#   
      idx := rec.xWorldAxis;
      wpos[idx] := dq.quantity(xypos[1], xyposunits[1]);
      if (is_fail(wpos[idx])) fail;
      idx := rec.yWorldAxis;
      wpos[idx] := dq.quantity(xypos[2], xyposunits[2]);
      if (is_fail(wpos[idx])) fail;
# 
# Convert to pixel and profile box
#
      pp := csys.topixel(wpos);
      if (is_fail(pp)) fail;
      pos := as_integer(pp + 0.5);
#  
      if (zAxis > 0) {
         val box := its.pixelToProfileBox (pos, rec.xPixelAxis, rec.yPixelAxis, 
                                           zAxis, shp, width, csys, asregion);
      } else {
         val box := [=];
      }
#
      return pos;
   }


###
   const its.computeProfileBox := function (pos, width, ddname, asregion=T)
#
# Compute the profile box from the given absolute pixel location
# and xy width
#
   {
# Get DD options

      rec := its.getDisplayAxes (ddname);
      if (is_fail(rec)) fail;

# Find movie axis

      zAxis := its.getMovieAxis(ddname, rec.ddOptions);
      if (is_fail(zAxis)) fail;

# Get coordsys

      im := its.imagetools[ddname];             # A reference
      csys := its.coordsys[ddname];
      shp := im.shape();
      if (is_fail(shp)) fail;

# Make the box

      if (zAxis > 0) {
         val box := its.pixelToProfileBox (pos, rec.xPixelAxis, rec.yPixelAxis, 
                                           zAxis, shp, width, csys, asregion);
      } else {
         val box := [=];
      }
#
      return ref box;
   }


###
   const its.pseudoToWorldRegion := function (ddname, pseudoregion, intersect=T)
   {
      wider its;
#
      ddOptions := its.getDDOptions(ddname);
      if (is_fail(ddOptions)) fail;
      im := its.imagetools[ddname];
      return drm.pseudotoworldregion(im, pseudoregion, ddOptions, intersect)
   }


###
   const its.update := function (ddname)
   {
      wider its;

# vip and vid need to know

      ok := its.vip.update(ddname);
      if (is_fail(ok)) fail;
#
      ok := its.vid.update(ddname);
      if (is_fail(ok)) fail;
#
      return T;
   }



### Public methods

###
    const self.add := function (ddname, datasource, datatype, ptype)
    {
       wider its;
#
       n := its.find(ddname);
       if (is_fail(n)) fail;
       if (n > 0 && its.active[n]) {
          note (spaste('An entry for DD ', ddname, ' already exists'),
                priority='WARN', origin='viewerimageanalysis.add');
          return T;
       }

# Create Image tool and replace/add in list

       if (n < 0) n := length(its.ddnames) + 1;
#
       if (datatype=='image') {
          if (ptype=='float') {
             its.imagetools[ddname] := image(datasource);
             if (is_fail(its.imagetools[ddname])) fail;  
             its.coordsys[ddname] := its.imagetools[ddname].coordsys();
             if (is_fail(its.coordsys[ddname])) fail;  
#
             its.axisnames[ddname] := [=];
             its.axisnames[ddname].world := its.coordsys[ddname].names();         # World axis order
             if (is_fail(its.axisnames[ddname].world)) fail; 
             p2w := its.coordsys[ddname].axesmap(toworld=T);
             its.axisnames[ddname].pixel := its.axisnames[ddname].world[p2w];     # Pixel axis order
             if (is_fail(its.axisnames[ddname].pixel)) fail;
#
             its.children[ddname] := ddname;
          } else if (ptype=='complex') {

# Real

             ddnameReal := spaste('R(', ddname, ')');
             expr := spaste('real("', datasource, '")');
             its.imagetools[ddnameReal] := imagecalc(pixels=expr);
             if (is_fail(its.imagetools[ddnameReal])) fail;  
             its.coordsys[ddnameReal] := its.imagetools[ddnameReal].coordsys();
             if (is_fail(its.coordsys[ddnameReal])) fail;  
#
             its.axisnames[ddnameReal] := [=];
             its.axisnames[ddnameReal].world := its.coordsys[ddnameReal].names();         # World axis order
             if (is_fail(its.axisnames[ddnameReal].world)) fail; 
             p2w := its.coordsys[ddnameReal].axesmap(toworld=T);
             its.axisnames[ddnameReal].pixel := its.axisnames[ddnameReal].world[p2w];     # Pixel axis order
             if (is_fail(its.axisnames[ddnameReal].pixel)) fail;

# Imaginary

             ddnameImag := spaste('I(', ddname, ')');
             expr := spaste('imag("', datasource, '")');
             its.imagetools[ddnameImag] := imagecalc(pixels=expr);
             if (is_fail(its.imagetools[ddnameImag])) fail;  
             its.coordsys[ddnameImag] := its.imagetools[ddnameImag].coordsys();
             if (is_fail(its.coordsys[ddnameImag])) fail;  
#
             its.axisnames[ddnameImag] := [=];
             its.axisnames[ddnameImag].world := its.coordsys[ddnameImag].names();         # World axis order
             if (is_fail(its.axisnames[ddnameImag].world)) fail; 
             p2w := its.coordsys[ddnameImag].axesmap(toworld=T);
             its.axisnames[ddnameImag].pixel := its.axisnames[ddnameImag].world[p2w];     # Pixel axis order
             if (is_fail(its.axisnames[ddnameImag].pixel)) fail;
#
             its.children[ddname] := [ddnameReal, ddnameImag];
          }
       } else if (datatype=='array') {

# Set up csys to be the same as that which LatticePADD
# makes. In future, I will retrieve the cs from the world
# canvas so this breakable code will go

          s := shape(datasource);
          ndim := length(s);
          cs := coordsys();
          if (is_fail(cs)) fail;
          axisNames := "";
          axisUnits := "";
          rp := [];
          for (i in 1:ndim) {
             axisNames[i] := spaste('Axis ', i);
             axisUnits[i] := '';
             rp[i] := 0.0;
          }
          ok := cs.addcoordinate(linear=ndim);
          if (is_fail(ok)) fail;
          ok := cs.setnames(axisNames);
          if (is_fail(ok)) fail;
          ok := cs.setunits(axisUnits, type='linear', overwrite=T);
          if (is_fail(ok)) fail;
          ok := cs.setreferencepixel(rp);
          if (is_fail(ok)) fail;
#
          if (ptype=='float') {
             its.imagetools[ddname] := imagefromarray(pixels=datasource, csys=cs, log=F);
             if (is_fail(its.imagetools[ddname])) fail;  
             its.coordsys[ddname] := its.imagetools[ddname].coordsys();
             if (is_fail(its.coordsys[ddname])) fail;  
#
             its.axisnames[ddname] := [=];
             its.axisnames[ddname].world := its.coordsys[ddname].names();         # World axis order
             if (is_fail(its.axisnames[ddname].world)) fail; 
             p2w := its.coordsys[ddname].axesmap(toworld=T);
             its.axisnames[ddname].pixel := its.axisnames[ddname].world[p2w];     # Pixel axis order
             if (is_fail(its.axisnames[ddname].pixel)) fail;
#
             its.children[ddname] := ddname;
          } else if (ptype=='complex') {

# Real

             ddnameReal := spaste('R(', ddname, ')');
             its.imagetools[ddnameReal] := imagefromarray(pixels=real(datasource), csys=cs, log=F);
             if (is_fail(its.imagetools[ddnameReal])) fail;  
             its.coordsys[ddnameReal] := its.imagetools[ddnameReal].coordsys();
             if (is_fail(its.coordsys[ddnameReal])) fail;  
#
             its.axisnames[ddnameReal] := [=];
             its.axisnames[ddnameReal].world := its.coordsys[ddnameReal].names();         # World axis order
             if (is_fail(its.axisnames[ddnameReal].world)) fail; 
             p2w := its.coordsys[ddnameReal].axesmap(toworld=T);
             its.axisnames[ddnameReal].pixel := its.axisnames[ddnameReal].world[p2w];     # Pixel axis order
             if (is_fail(its.axisnames[ddnameReal].pixel)) fail;

# Imaginary

             ddnameImag := spaste('I(', ddname, ')');
             its.imagetools[ddnameImag] := imagefromarray(pixels=imag(datasource), csys=cs, log=F);
             if (is_fail(its.imagetools[ddnameImag])) fail;  
             its.coordsys[ddnameImag] := its.imagetools[ddnameImag].coordsys();
             if (is_fail(its.coordsys[ddnameImag])) fail;  
#
             its.axisnames[ddnameImag] := [=];
             its.axisnames[ddnameImag].world := its.coordsys[ddnameImag].names();         # World axis order
             if (is_fail(its.axisnames[ddnameImag].world)) fail; 
             p2w := its.coordsys[ddnameImag].axesmap(toworld=T);
             its.axisnames[ddnameImag].pixel := its.axisnames[ddnameImag].world[p2w];     # Pixel axis order
             if (is_fail(its.axisnames[ddnameImag].pixel)) fail;
#
             its.children[ddname] := [ddnameReal, ddnameImag];
          }
       } else {

# Unhandled type of DD.  

          note (spaste('Cannot handled DD of type ', datatype),
                priority='WARN', origin='viewerimageanalysis.add');
          return F;
       }

# Add new entry/ies

       its.active[n] := T;
       its.index[ddname] := n;
       its.ddnames[n] := ddname;
#
       for (child in its.children[ddname]) {
          its.parents[child] := ddname;
	
# Add Tab to all rollups

          ok := its.add(child);
          if (is_fail(ok)) fail;
       }
#       
       return T;
    }

###
    const self.delete := function (ddname) 
    {
       wider its;
#
       n := its.find(ddname);
       if (is_fail(n)) fail;
#
       ok := T;
       if (n>0) {

# Deactivate active entry

          if (its.active[n]) {
             its.active[n] := F;

# We must destroy the Image tool(s), else a lock is left
# and other processes will be unable to access  the file

             for (child in its.children[ddname]) {
                ok := its.delete(child);
                if (is_fail(ok)) fail;
#
                ok := its.imagetools[child].done();
                if (is_fail(ok)) fail;
                ok := its.coordsys[child].done();
                if (is_fail(ok)) fail;
#
                its.axisnames[child] := [=];
             }
          } else {
             txt := spaste (ddname, ' is already deactivated');
             note (txt, priority='WARN', origin='viewerimageanalysis.g');
          }
       } else {
          txt := spaste ('There is no entry for ', ddname, ', cannot deactivate');
          note (txt, priority='WARN', origin='viewerimageanalysis.g');
       }
#
       return ok;
    }

###
   const self.dismiss := function ()
   {
      wider its;
      its.gui.f0->unmap();
      return T;
   }

###
    const self.done := function () 
    {
       wider its, self;
#
       for (parent in its.ddnames) {
          n := its.index[parent];
          if (its.active[n]) {
             for (child in its.children[parent]) {
                ok := its.imagetools[child].done();
                if (is_fail(ok)) fail;
                ok := its.coordsys[child].done();
                if (is_fail(ok)) fail;
             }
          }
       }

# Animator seems to be a reference, and when parent displaypanel
# gets the bullet, so does this one.

       if (is_agent(its.animator)) {
          ok := its.animator.done();
       }
       ok := its.ge.done();
#
       its.ws.popupremove(its.gui);
#
       ok := its.vis.done();
       ok := its.roll.stats.ru.done();
#
       ok := its.vip.done();
       ok := its.roll.pos.ru.done();
#
       ok := its.vir.done();
       ok := its.roll.reg.ru.done();
#
       ok := its.vid.done();
       ok := its.roll.dis.ru.done();
#
       ok := its.visu.done();
       ok := its.roll.summ.ru.done();
#
       val its := F;
       val self := F;
#
       return T;
    }

###
   const self.gui := function ()
   {
      wider its;
#
      its.gui.f0->map();
      return T;
   }


###
   const self.insertpolyline := function (value)
   {
      wider its;

# Always insert into distances rollup

      return its.vid.insertpolyline (value);
   }

###
   const self.insertposition := function (value)
   {
      wider its;

# Always insert into positions rollup

      return its.vip.insertposition (value);
   }


###
   const self.insertregion := function (value)
   {
      wider its;
#
# If we are in accumulation mode in the regions
# rollup we don't want to insert the itermediary
# pseudo regions

# Insert into statistics rollup only if rolled down

      if (!its.roll.stats.ru.hidden() && !its.vir.accumstate()) {
         ok := its.vis.insertregion (value, F);
         if (is_fail(ok)) fail;
      }

# Always insert into regions rollup

      ok := its.vir.insertregion (value);
      if (is_fail(ok)) fail;

# Insert into positions rollup only if rolled down

      if (!its.roll.pos.ru.hidden() && !its.vir.accumstate()) {
         ok := its.vip.insertregion (value, F);
         if (is_fail(ok)) fail;
      }
#
      return T;
   }


###
   const self.setcallbacks := function (callback1) 
   {
      wider its;
#
      if (is_function(callback1)) {
         its.getDDOptions2 := callback1;
      } else {
         return throw ('callback1 is not a function',
                        origin='viewerimageanalysis.setcallbacks');
      }
#
      return T;
   }

###
   const self.validtype := function (dtype, ptype)
   {
      return (dtype=='image' || dtype=='array') &&
             (ptype=='float' || ptype=='complex');
   }

###
   const self.update := function (ddname)
   {
      wider its;
      return its.update(ddname);
   }
     


### Constructor

   its.gui := [=];

# Top frame

   its.ws.tk_hold();
   its.gui.f0 := its.ws.frame(title='Image Analysis');  
   its.gui.f0->unmap();
   its.ws.tk_release();

# Statistics

   its.roll.stats := [=];
   its.roll.stats.ru := its.ws.rollup(its.gui.f0, title='Statistics', show=F, side='top');
   if (is_fail(its.roll.stats.ru)) fail;
   its.roll.stats.f0 := its.roll.stats.ru.frame();
   longhelp := spaste ('When this rollup is down, you can view statistics \n',
                       'generated from the registered images \n\n',
                       'This rollup responds to : \n',
                       '  Region events \n',
                       '    Simple - select box or polygon region icon from toolbox, \n',
                       '      use appropriate cursor button to outline region, \n',
                       '      double click within region to create \n',
                       '    Compound -  a compound region generated from the \n',
                       '      Regions rollup\n',
                       '  Buttons presses \n',
                       '    "Full"  - press the button labelled "Full" (full image) \n',
                       '    "Plane" - press the button labelled "Plane" (current \n',
                       '      displayed plane) \n\n',
                       ' Statistics for the generated region will be displayed for \n',
                       ' each registered DisplayData \n\n',
                       ' You can select the desired DisplayData by pressing the \n',
                       ' appropriate TAB button');
   its.roll.stats.ru.setpopuphelp('Roll down to control statistics', longhelp)
#
   its.vis := viewerimagestatistics(its.roll.stats.f0, widgetset=its.ws);
   if (is_fail(its.vis)) fail;
   ok := its.vis.setcallbacks(callback1=its.getImageTool,
                              callback2=its.getZoomedRegion,
                              callback3=its.pseudoToWorldRegion,
                              callback4=its.getMovieAxis);
   if (is_fail(ok)) fail;
   whenever its.vis->statistics do {
      self->statistics($value);
   }

# Positions

   its.roll.pos := [=];
   its.roll.pos.ru := its.ws.rollup(its.gui.f0, title='Positions', show=F, side='top');
   if (is_fail(its.roll.pos.ru)) fail;
   its.roll.pos.f0 := its.roll.pos.ru.frame();
   longhelp := spaste ('When this rollup is down, you can view positions \n',
                       'and profiles generated from the registered images \n\n',
                       'This rollup responds to : \n',
                       '  Position events \n',
                       '    Select the positions icon from the toolbox, \n',
                       '      use appropriate cursor button to select position, \n',
                       '      double click within position cursor to create \n',
                       '  Region events \n',
                       '    Simple - select box or polygon region icon from toolbox, \n',
                       '      use appropriate cursor button to outline region, \n',
                       '      double click within region to create \n',
                       '    Compound -  a compound region generated from the \n',
                       '      Regions rollup\n',
                       ' Positions and optionally profiles for the generated region \n',
                       ' will be displayed for each registered DisplayData \n\n',
                       ' You can select the desired DisplayData by pressing the \n',
                       ' appropriate TAB button');
   its.roll.pos.ru.setpopuphelp('Roll down to control positions', longhelp)
#
   its.vip := viewerimagepositions(its.roll.pos.f0, widgetset=its.ws);
   if (is_fail(its.vip)) fail;
   ok := its.vip.setcallbacks(callback1=its.getImageTool,
                              callback2=its.getZoomedRegion,
                              callback3=its.pseudoToWorldRegion,
                              callback4=its.getMovieAxis,
                              callback5=its.pseudoPositionToAbsolutePixel,
                              callback6=its.getMoviePixel,
                              callback7=its.computeProfileBox);
   if (is_fail(ok)) fail;
#
   whenever its.vip->position do {
      self->position($value);
   }

# Regions

   its.roll.reg := [=];
   its.roll.reg.ru := its.ws.rollup(its.gui.f0, title='Regions', show=F, side='top');
   if (is_fail(its.roll.reg.ru)) fail;
   its.roll.reg.f0 := its.roll.reg.ru.frame();
   longhelp := spaste ('When this rollup is down, you can collect regions\n',
                       'as you make them\n\n',
                       'This rollup responds to : \n',
                       '  Region events \n',
                       '    Simple - select box or polygon region icon from toolbox, \n',
                       '      use appropriate cursor button to outline region, \n',
                       '      double click within region to create \n',
                       '    Compound -  a compound region generated via\n',
                       '      the "Start/Finish" button\n\n',
                       ' As the regions are created they are captured in \n',
                       ' region entry widget, one for each registered DisplayData \n\n',
                       ' You can select the desired DisplayData by pressing the \n',
                       ' appropriate TAB button');
   its.roll.reg.ru.setpopuphelp('Roll down to control regions', longhelp)
#
   its.vir := viewerimageregions(its.roll.reg.f0, ddd=its.panel.annotationdd(),
                                 viewer=its.viewer, widgetset=its.ws);
   if (is_fail(its.vir)) fail;
   ok := its.vir.setcallbacks(callback1=its.getImageTool,
                              callback2=its.pseudoToWorldRegion,
                              callback3=its.getDisplayAxes);
   if (is_fail(ok)) fail;
#
   whenever its.vir->region do {
      self->region($value);

# Catch compound-generated regions and insert them

      if ($value.tag=='compound') {
         if (!its.roll.stats.ru.hidden()) {
            ok := its.vis.insertregion ($value.region, true=T);
            if (is_fail(ok)) {
               note (ok::message, priority='SEVERE', origin='viewerimageanalysis.g');
            }
         }
#
         if (!its.roll.pos.ru.hidden()) {
            ok := its.vip.insertregion ($value.region, true=T);
            if (is_fail(ok)) {
               note (ok::message, priority='SEVERE', origin='viewerimageanalysis.g');
            }
         }
      }
   }

# Distances

   its.roll.dis := [=];
   its.roll.dis.ru := its.ws.rollup(its.gui.f0, title='Slices', show=F, side='top');
   if (is_fail(its.roll.dis.ru)) fail;
   its.roll.dis.f0 := its.roll.dis.ru.frame();
   longhelp := spaste ('When this rollup is down, you can see image slices, when using the polyline tool.');
   its.roll.dis.ru.setpopuphelp('Roll down to view slice/distance information', longhelp)
#
   its.vid := viewerimageslices (its.roll.dis.f0, widgetset=its.ws);
   if (is_fail(its.vid)) fail;
#
   ok := its.vid.setcallbacks(callback1=its.getImageTool,
                              callback2=its.getDisplayAxes,
                              callback3=its.getOtherPixels);
   if (is_fail(ok)) fail;

# Summaries

   its.roll.summ := [=];
   its.roll.summ.ru := its.ws.rollup(its.gui.f0, title='Summaries', show=F, side='top');
   if (is_fail(its.roll.summ.ru)) fail;
   its.roll.summ.f0 := its.roll.summ.ru.frame();
   longhelp := spaste ('When this rollup is down, you can see image summaries.');
   its.roll.summ.ru.setpopuphelp('Roll down to view summaries', longhelp)
#
   its.visu := viewerimagesummaries(its.roll.summ.f0, widgetset=its.ws);
   if (is_fail(its.visu)) fail;
   ok := its.visu.setcallbacks(callback1=its.getImageTool);
   if (is_fail(ok)) fail;

# Dismiss

   its.gui.f0.f0 := its.ws.frame(its.gui.f0, side='right', expand='x', height=1);
   its.gui.f0.f0.dismiss := its.ws.button(its.gui.f0.f0, text='Dismiss', type='dismiss'); 
   its.ws.popuphelp(its.gui.f0.f0.dismiss, 'Dismiss GUI');
   whenever its.gui.f0.f0.dismiss->press do {
      its.gui.f0->unmap();
   }
}

