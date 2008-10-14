# keywordbrowser.g
#------------------------------------------------------------------------------
#   Copyright (C) 1995,1996,1997,1998
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
#   $Id: keywordbrowser.g,v 19.1 2004/08/25 01:18:24 cvsmgr Exp $
#
#------------------------------------------------------------------------------

pragma include once

# introduction
# ------------
# the keyword browser is a very simple combination of a canvas widget,
# a column of row numbers, and a menubar.  keywords are simple pairs:
# there is a keyword (which is a string), and a value (which may be any
# of the types that can appear in an aips++ table:  strings, numbers,
# arrays of strings or numbers, and tables.  an aips++ table may have any 
# number of these pairs
#
# design notes:
# -------------
# the only thing the least bit fancy about this browser is the handling
# of mousedown events.   if one of these occurs in a cell that contains
# a browsable value (an array, keywords, or a table) then the appropriate
# browser is popped up to look at it
#
# implementation notes
# --------------------
#  n/a
# 
# see also
# --------
# the other browsers
#
# todo list
# ---------
#  n/a
# 
# function list
# -------------
#                      keywordBrowser (keywordSet, name='')
#   createKwbSpreadsheetAndScrollbars (ref kwbGui)
#                    kwbCreateMenuBar (ref kwbGui)
#                     displayKeywords (ref kwbGui, keywords)
#         setupKwbCanvasEventHandling (ref kwbGui)
#            handleKwbCanvasMousedown (ref kwbGui, eventValue)
#                    mapKwbPixelToRow (kwbGui, yPixel)
#                 mapKwbPixelToColumn (kwbGui, xPixel)
#                    highlightKwbCell (ref kwbGui, column, row)
#                             testkwb ()
#
#------------------------------------------------------------------------------
kwbDefaults := [=];
kwbDefaults.visibleCanvasWidth := 400; 
kwbDefaults.visibleCanvasHeight := 100; 
kwbDefaults.maxSizeArrayForDirectDisplay := 8;

kwbDefaults.fonts := [=];
kwbDefaults.fonts.buttons := "-adobe-courier-bold-r-normal--12-*";
kwbDefaults.fonts.cells := "-adobe-courier-medium-r-normal--12-*";
kwbDefaults.fonts.rowTitles := "-adobe-courier-medium-r-normal--12-*";
#------------------------------------------------------------------------------
keywordBrowser := function (keywordSet, name='')
{
  kwbGui := [=];
  # global kwbGui;  #temporary
  kwbGui.toplevel := frame (title=name);
  kwbGui.menubar := kwbCreateMenuBar (kwbGui);

  kwbGui.keywords := keywordSet;

  kwbGui.numberOfRows := len (keywordSet);

  kwbGui.rowTitlesWidth := 44;
  kwbGui.columnTitlesHeight := 20;

  kwbGui.columnWidth := 160;
  kwbGui.numberOfColumns := 2;

  kwbGui.lineToLineHeight := 20;
  kwbGui.lineHeight := 10;

  kwbGui.virtualCanvasHeight := kwbGui.numberOfRows * kwbGui.lineToLineHeight;
  kwbGui.virtualCanvasWidth  := kwbDefaults.visibleCanvasWidth;
  kwbGui.visibleCanvasWidth :=  kwbDefaults.visibleCanvasWidth;

  if (kwbGui.virtualCanvasHeight > kwbDefaults.visibleCanvasHeight)
    kwbGui.visibleCanvasHeight := kwbDefaults.visibleCanvasHeight
  else
    kwbGui.visibleCanvasHeight := kwbGui.virtualCanvasHeight;

  kwbGui.workArea := createKwbSpreadsheetAndScrollbars (kwbGui);

    # a selected cell is marked by a Tk canvas rectangle, which is
    # usually deleted when another cell is selected.  by holding
    # onto the string returned by the canvas for the rectangle,
    # it can be easily deleted before the next is drawn.
    # <todo asof=1996/03/05> 
    #   <li> support multiple selections
    # </todo>
  kwbGui.currentSelectionTag := F;

  whenever kwbGui.menubar.dismissButton->press do {
    kwbGui.toplevel := F;
    }

  displayKeywords (kwbGui, keywordSet);
  setupKwbCanvasEventHandling (kwbGui);

  return ref kwbGui;
}
#------------------------------------------------------------------------------
createKwbSpreadsheetAndScrollbars := function (ref kwbGui)
{
  needVerticalScrollbar := 
       kwbGui.virtualCanvasHeight > kwbGui.visibleCanvasHeight;
  needHorizontalScrollbar := 
       kwbGui.virtualCanvasWidth > kwbGui.visibleCanvasWidth;

  workArea := [=];


  workArea.middleFrame  := frame (kwbGui.toplevel,
                                  side='left',
                                  expand='both');


   workArea.rowTitlesWidget := 
     canvas (workArea.middleFrame,
             width=kwbGui.rowTitlesWidth,height=kwbGui.visibleCanvasHeight,
             region=[0,0,kwbGui.rowTitlesWidth,kwbGui.virtualCanvasHeight],
             fill='y',
             relief='flat');

    if (kwbGui.numberOfColumns == 1)
      fillDirection := 'y'
   else
      fillDirection := 'both';

   workArea.canvas := canvas (workArea.middleFrame,
                           width=kwbGui.visibleCanvasWidth,
                           height=kwbGui.visibleCanvasHeight,
                           region=[0,0,kwbGui.virtualCanvasWidth, 
                                  kwbGui.virtualCanvasHeight],
                          background='white',
                          fill=fillDirection);

  if (needHorizontalScrollbar) {
    workArea.xsb := scrollbar (kwbGui.toplevel, orient='horizontal');
    }# if need scrolling in x

  if (needVerticalScrollbar) {
    workArea.ysb := scrollbar (workArea.middleFrame,orient='vertical');
    whenever workArea.canvas->yscroll do {
      workArea.ysb->view ($value);
      }
    whenever workArea.ysb->scroll do {
      workArea.canvas->view ($value)
      workArea.rowTitlesWidget->view ($value);
      }
    }# if need scrolling in y

  return workArea;

}# createKwbSpreadsheetAndScrollbars
#----------------------------------------------------------------------------
kwbCreateMenuBar := function (ref kwbGui)
{

  menubar := [=];
  menubar := frame (kwbGui.toplevel,expand='x',side='left',
                    relief='raised',height=35);
  menubar.dismissButton := 
    button (menubar,'Dismiss',relief='flat',font=kwbDefaults.fonts.buttons);
  menubar.middleSpacer := frame (menubar,width=30,height=10);

  menubar.rightSpacingFrame := frame (menubar,side='right',height=10);
  menubar.helpMenuButton := 
    button (menubar.rightSpacingFrame,'Help',relief='flat',
            font=kwbDefaults.fonts.buttons,disabled=T);

  return menubar;

}# kwbCreateMenuBar
#----------------------------------------------------------------------------
displayKeywords := function (ref kwbGui, keywords)
{
  x0 := 10;
  x1 := 160;
  done := 0;
  y := 20;
  maxRows := len (keywords);

  kwbGui.columnOrigins := array (0.0, 2);
  kwbGui.columnOrigins [1] := x0;
  kwbGui.columnOrigins [2] := x1;

  kwbGui.rowOrigins := array (0.0, maxRows);

  for (row in 1:maxRows) {
    y := row * kwbGui.lineToLineHeight; 
    fieldName := field_names (keywords) [row];
    fieldValue := keywords [fieldName];
    if (len (fieldValue) > kwbDefaults.maxSizeArrayForDirectDisplay) { 
         # we have an array too big to display directly
       arrayBaseType := type_name (fieldValue);  
       if (!is_integer (fieldValue::shape)) {
           # vectors don't always have a shape attribute, so create a facsimile
          shapeOfArray := spaste ('[',len (fieldValue), '] ');
          }
        else { # use the existing shape attribute
          if (len (fieldValue::shape) == 1) #add brackets for consistent display
             shapeOfArray := spaste ('[',fieldValue::shape,'] ');
          else
             shapeOfArray := spaste (fieldValue::shape);
          }
       fieldValueAsString := 
          spaste (shapeOfArray, arrayBaseType);
       } 
    else {# a scalar, or a short vector: display directly
       fieldValueAsString := paste (fieldValue);
       }
    kwbGui.rowOrigins [row] := y;
    kwbGui.workArea.canvas->text (x0,y,
                             text=fieldName,
                             font="-adobe-courier-medium-r-normal--12-*",
                             anchor='sw');
    kwbGui.workArea.canvas->text (x1,y,
                             text=fieldValueAsString,
                             font="-adobe-courier-medium-r-normal--12-*",
                             anchor='sw');
     
    rowNumberAsString := paste (row);
    kwbGui.workArea.rowTitlesWidget->text (x0,y,
                                  text=rowNumberAsString,
                                  font="-adobe-courier-medium-r-normal--12-*",
                                  anchor='sw');
   }# for i

}# displayVector
#----------------------------------------------------------------------------
setupKwbCanvasEventHandling := function (ref kwbGui)
{
  kwbGui.workArea.canvas->bind ('<Button-1>','mousedown');
  whenever kwbGui.workArea.canvas->mousedown do 
    handleKwbCanvasMousedown (kwbGui, $value);
}
#----------------------------------------------------------------------------
handleKwbCanvasMousedown := function (ref kwbGui, eventValue)
{
  #print 'mousedown: ', eventValue;
  #print 'columnOrigins: ', kwbGui.columnOrigins;

  xPixel := eventValue.world [1];
  yPixel := eventValue.world [2];

  row := mapKwbPixelToRow (kwbGui, yPixel);
  column := mapKwbPixelToColumn (kwbGui, xPixel);

  #print 'event occurred in column', column, 'row', row;
  highlightKwbCell (kwbGui, column, row);

  fieldName := field_names (kwbGui.keywords) [row];
  fieldValue := kwbGui.keywords [fieldName];

  if (len (fieldValue) > 1) { # it is an array 
    junk := arrayBrowser (fieldValue, fieldName);
    }
    #if tableExists is passed a number, it will try to construe it as a table
    #id so make sure it's a string before using the lazy tableExists strategy
  else if (is_string (fieldValue) && tableExists (fieldValue)) {
    junk := browse (fieldValue)
    }
  #else: there's nothing else to do here

}# handleKwbCanvasMousedown
#----------------------------------------------------------------------------
mapKwbPixelToRow := function (kwbGui, yPixel)
{
  for (i in 1:kwbGui.numberOfRows)
    if (yPixel < kwbGui.rowOrigins [i]) break;

  return i;
}
#----------------------------------------------------------------------------
mapKwbPixelToColumn := function (kwbGui, xPixel)
{
  if (xPixel < kwbGui.columnOrigins [2])
    return 1;
  else
    return 2;
}
#----------------------------------------------------------------------------
highlightKwbCell := function (ref kwbGui, column, row)
{
  if (is_string (kwbGui.currentSelectionTag)) {
     kwbGui.workArea.canvas->delete (kwbGui.currentSelectionTag);
     kwbGui.currentSelectionTag := F;
     }

  leftX := kwbGui.columnOrigins [column];

  if (column == kwbGui.numberOfColumns)
     rightX := kwbGui.virtualCanvasWidth - 2;
  else
     rightX := kwbGui.columnOrigins [column+1];
  
  if (row == 1)
     topY := 1;
  else
     topY := kwbGui.rowOrigins [row-1];

  bottomY := kwbGui.rowOrigins [row];

  kwbGui.currentSelectionTag := 
      kwbGui.workArea.canvas->rectangle (leftX, topY, rightX, bottomY);

}
#----------------------------------------------------------------------------
testkwb := function ()
{
  keywords := [CHAN_BW=250000, 
               FILE_MJD=49973.3, 
               NO_ANT=9,
               NO_BAND=8,
               NO_CHAN=16,
               NO_STKD=1,
               OBSCODE='RDGEO',
               RDATE=25/07/95,
               REF_FREQ=8.10599e+09,
               REF_PIXL=1,
               STK_1=-1,
               TABREV=2,
               simpleArray=[1:10],
               bigMatrix=array (1+1i,30,30)]

  return  keywordBrowser (keywords, "test");

}
#----------------------------------------------------------------------------
