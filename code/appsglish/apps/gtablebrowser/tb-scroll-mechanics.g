# tb-scroll-mechanics.g  (04 mar 96)
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
#   $Id: tb-scroll-mechanics.g,v 19.1 2004/08/25 01:18:39 cvsmgr Exp $
#------------------------------------------------------------------------------
#
# introduction
# ------------
# this file provides a number of global functions used by tablebrowser.g.
# tk scrollbar and canvas widgets come with a nice simple scheme for
# connecting scrollbar to the scrolled canvas.  but with the tablebrowser
# we need to control the scrolling ourselves; specifically, we need to
# lie in a convincing way about the extent and location of the current
# table rows relative to the total rows in the table.  see the 
# comments in tablebrowser.g for a good description of this deception.
# this file contains functions which make it possible to manage this
# scrolling.
# 
#
# function list
# -------------
#
#           setRowPositionsStartingRow (ref tbGui, newStartingRow)
#                    recordRowPosition (ref tbGui, rowNumber, yPixel)
#                    bottomRenderedRow (tbGui)
#                       topRenderedRow (tbGui)
#                 numberOfRenderedRows (tbGui)
#                  numberOfVisibleRows (tbGui)
#                        topVisibleRow (tbGui)
#                     bottomVisibleRow (tbGui)
#               bottomMostVisiblePixel (tbGui)
#                  topMostVisiblePixel (tbGui)
#                           currentpos (tbGui)
#      pixelsToFractionOfVirtualCanvas (tbGui, pixels)
#                             yMapping (tbGui)
#                                 info (tbGui)
#                positionVisibleCanvas (ref tbGui, fraction)
#                    positionRowTitles (tbGui, fraction)
#                                 incr (ref tbGui)
#                                 decr (ref tbGui)
#                             pagedown (ref tbGui)
#                               pageup (ref tbGui)
#                     updateYScrollbar (tbGui)
#                         scrollCanvas (ref tbGui, newTopRow)
#         rowNumberToTopCanvasPosition (tbGui,row)
#                             pageSize (tbGui)
#                        mapPixelToRow (tbGui, yPixel)
#                     mapPixelToColumn (tbGui, xPixel)
# 
#------------------------------------------------------------------------------
pragma include once

setRowPositionsStartingRow := function (ref tbGui, newStartingRow)
{
  tbGui.rowPositions.startRow := newStartingRow;
  tbGui.rowPositions.yPixels := array (tbGui.constants.rowNotRendered,
                                       tbGui.numberOfRenderedRows);
  # print 'set starting row to: ', tbGui.rowPositions.startRow;
}
#----------------------------------------------------------------------------
recordRowPosition := function (ref tbGui, rowNumber, yPixel)
{
  i := 1 + rowNumber - tbGui.rowPositions.startRow;
  #print 'recording row ', rowNumber, 'at index', i, 'at ypixel ', yPixel;
  tbGui.rowPositions.yPixels [i] := yPixel;
}
#----------------------------------------------------------------------------
bottomRenderedRow := function (tbGui)
{
  max := len (tbGui.rowPositions.yPixels);
  for (i in max:1) 
    if (tbGui.rowPositions.yPixels [i] > 0) break;

  return (i + tbGui.rowPositions.startRow - 1);

}# bottomRenderedRow
#----------------------------------------------------------------------------
topRenderedRow := function (tbGui)
{
  max := len (tbGui.rowPositions.yPixels);
  for (i in 1:max) 
    if (tbGui.rowPositions.yPixels [i] > 0) break;

  return (i + tbGui.rowPositions.startRow - 1);

}# topRenderedRow
#----------------------------------------------------------------------------
numberOfRenderedRows := function (tbGui)
{
  return (bottomRenderedRow (tbGui) - topRenderedRow (tbGui) + 1);
}
#----------------------------------------------------------------------------
numberOfVisibleRows := function (tbGui)
{
  result := bottomVisibleRow (tbGui) - topVisibleRow (tbGui) + 1;
  return result;
}
#----------------------------------------------------------------------------
topVisibleRow := function (tbGui)
{
  topPixel := topMostVisiblePixel (tbGui);
  max := len (tbGui.rowPositions.yPixels);
  for (i in 1:max) {
    # subtract off the height of the line, so that only *fully* visible rows
    # meet the test
    if ((tbGui.rowPositions.yPixels [i] - tbGui.lineHeight) >= topPixel) break;
    }
  return (i + tbGui.rowPositions.startRow - 1);
}
#----------------------------------------------------------------------------
bottomVisibleRow := function (tbGui)
{
  bottomPixel := bottomMostVisiblePixel (tbGui);

  #start := topVisibleRow (tbGui);
  start := 1;
  stop := len (tbGui.rowPositions.yPixels);

  if ((stop <= start))
    return start;

  for (i in start:stop)
    if ((tbGui.rowPositions.yPixels [i] > bottomPixel) ||
        (tbGui.rowPositions.yPixels [i] == tbGui.constants.rowNotRendered)) 
      break;

  # there are 3 possible terminating conditions to this loop, all of
  # which are based on two assumptions
  #  - we started with visible row at the top of the screen
  #  - we stepped downward through the rowPositions until we passed by
  #    the last visible row, and encountered a row *beyond* the visible
  #    canvas, or a row not rendered at all
  # terminating conditions:
  #  1. (most common) one of the rows was discovered to have a position
  #     greater than <bottomPixel>.  this means the immediately preceeding
  #     row must have been the last visible row
  #  2. we ran into a 'rowNotRendered' value, indicating that last
  #     rendered row must be the last visible row.
  #  3. we exhausted the rowPositions array without finding a pixel
  #     value greater then <bottomPixel> but also w/o running into
  #     an unrendered row.  this could only be true if the last row
  #     in the data is actually the last visible row too.

  if ((tbGui.rowPositions.yPixels [i] > bottomPixel) ||
      (tbGui.rowPositions.yPixels [i] == tbGui.constants.rowNotRendered)) {
    return (i + tbGui.rowPositions.startRow - 2);  #i-1
    }
  else if (i == stop && tbGui.rowPositions.yPixels [i] <= bottomPixel) {
    # the last row is also the last visible row
    return (i + tbGui.rowPositions.startRow - 1);
    }
  else {
    print 'Error! unsuccessful search for bottomVisibleRow';
    print 'bottomMostVisiblePixel: ', bottomMostVisiblePixel ();
    print 'rowPositions: ', tbGui.rowPositions
    return -1;
    }


}# bottomVisibleRow
#----------------------------------------------------------------------------
bottomMostVisiblePixel := function (tbGui)
# this can be high by one in some (all?) circumstances, i.e., 164 when
# it should be 163.  todo.
{
  bottomAsFractionOfVirtualCanvas := yMapping (tbGui) [2];
  bottomPixel := tbGui.virtualCanvasCoords [4] * 
                 bottomAsFractionOfVirtualCanvas;

  bottomPixelRounded := as_integer (bottomPixel + 0.5);

  return bottomPixelRounded;

}
#----------------------------------------------------------------------------
topMostVisiblePixel := function (tbGui)
{
  topAsFractionOfVirtualCanvas := yMapping (tbGui) [1];
  topPixel := tbGui.virtualCanvasCoords [4] * topAsFractionOfVirtualCanvas;

  topPixelRounded := as_integer (topPixel + 0.5);

  return topPixelRounded;

}
#----------------------------------------------------------------------------
currentpos := function (tbGui)
{ 
  return tbGui.idealCanvasPosition;
}
#----------------------------------------------------------------------------
pixelsToFractionOfVirtualCanvas := function (tbGui, pixels)
{
  return pixels / tbGui.virtualCanvasCoords [4];
}
#----------------------------------------------------------------------------
yMapping := function (tbGui)
{
  return  tbGui.canvas ['yscroll']
}
#----------------------------------------------------------------------------
tb.info := function (tbGui)
{
  print 'total rows:       ', tbGui.table.numberOfRows;
  print 'pixels:           ', topMostVisiblePixel (tbGui), ' -> ', 
                              bottomMostVisiblePixel (tbGui);
  print 'rendered rows:    ', topRenderedRow (tbGui), ' -> ', 
                              bottomRenderedRow (tbGui);
  print 'visible rows:     ', topVisibleRow (tbGui), ' -> ', 
                              bottomVisibleRow (tbGui);
  print 'canvas mapped to: ', yMapping (tbGui);
  print 'ideal origin:     ', currentpos (tbGui);
}
#----------------------------------------------------------------------------
positionVisibleCanvas := function (ref tbGui, fraction)
# what part of the virtual canvas is seen by the user?  <fraction> is
# between 0 and 1, and specifies the point in the virtual canvas which
# appears at the top of the visible canvas.  
# note that <fraction> is a request, and that the canvas may not be
# able to satisfy the request precisely.  for that reason -- and the
# creeping inexactitude it leads to -- the actual <request> is stored
# away in global state, from which it can be retrieved by the 
# 'currentpos' function
{
  #print 'positionVisibleCanvas, fraction: ', fraction
  tbGui.canvas->view ([vertical=1,op=1,newpos=fraction]);
  tbGui.idealCanvasPosition := fraction;
  #print 'currentpos (), in positionVisibleCanvas', currentpos (tbGui);
}
#----------------------------------------------------------------------------
positionRowTitles := function (tbGui, fraction)
# what part of the virtual canvas is seen by the user?  <fraction> is
# between 0 and 1, and specifies the point in the virtual canvas which
# appears at the top of the visible canvas.  
# note that <fraction> is a request, and that the canvas may not be
# able to satisfy the request precisely.  for that reason -- and the
# creeping inexactitude it leads to -- the actual <request> is stored
# away in global state, from which it can be retrieved by the 
# 'currentpos' function
{
  #print 'positionRowTitles: ', fraction;
  tbGui.rowTitlesWidget->view ([vertical=1,op=1,newpos=fraction]);
}
#----------------------------------------------------------------------------
incr := function (ref tbGui)
{
  newTopRow := topVisibleRow (tbGui) + 1;
  scrollCanvas (tbGui, newTopRow);
}
#----------------------------------------------------------------------------
decr := function (ref tbGui)
{
  newTopRow := topVisibleRow (tbGui) - 1;
  scrollCanvas (tbGui, newTopRow);
}
#----------------------------------------------------------------------------
pagedown := function (ref tbGui)
# the new position is 'one-line-height' greater than current position
{
  scrollCanvas (tbGui, topVisibleRow (tbGui) + numberOfVisibleRows (tbGui) - 1);
}
#----------------------------------------------------------------------------
pageup := function (ref tbGui)
# the new position is 'one-line-height' greater than current position
{
  scrollCanvas (tbGui, 1 + topVisibleRow (tbGui) - numberOfVisibleRows (tbGui));
}
#----------------------------------------------------------------------------
updateYScrollbar := function (tbGui)
{
  topOfThumb := (topVisibleRow (tbGui) - 1) / tbGui.table.numberOfRows;
  bottomOfThumb := bottomVisibleRow (tbGui) / tbGui.table.numberOfRows;
  tbGui.ysb->view ([topOfThumb, bottomOfThumb]);
}
#----------------------------------------------------------------------------
scrollCanvas := function (ref tbGui, newTopRow)
{
  #print 'entering scrollCanvas, newTopRow: ', newTopRow;

  if (tbGui.table.numberOfRows < 1) return;

  topvisiblerow := topVisibleRow (tbGui);
  numberofvisiblerows := numberOfVisibleRows (tbGui);
  toprenderedrow := topRenderedRow (tbGui);
  bottomrenderedrow := bottomRenderedRow (tbGui);
  numberofrenderedrows := 1 + bottomrenderedrow - toprenderedrow;
     # numberOfRenderedRows ();

  maxTopRow := tbGui.table.numberOfRows + 1 - numberofvisiblerows;

  if (newTopRow < 1) 
     newTopRow := 1;
  else if (newTopRow > maxTopRow)
     newTopRow := maxTopRow;

  if (newTopRow == topvisiblerow ) {
     #updateYScrollbar ();
     return;
     }

  deltaRows := newTopRow - topvisiblerow;

  downwardScroll := (topvisiblerow < newTopRow);
  upwardScroll := !downwardScroll;

  if (downwardScroll) {
    #can we scroll down using the currently rendered rows?
    if ((newTopRow + numberofvisiblerows  - 1) <= bottomrenderedrow) {
       newVisibleTop := newTopRow;
       }
    else {
       #must render some new data to the canvas
       #is there enough data to be rendered so that <newTopRow> can be
       #the top of a new page?  if not, the new top row must be figured
       #backwards from the bottom of the table
       if ((newTopRow + numberofrenderedrows - 1) >
            tbGui.table.numberOfRows) {
         newVirtualTop := 1 + tbGui.table.numberOfRows - numberofrenderedrows;
         if ((newTopRow + numberofvisiblerows - 1) > tbGui.table.numberOfRows)
           newVisibleTop := 1 + tbGui.table.numberOfRows - numberofvisiblerows;
         else
           newVisibleTop := newTopRow;
         #print 'numberOfRows: ', tbGui.table.numberOfRows;
         #print 'numberofrenderedrows: ', numberofrenderedrows;
         #print 'numberofvisiblerows: ', numberofvisiblerows;
         #print 'newVisibleTop: ', newVisibleTop;
         }
       else {
          newVirtualTop := newTopRow;
          newVisibleTop := newTopRow;
         }
       clearBrowserCanvas (tbGui); 
       displayData (tbGui, newVirtualTop);
       displayRowTitles (tbGui, newVirtualTop);
       }# else: must render new data
    }# if downwardScroll

  if (upwardScroll) {
    if (newTopRow <= bottomrenderedrow && newTopRow >= toprenderedrow) {
       #all necessary rows are already rendered
       newVisibleTop := newTopRow;
       }
    else {
       #must render some new data. do this so that 
       #  - newTopRow becomes the topVisibleRow
       #  - the cache extends *above* newTopRow:  since we are executing
       #    an upward scroll, the next movement is somewhat more likely to
       #    be an upward movement, so have those rows already rendered.
       newVirtualTop := newTopRow + numberofvisiblerows - 
                        numberofrenderedrows;
       newVisibleTop := newTopRow;
       clearBrowserCanvas (tbGui); 
       displayData (tbGui, newVirtualTop);
       displayRowTitles (tbGui, newVirtualTop);
       }# else: must render new data
    }# if upwardScroll

  #print 'scrollCanvas, positionVisibleCanvas to row: ',newVisibleTop;
  positionVisibleCanvas (tbGui, 
                         rowNumberToTopCanvasPosition (tbGui, newVisibleTop));
  positionRowTitles (tbGui,
                     rowNumberToTopCanvasPosition (tbGui, newVisibleTop));
  updateYScrollbar (tbGui);

}# scrollCanvas
#----------------------------------------------------------------------------
rowNumberToTopCanvasPosition := function (tbGui,row)
# calculate where on the virtual canvas to scroll to so that <row> appears
# on as the first visible row.
#
# there are two failure conditions:
# 1. if <row> is not on the current virtual canvas, then the current position
#    is simply returned.
# 
# 2. if <row> is on the virtual canvas but is too far *down* the virtual
#    canvas to be placed at the top -- that is, there aren't enough lower
#    rows on the virutal canvas to fill out the rest of the visible canvas -- 
#    then the current  position is returned.
{

  toprenderedrow := topRenderedRow (tbGui);
  bottomrenderedrow := bottomRenderedRow (tbGui);
  numberofrenderedrows := 1 + bottomrenderedrow - toprenderedrow;
  numberofvisiblerows := numberOfVisibleRows (tbGui);

  relativeRow := row - toprenderedrow;

  if (row < toprenderedrow || row > bottomrenderedrow) {
     newpos := currentpos (tbGui);
     return newpos;
     }

  if ((row + numberofvisiblerows - 1) > bottomrenderedrow) {
    newpos := currentpos (tbGui);
    return newpos;
    }

  #print 'relativeRow: ', relativeRow;
  #print 'numberofrenderedrows: ', numberofrenderedrows;

  newpos := relativeRow/numberofrenderedrows;
  #print 'newpos: ', newpos;

  return newpos;

}# rowNumberToTopCanvasPosition
#----------------------------------------------------------------------------
pageSize := function (tbGui)
{
  canvasTop    := tbGui.canvas ['yscroll'][1];
  canvasBottom := tbGui.canvas ['yscroll'][2];

  return (canvasBottom - canvasTop);

}# pageSize
#----------------------------------------------------------------------------
mapPixelToRow := function (tbGui, yPixel)
# this returns the row on the actual canvas, without correcting
# for the offset from the top of the table to the first row 
# actually displayed.  
# the caller can add 'tbGui.rowPositions.startRow -1' to get that.
# it is not done here because the caller may need the actual canvas
# row too, for instance, for drawing a selection box around a selected
# cell, which must be done to a row on the  actual canvas
# todo: add error checking
{
  for (row in 1:len (tbGui.rowPositions.yPixels))
    if (yPixel <= tbGui.rowPositions.yPixels [row]) break;

  return row;
}
#----------------------------------------------------------------------------
mapPixelToColumn := function (tbGui, xPixel)
{
  lastColumn := len (tbGui.columnPositions);

  if (xPixel < tbGui.columnPositions [1]) {
    column := 1;
    }
  else if (xPixel >= tbGui.columnPositions [lastColumn])
    column := lastColumn;
  else {
    for (i in 1:len (tbGui.columnPositions)) {
      if (xPixel <  tbGui.columnPositions [i]) break;
      }
    column := i - 1;
    }# else

  return column;
}
#----------------------------------------------------------------------------
