# gbtlogviewPlotSpecial.g: define special purpose plotting functions w/buttons
#   Copyright (C) 1995,1996,1997,1999
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
#   $Id: gbtlogviewPlotSpecial.g,v 19.0 2003/07/16 03:42:26 aips2adm Exp $
#-----------------------------------------------------------------------------
# define special purpose plotting functions here, and create gui buttons
# that will run them. 
#
# gbtlogview has the built-in capability to plot any column from a log
# table.  use this file to add plotting functions which require some
# manipulation of the data before plotting
#
# this file is included by 'gbtlogview.g' which defines two global variables:
#    app
#    gui
# and which calls 'addSpecialPlottingButtons' with one argument, 'parentFrame'
# which is the glish/Tk frame widget in which the special plotting buttons
# will appear.
# 
# to add a new button and a new function:
#   1. create a button
#   2. setup a 'whenever' which will be invoked when the button is
#      pressed, and which does the required data extraction (from
#      app.table), data manipulation, and plotting.
#-----------------------------------------------------------------------------
addSpecialPlottingButtons := function (parentFrame)
# <parentFrame> is a Tk frame (an unadorned window used for grouping other
# Tk widgets).  any buttons you add here are arranged top-to-bottom,
# with subsequent buttons added below previous buttons.
{
  global gui;

  plotRelativeHumidityButton :=
      dws.button (parentFrame,
		  text='Relative Humidity',
		  width=gui.standardButtonWidth);

  whenever plotRelativeHumidityButton->press do {
      junk := plotRelativeHumidity ();
  }

}     
#-----------------------------------------------------------------------------
plotRelativeHumidity := function ()
# extract ambient temperature, dewpoint and atmospheric pressure columns
# from the current table (after checking to see that they exist -- error 
# dialogs are posted if they don't).
# then use the standard formula for calculating relative humidity
{
  global app;

  if (!legitimateTable (app.table)) {
    errorDialog ('No current table available');
    return F;
    }

  columnTitles :=  app.table.colnames();

    # assume the worst
  foundAmbientTemperature := F;
  foundDewPoint := F;
  foundPressure := F;
  successfulMatch := F;

    # column titles look like 'Weather1_AMB_TEMP'.  use the built-in
    # glish function 'split', with the optional 2nd argument '_'
    # to create an array of strings from each column title.  then
    # look for the desired substrings in that array
    # specifically, search for  'AMB' + 'TEMP' and then 'DEWP'
  for (i in 1:len (columnTitles)) {
    dividedTitle := split (columnTitles [i], '_');
    if (len (dividedTitle) == 2) { # may have 'Weather1_DEWP'
      if (dividedTitle [2] == 'DEWP') {
        foundDewPoint := T;
        dewPoint := app.table.getcol(columnTitles [i]);
        }# DEWP found
      else if (dividedTitle [2] == 'PRESSURE') {
        foundPressure := T;
        pressure := app.table.getcol(columnTitles [i]);
        }# PRESSURE found
      }# 2 part column title found
    if (len (dividedTitle) == 3) { # may have 'Weather1_AMB_TEMP'
      if (dividedTitle [2] == 'AMB' && dividedTitle [3] == 'TEMP') {
        foundAmbientTemperature := T;
        ambientTemperature := app.table.getcol(columnTitles [i]);
        }# AMB & TEMP found
      }# 3 part column title found
   }# for i

  successfulMatch := foundAmbientTemperature && foundDewPoint &&
                     foundPressure;

  if (successfulMatch) {
    # now get the time column, fake the calculation, make the plot
    timeVector := app.table.getcol("Time")
    relativeHumidity := 
         100.0 * satH2Opress (dewPoint, pressure) /
                 satH2Opress (ambientTemperature, pressure);
    junk := timeY (timeVector, relativeHumidity, 'Relative Humidity');
    junk := setXAxisLabel (paste ("t0:", toDate (timeVector [1])));
    }
  else {
    errorDialog (
      'Failed to find AMB_TEMP, DEWP, and/or PRESSURE columns in this table');
    }

  return successfulMatch;

}# plotRelativeHumidity
#-----------------------------------------------------------------------------
satH2Opress := function (t_,p_)
# t_ is temperature in degrees C
# p_ is pressure in millibars (?)
# reference: ????
{
  return 6.1121*(1.0007+p_*3.46e-6)*exp(t_*17.502/(240.97+t_))
}
#-----------------------------------------------------------------------------
