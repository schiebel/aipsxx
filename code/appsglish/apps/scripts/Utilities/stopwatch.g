# stopwatch: stopwatch functions for glish
# Copyright (C) 1997,1999
# Associated Universities, Inc. Washington DC, USA.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
# License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation,
# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: stopwatch.g,v 19.2 2004/08/25 02:10:13 cvsmgr Exp $

pragma include once
 
#
# tim := stopwatch()	# timer is created running and zeroed
#
# tim.start()		# timer returns mutable values
# tim.stop()		# timer returns fixed values
# tim.reset()		# zeros time w/o state change
# tim.zero()		# stop followed by reset
# tim.state() 		# returns 'RUNNING' or 'STOPPED'
# tim.value()		# return current value in seconds
# tim.fmtvalue()	# return string formatted value, with units
# tim.show()		# print state and value of timer
# tim.timefunc(f)	# time function f.  Should take no parameters.
#			# can be used as tim.timefunc(function () {foo(5)})
#

stopwatch := function() {

  public := [=]
  private := [=]

  private.state := 'INVALID'
  private.starttime := 0
  private.stoptime := 0

  public.ok := function () { return T; }
  public.delete := function () {
    wider public
    val public := F
  }

  public.help := function () {
    print 'Stopwatch style timing.  Available member functions:'
    print ''
    print 'tim := stopwatch()  # timer is created running and zeroed'
    print ''
    print 'tim.start()       # timer returns mutable values'
    print 'tim.stop()        # timer returns fixed values'
    print 'tim.reset()       # zeros time w/o state change'
    print 'tim.zero()        # stop followed by reset'
    print 'tim.state()       # returns \'RUNNING\' or \'STOPPED\''
    print 'tim.value()       # return current value in seconds'
    print 'tim.fmtvalue(v)   # return string formatted value, with units'
    print 'tim.show()        # print state and value of timer'
    print 'tim.timefunc(func,niter,label)'
    print '                  # time function f.  Should take no parameters'
    print 'tim.delete()      # destroy the object'
    print ''
    print 'Most functions take an optional quiet argument to suppress informational'
    print 'messages.  Notice that tim.timefunc(function () {foo(5)}) is a valid call'
    print 'if you wish to avoid defining a new function to provide arguments.  After'
    print 'timing a function, the numerical interval can be retrieved with tim.value()'
  }

  public.start := function (quiet=F) {
    wider private;
    if (private.state == 'RUNNING') {
      if (!quiet) print 'timer is already running'
      if (!quiet) print spaste('current value is ',public.fmtvalue())
      return
    } else if (private.state == 'STOPPED') {
      if (private.starttime != private.stoptime) {
        #adjust start time so that is appears to have running continuously
        if (!quiet) print spaste('timer restarted from ',public.fmtvalue())
        private.starttime := time() - (private.stoptime - private.starttime)
      } else {
        if (!quiet) print 'timer started from zero'
      }
    } else {
      print spaste('Unrecognized value of state: ',private.state)
    }
    private.state := 'RUNNING'
  }

  public.stop := function (quiet=F) {
    wider private;
    if (private.state == 'RUNNING') {
      private.stoptime := time()
      private.state := 'STOPPED'
      if (!quiet) print spaste('timer stopped at ',public.fmtvalue())
    } else if (private.state == 'STOPPED') {
      if (!quiet) print 'timer is already stopped'
      if (!quiet) print spaste('current value is ',public.fmtvalue())
    } else {
      print spaste('Unrecognized value of state: ',private.state)
    }
  }

  public.reset := function (quiet=F) {
    wider private
    private.starttime := time()
    private.stoptime := private.starttime
    if (!quiet) print 'timer reset to zero'
  }

  public.zero := function (quiet=F) {
    public.stop(quiet)
    public.reset(quiet)
    if (!quiet) print 'timer stopped and zeroed'    
  }

  public.state := function () {
    wider private;
    return private.state;
  }

  public.value := function () {
    wider private
    if (private.state == 'RUNNING') {
      return time() - private.starttime
    } else if (private.state == 'STOPPED') {
      return private.stoptime - private.starttime
    } else
      fail 'Unrecognized value of state'
  }
  
  public.fmtvalue := function (value=-1) {
    local y, d, h, m, s, v
    if (value < 0) {
      s := public.value()
    } else {
      s := value
    }

    m := as_integer(s/60.0)
    s := s - m * 60.0

    h := as_integer(m/60.0)
    m := m - h * 60.0

    d := as_integer(h/24.0)
    h := h - d * 24.0

    # include a rough approximation for leap years.
    y := as_integer(d/365.25)
    d := as_integer(d - y * 365)

    if (y > 0) {
      v := spaste(y,'y ')
    } else {
      v := ''
    }
    
    if ((d > 0) || (v != '')) v := spaste(v, d,'d ')
    if ((h > 0) || (v != '')) v := spaste(v, h,'h ')
    if ((m > 0) || (v != '')) v := spaste(v, m,'m ')
    v := spaste(v, sprintf('%.2f',s),'s')

    return v
  }

  public.show := function () {
    wider private
    print spaste('timer is ',public.state(),', value is ',public.fmtvalue())
  }

  # value can be retrieved later via public.value() if needed.
  # function may be specified by a string name, or a function value
  public.timefunc := function (f, niter=1, name='', quiet=F) {
    wider private
    local i, v, t, name, name1
    if (niter <= 0) fail 'niter must be greater than 0'
    if ((name == '') && (is_string(f))) name := f
    if (is_string(f)) f := eval(f)
    if (!is_function(f)) fail 'f must be a function'

    name1 := ''
    if (name != '') name1 := spaste(name,' ')
    if (!quiet) {
      if (niter == 1) {
        print spaste('Timing function ',name1,'...')
      } else {
        print spaste('Timing function ',name1, niter,' times...')
      }
    }
    t := 0
    for (i in 1:niter) {
      public.zero(quiet=T)
      public.start(quiet=T)
      v := f()
      public.stop(quiet=T)
      t := t + public.value()
      if (!quiet) print 'return value is', v
      if (!quiet) print spaste('Function ',name1,'took ', public.fmtvalue(),
        ' to run')
    }
    if (niter > 1) {
      print ''
      private.starttime := private.stoptime - t /niter
      if (!quiet) print spaste('Function ',name1,'took an average of ',
        public.fmtvalue(), ' to run, over ', niter, ' iterations')
    }
  }

  # debugging only.  return access to private record
  public.getpriv := function () {
    wider private
    return ref private
  }

  # initial state is running and zeroed
  private.state := 'RUNNING'
  public.reset(quiet=T)

  return ref public

}
