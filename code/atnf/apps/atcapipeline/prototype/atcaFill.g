#-----------------------------------------------------------------------------
# atcaFill.g: Filling/Loading class for the ATCA pipeline
#-----------------------------------------------------------------------------
# Copyright (C) 1996-2004
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
# $Id:
#-----------------------------------------------------------------------------
#

pragma include once

include 'ms.g'
include 'misc.g'
include 'quanta.g'
include 'table.g'
include 'atcafiller.g'
include 'configFiller.g'

atcafill := subsequence(config){

  its := [=]

  const its.make_filler := function(config){
    wider its

    c := config.get_vars()
    fnames := dms.tovector(c.rpfitsnames.val, 'string')
    msname := config.get_msname()

    its.fill := atcafiller(msname, fnames, options=c.options.val, shadow=c.shadow.val)
    if(is_fail(its.fill)) return fatal(PARMERR, 'Error starting filler', its.fill::)

    fprintf(config.get_pidfile(), '%d atcafiller\n', its.fill.id().pid)
    return T
  }

  const its.getpids := function(config){
    # get the process IDs of all the default servers started
    servers := ['drc', 'dq', 'dm']
    for(s in servers){
      if(is_record(eval(s))){
        pid := eval(s).id().pid
        fprintf(config.get_pidfile(), '%d %s\n', pid, s)
      }
    }
    return T
  }

  const its.check_filled := function(config){
    c := config.get_vars()

    t := table(c.msname.val)
    if(is_fail(t)) return fatal(IOERR, 'Error opening measurement set', t::)

    nrows := t.nrows()
    t.done()
    if(nrows == 0)
      note('WARNING: no data has been filled')
    return T
  }

  const its.select := function(config){
    c := config.get_vars()

    fields := dms.tovector(c.fields.val, 'string')
    freqchain := as_integer(c.freqchain.val)
    highfreq := dq.convert(c.highfreq.val, 'GHz').value
    lowfreq := dq.convert(c.lowfreq.val, 'GHz').value
    bandwidth := dq.convert(c.bandwidth.val, 'MHz').value

    ok := its.fill.select(firstscan=c.firstscan.val, lastscan=c.lastscan.val, 
                   freqchain=freqchain, lowfreq=lowfreq, highfreq=highfreq, 
                   fields=fields, bandwidth1=bandwidth, numchan1=c.numchan1.val)
    if(is_fail(ok)) return fatal(PARMERR, 'Error selecting data for filling', ok::)
    return T
  }


  const self.fill := function(config){
    # Run filling process

    ok := its.select(config)
    if(is_fail(ok)) return fatal(PARMERR, 'Error selecting data for filling', ok::)

    ok := its.fill.fill()
    if(is_fail(ok)) return fatal(PARMERR, 'Error filling measurement set', ok::)

    return T
  }

  const self.done := function(config){
    ok := its.getpids(config)
    if(is_fail(ok)) return fatal(PARMERR, 'Error getting server pids', ok::)

    ok := its.fill.done()
    if(is_fail(ok)) return fatal(PARMERR, 'Error closing atcafiller object', ok::)

    ok := its.check_filled(config)
    if(is_fail(ok)) 
      return fatal(PARMERR, 'Error checking if data has been filled', ok::)
    return T
  }


# Constructor
  ok := its.make_filler(config)
  if(is_fail(ok)) return fatal(PARMERR, 'Error initialising atcafiller', ok::)
}
