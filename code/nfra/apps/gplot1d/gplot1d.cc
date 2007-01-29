// gplot1d.cc:  Glish client for simple xy plotting
//# Copyright (C) 1994,1995,1996,1999,2000,2001,2002
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This program is free software; you can redistribute it and/or modify it
//# under the terms of the GNU General Public License as published by the Free
//# Software Foundation; either version 2 of the License, or (at your option)
//# any later version.
//#
//# This program is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//# more details.
//#
//# You should have received a copy of the GNU General Public License along
//# with this program; if not, write to the Free Software Foundation, Inc.,
//# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: gplot1d.cc,v 19.3 2004/11/30 17:50:39 ddebonis Exp $
//#----------------------------------------------------------------------------
#include <casa/BasicSL/String.h>
#include <tasking/Glish.h>
#include <tasking/Glish/XSysEvent.h>
#include <casa/Arrays/IPosition.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Exceptions/Error.h>
#include <casa/iostream.h>

//#----------------------------------------------------------------------------
#include <graphics/Graphics/PGPlot1d.h>

#include <casa/namespace.h>
//#----------------------------------------------------------------------------


#define GPLT_DECLARE_GLISH_STRING_FUNC(F, S)              \
Bool F(GlishSysEvent &event, void *)                       \
{                                                          \
  GlishValue glishValue = event.val ();                    \
  GlishSysEventSource *glishBus =  event.glishSource ();   \
                                                            \
  if (glishValue.type () == GlishValue::RECORD)  {           \
    glishBus->postEvent (S"_result",                          \
                         S" error: argument not an array");    \
    return True;                                               \
    }                                                          \
                                                               \
  GlishArray glishArray = glishValue;                          \
  if (glishArray.elementType() != GlishArray::STRING) {        \
    glishBus->postEvent (S"_result",                            \
                         S" error: argument is not a string");   \
    }                                                            \
                                                                  \
  String newColor = glishStringArrayToSingleString (glishArray);   \
                                                                   \
  plot_->F(newColor);                                              \
  glishBus->postEvent (S"_result", "ok");                          \
  return True;                                                     \
}

#define GPLT_DECLARE_GLISH_BOOL_FUNC(F,S)                       \
Bool F ( GlishSysEvent &event, void *)                           \
{                                                                 \
  GlishValue glishValue = event.val ();                           \
  GlishSysEventSource *glishBus =  event.glishSource ();           \
                                                                    \
  if (glishValue.type () == GlishValue::RECORD)  {                   \
    glishBus->postEvent (S"_result",                                 \
                         S" error: argument not an array");           \
    return True;                                                       \
    }                                                                  \
                                                                       \
  GlishArray glishArray = glishValue;                                  \
  if (glishArray.elementType() != GlishArray::STRING) {                 \
    glishBus->postEvent (S"_result",                                    \
                         S" error: argument is not a string");           \
    return True;                                                          \
    }                                                                     \
                                                                          \
  String onOff = downcase(glishStringArrayToSingleString (glishArray));   \
                                                                          \
  if (onOff == "on" || onOff[0] == 't' || onOff[0] == 'y' )               \
    plot_->F(True);                                                       \
  else if (onOff == "off" || onOff[0] == 'f' || onOff[0] == 'n')          \
    plot_->F(False);                                                      \
  else                                                                    \
    glishBus->postEvent (S"_result",                                      \
			 S" error: argument not understood");             \
  glishBus->postEvent (S"_result", "ok");                                 \
  return True;                                                             \
}

#define GPLT_DECLARE_GLISH_MINMAX_FUNC(F,S)                 \
Bool F (GlishSysEvent &event, void *)                        \
{                                                             \
  GlishValue glishValue = event.val ();                        \
  GlishSysEventSource *glishBus =  event.glishSource ();        \
  Double min, max;                                               \
                                                                  \
  if (glishValue.type () != GlishValue::RECORD)  {                 \
    glishBus->postEvent (S"_result",                                \
                         S" error: argument not a record");          \
    return True;                                                     \
    }                                                                \
                                                                     \
  GlishRecord record = glishValue;                                   \
  GlishArray glishArray;                                             \
                                                                     \
  if (!record.exists ("min")) {                                      \
    glishBus->postEvent (S"_result",                                 \
                         S" error: no <min> field");                 \
    return True;                                                     \
    }                                                                \
  else {                                                             \
    glishArray = record.get ("min");                                 \
    Vector <Double> temp (1);                                        \
    glishArray.get (temp);                                           \
    min = temp (0);                                                  \
    }                                                                \
                                                                     \
  if (!record.exists ("max")) {                                      \
    glishBus->postEvent (S"_result",                                 \
                         S" error: no <max> field");                 \
    return True;                                                     \
    }                                                                \
  else {                                                             \
    glishArray = record.get ("max");                                 \
    Vector <Double> temp (1);                                        \
    glishArray.get (temp);                                           \
    max = temp (0);                                                  \
    }                                                                \
                                                                     \
  plot_->F (min, max);                                               \
                                                                     \
  glishBus->postEvent (S"_result", "ok");                            \
  return True;                                                       \
}


#define GPLT_DECLARE_GLISH_DS_STRING_FUNC(F,S,V)  \
Bool F (GlishSysEvent &event, void *)              \
{                                                   \
  GlishValue glishValue = event.val ();                  \
  GlishSysEventSource *glishBus =  event.glishSource ();  \
  Int dataSetNumber;                                      \
  String colorName;                                       \
                                                          \
  if (glishValue.type () != GlishValue::RECORD)  {         \
    glishBus->postEvent (S"_result",                        \
                         S" error: argument not a record");  \
    return True;                                             \
    }                                                        \
                                                             \
  GlishRecord record = glishValue;                           \
  GlishArray glishArray;                                     \
                                                             \
  if (!record.exists ("dataSet")) {                          \
    glishBus->postEvent (S"_result",                         \
                         S" error: no <dataSet> field");     \
    return True;                                             \
    }                                                        \
  else {                                                     \
    glishArray = record.get ("dataSet");                     \
    glishArray.get (dataSetNumber, 0);                       \
    }                                                        \
                                                             \
  if (!record.exists (V)) {                                  \
    glishBus->postEvent (S"_result",                         \
                         S" error: no <"V"> field");         \
    return True;                                             \
    }                                                        \
  else {                                                     \
    glishArray = record.get (V);                              \
    colorName = glishStringArrayToSingleString (glishArray);   \
    }                                                          \
                                                               \
  plot_-> F (dataSetNumber, colorName);                        \
                                                               \
  glishBus->postEvent (S"_result", "ok");                      \
  return True;                                                 \
}

#define GPLT_DECLARE_GLISH_VOID_FUNC(F,S)             \
Bool F (GlishSysEvent &event, void *)                  \
{                                                       \
  GlishValue glishValue = event.val ();                  \
  GlishSysEventSource *glishBus =  event.glishSource ();  \
  plot_->F();                                             \
  glishBus->postEvent (S"_result", "ok");                 \
  return True;                                            \
}


//#----------------------------------------------------------------------------
Bool catchAllHandler (SysEvent &event, void *);
Bool defaultHandler (GlishSysEvent &event, void *);

Bool shutdownHandler (GlishSysEvent &event, void *);

Bool setPlotTitle (GlishSysEvent &event, void *);
Bool setPlotTitleColor (GlishSysEvent &event, void *);
Bool setCursorColor (GlishSysEvent &event, void *);
Bool setSelectionColor (GlishSysEvent &event, void *);

Bool setXAxisLabel (GlishSysEvent &event, void *);
Bool setYAxisLabel (GlishSysEvent &event, void *);
Bool setY2AxisLabel (GlishSysEvent &event, void *);

Bool setXAxisColor (GlishSysEvent &event, void *);
Bool setYAxisColor (GlishSysEvent &event, void *);
Bool setY2AxisColor (GlishSysEvent &event, void *);

Bool setXAxisLabelColor (GlishSysEvent &event, void *);
Bool setYAxisLabelColor (GlishSysEvent &event, void *);
Bool setY2AxisLabelColor (GlishSysEvent &event, void *);

Bool setTopXAxis (GlishSysEvent &event, void *);
Bool setRightYAxis (GlishSysEvent &event, void *);
Bool setLeftY2Axis (GlishSysEvent &event, void *);

#if 0
Bool setXAxisLineWidth (GlishSysEvent &event, void *);
Bool setYAxisLineWidth (GlishSysEvent &event, void *);
Bool setY2AxisLineWidth (GlishSysEvent &event, void *);
#endif

Bool setXAxisGrid (GlishSysEvent &event, void *);
Bool setYAxisGrid (GlishSysEvent &event, void *);
Bool setY2AxisGrid (GlishSysEvent &event, void *);

Bool setXAxisGridColor (GlishSysEvent &event, void *);
Bool setYAxisGridColor (GlishSysEvent &event, void *);
Bool setY2AxisGridColor (GlishSysEvent &event, void *);

#if 0
Bool setXAxisGridLineWidth (GlishSysEvent &event, void *);
Bool setYAxisGridLineWidth (GlishSysEvent &event, void *);
Bool setY2AxisGridLineWidth (GlishSysEvent &event, void *);
#endif

Bool setXScale (GlishSysEvent &event, void *);
Bool setYScale (GlishSysEvent &event, void *);
Bool setY2Scale (GlishSysEvent &event, void *);

Bool setLineColor (GlishSysEvent &event, void *);
Bool setLineStyle (GlishSysEvent &event, void *);
Bool setLineWidth (GlishSysEvent &event, void *);

Bool setPointColor (GlishSysEvent &event, void *);
Bool setPointStyle (GlishSysEvent &event, void *);
Bool setPointSize (GlishSysEvent &event, void *);

Bool showMarker (GlishSysEvent &event, void *);
Bool showSelections (GlishSysEvent &event, void *);

Bool setXAxisPosition (GlishSysEvent &event, void *);
Bool setYAxisPosition (GlishSysEvent &event, void *);
Bool setY2AxisPosition (GlishSysEvent &event, void *);

Bool setLegendGeometry (GlishSysEvent &event, void *);

Bool reverseXAxis (GlishSysEvent &event, void *);
Bool reverseYAxis (GlishSysEvent &event, void *);
Bool reverseY2Axis (GlishSysEvent &event, void *);

Bool swapY1Y2 (GlishSysEvent &event, void *);

Bool vectorcb (GlishSysEvent &event, void *);
Bool plotxy   (GlishSysEvent &event, void *);
Bool plotTimeY (GlishSysEvent &event, void *);
Bool plotSkyY (GlishSysEvent &event, void *);

Bool appendxy (GlishSysEvent &event, void *);

Bool deleteDataSet (GlishSysEvent &event, void *);

Bool numberOfSelectedRegions (GlishSysEvent &event, void *);
Bool getSelectedData (GlishSysEvent &event, void *);
Bool getSelectionMaskAndAllData (GlishSysEvent &event, void *);

Bool getXValues (GlishSysEvent &event, void *);
Bool getYValues (GlishSysEvent &event, void *);

Bool clear (GlishSysEvent &event, void *);
Bool clearData (GlishSysEvent &event, void *);
Bool clearSelections (GlishSysEvent &event, void *);
Bool queryData (GlishSysEvent &event, void *);
Bool queryStyles (GlishSysEvent &event, void *);

Bool setPrinter (GlishSysEvent &event, void *);
Bool setPrintCommand (GlishSysEvent &event, void *);
Bool printToPrinter (GlishSysEvent &event, void *);
Bool printToFile (GlishSysEvent &event, void *);

Bool drawBlockEnter(GlishSysEvent &event, void *);
Bool drawBlockExit(GlishSysEvent &event, void *);
Bool queryPrintCommand(GlishSysEvent &event, void *);

String glishStringArrayToSingleString (GlishArray stringArray);
void buildGUI (Widget topLevel, uInt width, uInt height,
               GlishSysEventSource &glishStream);
//#----------------------------------------------------------------------------
static char *fallback_resources [] = {
  "gplot1d*background: gray",
  "gplot1d*commandsForm.background: gray",
  "gplot1d.width: 300",
  "gplot1d.height: 500",
  "gplot1d.x: 720",
  "gplot1d.y: 20",
  "gplot1d*fontList: -adobe-courier-medium-r-normal--12-*",
  "gplot1d*separator.topAttachment: attach_widget",
  "gplot1d*separator.topWidget: commandsForm",
  "gplot1d*separator.topOffset: 0",
  "gplot1d*separator.leftAttachment: attach_form",
  "gplot1d*separator.leftOffset: 0",
  "gplot1d*separator.rightAttachment: attach_form",
  "gplot1d*separator.rightOffset: 0",
  "gplot1d*separator.background: gray",
  "gplot1d*plotterForm.background: gray",
  "gplot1d*plotterForm.topAttachment: attach_widget",
  "gplot1d*plotterForm.topWidget: separator",
  "gplot1d*plotterForm.topOffset: 2",
  "gplot1d*plotterForm.leftAttachment: attach_form",
  "gplot1d*plotterForm.leftOffset: 10",
  "gplot1d*plotterForm.rightAttachment: attach_form",
  "gplot1d*plotterForm.rightOffset: 10",
  "gplot1d*plotterForm.bottomAttachment: attach_form",
  "gplot1d*plotterForm.bottomOffset: 10",
  "gplot1d*buttonContainer.topAttachment: attach_form",
  "gplot1d*buttonContainer.topOffset: 10",
  "gplot1d*buttonContainer.leftAttachment: attach_form",
  "gplot1d*buttonContainer.leftOffset: 10",
  "gplot1d*fullViewButton.labelString: Full View",
  "gplot1d*clearSelectionButton.labelString: Clear Selection",
  "gplot1d*clearPlotButton.labelString: Clear Plot",
  "gplot1d*setDragModeFrame.topAttachment: attach_form",
  "gplot1d*setDragModeFrame.topOffset: 10",
  "gplot1d*setDragModeFrame.leftAttachment: attach_widget",
  "gplot1d*setDragModeFrame.leftWidget: buttonContainer",
  "gplot1d*setDragModeFrame.leftOffset: 5",
  "gplot1d*setDragModeRadioBox.orientation: VERTICAL",
  "gplot1d*setSelectDataButton.labelString: Select",
  "gplot1d*setZoomButton.labelString: Zoom",
  "gplot1d*setDragObjectFrame.topAttachment: attach_form",
  "gplot1d*setDragObjectFrame.topOffset: 10",
  "gplot1d*setDragObjectFrame.leftAttachment: attach_widget",
  "gplot1d*setDragObjectFrame.leftWidget: buttonContainer",
  "gplot1d*setDragObjectFrame.leftOffset: 84",
  "gplot1d*setDragObjectFrame.bottomAttachment: attach_form",
  "gplot1d*setDragObjectFrame.bottomOffset: 10",
  "gplot1d*setDragObjectRadioBox.orientation: VERTICAL",
  "gplot1d*selectXAxisButton.labelString: X Axis",
  "gplot1d*selectYAxisButton.labelString: Y Axis",
  "gplot1d*selectBoxButton.labelString: Box",
  "gplot1d*y1readout.width:           130",
  "gplot1d*y1readout.background:      gray91",
  "gplot1d*y1readout.topAttachment:   attach_form",
  "gplot1d*y1readout.topOffset:       2",
  "gplot1d*y1readout.leftAttachment:  attach_form",
  "gplot1d*y1readout.leftOffset:      10",
  "gplot1d*x1readout.width:           130",
  "gplot1d*x1readout.background:      gray91",
  "gplot1d*x1readout.topAttachment:   attach_widget",
  "gplot1d*x1readout.topWidget:       y1readout",
  "gplot1d*x1readout.topOffset:       1",
  "gplot1d*x1readout.leftAttachment:  attach_form",
  "gplot1d*x1readout.leftOffset:      10",
  "gplot1d*y2readout.width:           130",
  "gplot1d*y2readout.background:      gray91",
  "gplot1d*y2readout.topAttachment:   attach_form",
  "gplot1d*y2readout.topOffset:       2",
  "gplot1d*y2readout.rightAttachment: attach_form",
  "gplot1d*y2readout.rightOffset:     10",
  "gplot1d*x2readout.width:           130",
  "gplot1d*x2readout.background:      gray91",
  "gplot1d*x2readout.topAttachment:   attach_widget",
  "gplot1d*x2readout.topWidget:       y2readout",
  "gplot1d*x2readout.topOffset:       1",
  "gplot1d*x2readout.rightAttachment: attach_form",
  "gplot1d*x2readout.rightOffset:     10",
  "gplot1d*plot.topAttachment: attach_widget",
  "gplot1d*plot.topWidget: x1readout",
  "gplot1d*plot.topOffset: 10",
  "gplot1d*plot.leftAttachment: attach_form",
  "gplot1d*plot.leftOffset: 10",
  "gplot1d*plot.bottomAttachment: attach_form",
  "gplot1d*plot.bottomOffset: 10",
  "gplot1d*plot.rightAttachment: attach_form",
  "gplot1d*plot.rightOffset: 10",
  "gplot1d*.plot.xrtLegendAnchor:  AnchorSouth",
  "gplot1d*.plot.xrtLegendBorder:  BorderEtchedOut",
  "gplot1d*.plot.xrtLegendBorderWidth:  5",
  "gplot1d*.plot.xrtAxisBoundingBox: False",
  NULL};
//#----------------------------------------------------------------------------

Plot1d *plot_;

//#----------------------------------------------------------------------------
int main (int argc, char **argv)
/* start the glish event loop, and dispatch on event name.
 */
{
  try {
    int canvasHeight=500, canvasWidth=500;
    XSysEventSource xStream (argc, argv, (void *) NULL, fallback_resources,
                             "gplot1d");
    GlishSysEventSource glishStream (argc, argv);
    
    glishStream.setDefault (defaultHandler);
    glishStream.addTarget  (shutdownHandler, "^shutdown$");
    glishStream.addTarget  (queryData,        "^queryData$");
    glishStream.addTarget  (setPlotTitle,     "^setPlotTitle$");
    glishStream.addTarget  (setPlotTitleColor,"^setPlotTitleColor$");
    glishStream.addTarget  (setCursorColor,   "^setCursorColor$");
    glishStream.addTarget  (setSelectionColor,"^setSelectionColor$");
    glishStream.addTarget  (setXAxisLabel,    "^setXAxisLabel$");
    glishStream.addTarget  (setYAxisLabel,    "^setYAxisLabel$");
    glishStream.addTarget  (setY2AxisLabel,   "^setY2AxisLabel$");
    glishStream.addTarget  (setXAxisLabelColor,    "^setXAxisLabelColor$");
    glishStream.addTarget  (setYAxisLabelColor,    "^setYAxisLabelColor$");
    glishStream.addTarget  (setY2AxisLabelColor,   "^setY2AxisLabelColor$");
    glishStream.addTarget  (setXAxisColor,    "^setXAxisColor$");
    glishStream.addTarget  (setYAxisColor,    "^setYAxisColor$");
    glishStream.addTarget  (setY2AxisColor,   "^setY2AxisColor$");
#if 0
    glishStream.addTarget  (setXAxisLineWidth,    "^setXAxisLineWidth$");
    glishStream.addTarget  (setYAxisLineWidth,    "^setYAxisLineWidth$");
    glishStream.addTarget  (setY2AxisLineWidth,   "^setY2AxisLineWidth$");
#endif
    glishStream.addTarget  (setXAxisGrid,    "^setXAxisGrid$");
    glishStream.addTarget  (setYAxisGrid,    "^setYAxisGrid$");
    glishStream.addTarget  (setY2AxisGrid,   "^setY2AxisGrid$");
#if 0
    glishStream.addTarget  (setXAxisGridLineWidth,    "^setXAxisGridLineWidth$");
    glishStream.addTarget  (setYAxisGridLineWidth,    "^setYAxisGridLineWidth$");
    glishStream.addTarget  (setY2AxisGridLineWidth,   "^setY2AxisGridLineWidth$");
#endif
    glishStream.addTarget  (setTopXAxis,      "^setTopXAxis$");
    glishStream.addTarget  (setRightYAxis,    "^setRightYAxis$");
    glishStream.addTarget  (setLeftY2Axis,     "^setLeftY2Axis$");
    glishStream.addTarget  (setXAxisGridColor,    "^setXAxisGridColor$");
    glishStream.addTarget  (setYAxisGridColor,    "^setYAxisGridColor$");
    glishStream.addTarget  (setY2AxisGridColor,   "^setY2AxisGridColor$");
    glishStream.addTarget  (setLineColor,     "^setLineColor$");
    glishStream.addTarget  (setLineStyle,     "^setLineStyle$");
    glishStream.addTarget  (setLineWidth,     "^setLineWidth$");
    glishStream.addTarget  (setPointColor,    "^setPointColor$");
    glishStream.addTarget  (setPointStyle,    "^setPointStyle$");
    glishStream.addTarget  (setPointSize,     "^setPointSize$");
    glishStream.addTarget  (setPrintCommand,  "^setPrintCommand$");
    glishStream.addTarget  (setXAxisPosition, "^setXAxis$");
    glishStream.addTarget  (setYAxisPosition, "^setYAxis$");
    glishStream.addTarget  (setY2AxisPosition, "^setY2Axis$");
    glishStream.addTarget  (setXScale,        "^setXScale$");
    glishStream.addTarget  (setYScale,        "^setYScale$");
    glishStream.addTarget  (setY2Scale,        "^setY2Scale$");
    glishStream.addTarget  (setPointSize,     "^setPointSize$");
    glishStream.addTarget  (vectorcb,         "^vector$");
    glishStream.addTarget  (vectorcb,         "^vectorY2$");
    glishStream.addTarget  (plotxy,           "^xy$");
    glishStream.addTarget  (plotTimeY,        "^timeY$");
    glishStream.addTarget  (plotSkyY,         "^skyY$");
    glishStream.addTarget  (appendxy,         "^appendxy$");
    glishStream.addTarget  (getXValues,       "^getX$");
    glishStream.addTarget  (getYValues,       "^getY$");
    glishStream.addTarget  (numberOfSelectedRegions, 
                                              "^numberOfSelectedRegions$");

    glishStream.addTarget  (drawBlockEnter,   "^drawBlockEnter$");
    glishStream.addTarget  (drawBlockExit,    "^drawBlockExit$");

    glishStream.addTarget  (getSelectedData,  "^getSelection$");
    glishStream.addTarget  (getSelectionMaskAndAllData,
                                              "^getSelectionMask$");
    glishStream.addTarget  (deleteDataSet,    "^deleteDataSet$");
    glishStream.addTarget  (clear,             "^clear$");
    glishStream.addTarget  (clearData,        "^clearData$");
    glishStream.addTarget  (clearSelections,  "^clearSelections$");
    glishStream.addTarget  (reverseXAxis,     "^reverseXAxis$");
    glishStream.addTarget  (reverseYAxis,     "^reverseYAxis$");
    glishStream.addTarget  (reverseY2Axis,    "^reverseY2Axis$");
    glishStream.addTarget  (swapY1Y2,         "^swapY1Y2$");
    glishStream.addTarget  (setLegendGeometry,"^setLegendGeometry");
    glishStream.addTarget  (queryStyles,      "^queryStyles$");
    glishStream.addTarget  (showMarker,       "^showMarker$");
    glishStream.addTarget  (showSelections,   "^showSelections$");
    glishStream.addTarget  (setPrinter,       "^setPrinter$");
    glishStream.addTarget  (printToPrinter,   "^print$");
    glishStream.addTarget  (printToFile,      "^printToFile$");
    glishStream.addTarget  (queryPrintCommand,"^queryPrintCommand$");
    
    //glishStream.addTarget (catchAllHandler,"[a-z]+");   
    
    xStream.combine (glishStream);
    
    buildGUI (xStream.toplevel (), canvasHeight, canvasWidth, glishStream);
    XtRealizeWidget (xStream.toplevel ());

    xStream.loop ();                                  
    } 
  catch   (AipsError x) {
    cerr << "----------------------- exception! -------------------" << endl;
    cerr << "Exception Caught" << endl;
    } 

  return 0;

} // main
//#----------------------------------------------------------------------------
Bool defaultHandler (GlishSysEvent &event, void *)
{
  GlishSysEventSource *src =  event.glishSource ();     
  cerr << "gplot1d default handler invoked, with event: " 
       << event.type () << endl;
  src->postEvent ("default_result", "not handled");
  return True;                                     

//     GlishSysEventSource eventStream(argc, argv);                  //  7
//     GlishSysEvent event;                                          //  8
//     while (eventStream.connected()) {                             //  9
//         event = eventStream.nextGlishEvent();                     // 10
//         if (event.type() == "statistics") {                       // 11
//             GlishArray ga = event.val();                          // 12

}                                                    
//----------------------------------------------------------------------------
Bool shutdownHandler (GlishSysEvent &, void *)
{
  exit (0);
  return True;                                     
}     

GPLT_DECLARE_GLISH_STRING_FUNC(setPlotTitle, "setPlotTitle")
GPLT_DECLARE_GLISH_STRING_FUNC(setPlotTitleColor, "setPlotTitleColor")
GPLT_DECLARE_GLISH_STRING_FUNC(setPrintCommand, "setPrintCommand")

GPLT_DECLARE_GLISH_STRING_FUNC(setXAxisLabel, "setXAxisLabel")
GPLT_DECLARE_GLISH_STRING_FUNC(setYAxisLabel, "setYAxisLabel")
GPLT_DECLARE_GLISH_STRING_FUNC(setY2AxisLabel, "setY2AxisLabel")

GPLT_DECLARE_GLISH_STRING_FUNC(setXAxisColor, "setXAxisColor")
GPLT_DECLARE_GLISH_STRING_FUNC(setYAxisColor, "setYAxisColor")
GPLT_DECLARE_GLISH_STRING_FUNC(setY2AxisColor, "setY2AxisColor")

GPLT_DECLARE_GLISH_STRING_FUNC(setXAxisLabelColor, "setXAxisLabelColor")
GPLT_DECLARE_GLISH_STRING_FUNC(setYAxisLabelColor, "setYAxisLabelColor")
GPLT_DECLARE_GLISH_STRING_FUNC(setY2AxisLabelColor, "setY2AxisLabelColor")

GPLT_DECLARE_GLISH_BOOL_FUNC(setXAxisGrid, "setXAxisGrid")
GPLT_DECLARE_GLISH_BOOL_FUNC(setYAxisGrid, "setYAxisGrid")
GPLT_DECLARE_GLISH_BOOL_FUNC(setY2AxisGrid, "setY2AxisGrid")
GPLT_DECLARE_GLISH_BOOL_FUNC(setTopXAxis, "setTopXAxis")
GPLT_DECLARE_GLISH_BOOL_FUNC(setRightYAxis, "setRightYAxis")
GPLT_DECLARE_GLISH_BOOL_FUNC(setLeftY2Axis, "setLeftY2Axis")
GPLT_DECLARE_GLISH_BOOL_FUNC(showSelections, "showSelections")

GPLT_DECLARE_GLISH_STRING_FUNC(setXAxisGridColor, "setXAxisGridColor")
GPLT_DECLARE_GLISH_STRING_FUNC(setYAxisGridColor, "setYAxisGridColor")
GPLT_DECLARE_GLISH_STRING_FUNC(setY2AxisGridColor, "setY2AxisGridColor")

GPLT_DECLARE_GLISH_STRING_FUNC(setCursorColor, "setCursorColor")
GPLT_DECLARE_GLISH_STRING_FUNC(setSelectionColor, "setSelectionColor")

GPLT_DECLARE_GLISH_MINMAX_FUNC(setXScale, "setXScale")
GPLT_DECLARE_GLISH_MINMAX_FUNC(setYScale, "setYScale")
GPLT_DECLARE_GLISH_MINMAX_FUNC(setY2Scale, "setY2Scale")

GPLT_DECLARE_GLISH_DS_STRING_FUNC(setLineColor, "setLineColor", "color")
GPLT_DECLARE_GLISH_DS_STRING_FUNC(setPointColor, "setPointColor", "color")

GPLT_DECLARE_GLISH_VOID_FUNC(reverseXAxis, "reverseXAxis")
GPLT_DECLARE_GLISH_VOID_FUNC(reverseYAxis, "reverseYAxis")
GPLT_DECLARE_GLISH_VOID_FUNC(reverseY2Axis, "reverseY2Axis")
GPLT_DECLARE_GLISH_VOID_FUNC(swapY1Y2, "swapY1Y2")
GPLT_DECLARE_GLISH_VOID_FUNC(clear, "clear")
GPLT_DECLARE_GLISH_VOID_FUNC(clearData, "clearData")
GPLT_DECLARE_GLISH_VOID_FUNC(clearSelections, "clearSelections")
GPLT_DECLARE_GLISH_VOID_FUNC(drawBlockEnter, "drawBlockEnter")
GPLT_DECLARE_GLISH_VOID_FUNC(drawBlockExit, "drawBlockExit")
GPLT_DECLARE_GLISH_VOID_FUNC(queryPrintCommand, "queryPrintCommand")

//#--------------------------------------------------------------------------
Bool setLineStyle (GlishSysEvent &event, void *)
{
  GlishValue glishValue = event.val ();
  GlishSysEventSource *glishBus =  event.glishSource ();     
  Int dataSetNumber;
  String styleName;

    // does the event contain a record?
  if (glishValue.type () != GlishValue::RECORD)  {
    glishBus->postEvent ("setLineStyle_result", 
                         "setLineStyle error: argument not a record");
    return True;
    }
    // get the plotting legend from the record
  GlishRecord record = glishValue;
  GlishArray glishArray;
  
  if (!record.exists ("dataSet")) {
    glishBus->postEvent ("setLineStyle_result", 
                         "setLineStyle error: no <dataSet> field");
    return True;
    }
  else {
    glishArray = record.get ("dataSet");
    glishArray.get (dataSetNumber, 0);
    }

  if (!record.exists ("style")) {
    glishBus->postEvent ("setLineStyle_result", 
                         "setLineStyle error: no <style> field");
    return True;
    }
  else {
    glishArray = record.get ("style");
    styleName = glishStringArrayToSingleString (glishArray);
    }
  
  Plot1d::LineStyles newStyle;

  const char* styleNameC = styleName.chars();
  if (!strcmp (styleNameC, "none"))
    newStyle = Plot1d::noLine;
  else if (!strcmp (styleNameC, "solid"))
    newStyle = Plot1d::solid;
  else if (!strcmp (styleNameC, "dashed"))
    newStyle = Plot1d::dashed;
  else if (!strcmp (styleNameC, "dotted"))
    newStyle = Plot1d::dotted;
  else if (!strcmp (styleNameC, "shortDashed"))
    newStyle = Plot1d::shortDashed;
  else if (!strcmp (styleNameC, "mixedDashed"))
    newStyle = Plot1d::mixedDashed;
  else if (!strcmp (styleNameC, "dashDot"))
    newStyle = Plot1d::dashDot;
  else {
    glishBus->postEvent ("setLineStyle_result", 
      "setLineStyle error: style must be one of "
      "none, solid, dashed, dotted, shortDashed, mixedDashed, dashDot");
    return True;
    }

  plot_->setLineStyle (dataSetNumber, newStyle);
  
  glishBus->postEvent ("setLineStyle_result", "ok");
  return True;
  
} // setLineStyle 
//#--------------------------------------------------------------------------
Bool setLineWidth (GlishSysEvent &event, void *)
{
  GlishValue glishValue = event.val ();
  GlishSysEventSource *glishBus =  event.glishSource ();     
  Int dataSetNumber;
  Int width;

    // does the event contain a record?
  if (glishValue.type () != GlishValue::RECORD)  {
    glishBus->postEvent ("setLineWidth_result", 
                         "setLineWidth error: argument not a record");
    return True;
    }
    // get the plotting legend from the record
  GlishRecord record = glishValue;
  GlishArray glishArray;
  
  if (!record.exists ("dataSet")) {
    glishBus->postEvent ("setLineWidth_result", 
                         "setLineWidth error: no <dataSet> field");
    return True;
    }
  else {
    glishArray = record.get ("dataSet");
    glishArray.get (dataSetNumber, 0);
    }

  if (!record.exists ("width")) {
    glishBus->postEvent ("setLineWidth_result", 
                         "setLineWidth error: no <width> field");
    return True;
    }
  else {
    glishArray = record.get ("width");
    glishArray.get (width, 0); 
    }
  
  plot_->setLineWidth (dataSetNumber, width);
  
  glishBus->postEvent ("setLineWidth_result", "ok");
  return True;
  
} // setLineWidth 

//#--------------------------------------------------------------------------
Bool setPointStyle (GlishSysEvent &event, void *)
{
  GlishValue glishValue = event.val ();
  GlishSysEventSource *glishBus =  event.glishSource ();     
  Int dataSetNumber;
  String styleName;

    // does the event contain a record?
  if (glishValue.type () != GlishValue::RECORD)  {
    glishBus->postEvent ("setPointStyle_result", 
                         "setPointStyle error: argument not a record");
    return True;
    }
    // get the plotting legend from the record
  GlishRecord record = glishValue;
  GlishArray glishArray;
  
  if (!record.exists ("dataSet")) {
    glishBus->postEvent ("setPointStyle_result", 
                         "setPointStyle error: no <dataSet> field");
    return True;
    }
  else {
    glishArray = record.get ("dataSet");
    glishArray.get (dataSetNumber, 0);
    }

  if (!record.exists ("style")) {
    glishBus->postEvent ("setPointStyle_result", 
                         "setPointStyle error: no <style> field");
    return True;
    }
  else {
    glishArray = record.get ("style");
    styleName = glishStringArrayToSingleString (glishArray);
    }
  
  Plot1d::PointStyles newStyle;

  const char* styleNameC = styleName.chars();
  if (!strcmp (styleNameC, "none"))
    newStyle = Plot1d::noPoint;
  else if (!strcmp (styleNameC, "dot"))
    newStyle = Plot1d::dot;
  else if (!strcmp (styleNameC, "box"))
    newStyle = Plot1d::box;
  else if (!strcmp (styleNameC, "triangle"))
    newStyle = Plot1d::triangle;
  else if (!strcmp (styleNameC, "diamond"))
    newStyle = Plot1d::diamond;
  else if (!strcmp (styleNameC, "star"))
    newStyle = Plot1d::star;
  else if (!strcmp (styleNameC, "verticalLine"))
    newStyle = Plot1d::verticalLine;
  else if (!strcmp (styleNameC, "horizontalLine"))
    newStyle = Plot1d::horizontalLine;
  else if (!strcmp (styleNameC, "cross"))
    newStyle = Plot1d::cross;
  else if (!strcmp (styleNameC, "circle"))
    newStyle = Plot1d::circle;
  else if (!strcmp (styleNameC, "square"))
    newStyle = Plot1d::square;
  else {
    glishBus->postEvent ("setPointStyle_result", 
      "setPointStyle error: style must be one of "
      "dot, box, triangle, diamond, star, verticalLine, "
      "horizontalLine, cross, circle, square");
    return True;
    }

  plot_->setPointStyle (dataSetNumber, newStyle);
  
  glishBus->postEvent ("setPointStyle_result", "ok");
  return True;
  
} // setPointStyle
//#--------------------------------------------------------------------------
Bool setPointSize (GlishSysEvent &event, void *)
{
  GlishValue glishValue = event.val ();
  GlishSysEventSource *glishBus =  event.glishSource ();     
  Int dataSetNumber;
  Int size;

    // does the event contain a record?
  if (glishValue.type () != GlishValue::RECORD)  {
    glishBus->postEvent ("setPointSize_result", 
                         "setPointSize error: argument not a record");
    return True;
    }
    // get the plotting legend from the record
  GlishRecord record = glishValue;
  GlishArray glishArray;
  
  if (!record.exists ("dataSet")) {
    glishBus->postEvent ("setPointSize_result", 
                         "setPointSize error: no <dataSet> field");
    return True;
    }
  else {
    glishArray = record.get ("dataSet");
    glishArray.get (dataSetNumber, 0);
    }

  if (!record.exists ("size")) {
    glishBus->postEvent ("setPointSize_result", 
                         "setPointSize error: no <size> field");
    return True;
    }
  else {
    glishArray = record.get ("size");
    glishArray.get (size, 0); 
    }
  
  plot_->setPointSize (dataSetNumber, size);
  
  glishBus->postEvent ("setPointSize_result", "ok");
  return True;
  
} // setPointSize
//#--------------------------------------------------------------------------
Bool setXAxisPosition (GlishSysEvent &event, void *)
{
  GlishValue glishValue = event.val ();
  GlishSysEventSource *glishBus =  event.glishSource ();     
  String strategyString;

    // does the event contain a record?
  if (glishValue.type () != GlishValue::RECORD)  {
    glishBus->postEvent ("setXAxis_result", 
                         "setXAxis error: argument not a record");
    return True;
    }
    // get the plotting legend from the record
  GlishRecord record = glishValue;
  GlishArray glishArray;
  
  if (!record.exists ("strategy")) {
    glishBus->postEvent ("setXAxis_result", 
                         "setXAxis error: no <strategy> field");
    return True;
    }
  else {
    glishArray = record.get ("strategy");
    strategyString = glishStringArrayToSingleString (glishArray);
    }
  
  Plot1d::AxisPlacementStrategy newStrategy;
  Double explicitlyWhere;  // needed only if positioning is explicit

  /* find out which of the possible placement strategies has
   * been requested:
   *   axisAutomatic, axisAtMinimum, axisAtMaximum, axisAtExplicitPosition
   * note that 'axisAtExplicitPosition' requires an extra argument
   */

  const char* strategyStringC = strategyString.chars();
  if (!strcmp (strategyStringC, "auto"))
    newStrategy = Plot1d::axisAutomaticPlacement;
  else if (!strcmp (strategyStringC, "min"))
    newStrategy = Plot1d::axisAtMinimum;
  else if (!strcmp (strategyStringC, "max"))
    newStrategy = Plot1d::axisAtMaximum;
  else if (!strcmp (strategyStringC, "explicit")) {
    // 'explicit' needs an argument, so get it from the event
    newStrategy = Plot1d::axisAtExplicitPosition;
    if (!record.exists ("where")) {
      glishBus->postEvent ("setXAxis_result", 
                           "setXAxis error: no <where> field");
      return True;
    } // no <where> field
    else {
      glishArray = record.get ("where");
      glishArray.get (explicitlyWhere, 0);
      } // else: where field found
    } // explicit placement requested
  else { // no recognized placement
    glishBus->postEvent ("setXAxis_result", 
      "setXAxis error: style must be one of auto, min, max, explicit");
    return True;
    }

  if (newStrategy == Plot1d::axisAtExplicitPosition)
     plot_->setXAxisPosition (newStrategy, explicitlyWhere);
  else
     plot_->setXAxisPosition (newStrategy);
  
  glishBus->postEvent ("setXAxis_result", "ok");
  return True;

} // setXAxisPosition
//#--------------------------------------------------------------------------
Bool setYAxisPosition (GlishSysEvent &event, void *)
{
  GlishValue glishValue = event.val ();
  GlishSysEventSource *glishBus =  event.glishSource ();     
  String strategyString;

    // does the event contain a record?
  if (glishValue.type () != GlishValue::RECORD)  {
    glishBus->postEvent ("setYAxis_result", 
                         "setYAxis error: argument not a record");
    return True;
    }
    // get the plotting legend from the record
  GlishRecord record = glishValue;
  GlishArray glishArray;
  
  if (!record.exists ("strategy")) {
    glishBus->postEvent ("setYAxis_result", 
                         "setYAxis error: no <strategy> field");
    return True;
    }
  else {
    glishArray = record.get ("strategy");
    strategyString = glishStringArrayToSingleString (glishArray);
    }
  
  Plot1d::AxisPlacementStrategy newStrategy;
  Double explicitlyWhere;  // needed only if positioning is explicit

  /* find out which of the possible placement strategies has
   * been requested:
   *   axisAutomatic, axisAtMinimum, axisAtMaximum, axisAtExplicitPosition
   * note that 'axisAtExplicitPosition' requires an extra argument
   */

  const char* strategyStringC = strategyString.chars();
  if (!strcmp (strategyStringC, "auto"))
    newStrategy = Plot1d::axisAutomaticPlacement;
  else if (!strcmp (strategyStringC, "min"))
    newStrategy = Plot1d::axisAtMinimum;
  else if (!strcmp (strategyStringC, "max"))
    newStrategy = Plot1d::axisAtMaximum;
  else if (!strcmp (strategyStringC, "explicit")) {
    // 'explicit' needs an argument, so get it from the event
    newStrategy = Plot1d::axisAtExplicitPosition;
    if (!record.exists ("where")) {
      glishBus->postEvent ("setYAxis_result", 
                           "setYAxis error: no <where> field");
      return True;
    } // no <where> field
    else {
      glishArray = record.get ("where");
      glishArray.get (explicitlyWhere, 0);
      } // else: where field found
    } // explicit placement requested
  else { // no recognized placement
    glishBus->postEvent ("setYAxis_result", 
      "setYAxis error: style must be one of auto, min, max, explicit");
    return True;
    }

  if (newStrategy == Plot1d::axisAtExplicitPosition)
     plot_->setYAxisPosition (newStrategy, explicitlyWhere);
  else
     plot_->setYAxisPosition (newStrategy);
  
  glishBus->postEvent ("setYAxis_result", "ok");
  return True;

} // setYAxisPosition
//#--------------------------------------------------------------------------
Bool setY2AxisPosition (GlishSysEvent &event, void *)
{
  GlishValue glishValue = event.val ();
  GlishSysEventSource *glishBus =  event.glishSource ();     
  String strategyString;

    // does the event contain a record?
  if (glishValue.type () != GlishValue::RECORD)  {
    glishBus->postEvent ("setY2Axis_result", 
                         "setY2Axis error: argument not a record");
    return True;
    }
    // get the plotting legend from the record
  GlishRecord record = glishValue;
  GlishArray glishArray;
  
  if (!record.exists ("strategy")) {
    glishBus->postEvent ("setY2Axis_result", 
                         "setY2Axis error: no <strategy> field");
    return True;
    }
  else {
    glishArray = record.get ("strategy");
    strategyString = glishStringArrayToSingleString (glishArray);
    }
  
  Plot1d::AxisPlacementStrategy newStrategy;
  Double explicitlyWhere;  // needed only if positioning is explicit

  /* find out which of the possible placement strategies has
   * been requested:
   *   axisAutomatic, axisAtMinimum, axisAtMaximum, axisAtExplicitPosition
   * note that 'axisAtExplicitPosition' requires an extra argument
   */

  const char* strategyStringC = strategyString.chars();
  if (!strcmp (strategyStringC, "auto"))
    newStrategy = Plot1d::axisAutomaticPlacement;
  else if (!strcmp (strategyStringC, "min"))
    newStrategy = Plot1d::axisAtMinimum;
  else if (!strcmp (strategyStringC, "max"))
    newStrategy = Plot1d::axisAtMaximum;
  else if (!strcmp (strategyStringC, "explicit")) {
    // 'explicit' needs an argument, so get it from the event
    newStrategy = Plot1d::axisAtExplicitPosition;
    if (!record.exists ("where")) {
      glishBus->postEvent ("setY2Axis_result", 
                           "setY2Axis error: no <where> field");
      return True;
    } // no <where> field
    else {
      glishArray = record.get ("where");
      glishArray.get (explicitlyWhere, 0);
      } // else: where field found
    } // explicit placement requested
  else { // no recognized placement
    glishBus->postEvent ("setY2Axis_result", 
      "setY2Axis error: style must be one of auto, min, max, explicit");
    return True;
    }

  if (newStrategy == Plot1d::axisAtExplicitPosition)
     plot_->setY2AxisPosition (newStrategy, explicitlyWhere);
  else
     plot_->setY2AxisPosition (newStrategy);
  
  glishBus->postEvent ("setY2Axis_result", "ok");
  return True;

} // setY2AxisPosition
//#--------------------------------------------------------------------------
Bool setLegendGeometry (GlishSysEvent &event, void *)
{
  GlishValue glishValue = event.val ();
  GlishSysEventSource *glishBus =  event.glishSource ();     

    // does the event contain a record?
  if (glishValue.type () == GlishValue::RECORD)  {
    glishBus->postEvent ("setLegendGeometry_result", 
                         "setLegendGeometry error: argument not an array");
    return True;
    }

  GlishArray glishArray = glishValue;
  if (glishArray.elementType() != GlishArray::STRING) {
    glishBus->postEvent ("setLegendGeometry_result", 
                         "setLegendGeometry error: argument is not a string");
    }
  
  String geometryString = glishStringArrayToSingleString (glishArray);

  Plot1d::LegendGeometry newGeometry;

  const char* geometryStringC = geometryString.chars();
  if (!strcmp (geometryStringC, "north"))
     newGeometry = Plot1d::legendNorth;
  else if (!strcmp (geometryStringC, "east"))
     newGeometry = Plot1d::legendEast;
  else if (!strcmp (geometryStringC, "south"))
     newGeometry = Plot1d::legendSouth;
  else if (!strcmp (geometryStringC, "west"))
     newGeometry = Plot1d::legendWest;
  else if (!strcmp (geometryStringC, "vertical"))
     newGeometry = Plot1d::legendVertical;
  else if (!strcmp (geometryStringC, "horizontal"))
     newGeometry = Plot1d::legendHorizontal;
  else if (!strcmp (geometryStringC, "hide"))
     newGeometry = Plot1d::legendHidden;
  else if (!strcmp (geometryStringC, "show"))
     newGeometry = Plot1d::legendVisible;
  else if (!strcmp (geometryStringC, "default"))
     newGeometry = Plot1d::legendDefault;
  else {
     glishBus->postEvent ("setLegendGeometry_result", "unrecognized geometry");
     return True;
     }

  plot_->setLegendGeometry (newGeometry);

  glishBus->postEvent ("setLegendGeometry_result", "ok");
  return True;
  
} // setLegendPosition
//#--------------------------------------------------------------------------
Bool vectorcb (GlishSysEvent &event, void *)
{
  GlishValue glishValue = event.val ();
  GlishSysEventSource *glishBus =  event.glishSource ();     
  Int dataSetID;

    // does the event contain a record?
  if (glishValue.type () != GlishValue::RECORD)  {
    glishBus->postEvent ("vector_result", 
                         "vector error: argument not a record");
    return True;
    }
    // get the plotting legend from the record
  GlishRecord record = glishValue;
  GlishArray glishArray;
  String dataSetName;
  
  if (!record.exists ("name")) {
    glishBus->postEvent ("vector_result", "vector error: no <name> field");
    return True;
    }
  else {
    glishArray = record.get ("name");
    dataSetName = glishStringArrayToSingleString (glishArray);
  }
  
  Vector <Double> lvector;
  
    // get the data from the record
  if (!record.exists ("data")) {
    glishBus->postEvent ("vector_result", "vector error: no <data> field");
    return True;
    }
  else {
    glishArray = record.get ("data");
    IPosition shape = glishArray.shape ();
    if (shape.nelements () != 1) {
      glishBus->postEvent ("vector_result", "vector error: dimension != 1");
      return True;
      }
    uInt vectorLength = glishArray.nelements ();
    lvector.resize (vectorLength);
    glishArray.get (lvector);
    }


  Plot1d::DataStyles dataStyle = Plot1d::linespoints;

  if (record.exists ("style")) {
    glishArray = record.get ("style");
    String styleName = glishStringArrayToSingleString (glishArray);
    const char* styleNameC = styleName.chars();
    if (!strcmp (styleNameC, "lines"))
       dataStyle = Plot1d::lines;
    else if (!strcmp (styleNameC, "linespoints"))
       dataStyle = Plot1d::linespoints;
    else if (!strcmp (styleNameC, "points"))
       dataStyle = Plot1d::points;
    else if (!strcmp (styleNameC, "histogram"))
       dataStyle = Plot1d::histogram;
    else {
      glishBus->postEvent ("vector_result", "vector unknown style");
      return True;
      }
    } // if style record exists


  String xAxisLabel = "";
  
  if (record.exists ("xLabel")) {
    glishArray = record.get ("xLabel");
    xAxisLabel = glishStringArrayToSingleString (glishArray);
  }
  
  String yAxisLabel = "";
  
  if (record.exists ("yLabel")) {
    glishArray = record.get ("yLabel");
    yAxisLabel = glishStringArrayToSingleString (glishArray);
  }
  
  Plot1d::AxisType xAxisType = Plot1d::RAW_AXIS;  // default
  Plot1d::AxisType yAxisType = Plot1d::RAW_AXIS;  // default


  Plot1dData::AssociatedYAxis associatedYAxis = Plot1dData::Y1Axis;

  if (record.exists ("y2axis")) 
    associatedYAxis = Plot1dData::Y2Axis;   // Y1Axis is the default

  dataSetID = plot_->addDataSet (lvector, dataSetName.chars(), dataStyle, 
                                 xAxisLabel.chars(), yAxisLabel.chars(), 
                                 xAxisType, yAxisType, 
                                 associatedYAxis);

  //dataSetID = plot_->addDataSet (lvector, dataSetName, dataStyle);

  GlishArray resultAsArray (dataSetID);
  glishBus->postEvent ("vector_result", resultAsArray);
  return True;
  
} // handleVectorEvent
//#--------------------------------------------------------------------------
Bool plotxy (GlishSysEvent &event, void *)
/* the value of the xy event is a record, with several fields, some
 * of which are optional.  missing optional values take on default values.
 *
 * required fields
 * ---------------
 *    name: 
 *    x:
 *    y:
 *
 * optional fields
 * ---------------
 *    y2axis:
 *    x_label:
 *    y_label:
 *    lineColor:
 *    lineStyle:
 *    lineWidth:
 *    dotColor:
 *    dotStyle:
 *    dotSize:
 */
{
  GlishValue glishValue = event.val ();
  GlishSysEventSource *glishBus =  event.glishSource ();     
  Int dataSetID;

    // does the event contain a record?
  if (glishValue.type () != GlishValue::RECORD)  {
    glishBus->postEvent ("xy_result", 
                         "xy error: argument not a record");
    return True;
    }
    // get the plotting legend from the record
  GlishRecord record = glishValue;
  GlishArray glishArray;
  String dataSetName;
  
  if (!record.exists ("name")) {
    glishBus->postEvent ("xy_result", "xy error: no <name> field");
    return True;
    }
  else {
    glishArray = record.get ("name");
    dataSetName = glishStringArrayToSingleString (glishArray);
  }
  
  Vector <Double> x;

  
    // get the data from the record
  if (!record.exists ("x")) {
    glishBus->postEvent ("xy_result", "xy error: no <x> field");
    return True;
    }
  else {
    glishArray = record.get ("x");
    IPosition shape = glishArray.shape ();
    if (shape.nelements () != 1) {
      glishBus->postEvent ("xy_result", "xy error: dimension != 1");
      return True;
      }
    uInt vectorLength = glishArray.nelements ();
    x.resize (vectorLength);
    glishArray.get (x);
    }
  
  Vector <Double> y;
  
    // get the data from the record
  if (!record.exists ("y")) {
    glishBus->postEvent ("xy_result", "xy error: no <y> field");
    return True;
    }
  else {
    glishArray = record.get ("y");
    IPosition shape = glishArray.shape ();
    if (shape.nelements () != 1) {
      glishBus->postEvent ("xy_result", "xy error: dimension != 1");
      return True;
      }
    uInt vectorLength = glishArray.nelements ();
    y.resize (vectorLength);
    glishArray.get (y);
    }
  
  Plot1dData::AssociatedYAxis associatedYAxis = Plot1dData::Y1Axis;

  if (record.exists ("y2axis")) 
    associatedYAxis = Plot1dData::Y2Axis;   // Y1Axis is the default

  Plot1d::DataStyles dataStyle = Plot1d::linespoints;

  if (record.exists ("style")) {
    glishArray = record.get ("style");
    String styleName = glishStringArrayToSingleString (glishArray);
    const char* styleNameC = styleName.chars();
    //cout << "xy style: " << styleName << endl;
    if (!strcmp (styleNameC, "lines"))
       dataStyle = Plot1d::lines;
    else if (!strcmp (styleNameC, "linespoints"))
       dataStyle = Plot1d::linespoints;
    else if (!strcmp (styleNameC, "points"))
       dataStyle = Plot1d::points;
    else if (!strcmp (styleNameC, "histogram"))
       dataStyle = Plot1d::histogram;
    else {
      glishBus->postEvent ("xy_result", "xy unknown style");
      return True;
      }
    } // if style record exists

  String xAxisLabel = "";
  
  if (record.exists ("xLabel")) {
    glishArray = record.get ("xLabel");
    xAxisLabel = glishStringArrayToSingleString (glishArray);
  }
  
  String yAxisLabel = "";
  
  if (record.exists ("yLabel")) {
    glishArray = record.get ("yLabel");
    yAxisLabel = glishStringArrayToSingleString (glishArray);
  }
  
  Plot1d::AxisType xAxisType = Plot1d::RAW_AXIS;  // default
  Plot1d::AxisType yAxisType = Plot1d::RAW_AXIS;  // default

  dataSetID = plot_->addDataSet (x, y, dataSetName.chars(), dataStyle, 
                                 xAxisLabel.chars(), yAxisLabel.chars(), 
                                 xAxisType, yAxisType, 
                                 associatedYAxis);

  GlishArray resultAsArray (dataSetID);
  glishBus->postEvent ("xy_result", resultAsArray);
  return True;
  
} // plot xy
//#--------------------------------------------------------------------------
Bool plotTimeY (GlishSysEvent &event, void *)
/* the value of the plotTimeY event is a record, with several fields, some
 * of which are optional.  missing optional values take on default values.
 *
 * required fields
 * ---------------
 *    name: 
 *    x:
 *    y:
 *
 * optional fields
 * ---------------
 *    x_label:
 *    y_label:
 *    lineColor:
 *    lineStyle:
 *    lineWidth:
 *    dotColor:
 *    dotStyle:
 *    dotSize:
 */
{
  GlishValue glishValue = event.val ();
  GlishSysEventSource *glishBus =  event.glishSource ();     
  Int dataSetID;

    // does the event contain a record?
  if (glishValue.type () != GlishValue::RECORD)  {
    glishBus->postEvent ("timeY_result", 
                         "timeY error: argument not a record");
    return True;
    }
    // get the plotting legend from the record
  GlishRecord record = glishValue;
  GlishArray glishArray;
  String dataSetName;
  
  if (!record.exists ("name")) {
    glishBus->postEvent ("timeY_result", "timeY error: no <name> field");
    return True;
    }
  else {
    glishArray = record.get ("name");
    dataSetName = glishStringArrayToSingleString (glishArray);
  }
  
  Vector <Double> x;
  
    // get the data from the record
  if (!record.exists ("x")) {
    glishBus->postEvent ("timeY_result", "timeY error: no <x> field");
    return True;
    }
  else {
    glishArray = record.get ("x");
    IPosition shape = glishArray.shape ();
    if (shape.nelements () != 1) {
      glishBus->postEvent ("timeY_result", "timeY error: dimension != 1");
      return True;
      }
    uInt vectorLength = glishArray.nelements ();
    x.resize (vectorLength);
    glishArray.get (x);
    }
  
  Vector <Double> y;
  
    // get the data from the record
  if (!record.exists ("y")) {
    glishBus->postEvent ("timeY_result", "timeY error: no <y> field");
    return True;
    }
  else {
    glishArray = record.get ("y");
    IPosition shape = glishArray.shape ();
    if (shape.nelements () != 1) {
      glishBus->postEvent ("timeY_result", "timeY error: dimension != 1");
      return True;
      }
    uInt vectorLength = glishArray.nelements ();
    y.resize (vectorLength);
    glishArray.get (y);
    }
  
  Plot1d::DataStyles dataStyle = Plot1d::linespoints;

  if (record.exists ("style")) {
    glishArray = record.get ("style");
    String styleName = glishStringArrayToSingleString (glishArray);
    const char* styleNameC = styleName.chars();
    if (!strcmp (styleNameC, "lines"))
       dataStyle = Plot1d::lines;
    else if (!strcmp (styleNameC, "linespoints"))
       dataStyle = Plot1d::linespoints;
    else if (!strcmp (styleNameC, "points"))
       dataStyle = Plot1d::points;
    else if (!strcmp (styleNameC, "histogram"))
       dataStyle = Plot1d::histogram;
    else {
      glishBus->postEvent ("timeY_result", "timeY unknown style");
      return True;
      }
    } // if style record exists


  String xAxisLabel;
  
  if (record.exists ("xLabel")) {
    glishArray = record.get ("xLabel");
    xAxisLabel = glishStringArrayToSingleString (glishArray);
  }
  
  String yAxisLabel;
  
  if (record.exists ("yLabel")) {
    glishArray = record.get ("yLabel");
    yAxisLabel = glishStringArrayToSingleString (glishArray);
  }
  
  Plot1dData::AssociatedYAxis associatedYAxis = Plot1dData::Y1Axis;
  if (record.exists ("y2axis")) 
    associatedYAxis = Plot1dData::Y2Axis;   // Y1Axis is the default


  Plot1d::AxisType xAxisType = Plot1d::TIME_AXIS;
  Plot1d::AxisType yAxisType = Plot1d::RAW_AXIS; 

  //cout << "gplot1d: about to call addDataSet with time axis" << endl;
  //cout << "    x: " << x.nelements () << endl;
  //cout << "    y: " << y.nelements () << endl;
  dataSetID = plot_->addDataSet (x, y, dataSetName.chars(), dataStyle, 
                                 xAxisLabel.chars(), yAxisLabel.chars(), 
                                 xAxisType, yAxisType,
				 associatedYAxis);

  GlishArray resultAsArray (dataSetID);
  glishBus->postEvent ("timeY_result", resultAsArray);
  return True;
  
} // time Y
Bool plotSkyY (GlishSysEvent &event, void *)
/* the value of the plotSkyY event is a record, with several fields, some
 * of which are optional.  missing optional values take on default values.
 *
 * required fields
 * ---------------
 *    name: 
 *    x:
 *    y:
 *
 * optional fields
 * ---------------
 *    x_label:
 *    y_label:
 *    lineColor:
 *    lineStyle:
 *    lineWidth:
 *    dotColor:
 *    dotStyle:
 *    dotSize:
 */
{
  GlishValue glishValue = event.val ();
  GlishSysEventSource *glishBus =  event.glishSource ();     
  Int dataSetID;

    // does the event contain a record?
  if (glishValue.type () != GlishValue::RECORD)  {
    glishBus->postEvent ("skyY_result", 
                         "skyY error: argument not a record");
    return True;
    }
    // get the plotting legend from the record
  GlishRecord record = glishValue;
  GlishArray glishArray;
  String dataSetName;
  
  if (!record.exists ("name")) {
    glishBus->postEvent ("skyY_result", "skyY error: no <name> field");
    return True;
    }
  else {
    glishArray = record.get ("name");
    dataSetName = glishStringArrayToSingleString (glishArray);
  }
  
  Vector <Double> x;
  
    // get the data from the record
  if (!record.exists ("x")) {
    glishBus->postEvent ("skyY_result", "skyY error: no <x> field");
    return True;
    }
  else {
    glishArray = record.get ("x");
    IPosition shape = glishArray.shape ();
    if (shape.nelements () != 1) {
      glishBus->postEvent ("skyY_result", "skyY error: dimension != 1");
      return True;
      }
    uInt vectorLength = glishArray.nelements ();
    x.resize (vectorLength);
    glishArray.get (x);
    }
  
  Vector <Double> y;
  
    // get the data from the record
  if (!record.exists ("y")) {
    glishBus->postEvent ("skyY_result", "skyY error: no <y> field");
    return True;
    }
  else {
    glishArray = record.get ("y");
    IPosition shape = glishArray.shape ();
    if (shape.nelements () != 1) {
      glishBus->postEvent ("skyY_result", "skyY error: dimension != 1");
      return True;
      }
    uInt vectorLength = glishArray.nelements ();
    y.resize (vectorLength);
    glishArray.get (y);
    }
  
  Plot1d::DataStyles dataStyle = Plot1d::linespoints;

  if (record.exists ("style")) {
    glishArray = record.get ("style");
    String styleName = glishStringArrayToSingleString (glishArray);
    const char* styleNameC = styleName.chars();
    if (!strcmp (styleNameC, "lines"))
       dataStyle = Plot1d::lines;
    else if (!strcmp (styleNameC, "linespoints"))
       dataStyle = Plot1d::linespoints;
    else if (!strcmp (styleNameC, "points"))
       dataStyle = Plot1d::points;
    else if (!strcmp (styleNameC, "histogram"))
       dataStyle = Plot1d::histogram;
    else {
      glishBus->postEvent ("skyY_result", "skyY unknown style");
      return True;
      }
    } // if style record exists


  String xAxisLabel;
  
  if (record.exists ("xLabel")) {
    glishArray = record.get ("xLabel");
    xAxisLabel = glishStringArrayToSingleString (glishArray);
  }
  
  String yAxisLabel;
  
  if (record.exists ("yLabel")) {
    glishArray = record.get ("yLabel");
    yAxisLabel = glishStringArrayToSingleString (glishArray);
  }
  
  Plot1dData::AssociatedYAxis associatedYAxis = Plot1dData::Y1Axis;
  if (record.exists ("y2axis")) 
    associatedYAxis = Plot1dData::Y2Axis;   // Y1Axis is the default

  Plot1d::AxisType xAxisType = Plot1d::SKYPOSITION_AXIS;
  Plot1d::AxisType yAxisType = Plot1d::RAW_AXIS; 

  //cout << "gplot1d: about to call addDataSet with time axis" << endl;
  //cout << "    x: " << x.nelements () << endl;
  //cout << "    y: " << y.nelements () << endl;
  dataSetID = plot_->addDataSet (x, y, dataSetName.chars(), dataStyle, 
                                 xAxisLabel.chars(), yAxisLabel.chars(), 
                                 xAxisType, yAxisType,
				 associatedYAxis);

  GlishArray resultAsArray (dataSetID);
  glishBus->postEvent ("skyY_result", resultAsArray);
  return True;
  
} // sky Y
//#--------------------------------------------------------------------------
Bool appendxy (GlishSysEvent &event, void *)
{
  GlishValue glishValue = event.val ();
  GlishSysEventSource *glishBus =  event.glishSource ();     
  Int dataSetNumber;
  Double x,y;

    // does the event contain a record?
  if (glishValue.type () != GlishValue::RECORD)  {
    glishBus->postEvent ("appendxy_result", 
                         "appendxy error: argument not a record");
    return True;
    }
    // get the plotting legend from the record
  GlishRecord record = glishValue;
  GlishArray glishArray;

  if (!record.exists ("dataset")) {
    glishBus->postEvent ("appendxy_result", 
                         "appendxy error: no <dataset> field");
    return True;
    }
  else {
    glishArray = record.get ("dataset");
    Vector <Int> temp (1);
    glishArray.get (temp);
    dataSetNumber = temp (0);
    }
  
  if (!record.exists ("x")) {
    glishBus->postEvent ("appendxy_result", 
                         "appendxy error: no <x> field");
    return True;
    }
  else {
    glishArray = record.get ("x");
    Vector <Double> temp (1);
    glishArray.get (temp);
    x = temp (0);
    }
  
  if (!record.exists ("y")) {
    glishBus->postEvent ("appendxy_result", 
                         "appendxy error: no <y> field");
    return True;
    }
  else {
    glishArray = record.get ("y");
    Vector <Double> temp (1);
    glishArray.get (temp);
    y = temp (0);
    }
  
  plot_->appendData (dataSetNumber, x, y);

  glishBus->postEvent ("appendxy_result", "ok");
  return True;

} // append xy
//#--------------------------------------------------------------------------
Bool deleteDataSet (GlishSysEvent &event, void *)
{
  GlishValue glishValue = event.val ();
  GlishSysEventSource *glishBus =  event.glishSource ();     

  if (glishValue.type () != GlishValue::ARRAY)  {
    glishBus->postEvent ("deleteDataSet_result", 
                         "deleteDataSet error: argument is a record");
    return True;
    }

  GlishArray glishArray = glishValue;
  if (glishArray.elementType() == GlishArray::STRING) {
    glishBus->postEvent ("deleteDataSet_result", 
                         "deleteDataSet error: argument not an integer");
    return True;
    }

  Vector <Int> temp (1);
  glishArray.get (temp);
  Int dataSetNumber = temp (0);

  Bool success = plot_->deleteDataSet (dataSetNumber);

  if (success)
     glishBus->postEvent ("deleteDataSet_result", "ok");
  else
     glishBus->postEvent ("deleteDataSet_result", "failed");

  return True;

} // delete data set
//#--------------------------------------------------------------------------
Bool getXValues (GlishSysEvent &event, void *)
{
  GlishValue glishValue = event.val ();
  GlishSysEventSource *glishBus =  event.glishSource ();     

  if (glishValue.type () != GlishValue::ARRAY)  {
    glishBus->postEvent ("getX_result", 
                         "getX error: argument is a record");
    return True;
    }

  GlishArray glishArray = glishValue;
  if (glishArray.elementType() == GlishArray::STRING) {
    glishBus->postEvent ("getX_result", 
                         "getX error: argument not an integer");
    return True;
    }

  Vector <Int> temp (1);
  glishArray.get (temp);
  Int dataSetNumber = temp (0);

  Vector <Double> x = plot_->getXValues (dataSetNumber);
     
  glishBus->postEvent ("getX_result", x);
  return True;

}  // get x values
//#--------------------------------------------------------------------------
Bool getYValues (GlishSysEvent &event, void *)
{
  GlishValue glishValue = event.val ();
  GlishSysEventSource *glishBus =  event.glishSource ();     

  if (glishValue.type () != GlishValue::ARRAY)  {
    glishBus->postEvent ("getY_result", 
                         "getY error: argument is a record");
    return True;
    }

  GlishArray glishArray = glishValue;
  if (glishArray.elementType() == GlishArray::STRING) {
    glishBus->postEvent ("getY_result", 
                         "getY error: argument not an integer");
    return True;
    }

  Vector <Int> temp (1);
  glishArray.get (temp);
  Int dataSetNumber = temp (0);

  Vector <Double> y = plot_->getYValues (dataSetNumber);
     
  glishBus->postEvent ("getY_result", y);
  return True;

} // get y values
//#--------------------------------------------------------------------------
Bool numberOfSelectedRegions (GlishSysEvent &event, void *)
{
  GlishValue glishValue = event.val ();
  GlishSysEventSource *glishBus =  event.glishSource ();     

  Vector <Double> x, y;
  Vector <Bool> mask;

  Int numberOfRegions  =  plot_->numberOfSelections ();
     
  GlishArray resultAsArray (numberOfRegions);
  glishBus->postEvent ("numberOfSelectedRegions_result", resultAsArray);

  return True;
  
} // getSelectedData
//#--------------------------------------------------------------------------
Bool getSelectedData (GlishSysEvent &event, void *)
/* create two local vectors, and ask the plotter to fill them with the
 * current selection. when the plotter returns, see if the vectors have
 * any points in them.  if yes, return them as two parts of a glish
 * record.  if not, simply return False.
 */
{
  GlishValue glishValue = event.val ();
  GlishSysEventSource *glishBus =  event.glishSource ();     

  Vector <Double> x, y;
  Bool successful =  plot_->getSelectedData (x, y);
  if (!successful) {
    glishBus->postEvent ("getSelection_result", "error:  no selected data");
    return True;
    }
     
  GlishRecord response;

  if (x.nelements () > 0) {
     response.add ("x", x);
     response.add ("y", y);
     glishBus->postEvent ("getSelection_result", response);
     }
  else {
    Bool result = False;
    GlishArray resultAsArray (result);
    glishBus->postEvent ("getSelection_result", resultAsArray);
    }

  return True;
  
} // getSelectedData
//#--------------------------------------------------------------------------
Bool getSelectionMaskAndAllData (GlishSysEvent &event, void *)
{
  GlishValue glishValue = event.val ();
  GlishSysEventSource *glishBus =  event.glishSource ();     

  Vector <Double> x, y;
  Vector <Bool> mask;

  Bool successful =  plot_->getDataAndSelectionMask (x, y, mask);
  if (!successful)
    glishBus->postEvent ("getSelectionMask_result",
                         "error:  no selected data");
     
  GlishRecord response;
  response.add ("x", x);
  response.add ("y", y);
  response.add ("mask", mask);

  glishBus->postEvent ("getSelectionMask_result", response);
  return True;
  
} // getSelectedData
//#--------------------------------------------------------------------------
Bool queryData (GlishSysEvent &event, void *)
{
  GlishValue glishValue = event.val ();
  GlishSysEventSource *glishBus =  event.glishSource ();     

  String dataSetDescription = plot_->describeDataSets ();
  String selectionsDescription = plot_->describeDataSelections ();

  Vector <String> descriptions (2);
  descriptions (0) = dataSetDescription;
  descriptions (1) = selectionsDescription;

  glishBus->postEvent ("queryData_result", descriptions);
  return True;
  
} // queryData 
//#--------------------------------------------------------------------------
Bool queryStyles (GlishSysEvent &event, void *)
{
  GlishValue glishValue = event.val ();
  GlishSysEventSource *glishBus =  event.glishSource ();     

  String stylesDescription = plot_->describeDataDisplayStyles ();
  
  // <todo asof=1995/11/07>
  // strange but true:  copying the scalar String variable into
  // the 0th element of the vector ensures that linefeeds are
  // preserved.  
  // </todo>

  Vector <String> descriptions (2);
  descriptions (0) = stylesDescription;

  glishBus->postEvent ("queryStyles_result", descriptions);
  return True;
  
} // queryStyles 
//#--------------------------------------------------------------------------
Bool showMarker (GlishSysEvent &event, void *)
{
  GlishValue glishValue = event.val ();
  GlishSysEventSource *glishBus =  event.glishSource ();     

    // does the event contain a record?
  if (glishValue.type () == GlishValue::RECORD)  {
    glishBus->postEvent ("showMarker_result", 
                         "showMarker error: argument not an array");
    return True;
    }

  GlishArray glishArray = glishValue;
  if (glishArray.elementType() != GlishArray::STRING) {
    glishBus->postEvent ("showMarker_result", 
                         "showMarker error: argument is not a string");
    }
  
  String newMarkers = glishStringArrayToSingleString (glishArray);
  const char* newMarkersC = newMarkers.chars();
  if (!strcmp (newMarkersC, "x")) {
     plot_->enableXMarker (1);
     plot_->enableYMarker (0);
     }
  else if (!strcmp (newMarkersC, "y")) {
     plot_->enableXMarker (0);
     plot_->enableYMarker (1);
     }
  else if (!strcmp (newMarkersC, "xy")) {
     plot_->enableXMarker (1);
     plot_->enableYMarker (1);
     }
  else if (!strcmp (newMarkersC, "none")) {
     plot_->enableXMarker (0);
     plot_->enableYMarker (0);
     }
  else {
    glishBus->postEvent ("showMarker_result", 
      "showMarkers error: value must be one of x, y, xy, none");
    return True;
    }

  glishBus->postEvent ("showMarker_result", "ok");
  return True;
  
} // showMarker
//#--------------------------------------------------------------------------
Bool setPrinter (GlishSysEvent &event, void *)
{
  GlishValue glishValue = event.val ();
  GlishSysEventSource *glishBus =  event.glishSource ();     
  
    // does the event contain a record?
  if (glishValue.type () == GlishValue::RECORD)  {
    glishBus->postEvent ("setPrinter_result", 
                         "setPrinter error: argument not an array");
    return True;
    }

  GlishArray glishArray = glishValue;
  if (glishArray.elementType() != GlishArray::STRING) {
    glishBus->postEvent ("setPrinter_result", 
                         "setPrinter error: argument is not a string");
    }
  
  String printerName = glishStringArrayToSingleString (glishArray);

  plot_->setPrinter (printerName);
  glishBus->postEvent ("setPrinter_result", "setPrinter ok");          
  return True;

}
//#--------------------------------------------------------------------------
Bool printToPrinter (GlishSysEvent &event, void *)
{
  GlishValue glishValue = event.val ();
  GlishSysEventSource *glishBus =  event.glishSource ();     

  Bool success = plot_->printGraphToPrinter ();
  
  if (success)
     glishBus->postEvent ("print_result", "print ok");
  else
     glishBus->postEvent ("print_result", "print failed");

  return True;

}
//#--------------------------------------------------------------------------
Bool printToFile (GlishSysEvent &event, void *)
{
  GlishValue glishValue = event.val ();
  GlishSysEventSource *glishBus =  event.glishSource ();     

    // does the event contain a record?
  if (glishValue.type () == GlishValue::RECORD)  {
    glishBus->postEvent ("printToFile_result", 
                         "printToFile error: argument not an array");
    return True;
    }

  GlishArray glishArray = glishValue;
  if (glishArray.elementType() != GlishArray::STRING) {
    glishBus->postEvent ("printToFile_result", 
                         "printToFile error: argument is not a string");
    }
  
  String filename = glishStringArrayToSingleString (glishArray);

  Bool success = plot_->printGraphToFile (filename);

  if (success)
     glishBus->postEvent ("printToFile_result", "printToFile ok");
  else
     glishBus->postEvent ("printToFile_result", "printToFile failed");

  return True;

}
//#--------------------------------------------------------------------------
String glishStringArrayToSingleString (GlishArray stringArray)
/* a simple utility function, to correct glish's (intentional?) division
 * of multi-word strings into an array of strings, one word per array
 * element.
 */
{

  uInt numberOfElements = stringArray.nelements ();
  Vector <String> compoundString (numberOfElements);

  if (numberOfElements == 0)
    return "";
  
  stringArray.get (compoundString);

  String result = "";
  for (uInt i=0; i < numberOfElements; i++) {
    result += compoundString (i);
    if (i < numberOfElements-1) result += " ";  // add back the white space
    }

  return result;

} // glishStringArrayToSingleString
//#---------------------------------------------------------------------------
void buildGUI (Widget topLevel, uInt, uInt, GlishSysEventSource &)
/* glishStream is here so that it can be passed into Xt callback functions,
 * and those functions can initiate glish events.
 */
{
  plot_ = new PGPlot1d (topLevel);

} // buildGUI
//----------------------------------------------------------------------------
Bool catchAllHandler (SysEvent &event, void *)
{
  cout << "gplot1d catch-all handler invoked..." << endl;

  if (event.group () == SysEvent::GlishGroup) {       
    GlishSysEvent &glishEvent = (GlishSysEvent &) event;
    GlishSysEventSource *src =  glishEvent.glishSource ();   
    src->postEvent ("unknown", "not handled");
    return True;                                    
    }                                                

  return False;                                    
}                                                    
//---------------------------------------------------------------------------
