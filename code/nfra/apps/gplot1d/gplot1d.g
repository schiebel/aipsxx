# gplot1d.g: convenience functions for glish client gplot1d
#
#   Copyright (C) 1995,1996,1997
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
#   $Id: gplot1d.g,v 19.0 2003/07/16 03:38:47 aips2adm Exp $
#
#-----------------------------------------------------------------------------
pragma include once
  
include "plotter.g"

# Start a globally available plotter

const gplot1d:=ref defaultplotter;

# Need these global functions for compatibility

const sleep:=ref gplot1d.sleep;
#  id:=gplot1d.id;
const drawBlockEnter:=ref gplot1d.drawBlockEnter;
const drawBlockExit:=ref gplot1d.drawBlockExit;
const getX:=ref gplot1d.getX;
const getY:=ref gplot1d.getY;
const setTopXAxis:=ref gplot1d.setTopXAxis;
const setLeftY2Axis:=ref gplot1d.setLeftY2Axis;
const setRightYAxis:=ref gplot1d.setRightYAxis;
const setXAxisLabel:=ref gplot1d.setXAxisLabel;
const setYAxisLabel:=ref gplot1d.setYAxisLabel;
const setY2AxisLabel:=ref gplot1d.setY2AxisLabel;
const setXAxisGrid:=ref gplot1d.setXAxisGrid;
const setYAxisGrid:=ref gplot1d.setYAxisGrid;
const setY2AxisGrid:=ref gplot1d.setY2AxisGrid;
const swapY1Y2:=ref gplot1d.swapY1Y2;
const setXAxisColor:=ref gplot1d.setXAxisColor;
const setYAxisColor:=ref gplot1d.setYAxisColor;
const setY2AxisColor:=ref gplot1d.setY2AxisColor;
const setXAxisLabelColor:=ref gplot1d.setXAxisLabelColor;
const setYAxisLabelColor:=ref gplot1d.setYAxisLabelColor;
const setY2AxisLabelColor:=ref gplot1d.setY2AxisLabelColor;
const setXAxisGridColor:=ref gplot1d.setXAxisGridColor;
const setYAxisGridColor:=ref gplot1d.setYAxisGridColor;
const setY2AxisGridColor:=ref gplot1d.setY2AxisGridColor;
const setPlotTitle:=ref gplot1d.setPlotTitle;
const setPlotTitleColor:=ref gplot1d.setPlotTitleColor;
const setCursorColor:=ref gplot1d.setCursorColor;
const setSelectionColor:=ref gplot1d.setSelectionColor;
# const setXAxisPosition:=ref gplot1d.setXAxisPosition;
# const setYAxisPosition:=ref gplot1d.setYAxisPosition;
const setY2AxisPosition:=ref gplot1d.setY2AxisPosition;
const ploty:=ref gplot1d.ploty;
const plotxy:=ref gplot1d.plotxy;
const plotxy2:=ref gplot1d.plotxy2;
const ploty2:=ref gplot1d.ploty2;
const timeY:=ref gplot1d.timeY;
const timeY2:=ref gplot1d.timeY2;
const skyY:=ref gplot1d.skyY;
const skyY2:=ref gplot1d.skyY2;
# const appendxy:=ref gplot1d.appendxy;
const setXScale:=ref gplot1d.setXScale;
const setYScale:=ref gplot1d.setYScale;
const setY2Scale:=ref gplot1d.setY2Scale;
const clear:=ref gplot1d.clear;
const clearData:=ref gplot1d.clearData;
const clearSelections:=ref gplot1d.clearSelections;
const showSelections:=ref gplot1d.showSelections;
const queryData:=ref gplot1d.queryData;
const deleteDataSet:=ref gplot1d.deleteDataSet;
const numberOfSelections:=ref gplot1d.numberOfSelections;
const getSelection:=ref gplot1d.getSelection;
const getSelectionMask:=ref gplot1d.getSelectionMask;
# const queryStyles:=ref gplot1d.queryStyles;
const setLineColor:=ref gplot1d.setLineColor;
const setLineStyle:=ref gplot1d.setLineStyle;
const setLineWidth:=ref gplot1d.setLineWidth;
const setPointColor:=ref gplot1d.setPointColor;
const setPointStyle:=ref gplot1d.setPointStyle;
const setPointSize:=ref gplot1d.setPointSize;
# const setPrintCommand:=ref gplot1d.setPrintCommand;
const marker:=ref gplot1d.marker;
const reverseX:=ref gplot1d.reverseX;
const reverseY:=ref gplot1d.reverseY;
const reverseY2:=ref gplot1d.reverseY2;
# const setLegendGeometry:=ref gplot1d.setLegendGeometry;
# const legendsOff:=ref gplot1d.legendsOff;
# const legendsOn:=ref gplot1d.legendsOn;
# const setPrinter:=ref gplot1d.setPrinter;
const psPrint:=ref gplot1d.psPrint;
const psPrintToFile:=ref gplot1d.psPrintToFile;
const helpPlot:=ref gplot1d.helpPlot;
