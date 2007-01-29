# arraybrowser.g
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
#   $Id: arraybrowser.g,v 19.1 2004/08/25 01:18:07 cvsmgr Exp $
#
#------------------------------------------------------------------------------
pragma include once


# introduction
# -------------
# a graphical user interface for 1-d and 2-d glish arrays, with
# scrollbars as needed
#
# design notes:
# -------------
# nothing special
#
# implementation notes
# --------------------
# this uses a tk canvas, some scrollbars, a column of row numbers in a tall 
# skinny canvas.  
# 
# see also
# --------
# the other browsers:  tablebrowser, keywordbrowser
#
# todo list
# ---------
#  1. add column formatting
#  2. provide support for 3 and more dimensions
#  3. use busy cursor when appropriate, as in loading large arrays
#  4. allow user to switch back and forth between matrix and x-y
#     display
#  5. allow user to change fonts and colors.
#------------------------------------------------------------------------------
abDefaults := [=];
abDefaults.visibleCanvasWidth := 400; 
abDefaults.visibleCanvasHeight := 400; 
#------------------------------------------------------------------------------
arrayBrowser := function (ref theArray, name='')
{
    self := [=];
    public := [=];

    self.abGui := [=];

    self.abGui.fonts := [=];
    self.abGui.menubar := [=];

    self.abGui.fonts.buttons := "-adobe-courier-bold-r-normal--12-*";
    self.abGui.fonts.cells := "-adobe-courier-medium-r-normal--12-*";
    self.abGui.fonts.rowTitles := "-adobe-courier-medium-r-normal--12-*";

    self.abGui.rowTitlesWidth := 44;
    self.abGui.columnTitlesHeight := 20;

    self.abGui.lineToLineHeight := 20;
    self.abGui.lineHeight := 10;

    # in pixels. todo: calculate from font and from number of characters
    # needed to portray one element of the array's base type
    if (is_complex (theArray))
	self.abGui.columnWidth := 170;
    else
	self.abGui.columnWidth := 90;

    self.setShape := function(ref theArray)
    {
	wider self;
	# it seems that vectors sometimes have no shape attribute, and sometimes do
	# allow for both possibilities here
	if (is_boolean (theArray::shape)) {
	    self.abGui.dimension := 1;
	    self.abGui.numberOfRows := len (theArray);
	    self.abGui.numberOfColumns := 1;
	}
	else { # array has a shape attribute
	    self.abGui.arrayShape := theArray::shape;
	    self.abGui.dimension := len (self.abGui.arrayShape);
	    if (self.abGui.dimension == 1) {
		self.abGui.numberOfRows := len (theArray);
		self.abGui.numberOfColumns := 1;
	    }
	    else {
		# treat everything else as a simple matrix.  cubes & better
		# deserve special treatment, and will get that later.
		self.abGui.numberOfRows := self.abGui.arrayShape [2];
		self.abGui.numberOfColumns := self.abGui.arrayShape [1];
	    }
	}

	#print 'array has shape: ', self.abGui.numberOfRows, self.abGui.numberOfColumns;
	#print 'dimension:       ', self.abGui.dimension;

	self.abGui.virtualCanvasHeight := self.abGui.numberOfRows * self.abGui.lineToLineHeight;
	self.abGui.virtualCanvasWidth  := self.abGui.numberOfColumns * self.abGui.columnWidth;

	if (self.abGui.virtualCanvasWidth > abDefaults.visibleCanvasWidth)
	    self.abGui.visibleCanvasWidth := abDefaults.visibleCanvasWidth;
	else
	    self.abGui.visibleCanvasWidth := self.abGui.virtualCanvasWidth;

	if (self.abGui.virtualCanvasHeight > abDefaults.visibleCanvasHeight)
	    self.abGui.visibleCanvasHeight := abDefaults.visibleCanvasHeight;
	else
	    self.abGui.visibleCanvasHeight := self.abGui.virtualCanvasHeight;
    }
    self.setShape(theArray);

    self.abGui.toplevel := frame (title=name);

    public.dismiss := function() 
    { 
	wider self; 
	val self.abGui.toplevel := F; 
	self.isactive := F;
    }

    abCreateMenuBar (self.abGui, public.dismiss);
    abCreateSpreadsheetAndScrollbars (self.abGui);

    if (self.abGui.dimension == 1)
	displayVector (self.abGui, theArray);
    else if (self.abGui.dimension == 2)
	displayMatrix (self.abGui, theArray);

    self.isactive := T;

    public.isactive := function() { wider self; return self.isactive;}

    public.setValue := function(ref newValue)
    {
	wider self;
	oldncols := self.abGui.numberOfColumns;
	self.setShape(newValue);
	if (self.abGui.numberOfColumns != oldncols) abCreateSpreatTitleWidget(self.abGui);
	abCreateSpreadsheetCanvases(self.abGui);
	abSetWhenevers(self.abGui);
	if (self.abGui.dimension == 1)
	    displayVector (self.abGui, newValue);
	else if (self.abGui.dimension == 2)
	    displayMatrix (self.abGui, newValue);
    }

    public.self := function() { wider self; return self;}
  
  return public;  
  
}# arrayBrowser
#------------------------------------------------------------------------------
abCreateTitlesWidget := function(ref abGui)
{
    abGui.columnTitlesWidget := F;
    abGui.columnTitlesWidget := canvas (abGui.columnTitlesFrame,
					    width=abGui.visibleCanvasWidth,
					    height=abGui.columnTitlesHeight,
					    region=[0,0,abGui.virtualCanvasWidth,
						    abGui.columnTitlesHeight],
					    fill='x',
					    relief='flat');
}
#------------------------------------------------------------------------------
abCreateSpreadsheetCanvases := function (ref abGui)
{
    abGui.rowTitlesWidget := F;
    abGui.rowTitlesWidget := 
	canvas (abGui.spreadsheetFrame,
		width=abGui.rowTitlesWidth,height=abGui.visibleCanvasHeight,
		region=[0,0,abGui.rowTitlesWidth,abGui.virtualCanvasHeight],
		fill='y',
		relief='flat');

    #print 'about to create canvas with dimensions', 
    #      abGui.visibleCanvasWidth, abGui.visibleCanvasHeight;

    if (abGui.numberOfColumns == 1)
	fillDirection := 'y';
    else
	fillDirection := 'both';

    abGui.canvas := F;
    abGui.canvas := canvas (abGui.spreadsheetFrame,
				width=abGui.visibleCanvasWidth,
				height=abGui.visibleCanvasHeight,
				region=[0,0,abGui.virtualCanvasWidth, 
					abGui.virtualCanvasHeight],
				background='white',
				fill=fillDirection);
}
#------------------------------------------------------------------------------
abSetWhenevers := function(ref abGui)
{
    if (is_agent(abGui.xsb)) {
	whenever abGui.canvas->xscroll do {
	    abGui.xsb->view ($value);
	}
	whenever abGui.xsb->scroll do {
	    abGui.canvas->view ($value);
	    abGui.columnTitlesWidget->view ($value);
	}
    }
    if (is_agent(abGui.ysb)) {
	whenever abGui.canvas->yscroll do {
	    abGui.ysb->view ($value);
	}
	whenever abGui.ysb->scroll do {
	    abGui.canvas->view ($value);
	    abGui.rowTitlesWidget->view ($value);
	}
    }
}
#------------------------------------------------------------------------------
abCreateSpreadsheetAndScrollbars := function (ref abGui)
{
    needHorizontalScrollbar := 
	abGui.virtualCanvasWidth > abGui.visibleCanvasWidth;
    needVerticalScrollbar := 
	abGui.virtualCanvasHeight > abGui.visibleCanvasHeight;

    if (abGui.dimension >= 2) {
	abGui.columnTitlesFrame := frame (abGui.toplevel,
					      side='left',
					      expand='x');

	abGui.topSpacerLeft := frame (abGui.columnTitlesFrame,
					  width=abGui.rowTitlesWidth+8,
					  height=abGui.columnTitlesHeight,
					  expand='none');
	abCreateTitlesWidget(abGui);

	if (needVerticalScrollbar) 
	    abGui.topSpacerRight := frame (abGui.columnTitlesFrame,
					       width=20,height=abGui.columnTitlesHeight,
					       expand='none');
    }# if dimension >= 2

    abGui.middleFrame  := frame (abGui.toplevel,
				     side='left',
				     expand='both');
    abGui.spreadsheetFrame := frame(abGui.middleFrame, side='left',expand='both',borderwidth=0);
    abCreateSpreadsheetCanvases(abGui);

    abGui.xsb := F;
    abGui.ysb := F;
    if (needHorizontalScrollbar) {
	abGui.bottomFrame := frame (abGui.toplevel,side='right',expand='x');
	abGui.bottomRightSpacer := frame (abGui.bottomFrame,expand='none',
					      width=23,height=23,relief='groove');
	abGui.xsb := scrollbar (abGui.bottomFrame, orient='horizontal');
	abGui.bottomLeftSpacer := frame (abGui.bottomFrame,expand='none',
					     width=54,height=23);
	abGui.xsb->borderwidth (1);
    }# if need scrolling in x

    if (needVerticalScrollbar) {
	abGui.ysb := scrollbar (abGui.middleFrame,orient='vertical');
	abGui.ysb->borderwidth (1);
    }# if need scrolling in y
    abSetWhenevers(abGui);
}# createSpreadsheetAndScrollbars
#----------------------------------------------------------------------------
abCreateMenuBar := function (ref abGui, dismissCallback)
{

  abGui.menubar := frame (abGui.toplevel,expand='x',side='left',
			      relief='raised');
  abGui.menubar.dismiss := 
      button (abGui.menubar,'Dismiss',relief='flat',font=abGui.fonts.buttons);
  abGui.menubar.middleSpacer := frame (abGui.menubar,width=30,height=10);

  abGui.menubar.rightSpacingFrame := frame (abGui.menubar,side='right',
						height=10);
  abGui.menubar.helpMenu := 
      button (abGui.menubar.rightSpacingFrame,'Help',relief='flat',
	      font=abGui.fonts.buttons,disabled=T);

  whenever abGui.menubar.dismiss->press do {
      dismissCallback();
  }

}
#----------------------------------------------------------------------------
displayVector := function (const abGui, vector)
{
    x := 10;
    done := 0;
    y := 20;
    max := len (vector);
    for (i in 1:max) {
	y := i * abGui.lineToLineHeight; 
	cellValueAsString := paste (vector [i]);
	abGui.canvas->text (x,y,
				 text=cellValueAsString,
				 font="-adobe-courier-medium-r-normal--12-*",
				 anchor='sw');
     
	rowNumberAsString := paste (i);
	abGui.rowTitlesWidget->text (x,y,
					  text=rowNumberAsString,
					  font="-adobe-courier-medium-r-normal--12-*",
					  anchor='sw');
    }# for i

}# displayVector
#----------------------------------------------------------------------------
displayMatrix := function (const abGui, matrix)
{
    x := 10;
    done := 0;
    y := 20;
    rows := matrix::shape [2];
    columns := matrix::shape [1];
    #print 'matrix has', rows, 'rows and', columns, 'columns';
    for (c in 1:columns) {
	for (r in 1:rows) {
	    y := r * abGui.lineToLineHeight; 
	    cellValue := matrix [c,r];
	    cellValueAsString := paste (cellValue);
	    abGui.canvas->text (x,y,
				     text=cellValueAsString,
				     font="-adobe-courier-medium-r-normal--12-*",
				     anchor='sw');
	    if (c == 1) { # draw the row titles
		rowNumberAsString := paste (r);
		abGui.rowTitlesWidget->text (x,y,
						  text=rowNumberAsString,
						  font="-adobe-courier-medium-r-normal--12-*",
						  anchor='sw');
	    }# if c == 1
	}# for r
	# draw the column titles
	columnNumberAsString := paste (c);
	abGui.columnTitlesWidget->text (x,17,
					     text=columnNumberAsString,
					     font="-adobe-courier-medium-r-normal--12-*",
					     anchor='sw');
  
	x +:= abGui.columnWidth;
    }# for c
}# displayMatrix
#----------------------------------------------------------------------------
test_arraybrowser := function () 
{
    result := [=];

    result.v := array (1:1000, 1000);
    result.vb := arrayBrowser (result.v, 'simple vector');
    # result.m := array (1:400, 10, 40);
    # result.mb := arrayBrowser (result.m, 'simple matrix');

    return ref result;
}  
#----------------------------------------------------------------------------
#t := test_arraybrowser ();
