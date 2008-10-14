#-----------------------------------------------------------------------------
# pkslib.g: Multibeam glish function library.
#-----------------------------------------------------------------------------
# Copyright (C) 2000-2006
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
# $Id: pkslib.g,v 19.11 2006/07/13 06:37:05 mcalabre Exp $
#-----------------------------------------------------------------------------
# This file contains global functions and subsequences commonly used by the
# Multibeam Glish scripts.
#
# Original: 2000/04/10, Mark Calabretta
#-----------------------------------------------------------------------------

pragma include once

global pkslib := [=]

global equ2gal, eulrot, explain, filebrowser, filexp, gal2equ, mkdir, pindx,
       pkslogger, printrecord, resex, sformat, showparm, store, streq,
       strmerg, textviewer, validate, warning

# Font definitions; fixed/variable, medium/bold, and pixel size.
# Vm12 is the glish/tk default for entry boxes.
# Vb12 is the glish/tk default for labels.
fonts := [Fm12 = '-adobe-courier-medium-r-*-*-12',
          Fb12 = '-adobe-courier-bold-r-*-*-12',
          Fb15 = '-misc-fixed-bold-r-*-*-15',
          Vm12 = '-adobe-helvetica-medium-r-*-*-12',
          Vb8  = '-adobe-helvetica-bold-r-*-*-8',
          Vb12 = '-adobe-helvetica-bold-r-*-*-12']

#===================================================================== equ2gal
# Equatorial (J2000.0) to galactic coordinate conversion.
#
# Given:
#    ra,dec     double   J2000.0 RA and Dec (deg).  Either ra and dec are
#                        vectors of equal length, or at least one of them is a
#                        scalar.
#
# Returned:
#    glon,glat  double   Galactic longitude and latitude (deg).
#
# J2000.0  coordinates of the NGP: (12:51:26.2755, +27:07:41.704).
# Galactic coordinates of the NCP: (122.93191814,  +27.12825126).
#-----------------------------------------------------------------------------

const equ2gal := function(ra, dec, ref glon, ref glat)
{
  eul := [-77.14051875,
          +62.87174874,
          +32.93191814,
           +0.455983795747,
           +0.889988077457]

  eulrot(eul, ra, dec, glon, glat)

  mask := glon < 0
  val glon[mask] := glon[mask] + 360
}



#====================================================================== eulrot
# Euler angle-based spherical rotation.
#
# Given:
#    eul        double[5]
#                        Euler angles for the transformation:
#                          1: Longitude of the ascending node in the first
#                             coordinate system (deg).  The ascending node is
#                             the point of intersection of the equators of the
#                             two coordinate systems such that the equator of
#                             the new system crosses from south to north as
#                             viewed in the old system.
#                          2: The angle between the poles of the two systems;
#                             positive for a positive rotation about the
#                             ascending node (deg).
#                          3: Longitude of the ascending node in the second
#                             coordinate system (deg).
#                          4: cos(eul[2])
#                          5: sin(eul[2])
#    lng0,lat0  double   Longitude and latitude (deg).  Either lng0 and lat0
#                        are vectors of equal length, or at least one of them
#                        is a scalar.
#
# Returned:
#    lng1,lat1  double   Transformed longitude and latitude (deg).
#-----------------------------------------------------------------------------

const eulrot := function(eul, lng0, lat0, ref lng1, ref lat1)
{
  D2R := pi/180
  R2D := 180/pi

  lng0 := (lng0 - eul[1])*D2R
  lat0 *:= D2R

  coslng := cos(lng0)
  sinlng := sin(lng0)
  coslat := cos(lat0)
  sinlat := sin(lat0)

  x := coslat*coslng
  y := sinlat*eul[5] + coslat*sinlng*eul[4]

  mask := (x == 0.0 && y == 0.0)
  val lng1 := arg(complex(x,y))*R2D + eul[3]
  if (any(mask)) val lng1[mask] := lng0*R2D + eul[3]

  mask := lng1 <= -180
  val lng1[mask] := lng1[mask] + 360
  mask := lng1 > +180
  val lng1[mask] := lng1[mask] - 360

  z := sinlat*eul[4] - coslat*eul[5]*sinlng
  z[z > +1.0] := +1.0
  z[z < -1.0] := -1.0
  val lat1 := asin(z)*R2D
}



#===================================================================== explain
# Write explanatory text to a global textviewer.
#
# Given:
#    file       string   File containing explanatory text.
#    section    string   Explanatory text section.
#    raise      boolean  Map and raise textviewer to top of window stack?
#
# Returned:
#    none
#-----------------------------------------------------------------------------

const explain := function(file, section='USAGE', raise=T)
{
  global pkslib

  if (!has_field(pkslib, 'explain')) {
    pkslib.explain.tx := textviewer(title = 'Explanation',
                                    file  = file,
                                    lines = '0',
                                    width = 78,
                                    hsb   = F)

    whenever
      pkslib.explain.tx->done do
        pkslib.explain.tx := F

    pkslib.explain.tx->unmap()
  }

  pkslib.explain.tx->setparm([
                       title = paste(file ~ s|.*/|| ~ s|\.g| -|, section),
                       file  = file,
                       lines = spaste('/<',section,'>$/,',
                                      '/<',section,'>$/s/^#//')])

  if (raise) {
    pkslib.explain.tx->raise()
    pkslib.explain.tx->map()
  }
}



#================================================================= filebrowser
# Utility to select files using a glish/tk interface.
#
# Given:
#    title      string   Window frame title.
#    create     boolean  If true, provide an entry box to specify the name of
#                        a file to be created.
#    dir        string   Starting directory.
#    navigate   boolean  Allow navigation above the starting directory?
#    multiple   boolean  Allow multiple file selection?  Cannot be used with
#                        the create option.
#
# Received events:
#    dir(string)         Change directory.
#    stayup(boolean)     Set "Stay up" state.
#    raise()             Raise window to the top of the window stack.
#    map()               Make window visible at the top of the window stack;
#                        no effect if it was not previously unmap'd.
#    unmap()             Make window invisible.
#    terminate()         Close down.
#
# Sent events:
#    selection([dir=<directory>, file=<file>])
#                        The file selected.
#    done([dir=<directory>])
#                        Widget has exited.  The directory is returned.
#-----------------------------------------------------------------------------

const filebrowser := subsequence(title    = 'File Browser',
                                 create   = F,
                                 dir      = '.',
                                 navigate = T,
                                 multiple = F) : [reflect=T]
{
  # Our identity.
  self.name := 'filebrowser'

  fb := [=]

  fb.dir      := spaste(shell('cd', dir, ' && pwd'))
  fb.startdir := fb.dir
  fb.create   := create
  fb.navigate := navigate
  fb.multiple := multiple && !fb.create

  fb.file     := F
  fb.index    := -1
  fb.killsel  := F
  if (fb.multiple) {
    fb.mode   := 'browse'
  } else {
    fb.mode   := 'extended'
  }
  fb.verify   := T

  gui := [=]

  #---------------------------------------------------------------------------
  # Function definitions.
  #---------------------------------------------------------------------------
  # Declare all functions so that their order of definition is irrelevant.
  local setdir, terminate, update, verify

  #-------------------------------------------------------------------- setdir

  # Change directory.

  const setdir := function(dir)
  {
    wider fb

    fb.dir := spaste(shell('cd', dir, ' && pwd'))
    if (fb.dir != '') {
      gui.dir.en->delete('start', 'end')
      gui.dir.en->insert(fb.dir, 'start')
      if (fb.create && fb.navigate) {
        gui.file.en->delete('start', 'end')
        gui.file.en->insert(spaste(fb.dir,'/'), 'start')
      }
      update()
    } else {
      gui.win.lb->delete('start', 'end')
      gui.win.lb->insert('*BAD DIRECTORY*')
      if (fb.create) gui.file.en->delete('start', 'end')
      fb.file := F
    }
  }

  #---------------------------------------------------- filebrowser::terminate

  # Close down the file browser.

  const terminate := function()
  {
     wider fb, gui

     deactivate fb.self
     self->done(([dir=fb.dir]))
     gui := F
     fb  := F
  }

  #------------------------------------------------------- filebrowser::update

  # Update the directory listing.

  const update := function(index=-1)
  {
     wider fb

     ls := '/bin/ls -1Ldp'

     if (gui.long.bn->state())
        ls := spaste(ls, 'l')

     if (gui.rev.bn->state())
        ls := spaste(ls, 'r')

     if (gui.abc.bn->state()) {
        # Alphabetic sort.
     } else if (gui.mod.bn->state()) {
        # Sort by modification time.
        ls := spaste(ls, 't')
     } else if (gui.acc.bn->state()) {
        # Sort by access time.
        ls := spaste(ls, 'u')
     } else if (gui.ino.bn->state()) {
        # Sort by inode modification time.
        ls := spaste(ls, 'c')
     }

     if (gui.all.bn->state()) {
        ls := paste(ls, '.* *')
     } else {
        ls := paste(ls, '. .. *')
     }
     ls := paste('cd', fb.dir, ';', ls, '2>/dev/null')
     files := shell('if [ -r ', fb.dir, ' ] ; then ', ls,
                    '|| true ; else echo "*BAD DIRECTORY*" ; fi')

     files := files[[files != './']]
     if (!fb.navigate) {
       # Disallow navigation above the starting directory.
       if (fb.dir == fb.startdir) {
         files := files[[files != '../']]
       }
     }

     gui.win.lb->delete("start", "end")
     gui.win.lb->insert(files)

     fb.index := index
     if (index == -1) {
        fb.file := F
     } else {
        gui.win.lb->select(as_string(fb.index))
     }
  }

  #------------------------------------------------------- filebrowser::verify

  # Verify file replacement; returns F if the file is not to be overwritten.

  const verify := function()
  {
    wider fb

    if (!is_string(fb.file)) return T

    status := stat(spaste(fb.dir,'/',fb.file), 0)
    if (len(status) == 0 || status.type != 'regular') return T


    tk_hold()

    gui.f2 := frame(title='Verify', expand='none')
    gui.f2->grab('local')

    gui.f21 := frame(gui.f2, padx=30, pady=15, borderwidth=4, relief='ridge',
                     expand='none')

    gui.f211 := frame(gui.f21, expand='none')
    gui.verify.la := label(gui.f211, 'Overwrite existing file?')

    gui.f2111 := frame(gui.f211, side='left')
    gui.overwrite.bn := button(gui.f2111, 'Overwrite', value=T, width=9)
    gui.cancel.bn := button(gui.f2111, 'Cancel', value=F, width=9)

    whenever
      gui.overwrite.bn->press,
      gui.cancel.bn->press do {
        fb.verify := $value
        gui.f2->release()
        gui.f2 := F
      }

    tk_release()

    await gui.overwrite.bn->press, gui.cancel.bn->press

    return fb.verify
  }

  #---------------------------------------------------------------------------
  # Build file browser window.
  #---------------------------------------------------------------------------
  tk_hold()

  gui.f1 := frame(title=title, borderwidth=4, relief='ridge')

  if (is_fail(gui.f1)) {
    print '\n\nWindow creation failed - check that the DISPLAY environment',
          'variable is set\nsensibly and that you have done \'xhost +\' as',
          'necessary.\n'
    gui.f1 := F
    return
  }

  whenever
    self->raise,
    self->map,
    self->unmap do
      gui.f1->[$name]()

  gui.f11 := frame(gui.f1, side='left', borderwidth=0, expand='x')

  gui.dir.bn := button(gui.f11, 'Dir')
  gui.dir.en := entry(gui.f11, disabled=!fb.navigate)
  gui.dir.en->insert(fb.dir, 'start')

  whenever
    gui.dir.bn->press,
    gui.dir.en->return do
      setdir(gui.dir.en->get())

  whenever
    self->dir do
      setdir($value)

  gui.f12 := frame(gui.f1, side='left', borderwidth=0, expand='both')
  gui.f13 := frame(gui.f1, side='left', borderwidth=0, expand='x')

  gui.win.lb := listbox(gui.f12, mode=fb.mode, font=fonts.Fm12, height=10,
                        width=50, fill='both', relief='ridge')

  whenever
    gui.win.lb->yscroll do
      gui.win.vsb->view($value)

  whenever
    gui.win.lb->xscroll do
      gui.win.hsb->view($value)

  whenever
    gui.win.lb->select do {
      # Double-clicks generate two "select" events!
      if (fb.killsel) {
        fb.killsel := F
      } else {
        fb.index := $value

        # Update the directory entry box.
        fb.dir := spaste(shell('cd', fb.dir, '&& pwd'))
        gui.dir.en->delete('start', 'end')
        gui.dir.en->insert(fb.dir, 'start')

        sel := gui.win.lb->get($value)
        if (gui.long.bn->state()) {
          # Long directory listing, dig the filename out.
          sel ~:= s|.{54}||
        }

        if (sel =~ m|/$|) {
          # Got a directory; update the browser.
          fb.dir := split(fb.dir, '/')
          if (sel == '../') {
            if (len(fb.dir) > 1) {
              fb.dir := fb.dir[1:(len(fb.dir)-1)]
            } else {
              fb.dir := ''
            }
          } else if (sel != './') {
            fb.dir[len(fb.dir)+1] := sel ~ s|/$||
          }

          fb.dir := spaste('/', paste(fb.dir, sep='/'))
          gui.dir.en->delete('start', 'end')
          gui.dir.en->insert(fb.dir, 'start')

          if (fb.create && fb.navigate) {
            gui.file.en->delete('start', 'end')
            gui.file.en->insert(spaste(fb.dir,'/'), 'start')
          }

          update()

        } else {
          # Got a file.
          fb.file := sel
          if (fb.create) {
            gui.file.en->delete('start', 'end')
            if (fb.navigate) {
              gui.file.en->insert(paste(fb.dir,fb.file,sep='/'), 'start')
            } else {
              gui.file.en->insert(fb.file, 'start')
            }
          }
        }
      }
    }

  # Enable double-clicking on listbox selections.
  gui.win.lb->bind('<Double-1>', 'double')

  whenever
    gui.win.lb->double do {
      if (is_string(fb.file)) {
        if (!fb.create || verify()) {
          self->selection([dir=fb.dir, file=fb.file])
          if (!gui.stay.bn->state()) terminate()
        }
      }

      # Kill the select event that will follow this.
      fb.killsel := T
    }

  gui.win.vsb := scrollbar(gui.f12)
  gui.win.hsb := scrollbar(gui.f13, orient='horizontal')
  gui.win.pad := frame(gui.f13, width=20, height=20, expand='none',
                       relief='sunken')

  whenever
    gui.win.vsb->scroll,
    gui.win.hsb->scroll do
      gui.win.lb->view($value)

  if (fb.create) {
    gui.f14 := frame(gui.f1, side='left', borderwidth=0, expand='x')
    gui.file.la := label(gui.f14, 'File')
    gui.file.en := entry(gui.f14)
    if (fb.navigate) gui.file.en->insert(spaste(fb.dir,'/'), 'start')

    whenever
      gui.file.en->return do {
        fb.dir  := $value ~ s|(.*/)*.*$|$1|
        fb.file := $value ~ s|.*/||
        if (len(fb.file) == 0) fb.file := F

        if (fb.dir == '') {
          # No path specified.
          fb.dir := gui.dir.en->get()
        } else if (fb.dir !~ m|^/|) {
          # Relative path specified.
          fb.dir := spaste(gui.dir.en->get(), '/', fb.dir)
        }

        # Strip trailing slash.
        fb.dir =~ s|/$||

        if (verify()) {
          if (is_string(fb.file)) self->selection([dir=fb.dir, file=fb.file])
          if (!gui.stay.bn->state()) terminate()
        }
      }

    # Notice key presses in the file entry box.
    gui.file.en->bind('<KeyPress>', 'key')

    whenever
      gui.file.en->key do
        gui.win.lb->clear('start', 'end')
  }

  gui.f15 := frame(gui.f1, side='left', borderwidth=0, expand='x')

  # List options.
  gui.opts.bn := button(gui.f15, 'Options', type='menu', relief='groove')
  gui.long.bn := button(gui.opts.bn, 'Long list',    type='check')

  whenever
    gui.long.bn->press do {
      if (gui.long.bn->state()) {
        gui.win.lb->width(80)
      } else {
        gui.win.lb->width(50)
      }
      update(fb.index)
    }

  gui.all.bn := button(gui.opts.bn, 'List all',     type='check')
  gui.rev.bn := button(gui.opts.bn, 'Reverse sort', type='check')

  # Nest of radio buttons used for setting the sort type.
  gui.abc.bn := button(gui.opts.bn, 'Alpha',        type='radio')
  gui.mod.bn := button(gui.opts.bn, 'Time modified',type='radio')
  gui.acc.bn := button(gui.opts.bn, 'Access time',  type='radio')
  gui.ino.bn := button(gui.opts.bn, 'Inode time',   type='radio')
  gui.abc.bn->state(T)

  whenever
    gui.all.bn->press,
    gui.rev.bn->press,
    gui.abc.bn->press,
    gui.mod.bn->press,
    gui.acc.bn->press,
    gui.ino.bn->press do
      update()

  # Browser control buttons.
  gui.stay.bn := button(gui.f15, 'Stay up', type='check')

  whenever
    gui.stay.bn->press do
      if (!gui.stay.bn->state()) terminate()

  # Spacer.
  gui.f151 := frame(gui.f15, height=0, borderwidth=0)

  whenever
    self->stayup do
      gui.stay.bn->state($value)

  gui.ok.bn := button(gui.f15, 'Okay')

  whenever
    gui.ok.bn->press do {
      if (fb.create) {
        value := gui.file.en->get()
        fb.dir  := value ~ s|(.*/)*.*$|$1|
        fb.file := value ~ s|.*/||
        if (len(fb.file) == 0) fb.file := F
      }

      if (fb.dir == '') {
        # No path specified.
        fb.dir := gui.dir.en->get()
      } else if (fb.dir !~ m|^/|) {
        # Relative path specified.
        fb.dir := spaste(gui.dir.en->get(), '/', fb.dir)
      }

      # Strip trailing slash.
      fb.dir =~ s|/$||

      if (!fb.create || verify()) {
        if (is_string(fb.file)) self->selection([dir=fb.dir, file=fb.file])
        if (!gui.stay.bn->state()) terminate()
      }
    }

  gui.dismiss.bn := button(gui.f15, 'Dismiss')

  whenever
    gui.dismiss.bn->press,
    self->terminate do
      terminate()

  tk_release()


  #---------------------------------------------------------------------------
  # Initialization.
  #---------------------------------------------------------------------------
  # Events that we listen for.
  fb.self := whenever_stmts(self).stmt

  # Initialize the file browser.
  update()

  return
}



#====================================================================== filexp
# Translate a file wildcard expression into a glish regular expression.
#
# Given:
#    wildcard   string   File wildcard expression.
#
# Function return value:
#               regexp   The regular exppression containing the translation.
#-----------------------------------------------------------------------------

const filexp := function(wildcard = '*')
{
  wildcard := wildcard ~ s/\./\\./g  \
                       ~ s/\?/./g    \
                       ~ s/\*/.*/g   \
                       ~ s/ /$|^/g

  eval(spaste('return m/^', wildcard, '$/'))
}



#===================================================================== gal2equ
# Galactic to equatorial (J2000.0) coordinate conversion.
#
# Given:
#    glon,glat  double   Galactic longitude and latitude (deg).  Either glon
#                        and glat are vectors of equal length, or at least one
#                        of them is a scalar.
#
# Returned:
#    ra,dec     double   J2000.0 RA and Dec (deg).
#
# J2000.0  coordinates of the NGP: (12:51:26.2755, +27:07:41.704).
# Galactic coordinates of the NCP: (122.93191814,  +27.12825126).
#-----------------------------------------------------------------------------

const gal2equ := function(glon, glat, ref ra, ref dec)
{
  eul := [+32.93191814,
          -62.87174874,
          -77.14051875,
           +0.455983795747,
           -0.889988077457]

  eulrot(eul, glon, glat, ra, dec)
  mask := ra < 0
  val ra[mask] := ra[mask] + 360
}



#======================================================================= mkdir
# Create a sequence of directories.
#
# Given:
#    path       string   An absolute or relative pathname.  Understands
#                        tilde (~) notation for home directories.
#    file       boolean  If true, directory components must have a trailing
#                        slash, e.g. './dir1/dir2/file' creates ./dir1 then
#                        ./dir1/dir2 and 'file' is ignored.  Hence to create
#                        a single directory in this mode its name must end in
#                        a slash.
#    umask      string   Directory creation umask, e.g. 2022.
#
# Function return value:
#    A fail-value if any of the directories were not created, otherwise T.
#
# Original: 2004/07/26 MRC (from TCS)
#-----------------------------------------------------------------------------

pragma include once

const mkdir := function(path='', file=F, umask='')
{
  if (!is_string(path)) fail paste('Non-string path specification:', path)
  if ((path := path[1]) == '') return T

  # Strip off file component?
  if (file) {
    path =~ s|[^/]*$||
    if (path == '') return T
  }

  # Check for quick return.
  status := stat(path, follow=T)
  if (len(status)) {
    if (status.type == 'directory') return T
    fail paste(path, 'exists and is not a directory.')
  }

  # Set umask.
  if (missing()[3]) {
    umask := ''
  } else {
    umask := paste('umask', umask, ';')
  }

  dirs := split(path, '/')
  if (path ~ m|^/|) {
    # Absolute pathname.
    path := '/'

  } else if (path ~ m|^~|) {
    if (dirs[1] == '~') {
      # Home directory.
      path := environ.HOME

    } else {
      # Someone else's home directory.
      path := shell('csh -c \'echo', dirs[1], '\'')
    }

    dirs := dirs[2:len(dirs)]

  } else {
    # Relative pathname.
    path := '.'

    if (dirs[1] == '.') dirs := dirs[2:len(dirs)]
  }

  for (dir in dirs) {
    path := spaste(path, '/', dir)
    status := stat(path, follow=T)

    if (len(status) == 0) {
      shell(umask, 'mkdir', path)
      status := stat(path, follow=T)
    }

    if (!len(status)) {
      print msg := paste('Failed to create', path)
      fail msg
    } else if (status.type != 'directory') {
      print msg := paste(path, 'exists and is not a directory.')
      fail msg
    }
  }

  return T
}



#======================================================================= pindx
# Return an index of record field names.
#
# Given:
#    record     record   The record to be indexed.
#
# Function return value:
#               record   The index, e.g. if the input record was
#
#                          [a = 'a', b = 7.9, c = [u = 1, v = 0, w = 0]]
#
#                        the index is
#
#                          [a = 1, b = 2, c = 3]
#
# Notes:
#    1) It is useful to index function arguments so that missing arguments
#       may be referred to by name, e.g.
#
#         p := pindx(parameters())
#         if (missing()[p.arg1]) arg1 := do_something()
#
#-----------------------------------------------------------------------------

const pindx := function(record=[=])
{
  j := 0
  r := [=]
  for (field in field_names(record)) {
    j +:= 1
    r[field] := j
  }

  return r
}



#=================================================================== pkslogger
# Simple logger with batch or graphical modes of operation.
#
# Given:
#    title      string   Window frame title.
#    file       string   Output file name.
#    utc        boolean  Write UTC timestamps?  Else local time.
#    reuse      boolean  Reuse a previously-created pkslogger if available?
#    share      boolean  Share this pkslogger with other clients?
#
# Received events:
#    setparm(record)     Set parameter values.
#    printparms()        Print parameter values.
#    log()               Write a message.
#    raise()             Raise window to the top of the window stack.
#    showgui(agent)      Create the GUI or make it visible if it already
#                        exists.  The parent frame may be specified.
#    hidegui()           Make log window invisible.
#    nogui()             Destroy the log window.
#    terminate()         Close down.
#
# Sent events:
#    guiready()          GUI construction complete.
#    done()              Logger has exited.
#
# Notes:
#    1) The pkslogger is implemented as a function that emulates a
#       subsequence.  A global reference is maintained to the agent variable
#       created on the first invokation and this is returned on subsequent
#       invokations (if shared usage is required).  This allows different
#       clients to share one instance of a pkslogger.
#
#    2) It is assumed that the icon path has been defined beforehand by a call
#       to tk_iconpath().
#-----------------------------------------------------------------------------

const pkslogger := function(title = 'Multibeam logger',
                            file  = '',
                            utc   = T,
                            reuse = T,
                            share = T) : [reflect=T]
{
  # Do we want to use a pkslogger that has already been instantiated?
  if (reuse && is_defined('pkslogger_agent')) return ref pkslogger_agent

  # Our identity.
  self := create_agent()
  self.name := 'pkslogger'

  # Parameter values.
  parms := [=]

  # Parameter value checking.
  pchek := [
    title      = [string  = [default = 'Multibeam logger']],
    file       = [string  = [default = '']],
    utc        = [boolean = [default = T]],
    reuse      = [boolean = [default = T]],
    share      = [boolean = [default = T]]]

  if (!streq(field_names(pchek), field_names(parameters()))) {
    print spaste('pkslogger: internal inconsistency - pchek field names.')
  }

  # Work variables.
  wrk := [=]

  wrk.date    := ''
  wrk.handle  := F
  wrk.scroll  := T

  wrk.palette := [
    background = "#d4d4d4 Normal background",
    active     = "#ececec Active widgets",
    NORMAL     = "#000000 Unexceptional messages",
    HIGHLIGHT  = "#dddddd Highlighted messages",
    BOLD       = "#000000 Bold-text messages",
    WARN       = "#ff9933 Warnings",
    SEVERE     = "#ff3333 Serious errors",
    scroll     = "#000000 Scroll active",
    noscroll   = "#dd0000 Scroll inactive"]

  # GUI widgets.
  gui := [=]
  gui.f1 := F

  #---------------------------------------------------------------------------
  # Local function definitions.
  #---------------------------------------------------------------------------
  local logger, setparm, set := [=], showgui

  #------------------------------------------------------------ pkslogger::log

  # Write a message in the log.

  const log := function(msg='', priority='NORMAL')
  {
    wider wrk

    # Current day number.
    if (parms.utc) {
      date := shell('date -u \'+%Y/%m/%d UTC (%a)\'')
    } else {
      date := shell('date \'+%Y/%m/%d %Z (%a)\'')
    }

    # Log the full date and identification if the date has changed.
    if (wrk.date != date) {
      wrk.date := date
      if (parms.utc) {
        timer := shell('date -u \'+%T: %Y/%m/%d UTC (%a) \'')
      } else {
        timer := shell('date \'+%T: %Y/%m/%d %Z (%a) \'')
      }

      if (is_agent(gui.f1)) {
        if (wrk.scroll) {
          gui.log.tx->append(spaste(timer, parms.title, '\n'), 'NORMAL')
        } else {
          gui.log.tx->insert(spaste(timer, parms.title, '\n'), 'end', 'NORMAL')
        }

      } else {
        print timer
      }

      if (is_file(wrk.handle)) write(wrk.handle, spaste('\n\n', timer))
    }

    if (any(!missing())) {
      if (is_record(msg)) {
         # Reformat an aips++ Logger record.
         if (msg.location == '') {
           location := ''
         } else {
           location := msg.location ~ s|(pks)*(.*)|$2:|
         }

         priority := spaste(msg.priority)
         msg := sprintf('%10s %s', location, msg.message)
      }

      if (parms.utc) {
        timer := shell('date -u \'+%T\'')
      } else {
        timer := shell('date \'+%T\'')
      }

      # Write message out.
      if (is_agent(gui.f1)) {
        if (wrk.scroll) {
          # Automatically scrolls to the end of the text viewer.
          gui.log.tx->append(spaste(timer, ': '), 'NORMAL')
          gui.log.tx->append(spaste(msg, '\n'), priority)
        } else {
          # Doesn't scroll the text viewer.
          gui.log.tx->insert(spaste(timer, ': '), 'end', 'NORMAL')
          gui.log.tx->insert(spaste(msg, '\n'), 'end', priority)
        }

      } else {
        print spaste(timer, ': ', msg)
      }

      # Write timestamped message to log file.
      if (is_file(wrk.handle)) write(wrk.handle, spaste(timer, ': ', msg))
    }
  }

  #-------------------------------------------------------- pkslogger::setparm

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
    value := validate(pchek, parms, value)

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

  #------------------------------------------------------- pkslogger::set.file

  # Set the output log file.

  const set.file := function(value)
  {
    wider parms, wrk

    parms.file := value

    # Close the current file.
    wrk.handle := F

    # Open the output file.
    if (parms.file != '') {
      wrk.handle := open(paste('>>', parms.file))
      if (is_fail(wrk.handle)) {
        print spaste('Failed to open ', parms.file,
                     ', continuing without log file.')
        wrk.handle := F
      }
    }
  }

  #-------------------------------------------------------- pkslogger::showgui

  # Build a graphical log window.

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
      gui.f1->expand('both')
      gui.f1->map()
      gui.f1.top := F

    } else {
      # Create a top-level frame.
      gui.f1 := frame(title=parms.title, expand='both')

      if (is_fail(gui.f1)) {
        print '\n\nWindow creation failed - check that the DISPLAY',
              'environment variable is set\nsensibly and that you have done',
              '\'xhost +\' as necessary.\n'
        gui.f1 := F
        return
      }

      gui.f1.top := T
    }

    #-------------------------------------------------------------------------

    gui.f11  := frame(gui.f1, relief='ridge', borderwidth=4)
    gui.f111 := frame(gui.f11, side='left', borderwidth=0, expand='both')
    gui.f112 := frame(gui.f11, side='left', borderwidth=0, expand='x')

    gui.log.tx := text(gui.f111, wrap='none', relief='ridge', width=100,
                       height=10, fill='both', disabled=T)

    for (t in field_names(wrk.palette)) {
      if (any(t == "SEVERE WARN")) {
        # Write error and warnings in bold font and reverse video.
        gui.log.tx->config(t, font=fonts.Fb12,
                           foreground=wrk.palette.active,
                           background=wrk.palette[t])

      } else if (t == 'HIGHLIGHT') {
        gui.log.tx->config(t, background=wrk.palette[t])

      } else if (t == 'BOLD') {
        gui.log.tx->config(t, font=fonts.Fb12, foreground=wrk.palette[t])

      } else {
        gui.log.tx->config(t, foreground=wrk.palette[t])
      }
    }

    whenever
      gui.log.tx->yscroll do {
        if ($value[2] == 1.0) {
          if (!wrk.scroll) {
            gui.log.bn->foreground(wrk.palette.scroll)
            wrk.scroll := T
          }
        } else {
          if (wrk.scroll) {
            gui.log.bn->foreground(wrk.palette.noscroll)
            wrk.scroll := F
          }
        }

        gui.log.vsb->view($value)
      }

    whenever
      gui.log.tx->xscroll do
        gui.log.hsb->view($value)

    gui.log.vsb := scrollbar(gui.f111, width=8)
    gui.log.hsb := scrollbar(gui.f112, orient='horizontal', width=8)

    whenever
      gui.log.hsb->scroll,
      gui.log.vsb->scroll do
        gui.log.tx->view($value)

    gui.log.bn  := button(gui.f112, bitmap='blank6x6.xbm')

    whenever
      gui.log.bn->press do
        gui.log.tx->see('end')

    tk_release()

    # Write a header line.
    log()

    self->guiready()
  }

  #---------------------------------------------------------------------------
  # Events that we respond to.
  #---------------------------------------------------------------------------

  # Set parameter values.
  whenever
    self->setparm do
      setparm($value)

  # Show parameter values.
  whenever
    self->printparms do
      print parms

  # Log a message.
  whenever
    self->log do
      log($value)

  # Create or expose the GUI.
  whenever
    self->showgui do
      showgui($value)

  # Hide the GUI.
  whenever
    self->hidegui do
      if (is_agent(gui.f1)) gui.f1->unmap()

  # Destroy the GUI.
  whenever
    self->nogui do
      gui.f1 := F

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
  args := [title = title,
           file  = file,
           utc   = utc,
           reuse = reuse,
           share = share]

  if (!streq(field_names(args), field_names(pchek))) {
    print spaste('pkslogger: internal inconsistency - args field names.')
  }

  setparm(args)

  if (share) global pkslogger_agent := ref self

  return self
}



#================================================================= printrecord
# Print a record in a nicely formatted way.
#
# Given:
#    rec        record   The record whose value is to be printed.
#-----------------------------------------------------------------------------

const printrecord := function(rec, name='', q='')
{
  l := len(rec)
  p := ','

  if (name == '') {
    name := spaste('[')
  } else {
    name := spaste(name, '=[')
  }

  for (field in field_names(rec)) {
    l -:= 1
    if (l == 0) p := spaste(']', q)

    if (is_record(rec[field])) {
      printrecord(rec[field], spaste(name,field), p)

    } else if (is_string(rec[field])) {
      print spaste(name, field, '="', rec[field], '"', p)

    } else {
      print spaste(name, field, '=', rec[field], p)
    }

    name =~ s|.| |g
  }
}



#======================================================================= resex
# Reencode sexagesimal formatting information converting times to angle.
#
# Given:
#    value      double   Time or angle.
#    time       boolean  Is value time or not?
#
# Function return value:
#               double   value with sexagesimal formatting attributes applied
#                        and converted to angle if it was a time.
#-----------------------------------------------------------------------------

const resex := function(value, time=F)
{
  if (!has_field(value::, 'format')) {
    # No formatting attributes.
    value::format := [type = 'void', precision = 4]

  } else if (is_string(value::format)) {
    # Decimal, rather than sexagesimal, formatting attributes.
    p := as_integer(value::format ~ s|.*\.(\d+)f$|$1|) - 3
    value::format := [type = 'void', precision = p]
  }

  # Convert times to angles for internal use.
  if (value::format.type == 'time' ||
     (value::format.type == 'void' && time)) {
    value *:= 15.0
    value::format.precision -:= 1
  }
  value::format.type := 'angle'
  value::format.signed := T

  return value
}



#===================================================================== sformat
# Extension of sprintf formatting that handles complex and sexagesimal
# formatting, and negative zero.
#
# Given:
#    value    any        Value to be formatted as a string.
#    format   string     sprintf() format specification, or
#             record     Sexagesimal format specification containing the
#                        following fields:
#
#                                type: 'angle' (o'") or 'time' (hms).
#
#                           precision: number of decimal places in the seconds
#                                      field.
#
#                              signed: if T positive values will be signed.
#
# Function return value:
#             string     The formatted value.
#
#-----------------------------------------------------------------------------

const sformat := function(value, format='')
{
  if (has_field(value::, 'format')) format := value::format

  if (is_string(format)) {
    if (is_dcomplex(value)) {
      if (format == '') {
        return as_string(real(value), imag(value))
      } else {
        return sprintf(format, real(value), imag(value))
      }

    } else if (is_numeric(value) && value == 0 && has_field(value::, 'sign')) {
      if (format == '') {
        return '-0'
      } else {
        return sprintf(format, -9) ~ s|9|0|
      }

    } else {
      if (format == '') {
        return as_string(value)
      } else {
        return sprintf(format, value)
      }
    }

  } else {
    # Sexagesimal formatting.
    if (type_name(value) != 'double') return as_string(value)

    # Record sign.
    if (value < 0.0) {
      sign := '-'
    } else if (has_field(format, 'signed') && format.signed) {
      sign := '+'
    } else {
      sign := ''
    }

    # Work in integer arithmetic to avoid rounding problems.
    if (has_field(format, 'precision')) {
      precision := max(0, format.precision)
    } else {
      precision := 0
    }

    # Be careful to avoid integer overflow.
    scale := as_integer(10^precision)
    value := abs(value * 3600) + 0.5/scale

    v4 := as_integer((value - as_integer(value)) * scale)
    value := as_integer(value)
    v3 := value%60
    value := as_integer((value-v3)/60 + 0.5)
    v2 := value%60
    v1 := as_integer((value-v2)/60 + 0.5)

    # Angle or time formatting?
    if (has_field(format, 'type')) {
      type := format.type
    } else {
      type := ':'
    }

    if (type == 'angle') {
      # Angle in DMS.
      s1 := sprintf('%c', 176)
      s2 := '\''
      s3 := '"'
      s4 := ''

    } else if (type == 'time') {
      # Time in HMS.
      s1 := 'h'
      s2 := 'm'
      s3 := ''
      s4 := 's'

    } else {
      # Unspecified type.
      s1 := ':'
      s2 := ':'
      s3 := ''
      s4 := ''
    }

    if (precision > 0) {
      format := spaste('%s%02d%s%02d%s%02d%s.%0', precision, 'd%s')
      return sprintf(format, sign, v1, s1, v2, s2, v3, s3, v4, s4)
    } else {
      format := spaste('%s%02d%s%02d%s%02d%s%s')
      return sprintf(format, sign, v1, s1, v2, s2, v3, s3, s4)
    }
  }
}



#==================================================================== showparm
# showparm() updates widget(s) associated with parameter values if the GUI
# is active.
#
# Given:
#    gui      record     Record containing widget agent variables.
#    parms    record     Each field, item, of the paramater record identifies
#                        a widget as
#
#                           gui[item].bn   ...button
#                           gui[item].en   ...entry box
#                           gui[item].sv   ...label (status value)
#                           gui[item].lb   ...listbox
#
#                        If
#
#                           gui[item].show
#
#                        is defined it is taken to be a specialized function
#                        for displaying the parameter.  Otherwise showparm()
#                        does a generic widget update.
#
# Generic update methods
# ----------------------
# 1) If the parameter associated with a button is of boolean type then the
#    button is assumed to be a check-button.
#
# 2) For other button types, and for entry box and status value widgets,
#    parameter values are reformatted to string and this becomes the button or
#    status value label, or entry box contents.  An sprintf() format may be
#    specified for the conversion via
#
#      gui[item].en.format
#      gui[item].bn.format
#      gui[item].sv.format
#
#    If a format is not defined then as_string() is used to cast the parameter
#    value to string.
#
# 3) Vector-valued parameters are assumed to be associated with vectors of
#    buttons or entry boxes.
#-----------------------------------------------------------------------------

const showparm := function(gui, parms)
{
  if (is_agent(gui.f1)) {
    for (item in field_names(parms)) {
      if (has_field(gui, item)) {
        if (has_field(gui[item], 'show')) {
          # Invoke specialized update procedure.
          gui[item].show()

        } else if (has_field(gui[item], 'bn')) {
          # Relabel the button(s).
          if (len(parms[item]) == 1) {
            if (is_boolean(parms[item])) {
              gui[item].bn->state(parms[item])
            } else {
              if (has_field(gui[item].bn, 'format')) {
                gui[item].bn->text(sformat(parms[item], gui[item].bn.format))
              } else {
                gui[item].bn->text(sformat(parms[item]))
              }
            }
          } else {
            if (is_boolean(parms[item])) {
              for (j in 1:len(parms[item])) {
                gui[item].bn[j]->state(parms[item][j])
              }
            } else {
              for (j in 1:len(parms[item])) {
                if (has_field(parms[item]::, 'format')) {
                  gui[item].bn[j]->text(sformat(parms[item][j],
                                                parms[item]::format[j]))
                } else if (has_field(gui[item].bn[j], 'format')) {
                  gui[item].bn[j]->text(sformat(parms[item][j],
                                                gui[item].bn[j].format))
                } else {
                  gui[item].bn[j]->text(sformat(parms[item][j]))
                }
              }
            }
          }

        } else if (has_field(gui[item], 'en')) {
          # Update the entry box(s).
          if (len(parms[item]) == 1) {
            gui[item].en->delete('start', 'end')
            if (has_field(gui[item].en, 'format')) {
              gui[item].en->insert(sformat(parms[item], gui[item].en.format))
            } else {
              gui[item].en->insert(sformat(parms[item]))
            }
          } else {
            for (j in 1:len(parms[item])) {
              gui[item].en[j]->delete('start', 'end')
              if (has_field(parms[item]::, 'format')) {
                gui[item].en[j]->insert(sformat(parms[item][j],
                                                parms[item]::format[j]))
              } else if (has_field(gui[item].en[j], 'format')) {
                gui[item].en[j]->insert(sformat(parms[item][j],
                                                gui[item].en[j].format))
              } else {
                gui[item].en[j]->insert(sformat(parms[item][j]))
              }
            }
          }

        } else if (has_field(gui[item], 'sv')) {
          # Update the status value.
          if (has_field(gui[item].sv, 'format')) {
            gui[item].sv->text(sformat(parms[item], gui[item].sv.format))
          } else {
            gui[item].sv->text(sformat(parms[item]))
          }

        } else if (has_field(gui[item], 'lb')) {
          # Update the list box.
          gui[item].lb->delete('start', 'end')
          if (len(parms[item])) {
            gui[item].lb->insert(parms[item])
            gui[item].lb->see('end')
          }
        }
      }
    }
  }
}



#======================================================================= store
# Store a value to a file using write_value().  The file name may be given as
# an absolute or relative pathname of which any non-existent directories will
# be created.
#
# Given:
#    value    any        Value to be stored to file.
#    file     string     Pathname of file.
#
# Function return value:
#    A fail-value if any of the directories were not created, otherwise T.
#-----------------------------------------------------------------------------

const store := function(value, file)
{
  if (is_fail(mkdir(file, file=T))) fail
  return write_value(value, file)
}



#======================================================================= streq
# Check that two string arrays are equal.
#-----------------------------------------------------------------------------

const streq := function(s1, s2)
{
  if (len(s1) != len(s2)) return F
  return all(s1 == s2)
}



#===================================================================== strmerg
# Merge two string vectors.  Either the vectors are the same length, or one or
# other of them is of unit length.  The result is returned as the function
# value.
#
# Given:
#    prefix   string[]   String(s) to be prepended.
#    suffix   string[]   String(s) to be appended.
#
# Function return value:
#             string[]   The merged string(s).
#-----------------------------------------------------------------------------

const strmerg := function(prefix, suffix)
{
  l1 := len(prefix)
  l2 := len(suffix)

  result := ""

  if (l1 == l2) {
    if (l1 > 0) {
      for (j in 1:l1) {
        result[j] := spaste(prefix[j], suffix[j])
      }
    }

  } else if (l1 == 1) {
    if (l2 > 0) {
      for (j in 1:l2) {
        result[j] := spaste(prefix, suffix[j])
      }
    }

  } else if (l2 == 1) {
    if (l1 > 0) {
      for (j in 1:l1) {
        result[j] := spaste(prefix[j], suffix)
      }
    }

  } else {
    fail 'String merge failed - incompatible string vector lengths.'
  }

  return result
}



#================================================================== textviewer
# Utility to display ASCII text from a file using a glish/tk window.
#
# Arguments:
#    title      string   Window frame title.
#    file       string   File name (no default).  If "-" input will be taken
#                        from the records argument.
#    records    string[] Text records if file is "-".
#    index      string   Index column type.  If LINE, the index will be a
#                        simple line number count; if ENTRY, comments and
#                        blank lines will be skipped.  Anything else results
#                        in no index.
#    lines      string   Range of lines to display (sed format).  Set to '0'
#                        to defeat.
#    height     int      Display height.
#    width      int      Display width.
#    hsb        boolean  Add horizontal scroll bar?
#    vsb        boolean  Add vertical scroll bar?
#
# Received events:
#    setparm(record)     Open a new file.
#                           title   string   Window frame title.
#                           file    string   File name path specification.
#                           records string[] Text records if file is '-'.
#                           lines   string   Range of lines to display.
#                           height  int      Display height.
#                           width   int      Display width.
#    raise()             Raise window to the top of the window stack.
#    map()               Make window visible at the top of the window stack;
#                        no effect if it was not previously unmap'd.
#    unmap()             Make window invisible.
#    terminate()         Close down.
#
# Sent events:
#    done()              Viewer has exited.
#-----------------------------------------------------------------------------

const textviewer := subsequence(title   = 'Text viewer',
                                file    = '',
                                records = '',
                                index   = 'NONE',
                                lines   = '1,$',
                                height  = 25,
                                width   = 80,
                                hsb     = T,
                                vsb     = T) : [reflect=T]
{
  # Parameter values.
  parms := [=]

  parms.file    := file
  parms.records := records
  parms.index   := index
  parms.indx    := any(index == "LINE ENTRY")
  parms.lines   := lines

  # Work variables.
  wrk := [=]

  # GUI widgets.
  gui := [=]
  gui.f1 := F


  #---------------------------------------------------------------------------
  # Function definitions.
  #---------------------------------------------------------------------------
  # Declare all functions so that their order of definition is irrelevant.
  local update

  #-------------------------------------------------------------------- update

  const update := function()
  {
    tk_hold()

    if (parms.indx) gui.indx.tx->delete('start', 'end')
    gui.text.tx->delete('start', 'end')

    if (parms.file == '-') {
      gui.text.tx->append(paste(parms.records, sep='\n'), 'black')
    } else if (parms.lines != '0') {
      cmd := spaste('if [ -r \'', parms.file, '\' ] ; then sed -n \'',
                    parms.lines, 'p\' \'', parms.file,
                   '\'; else echo "*BAD FILE*"; fi')
      gui.text.tx->append(paste(shell(cmd), sep='\n'), 'black')
    }

    gui.text.tx->see('start')

    if (parms.indx) {
      # Construct the index.
      n := as_integer(gui.text.tx->ranges('black'))[2]

      if (parms.index == 'LINE') {
        # Simple line count.
        wid := as_integer(log(n)) + 1
        fmt := spaste('%', wid, 'd')
        indx := sprintf(fmt, 1:n)

      } else {
        # Count non-comments only.
        count := 0
        for (i in 1:n) {
          rec := gui.text.tx->get(sprintf('%d.0',i), sprintf('%d.end',i))
          if (rec =~ m|^\s*[^#\s]|) {
            count +:= 1
            idx[i] := count
          } else {
            idx[i] := 0
          }
        }

        wid := as_integer(log(count)) + 1
        fmt := spaste('%', wid, 'd')
        indx := sprintf(fmt, idx)
        fmt := spaste('%', wid, 's')
        indx[idx == 0] := sprintf(fmt, '-')
      }

      gui.indx.tx->width(wid)
      gui.indx.tx->append(paste(indx, sep='\n'), 'red')
      gui.indx.tx->see('start')
    }

    tk_release()
  }


  #---------------------------------------------------------------------------
  # Build text viewer window.
  #---------------------------------------------------------------------------
  tk_hold()
  gui.f1 := frame(title=title, relief='ridge', borderwidth=4)

  whenever
    self->raise,
    self->map,
    self->unmap do
      gui.f1->[$name]()

  gui.f11 := frame(gui.f1, side='left', borderwidth=0, expand='both')

  if (parms.indx) {
    gui.indx.tx := text(gui.f11, height=height, width=3, fill='y',
                        relief='ridge', wrap='none', disabled=T)
    gui.indx.tx->config('red', foreground='#ff0000')
  }

  gui.text.tx := text(gui.f11, height=height, width=width, fill='both',
                      relief='ridge', wrap='none', disabled=T)

  gui.text.tx->config('black', foreground='#000000')

  # Vertical scroll bar.
  if (vsb) {
    gui.text.vsb := scrollbar(gui.f11, width=10)

    whenever
      gui.text.vsb->scroll do {
        if (parms.indx) gui.indx.tx->view($value)
        gui.text.tx->view($value)
      }

    whenever
      gui.text.tx->yscroll do {
        if (hsb) {
          if ($value[2] == 1.0) {
            gui.text.bn->relief('sunken')
          } else {
            gui.text.bn->relief('raised')
          }
        }

        gui.text.vsb->view($value)
      }
  }

  # Horizontal scroll bar.
  if (hsb) {
    gui.f12 := frame(gui.f1, side='left', borderwidth=0, expand='x')
    gui.text.hsb := scrollbar(gui.f12, orient='horizontal', width=10)

    whenever
      gui.text.hsb->scroll do
        gui.text.tx->view($value)

    whenever
      gui.text.tx->xscroll do
        gui.text.hsb->view($value)

    if (vsb) {
      gui.text.bn := button(gui.f12, bitmap='blank10x10.xbm')

      whenever
        gui.text.bn->press do {
          if (parms.indx) gui.indx.tx->see('end')
          gui.text.tx->see('end')
        }
    }
  }

  # Dismiss button.
  gui.f13 := frame(gui.f1, relief='ridge', expand='x')
  gui.dismiss.bn := button(gui.f13, 'Dismiss')

  tk_release()


  #---------------------------------------------------------------------------
  # Events that we respond to.
  #---------------------------------------------------------------------------

  whenever
    gui.dismiss.bn->press do
      self->unmap()

  whenever
    self->terminate do {
      deactivate wrk.whenevers
      self->done()
      gui := F
    }

  whenever
    self->setparm do {
      if (has_field($value, 'title'))   gui.f1->title($value.title)
      if (has_field($value, 'file'))    parms.file    := $value.file
      if (has_field($value, 'records')) parms.records := $value.records
      if (has_field($value, 'lines'))   parms.lines   := $value.lines
      if (has_field($value, 'height'))  {
        gui.text.tx->height($value.height)
        if (parms.indx) gui.indx.tx->height($value.height)
      }
      if (has_field($value, 'width'))   gui.text.tx->width($value.width)

      update()
    }

  wrk.whenevers := whenever_stmts(self).stmt


  #---------------------------------------------------------------------------
  # Initialization.
  #---------------------------------------------------------------------------
  # Initialize the text viewer.
  update()

  return
}


#==================================================================== validate
# Perform parameter validity checking.
#
# Given:
#    valid    record     This record contains one field for each legitimate
#                        parameter:
#
#                          valid[parm]
#
#                        The parm field is itself a record whose first field
#                        is the primary type of the parameter (the type being
#                        as returned by type_name()):
#
#                          valid[parm][type]
#
#                        Recognized types are:
#
#                          boolean
#                          integer
#                          double
#                          dcomplex
#                          string
#                          record
#
#                        Other fields list acceptable alternative types.
#                        These are cast to the primary type here.  See Note 1
#                        below.
#
#                        The type field is itself a record whose fields
#                        define the validation rules for the parameter value:
#
#                          default:  The primary type of all parameters MUST
#                                    have a default value.  This is used if
#                                    the parameter value is invalid and the
#                                    parameter has not already been set.
#
#                                    If the default value is a vector then its
#                                    length defines the required vector length
#                                    of the parameter unless varlen (c.f.) is
#                                    specified; if the length is zero then
#                                    varlen == 0 is implied unless overridden
#                                    explicitly by varlen.
#
#                           varlen:  If this integer-valued field is present
#                                    for the primary type it indicates that
#                                    the parameter is a variable-length
#                                    vector.  Its absolute value specifies the
#                                    maximum allowed length; if zero there is
#                                    no limit on the length.  If zero or
#                                    negative, repeated values will be culled.
#
#                            valid:  An EXHAUSTIVE list of valid values.  For
#                                    string-type, if the case-sensitive match
#                                    fails a case-insensitive match will be
#                                    applied.  If this also fails, then case-
#                                    sensitive and case-insensitive minimum-
#                                    match will be applied.  These alternative
#                                    tests must match exactly one of the valid
#                                    values.
#
#                                    Also for string-type this may be a
#                                    regular expression that a valid string
#                                    must match (leading and trailing
#                                    whitespace having already been removed).
#
#                        If valid is not specified, then
#
#                          invalid:  An INEXHAUSTIVE list of invalid values.
#                                    May be specified as a regular expression
#                                    for string type.
#
#                          allowed:  Allows specific exceptions to the
#                                    minimum, maximum, exclmin, and exclmax
#                                    rules to be defined.  For example, a
#                                    range of values 0.5 to 1.5 might be
#                                    specified, but 0.0 also allowed.
#
#                          minimum:  For integer and double types, the minimum
#                                    acceptable value.  For dcomplex types,
#                                    the minimum acceptable amplitude.
#
#                          maximum:  For integer and double types, the maximum
#                                    acceptable value.  For dcomplex types,
#                                    the maximum acceptable amplitude.
#
#                          exclmin:  For integer and double types, the value
#                                    that the parameter must exceed.  For
#                                    dcomplex types, the amplitude that the
#                                    parameter must exceed.
#
#                          exclmax:  For integer and double types, the value
#                                    that the parameter must NOT exceed.  For
#                                    dcomplex types, the amplitude that the
#                                    parameter must NOT exceed.
#
#                        If the primary type is double, then
#
#                          sexages:  Presence of this field indicates that the
#                                    value may be represented as a string in
#                                    sexagesimal format.  If its value is
#
#                                      'angle': then only angle types (d'")
#                                               are allowed,
#
#                                       'time': then only times (hms) are
#                                               allowed,
#
#                                    Otherwise either type is allowed.
#
#                        If the primary type is string then alternative types
#                        may be specified containing
#
#                           format:  Defines an sprintf() format for
#                                    conversion of integer and double types to
#                                    the required string type.  Otherwise the
#                                    as_string() function is used.
#
#    parms    record     The parameter record will be used to set values:
#
#                          1) Where a value supplied was invalid.
#
#                          2) To fill unspecified elements of a vector value,
#                             overriding the default value.
#
#                        parms itself is not modified.
#
#    value    record     Record of parameter values to be validated, its
#                        fields correspond to parameter names.
#
#    dogui    boolean    If true, warnings relating to invalid parameter
#                        assignment will appear in a pop-up window, otherwise
#                        they are written to stdout.
#
# Function return value:
#             record     The validated value record.
#
# Notes:
#   1) Validation of vectors is done on an element-by-element basis using the
#      rules described above for validating the vector length.
#
#   2) The full list of valid conversions are as follows.
#
#      Implicit conversions are done immediately - validity checking is done
#      against the primary type:
#
#      Explicit conversions are deferred, validity checking is done against
#      the alternate type.
#
#      Primary      Alternate
#      -------      ---------
#      boolean  <-   string    ...Implicit: a string of the form 'T' or 'F' is
#                                           implicitly converted.
#
#      integer  <-   float     ...Implicit: float and double values are
#      integer  <-   double                 implicitly converted to integer if
#                                           there is no resulting truncation,
#                                           e.g. 1.0 would be converted to 1
#                                           but 1.1 would not since the value
#                                           would be truncated.
#
#      integer  <-   string    ...Implicit: a string value of '1' would be
#                                           implicitly converted to integer
#                                           and checked against the integer
#                                           validation rules.  However, a
#                                           string value of 'one' would not
#                                           be converted and would be invalid
#                                           since explicit conversion from
#                                           string to integer is not currently
#                                           supported.  A string value of '-0'
#                                           is converted to integer zero with
#                                           'sign' attribute set to -1.
#
#      double   <-   integer   ...Implicit: always safe.
#
#      double   <-   string    ...Implicit: for example, '3.1415' would be
#                                           converted implicitly to 3.1415.
#
#                                           Conversion to double from a string
#                                           in sexagesimal format is implicit
#                                           if the 'sexages' field is
#                                           specified.
#
#                                           Further information about the
#                                           value is returned via the 'format'
#                                           attribute which may be either
#                                           string-, or record-valued.
#
#                                           A string-valued format contains an
#                                           sprintf() format string which may
#                                           be used to reconstruct the string
#                                           to the appropriate decimal
#                                           precision.
#
#                                           Record-valued formats imply
#                                           sexagesimal conversion:
#
#                                           The format.type records whether
#                                           the value is an 'angle' or 'time'.
#                                           Otherwise it is set to 'void'.
#
#                                           The number of decimal digits given
#                                           in the string is returned via
#                                           format.precision.  This allows the
#                                           double value to be recast to
#                                           string (e.g. for display) without
#                                           loss of decimal precision.
#
#      dcomplex <-   integer   ...Implicit: always safe.
#
#      dcomplex <-   integer   ...Implicit: always safe.
#
#      dcomplex <-   float     ...Implicit: always safe.
#
#      dcomplex <-   double    ...Implicit: always safe.
#
#      dcomplex <-   complex   ...Implicit: always safe.
#
#      string   <-   boolean   ...Explicit: boolean type must be declared as
#                                           an alternate.  [T,F] are converted
#                                           to "T F" using as_string().
#
#      string   <-   integer   ...Explicit: integer type must be declared as
#                                           an alternate.  An sprintf() format
#                                           may be specified, otherwise
#                                           as_string() is used.
#
#      string   <-   double    ...Explicit: double type must be declared as
#                                           an alternate.  An sprintf() format
#                                           may be specified, otherwise
#                                           as_string() is used.
#
#-----------------------------------------------------------------------------

const validate := function(valid, parms, value, dogui=F)
{
  rec := [=]

  # Regular expressions used for parsing string-encoded angles and times.
  # Convert degree symbol to 'd'.
  eval(spaste('rxo := s|', sprintf('%c', 176), '|d|'))

  # Generic decimal value.
  rxdg := m|^([+-]?\d*)?(\.\d*)?$|

  # Decimal encoded time.
  rxdt := m|^([+-])?(\d*)?(h)?(\.\d*)?(h)?$|

  # Decimal encoded angle.
  rxda := m|^([+-])?(\d*)?(d)?(\.\d*)?(d)?$|

  # Generic sexagesimal.
  rxsg := m|^([+-])?(\d+)([: ]) *((\d{1,2})[: ] *((\d{1,2})(\.\d*)?)?)? *$|

  # Sexagesimal encoded time.
  rxst := m|^([+-])?((\d+)[h: ])? *((\d{1,2})[m: ])? *((\d{1,2})s?(\.\d*)?s?)? *$|

  # Sexagesimal encoded angle.
  rxsa := m|^([+-])?((\d+)[d: ])? *((\d{1,2})['m: ])? *((\d{1,2})["s]?(\.\d*)?["s]?)? *$|


  pnames := field_names(valid)

  for (parm in field_names(value)) {
    # Check that it's a legitimate parameter.
    if (all(parm != pnames)) {
      # Try a case-insensitive match.
      match := [to_lower(parm) == to_lower(pnames)]
      if (!any(match)) {
        print 'Ignored attempt to set unrecognized parameter:', parm
        continue
      }

      parm := pnames[match]
    }

    types := field_names(valid[parm])

    # The primary parameter type is the first listed.
    type1 := types[1]

    # Check that it has a default value.
    if (!has_field(valid[parm][type1], 'default')) {
      print spaste('Internal error: valid.', parm, '.', type1,
                   ' has no default value.')
      continue
    }

    if (is_record(value[parm])) {
      vps := [=]
      vps[1] := value[parm]
    } else {
      vps := value[parm]
    }

    errmsg := ''

    # Get vector lengths.
    l1 := len(vps)

    varlen := has_field(valid[parm][type1], 'varlen')
    unique := F
    if (varlen) {
      l2 := valid[parm][type1].varlen
      if (l2 < 0) {
        l2 := -l2
        unique := T
      }
    } else {
      l2 := len(valid[parm][type1].default)
    }

    if (l2 == 0) {
      # The default value is a zero-length vector, or varlen is zero.
      l2 := l1
      varlen := T
      unique := T
    }

    # Check the vector length of the parameter value given.
    recparm := []
    ok := F
    if (l1 == 0) {
      if (varlen) {
        recparm := valid[parm][type1].default
        ok := T
      }
    } else if (l1 > l2) {
      # The parameter value has too many elements, kill it.
      vps := []
    }


    for (vp in vps) {
      ok := F

      for (type in types) {
        if (type == 'boolean') {
          if (is_boolean(vp)) {
            wp := vp

          } else if (is_string(vp)) {
            # Allow string representation of a boolean.
            if (len(vp)) {
              # Strip off leading and trailing whitespace.
              wp := vp ~ s|^\s*(.*?)\s*$|$1|
            } else {
              wp := vp
            }

            if (wp == 'T') {
              wp := T
            } else if (wp == 'F') {
              wp := F
            } else {
              continue
            }

          } else {
            continue
          }

          # Cast value.
          if (type1 == 'boolean') vp := wp

          if (type1 == 'string') {
            # Cast to string.
            wp := as_string(wp)
          }

          ok := T
          break

        } else if (type == 'integer') {
          if (is_integer(vp)) {
            wp := vp

          } else if (is_double(vp) || is_float(vp)) {
            wp := as_integer(vp)
            if (wp != vp) continue

          } else if (is_string(vp)) {
            # Allow string representation of an integer, as from an entry box.
            if (len(vp)) {
              # Strip off leading and trailing whitespace, and leading zeros.
              wp := vp ~ s|^\s*(.*?)\s*$|$1| ~ s|^([+-]??)0+(\d)|$1$2| ~ s|^\+||

              # Allow some additional flexibility.
              wp := wp ~ s|^\+|| ~ s|\.0*$||
            } else {
              wp := vp
            }

            if (wp == '-0') {
              # Handle negative zero via an attribute.
              wp := 0
              wp::sign := -1

            } else if (wp == as_string(as_integer(wp))) {
              wp := as_integer(wp)

            } else {
              continue
            }

          } else {
            continue
          }

          # Cast value.
          if (type1 == 'integer') vp := wp

          if (has_field(valid[parm][type], 'allowed')) {
            xp := wp[wp != valid[parm][type].allowed]
          } else {
            xp := wp
          }

          if (has_field(valid[parm][type], 'minimum')) {
            if (any(xp < valid[parm][type].minimum)) {
              errmsg := spaste(' (< ', valid[parm][type].minimum, ')')
              continue
            }
          }

          if (has_field(valid[parm][type], 'exclmin')) {
            if (any(xp <= valid[parm][type].exclmin)) {
              errmsg := spaste(' (<= ', valid[parm][type].exclmin, ')')
              continue
            }
          }

          if (has_field(valid[parm][type], 'maximum')) {
            if (any(xp > valid[parm][type].maximum)) {
              errmsg := spaste(' (> ', valid[parm][type].maximum, ')')
              continue
            }
          }

          if (has_field(valid[parm][type], 'exclmax')) {
            if (any(xp >= valid[parm][type].exclmax)) {
              errmsg := spaste(' (>= ', valid[parm][type].exclmax, ')')
              continue
            }
          }

          if (type1 == 'string') {
            # Cast to string.
            if (has_field(valid[parm].integer, 'format')) {
              wp := sprintf(valid[parm].integer.format, wp)
            } else {
              wp := as_string(wp)
            }
          }

          ok := T
          break

        } else if (type == 'double') {
          if (is_double(vp)) {
            wp := vp

          } else if (is_float(vp)) {
            # Float representation of a double is always safe.
            wp := as_double(vp)

          } else if (is_integer(vp)) {
            # Integer representation of a double is always safe.
            wp := as_double(vp)

          } else if (is_string(vp)) {
            # Allow string representation of a double, as from an entry box.
            if (len(vp)) {
              # Strip off leading and trailing whitespace.
              wp := vp ~ s|^\s*(.*?)\s*$|$1|
            } else {
              wp := vp
            }

            if (has_field(valid[parm][type], 'sexages')) {
              # Translate degree symbol (to_lower can't handle it).
              wp := to_lower(wp ~ rxo)

              # Allow angle or time or both?
              sx  := valid[parm][type].sexages
              sxa := T
              sxt := T
              if (is_string(sx)) {
                if (sx == 'angle') {
                  sxt := F
                } else if (sx == 'time') {
                  sxa := F
                }
              }

              if (wp ~ rxdg) {
                # Generic decimal value.
                wp := as_double(wp)

                # Record auxiliary information as attributes.
                if (!sxt) {
                  wp::format.type := 'angle'
                } else if (!sxa) {
                  wp::format.type := 'time'
                } else {
                  wp::format.type := 'void'
                }
                wp::format.precision := max(0, strlen($m[2]) - 1)

              } else if (sxt && wp ~ rxdt) {
                # Degenerate sexagesimal time.
                wp := as_double($m[2]) + as_double($m[4])
                if ($m[1] == '-') wp := -wp

                wp::format := [type = 'time',
                               precision = max(0, strlen($m[4]) - 4)]

              } else if (sxa && wp ~ rxda) {
                # Degenerate sexagesimal angle.
                wp := as_double($m[2]) + as_double($m[4])
                if ($m[1] == '-') wp := -wp

                wp::format := [type = 'angle',
                               precision = max(0, strlen($m[4]) - 4)]

              } else {
                # Add terminating blank for regexps of incomplete sexagesimals.
                wp := spaste(wp, ' ')

                if (wp ~ rxsg) {
                  # Generic sexagesimal value.
                  sx := as_double([$m[2], $m[5], $m[7], $m[8]])
                  wp := sx[1] + (sx[2] + (sx[3] + sx[4])/60.0)/60.0
                  if ($m[1] == '-') wp := -wp

                  # Record auxiliary information as attributes.
                  if (!sxt) {
                    wp::format.type := 'angle'
                  } else if (!sxa) {
                    wp::format.type := 'time'
                  } else {
                    wp::format.type := 'void'
                  }
                  wp::format.precision := max(0, strlen($m[8]) - 1)

                } else if (sxt && wp ~ rxst) {
                  # Sexagesimal time.
                  sx := as_double([$m[3], $m[5], $m[7], $m[8]])
                  wp := sx[1] + (sx[2] + (sx[3] + sx[4])/60.0)/60.0
                  if ($m[1] == '-') wp := -wp

                  # Record auxiliary information as attributes.
                  wp::format := [type = 'time',
                                 precision = max(0, strlen($m[8]) - 1)]

                } else if (sxa && wp ~ rxsa) {
                  # Sexagesimal angle.
                  sx := as_double([$m[3], $m[5], $m[7], $m[8]])
                  wp := sx[1] + (sx[2] + (sx[3] + sx[4])/60.0)/60.0
                  if ($m[1] == '-') wp := -wp

                  # Record auxiliary information as attributes.
                  wp::format := [type = 'angle',
                                 precision = max(0, strlen($m[8]) - 1)]

                } else {
                  continue
                }
              }

            } else if (num := (wp ~ m|^[+-]??\d*(\.\d*)??(e[+-]??\d+)??$|i)) {
              wp := as_double(wp)

              # Record auxiliary information as attributes.
              wp::format := array('%f', len(wp))
              for (j in 1:len(wp)) {
                if (num[j]) {
                  wp::format[j] := spaste('%.', max(0, strlen($m[j])-1), 'f')
                }
              }

            } else {
              continue
            }

          } else {
            continue
          }

          # Cast value.
          if (type1 == 'double') vp := wp

          if (has_field(valid[parm][type], 'allowed')) {
            xp := wp[wp != valid[parm][type].allowed]
          } else {
            xp := wp
          }

          if (has_field(valid[parm][type], 'minimum')) {
            if (any(xp < valid[parm][type].minimum)) {
              errmsg := spaste(' (< ', valid[parm][type].minimum, ')')
              continue
            }
          }

          if (has_field(valid[parm][type], 'exclmin')) {
            if (any(xp <= valid[parm][type].exclmin)) {
              errmsg := spaste(' (<= ', valid[parm][type].exclmin, ')')
              continue
            }
          }

          if (has_field(valid[parm][type], 'maximum')) {
            if (any(xp > valid[parm][type].maximum)) {
              errmsg := spaste(' (> ', valid[parm][type].maximum, ')')
              continue
            }
          }

          if (has_field(valid[parm][type], 'exclmax')) {
            if (any(xp >= valid[parm][type].exclmax)) {
              errmsg := spaste(' (>= ', valid[parm][type].exclmax, ')')
              continue
            }
          }

          if (type1 == 'string') {
            # Cast to string.
            if (has_field(valid[parm].integer, 'format')) {
              wp := sprintf(valid[parm].integer.format, wp)
            } else {
              wp := as_string(wp)
            }
          }

          ok := T
          break

        } else if (type == 'dcomplex') {
          if (is_dcomplex(vp)) {
            wp := vp

          } else if (is_complex(vp)) {
            # Complex representation of a dcomplex is always safe.
            wp := as_dcomplex(vp)

          } else if (is_double(vp)) {
            # Double representation of a dcomplex is always safe.
            wp := as_dcomplex(vp)

          } else if (is_float(vp)) {
            # Float representation of a dcomplex is always safe.
            wp := as_dcomplex(vp)

          } else if (is_integer(vp)) {
            # Integer representation of a dcomplex is always safe.
            wp := as_dcomplex(vp)

          } else {
            continue
          }

          # Cast value.
          if (type1 == 'dcomplex') vp := wp

          if (has_field(valid[parm][type], 'allowed')) {
            xp := abs(wp[wp != valid[parm][type].allowed])
          } else {
            xp := abs(wp)
          }

          if (has_field(valid[parm][type], 'minimum')) {
            if (any(xp < valid[parm][type].minimum)) {
              errmsg := spaste(' (amplitude < ', valid[parm][type].minimum,')')
              continue
            }
          }

          if (has_field(valid[parm][type], 'exclmin')) {
            if (any(xp <= valid[parm][type].exclmin)) {
              errmsg := spaste(' (amplitude <= ', valid[parm][type].exclmin,')')
              continue
            }
          }

          if (has_field(valid[parm][type], 'maximum')) {
            if (any(xp > valid[parm][type].maximum)) {
              errmsg := spaste(' (amplitude > ', valid[parm][type].maximum,')')
              continue
            }
          }

          if (has_field(valid[parm][type], 'exclmax')) {
            if (any(xp >= valid[parm][type].exclmax)) {
              errmsg := spaste(' (amplitude >= ', valid[parm][type].exclmax,')')
              continue
            }
          }

          ok := T
          break

        } else if (type == 'string') {
          if (!is_string(vp)) continue

          # Strip off leading and trailing whitespace.
          if (len(vp)) {
            wp := vp ~ s|^\s*(.*?)\s*$|$1|
          } else {
            wp := vp
          }

          if (has_field(valid[parm][type], 'valid')) {
            if (is_regex(valid[parm][type].valid)) {
              # We have a regular expression to match.
              if (!(wp ~ valid[parm][type].valid)) continue

            } else {
              # We have an exhaustive list of valid string values.
              if (all(wp != valid[parm][type].valid)) {
                # Try a case-insensitive match.
                match := to_lower(wp) == to_lower(valid[parm][type].valid)

                if (sum(match) != 1) {
                  # Try a case-sensitive minimum-match.
                  eval(spaste('regex := m|^', wp, '|'))
                  match := valid[parm][type].valid ~ regex

                  if (sum(match) != 1) {
                    # Try a case-insensitive minimum-match.
                    eval(spaste('regex := m|^', to_lower(wp), '|'))
                    match := to_lower(valid[parm][type].valid) ~ regex

                    if (sum(match) != 1) {
                      # Give up.
                      continue
                    }
                  }
                }

                wp := valid[parm][type].valid[match]
              }
            }
          }

          if (has_field(valid[parm][type], 'invalid')) {
            if (is_regex(valid[parm][type].invalid)) {
              # We have a regular expression to match.
              if (wp ~ valid[parm][type].invalid) continue

            } else {
              # We have an inexhaustive list of invalid string values.
              if (any(wp == valid[parm][type].invalid)) continue
            }
          }

          ok := T
          break

        } else if (type == 'record') {
          # The value must at least be a record.
          if (is_record(vp)) {
            wp := vp
            ok := T
          }

          break
        }
      }

      # Add this vector element?
      if (ok) {
        if (len(recparm) == 0) {
          recparm := wp
        } else {
          if (unique && any(recparm == wp)) continue
          recparm := [recparm, wp]
        }
      } else {
        recparm := []
        break
      }
    }


    if (ok) {
      rec[parm] := recparm

      if (!is_record(recparm)) {
        # Check vector length.
        l1 := len(recparm)

        if (l1 < l2 && !varlen) {
          # Pad vector appropriately.
          if (has_field(parms, parm)) {
            rec[parm] := [rec[parm], parms[parm][(l1+1):l2]]
          } else {
            rec[parm] := [rec[parm], valid[parm][type1].default[(l1+1):l2]]
          }
        }
      }

    } else {
      # Fallback behaviour.
      text := spaste('Invalid parameter assignment', errmsg, ':\n',
                     '   ignored [', parm, ' = ', value[parm], '] (',
                     type_name(value[parm]), ' type)\n')

      if (has_field(parms, parm) && !is_fail(parms[parm])) {
        rec[parm] := parms[parm]
        text := spaste(text, '   remains [', parm, ' = ', parms[parm], '] (',
                       type_name(parms[parm]), ' type)')

      } else {
        rec[parm] := valid[parm][type1].default
        text := spaste(text, '   default [', parm, ' = ', rec[parm], '] (',
                       type_name(rec[parm]), ' type)')
      }

      if (dogui) {
        w := warning(text)
      } else {
        print text
      }
    }

    # Reattach attributes.
    if (has_field(rec, parm) && len(value[parm]::)) {
      # Don't propagate the [state=T] attribute returned with button presses.
      if (len(value[parm]::) > 1 || !has_field(value[parm]::, 'state')) {
        for (attrib in field_names(value[parm]::)) {
          if (attrib != 'state') rec[parm]::[attrib] := value[parm]::[attrib]
        }
      }
    }
  }

  return rec
}



#===================================================================== warning
# Utility to display a small warning message using a glish/tk window.
#
# Arguments:
#    text       string   The warning message (no default).
#    colour     string   Background colour.
#    title      string   Window frame label.
#
# Received events:
#    text(string)        Change warning text.
#    raise()             Raise window to the top of the stack.
#    terminate()         Close down.
#
# Sent events:
#    done()              Viewer has exited.
#
#-----------------------------------------------------------------------------

const warning := subsequence(text,
                             colour='#ff9933',
                             title='WARNING') : [reflect=T]
{
  gui := [=]

  # Build warning viewer window.
  tk_hold()
  gui.f1 := frame(title=title)

  gui.f11   := frame(gui.f1, borderwidth=4, relief='ridge')
  gui.f111  := frame(gui.f11, padx=30, pady=15, background=colour)
  gui.f1111 := frame(gui.f111, borderwidth=0, background=colour,
                     expand='none')
  gui.warning.la := label(gui.f1111, text, font=fonts.Vb14, justify='center',
                          relief='flat', background=colour)

  # Dismiss button.
  gui.dismiss.bn := button(gui.f111, 'Dismiss', background=colour)

  whenever
    gui.dismiss.bn->press,
    self->terminate do {
      gui := F
      self->done()
    }

  whenever
    self->text do {
      gui.warning.la->text($value)
      gui.f1->raise()
    }

  whenever
    self->raise do
      gui.f1->raise()

  tk_release()
}
