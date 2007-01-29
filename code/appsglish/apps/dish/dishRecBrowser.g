# recordbrowser.g: for browsing a glish record
#------------------------------------------------------------------------------
#   Copyright (C) 1997,1998,1999,2000
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
#    $Id: dishRecBrowser.g,v 19.1 2004/08/25 01:08:34 cvsmgr Exp $
#
#------------------------------------------------------------------------------
pragma include once;

#include "oldsditerator.g";
include "dishArrBrowser.g";
include 'widgetserver.g';
include "note.g";

const recordBrowser := function(ref theRecord, name='', topFrame=F, 
				hasDismissButton=T, widgetset=dws)
{
    if (!widgetset.have_gui()) {
	return throw('No GUI is available, check your DISPLAY environment variable.',
		     origin='recordBrowser');
    }
    widgetset.tk_hold();

    self := [=];
    public := [=];

    self.rec := ref theRecord;

    # these seem to work 
    self.textLineHeight := 24;
    self.buttonLineHeight := 24;
    self.charWidth := 12;
    self.maxVisibleWidth := 15*self.charWidth + 4;
    # arrays larger than this many elements appear as buttons which
    # launch an array browser
    self.maxNonBrowsedArray := 3;

    self.yoffset :=  4;

    self.fieldCanvasVisibleHeight := 5*self.buttonLineHeight;
    self.fieldCanvasVisibleWidth := 1;
    self.valueCanvasVisibleHeight := 5*self.buttonLineHeight;
    self.valueCanvasVisibleWidth := 1;

    self.fieldCanvasVirtualHeight := 5*self.buttonLineHeight;
    self.fieldCanvasVirtualWidth := 1;
    self.valueCanvasVirtualHeight := 5*self.buttonLineHeight;
    self.valueCanvasVirtualWidth := 1;

    self.fieldCanvas := F;
    self.topFrame := topFrame;
    if (is_boolean(self.topFrame)) {
	self.topFrame := widgetset.frame();
    } 
    self.name := as_string(spaste(name));
    self.m := message(self.topFrame, self.name);
    self.yScrollFrame := widgetset.frame(self.topFrame, side='left',borderwidth=0);
    self.textFrame := widgetset.frame(self.yScrollFrame, side='left',borderwidth=0);

    self.fieldFrame := widgetset.frame(self.textFrame, side='top',borderwidth=0);
    self.fieldLabel := widgetset.label(self.fieldFrame,"Field");
    self.fieldCanvasFrame := widgetset.frame(self.fieldFrame, borderwidth=0);
    self.fieldCanvas := F;
    self.fieldXScroll := widgetset.scrollbar(self.fieldFrame,orient='horizontal');
    self.valueFrame := widgetset.frame(self.textFrame, side='top',borderwidth=0);
    self.valueLabel := widgetset.label(self.valueFrame,"Value");
    self.valueCanvasFrame := widgetset.frame(self.valueFrame, borderwidth=0);
    self.valueCanvas := F;
    self.valueXScroll := widgetset.scrollbar(self.valueFrame,orient='horizontal');

    # add the y scroll bar

    self.yScrollbarFrame := widgetset.frame(self.yScrollFrame, expand='y');
    self.topPad := widgetset.frame(self.yScrollbarFrame, expand='none', width=23, height=23);
    self.yScrollbar := widgetset.scrollbar(self.yScrollbarFrame);
    self.bottomPad := widgetset.frame(self.yScrollbarFrame, expand='none', width=23, height=23,relief='groove');

    # and a dismiss button on the bottom
    if (hasDismissButton) {
	self.dismissBox := widgetset.frame(self.topFrame,side='right',borderwidth=0);
	self.dismissButton := widgetset.button(self.dismissBox,'Dismiss',type='dismiss');
	whenever self.dismissButton->press do 
	{
	    public.dismiss();
	}
    }

    self.isactive := T;

    self.arrayButton := function(ref theArray, buttonLabel, arrayName, theCanvas, xPos, yPos)
    {
	self := [=];
	public := [=];

	self.value := ref theArray;
	self.arrayName := arrayName;
	self.frame := theCanvas->frame(xPos,yPos);
	self.button := widgetset.button(self.frame, buttonLabel, pady=1,borderwidth=1);
	self.browser := F;
	whenever self.button->press do {
	    deactivate;
	    if (is_boolean(self.browser) || !self.browser.isactive()) {
		self.browser := dishArrBrowser(self.value, self.arrayName);
	    } else {
		self.browser.dismiss();
		self.browser := F;
	    }
	    activate;
	}

	public.dismiss := function() 
	{ 
	    wider self; 
	    if (!is_boolean(self.browser) && self.browser.isactive()) self.browser.dismiss();
	    self.frame := F; 
	}

	public.setValue := function(ref newValue, newLabel)
	{
	    wider self;
	    self.value := ref newValue;
	    
	    if (!is_boolean(self.browser) && self.browser.isactive())
		self.browser.setValue(self.value);
	    self.button->text(newLabel);
	}

#	public.self := function() { wider self; return self;}

	return public;
    }
    
    self.recordButton := function(ref theArray, buttonLabel, recordName, theCanvas, xPos, yPos)
    {
	self := [=];
	public := [=];

	self.value := ref theArray;
	self.recordName := recordName;
	self.frame := theCanvas->frame(xPos,yPos);
	self.button := widgetset.button(self.frame, buttonLabel, pady=1,borderwidth=1);
	self.browser := F;
	whenever self.button->press do {
	    deactivate;
	    wider self;
	    if (is_boolean(self.browser) || !self.browser.isactive()) {
		self.browser := recordBrowser(self.value, self.recordName);
	    } else {
		self.browser.dismiss();
		self.browser := F;
	    }
	    activate;
	}

	public.dismiss := function() 
	{ 
	    wider self;
	    if (!is_boolean(self.browser) && self.browser.isactive()) self.browser.dismiss();
	    self.frame := F; 
	}

	public.setValue := function(ref newValue, newLabel)
	{
	    wider self;
	    self.value := ref newValue;
	    
	    if (!is_boolean(self.browser) && self.browser.isactive())
		self.browser.setValue(self.value);
	    self.button->text(newLabel);
	}

#	public.self := function() { wider self; return self;}
	return public;
    }

    self.field := function(theFieldName, ref theFieldValue, ypos, ref parent)
    {
	self := [=];
	public := [=];

	self.name := theFieldName;
	self.value := ref theFieldValue;

	self.parent := ref parent;
	self.currValueWidth := 0;

	self.ysize := parent.textLineHeight;

	self.valueText := function(theValue)
	{
	    wider self;
	    result := "";
	    if (self.isButton && !self.isArray) result := "RECORD";
	    else if (self.isArray) {
		result := 'ARRAY : shape = ';
		if (!is_boolean(theValue::shape)) {
		    result := spaste(result,as_string(theValue::shape));
		} else {
		    result := spaste(result,len(theValue));
		}
	    } else {
		result := spaste(as_string(theValue));
	    }
	    return result;
	}

	self.setSize := function(valueLength, ref parent)
	{
	    wider self;
	    valueWidth := valueLength*parent.charWidth + 4;
	    if (self.isButton) {
		# add x padding in button
		valueWidth +:= 7*parent.charWidth;
		self.ysize := parent.buttonLineHeight;
	    }
	    if (parent.valueCanvasVisibleWidth < parent.maxVisibleWidth && 
		valueWidth > parent.valueCanvasVisibleWidth) {
		val parent.valueCanvasVisibleWidth := min(valueWidth, parent.maxVisibleWidth);
		parent.valueCanvas->width(parent.valueCanvasVisibleWidth);
	    }
	    if (valueWidth > parent.valueCanvasVirtualWidth) {
		val parent.valueCanvasVirtualWidth := valueWidth;
		parent.valueCanvas->region(0,0,parent.valueCanvasVirtualWidth,
					   parent.valueCanvasVirtualHeight);
	    }
	    self.currValueWidth := valueWidth;
	}
	    
	self.init := function(ref parent) {
	    wider self;
	    fieldLength := strlen(self.name)*parent.charWidth + 4;
	    if (parent.fieldCanvasVisibleWidth < parent.maxVisibleWidth && 
		fieldLength > parent.fieldCanvasVisibleWidth) {
		val parent.fieldCanvasVisibleWidth := min(fieldLength, parent.maxVisibleWidth);
		parent.fieldCanvas->width(parent.fieldCanvasVisibleWidth);
	    }
	    if (fieldLength > parent.fieldCanvasVirtualWidth) {
		val parent.fieldCanvasVirtualWidth := fieldLength;
		parent.fieldCanvas->region(0,0,parent.fieldCanvasVirtualWidth,
					   parent.fieldCanvasVirtualHeight);
	    }
	    self.fieldFrame := parent.fieldCanvas->frame(2,ypos,borderwidth=0);
	    self.fieldLabel := widgetset.label(self.fieldFrame,self.name);
	    self.isArray := !is_record(self.value) && len(self.value) > 3;
	    self.isButton := is_record(self.value) ||  self.isArray;
	    valueText := self.valueText(self.value);
	    valueLength := strlen(valueText) + 1;
	    self.setSize(valueLength, parent);
	    if (self.isButton) {
		if (self.isArray) {
		    self.valueEntry := parent.arrayButton(self.value,valueText,spaste(parent.name,".",self.name),
							  parent.valueCanvas,2,ypos-4);
		} else {
		    self.valueEntry:= parent.recordButton(self.value,valueText,spaste(parent.name,".",self.name),
							  parent.valueCanvas,2,ypos-4);
		}
	    } else {
		self.valueFrame := parent.valueCanvas->frame(2,ypos,borderwidth=0);
		self.valueEntry := widgetset.entry(self.valueFrame,width=valueLength,relief='flat',borderwidth=0);
		self.setValue(self.value, valueText, valueLength);
	    }
	}

	self.setValue := function(ref newValue, newValueText, newWidth) 
	{
	    if (is_agent(self.valueEntry)) {
		# this must be an actual entry field
		self.valueEntry->disabled(F);
		if (newWidth != self.currValueWidth) {
		    self.setSize(newWidth, self.parent);
		    self.valueEntry->width(newWidth);
		}
		self.valueEntry->delete("start","end");
		self.valueEntry->insert(newValueText);
		self.valueEntry->disabled(T);
	    } else {
		# its either a record or array browser
		self.valueEntry.setValue(newValue, newValueText);
	    }
	}

	self.init(parent);

	public.ysize := function() { wider self; return self.ysize;}
	public.setValue := function(ref newValue)
	{
	    wider self;
	    self.value := ref newValue;
	    valueText := self.valueText(self.value);
	    valueLength := strlen(valueText) + 1;
	    self.setValue(newValue, valueText, valueLength);
	}


	public.dismiss := function()
	{
	    wider self;
	    self.parent := F;
	    if (self.isButton) self.valueEntry.dismiss();
	    self.fieldFrame := F;
	    self.valueFrame := F;
	}

#	public.self := function() { wider self; return self;}
	return public;
    }

    self.fields := [=];
 
    self.initCanvas := function(theRecord)
    {
	wider self;
	if (!is_record(theRecord)) fail;

	# wipe out any fields 
	for (i in field_names(self.fields)) self.fields[i].dismiss();
	val self.fields := [=];

	# this should kill any existing canvas
	val self.fieldCanvas := F;
	val self.valueCanvas := F;
	
	# and reset the y offset to the top
	self.yoffset :=  4;
	# and the widths to their default values
	self.fieldCanvasVisibleWidth := 1;
	self.valueCanvasVisibleWidth := 1;
	self.fieldCanvasVirtualWidth := 1;
	self.valueCanvasVirtualWidth := 1;
	
	# set some sizes
	nlines := len(field_names(theRecord));
	visibleLines := nlines;
	if (nlines > 5) visibleLines := 5;

	self.fieldCanvasVisibleHeight := visibleLines*self.buttonLineHeight;
	self.valueCanvasVisibleHeight := visibleLines*self.buttonLineHeight;
	
	self.fieldCanvasVirtualHeight := nlines*self.buttonLineHeight;
	self.valueCanvasVirtualHeight := nlines*self.buttonLineHeight;
    
	self.fieldCanvas := widgetset.canvas(self.fieldCanvasFrame, width=self.fieldCanvasVisibleWidth,
				   height=self.fieldCanvasVisibleHeight, 
				   region=[0,0,self.fieldCanvasVirtualWidth,self.fieldCanvasVirtualHeight],
				   borderwidth=0,relief='flat');
	self.valueCanvas := widgetset.canvas(self.valueCanvasFrame, width=self.valueCanvasVisibleWidth,
				   height=self.valueCanvasVisibleHeight, 
				   region=[0,0,self.valueCanvasVirtualWidth,self.valueCanvasVirtualHeight],
				   borderwidth=0,relief='flat');
	whenever self.yScrollbar->scroll do
	{
	    self.fieldCanvas->view($value);
	    self.valueCanvas->view($value);
	}

	whenever self.fieldCanvas->yscroll, self.valueCanvas->yscroll do
	{
	    self.yScrollbar->view($value);
	}

	whenever self.fieldXScroll->scroll do 
	{
	    self.fieldCanvas->view($value);
	}

	whenever self.fieldCanvas->xscroll do
	{
	    self.fieldXScroll->view($value);
	}

	whenever self.valueXScroll->scroll do
	{
	    self.valueCanvas->view($value);
	}

	whenever self.valueCanvas->xscroll do
	{
	    self.valueXScroll->view($value);
	}

	# and finally set the values
	self.fields := [=];
	for (i in field_names(theRecord)) {
	    self.fields[i] := self.field(i, theRecord[i], self.yoffset, self);
	    self.yoffset +:= self.fields[i].ysize();
	}
    }

    self.initCanvas(theRecord);

    public.dismiss := function() 
    {
	wider self;
	for (i in field_names(self.fields)) self.fields[i].dismiss();
	self.topFrame := F;
	self.isactive := F;
    }

    public.isactive := function()
    {
	wider self;
	return self.isactive;
    }

    public.setValue := function(ref newValue)
    {
	wider self;
	if (!is_record(newValue)) fail;

	names := field_names(newValue);
	oldnames := field_names(self.rec);
	self.rec := ref newValue;
	if (len(names) != len(oldnames) || names != oldnames) {
	    # need a completely new one
	    self.initCanvas(self.rec);
	} else {
	    # we can just use the existing fields
	    for (i in field_names(self.fields)) {
		self.fields[i].setValue(self.rec[i]);
	    }
	}
    }

#    public.self := function() { wider self; return self; }
    widgetset.tk_release();

    return public;
}
