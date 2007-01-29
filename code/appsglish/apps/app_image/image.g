# image.g: Manipulate AIPS++ images
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
#   $Id: image.g,v 19.25 2005/09/15 02:34:46 nkilleen Exp $
#

pragma include once

include 'componentlist.g'
include 'coordsys.g'
include 'coordsyssupport.g'
include 'imagesupport.g'
include 'foreignimagesupport.g'
include 'measures.g';
include 'misc.g'
include 'note.g'
include 'os.g'
include 'plugins.g'
include 'quanta.g'
include 'regionmanager.g'
include 'serverexists.g'
include 'servers.g'
include 'substitute.g'
include 'table.g'
include 'unset.g'
include 'widgetserver.g'

#defaultservers.suspend(T)
#defaultservers.trace(T)


# Global functions

const is_image := function (thing)
{
   if (!is_record(thing)) return F;
   if (!has_field(thing, 'type')) return F;
   if (!is_function(thing.type)) return F;
   if (!(thing.type() == 'image')) return F;
   return T;   
}          



const images := function(which=unset, auto=T)
#
# Make image tools from disk files.
# This does not work owing to a Glish defect !
#
{
    if (!serverexists('defaultimagesupport', 'imagesupport', defaultimagesupport)) {
       return throw('The imagesupport server "defaultimagesupport" is not running',
                    origin='image.g');
    }
    if (!serverexists('dms', 'misc', dms)) {
       return throw('The misc server "dms" is not running',
                     origin='image.g');
    }
#
   if (is_unset(which)) {
      which := imagefiles();
   } else {
      which := dms.tovector(which, 'string');
   }
   if (is_fail(which)) fail;
#
   for (i in 1:length(which)) {
      if (auto) {
        name := defaultimagesupport.unusedtoolname('im');
      } else {
        name := which[i];       
      }
      s2 := spaste ('global ', name, ' := image(', as_evalstr(which[i]), ')');
      x := eval(s2);
      if (is_fail(x)) fail;
      note('Created Image tool : ', name, priority='NORMAL',
           origin='images');
   }
#
   return T;
}


const imagetools := function(showname=F, showclosed=T)
#
# Find all the Glish image tools
#
{
   list := symbol_names(is_image);
   if (length(list)==0) return [];
#
   list2 := "";
   j := 1;
   for (i in 1:length(list)) {
      if (!(list[i] ~ m/^_/)) {     # Strip anything with leading underscore
         s := list[i];
#
         ok := T;
         if (!showclosed) {
            cmd := spaste(list[i], '.isopen()');
            isopen := eval(cmd);
            if (!is_fail(isopen)) {
               if (!isopen) ok := F;
            }
         }
#
         if (ok) {
            if (showname) {
               cmd := spaste(list[i], '.name(T)');
               n := eval(cmd);
               if (!is_fail(n)) {
                 s := spaste (list[i], '(', n, ')');
               }
            }
#
            list2[j] := s;
            j +:= 1;  
         }
      }
   }
   if (length(list2)==0) return list2;
   return sort(list2);
}

const imagedones := function(which=unset)
#
# Done all the Glish image tools
#
{
    if (!serverexists('dms', 'misc', dms)) {
       return throw('The misc server "dms" is not running',
                     origin='imagedones');
    }
#
   l := dms.tovector(which, 'string');
   if (is_fail(l)) fail;
   if (length(l)==0) {
      l:= symbol_names(is_image);
      if (length(l)==0) {
         note ('There are no image tools to done presently', 
               origin='imagedones', priority='WARN');
         return T;
      }
   } 
#
   for (i in 1:length(l)) {
      if (!(l[i] ~ m/^_/)) {     # Strip anything with leading underscore
         if (is_defined(l[i])) {
            t := symbol_value(l[i]);
            if (is_image(t)) {
               t.done();
               txt := spaste ('Done applied to image tool "', l[i], '"');
            } else {
               txt := spaste ('Symbol "', l[i], '" is not an image');
            }
         } else {
            txt := spaste ('String "', l[i], '" is not an image');
         }
         note (txt, origin='imagedones', priority='NORMAL');
      }
   }
   return T;
}

const imagefiles := function(files='.', strippath=T, foreign=F)
{
   include 'catalog.g';
   if (!serverexists('dc', 'catalog', dc)) {
      return throw('The catalog server "dc" is not running',
                    origin='imagefiles');
   }
#   
   local types;
   if (foreign) {
      types := ['Image', 'Miriad Image', 'FITS'];
   } else {
      types := ['Image'];
   }
   return dc.list(listtypes=types, files=files, strippath=strippath);
}

const imagedemo := function()
{
    include 'imageservertest.g';
    return imageserverdemo();
}

const imagetest := function(which=unset)
{
    include 'imageservertest.g'
    return imageservertest(which=which);
}





# Users aren't to use this.
const _define_image := function (ref agent, id) {

    if (!serverexists('dos', 'os', dos)) {
       return throw('The os server "dos" is not running',
                     origin='image.g');
    }
    if (!serverexists('drm', 'regionmanager', drm)) {
       return throw('The regionmanager server "drm" is not running',
                     origin='image.g');
    }
    if (!serverexists('dms', 'misc', dms)) {
       return throw('The misc server "dms" is not running',
                     origin='image.g');
    }
    if (!serverexists('dws', 'widgetserver', dws)) {
       return throw('The widget server "dws" is not running',
                    origin='image.g');
    }
    if (!serverexists('defaultimagesupport', 'imagesupport', defaultimagesupport)) {
       return throw('The imagesupport server "defaultimagesupport" is not running',
                    origin='image.g');
    }
    if (!serverexists('defaultcoordsyssupport', 'coordsyssupport', defaultcoordsyssupport)) {
       return throw('The coordsyssupport server "defaultcoordsyssupport" is not running',
                    origin='image.g');
    }
    if (!serverexists('dq', 'quanta', dq)) {
       return throw('The quanta server "dq" is not running',
                    origin='image.g');
    }
    if (!serverexists('dm', 'measures', dm)) {
       return throw('The measures server "dm" is not running',
                    origin='image.g');
    }
#
    private := [=]
#
# CoordinateSystem.  We plonk it here to save fishing it out
# with function coordsys() every time we need it.  Any function
# that changes the image must done the old CS and assign a new one
#
    private.csys := [=];
#
# GUIs
#
    private.momentsgui := [=];
    private.momentsgui.standalone := T;
    private.momentsgui.gui := [=];
    private.momentsgui.imagename := '';
#
    private.maskgui := [=];
    private.maskgui.standalone := T;
    private.maskgui.gui := [=];
    private.maskgui.imagename := '';
#
    private.sepconvolvegui := [=];
    private.sepconvolvegui.standalone := T;
    private.sepconvolvegui.gui := [=];
    private.sepconvolvegui.imagename := '';
#
    private.sliceplotter := [=];
#
# imageviewersupport.  Does all of the viewer related stuff.
#
    private.ivs := [=];
#
# table holding log table 
#
    private.logtable := [=];
#
# This indicates whether tool, once made, is open or closed
#
    private.isopen := T;
#
# Make this closure an agent so it can emit events.  This
# code shouild be consolidated within servers.g
#
    private.agent := ref agent;
    private.id := id;
    public := [=]
    public := defaultservers.init_object(private)
    x := create_agent();
    for (i in field_names(x)) {
       public[i] := x[i];
    }

### Private methods

   
###
   const private.substitute := function (infile)
   {
      infile2 := infile;
      if (is_image(infile)) {
#
# This will let us get at the underlying "image" object
#
         rec := infile.id();
         infile2 := spaste('\'ObjectID=', as_string(rec), '\'');
      } else if (is_string(infile)) {
#                                   
# This means '$im' will work as well as just the file name
# (no substitution in that case)
#
         local idrec;
         infile2 := substitute(infile, 'image', idrec=idrec);
         if (is_fail(infile2)) fail;
      }
#
      return infile2;
   }

###
    const private.componentlistToVector := function (cl)
    {
       rec := [=];
       rec::shape := 0;
       if (!is_unset(cl)) {
          if (is_componentlist(cl)) {
             if (cl.length()>0) {
                n := cl.length();
                rec := r_array(cl.component(1,iknow=T), n);
                if (n>1) {
                   for (i in 1:n) {
                      rec[i] := cl.component(i,iknow=T);
                   }
                }
             }
          } else {
            return throw('Variable is not a valid componentlist',
                          origin='image.componentlistToVector');
          }
       }
       return rec;
    }

###
    const private.componentlistFromVector := function (skyvector)
    {
        cl := emptycomponentlist(log=F);
        if (is_fail(cl)) fail;
#
        const n := length(skyvector);
        if (n==0) return cl;
#
        if (has_field(skyvector::, 'shape')) {
           for (i in 1:n) {
              cl.add(skyvector[i], iknow=T);
           }
        } else {
           cl.add(skyvector, iknow=T);
        }
        return cl;
    }

###
   const private.convertPixels := function (ref pixels, 
                                            doFloat=T,
                                            where='private.convertPixels')
   {
      wider private;
#
      if (doFloat) {
         if (!is_float(pixels)) {
            if (is_complex(pixels) || is_dcomplex(pixels)) {
               note ('Converting complex pixels array to float type',
                     priority='WARN', origin=where);
            } 
            val pixels := as_float(pixels);
         }
      } else {
         if (!is_boolean(pixels)) {
            tp := type_name(pixels);            
            msg := spaste('Converting ', tp, ' pixels array to boolean type');
            note(msg, priority='WARN', origin=where);
         }
         val pixels := as_boolean(pixels);
      } 
#
      return T;
   }


###
   const private.signifyImageHasChanged := function ()
   {
      wider private;

# We may need to update any mask handler gui if the image has changed
# e.g. new masks.

      if (has_field(private.maskgui,'gui') && is_agent(private.maskgui.gui)) {
         private.maskgui.gui.update();
      }
#
      if (is_agent(private.ivs)) {
#
# Tell viewer related stuff to notice that image has changed
# and redisplay it
#
         return private.ivs.signifyImageHasChanged();
      } else {
         return T;
      }
   }


### Public methods

###
    private.addDegAxesRec := [_method="adddegaxes", _sequence=private.id._sequence]
    const public.adddegaxes := function(outfile=unset, direction=F, spectral=F, 
                                        stokes=unset, linear=F, tabular=F, overwrite=F)
    {
        wider private;
        private.addDegAxesRec.outfile := outfile;
        if (is_unset(outfile)) private.addDegAxesRec.outfile := '';
        private.addDegAxesRec.direction := as_boolean(direction);
        private.addDegAxesRec.spectral := as_boolean(spectral);
        if (is_unset(stokes)) stokes := '';
        private.addDegAxesRec.stokes := as_string(stokes);
        private.addDegAxesRec.linear := as_boolean(linear);
        private.addDegAxesRec.tabular := as_boolean(tabular);
        private.addDegAxesRec.overwrite := as_boolean(overwrite);
#
        id := defaultservers.run(private.agent, private.addDegAxesRec, F);
        if (is_fail(id)) fail;
        id2 := defaultservers.add(private.agent, id);
        ok := _define_image(private.agent, id2)
        if (!is_fail(ok)) ok.unlock();
        return ok;
    }
    const public.ada :=  public.adddegaxes;

###
    private.addNoiseRec := [_method="addnoise", _sequence=private.id._sequence]
    const public.addnoise := function(type='normal', pars=[0,1],
                                      region=unset, 
                                      zero=F)
    {
        wider private;
#
        private.addNoiseRec.region := defaultimagesupport.regioncheck(region);
        if (is_fail(private.addNoiseRec.region)) fail;
#
        private.addNoiseRec.type := as_string(type);
        private.addNoiseRec.pars := as_double(pars);
        private.addNoiseRec.zero := as_boolean(zero);
#
        ok := defaultservers.run(private.agent, private.addNoiseRec, F);
        public.unlock();
        private.signifyImageHasChanged ();
        return ok;
    }

###
    private.convolveRec := [_method="convolve", _sequence=private.id._sequence]
    const public.convolve := function(outfile=unset, kernel, scale=unset, region=unset, 
                                      mask=unset, overwrite=F, async=!dowait)
    {
        wider private;
        private.convolveRec.region := defaultimagesupport.regioncheck(region);
        if (is_fail(private.convolveRec.region)) fail;
#
        private.convolveRec.mask := defaultimagesupport.maskcheck(mask);
        if (is_fail(private.convolveRec.mask)) fail;
#
        if (is_string(kernel)) {
           private.convolveRec.kernelarray := [];
           private.convolveRec.kernelfilename := kernel;
        } else {
           ok := private.convertPixels (kernel, T);
           if (is_fail(ok)) fail;
           private.convolveRec.kernelarray := kernel;
           private.convolveRec.kernelfilename := '';
        }
#
        private.convolveRec.outfile := outfile;
        if (is_unset(outfile)) private.convolveRec.outfile := '';
#
        private.convolveRec.autoscale := F;
        private.convolveRec.scale := scale;
        if (is_unset(scale)) {
           private.convolveRec.autoscale := T;
           private.convolveRec.scale := 1.0;
        }
#
        private.convolveRec.overwrite := as_boolean(overwrite);
#
        id := defaultservers.run(private.agent, private.convolveRec, async);
        if (is_fail(id)) fail;
#
        id2 := defaultservers.add(private.agent, id);
        ok := _define_image(private.agent, id2)
        if (!is_fail(ok)) ok.unlock();
        return ok;
    }
    const public.arrconvolve := function(outfile=unset, kernel, region=unset, 
                                      mask=unset, overwrite=F, async=!dowait)
    {
       note ('Function arrconvolve is deprectaed  in favour of function convolve',
             priority='WARN', otigin='image.arrconvolve');
       return public.convolve (outfile, kernel, region, mask, overwrite, async);
    }

###
    private.boundingboxRec := [_method="boundingbox", _sequence=private.id._sequence]
    const public.boundingbox := function(region=unset) {
        wider private;
        private.boundingboxRec.region := defaultimagesupport.regioncheck(region);
        if (is_fail(private.boundingboxRec.region)) fail;
#
 	id := defaultservers.run(private.agent, private.boundingboxRec);
        if (is_fail(id)) fail;
        return id;
    }
    const public.bb := public.boundingbox;

###
    private.brightnessunitRec := [_method="brightnessunit", _sequence=private.id._sequence]
    const public.brightnessunit := function () 
    {
        wider private;
	return defaultservers.run(private.agent, private.brightnessunitRec, F);
    }
    const public.bu := public.brightnessunit;

###
    private.calcRec := [_method="calc", _sequence=private.id._sequence]
    const public.calc := function(pixels='', async=!dowait)
    {
        wider private;
	private.calcRec.regions := [=];
        tmp := pixels;
        if (!is_string(pixels)) tmp := as_string(pixels);
	private.calcRec.expr := 
           substitute (tmp, "image region", idrec=private.calcRec.regions);
#
	id := defaultservers.run(private.agent, private.calcRec, async);
        if (is_fail(id)) fail;
        ok := public.unlock();
        ok := private.signifyImageHasChanged ();
        if (is_fail(ok)) fail;
        return id;
    }

###
    private.calcMaskRec := [_method="calcmask", _sequence=private.id._sequence]
    const public.calcmask := function(mask, name=unset, default=T)
    {
        wider private;
#
	private.calcMaskRec.regions := [=];
        private.calcMaskRec.expr := defaultimagesupport.maskcheck(mask, T, private.calcMaskRec.regions);
        if (is_fail(private.calcMaskRec.expr)) fail;
#
	private.calcMaskRec.name := name;
        if (is_unset(name)) private.calcMaskRec.name := '';
#
	private.calcMaskRec.default := default;
#
	id := defaultservers.run(private.agent, private.calcMaskRec, F);
        if (is_fail(id)) fail;
#
        ok := public.unlock();
        ok := private.signifyImageHasChanged ();
        if (is_fail(ok)) fail;
#
        return id;
    }


###
    private.closeRec := [_method="close", _sequence=private.id._sequence]
    const public.close := function() 
    {
	wider private;
        if (is_agent(private.ivs)) {
           ok := private.ivs.done();
           private.ivs := [=];
        }
#
        if (length(private.logtable) > 0) {
           ok := private.logtable.done();
           private.logtable := [=];
        }
        private.isopen := F;
#
        return defaultservers.run(private.agent, private.closeRec);
    }

###
    const public.continuumsub := function(outline=unset,
                                          outcont='continuumsub.im',
                                          region=unset,
                                          channels=unset,
                                          pol=unset,
                                          fitorder=0,
                                          overwrite=F) 
    {

      wider private;
#
      pr := [=];
    
# Input parameters

      pr.outline := outline;
      pr.outcont := outcont;
      pr.channels := channels;
      if (!is_string(pol) && !is_unset(pol)) {
         return throw ('Stokes selection must be given as a String such as "Q"');
      }
      pr.pol := pol;
#
      if (!is_integer(fitorder)) {
         return throw ('Fit order must be integer');
      }
      pr.fitorder := fitorder;
      pr.overwrite := overwrite;

# Check input region

      pr.region := defaultimagesupport.regioncheck(region=region, 
                                                   csys=private.csys, 
                                                   torec=F);
      if (is_fail(pr.region)) fail;

    
# Form virtual image according to region argument and find coordinate system

      pr.image := public.subimage(region=pr.region, list=F);
      if (is_fail(pr.image)) fail;
      pr.csys:=pr.image.coordsys();
      if (is_fail(pr.csys)) fail;

# Spectral axis

      local spectralPixelAxis, spectralWorldAxis;
      foundSpectral := pr.csys.findcoordinate(pixel=spectralPixelAxis,
                                              world=spectralWorldAxis,
                                              type='spectral');
      if (is_fail(foundSpectral)) fail;
      if (!foundSpectral) {
         pr.image.done();
         pr.csys.done();
         return throw('No Spectral axis in this image');
      }

# Check non-degeneracy of spectral axis

      if (pr.image.shape()[spectralPixelAxis]==1) {
        pr.image.done();
        pr.csys.done();
        return throw ('There is only one channel in the selected region');
      }

# If requested, select additionally on Stokes axis

      pr.fitregion := unset;
      if (!is_unset(pr.pol)) {
         local stokesPixelAxis, stokesWorldAxis;
         foundStokes := pr.csys.findcoordinate(pixel=stokesPixelAxis, 
                                               world=stokesWorldAxis,
                                               type='stokes');
         if (is_fail(foundStokes)) fail;
         if (!foundStokes) {
            pr.image.done();
            pr.csys.done();
            return throw('No Stokes axis in this image');
         }

# Find reference value

        world := pr.csys.referencevalue (format='s');
        if (is_fail(world)) fail;

# Insert desire Stokes string and convert to pixel coordinates

        world[stokesWorldAxis] := pr.pol;
        pixel := pr.csys.topixel(world);
        if (is_fail(pixel)) {
          pr.image.done();
          pr.csys.done();
          fail;
        }

# Now create box region to select only on the Stokes axis. Pretty hard work.

        nDim := length(pr.image.shape());
        blc := array(drm.def(), nDim);
        trc := array(drm.def(), nDim);
        blc[stokesPixelAxis] := pixel[stokesPixelAxis];
        trc[stokesPixelAxis] := pixel[stokesPixelAxis];
#
        pr.fitregion := drm.box(blc=blc, trc=trc);
        if (is_fail(pr.fitregion)) fail;
      }

# Create OTF mask from given channels and axis

      pr.mask := unset;
      if (!is_unset(pr.channels)) {

# Check order

         pr.ncchan:=shape(pr.channels);
         if (pr.ncchan==1) {
            note('Only one continuum channel specified; forcing fitorder=0.',
                 origin='image.continuumsub');
            pr.fitorder:=0;
         }
         if (pr.fitorder < 0) {
            return throw ('Fit order must be non-negative');
         }

# Make mask

          pr.mask := spaste ('indexin(', spectralPixelAxis, ',', as_evalstr(pr.channels), ')');
      }

# Do fit and subtraction

      oline := pr.image.fitpolynomial(residfile=pr.outline,
                                      fitfile=pr.outcont,
                                      axis=spectralPixelAxis,
                                      order=pr.fitorder,
                                      region=pr.fitregion,
                                      mask=pr.mask,
                                      overwrite=pr.overwrite);
      if (is_fail(oline)) fail;

# Clean up intermediate products

      if (is_coordsys(pr.csys)) pr.csys.done();
      if (is_image(pr.image)) pr.image.done();
      if (is_region(pr.fitregion)) pr.fitregion.done();
      pr:=[=];
    
# Return Image tool to fitted image

      return ref oline;
    }


###
   private.convertfluxRec := [_method = 'convertflux',
                              _sequence = private.id._sequence];
   const public.convertflux := function(value, major, minor, type='gaussian', topeak=T)
   {
     wider private;
#
     private.convertfluxRec.value := defaultcoordsyssupport.valuetoquantum (value, public.brightnessunit());
     if (is_fail(private.convertfluxRec.value)) fail;
#
     private.convertfluxRec.major:= defaultcoordsyssupport.valuetoquantum (major);
     if (is_fail(private.convertfluxRec.major)) fail;
#
     private.convertfluxRec.minor := defaultcoordsyssupport.valuetoquantum (minor);
     if (is_fail(private.convertfluxRec.minor)) fail;
#
     private.convertfluxRec.type := as_string(type);
     private.convertfluxRec.topeak := as_boolean(topeak);
#
     return defaultservers.run(private.agent, private.convertfluxRec);
   }


###
    private.convolve2dRec := [_method="convolve2d", _sequence=private.id._sequence]
    const public.convolve2d := function(outfile=unset, axes=[1,2], type='gaussian',
                                        major, minor, pa=0.0, scale=unset,
                                        region=unset, mask=unset, 
                                        overwrite=F, async=!dowait)
    {
        wider private;
#
        private.convolve2dRec.region := defaultimagesupport.regioncheck(region);
        if (is_fail(private.convolve2dRec.region)) fail;
#
        private.convolve2dRec.mask := defaultimagesupport.maskcheck(mask);
        if (is_fail(private.convolve2dRec.mask)) fail;
#
	private.convolve2dRec.type := type;
	private.convolve2dRec.axes := dms.tovector(axes, 'integer');
        if (is_fail(private.convolve2dRec.axes)) fail;
#
        dq.define('pix', "100%");
        private.convolve2dRec.major := defaultcoordsyssupport.valuetoquantum (major, 'pix');
        if (is_fail(private.convolve2dRec.major)) fail;
#
        private.convolve2dRec.minor := defaultcoordsyssupport.valuetoquantum (minor, 'pix');
        if (is_fail(private.convolve2dRec.minor)) fail;
#
        private.convolve2dRec.pa := defaultcoordsyssupport.valuetoquantum (pa, 'deg');
        if (is_fail(private.convolve2dRec.pa)) fail;
#           
        private.convolve2dRec.outfile := outfile
        if (is_unset(outfile)) private.convolve2dRec.outfile := '';
#
        private.convolve2dRec.autoscale := F;
        private.convolve2dRec.scale := scale;
        if (is_unset(scale)) {
           private.convolve2dRec.autoscale := T;
           private.convolve2dRec.scale := 1.0;
        }
#
        private.convolve2dRec.overwrite := as_boolean(overwrite);
#
        id := defaultservers.run(private.agent, private.convolve2dRec, async);
        if (is_fail(id)) fail;
#
        id2 := defaultservers.add(private.agent, id);
        ok := _define_image(private.agent, id2)
        if (!is_fail(ok)) ok.unlock();
        return ok;
    }
    const public.c2d := public.convolve2d;

###
    const public.coordmeasures:=function(pixel=unset,
					 ref intensity=unset_value(),
					 ref direction=unset_value(),
					 ref frequency=unset_value(),
					 ref velocity=unset_value()) 
    {
        if (is_unset(pixel)) pixel := private.csys.referencepixel();
        if (is_fail(pixel)) fail;
        r := private.csys.toworld(pixel, 'm');
        if (is_fail(r)) fail;
#
        p := public.pixelvalue (pixel);
        if (is_fail(p)) fail;
        if (is_unset(p)) {
           r.mask := F;
        } else {
           r.intensity := p.value;
           r.mask := p.mask
        }
#
# This code looks dodgy to me !  We have to use the unset_value()
# function in the default arguments or Glish tries to change
# THE unset if coordmeasures is called with all the 'ref' args not given
#
	if (has_field(r, 'intensity')) {
	  val intensity := r.intensity;
	}
	if (has_field(r, 'direction')){ 
	  val direction := r.direction;
	}
	if (has_field(r, 'spectral')){ 
	  val frequency := r.spectral.frequency;
	  val velocity := r.spectral.radiovelocity;
	}
#
        return r;
    }

###
    private.coordsysRec := [_method="coordsys", _sequence=private.id._sequence]
    const public.coordsys := function (axes=unset)
    {
        wider private;
        private.coordsysRec.axes := dms.tovector(axes, 'integer');
        if (is_fail(private.coordsysRec.axes)) fail;
#
        id := defaultservers.run(private.agent, private.coordsysRec);
        if (is_fail(id)) fail;
        id2 := defaultservers.add(private.agent, id);
        id3 := _define_coordsys(agent, id2)
        id3.setparentname(public.name(strippath=T));
#
        return id3;
   }

###
    private.deconvolvecomponentlistRec := [_method="deconvolvecomponentlist", _sequence=private.id._sequence]
    const public.deconvolvecomponentlist := function (complist)
    {
        wider private;
        if (is_unset(complist)) {
           return throw ('You must specify a Componentlist');
        }
        private.deconvolvecomponentlistRec.list :=  private.componentlistToVector(complist);
        if (is_fail(private.deconvolvecomponentlistRec.list)) fail;
#
	id := defaultservers.run(private.agent, private.deconvolvecomponentlistRec);
        if (is_fail(id)) fail;
        return private.componentlistFromVector(id);
    }
    const public.dcl := public.deconvolvecomponentlist;

###
    private.decomposeRec := [_method="decompose", _sequence=private.id._sequence]
    const public.decompose := function(region=unset, mask=unset, simple=F,
                                       threshold=unset, ncontour=11,
                                       minrange=1, naxis=2, fit=T, maxrms=unset,
                                       maxretry=-1, maxiter=256, 
                                       convcriteria=0.0001)
    {
        wider private;
        private.decomposeRec.region := defaultimagesupport.regioncheck(region);
        if (is_fail(private.decomposeRec.region)) fail;
#
        private.decomposeRec.mask := defaultimagesupport.maskcheck(mask);
        if (is_fail(private.decomposeRec.mask)) fail;
#
        private.decomposeRec.simple := as_boolean(simple);
        if (is_unset(threshold)) {
           private.decomposeRec.threshold := -1.0;
        } else {
           private.decomposeRec.threshold := as_float(abs(threshold));
        }
#
        private.decomposeRec.ncontour := as_integer(ncontour);
        private.decomposeRec.minrange := as_integer(minrange);
        private.decomposeRec.naxis := as_integer(naxis);
        private.decomposeRec.fit := as_boolean(fit);
        private.decomposeRec.maxrms := as_float(maxrms);

        if (is_unset(maxretry)) {
            private.decomposeRec.maxretry := -1;
        } else {
            private.decomposeRec.maxretry := as_integer(maxretry);
        }

        private.decomposeRec.maxiter := as_integer(maxiter);
        private.decomposeRec.convcriteria := as_float(convcriteria);
#
	ok := defaultservers.run(private.agent, private.decomposeRec);
        return ok;
    }



###
    const public.delete := function(done=T)
    {
#
# Let's see if it exists.  If it doesn't, then the user has 
# deleted it, or its a readonly expression
#
        if (!public.ispersistent()) {
          msg := spaste('This image tool is not associated with a persistent disk file. It cannot be deleted')
          return throw(msg, origin='image.delete');
        }
#
        fileName := public.name(strippath=F);
        if (is_fail(fileName)) fail;
#
        if (strlen(fileName)==0 || !dos.fileexists(fileName, follow=T)) {
           msg := spaste('"', fileName, '" does not exist.');
           return throw (msg, origin='image.delete');
        }
#
# OK the file exists. Close ourselves first.  This deletes
# the temporary persistent image as well, if any and destroys
# the DDs associated with this image (they reference the image
# and will prevent us from deleting it)
#
       ok := public.close();
       if (is_fail(ok)) fail;
#
# Now try and blow it away.  If it's open, tabledelete won't delete it.
#
       result := tabledelete(fileName, T);
       if (is_fail(result)) {
          return throw (spaste('Failed to delete file "', fileName, '" (',
			       result::message, ')'), 
                        origin='image.delete');
       }
#
# Now done the image tool if desired.
#
       if (done) public.done();
#
       return T;
    }


### Public interface

###
    const public.done := function(delete=F)
    {
        wider private, public;
#
        if (delete) {
           return public.delete(done=T);
        }
#
        ok := defaultservers.done(private.agent, public.id());
        if (is_fail(ok)) fail;
#
# Do in private coordinate system
#
        ok := private.csys.done();
        if (is_fail(ok)) fail;
#
        if (ok) {
#
# Do in the GUIs
#
           if (has_field(private.momentsgui, 'gui') &&
               is_agent(private.momentsgui.gui)) {
              ok := private.momentsgui.gui.done();
              if (is_fail(ok)) {
                 note (ok::message, priority='SEVERE', origin='image.done');
                 note ('Trouble destroying moments GUI', priority='SEVERE', origin='image.done');
              }
           }
           if (has_field(private.maskgui, 'gui') &&
               is_agent(private.maskgui.gui)) {
              ok := private.maskgui.gui.done();
              if (is_fail(ok)) {
                 note (ok::message, priority='SEVERE', origin='image.done');
                 note ('Trouble destroying maskhandler GUI', priority='SEVERE', origin='image.done');
              }
           }
           if (has_field(private.sepconvolvegui, 'gui') &&
               is_agent(private.sepconvolvegui.gui)) {
              ok := private.sepconvolvegui.gui.done();
              if (is_fail(ok)) {
                 note (ok::message, priority='SEVERE', origin='image.done');
                 note ('Trouble destroying separable convolution GUI', priority='SEVERE', origin='image.done');
              }
           }
           if (length(private.sliceplotter) > 0) {
              private.sliceplotter.done();
              private.sliceplotter := [=];
           }
#
# Do in the viewer stuff
#
           if (is_agent(private.ivs)) {
             ok := private.ivs.done();
             if (is_fail(ok)) {
                note (ok::message, priority='SEVERE', origin='image.done');
                note ('Trouble destroying Imageviewersupport tool', priority='SEVERE', origin='image.done');
             }
           }
#
# Do in the logtable Table
#
           if (length(private.logtable) > 0) {
             ok := private.logtable.done();
             if (is_fail(ok)) {
                note (ok::message, priority='SEVERE', origin='image.done');
                note ('Trouble destroying logtable Table tool', priority='SEVERE', origin='image.done');
             }
           }
#
           val private := F;
           val public := F;
        }
        return ok;
    }


###
    private.fftRec := [_method="fft", _sequence=private.id._sequence]
    const public.fft := function(real=unset, imag=unset, 
                                 amp=unset, phase=unset, 
                                 axes=unset, region=unset, mask=unset)
    {
        wider private;
#
        private.fftRec.real := real;
        if (is_unset(real)) {
           private.fftRec.real := '';
        }
        private.fftRec.imag := imag;
        if (is_unset(imag)) {
           private.fftRec.imag:= '';
        }
        private.fftRec.amp := amp;
        if (is_unset(amp)) {
           private.fftRec.amp := '';
        }
        private.fftRec.phase := phase;
        if (is_unset(phase)) {
           private.fftRec.phase := '';
        }
        private.fftRec.axes := axes;
        if (is_unset(axes)) {
           private.fftRec.axes := [];
        }
#
        private.fftRec.region := defaultimagesupport.regioncheck(region);
        if (is_fail(private.fftRec.region)) fail;
#
        private.fftRec.mask := defaultimagesupport.maskcheck(mask);
        if (is_fail(private.fftRec.mask)) fail;
#
	id := defaultservers.run(private.agent, private.fftRec);
        return id;
    }


###
    private.findsourcesRec := [_method="findsources", _sequence=private.id._sequence]
    const public.findsources := function(nmax=20, cutoff=0.1, region=unset,
                                         mask=unset, point=T, width=5, negfind=F)
    {
        wider private;
        private.findsourcesRec.region := defaultimagesupport.regioncheck(region);
        if (is_fail(private.findsourcesRec.region)) fail;
#
        private.findsourcesRec.mask := defaultimagesupport.maskcheck(mask);
        if (is_fail(private.findsourcesRec.mask)) fail;
#
        private.findsourcesRec.nmax := nmax;
        private.findsourcesRec.cutoff := cutoff;
        private.findsourcesRec.absfind := as_boolean(negfind);
        private.findsourcesRec.point := as_boolean(point);
        private.findsourcesRec.width := as_integer(width);
#
	id := defaultservers.run(private.agent, private.findsourcesRec);
        if (is_fail(id)) fail;
        return private.componentlistFromVector(id);
    }
    const public.fs := ref public.findsources;


 
###
    private.fitskyRec := [_method="fitsky", _sequence=private.id._sequence]
    const public.fitsky := function(ref pixels, 
                                    ref pixelmask, 
                                    ref converged, 
                                    region=unset,
                                    mask=unset,
                                    models="gaussian",
                                    estimate=unset, 
                                    fixed=unset,
                                    includepix=unset,
                                    excludepix=unset, 
                                    fit=T, deconvolve=F, list=T)
    {
        wider private;
        private.fitskyRec.region := defaultimagesupport.regioncheck(region);
        if (is_fail(private.fitskyRec.region)) fail;
#
        private.fitskyRec.mask := defaultimagesupport.maskcheck(mask);
        if (is_fail(private.fitskyRec.mask)) fail;
#
        private.fitskyRec.models := dms.tovector(models, 'string');
        if (is_fail(private.fitskyRec.models)) fail;
        private.fitskyRec.fixed := dms.tovector(fixed, 'string');
        if (is_fail(private.fitskyRec.fixed)) fail;
#
        private.fitskyRec.includepix := dms.tovector(includepix, 'float');
        if (is_fail(private.fitskyRec.includepix)) fail;
        private.fitskyRec.excludepix := dms.tovector(excludepix, 'float');
        if (is_fail(private.fitskyRec.excludepix)) fail;
#
        private.fitskyRec.estimate := private.componentlistToVector(estimate);
        if (is_fail(private.fitskyRec.estimate)) fail;
#
        private.fitskyRec.fit := fit;
        private.fitskyRec.deconvolve := deconvolve;
        private.fitskyRec.list := list;
#
	id := defaultservers.run(private.agent, private.fitskyRec);
        if (is_fail(id)) {
           val converged := F;
           val pixels := [];
           val mask := [];
           fail;
        } else {
           if (fit) {
              val pixels := private.fitskyRec.pixels;
              val pixelmask := private.fitskyRec.pixelmask;
              val converged := private.fitskyRec.converged;
           }
#
           return private.componentlistFromVector(id);
       }
    }

###
    private.fitallprofilesRec := [_method="fitallprofiles", _sequence=private.id._sequence]
    const public.fitallprofiles := function(region=unset, axis=unset,
                                            mask=unset, ngauss=1,
                                            poly=unset,  sigma=unset,
                                            fit=unset, resid=unset)
    {
        wider private;
        private.fitallprofilesRec.region := defaultimagesupport.regioncheck(region);
        if (is_fail(private.fitallprofilesRec.region)) fail;
#
        if (is_unset(axis)) {
           private.fitallprofilesRec.axis := -1;
        } else {
           private.fitallprofilesRec.axis := as_integer(axis);
        }
#
        if (is_unset(fit) && is_unset(resid)) {
           return throw('You must give an output fit or residual file',
                         origin='image.fitallprofiles');
        }
        if (is_unset(fit)) fit := '';
        if (is_unset(resid)) resid := '';
        private.fitallprofilesRec.fit := as_string(fit);
        private.fitallprofilesRec.resid := as_string(resid);
#
        if (is_unset(sigma)) sigma := '';
        private.fitallprofilesRec.sigma := as_string(sigma);
#
        private.fitallprofilesRec.mask := defaultimagesupport.maskcheck(mask);
        if (is_fail(private.fitallprofilesRec.mask)) fail;
#
        if (is_unset(ngauss)) {
           private.fitallprofilesRec.ngauss := -1;
        } else {
           private.fitallprofilesRec.ngauss := as_integer(ngauss); 
        }
#
        if (is_unset(poly)) {
           private.fitallprofilesRec.poly := -1;
        } else {
           private.fitallprofilesRec.poly := as_integer(poly);
        }
#
        return defaultservers.run(private.agent, private.fitallprofilesRec);
    }
    
###
    private.fitprofileRec := [_method="fitprofile", _sequence=private.id._sequence]
    const public.fitprofile := function(ref values, ref resid, 
                                        region=unset, axis=unset, 
                                        mask=unset, estimate=unset,
                                        ngauss=unset, poly=unset,
                                        fit=T, sigma=unset)


    {
        wider private;
        private.fitprofileRec.region := defaultimagesupport.regioncheck(region);
        if (is_fail(private.fitprofileRec.region)) fail;
#
        if (is_unset(axis)) {
           private.fitprofileRec.axis := -1;
        } else {
           private.fitprofileRec.axis := as_integer(axis);
        }
#
        if (is_unset(sigma)) sigma := '';
        private.fitprofileRec.sigma := as_string(sigma);
#
        private.fitprofileRec.mask := defaultimagesupport.maskcheck(mask);
        if (is_fail(private.fitprofileRec.mask)) fail;
#
        if (is_unset(estimate)) {
           private.fitprofileRec.estimate := [=];
        } else {
           private.fitprofileRec.estimate := estimate;
        }
#
        if (is_unset(ngauss)) {
           private.fitprofileRec.nmax := -1;
        } else {
           private.fitprofileRec.nmax := as_integer(ngauss);
        }
#
        if (is_unset(poly)) {
           private.fitprofileRec.baseline := -1;
        } else {
           private.fitprofileRec.baseline := as_integer(poly);
        }
#
        private.fitprofileRec.fit := fit;
#
        ok := defaultservers.run(private.agent, private.fitprofileRec);
        if (!is_fail(ok)) {
           val values :=  private.fitprofileRec.values;
           val resid :=  private.fitprofileRec.resid;
        }
        return ok;
    }


###
    private.fitpolyRec := [_method="fitpoly", _sequence=private.id._sequence]
    const public.fitpolynomial := function(residfile=unset, fitfile=unset, sigmafile=unset, 
                                           axis=unset, order=0, region=unset, mask=unset, 
                                           overwrite=F)
    {
        wider private;
        private.fitpolyRec.region := defaultimagesupport.regioncheck(region);
        if (is_fail(private.fitpolyRec.region)) fail;
#
        if (is_unset(axis)) {
           private.fitpolyRec.axis := -1;
        } else {
           private.fitpolyRec.axis := as_integer(axis);
        }
#
        if (is_unset(fitfile)) fitfile := '';
        if (is_unset(residfile)) residfile := '';
        private.fitpolyRec.outfit := as_string(fitfile);
        private.fitpolyRec.outresid := as_string(residfile);
#
        if (is_unset(sigmafile)) sigmafile := '';
        private.fitpolyRec.sigma := as_string(sigmafile);
#
        private.fitpolyRec.overwrite := as_boolean(overwrite);
#
        private.fitpolyRec.mask := defaultimagesupport.maskcheck(mask);
        if (is_fail(private.fitpolyRec.mask)) fail;
#
        if (is_unset(order)) {
           private.fitpolyRec.baseline := 0;
        } else {
           private.fitpolyRec.baseline := as_integer(order);
        }
#
        id := defaultservers.run(private.agent, private.fitpolyRec);
        if (is_fail(id)) fail;
        id2 := defaultservers.add(private.agent, id);
        ok := _define_image(private.agent, id2)
        if (!is_fail(ok)) ok.unlock();
        return ok;
    }
    const public.fp := public.fitpolynomial;


###
    private.getchunkRec := [_method="getchunk", _sequence=private.id._sequence]
    const public.getchunk := function(blc=unset, trc=unset, inc=unset, list=F, 
                                      dropdeg=F, axes=unset, getmask=F) 
    {
        wider private;
#
        private.getchunkRec.blc := dms.tovector(blc, 'integer');
        if (is_fail(private.getchunkRec.blc)) fail;
        private.getchunkRec.trc := dms.tovector(trc, 'integer');
        if (is_fail(private.getchunkRec.trc)) fail;
        private.getchunkRec.inc := dms.tovector(inc, 'integer');
        if (is_fail(private.getchunkRec.inc)) fail;
        private.getchunkRec.list := as_boolean(list);
        private.getchunkRec.dropdeg := as_boolean(dropdeg);
        private.getchunkRec.getmask := as_boolean(getmask);
#
        if (is_unset(axes)) {
           private.getchunkRec.axes := [];
        } else {
           private.getchunkRec.axes := dms.tovector(axes, 'integer');
           if (is_fail(private.getchunkRec.axes)) fail;
        }
        id := defaultservers.run(private.agent, private.getchunkRec);
        if (is_fail(id)) fail;
#
        if (getmask) {
           return [pixels=private.getchunkRec.pixels, 
                   pixelmask=private.getchunkRec.pixelmask];
        } else {
           return private.getchunkRec.pixels;
        }
    }

###
    private.getregionRec := [_method="getregion", _sequence=private.id._sequence]
    const public.getregion := function(ref pixels=unset, ref pixelmask=unset, region=unset,
                                       axes=unset, mask=unset, list=F, dropdeg=F) 
    {
        wider private;

# What do we want to get ?

        getPixels := T;
        if (is_unset(pixels)) getPixels := F;
#
        getMask := T;
        if (is_unset(pixelmask)) getMask := F;
        if (!getPixels && !getMask) {
          note ('Neither pixels nor mask requested', 
                priority='WARN', origin='image.getregion');
          return T;
        }
        private.getregionRec.getpixels := getPixels;
        private.getregionRec.getmask := getMask;
#
        private.getregionRec.region := defaultimagesupport.regioncheck(region);
        if (is_fail(private.getregionRec.region)) fail;
#
        private.getregionRec.mask := defaultimagesupport.maskcheck(mask);
        if (is_fail(private.getregionRec.mask)) fail;
#
        private.getregionRec.list := list;
        private.getregionRec.dropdeg := dropdeg;
#
        if (is_unset(axes)) {
           private.getregionRec.axes := [];
        } else {
           private.getregionRec.axes := dms.tovector(axes, 'integer');
           if (is_fail(private.getregionRec.axes)) fail;
        }
#
 	id := defaultservers.run(private.agent, private.getregionRec);
        if (is_fail(id)) fail;
#      
        if (getPixels) val pixels := private.getregionRec.pixels;
        if (getMask)   val pixelmask := private.getregionRec.pixelmask;
#
        return id;
    }

###
    private.getsliceRec := [_method="getslice", _sequence=private.id._sequence]
    const public.getslice := function(x, y, axes=[1,2], coord=unset, 
                                      npts=unset, method='linear', plot=F)
    {
        wider private;
#
        shp := public.shape();
#
        if (is_unset(coord)) {
           private.getsliceRec.coord := array(1, length(shp));
        } else {
           private.getsliceRec.coord := dms.tovector(coord, 'integer');
           if (is_fail(private.getsliceRec.coord)) fail;
        }
#
        private.getsliceRec.axes := dms.tovector(axes, 'integer');
        if (is_fail(private.getsliceRec.axes)) fail;
#
        private.getsliceRec.x := dms.tovector(x, 'double');
        if (is_fail(private.getsliceRec.x)) fail;
#
        private.getsliceRec.y := dms.tovector(y, 'double');
        if (is_fail(private.getsliceRec.y)) fail;
#
        if (is_unset(npts)) {
           private.getsliceRec.npts := 0;
        } else {
           private.getsliceRec.npts := as_integer(npts);
        }
        private.getsliceRec.method := as_string(method);
#
        id := defaultservers.run(private.agent, private.getsliceRec);
        if (is_fail(id)) fail;
#
        rec := [=];
        rec.pixels := private.getsliceRec.pixels;
        rec.mask := private.getsliceRec.pixelmask;
        rec.xpos := private.getsliceRec.xpos;
        rec.ypos := private.getsliceRec.ypos;
        rec.distance := private.getsliceRec.distance;
        rec.axes := axes;
#
        if (plot) {
           include 'pgplotter.g'
           if (length(private.sliceplotter)==0) {
              private.sliceplotter := pgplotter();
           }
#
           yLab := spaste('Intensity (', public.brightnessunit(), ')');
           pixels := rec.pixels[rec.mask==T];
           distance := rec.distance[rec.mask==T];
           ok := private.sliceplotter.plotxy (distance, pixels, T, T, 'Distance (pixels)', yLab, 'Slice');
        }
#
        return rec;
    }

###
    private.hanningRec := [_method="hanning", _sequence=private.id._sequence]
    const public.hanning:=function(outfile=unset, region=unset, mask=unset,
                                   axis=unset, drop=T, overwrite=F, async=!dowait)
    {
        wider private;
#
        private.hanningRec.region := defaultimagesupport.regioncheck(region);
        if (is_fail(private.hanningRec.region)) fail;
#
        private.hanningRec.mask := defaultimagesupport.maskcheck(mask);
        if (is_fail(private.hanningRec.mask)) fail;
#
	private.hanningRec.outfile := outfile
	if (is_unset(outfile)) private.hanningRec.outfile := '';
	private.hanningRec.axis := axis;
        if (is_unset(axis)) private.hanningRec.axis := -10;
	private.hanningRec.drop := drop
        private.hanningRec.overwrite := as_boolean(overwrite);
#
	id :=  defaultservers.run(private.agent, private.hanningRec,async);
        if (is_fail(id)) fail;
#
        if (async) return id;
        id2 := defaultservers.add(private.agent, id);
        ok := _define_image(private.agent, id2)
        if (!is_fail(ok)) ok.unlock();
        return ok;
     }

###
    private.haslockRec := [_method="haslock", _sequence=private.id._sequence]
    const public.haslock := function()
    {
        wider private;
	id := defaultservers.run(private.agent, private.haslockRec);
        if (is_fail(id)) fail;
        return id;
    }

###
    private.histogramsRec := [_method="histograms", _sequence=private.id._sequence]
    const public.histograms := function(ref histout=[=], 
                                        axes=unset,
                                        region=unset, 
                                        mask=unset,
                                        nbins=25,
                                        includepix=unset,
                                        gauss=F, cumu=F, 
                                        log=F, list=T,
                                        plotter=unset,
                                        nx=1, ny=1, size=[600,450],
                                        force=F, disk=F, 
                                        async=!dowait) 
    {
        wider private;
        private.histogramsRec.region := defaultimagesupport.regioncheck(region);
        if (is_fail(private.histogramsRec.region)) fail;
#
        private.histogramsRec.mask := defaultimagesupport.maskcheck(mask);
        if (is_fail(private.histogramsRec.mask)) fail;
#
	private.histogramsRec.axes := dms.tovector(axes, 'integer');
	if (is_fail(private.histogramsRec.axes)) fail;
	private.histogramsRec.nbins := nbins;
	private.histogramsRec.includepix := dms.tovector(includepix, 'float');
	if (is_fail(private.histogramsRec.includepix)) fail;
	private.histogramsRec.gauss := gauss;
	private.histogramsRec.cumu := cumu;
	private.histogramsRec.log := log;
	private.histogramsRec.list := list;
#
	private.histogramsRec.plotter := plotter;
        if (is_unset(plotter)) private.histogramsRec.plotter := '';
#
	private.histogramsRec.nx := nx;
	private.histogramsRec.ny := ny;
	private.histogramsRec.size := as_integer(size);
#
	private.histogramsRec.force := force;
	private.histogramsRec.disk := disk;
        if(strlen(private.histogramsRec.plotter)!=0) async:=F
	id := defaultservers.run(private.agent, private.histogramsRec, async);
        if (is_fail(id)) fail;
#
        if (!async) val histout := private.histogramsRec.histout;
	return id;
    }
    const public.histo := public.histograms;

###
    private.historyRec := [_method="history", _sequence=private.id._sequence]
    const public.history := function(list=F, browse=T)
    {
        wider private;
        if (browse) {
           if (length(private.logtable)==0) {
              include 'table.g';
              name := public.name(F);
              if (is_fail(name)) fail;
#
              if (tableexists(name)) {
                 t := table(public.name(F), ack=F);
                 if (is_fail(t)) fail;
#
                 kw := t.getkeywords();
                 if (is_fail(kw)) fail;
                 ok := t.done();
                 if (is_fail(ok)) fail;
#
                 if (has_field(kw, 'logtable')) {
                    logtable := kw.logtable;
                    if (is_fail(logtable)) fail;
                    private.logtable := table(logtable, ack=F);  # cleaned up in done()
                    if (is_fail(private.logtable)) fail;
                    if (private.logtable.nrows()==0) {
                       note('The history is of zero length',
                            origin='image.history', priority='WARN');
                       return;
                    }
                 } else {
                    note('This image does not have a logtable',
                         origin='image.history', priority='WARN');
                    return;
                 }
              } else {
                 note ('This image is not disk based. Cannot browse the logtable - will send to logger instead',
                       origin='image.history', priority='WARN');
                 return public.history(list=T, browse=F);
              }                 
           }

# We have either a new or old table. have a look at it.

           if (length(private.logtable)>0) {
              return private.logtable.browse();
           }
        } else {
           wider private;
           private.historyRec.list := list;
           ok := defaultservers.run(private.agent, private.historyRec);
           if (is_fail(ok)) fail;
#
           if (list) {
              return T;
           } else {
              return ok;
           } 
        }
    }

###
    const public.id := function()
    {
        wider private;
        return private.id.objectid;
    }

###
    private.insertRec := [_method="insert", _sequence=private.id._sequence]
    const public.insert := function(infile, region=unset, locate=unset, dbg=0)
    {
        wider private;
        private.insertRec.region := defaultimagesupport.regioncheck(region);
        if (is_fail(private.insertRec.region)) fail;
#
	private.insertRec.infile := private.substitute (infile);
        if (is_fail(private.insertRec.infile)) fail;
#
        if (is_unset(locate)) {
           private.insertRec.doref := T;
           private.insertRec.locate := [];
        } else {
           private.insertRec.doref := F;
           private.insertRec.locate := dms.tovector(locate, 'double');
   	   if (is_fail(private.insertRec.locate)) fail;
        }
#
	private.insertRec.dbg := dbg;
#
	ok := defaultservers.run(private.agent, private.insertRec, F);
        if (is_fail(ok)) fail;
        public.unlock();
        private.signifyImageHasChanged ();
        return ok;
     }

###
   const public.isopen := function ()
   {
      return private.isopen;
   }

###
    private.ispersistentRec := [_method="ispersistent", _sequence=private.id._sequence] 
    const public.ispersistent := function()
    {
       return defaultservers.run(private.agent, private.ispersistentRec);
    }

### 
    private.lockRec := [_method="lock", _sequence=private.id._sequence]
    const public.lock := function(write=F, nattempts=unset)
    {
        wider private;
        private.lockRec.read := !write;
        private.lockRec.nattempts := nattempts;
        if (is_unset(nattempts)) private.lockRec.nattempts := 0;
	id := defaultservers.run(private.agent, private.lockRec);
        if (is_fail(id)) fail;
        return id;
    }

###
    private.makecomplexRec := [_method="makecomplex", _sequence=private.id._sequence]
    const public.makecomplex := function(outfile, imag, region=unset, overwrite=F)
    {
        wider private;
#
         private.makecomplexRec.outfile := as_string(outfile);
         private.makecomplexRec.imag := as_string(imag);
         private.makecomplexRec.region := defaultimagesupport.regioncheck(region);
         if (is_fail(private.makecomplexRec.region)) fail;
         private.makecomplexRec.overwrite := as_boolean(overwrite);
#
	return defaultservers.run(private.agent, private.makecomplexRec, F);
    }

### 
    private.maskhandlerRec := [_method="maskhandler", _sequence=private.id._sequence]
    const public.maskhandler := function(op, ref name=unset) 
    {
        wider private;
        name2 := name;
        if (is_unset(name)) name2 := '';
	private.maskhandlerRec.inputnames := dms.tovector(name2, 'string');
	if (is_fail(private.maskhandlerRec.inputnames)) fail;
	private.maskhandlerRec.op := op;
	private.maskhandlerRec.output := F;
	id := defaultservers.run(private.agent, private.maskhandlerRec, F);
        if (is_fail(id)) fail;
#
        if (private.maskhandlerRec.output==T) {
           return private.maskhandlerRec.outputnames;
        }
        ok := public.unlock();

# Tell the image view to update itself if the mask has changed

        ops := split(op,'');
        n := min(3,length(ops));
        ops2 := spaste(ops[1:n]);
        if (ops2=='set' || ops2=='del') {
           ok := private.signifyImageHasChanged ();
           if (is_fail(ok)) fail;
        } else {
#
# SignifyImageHasChanged will update any maskhandler gui
# However, other maskhandler operations apart from 'del' and 'set'
# may require an update as well (e.g. 'cop')
#
           if (has_field(private.maskgui,'gui') && is_agent(private.maskgui.gui)) {
              private.maskgui.gui.update();
           }
        }
#
        return T;
    }
    const public.mh := public.maskhandler;

###
    const public.maskhandlergui := function(parent=F, widgetset=dws)
    {
      include 'imagemaskhandlergui.g';
      wider private;
      standalone := (is_boolean(parent) && parent==F);
      isAgent := is_agent(private.maskgui.gui);
      glen := length(private.maskgui);
      imagename := public.name(strippath=F);
#
      newgui := glen==0  ||                              # first time
                (has_field(private.maskgui,'gui') &&     # gui doned
                 !isAgent) ||
                (has_field(private.maskgui,'gui') &&     # standalone changed
                 isAgent &&                              # or image name changed
                 (private.maskgui.standalone!=standalone ||
                  private.maskgui.imagename!=imagename));
#
      if (newgui) {
         if (has_field(private.maskgui,'gui') && is_agent(private.maskgui.gui)) {
            private.maskgui.gui.done();
         }
         private.maskgui.gui := imagemaskhandlergui(parent=parent,
                                                 imageobject=public, 
                                                 widgetset=widgetset);
      } else {
#
# The image may have changed (the name change trap is not bullet proof)
#
         private.maskgui.gui.setimage(public);
         private.maskgui.gui.gui();
      }
      private.maskgui.standalone := standalone;
      private.maskgui.imagename := imagename;
      return ref private.maskgui.gui;
    }
    const public.mhgui := public.maskhandlergui;


### 
    private.maxfitRec := [_method="maxfit", _sequence=private.id._sequence]
    const public.maxfit := function(region=unset, point=T, width=5, negfind=F, list=T)
    {
        wider private;
        private.maxfitRec.region := defaultimagesupport.regioncheck(region);
        if (is_fail(private.maxfitRec.region)) fail;
        private.maxfitRec.absfind := as_boolean(negfind);
        private.maxfitRec.point := as_boolean(point);
        private.maxfitRec.width := as_integer(width);
#
	ok := defaultservers.run(private.agent, private.maxfitRec, F);
        if (is_fail(ok)) fail;
#
        cl := emptycomponentlist(log=F);
        if (is_fail(cl)) fail;
        cl.add(private.maxfitRec.sky, T);
        if (list) {
           cs := public.coordsys();
           ap := private.maxfitRec.abspixel;
           aw := cs.toworld(ap, 's');
           if (is_fail(aw)) fail;
           rw := cs.torel(aw);
           if (is_fail(rw)) fail;
           rp := cs.torel(ap,F);
           if (is_fail(rp)) fail;
           ok := cs.done();
           if (is_fail(ok)) fail;
#
           s0 := spaste ('Brightness     = ', cl.getfluxvalue(1), 
                         cl.getfluxunit(1));
           s1 := spaste ('Absolute pixel = ', ap);
           s2 := spaste ('Relative pixel = ', rp);
           s3 := spaste ('Absolute world = ', aw);
           s4 := spaste ('Relative world = ', rw);
           note (s0, priority='NORMAL', origin='image.maxfit');
           note (s3, priority='NORMAL', origin='image.maxfit');
           note (s4, priority='NORMAL', origin='image.maxfit');
           note (s1, priority='NORMAL', origin='image.maxfit');
           note (s2, priority='NORMAL', origin='image.maxfit');
        }
        return cl;        
    }

###
    private.miscinfoRec := [_method="miscinfo", _sequence=private.id._sequence]
    const public.miscinfo:=function()
    {
        wider private;
	id := defaultservers.run(private.agent, private.miscinfoRec);
        if (is_fail(id)) fail;
        return id;
    }
    const public.mi := ref public.miscinfo;


###
    private.modifyRec := [_method="modify", _sequence=private.id._sequence]
    const public.modify := function(model, region=unset, mask=unset, 
                                    subtract=T, list=T,
                                    async=!dowait)
    {
        wider private;
        private.modifyRec.region := defaultimagesupport.regioncheck(region);
        if (is_fail(private.modifyRec.region)) fail;
#
        private.modifyRec.mask := defaultimagesupport.maskcheck(mask);
        if (is_fail(private.modifyRec.mask)) fail;
#
        private.modifyRec.model := private.componentlistToVector(model);
        if (is_fail(private.modifyRec.model)) fail;
#
        private.modifyRec.subtract := subtract;
        private.modifyRec.list := list;
#
	ok := defaultservers.run(private.agent, private.modifyRec, async);
        if (is_fail(ok)) fail;
#
        public.unlock();
#
        ok2 := private.signifyImageHasChanged ();
        if (is_fail(ok2)) fail;
#
        return ok;
    }

###
    private.momentsRec := [_method="moments", _sequence=private.id._sequence]
    const public.moments := function(moments = 0, axis=unset, 
                                     region=unset, mask=unset,
                                     method='', smoothaxes=unset,
                                     smoothtypes=unset, smoothwidths=unset,
                                     includepix=unset, excludepix=unset,
                                     peaksnr=3.0, stddev=0.0,
                                     doppler="radio", outfile=unset,
                                     smoothout=unset, plotter=unset,
                                     nx=1, ny=1, yind=F, overwrite=T,
                                     drop=T,  async=!dowait) 
    {
        wider private;
        private.momentsRec.region := defaultimagesupport.regioncheck(region);
        if (is_fail(private.momentsRec.region))fail;
#
        private.momentsRec.mask := defaultimagesupport.maskcheck(mask);
        if (is_fail(private.momentsRec.mask))fail;
#
	private.momentsRec.moments := dms.tovector(moments, 'integer');
        if (is_fail(private.momentsRec.moments)) fail;
	private.momentsRec.axis := axis
	if (is_unset(axis)) private.momentsRec.axis := -10;
	private.momentsRec.method := method
#
        private.momentsRec.smoothaxes := dms.tovector(smoothaxes, 'integer');
        if (is_fail(private.momentsRec.smoothaxes)) fail;
        private.momentsRec.smoothtypes := dms.tovector(smoothtypes, 'string');
        if (is_fail(private.momentsRec.smoothtypes)) fail;
#
        dq.define('pix', "100%");
        if (is_unset(smoothwidths)) {
           private.momentsRec.smoothwidths := "0pix";
        } else {
           private.momentsRec.smoothwidths := defaultcoordsyssupport.valuetovectorquantum (smoothwidths, 'pix');
           if (is_fail(private.momentsRec.smoothwidths)) fail;
        }
#
        private.momentsRec.includepix := dms.tovector(includepix, 'float');
        if (is_fail(private.momentsRec.includepix)) fail;
        private.momentsRec.excludepix := dms.tovector(excludepix, 'float');
        if (is_fail(private.momentsRec.excludepix)) fail;
#
        if (is_unset(peaksnr)) peaksnr := 3.0;
        private.momentsRec.peaksnr := peaksnr
        if (is_unset(stddev)) stddev := 0.0;
        private.momentsRec.stddev := stddev;
        private.momentsRec.velocity:= doppler;
#
        private.momentsRec.outfile := outfile
        if (is_unset(outfile)) private.momentsRec.outfile := '';        
#
        if (is_unset(smoothout)) smoothout := ''; 
        private.momentsRec.smoothout := smoothout;
#
        if (is_unset(plotter)) plotter := ''; 
        private.momentsRec.plotter := plotter;
#
        if (is_unset(nx)) nx := 1;
        private.momentsRec.nx := nx;
        if (is_unset(ny)) ny := 1;
        private.momentsRec.ny := ny;
#
        private.momentsRec.overwrite := as_boolean(overwrite);
        private.momentsRec.remove := as_boolean(drop);
        private.momentsRec.yind := yind
        if(strlen(private.momentsRec.plotter)!=0) async := F;
        id := defaultservers.run(private.agent, private.momentsRec,async);
        if (is_fail(id)) fail;
#
        if (async) return id;
        id2 := defaultservers.add(private.agent, id);
        ok := _define_image(private.agent, id2)
        if (!is_fail(ok)) ok.unlock();
        return ok;
    }

###
    const public.momentsgui := function(parent=F, widgetset=dws)
#
# The presence of widgetset here makes us include widgetserver.g
# at the top of image.g
#
    {
      wider private;
      include 'imagemomentsgui.g';
      standalone := (is_boolean(parent) && parent==F);
      isAgent := is_agent(private.momentsgui.gui);
      glen := length(private.momentsgui);
      imagename := public.name(strippath=F);
#
      newgui := glen==0  ||                                 # first time
                (has_field(private.momentsgui,'gui') &&     # gui doned
                 !isAgent) ||
                (has_field(private.momentsgui,'gui') &&     # standalone changed
                 isAgent &&                                 # or image name changed
                 (private.momentsgui.standalone!=standalone ||
                  private.momentsgui.imagename!=imagename));
      if (newgui) {
         if (has_field(private.momentsgui,'gui') && is_agent(private.momentsgui.gui)) {
            private.momentsgui.gui.done();
         }
         private.momentsgui.gui := imagemomentsgui(parent=parent,
                                                image=public, 
                                                widgetset=widgetset);
      } else {
#
# The image may have changed (the name trap is not bullet proof)
#
         private.momentsgui.gui.setimage(public);
         private.momentsgui.gui.gui();
      }
      private.momentsgui.standalone := standalone;
      private.momentsgui.imagename := imagename;
      return ref private.momentsgui.gui;
    }


##
    private.nameRec := [_method="name", _sequence=private.id._sequence]
    const public.name := function(strippath=F) 
    {
	wider private;
        private.nameRec.strippath := strippath
        id := defaultservers.run(private.agent, private.nameRec);
        if (is_fail(id)) fail;
        return id;
    }

###
    private.openRec := [_method="open", _sequence=private.id._sequence]
    const public.open := function(infile) 
    {
	wider private;
#
	private.openRec.infile := as_string(infile);
#
        id := defaultservers.run(private.agent, private.openRec);
        if (is_fail(id)) fail;
#
# Update internal copy of Coordinate System
#
        if (is_coordsys(private.csys)) {
           if (is_fail(private.csys.done())) fail;
        }
        private.csys := public.coordsys();
        if (is_fail(private.csys)) fail;   
#
        private.isopen := T;
        return id;
    }

###
    private.pixelvalueRec := [_method="pixelvalue", _sequence=private.id._sequence]
    const public.pixelvalue := function (pixel=unset)
    {
        wider private;
        if (is_unset(pixel)) {
           private.pixelvalueRec.pos := as_integer([]);
        } else {
           private.pixelvalueRec.pos := dms.tovector(pixel, 'integer');
           if (is_fail(private.pixelvalueRec.pos)) fail;
        }
        id := defaultservers.run(private.agent, private.pixelvalueRec);
        if (is_fail(id)) fail;
#
        if (private.pixelvalueRec.offimage==T) { 
           return unset;
        } else {
           rec := [=];
           rec.mask := private.pixelvalueRec.mask;
           rec.value := private.pixelvalueRec.value;
           rec.pixel := private.pixelvalueRec.pos;
           return rec;
        }
    }

###
    private.putchunkRec := [_method="putchunk", _sequence=private.id._sequence] 
    const public.putchunk := function(pixels, blc=unset, inc=unset, 
                                     list=F, locking=T, replicate=F)
    {
        wider private;
#
        ok := private.convertPixels (pixels, T);
        if (is_fail(ok)) fail;
        private.putchunkRec.pixels := pixels
#
        private.putchunkRec.blc := dms.tovector(blc, 'integer');
        if (is_fail(private.putchunkRec.blc)) fail;
        private.putchunkRec.inc := dms.tovector(inc, 'integer');
        if (is_fail(private.putchunkRec.inc)) fail;
        private.putchunkRec.list := as_boolean(list);
        private.putchunkRec.replicate := as_boolean(replicate);
        id := defaultservers.run(private.agent, private.putchunkRec);
        if (is_fail(id)) fail;
#
        if (locking) {
           ok := public.unlock();
           ok := private.signifyImageHasChanged ();
           if (is_fail(ok)) fail;
        }
#
        return id;
    }

###
    private.putregionRec := [_method="putregion", _sequence=private.id._sequence]
    const public.putregion := function(pixels=unset, pixelmask=unset,
                                       region=unset, list=F, usemask=T,
                                       locking=T, replicate=F)
    {
        wider private;
        if (is_unset(pixels) && is_unset(pixelmask)) {
           return throw('You must specify at least either the pixels or the mask',
                        origin='image.putregion');
        }
#
        if (is_unset(pixels)) pixels := as_float([]);
        ok := private.convertPixels (pixels, T);
        if (is_fail(ok)) fail;
#
        if (is_unset(pixelmask)) pixelmask := as_boolean([]);
        ok := private.convertPixels (pixelmask, F);
        if (is_fail(ok)) fail;
#
        private.putregionRec.region := defaultimagesupport.regioncheck(region);
        if (is_fail(private.putregionRec.region)) fail;
#
        private.putregionRec.pixels := pixels;
        private.putregionRec.pixelmask := pixelmask;
        private.putregionRec.list := list;
        private.putregionRec.usemask := as_boolean(usemask);
        private.putregionRec.replicate := as_boolean(replicate);
#
 	id := defaultservers.run(private.agent, private.putregionRec);
        if (is_fail(id)) fail;
#
        if (locking) {
           ok := public.unlock();
           ok := private.signifyImageHasChanged ();
           if (is_fail(ok)) fail;
        }
#
        return id;
    }

###
    private.rebinRec := [_method="rebin", _sequence=private.id._sequence]
    const public.rebin := function(outfile=unset, bin, region=unset, 
                                   mask=unset, dropdeg=F, overwrite=F,  async=!dowait)
    {
        wider private;
#
        private.rebinRec.factors := as_integer(bin);
#
	private.rebinRec.outfile := outfile
	if (is_unset(outfile)) private.rebinRec.outfile := '';
#
        private.rebinRec.region := defaultimagesupport.regioncheck(region);
        if (is_fail(private.rebinRec.region)) fail;
#
        private.rebinRec.mask := defaultimagesupport.maskcheck(mask);
        if (is_fail(private.rebinRec.mask)) fail;
#
        private.rebinRec.overwrite := as_boolean(overwrite);
        private.rebinRec.dropdeg := as_boolean(dropdeg);
#
	id :=  defaultservers.run(private.agent, private.rebinRec, async);
        if (is_fail(id)) fail;
        if (async) return id;
        id2 := defaultservers.add(private.agent, id);
        ok := _define_image(private.agent, id2)
        if (!is_fail(ok)) ok.unlock();
        return ok;
     }

###
    private.regridRec := [_method="regrid", _sequence=private.id._sequence]
    const public.regrid := function(outfile=unset, shape=unset, csys=unset, axes=unset,
                                    region=unset, mask=unset, method='linear', 
                                    decimate=10, replicate=F, doref=T,
                                    dropdeg=F, overwrite=F, force=F, async=!dowait, dbg=0)
    {
        wider private;
#
        if (is_unset(shape)) {
           private.regridRec.shape := public.shape();
           if (dropdeg) {
              shp := [];
              j := 1;
              for (i in 1:length(private.regridRec.shape)) {
                 if (private.regridRec.shape[i] != 1) {
                    shp[j] := private.regridRec.shape[i]
                    j +:= 1;
                 }
              }
              private.regridRec.shape := shp;
           }
        } else {
           private.regridRec.shape := dms.tovector(shape, 'integer');
           if (is_fail(private.regridRec.shape)) fail;
        }
        if (is_fail(private.regridRec.shape)) fail;
#
# We send the coordinate system through as a Record.  If unset
# we send an empty record that will get filled in in C++
#
        if (is_unset(csys)) {
           private.regridRec.csys := [=];
        } else {
           private.regridRec.csys := defaultimagesupport.coordinatescheck(csys);
        }
        if (is_fail(private.regridRec.csys)) fail;
#
	private.regridRec.outfile := outfile
	if (is_unset(outfile)) private.regridRec.outfile := '';
#
	private.regridRec.method := method;
#
        private.regridRec.axes := dms.tovector(axes, 'integer');
        if (is_fail(private.regridRec.axes)) fail;
#
        private.regridRec.region := defaultimagesupport.regioncheck(region);
        if (is_fail(private.regridRec.region)) fail;
#
        private.regridRec.mask := defaultimagesupport.maskcheck(mask);
        if (is_fail(private.regridRec.mask)) fail;
#
	private.regridRec.dbg := dbg;
        private.regridRec.doref := as_boolean(doref);
        private.regridRec.dropdeg := as_boolean(dropdeg);
        private.regridRec.replicate := as_boolean(replicate);
        private.regridRec.decimate := as_integer(decimate);
        private.regridRec.overwrite := as_boolean(overwrite);
        private.regridRec.force := as_boolean(force);
#
	id :=  defaultservers.run(private.agent, private.regridRec, async);
        if (is_fail(id)) fail;
        if (async) return id;
        id2 := defaultservers.add(private.agent, id);
        ok := _define_image(private.agent, id2)
        if (!is_fail(ok)) ok.unlock();
        return ok;
     }

###
    private.rotateRec := [_method="rotate", _sequence=private.id._sequence]
    const public.rotate := function(outfile=unset, shape=unset, pa=0.0,
                                    region=unset, mask=unset, method='cubic', 
                                    decimate=0, replicate=F,
                                    overwrite=F, async=!dowait, dbg=0)
    {
        wider private;
#
        if (is_unset(shape)) {
           private.rotateRec.shape := public.shape();
           if (dropdeg) {
              shp := [];
              j := 1;
              for (i in 1:length(private.rotateRec.shape)) {
                 if (private.rotateRec.shape[i] != 1) {
                    shp[j] := private.rotateRec.shape[i]
                    j +:= 1;
                 }
              }
              private.rotateRec.shape := shp;
           }
        } else {
           private.rotateRec.shape := dms.tovector(shape, 'integer');
           if (is_fail(private.rotateRec.shape)) fail;
        }
        if (is_fail(private.rotateRec.shape)) fail;
#
# We send the coordinate system rotation angle.
#
        private.rotateRec.pa := defaultcoordsyssupport.valuetoquantum (pa, 'deg');
        if (is_fail(private.rotateRec.pa)) fail;
#
	private.rotateRec.outfile := outfile
	if (is_unset(outfile)) private.rotateRec.outfile := '';
#
	private.rotateRec.method := method;
#
        private.rotateRec.region := defaultimagesupport.regioncheck(region);
        if (is_fail(private.rotateRec.region)) fail;
#
        private.rotateRec.mask := defaultimagesupport.maskcheck(mask);
        if (is_fail(private.rotateRec.mask)) fail;
#
	private.rotateRec.dbg := dbg;
        private.rotateRec.replicate := as_boolean(replicate);
        private.rotateRec.decimate := as_integer(decimate);
        private.rotateRec.overwrite := as_boolean(overwrite);
#
	id :=  defaultservers.run(private.agent, private.rotateRec, async);
        if (is_fail(id)) fail;
        if (async) return id;
        id2 := defaultservers.add(private.agent, id);
        ok := _define_image(private.agent, id2)
        if (!is_fail(ok)) ok.unlock();
        return ok;
     }

###
    const public.rename:= function(name, overwrite=F)
    {
       if (!public.ispersistent()) {
         msg := spaste('This image tool is not associated with a persistent disk file. It cannot be renamed')
         return throw(msg, origin='image.rename');
       }
#
       if (strlen(name)==0) {
          return throw('Empty name', origin='image.rename');
       }
#
       oldName := public.name(strippath=F);
       if (is_fail(oldName)) fail;
#
# Let's see if it exists.  If it doesn't, then the user has deleted it
#
       if (!dos.fileexists(oldName, follow=T)) {
          msg := 'The disk file associated with this image tool appears to have been deleted';
          return throw (msg,  origin='image.rename');
       }
#
# Make sure we don't rename ourselves to ourselves
#
       if (oldName==name) {
          return throw ('Given name is already the name of the disk file associated with this image tool',
                        origin='image.rename');
       }
#
# Make sure target image name does not already exist
#
       if (!overwrite) {
          if (dos.fileexists(name, follow=T)) {
             msg := spaste('There is already a file with the name "', name, '"');
             return throw (msg, origin='image.rename');
          }
       }
#
# OK we passed the tests.  Close ourprivate (deletes temporary persistent image)
#
       ok := public.close();
       if (is_fail(ok)) fail;
#
# Now try and move it
#
       if (!is_fail(dos.move(source=oldName, target=name, overwrite=overwrite, follow=T))) {
          note(spaste('Successfully renamed file "', oldName, 
               ' to "', name, '"'), priority='NORMAL', 
               origin='image.rename');
       } else {
          return throw (spaste('Failed to rename file "', oldName, 
               ' to "', name, '"'), origin='image.rename');
       }
#
# Reopen ourprivate with the new file
#
      ok := public.open(name);
      if (is_fail(ok)) fail;
#
      return T;
    }


###
    private.replacemaskedpixelsRec := [_method="replacemaskedpixels", _sequence=private.id._sequence]
    const public.replacemaskedpixels := function(pixels, region=unset, 
                                                 mask=unset, update=F, 
                                                 list=F)
    {
       wider private;
#
       private.replacemaskedpixelsRec.pixels := pixels;
       if (is_numeric(pixels)) {
          if (length(pixels)>1) {
             return throw ('The variable "pixels" must be a numeric scalar, or an expression string',
                           origin='image.replacemaskedpixels');
          }
          private.replacemaskedpixelsRec.pixels := as_string(pixels);
       }
       private.replacemaskedpixelsRec.regions := [=];
       private.replacemaskedpixelsRec.pixels := 
          substitute (pixels, "image region",
                      idrec=private.replacemaskedpixelsRec.regions);
#
       private.replacemaskedpixelsRec.region := defaultimagesupport.regioncheck(region);
       if (is_fail(private.replacemaskedpixelsRec.region)) fail;
#
       private.replacemaskedpixelsRec.mask := defaultimagesupport.maskcheck(mask);
       if (is_fail(private.replacemaskedpixelsRec.mask)) fail;
#
       private.replacemaskedpixelsRec.list := list;
       private.replacemaskedpixelsRec.update := update;
#
       id := defaultservers.run(private.agent, private.replacemaskedpixelsRec);
       if (is_fail(id)) fail;
#
       ok := private.signifyImageHasChanged ();
       if (is_fail(ok)) fail;
#
       return id;
    }
    const public.rmp := ref public.replacemaskedpixels;

###
    private.restoringbeamRec := [_method="restoringbeam", _sequence=private.id._sequence]
    const public.restoringbeam := function() 
    {
       wider private;
       return defaultservers.run(private.agent, private.restoringbeamRec);
    }
    const public.rb := ref public.restoringbeam;
          

###
    private.sepconvolveRec := [_method="sepconvolve", _sequence=private.id._sequence]
    const public.sepconvolve := function(outfile=unset, axes=unset, types=unset,
                                         widths, scale=unset, region=unset, mask=unset,
                                         overwrite=F, async=!dowait)
    {
        wider private;
#
        private.sepconvolveRec.region := defaultimagesupport.regioncheck(region);
        if (is_fail(private.sepconvolveRec.region)) fail;
#
        private.sepconvolveRec.mask := defaultimagesupport.maskcheck(mask);
        if (is_fail(private.sepconvolveRec.mask)) fail;
#
        dq.define('pix', "100%");
        private.sepconvolveRec.widths := defaultcoordsyssupport.valuetovectorquantum (widths, 'pix');
        if (is_fail(private.sepconvolveRec.widths)) fail;
        const n := defaultcoordsyssupport.lengthofquantum(private.sepconvolveRec.widths);
        if (is_fail(n)) fail;
#
        if (is_unset(types)) {
    	   private.sepconvolveRec.types := array('gauss', n);
        } else {
    	   private.sepconvolveRec.types := dms.tovector(types, 'string');
           if (is_fail(private.sepconvolveRec.types)) fail;
        }
        if (is_unset(axes)) {
           private.sepconvolveRec.axes := 1:n;
        } else {
   	   private.sepconvolveRec.axes := dms.tovector(axes, 'integer');
           if (is_fail(private.sepconvolveRec.axes)) fail;
        }
#
        private.sepconvolveRec.autoscale := F;
        private.sepconvolveRec.scale := scale;
        if (is_unset(scale)) {
           private.sepconvolveRec.autoscale := T;
           private.sepconvolveRec.scale := 1.0;
        }
#
        private.sepconvolveRec.outfile := outfile
        if (is_unset(outfile)) private.sepconvolveRec.outfile := '';
#
        private.sepconvolveRec.overwrite := as_boolean(overwrite);
#
        id := defaultservers.run(private.agent, private.sepconvolveRec, async);
        if (is_fail(id)) fail;
#
        id2 := defaultservers.add(private.agent, id);
        ok := _define_image(private.agent, id2)
        if (!is_fail(ok)) ok.unlock();
        return ok;
     }
    const public.sc := public.sepconvolve;

###
    const public.sepconvolvegui := function(parent=F, widgetset=dws)
    {
      include 'imagesepconvolvegui.g';
      wider private;
      standalone := (is_boolean(parent) && parent==F);
      isAgent := is_agent(private.sepconvolvegui.gui);
      glen := length(private.sepconvolvegui);
      imagename := public.name(strippath=F);
#
      newgui := glen==0  ||                                  # first time
                (has_field(private.sepconvolvegui,'gui') &&     # gui doned
                 !isAgent) ||
                (has_field(private.sepconvolvegui,'gui') &&     # standalone changed
                 isAgent &&                                  # or image name changed
                 (private.sepconvolvegui.standalone!=standalone ||
                  private.sepconvolvegui.imagename!=imagename));
#
      if (newgui) {
         if (has_field(private.sepconvolvegui,'gui') && is_agent(private.sepconvolvegui.gui)) {
            private.sepconvolvegui.gui.done();
         }
         private.sepconvolvegui.gui := imagesepconvolvegui(parent=parent,
                                                        imageobject=public, 
                                                        widgetset=widgetset);
      } else {
#
# Image may have changed 
#
         private.sepconvolvegui.gui.setimage(imageobject=public);
         private.sepconvolvegui.gui.gui();
      }
      private.sepconvolvegui.standalone := standalone;
      private.sepconvolvegui.imagename := imagename;
      return ref private.sepconvolvegui.gui;
    }
    const public.scgui := ref public.sepconvolvegui;


###
    private.setRec := [_method="set", _sequence=private.id._sequence]
    const public.set := function(pixels=unset, pixelmask=unset,
                                 region=unset, list=F) 
    {
        wider private;
        if (is_unset(pixels) && is_unset(pixelmask)) {
           return throw('You must specify at least either the pixels or the mask to set',
                        origin='image.set');
        }
#
        private.setRec.regions := [=];
        if (is_unset(pixels)) {
           private.setRec.setpixels := F;
           private.setRec.pixels := '0.0';
        } else {
           private.setRec.setpixels := T;
           if (is_numeric(pixels)) {
#
# Make string expression
#
              tmp := spaste(pixels);
              private.setRec.pixels := tmp;
           } else {
#
# Is an expression already
#
              private.setRec.pixels := substitute (pixels, "image region",
                                                idrec=private.setRec.regions);
           }
        }
#
        if (is_unset(pixelmask)) {
           private.setRec.setmask := F;
           private.setRec.pixelmask := T;
        } else {
           if (!is_boolean(pixelmask)) {
              return throw ('The mask must be boolean', origin='image.set');
           }
           private.setRec.setmask := T;
           private.setRec.pixelmask := pixelmask;
        }
#
        private.setRec.region := defaultimagesupport.regioncheck(region);
        if (is_fail(private.setRec.region)) fail;
        private.setRec.list := list;
#
 	id := defaultservers.run(private.agent, private.setRec);
        if (is_fail(id)) fail;
#
        ok := public.unlock();
        ok := private.signifyImageHasChanged ();
        if (is_fail(ok)) fail;
#
        return id;
    }


###
    private.setbrightnessunitRec := [_method="setbrightnessunit", _sequence=private.id._sequence]
    const public.setbrightnessunit := function (unit)
    {
        wider private;
        private.setbrightnessunitRec.unit := as_string(unit);
	ok := defaultservers.run(private.agent, private.setbrightnessunitRec, F);
        if (is_fail(ok)) fail;
        return public.unlock();
    }
    const public.sbu := public.setbrightnessunit;

###
    private.setcoordsysRec := [_method="setcoordsys", _sequence=private.id._sequence]
    const public.setcoordsys := function (csys)
    {
        wider private;
        if (!is_coordsys(csys)) {
           return throw ('Provided CoordinateSystem is invalid',
                         origin='image.setcoordsys');
        }
        private.setcoordsysRec.csys := csys.torecord();
        ok := defaultservers.run(private.agent, private.setcoordsysRec);
        if (is_fail(ok)) fail;

# Update internal copy.  

        if (is_fail(private.csys.done())) fail;
        private.csys := csys.copy(); 
        if (is_fail(private.csys)) fail;   
#
        return public.unlock();
   }

###
    private.sethistoryRec := [_method="sethistory", _sequence=private.id._sequence]
    const public.sethistory := function(history)
    {
        wider private;
#
        if (!is_string(history)) {
           return throw ('History must be a string or vector of strings',
                         origin='image.sethistory');
        }
#
        if (length(history)==0) {
           return throw('history string is empty', origin='image.sethistory');
        }
#
	private.sethistoryRec.history := dms.tovector(history, 'string');
        if (is_fail(private.sethistoryRec.history)) fail;
        return defaultservers.run(private.agent, private.sethistoryRec);
    }

###
    private.setmiscinfoRec := [_method="setmiscinfo", _sequence=private.id._sequence]
    const public.setmiscinfo:=function(info)
    {
        wider private;
	private.setmiscinfoRec.newinfo := info
	return defaultservers.run(private.agent, private.setmiscinfoRec);
    }
    const public.smi := ref public.setmiscinfo;

###
    private.setrestoringbeamRec := [_method="setrestoringbeam", _sequence=private.id._sequence]
    const public.setrestoringbeam := function (major=unset, minor=unset, pa=unset,
                                               beam=unset, delete=F, log=T)
    {
       wider private;
#
       private.setrestoringbeamRec.beam := [=];
       private.setrestoringbeamRec.delete := as_boolean(delete);
       private.setrestoringbeamRec.log := as_boolean(log);
       if (!private.setrestoringbeamRec.delete) {
#
# Set values
#
          if (!is_unset(beam) && is_record(beam)) {
#
# Beam given as record
#
             if (has_field(beam, 'major') && has_field(beam, 'minor') &&
                 has_field(beam, 'positionangle')) {
                private.setrestoringbeamRec.beam.major := beam.major;
                private.setrestoringbeamRec.beam.minor := beam.minor;
                private.setrestoringbeamRec.beam.positionangle := beam.positionangle;
             } else {
                return throw ('Supplied restoring beam record is invalid',
                              origin='image.setrestoringbeam');
             }
          } else {
#
# Beam given as individual items
#
             rb := public.restoringbeam();
             if (length(rb)==0) {
                if (is_unset(major) || is_unset(minor) || is_unset(pa)) {
                   return throw ('There is no current restoring beam; give all of major, minor & pa',
                                  origin='image,setrestoringbeam');
                }       
                rb.major := dq.quantity('0arcsec');
                rb.minor := dq.quantity('0arcsec');
                rb.positionangle := dq.quantity('0deg');
             }
             if (is_unset(major)) major := rb.major;
             if (is_unset(minor)) minor := rb.minor;
             if (is_unset(pa)) pa := rb.positionangle;
#
             private.setrestoringbeamRec.beam.major := defaultcoordsyssupport.valuetoquantum (major, rb.major.unit);            
             private.setrestoringbeamRec.beam.minor := defaultcoordsyssupport.valuetoquantum (minor, rb.minor.unit);
             private.setrestoringbeamRec.beam.positionangle := defaultcoordsyssupport.valuetoquantum (pa, rb.positionangle.unit);
          }
       }
#
       return defaultservers.run(private.agent, private.setrestoringbeamRec);
    }
    const public.srb := ref public.setrestoringbeam;

###
    private.shapeRec := [_method="shape", _sequence=private.id._sequence]
    const public.shape := function() {
	wider private;
        id := defaultservers.run(private.agent, private.shapeRec);
        if (is_fail(id)) fail;
        return id;
    }

###
    private.statisticsRec := [_method="statistics", _sequence=private.id._sequence]
    const public.statistics := function(ref statsout = [=], 
                                        axes=unset,
                                        region=unset, 
                                        mask=unset,
                                        plotstats="mean sigma",
                                        includepix=unset,
                                        excludepix=unset,
                                        list=T, 
                                        plotter=unset,
                                        nx=1, ny=1, 
                                        force=F, disk=F, robust=F, verbose=T,
                                        async=!dowait) 
    {
        wider private;
        private.statisticsRec.region := defaultimagesupport.regioncheck(region);
        if (is_fail(private.statisticsRec.region)) fail;
#
        private.statisticsRec.mask := defaultimagesupport.maskcheck(mask);
        if (is_fail(private.statisticsRec.mask)) fail;
#
	private.statisticsRec.axes := dms.tovector(axes, 'integer');
	if (is_fail(private.statisticsRec.axes)) fail;
        private.statisticsRec.plotstats := dms.tovector(plotstats, 'string');
	if (is_fail(private.statisticsRec.plotstats)) fail;
	private.statisticsRec.includepix := dms.tovector(includepix, 'float');
	if (is_fail(private.statisticsRec.includepix)) fail;
	private.statisticsRec.excludepix := dms.tovector(excludepix, 'float');
	if (is_fail(private.statisticsRec.excludepix)) fail;
#
	private.statisticsRec.plotter := plotter;
        if (is_unset(plotter)) private.statisticsRec.plotter := '';
	private.statisticsRec.list := list;
	private.statisticsRec.nx := nx;
	private.statisticsRec.ny := ny;
	private.statisticsRec.force := force;
	private.statisticsRec.disk := disk;
	private.statisticsRec.robust := robust;
        if(strlen(private.statisticsRec.plotter)!=0) async:=F
	private.statisticsRec.verbose := as_boolean(verbose);
	id := defaultservers.run(private.agent, private.statisticsRec, async);
        if (is_fail(id)) fail;
#
        if (!async) val statsout := private.statisticsRec.statsout;
	return id;
    }
    const public.stats := public.statistics;


###
    private.twopointcorrelationRec := [_method="twopointcorrelation", _sequence=private.id._sequence]
    const public.twopointcorrelation := function(outfile=unset, region=unset, 
                                                 mask=unset, axes=unset, 
                                                 method='structurefunction',
                                                 overwrite=F)
    {
        wider private;
        private.twopointcorrelationRec.region := defaultimagesupport.regioncheck(region);
        if (is_fail(private.twopointcorrelationRec.region)) fail;
#
        private.twopointcorrelationRec.mask := defaultimagesupport.maskcheck(mask);
        if (is_fail(private.twopointcorrelationRec.mask)) fail;
#
	private.twopointcorrelationRec.outfile := outfile;
	if (is_unset(outfile)) private.twopointcorrelationRec.outfile := '';
	private.twopointcorrelationRec.overwrite := overwrite;
#
        if (is_unset(axes)) axes := [];
	private.twopointcorrelationRec.axes := axes;
#
	private.twopointcorrelationRec.method := method;
#
	id := defaultservers.run(private.agent, private.twopointcorrelationRec, F);
        if (is_fail(id)) fail;
        id2 := defaultservers.add(private.agent, id);
        ok := _define_image(private.agent, id2)
        if (!is_fail(ok)) ok.unlock();
        return ok;
    }
    const public.tpc := public.twopointcorrelation;

###
    private.subimageRec := [_method="subimage", _sequence=private.id._sequence]
    const public.subimage := function(outfile=unset, region=unset, 
                                      mask=unset, dropdeg=F, overwrite=F,
                                      list=T)
    {
        wider private;
        private.subimageRec.region := defaultimagesupport.regioncheck(region);
        if (is_fail(private.subimageRec.region)) fail;
#
        private.subimageRec.mask := defaultimagesupport.maskcheck(mask);
        if (is_fail(private.subimageRec.mask)) fail;
#
	private.subimageRec.outfile := outfile;
	if (is_unset(outfile)) private.subimageRec.outfile := '';
	private.subimageRec.dropdeg := dropdeg;
	private.subimageRec.overwrite := overwrite;
	private.subimageRec.list := list;
#
	id := defaultservers.run(private.agent, private.subimageRec, F);
        if (is_fail(id)) fail;
        id2 := defaultservers.add(private.agent, id);
        ok := _define_image(private.agent, id2)
        if (!is_fail(ok)) ok.unlock();
        return ok;
    }
    const public.subim := public.subimage;

###
    private.summaryRec := [_method="summary", _sequence=private.id._sequence]
    const public.summary := function(ref header=[=], doppler="radio", 
                                     list=T, pixelorder=T)
    {
        wider private;
        private.summaryRec.velocity:= doppler;
        private.summaryRec.list := list;
        private.summaryRec.pixelorder := pixelorder;
	id := defaultservers.run(private.agent, private.summaryRec);
        if (is_fail(id)) fail;
        val header := private.summaryRec.header;
#
        if (!is_boolean(id)) {
           if (length(id)==0) return T;
           return split(id, '\n');
        }
#
        return id;
    }

###
    const public.toascii := function(outfile=unset, region=unset, mask=unset, 
                                     sep=' ', format='%e', maskvalue=unset, overwrite=F)
    {
	wider private;
#
        region2 := defaultimagesupport.regioncheck(region);
        if (is_fail(region2)) fail;
#
        mask2 := defaultimagesupport.maskcheck(mask);
        if (is_fail(mask2)) fail;

# Deal with output file

	outfile2 := outfile;
        if (is_unset(outfile)) {
           name := public.name(F);
           if (!public.ispersistent()) name := 'newfile';
           outfile2 := spaste(name, '.ascii');
        }
#
        if (!overwrite && dos.fileexists(outfile2)) {
           include 'choice.g';
           desc := spaste ('File "', outfile2, '" already exists. Remove it ?');
           c := choice(description=desc, choices="no yes", timeout=30.0);
           if (c=='yes') {
              ok := dos.remove(outfile2);
           } else {
              note ('User does not want to remove pre-existing file - aborted',
                    priority='WARN', origin='image.toascii');
              return T;
           }
        }
 #
        include 'asciifileio.g'
        af := asciifileio();
        if (is_fail(af)) fail;

# This needs to be rewritten with an iteration algorithm in C++.
# Any masked pixel is given the specified maskvalue. 

        local p, m;
        ok := public.getregion(pixels=p, pixelmask=m, mask=mask, region=region);
        if (is_fail(ok)) fail;      
        if (!is_unset(maskvalue)) {
           p[m==F] := as_float(maskvalue);
        }
        ok := af.toasciifile(outfile=outfile2, pixels=p, sep=sep, 
                             format=format, overwrite=T);
        if (is_fail(ok)) fail;      
#
        ok := af.done();
        if (is_fail(ok)) fail;      
#
        return T;
    }

###
    private.tofitsRec := [_method="tofits", _sequence=private.id._sequence]
    const public.tofits := function(outfile=unset, velocity=F, optical=T,
                                    bitpix=-32, minpix=unset, maxpix=unset, 
                                    region=unset, mask=unset, overwrite=F,
                                    dropdeg=F, deglast=F, async=!dowait) 
    {
	wider private;
#
        private.tofitsRec.region := defaultimagesupport.regioncheck(region);
        if (is_fail(private.tofitsRec.region)) fail;
#
        private.tofitsRec.mask := defaultimagesupport.maskcheck(mask);
        if (is_fail(private.tofitsRec.mask)) fail;
#
	private.tofitsRec.fitsfile := outfile;
        if (is_unset(outfile)) {
           name := public.name(F);
           if (!public.ispersistent()) name := 'newfile';
           private.tofitsRec.fitsfile := spaste(name, '.fits');
        }
	private.tofitsRec.velocity := velocity;
	private.tofitsRec.optical := optical;
	private.tofitsRec.bitpix := bitpix
#
	private.tofitsRec.minpix := minpix
        if (is_unset(minpix)) private.tofitsRec.minpix := 1;
	private.tofitsRec.maxpix := maxpix
        if (is_unset(maxpix)) private.tofitsRec.maxpix:= -1;
	private.tofitsRec.overwrite := as_boolean(overwrite);
	private.tofitsRec.dropdeg := as_boolean(dropdeg);
	private.tofitsRec.deglast := as_boolean(deglast);
#
        id := defaultservers.run(private.agent, private.tofitsRec,async);
        if (is_fail(id)) fail;
        return id;
    }

###
    const public.topixel := function (value=unset)
    {
       return private.csys.topixel (value);
    }

###
    const public.toworld := function (value=unset, format='n')
    {
       return private.csys.toworld (value, format);
    }

###
    private.unlockRec := [_method="unlock", _sequence=private.id._sequence]
    const public.unlock := function()
    {
        wider private;
	id := defaultservers.run(private.agent, private.unlockRec);
        if (is_fail(id)) fail;
        return id;
    }
 

###
    const public.view := function(parent=F, raster=unset, contour=unset, vector=unset,
                                  marker=unset, region=unset, mask=unset, model=unset, 
                                  adjust=F, axislabels=unset, includepix=unset, order=unset,
                                  activatebreak=unset, hasdismiss=T, 
                                  widgetset=unset)
#
# This function only uses the DO for a couple of services.
# If the image tool is closed, those are the only ones that
# will know it, so we must catch the fails (coordinates, name)
#
    {
       wider private;
#
       if (!have_gui()) {
          return throw ('There is no GUI available, probably DISPLAY is unset',
                        origin='image.view');
       }
#
       if (!is_agent(private.ivs)) {
          include 'imageviewersupport.g'
          if (is_unset(widgetset)) widgetset := ddlws;
          private.ivs := imageviewersupport (public, widgetset=widgetset);
          if (is_fail(private.ivs)) fail;

# Forward events

          whenever private.ivs->region do {public->region($value);}
          whenever private.ivs->position do {public->position($value);}
          whenever private.ivs->statistics do {public->statistics($value);}
#
          whenever private.ivs->displaypanelisdone do {public->viewerdone($value);}
          whenever private.ivs->breakfromviewer do {public->breakfromviewer($value);}
       }
#
       if (!is_unset(order)) {
          order := dms.tovector(order, 'integer');
          if (is_fail(order)) fail;
       }
#
       return private.ivs.view (parent=parent, raster=raster, contour=contour, 
                                vector=vector, marker=marker, region=region, 
                                mask=mask, model=model, adjust=adjust, 
                                axislabels=axislabels, includepix=includepix, 
                                activatebreak=activatebreak, hasdismiss=hasdismiss, 
                                order=order);
   }


# Rest of constructor
# Store Coordinate System internally

    private.csys := public.coordsys();
    if (is_fail(private.csys)) fail;

# Attach plugins

    ok := plugins.attach('image', public);
    if (is_fail(ok)) {
       note (ok::message, priority='SEVERE', origin='image.g');
       note ('Could not load plugins', priority='SEVERE', origin='image.g');
    }

    return ref public;
} # _define_image()



###  Constructors

const image := function(infile, host='', forcenewserver=F) 
{
    infile2 := infile;
    agent := defaultservers.activate('app_image', host, forcenewserver,
                                     terminateonempty=F);
    id := defaultservers.create(agent, 'image', 'image',
                        [infile=infile2]);
    if (is_fail(id)) fail;
    ok := ref _define_image(agent,id);
    if (!is_fail(ok)) ok.unlock();
    return ok;
} 


const imagecalc := function(outfile=unset, pixels, overwrite=F,
                            host='', forcenewserver=F) 
{
    outfile2 := outfile;
    if (is_unset(outfile)) outfile2 := '';    
#
    regions := [=];
    expr1 := substitute (pixels, "image region", idrec=regions);
#
    agent := defaultservers.activate('app_image', host, forcenewserver,
                                      terminateonempty=F);
#
    id := defaultservers.create(agent, 'image', 'imagecalc',
      [outfile=outfile2, expr=expr1, regions=regions, overwrite=overwrite]);
    if (is_fail(id)) fail;
    ok := ref _define_image(agent,id);
    if (!is_fail(ok)) ok.unlock();
    return ok;
}


const imageconcat := function(outfile=unset, infiles, axis=unset, relax=F,
                              tempclose=T, overwrite=F, host='', forcenewserver=F) 
{
    outfile2 := outfile;
    if (is_unset(outfile)) outfile2 := '';    
#
    axis2 := axis;
    if (is_unset(axis)) axis2 := -10;
    infiles := dms.tovector(infiles, 'string');
    if (is_fail(infiles)) fail;
#
    agent := defaultservers.activate('app_image', host, forcenewserver,
                                     terminateonempty=F);
    id := defaultservers.create(agent, 'image', 'imageconcat',
      [outfile=outfile2, infiles=infiles, axis=axis2, 
       relax=relax, tempclose=tempclose, overwrite=overwrite]);
    if (is_fail(id)) fail;
    ok := ref _define_image(agent,id);
    if (!is_fail(ok)) ok.unlock();
    return ok;
}



const imagefromarray := function(outfile=unset, pixels, csys=unset, linear=F, 
                                 overwrite=F, log=T, host='', forcenewserver=F)
{
    if (!serverexists('defaultimagesupport', 'imagesupport', defaultimagesupport)) {
       return throw('The imagesupport server "defaultimagesupport" is not running',
                     origin='imagefromarray');
    }
#
    cs := defaultimagesupport.coordinatescheck(csys);
    if (is_fail(cs)) fail;
#
    if (!is_float(pixels)) {
       if (is_complex(pixels) || is_dcomplex(pixels)) {
          note ('Converting complex pixels array to float type',
                priority='WARN', origin='imagefromarray');
       } 
       pixels := as_float(pixels);
    }
#
    outfile2 := outfile;
    if (is_unset(outfile)) outfile2 := '';
#
    agent := defaultservers.activate('app_image', host, forcenewserver,
                                     terminateonempty=F);
    id := defaultservers.create(agent, 'image', 'imagefromarray',
             [outfile=outfile2, pixels=pixels, csys=cs, 
              linear=linear, overwrite=overwrite, log=log]);
    if (is_fail(id)) fail;
    ok := ref _define_image(agent,id);
    if (!is_fail(ok)) ok.unlock();
    return ok;
}


const imagefromascii := function(outfile=unset, infile, shape, sep=' ',
                                 csys=unset, linear=F, overwrite=F, host='', 
                                 forcenewserver=F)
{
    include 'asciifileio.g'
    af := asciifileio();
    if (is_fail(af)) fail;
#
    pixels := af.fromasciifile(infile, shape);
    if (is_fail(pixels)) fail;
    ok := af.done();
    if (is_fail(ok)) fail;
#
    return imagefromarray(outfile=outfile, pixels=pixels, csys=csys, 
                          linear=linear, overwrite=overwrite,
                          host=host, forcenewserver=forcenewserver);
}


const imagefromfits := function(outfile=unset, infile, whichrep=1, 
                                whichhdu=1,
                                zeroblanks=F, overwrite=F, old=False,
                                host='', forcenewserver=F) 
{
    outfile2 := outfile;
    if (is_unset(outfile)) outfile2 := '';
#
    agent := defaultservers.activate('app_image', host, forcenewserver,
                                     terminateonempty=F);
    id := defaultservers.create(agent, 'image', 'imagefromfits',
          [outfile=outfile2, fitsfile=infile, whichrep=whichrep,
           whichhdu=whichhdu, zeroblanks=zeroblanks, overwrite=overwrite,old=old]);
    ok := ref _define_image(agent,id);
    if (!is_fail(ok)) ok.unlock();
    return ok;
}


const imagefromimage := function(outfile=unset, infile, region=unset, 
                                 mask=unset, dropdeg=F, overwrite=F, 
                                 host='', forcenewserver=F) 
{
    if (!serverexists('defaultimagesupport', 'imagesupport', defaultimagesupport)) {
       return throw('The imagesupport server "defaultimagesupport" is not running',
                     origin='imagefromimage');
    }
    rrec := defaultimagesupport.regioncheck(region);
    if (is_fail(rrec)) fail;
#
    mrec := defaultimagesupport.maskcheck(mask);
    if (is_fail(mrec)) fail;
#
    outfile2 := outfile;
    if (is_unset(outfile)) outfile2 := '';
#
    agent := defaultservers.activate('app_image', host, forcenewserver,
                                     terminateonempty=F);
    id := defaultservers.create(agent, 'image', 'imagefromimage',
            [outfile=outfile2, infile=infile, region=rrec, 
             mask=mrec, dropdeg=dropdeg, overwrite=overwrite]);
    if (is_fail(id)) fail;
    ok := ref _define_image(agent,id);
    if (!is_fail(ok)) ok.unlock();
    return ok;
} 


const imagefromshape := function(outfile=unset, shape, csys=unset, linear=F, 
                                 overwrite=F, log=T, host='', forcenewserver=F) 
{
    if (!serverexists('defaultimagesupport', 'imagesupport', defaultimagesupport)) {
       return throw('The imagesupport server "defaultimagesupport" is not running',
                     origin='imagefromshape');
    }
    cs := defaultimagesupport.coordinatescheck(csys);
    if (is_fail(cs)) fail;
    shape2 := dms.tovector(shape, 'integer');
    if (is_fail(shape2)) fail;
#
    outfile2 := outfile;
    if (is_unset(outfile)) outfile2 := '';
#
    agent := defaultservers.activate('app_image', host, forcenewserver,
                                     terminateonempty=F);
    id := defaultservers.create(agent, 'image', 'imagefromshape',
            [outfile=outfile2, shape=shape2, csys=cs, linear=linear, 
             log=log, overwrite=overwrite]);
    if (is_fail(id)) fail;
    ok := ref _define_image(agent,id);
    if (!is_fail(ok)) ok.unlock();
    return ok;
}

imagemaketestimage := function(outfile=unset) 
{
   include 'sysinfo.g';
   aroot := sysinfo().root();
   fitsfile := spaste(aroot, '/data/demo/Images/imagetestimage.fits');

# imagefromfits constructor will take care of removal
# of file if pre-existing

   return imagefromfits(outfile=outfile, infile=fitsfile);
}
