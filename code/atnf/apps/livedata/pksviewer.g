#-----------------------------------------------------------------------------
# pksviewer.g: Livedata interface to the scrolling aips++ viewer.
#-----------------------------------------------------------------------------
# Copyright (C) 2005
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
# $Id: pksviewer.g,v 1.1 2005/07/18 07:13:33 mcalabre Exp $
#-----------------------------------------------------------------------------
# Livedata interface to the scrolling aips++ viewer.
#
# Arguments:
#    ID                int      Display number.
#    title             string   Frame title on the aips++ viewer.
#
# Received events:
#    scrollBufBegin(record)
#                        Initialize the scroll buffer.
#    scrollBufAddImage(record)
#                        Add another row to the scroll buffer.
#    map()               Make display panel visible at the top of the window
#                        stack; no effect if it was not previously unmap'd.
#    unmap()             Make display panel invisible.
#    terminate()         Close down.
#
# Sent events:
#    imageID(int)        Scroll buffer initializedi; returns ID argument.
#    done()              Agent has terminated.
#
# Original (scroll-viewer.g): 2004/06/11, Roman Fieler (FARADAY project).
#=============================================================================

pragma include once

include 'pkslib.g'
include 'ddlws.g'
include 'viewer.g'

pksviewer := subsequence(ID    = 1,
                         title = '')
{
  # Our identity.
  self.name := 'pksviewer'

  # Parameter values.
  parms := [=]

  valid := [
    ID    = [integer = [default = 1,
                        valid   = 1:2]],
    title = [string  = [default = '']]]

  # Work variables.
  wrk := [=]

  #---------------------------------------------------------------------------
  # Local function definitions.
  #---------------------------------------------------------------------------
  local setparm

  #----------------------------------------------------------------- self.done

  const self.done := function()

  {
    wider wrk, self

    deactivate wrk.whenevers
    self->done()
    wrk  := F
    self := F
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
      # Update the parameter value.
      parms[item] := value[item]

      rec := [=]
      rec[item] := parms[item]
    }
  }

  #---------------------------------------------------------------------------
  # Events that we respond to.
  #---------------------------------------------------------------------------

  whenever
    self->scrollBufBegin do {
      self->imageID(parms.ID)
      wrk.display.data.setoptions([init = [value = $value]])
    }

  whenever
    self->scrollBufAddImage do
      wrk.display.data.setoptions([update = [value = $value]])

  whenever
    self->map do
      wrk.display.panel.gui()

  whenever
    self->unmap do
      wrk.display.panel.dismiss()

  whenever
    self->terminate do
      self.done()

  wrk.whenevers := whenever_stmts(self).stmt

  #---------------------------------------------------------------------------
  # Initialize.
  #---------------------------------------------------------------------------

  # Set parameters.
  setparm([ID    = ID,
           title = title])

  # aips++ viewer setup.
  wrk.display.panel := defaultviewer.newdisplaypanel(
                         maptype='index', newcmap=T,
                         guihasmenubar=[file=T, tools=F, displaydata=F])
  wrk.display.panel.setoptions([bottommarginspacepg=9, leftmarginspacepg=10])

  wrk.display.data := defaultviewer.loaddata(unset, 'pksmultibeam')
  wrk.display.panel.register(wrk.display.data)

  wrk.display.axes := defaultviewer.loaddata(unset, 'worldaxes')
  wrk.display.axes.setoptions([titletext = parms.title])
  wrk.display.panel.register(wrk.display.axes)
}
