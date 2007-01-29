# tautogui.g: Test use of autogui.g
# Copyright (C) 1996,1997,1998,1999
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
# $Id: tautogui.g,v 19.2 2004/08/25 02:21:17 cvsmgr Exp $

pragma include once;

include 'widgetserver.g';
include 'measures.g';
include 'autogui.g';

const tautogui := function() {

# we will put a "parameter set" into "parameters":
  parameters := [=];
  
# Set up various widgets:
  
# floatrange
# give min, max and resolution: it makes a scale widget
  p_power := [dlformat='power',
	      listname='Scaling power',
	      ptype='floatrange',
	      pmin=-5.0,
	      pmax=5.0,
	      presolution=0.1,
	      default=0.0,
	      value=1.5];
  parameters.power := p_power;
  
# choice
# give a list of options: it makes an optionmenu widget
  p_resample := [dlformat='resample',
		 listname='Resampling mode',
		 allowuset=T,
		 ptype='choice',
		 popt="nearest bilinear",
		 default='nearest',
		 value='nearest'];
  parameters.resample := p_resample;
  
# orderedvector
# give how many numbers, and the range: it makes "n" scale widgets,
# each constrained to have the slider between those above and below it.
  p_range := [dlformat='range',
	      listname='Data range',
	      ptype='orderedvector',
	      plength=2,
	      prange=[-10, 150],
	      default=[15, 85],
	      value=[15, 85]];
  parameters.range := p_range;
  
# boolean
# Only need to give default
  p_switch := [dlformat='switch',
	       listname='Plot contours',
	       ptype='boolean',
	       allowuset=T,
	       default=T,
	       value=F];
  parameters.switch := p_switch;

# vector
# just an entry box at the moment: needs some smarts like the ones
# in regionmanager and others.
  p_levels := [dlformat='levels',
	       listname='Contour levels',
	       ptype='vector',
	       default=[0.2, 0.4, 0.6, 0.8],
	       value=[0.2, 0.4, 0.6, 0.9]];
  parameters.levels := p_levels;
  
# scalar
# just an entry box at the moment - perhaps a scale or "winding entry
# box" in the future.
  p_scale := [dlformat='scale',
	      listname='Contour scale factor',
	      ptype='scalar',
	      default=0.5,
	      value=1.2];
  parameters.scale := p_scale;
  
# intrange
# give min/max: this makes a scale widget with step size 1.
  p_line := [dlformat='line',
	     listname='Line width',
	     ptype='intrange',
	     pmin=0,
	     pmax=6,
	     default=1,
	     value=1];
  parameters.line := p_line;
  
# userchoice
# just like 'choice', but allows extension by user via extendoptionmenu.
  p_color := [dlformat='color',
	      listname='Line color',
	      ptype='userchoice',
	      popt="black white red green blue yellow",
	      default='blue',
	      value='blue'];
  parameters.color := p_color;
  
# now for Axis selection example:
#
# any parameter can have a context field, which if it exists, forces
# the parameter to be put in a roll-up so it can be squirelled away
# for only occasional use.
#
# then there is also dependency_group, which can have any name, in
# this case "axes" and flags which parameters belong to a particular
# group.  Parameters in this group are only emitted if the dependencies
# are met.
#
# then there is dependency_type: exclusive is the only one known at
# the moment to the autogui.
#
# finally, dependency_list is a string list of the other parameters
# (actually their dlformat field values) which, in this case, must
# be exclusive of this value.
  
  p_xaxis := [dlformat='xaxis',
	      listname='X-axis',
	      ptype='choice',
	      popt="R.A. Dec Vel",
	      default='R.A.',
	      value='R.A.',
	      context='Axis_selection',
	      dependency_group='axes',
	      dependency_type='exclusive',
	      dependency_list="yaxis zaxis"];
  parameters.xaxis := p_xaxis;
  
  p_yaxis := [dlformat='yaxis',
	      listname='Y-axis',
	      ptype='choice',
	      popt="R.A. Dec Vel",
	      default='Dec',
	      value='Dec',
	      context='Axis_selection',
	      dependency_group='axes',
	      dependency_type='exclusive',
	      dependency_list="xaxis zaxis"];
  parameters.yaxis := p_yaxis;
  
  p_zaxis := [dlformat='zaxis',
	      listname='Z-axis',
	      ptype='choice',
	      popt="R.A. Dec Vel",
	      default='Vel',
	      value='Vel',
	      context='Axis_selection',
	      dependency_group='axes',
	      dependency_type='exclusive',
	      dependency_list="xaxis yaxis"];
  parameters.zaxis := p_zaxis;
  
  p_filename := [dlformat='file',
		 listname='File name',
		 ptype='file',
		 default=unset,
		 value='myfilename',
		 popt='All'];
  parameters.filename := p_filename;
  
  p_cellsize := [dlformat='quantity',
		 listname='Cell size',
		 ptype='quantity',
		 default=unset,
		 value='0.7arcsec'];
  parameters.cellsize := p_cellsize;
  
  p_imagesize := [dlformat='scalar',
		  listname='Image size',
		  ptype='scalar',
		  default=unset,
		  value=256];
  parameters.imagesize := p_imagesize;
  
  p_direction := [dlformat='measure',
		  listname='Phase Center',
		  ptype='measure',
		  default=unset,
		  value='dm.direction(\'sun\', \'0deg\', \'0deg\')'];
  
  parameters.direction := p_direction;
  
  mygui := autogui(parameters, 'My demonstration autogui', autoapply=F, actionlabel='Apply');
  if(is_fail(mygui)) fail;
  
  whenever mygui->setoptions do {
    print "New options for", field_names($value), "emitted...";
    print $value;
  }
}


tautogui();
  
