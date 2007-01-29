# qt_if_display.g: script to test qt_if_display client
#
#   Copyright (C) 1996,1997,1998,2001
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

pragma include once

###############
# Check whether DISPLAY is defined.
if (!has_field(environ, 'DISPLAY'))
 {
   print 'DISPLAY environment variable is not set, bailing out!'
   exit
}
 else
 {
   print 'Using DISPLAY', environ.DISPLAY
}


# Qt-based display client
  widgets_c := client("./qt_if_display")
  await widgets_c->qt_initialized

# display control parameters
  info := [=]
  info.dcm_selector := 5
  info.exhaust_selector := 1
  info.ifdata_type := [1,1,1,1]
  widgets_c->rtd_if_req(info)
 	
  whenever widgets_c->exit do		 
	exit
  
  timer_c := client("timer",0.05)
 
  k := 1
  whenever timer_c->ready do
	{
  	info := [=]
	#Check if first time plot is defined
	 
	  for (n in 1: 32)  
	  {		
	    j:= 1+ (random()/327680000)
  	    rtd_spectrum[n] := j
  	  }
	  for (n in 1: 32)  
	  {		
	    j:= 1+ (random()/327680000)
  	    rtd_spect1[n] := j
  	  }
	  for (n in 1: 32)  
	  {		
	    j:= 1+ (random()/327680000)
  	    rtd_spect2[n] := j
  	  }
	  j:= 1+ (random()/327680000)
          rtd_spec3[1] := j
          rtd_spec3[2] := j+1
	  info.SEQ_NUM := k
	  info.DCM_TP_IN := rtd_spectrum
	  info.DCM_TP_OUT := rtd_spect1
	  info.DCM_TEMP := rtd_spect2
	  info.INLET_TEMP := rtd_spec3
	  info.EXHAUST_TEMP := rtd_spec3
	  widgets_c->synctask_ifdata(info)
	  k := k + 1
	}
