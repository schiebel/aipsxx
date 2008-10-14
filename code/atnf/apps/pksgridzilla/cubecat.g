#-----------------------------------------------------------------------------
# cubecat.g: Cubelet concatenator and related utilities.
#-----------------------------------------------------------------------------
# Copyright (C) 1997-2004
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
# $Id: cubecat.g,v 19.2 2004/09/08 02:40:54 mcalabre Exp $
#-----------------------------------------------------------------------------
# Utility for concatenating cubelets produced by gridzilla with additional
# processing options.
#
# Arguments (string representation of numeric values is allowed):
#    config            string   Predefined processing configuration,
#                               'GENERAL', 'HIPASS', or 'ZOA'.
#    infiles           string[] List of input files.
#    accum             boolean  If true, add additional files to the input
#                               list, otherwise overwrite it.
#    concat            boolean  If true, concatenate all files in the input
#                               list.
#    hanning           boolean  If true, Hanning smooth the output.
#    luther            boolean  If true, run luther on the FITS file.
#    gzip              boolean  If true, compress the output FITS file using
#                               gzip.
#    save              boolean  If true, and concatenation and smoothing
#                               and/or luther are selected, then save the raw
#                               concatenated file.
#    catsets           boolean  If true, the input list will be split into
#                               multiple concatenation sets based on the first
#                               four letters of the input file name.
#    intfits           boolean  If true, write 16-bit integer FITS data format
#                               (with range -8 to +32 Jy) instead of 32-bit
#                               IEEE floating.  Integer format output is half
#                               the size and is also amenable to compression.
#    fixint            boolean  If true, set the FITS integer scale to -8 to
#                               +32 Jy.  Otherwise the scale is adjusted to
#                               encompass the minimum and maximum values.
#    outdir            string   Output directory.
#    outfile           string   Output file name; used only if there is one
#                               input file or there are several to be
#                               concatenated.
#    outfgen           boolean  If true, generate an output file name based on
#                               the (first) input cube filename and processing
#                               options.
# Received events:
#    setparm(record)     Set parameter values.
#    setconfig(string)   Set mode to 'GENERAL', 'HIPASS', or 'ZOA'.
#    printparms()        Show parameter values.
#    go(record)          Start gridding.  Parameter values may optionally be
#                        specified.
#    abort()             Abort gridding.
#    showgui(agent)      Create the GUI or make it visible if it already
#                        exists.  The parent frame may be specified.
#    hidegui()           Make the GUI invisible.
#    terminate()         Close down.
#
# Sent events:
#    finished()          Processing finished.
#    guidone()           Finished constructing GUI.
#    done()              Agent has terminated.
#
# Original: 1997/08, Lister Staveley-Smith (cubehelper).
#-----------------------------------------------------------------------------

pragma include once

include 'logger.g'
include 'popuphelp.g'			# logger.g includes this anyway.
include 'image.g'

include 'pkslib.g'

const cubecat := subsequence(config  = 'HIPASS',
                             infiles = "*.fits *.fits.gz",
                             accum   = F,
                             concat  = T,
                             hanning = F,
                             luther  = F,
                             gzip    = F,
                             catsets = T,
                             save    = F,
                             intfits = T,
                             fixint  = T,
                             outdir  = '.',
                             outfile = 'cubecat',
                             outfgen = T) : [reflect=T]
{
  # Our identity.
  self.name := 'cubecat'

  # Parameter values.
  parms := [=]

  # Parameter value checking.
  valid := [
    config  = [string  = [default = 'HIPASS',
                          valid   = "GENERAL HIPASS ZOA"]],
    infiles = [string  = [default = ""]],
    accum   = [boolean = [default = F]],
    concat  = [boolean = [default = T]],
    hanning = [boolean = [default = F]],
    luther  = [boolean = [default = F]],
    gzip    = [boolean = [default = F]],
    save    = [boolean = [default = F]],
    catsets = [boolean = [default = T]],
    intfits = [boolean = [default = T]],
    fixint  = [boolean = [default = T]],
    outdir  = [string  = [default = '.']],
    outfile = [string  = [default = 'cubecat',
                          invalid = '']],
    outfgen = [boolean = [default = T]]]

  # Get missing arguments by name.
  missarg := [=]
  j := 0
  for (field in field_names(valid)) {
    j +:= 1
    missarg[field] := missing()[j]
  }

  if (missarg.infiles) {
    infiles := shell('ls -1d', strmerg(spaste(environ.PWD, '/'), infiles),
                     '2> /dev/null')

    if (len(infiles)) {
      infiles := infiles[infiles !~ m|.scancounts.fits$|]
    }
  }

  if (missarg.outdir && has_field(environ, 'MB_CUBE_DESTINATION')) {
    outdir := environ.MB_CUBE_DESTINATION
  }

  # Disable print paging.
  global system
  system.output.pager.limit := -1


  # Work variables.
  wrk := [=]
  wrk.abort   := F
  wrk.accum   := F
  wrk.busy    := F
  wrk.catsets := catsets
  wrk.fixint  := fixint
  wrk.indir   := '.'
  wrk.outfgen := outfgen
  wrk.save    := save

  # Is luther available?
  wrk.luther := len(shell('hash luther.exe > /dev/null 2>&1 && echo T'))
  if (wrk.luther) {
    wrk.icbase := '/nfs/atapplic/multibeam/code/luther/ic_baseline/\
                   ic_baseline.txt'
    wrk.luther := len(stat(wrk.icbase)) > 0
  }

  # GUI widgets.
  gui := [=]
  gui.f1 := F


  #---------------------------------------------------------------------------
  #  Local function definitions.
  #---------------------------------------------------------------------------
  local autogen, busy, fits2img, go, img2fits, is_fits, readgui, set := [=],
        setparm, showgui, status

  #------------------------------------------------------------------- autogen

  # Generate an appropriate output file name.

  const autogen := function(infiles="")
  {
    if (missing()[1]) infiles := ref parms.infiles

    if (len(infiles) && (parms.concat || len(infiles) == 1)) {
      t := split(infiles[1] ~ s|.*/||, '.')

      if (t[1] ~ m|^.+_[a-z]+_\d\d\d$| && len(infiles) > 1) {
        # Looks like gridzilla output.
        t[1] =~ s|_\d\d\d$||

      } else {
        if (!(parms.hanning || parms.luther)) {
          t[1] =~ s|$|-new|
        }
      }

      setparm([outfile = paste(t, sep='.')])

    } else {
      setparm([outfile = '(not applicable)'])
    }
  }

  #---------------------------------------------------------------------- busy

  # Lock or unlock parameter entry.

  const busy := function(value=T)
  {
    wider wrk

    if (!missing()[1]) {
      if (wrk.busy == value) return
      wrk.busy := value
    }

    if (is_agent(gui.f1)) {
      if (wrk.busy) {
        gui.f1->cursor('watch')
        gui.f11->disable()
        gui.go.bn->disabled(T)
        gui.abort.bn->disabled(F)
        gui.exit.bn->disabled(T)

      } else {
        gui.f1->cursor('')
        gui.f11->enable()
        gui.go.bn->disabled(F)
        gui.abort.bn->disabled(T)
        gui.exit.bn->disabled(F)
      }
    }
  }

  #------------------------------------------------------------------ fits2img

  # Convert a FITS file to aips++ image.

  const fits2img := function(fitsfile, imgfile)
  {
    wider wrk

    gunzip := fitsfile ~ m|\.gz$|

    if (gunzip) {
      # Uncompress input files.
      status('Uncompressing', fitsfile ~ s|.*/||)

      tmpfile := spaste(imgfile ~ s|[^/]*$||, fitsfile ~ s|.*/||)
      shell('ln -s', fitsfile, tmpfile, '; gunzip -f', tmpfile)

      fitsfile := tmpfile ~ s|\.gz$||
    }

    if (wrk.abort) fail 'Terminated by request'

    # Is it a FITS file?
    if (!is_fits(fitsfile)) {
      msg := paste('Input is not FITS:', fitsfile)
      dl.log('', 'SEVERE', msg)
      fail msg
    }

    status('Converting', fitsfile ~ s|.*/||)

    img := imagefromfits(imgfile, fitsfile)

    if (gunzip) {
      # The uncompressed FITS file is no longer needed.
      shell('rm -f', fitsfile)
    }

    if (is_fail(img)) {
      msg := paste('Problem converting', fitsfile)
      dl.log('', 'SEVERE', msg)
      fail msg
    }

    return img
  }

  #------------------------------------------------------------------------ go

  const go := function()
  {
    wider wrk

    if (wrk.busy) return

    # Number of input cubes.
    if (len(parms.infiles) == 0) {
      dl.log('', 'SEVERE', 'ERROR: no input files found.')
      return
    }


    # Create a temporary work area for intermediate files.
    workdir := spaste(parms.outdir, '/cubecat_', random())
    if (is_fail(shell('mkdir', workdir))) {
      dl.log('', 'SEVERE', 'ERROR: Failed to create temporary work area.')
      return
    }

    const cleanup := function(message='Terminated by request')
    {
      status('Cleaning up...')
      shell('rm -rf', workdir)
      busy(F)
      wrk.abort := F
      status(message)
      self->finished()
    }


    wrk.abort := F
    busy(T)
    if (is_agent(gui.f1)) readgui()


    # Determine the number of concatenation sets.
    catset := [=]
    if (parms.catsets) {
      for (infile in parms.infiles) {
        # Partition by the first four characters of the filename.
        set := infile ~ s|.*/|| ~ s|(....).*|$1|

        if (has_field(catset, set)) {
          catset[set] := [catset[set], infile]
        } else {
          catset[set] := infile
        }
      }

    } else {
      catset[1] := parms.infiles
    }

    for (icat in 1:len(catset)) {
      infiles := catset[icat]
      nfiles  := len(infiles)

      # Do concatenation.
      img := F
      if (parms.concat && nfiles > 1) {
        # Get output name.
        if (icat > 1) autogen(infiles)

        fitsfiles := infiles
        tmpfiles  := ""
        for (j in 1:nfiles) {
          if (infiles[j] ~ m|\.gz$|) {
            # Uncompress input file.
            status('Uncompressing', infiles[j] ~ s|.*/||)

            tmpfile := spaste(workdir, '/', infiles[j] ~ s|.*/||)
            shell('ln -s', infiles[j], tmpfile, '; gunzip -f', tmpfile)

            fitsfiles[j] := tmpfile ~ s|\.gz$||
            tmpfiles := [tmpfiles, tmpfile ~ s|\.gz$||]
          }

          if (wrk.abort) {cleanup(); return}
        }


        status('Concatenating...')

        imgfile := spaste(workdir, '/', parms.outfile, '.img')
        img := imageconcat(outfile=imgfile, infiles=fitsfiles, axis=3, relax=F)
        if (is_fail(img)) {
          dl.log('', 'SEVERE', 'ERROR: Problem concatenating.')
          cleanup('Concatenation failed')
          return
        }

        if (wrk.abort) {cleanup(); return}

        img.summary()

        # Don't need these anymore.
        if (len(tmpfiles)) {
          shell('rm -rf', tmpfiles)
        }

        # Just one file now.
        nfiles := 1

        # Save concatenated file?
        if (parms.save) {
          fitsfile := spaste(parms.outdir, '/', parms.outfile, '.fits')
          img2fits(img, fitsfile)

          if (wrk.abort) {cleanup(); return}

          # Compress FITS file.
          if (parms.gzip) {
            status('Compressing', fitsfile ~ s|.*/||, '...')
            shell('gzip -f', fitsfile)
          }

          if (wrk.abort) {cleanup(); return}
        }
      }


      # Filtering operations.
      for (j in 1:nfiles) {
        # Convert to image if required; note that if luther is not being run
        # then we must convert from FITS to image and back again in order to
        # coerce the FITS data format.
        if (!is_image(img) && (parms.hanning || !parms.luther)) {
          infile  := infiles[j] ~ s|.*/||
          imgfile := spaste(workdir, '/', infile ~ s|\..*$||, '.img')
          img := fits2img(infiles[j], imgfile)

          if (wrk.abort) {cleanup(); return}

          if (is_fail(img)) {
            continue
          }

          # Print summary.
          img.summary()
        }

        if (parms.hanning) {
          # Apply Hanning smooth.
          infile := img.name() ~ s|.*/||
          status('Hanning smoothing', infile)

          imgfile := spaste(workdir, '/', infile ~ s|\..*?$|-hann.img|)
          hannimg := img.hanning(outfile=imgfile, axis=3, drop=F, async=F)
          img.done(T)

          hannimg.done()
          img := image(imgfile)
          if (is_fail(img)) {
            dl.log('', 'SEVERE', 'ERROR: Problem with Hanning smooth.')
            continue
          }

          if (wrk.abort) {cleanup(); return}

          img.summary()
        }


        # Convert to FITS.
        if (is_image(img)) {
          if (parms.concat && len(infiles) > 1) {
            if (parms.hanning) {
              fitsfile := spaste(parms.outfile, '-hann.fits')
            } else {
              fitsfile := spaste(parms.outfile, '.fits')
            }

          } else {
            infile := infiles[j] ~ s|.*/||
            if (parms.hanning) {
              fitsfile := spaste(infile ~ s|\..*?$|-hann.fits|)
            } else {
              fitsfile := spaste(infile ~ s|\..*?$|-new.fits|)
            }
          }

          fitsfile := spaste(parms.outdir, '/', fitsfile)
          img2fits(img, fitsfile)

          if (wrk.abort) {cleanup(); return}

          # Image file no longer needed.
          img.done(T)

        } else {
          fitsfile := infiles[j]
        }


        # Run luther on the FITS file.
        if (parms.luther) {
          gunzip := fitsfile ~ m|\.gz$|

          if (gunzip) {
            # Uncompress input files.
            status('Uncompressing', fitsfile ~ s|.*/||)

            tmpfile := spaste(workdir, '/', fitsfile ~ s|.*/||)
            shell('ln -s', fitsfile, tmpfile, '; gunzip -f', tmpfile)

            fitsfile := tmpfile ~ s|\.gz$||
          }

          if (wrk.abort) fail 'Terminated by request'

          # Is it a FITS file?
          if (!is_fits(fitsfile)) {
            msg := paste('Input is not FITS:', fitsfile)
            dl.log('', 'SEVERE', msg)
            continue
          }

          luthfile := spaste(outdir, '/',
                             fitsfile ~ s|.*/|| ~ s|\.fits$|-luther.fits|)
          luthmsg := paste('Running luther on', fitsfile ~ s|.*/||)
          status(luthmsg, '...')
          luthexe := shell('luther.exe -r', fitsfile, '-w', luthfile, '-i',
                           wrk.icbase, async=T)

          whenever
            luthexe->stdout do {
              if ($value ~ m|^ *Row|) {
                status(spaste(luthmsg, ':  ', spaste(split($value)[2:3])))
              } else {
                print $value
              }
            }

          await luthexe->done
          luthexe := F

          if (gunzip) {
            # The uncompressed FITS file is no longer needed.
            shell('rm -f', fitsfile)
          }

          if (wrk.abort) {cleanup(); return}
        }


        # Compress output FITS file(s).
        if (parms.gzip) {
          if (fitsfile !~ m|\.gz$|) {
            status('Compressing', fitsfile ~ s|.*/||, '...')
            shell('gzip -f', fitsfile)
          }

          if (parms.luther) {
            status('Compressing', luthfile ~ s|.*/||, '...')
            shell('gzip -f', luthfile)
          }
        }
      }
    }

    # Clean up.
    cleanup('Finished')
  }

  #------------------------------------------------------------------ img2fits

  # Write an aips++ image in FITS format.

  const img2fits := function(img, fitsfile)
  {

    status('Writing', fitsfile ~ s|.*/||, '...')

    if (parms.intfits) {
      if (parms.fixint) {
        dl.note('Writing cube in FITS integer format (-8 to +32 Jy)...')
        img.tofits(fitsfile, bitpix=16, minpix=-8.0, maxpix=32.0, velocity=T,
                   optical=F, async=F)
      } else {
        dl.note('Writing cube in free-scale FITS integer format...')
        img.tofits(fitsfile, bitpix=16, velocity=T, optical=F, async=F)
      }
    } else {
      dl.note('Writing cube in FITS IEEE floating format...')
      img.tofits(fitsfile, velocity=T, optical=F, async=F)
    }
  }

  #------------------------------------------------------------------- is_fits

  # Test whether a file is in FITS format.

  const is_fits := function(file)
  {
    # Check accessibility.
    filestat := stat(file, 0)
    if (!has_field(filestat, 'type')) return F

    # Check file type.
    if (filestat.type != 'regular') return F

    # Try opening it.
    fd := open(spaste('< ', file))
    if (!is_file(fd)) return F

    # Look for FITS signature.
    return spaste(read(fd, 30, 'c')) ~ s| ||g == 'SIMPLE=T'
  }

  #------------------------------------------------------------------- readgui

  # Read values from entry boxes.

  const readgui := function()
  {
    wider parms

    if (is_agent(gui.f1)) {
      setparm([outdir  = gui.outdir.en->get(),
               outfile = gui.outfile.en->get()])
    }
  }

  #------------------------------------------------------------------- setparm

  # setparm() updates parameter values, also updating any associated widget(s)
  # using showparm() if the GUI is active.
  #
  # Given:
  #    value      record   Each field name, item, identifies the parameter as
  #
  #                           parms[item]
  #
  #                        The field values are the new parameter settings.

  const setparm := function(value)
  {
    wider parms

    # Do parameter validation.
    value := validate(valid, parms, value)

    if (len(parms) == 0) {
      # Initialize parms.
      parms := value
    }

    for (item in field_names(value)) {
      if (has_field(set, item)) {
        # Invoke specialized update procedure.
        set[item](value[item])

      } else {
        # Update the parameter value.
        parms[item] := value[item]
      }

      rec := [=]
      rec[item] := parms[item]
      showparm(gui, rec)
    }
  }

  #---------------------------------------------------------------- set.concat

  # Set image concatenation option.

  const set.concat := function(value)
  {
    wider parms

    # Check legitimacy.
    if (len(parms.infiles) != 1) {
      parms.concat := value
    } else {
      parms.concat := F
    }

    # Update dependencies.
    setparm([catsets = wrk.catsets, save = wrk.save, outfgen = wrk.outfgen])
    if (parms.outfgen) autogen()
  }

  #--------------------------------------------------------------- set.catsets

  # Set option to concatenate in sets.

  const set.catsets := function(value)
  {
    wider parms, wrk

    wrk.catsets := value

    # Check legitimacy.
    if (parms.concat) {
      parms.catsets := value
    } else {
      parms.catsets := F
    }
  }

  #---------------------------------------------------------------- set.config

  # Set predefined configuration.

  const set.config := function(value)
  {
    wider parms

    parms.config := value

    # Update dependencies.
    if (parms.config != 'GENERAL') setparm([intfits = T, fixint = T])
  }

  #---------------------------------------------------------------- set.fixint

  # Set integer FITS data format.

  const set.fixint := function(value)
  {
    wider parms, wrk

    wrk.fixint := value

    # Check legitimacy.
    if (parms.intfits) {
      if (parms.config == 'GENERAL') {
        parms.fixint := value
      } else {
        parms.fixint := T
      }
    } else {
      parms.fixint := F
    }
  }

  #--------------------------------------------------------------- set.hanning

  # Set hanning smooth option.

  const set.hanning := function(value)
  {
    wider parms

    parms.hanning := value

    # Update dependencies.
    setparm([save = wrk.save])
    if (parms.outfgen) autogen()
  }

  #--------------------------------------------------------------- set.infiles

  # Set input file name(s).

  const set.infiles := function(value)
  {
    wider parms

    if (parms.accum && len(parms.infiles)) {
      if (all(parms.infiles != value)) {
        parms.infiles := [parms.infiles, value]
      }
    } else {
      parms.infiles := value
    }

    # Update dependencies.
    setparm([concat = len(parms.infiles) > 1])
  }

  #--------------------------------------------------------------- set.intfits

  # Set integer FITS data format.

  const set.intfits := function(value)
  {
    wider parms

    # Check legitimacy.
    if (parms.config == 'GENERAL') {
      parms.intfits := value
    } else {
      parms.intfits := T
    }

    # Update dependencies.
    setparm([fixint = wrk.fixint])
  }

  #---------------------------------------------------------------- set.luther

  # Set luther option.

  const set.luther := function(value)
  {
    wider parms

    # Check legitimacy.
    if (wrk.luther) {
      parms.luther := value
    } else {
      parms.luther := F
    }

    # Update dependencies.
    setparm([save = wrk.save])
    if (parms.outfgen) autogen()
  }

  #--------------------------------------------------------------- set.outfile

  # Set output file name.

  const set.outfile := function(value)
  {
    wider parms

    parms.outfile := value ~ s|-hann|| ~ s|-luther|| ~ s|\.fits|| ~ s|\.gz$||
  }

  #--------------------------------------------------------------- set.outfgen

  # Set output name generation option.

  const set.outfgen := function(value)
  {
    wider parms

    wrk.outfgen := value

    # Check legitimacy.
    if (parms.concat || len(parms.infiles) == 1) {
      if (parms.outfgen := value) autogen()
    } else {
      parms.outfgen := F
    }
  }

  #------------------------------------------------------------------ set.save

  # Set option to save concatenated unsmoothed file.

  const set.save := function(value)
  {
    wider parms, wrk

    wrk.save := value

    # Check legitimacy.
    if (parms.concat && (parms.hanning || parms.luther)) {
      parms.save := value
    } else {
      parms.save := F
    }
  }

  #------------------------------------------------------------------- showgui

  # Display a graphical user interface.

  const showgui := function(parent=F)
  {
    wider gui, wrk

    if (is_agent(gui.f1)) {
      # Show the GUI and bring it to the top of the window stack.
      gui.f1->map()
      if (gui.f1.top) gui.f1->raise()
      return
    }

    # Check whether DISPLAY is defined.
    if (!has_field(environ, 'DISPLAY')) {
       print 'DISPLAY environment variable is not set, can\'t construct GUI!'
       return
    }

    # Parent window.
    tk_hold()
    if (is_agent(parent)) {
      gui.f1 := parent
      gui.f1->side('top')
      gui.f1->map()
      gui.f1.top := F

    } else {
      # Create a top-level frame.
      gui.f1 := frame(title='Parkes multibeam cube utilities', relief='ridge',
                      borderwidth=4, expand='both')
      gui.f1.top := T
    }

    #=========================================================================
    # Configuration selection.
    gui.f11  := frame(gui.f1, borderwidth=0, expand='both')
    gui.f111 := frame(gui.f11, side='left', relief='ridge', expand='x')

    gui.config.la := label(gui.f111, 'Configuration', foreground='#b03060')
    gui.config.bn := button(gui.f111, type='menu', relief='groove')
    short := 'Predefined processing options.'
    long  := '\nMenu selection of predefined processing options:\n\
              \n  GENERAL: Normal IEEE FITS cubes\
              \n   HIPASS: Parkes HIPASS (sets 16-bit integer FITS)\
              \n      ZOA: Parkes ZOA (sets 16-bit integer FITS)\n\
              \nN.B.: FITS integer range is -8 to +32 Jy.'
    popuphelp(gui.config.bn, long, short, combi=T)
    gui.config_1.bn := button(gui.config.bn, 'GENERAL', value='GENERAL')
    gui.config_2.bn := button(gui.config.bn, 'HIPASS',  value='HIPASS')
    gui.config_3.bn := button(gui.config.bn, 'ZOA',     value='ZOA')

    whenever
      gui.config_1.bn->press,
      gui.config_2.bn->press,
      gui.config_3.bn->press do
        setparm([config = $value])

    # Popup help options. ----------------------------------------------------
    gui.f1111 := frame(gui.f111, width=0, height=0, borderwidth=0, expand='x')
    popupmenu(gui.f111, relief='groove')

    #=========================================================================
    # Input specification.
    gui.f112 := frame(gui.f11, relief='ridge', expand='both')

    # Browse input files. ----------------------------------------------------
    gui.f1121 := frame(gui.f112, side='left', borderwidth=0, expand='x')
    gui.browse.bn := button(gui.f1121, 'Select input...', pady=2)
    short := 'Browse and select input FITS files.'
    long  := '\nPress the button to invoke a browser for input selection.\n\
              \nFITS input files will be converted to intermediate aips++\
              \nimage format for processing.\n\
              \nWithin the browser listbox directories are marked with a\
              \ntrailing slash; left mouse-button single-, or double-click on\
              \na directory follows it.\n\
              \nSingle-clicking on a file selects it - then click Okay to\
              \naccept it.  Alternatively, double-click on the file.\n\
              \nMultiple files may be selected via left mouse-button click-\
              \nand-drag in the listbox.  Use the CONTROL key on the keyboard\
              \nto augment the selection.  A range may be specified by use of\
              \nthe SHIFT key.'
    popuphelp(gui.browse.bn, long, short, combi=T)

    gui.infiles.fb := F
    whenever
      gui.browse.bn->press do {
        if (is_boolean(gui.infiles.fb)) {
          gui.infiles.fb := filebrowser(title='Input cube file name',
                                        dir=wrk.indir)
          whenever
            gui.infiles.fb->selection do {
              wrk.indir := spaste($value.dir, '/')
              setparm([infiles = strmerg(wrk.indir, $value.file)])
            }

          whenever
            gui.infiles.fb->done do
              gui.infiles.fb := F

        } else {
          # Bring file browser to the top.
          gui.infiles.fb->raise()
        }
      }

    gui.infiles.la := label(gui.f1121, 'Input file list', justify='center',
                            width=1, fill='x')

    # Accumulate input list? -------------------------------------------------
    gui.accum.bn := button(gui.f1121, 'Accumulate', type='check')
    short := 'Accumulate input files.'
    long  := '\nIf enabled, files will be added to the input list, otherwise\
              \nthe input list is rewritten.'
    popuphelp(gui.accum.bn, long, short, combi=T)

    whenever
      gui.accum.bn->press do
        setparm([accum = gui.accum.bn->state()])

    # Clear input list. ------------------------------------------------------
    gui.clear.bn := button(gui.f1121, 'Clear')
    popuphelp(gui.clear.bn, 'Clear the input list.')

    whenever
      gui.clear.bn->press do {
        wrk.accum := parms.accum
        setparm([accum = F, infiles = ""])
        setparm([accum = wrk.accum])
      }

    # Input file list. -------------------------------------------------------
    gui.f1122 := frame(gui.f112, side='left', borderwidth=0, expand='both')
    gui.f1123 := frame(gui.f112, side='left', borderwidth=0, expand='x')

    gui.infiles.tx := text(gui.f1122, wrap='none', width=60, height=10,
                           fill='both', relief='ridge', disabled=T)
    short := 'List of input FITS files.'
    long  := '\nInput files are opened for read-only access.\n\
              \nCompressed FITS files (with .gz suffix) will\
              \nbe decompressed automatically to a temporary\
              \nfile.'
    popuphelp(gui.infiles.tx, long, short, combi=T)

    whenever
      gui.infiles.tx->yscroll do
        gui.infiles.vsb->view($value)

    whenever
      gui.infiles.tx->xscroll do
        gui.infiles.hsb->view($value)

    gui.infiles.vsb := scrollbar(gui.f1122)
    gui.infiles.hsb := scrollbar(gui.f1123, orient='horizontal')
    gui.infiles.pad := frame(gui.f1123, width=20, height=20, expand='none',
                             relief='sunken')

    whenever
      gui.infiles.hsb->scroll,
      gui.infiles.vsb->scroll do
        gui.infiles.tx->view($value)

    gui.infiles.tx->config('normal', foreground='#000000')

    #=========================================================================
    # Processing operations.
    gui.f113 := frame(gui.f11, relief='ridge', expand='x')

    gui.f1131 := frame(gui.f113, side='left', borderwidth=0, expand='x')
    gui.operations.la := label(gui.f1131, 'Processing operations',
                               foreground='#b03060')

    # Cubelet concatenation? -------------------------------------------------
    gui.f1132 := frame(gui.f113, side='left', borderwidth=0, expand='x')
    gui.concat.bn := button(gui.f1132, 'Concatenate', type='check', width=1,
                            fill='x')
    short := 'Concatenate input cubelets?'
    long  := '\nAll input files will be concatenated to produce one output\
              \nfile.  nConcatenation occurs along the spectral (3rd) axis\
              \nof the cubelets.  A check is made for axis conformance.\n\
              \nNote that multiple input files may be specified without\
              \nconcatenation to apply Hanning, etc. to a set of files.\n\
              \nUses \'concat\' in the aips++ images module.'
    popuphelp(gui.concat.bn, long, short, combi=T)

    whenever
      gui.concat.bn->press do
        setparm([concat = gui.concat.bn->state()])

    # Apply Hanning smooth? --------------------------------------------------
    gui.hanning.bn := button(gui.f1132, 'Hanning', type='check', width=1,
                             fill='x')
    short := 'Apply Hanning smooth?'
    long  := '\nSmoothing occurs along the spectral (3rd) axis of the cube.\n\
              \nUses \'hanning\' in the aips++ images module.'
    popuphelp(gui.hanning.bn, long, short, combi=T)

    whenever
      gui.hanning.bn->press do
        setparm([hanning = gui.hanning.bn->state()])

    # Run luther? ------------------------------------------------------------
    gui.luther.bn := button(gui.f1132, 'Luther', type='check',
                            disabled=!wrk.luther, width=1, fill='x')
    short := 'Run luther on the FITS file?'
    long  := '\nThe \'luther\' filter removes baseline distortions\
              \nproduced by continuum sources in Parkes multibeam\
              \nspectral cubes.\n\
              \nNote that this option has restricted availability.'
    popuphelp(gui.luther.bn, long, short, combi=T)

    whenever
      gui.luther.bn->press do
        setparm([luther = gui.luther.bn->state()])

    # Compress FITS file? ----------------------------------------------------
    gui.gzip.bn := button(gui.f1132, 'Compress', type='check', width=1,
                          fill='x')
    short := 'Compress the output FITS file using gzip?'
    long  := '\nOnly applies if FITS output is selected.\n\
              \nFITS integer format (HIPASS/ZOA) compresses well with gzip,\
              \ntypically by a factor of two; IEEE floating less so.\n\
              \nNote that the karma kview viewer can read gzip\'d FITS.'
    popuphelp(gui.gzip.bn, long, short, combi=T)

    whenever
      gui.gzip.bn->press do
        setparm([gzip = gui.gzip.bn->state()])

    #=========================================================================
    # Concatenation options.
    gui.f1133  := frame(gui.f113, side='left', borderwidth=0, expand='x')
    gui.f11331 := frame(gui.f1133, relief='ridge', expand='x')
    gui.catopt.la := label(gui.f11331, 'Concatenation options', width=1,
                           fill='x')

    # Concatenate in sets? ---------------------------------------------------
    gui.catsets.bn := button(gui.f11331, 'Concatenate in sets       ',
                             type='check', width=1, padx=6, fill='x')
    short := 'Split input list into multiple sets?'
    long  := '\nThe input file list will be partitioned according to\
              \nthe first four characters of the file name.\n\
              \nThis allows multiple concatenations to be performed\
              \nin a single run.'
    popuphelp(gui.catsets.bn, long, short, combi=T)

    whenever
      gui.catsets.bn->press do
        setparm([catsets = gui.catsets.bn->state()])

    # Save raw concatenated file? --------------------------------------------
    gui.save.bn := button(gui.f11331, 'Save raw concatenation', type='check',
                          width=1, padx=6, fill='x')
    short := 'Save raw concatenated file?'
    long  := '\nIf the concatenated files are to be further processed\
              \n(Hanning smoothed or luthered) then this provides the\
              \noption to keep the raw cube as well as the processed one.'
    popuphelp(gui.save.bn, long, short, combi=T)

    whenever
      gui.save.bn->press do
        setparm([save = gui.save.bn->state()])

    #=========================================================================
    # FITS options.
    gui.f11332 := frame(gui.f1133, relief='ridge', expand='x')
    gui.fitsopt.la := label(gui.f11332, 'FITS output options', width=2,
                            fill='x')

    # Use integer FITS format? -----------------------------------------------
    gui.intfits.bn := button(gui.f11332, 'Integer FITS               ',
                             type='check', width=1, fill='x')
    short := 'Output FITS data in integer format?'
    long  := '\nFITS data may be written in 16-bit integer format with\
              \nrange -8 to +32 Jy, or in 32-bit IEEE floating format.\n\
              \nBesides being a factor of two smaller, integer format also\
              \nusually compresses quite well with gzip, typically by another\
              \nfactor of two.\n\
              \nHIPASS and ZOA are restricted to integer format.'
    popuphelp(gui.intfits.bn, long, short, combi=T)

    whenever
      gui.intfits.bn->press do
        setparm([intfits = gui.intfits.bn->state()])

    # Use fixed integer range? -----------------------------------------------
    gui.fixint.bn := button(gui.f11332, 'Use fixed integer scale',
                            type='check', width=1, fill='x')
    short := 'Set FITS integer scale to -8 to +32 Jy?'
    long  := '\nWhen FITS data are to be written in 16-bit integer\
              \nformat the scale may be fixed at -8 to +32 Jy, or\
              \nbe adjusted to the minimum and maximum values.\n\
              \nHIPASS and ZOA use the restricted integer range.'
    popuphelp(gui.fixint.bn, long, short, combi=T)

    whenever
      gui.fixint.bn->press do
        setparm([fixint = gui.fixint.bn->state()])

    #=========================================================================
    # Output specification.
    gui.f114 := frame(gui.f11, relief='ridge', expand='x')

    # Output directory. ------------------------------------------------------
    gui.f1141 := frame(gui.f114, side='left', borderwidth=0, expand='x')
    gui.outdir.la := label(gui.f1141, 'Output directory', width=14)
    gui.outdir.en := entry(gui.f1141, width=60, fill='x')
    short := 'Directory location for the output file(s).'
    long  := '\nDefault is the current directory (\'.\') unless the\
              \nMB_CUBE_DESTINATION environment variable is defined.\
              \nThere must be enough space in this directory for the\
              \noutput cube AND all intermediate files which will be\
              \nplaced in a separate subdirectory.'
    popuphelp(gui.outdir.en, long, short, combi=T)

    whenever
      gui.outdir.en->return do
        setparm([outdir = $value])

    # Output file name. ------------------------------------------------------
    gui.f1142 := frame(gui.f114, side='left', borderwidth=0, expand='x')
    gui.outfile.la := label(gui.f1142, 'Output basename', width=14)
    gui.outfile.en := entry(gui.f1142, width=30, fill='x')
    short := 'Basename of the output FITS files.'
    long  := '\nThis only applies if concatenation is selected or if\
              \nthere is only a single input file.\n\
              \nThe file names of Hanning and luther output will\
              \nautomatically receive \'-hann\' and/or \'-luther\'\
              \nqualifiers.\n\
              \nLikewise, the FITS output files will automatically\
              \nreceive a \'.fits\' extension.\n\
              \ngzip automatically adds \'.gz\' to compressed output.'
    popuphelp(gui.outfile.en, long, short, combi=T)

    whenever
      gui.outfile.en->return do
        setparm([outfile = $value])

    # Generate output file name. ---------------------------------------------
    gui.outfgen.bn := button(gui.f1142, 'Auto-generate', type='check',
                                pady=2)
    short := 'Generate basename based on input cube name.'
    long  := '\nPressing this button will generate a basename for the\
              \noutput files based on the (first) input cube filename\
              \nand processing options.\n\
              \nCheck that the basename generated won\'t conflict with\
              \nexisting files!'
    popuphelp(gui.outfgen.bn, long, short, combi=T)

    whenever
      gui.outfgen.bn->press do
        setparm([outfgen = gui.outfgen.bn->state()])

    #=========================================================================
    # Action buttons.
    gui.f12 := frame(gui.f1, side='left', relief='ridge', expand='x')

    # Start processing. ------------------------------------------------------
    gui.go.bn := button(gui.f12, 'Go')
    popuphelp(gui.go.bn, 'Commence processing.')

    whenever
      gui.go.bn->press do
        go()

    # Abort processing. ------------------------------------------------------
    gui.abort.bn := button(gui.f12, 'Abort', disabled=T)
    short := 'Abort processing.'
    long  := '\nProcessing terminates when the current operation completes,\
              \nthere being no way to interrupt the imagetool once it has\
              \nstarted a job.'
    popuphelp(gui.abort.bn, long, short, combi=T)

    whenever
      gui.abort.bn->press do {
        wrk.abort := T
        status('Stopping...')
      }

    # Status messages. -------------------------------------------------------
    gui.f121 := frame(gui.f12, borderwidth=0, expand='x')
    gui.status.sv := label(gui.f121, '', justify='center', width=1, fill='x',
                           foreground='#b03060')
    popuphelp(gui.status.sv, 'Current data processing operation.')

    # Shut down. -------------------------------------------------------------
    gui.exit.bn := button(gui.f12, 'Exit', foreground='#dd0000')
    popuphelp(gui.exit.bn, 'Exit from the GUI and glish.')

    whenever
      gui.exit.bn->press do
        self->terminate()

    #=========================================================================
    # Initialize widgets.
    showparm(gui, parms)

    # For some reason these are needed twice at GUI construction.
    gui.concat.bn->disabled(len(parms.infiles) < 2)
    gui.luther.bn->disabled(!wrk.luther)
    gui.save.bn->disabled(!(parms.concat && (parms.hanning || parms.luther)))
    gui.catsets.bn->disabled(!parms.concat)
    gui.intfits.bn->disabled(parms.config != 'GENERAL')
    gui.fixint.bn->disabled(parms.config != 'GENERAL')
    gui.outfgen.bn->disabled(!(parms.concat || len(parms.infiles) == 1))

    # Lock parameter entry?
    busy()

    tk_release()
  }

  #----------------------------------------------------------- gui.config.show

  const gui.config.show := function()
  {
    gui.config.bn->text(parms.config)

    gui.intfits.bn->disabled(parms.config != 'GENERAL')
    gui.fixint.bn->disabled(parms.config != 'GENERAL')
  }

  #----------------------------------------------------------- gui.concat.show

  const gui.concat.show := function()
  {
    gui.concat.bn->state(parms.concat)

    gui.concat.bn->disabled(len(parms.infiles) < 2)

    if (parms.concat) {
      gui.catopt.la->foreground('#000000')
    } else {
      gui.catopt.la->foreground('#a3a3a3')
    }

    gui.outfile.show()
  }

  #---------------------------------------------------------- gui.catsets.show

  const gui.catsets.show := function()
  {
    gui.catsets.bn->state(parms.catsets)

    gui.catsets.bn->disabled(!parms.concat)
  }

  #----------------------------------------------------------- gui.fixint.show

  const gui.fixint.show := function()
  {
    gui.fixint.bn->state(parms.fixint)

    gui.fixint.bn->disabled(!(parms.config == 'GENERAL' && parms.intfits))
  }

  #---------------------------------------------------------- gui.infiles.show

  const gui.infiles.show := function()
  {
    gui.infiles.tx->delete('start', 'end')

    if (len(parms.infiles)) {
      gui.infiles.tx->append(paste(parms.infiles, sep='\n'), 'normal')
    }

    gui.outfile.show()
  }

  #---------------------------------------------------------- gui.outfgen.show

  const gui.outfgen.show := function()
  {
    gui.outfgen.bn->state(parms.outfgen)

    gui.outfgen.bn->disabled(!(parms.concat || len(parms.infiles) == 1))
  }

  #---------------------------------------------------------- gui.outfile.show

  const gui.outfile.show := function()
  {
    # Enable output filename generation?
    if (parms.concat || len(parms.infiles) == 1) {
      gui.outfile.la->foreground('#000000')
      gui.outfile.en->foreground('#000000')
      gui.outfile.en->disabled(F)
      gui.outfile.en->delete('start', 'end')
      gui.outfile.en->insert(parms.outfile)
    } else {
      gui.outfile.la->foreground('#a3a3a3')
      gui.outfile.en->foreground('#a3a3a3')
      gui.outfile.en->disabled(T)
      gui.outfile.en->delete('start', 'end')
      gui.outfile.en->insert('(not applicable)')
    }

    gui.outfgen.show()
  }

  #------------------------------------------------------------- gui.save.show

  const gui.save.show := function()
  {
    gui.save.bn->state(parms.save)

    gui.save.bn->disabled(!(parms.concat && (parms.hanning || parms.luther)))
  }

  #-------------------------------------------------------------------- status

  # Write an informative message regarding processing status.

  const status := function(...)
  {
    message := paste(...)

    if (is_agent(gui.f1)) {
      gui.status.sv->text(message)
    } else {
      print message
    }
  }

  #---------------------------------------------------------------------------
  # Events that we respond to.
  #---------------------------------------------------------------------------

  # Set parameter values.
  whenever
    self->setparm do
      if (!wrk.busy) setparm($value)

  # Predefined parameter set.
  whenever
    self->setconfig do
      setparm([config = $value])

  # Show parameter values.
  whenever
    self->printparms do {
      readgui()
      print parms
    }

  # Start processing.
  whenever
    self->go do {
      setparm($value)
      go()
    }

  # Abort processing.
  whenever
    self->abort do {
      wrk.abort := T
      status('Stopping...')
    }

  # Create or expose the GUI.
  whenever
    self->showgui do {
      showgui($value)
      self->guidone()
    }

  # Hide the GUI.
  whenever
    self->hidegui do
      if (is_agent(gui.f1)) {
        gui.f1->unmap()
      }

  # Close down.
  whenever
    self->terminate do {
      deactivate wrk.whenevers
      self->done()
      gui  := F
      wrk  := F
      self := F
    }

  wrk.whenevers := whenever_stmts(self).stmt


  #---------------------------------------------------------------------------
  # Initialize.
  #---------------------------------------------------------------------------
  # Set parameters.
  setparm([config  = config,
           infiles = infiles,
           accum   = accum,
           concat  = concat,
           hanning = hanning,
           gzip    = gzip,
           luther  = luther,
           save    = save,
           catsets = catsets,
           intfits = intfits,
           fixint  = fixint,
           outdir  = outdir,
           outfile = outfile,
           outfgen = outfgen])

  if (missarg.outfile) autogen()
}




cuber := cubecat()

# Create the GUI.
cuber->showgui()

whenever
  cuber->done do
    exit
