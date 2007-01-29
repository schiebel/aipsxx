# oldcombobox.g: General-purpose oldcombobox widget.
# -----------------------------------------------------------------------------
#   Copyright (C) 1996-1998
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
#    $Id: oldcombobox.g,v 19.2 2004/08/25 02:00:02 cvsmgr Exp $
#
#------------------------------------------------------------------------------
# oldcombobox
#
# design notes:
# -------------
# the main goal is to provide something like the oldcombobox widget that first
# appeared with windows 3.1.  alan cooper's book "about face", p 392 give
# a good description.  contrary to his claim that comboboxes are no good
# for multiple selection, i have labored to make multiple selection
# work here.  the tk listbox is put into multiple selection mode, and all
# of those selections are displayed in the text entry widget.
#
# Harvey Liszt specified the operation for the combobox, to support data
# selection for the first aips++ singledish application (prototype?) sdavg.g.
# in addition to requiring multiple selection, he also asked for the
# 'enableButton' which allows the averager to ignore any combobox that
# the user wishes to exclude on a particular data selection operation.
#
# I have changed the comboboxes so that multiple selection is no longer
# the default.  (In fact, only single selection currently works;
# multiple selection is a bit broken.)  I've also set them up so that
# the list boxes can fill either bottom-up (most recent entry on top) or
# top-down (most recent entry at bottom).  Scrolling/viewing behavior
# changes according to mode so that the most recently selected item
# stays selected and in view.  (JAU: 17JAN97)
#
# I've made other changes that I need to document, such as the optional
# useDisplayAllButton and reverseFill options.  (JAU: 17JAN97)
#
# implementation notes
# --------------------
#   - please begin by reading the description in guicomponents.help
#   - there is a closure nested within combobox, called 'combobox_data'
#     which holds all of the items, and allows for addition and deletion.
#     combobox uses this, but it is hidden from the outside world
#
# see also
# --------
#  - windows comboboxes (3.0 and later)
#  - alan cooper's "about face: the essentials of user interface design", p 392
#
# todo list
# ---------
# - the pulldown menu reads 'show/hide'.  it would be a little nicer if
#   only the appropriate one was displayed on the menu button, either 'show' or
#   'hide'.  this wasn't possible until Darrell fixed a bug a couple of weeks
#   ago (11 dec 96, pshannon)
#   Note: this pulldown menu no longer exists; it's a List & Hide button
#   now.  (JAU: 17JAN97)
# - a lot of screen real estate is used up by the listboxes being mapped into
#   the same frame.  a self-positioning popup listbox, a la windows, would
#   be better -- though since multiple selection is provided, there would
#   have to be an explicit 'dismiss' button on this popup listbox.
#   Note: multiple selection is no longer the default mode.  (JAU: 16JAN97)
# - Revise guicomponents.help to reflect my recent changes.  (JAU: 17JAN97)
#
# More notes
# ----------
# - Added optional horizontal scroll-bars to entry & list boxes.
# - Added optional opaque (& invisible) attributes to entries for
#   call-backs that need some additional state information on entries.
#------------------------------------------------------------------------------

pragma include once;

include "gmisc.g";
include "ranges.g";

# Do something with these....
ACTIVE_TEXT_COLOR := 'black';
DISABLED_TEXT_COLOR := 'gray60';
#------------------------------------------------------------------------------
oldcombobox := function (parentFrame, title, values=F, useEnableButton=T,
		      useDisplayAllButton=F, reverseFill=F,
		      collapseDisplayAllRanges=F, collapseEnteredRanges=F,
		      useHorizontalScrollbars=F, dataHasAttributes=F,
		      squeezeWhiteSpace=F, useClearButton=F)
{
  #--------------------------------------------------------------------------
  oldcombobox_data := function (reverseFill, dataHasAttributes)
  {
    public := [=];		# public functions
    self := [=];		# mostly private data

    self.count := 0;
    self.values := array ('',1);
    self.allData := F;
    self.reverseFill := reverseFill;
    self.hasAttributes := dataHasAttributes;
    self.defaultAttribute := F;

    if (self.hasAttributes) {
      self.attributes := [];
    }

    public.set_default_attribute := function (attribute)
    {
      wider self;

      return self.defaultAttribute := attribute;
    }

    public.set_all_data := function (allData)
    {
      wider self;

      return self.allData := allData;
    }

    public.display_all_data := function ()
    {
      # JAU: Eventually set up to display using Bob's [] range syntax?
      # This as_string is sort of a kludge.
      #
      # The mechanism for doing this is there, though I need to be
      # careful of handling allData as it can be a vector, a string....
      return as_string (self.allData);
    }

    public.add := function (stringValue, attribute)
    {
      wider self;

      if (!is_string (stringValue)) {
        fail "oldcombobox_data.add requires a string argument";
      }
      self.count +:= 1;
      self.values [self.count] := stringValue;

      if (self.hasAttributes) {
	if (attribute) {
	  self.attributes[self.count] := attribute;
	} else {
	  self.attributes[self.count] := self.defaultAttribute;
	}
      }
      return self.count;
    }# oldcombobox_data.public.add

    public.value := function (passedIndex)
    {
      wider self;

      if (!is_integer (passedIndex)) {
	fail "oldcombobox_data.value requires an integer argument";
      }
      if (self.reverseFill) {
	integerIndex := self.count - passedIndex + 1;
      } else {
	integerIndex := passedIndex;
      }
      if (integerIndex > self.count || integerIndex < 1) {
         msg := spaste ('oldcombobox_data.value error:  index (', integerIndex,
                        ') out of range (1-', self.count, ')');
         fail msg;
       }# if out of range
      return self.values [integerIndex];
    }# oldcombobox_data.public.value

    public.attribute := function (passedIndex)
    {
      wider self;

      if (!self.hasAttributes) {
	fail "oldcombobox_data.attribute: oldcombobox has no attributes";
      }
      if (!is_integer (passedIndex)) {
	fail "oldcombobox_data.attribute requires an integer argument";
      }
      if (self.reverseFill) {
	integerIndex := self.count - passedIndex + 1;
      } else {
	integerIndex := passedIndex;
      }
      if (integerIndex > self.count || integerIndex < 1) {
         msg := spaste ('oldcombobox_data.attribute error:  index (',integerIndex,
                        ') out of range (1-', self.count,')');
         fail msg;
         }# if out of range
      return self.attributes [integerIndex];
    }# oldcombobox_data.public.attribute

    public.delete_item := function (passedIndex)
    {
      wider self;

      if (!is_integer (passedIndex)) {
	fail "oldcombobox_data.delete_item requires an integer argument";
      }
      if (self.reverseFill) {
	integerIndex := self.count - passedIndex + 1;
      } else {
	integerIndex := passedIndex;
      }
      if (integerIndex > self.count || integerIndex < 1) {
	msg := spaste ('oldcombobox_data.delete_item error:  index (',
		       integerIndex, ') out of range (1-', self.count,')');
	fail msg;
      }# if out of range
      minIndex := integerIndex;
      maxIndex := self.count-1;

      if (minIndex <= maxIndex) {
        for (i in minIndex:maxIndex) {
          self.values [i] := self.values [i+1];
	  if (self.hasAttributes) {
	    self.attributes [i] := self.attributes [i + 1];
	  }
	}
      }
      self.values [self.count] := '';

      if (self.hasAttributes) {
	self.attributes [self.count] := F; # JAU: Do I want to do it this way?
      }
      self.count -:= 1;

      return self.count;
    }# oldcombobox_data.public.delete_item

    public.index := function (valueToMatch)
    {
      wider self;

      if (self.count < 1) {
	return F;
      }
      for (i in 1:self.count) {
         if (valueToMatch == self.values [i]) {
	   if (self.reverseFill) {
	     return self.count - i + 1;
	   } else {
	     return i;
	   }
         }
       }
      return F;
    }# oldcombobox_data.public.index

    public.describe := function ()
    {
      wider self;

      if (self.count == 0) {
        print 'no contents';
        return T;
      }
      for (i in 1:self.count) {
        msg := spaste (i,': ', self.values [i]);
        print msg;
      }
      return T;
    }# oldcombobox_data.public.describe

    public.all := function ()
    {
      wider self;		# JAU: Needed?

      return self.values;
    }# oldcombobox_data.public.all

    public.attributes := function ()
    {
      wider self;		# JAU: Needed?

      return self.attributes;
    }

    public.size := function ()
    {
      wider self;

      return self.count;
    }
    public.debug := ref self;
    return ref public;
  }# oldcombobox_data, a closure function nested within oldcombobox
  #-----------------------------------------------------------------------

  #-----------------------------------------
  # the body of oldcombobox closure starts here
  #-----------------------------------------
  public := [=];		# public functions
  self := [=];			# private data and functions

  if (!is_agent (parentFrame)) {
    fail "need a tk widget in which to create oldcombobox...";
  }
  self.reverseFill := reverseFill;
  self.hasAttributes := dataHasAttributes;
  self.data := oldcombobox_data (self.reverseFill, self.hasAttributes);
  self.selectionCallback := F;	# if defined, this function is called
				# every time a selection is made
  self.alwaysCallSelectionCallback := F; # If T, also call callback when
				         # entry made in entry box.
  self.callBackWithAttributes := F; # If T, do callback with two arguments:
				    # (data, attributes)
  if (is_string (values)) {
    for (i in 1:len (values)) {
      junk := self.data.add (values[i]);
    }
  }
  self.defaultFont := spaste ('-adobe-courier-medium-r-normal--', 12, '-*');
  self.maxVisibleLinesInListbox := 5; # add scrollbar after this size is reached
  self.useEnableButton := useEnableButton;
  self.useClearButton := useClearButton;
  self.useDisplayAllButton := useDisplayAllButton;
  self.collapseDisplayAllRanges := collapseDisplayAllRanges;
  self.collapseEnteredRanges := collapseEnteredRanges;
  self.squeezeWhiteSpace := squeezeWhiteSpace;
  self.listbox := F;
  self.listboxDisplayed := F;
  self.listboxConstructed := F;
  self.selectedIndices := [];
  self.listbox_scrollbar := F;
  self.useHorizontalScrollbars := useHorizontalScrollbars;
  self.listbox_horizontal_scrollbar := F;
  self.enabled := F;
  self.listboxSelectionMode := 'single';
  self.outerFrame := frame (parentFrame, side='top');
  self.entryFrame := frame (self.outerFrame, side='left', expand='x');
  self.leftEntryFrame := frame (self.entryFrame, side='right', expand='none');
  self.rightEntryFrame := frame (self.entryFrame, side='top', expand='x');
  self.label := label (self.leftEntryFrame, text=title, font=self.defaultFont,
                       foreground=ACTIVE_TEXT_COLOR);
  self.entry := entry (self.rightEntryFrame, background='white', width=20,
                       fill='x', font=self.defaultFont, disabled=F);

  if (self.useHorizontalScrollbars) {
    self.entryScroll := scrollbar (self.rightEntryFrame, orient='horizontal');
  }
  self.enableButtonFrame := frame (self.entryFrame, expand='none', side='left');

  if (self.useEnableButton) {
    self.enableButton := button (self.enableButtonFrame, type='check', text='');
  }
  self.listboxToggleButton := button (self.enableButtonFrame, text='List',
				      font=self.defaultFont);

  if (self.data.size () == 0) {
    self.listboxToggleButton->disabled (T);
  }
  if (self.useDisplayAllButton) {
    self.displayAllButton := button (self.enableButtonFrame, text='All',
				     font=self.defaultFont, disabled=T);

    # JAU: This still feels really clunky--needs tuning IMO.
    if (self.collapseDisplayAllRanges && is_function (ranges)) {
      self.range_handler := ranges ();

      whenever self.displayAllButton->press do {
	junk := messagebox (self.range_handler.collapse (self.data.display_all_data ()),
			    title=spaste (stripleadingblanks (title)));
      }
    } else {
      whenever self.displayAllButton->press do {
	junk := messagebox (self.data.display_all_data (),
			    title=spaste (stripleadingblanks (title)));
      }
    }
  }
  whenever self.listboxToggleButton->press do {
    if (self.listboxDisplayed) {
      self.hide_listbox ();
    } else {
      tk_hold();
      public.show_listbox ();
      tk_release();
    }
  }# whenever listboxToggleButton->press
  if (self.useHorizontalScrollbars) {
    whenever self.entry->xscroll do {
      self.entryScroll->view ($value);
    }
    whenever self.entryScroll->scroll do {
      self.entry->view ($value);
    }
  }
  whenever self.entry->return do {
    if (self.maybe_add_entry_box_string_to_listbox (self.entry->get ())) {
      if (self.alwaysCallSelectionCallback) {
	self.do_callbacks (self.selectedIndices);
      }
    }
  }# whenever entry->return

  self.do_callbacks := function (indices)
  {
    if (is_function (self.selectionCallback)) {
      if (self.reverseFill) {
	# JAU: Could use sanity check here to see if we're even supposed
	# to have attributes.
	if (self.callBackWithAttributes) {
	  self.selectionCallback (self.data.all ()[self.data.size () -
						   indices + 1],
				  self.data.attributes ()[self.data.size () -
							  indices + 1]);
	} else {
	  self.selectionCallback (self.data.all ()[self.data.size () -
						   indices + 1]);
	}
      } else {
	if (self.callBackWithAttributes) {
	  self.selectionCallback (self.data.all ()[indices],
				  self.data.attributes ()[indices]);
	} else {
	  self.selectionCallback (self.data.all ()[indices]);
	}
      }
    }
    return T;
  }

  # JAU: This is currently called both when CR is hit in the entry
  # window and when the "Average selected spectra" button is hit.  In
  # the latter case it is only called if the entry box information does
  # not duplicate the "logical last" entry in the listbox.  (Should the
  # former case mimic this behavior?)  If the oldcombobox is in reverseFill
  # mode then the "logical last" entry will actually reside at the *top*
  # of the listbox, though still be the last entry in the oldcombobox_data
  # internal data store.
  self.handle_entry_return := function ()
  {
    # add the contents of the entry widget to the listbox, and select it
    # deselect any previous selections, thereby ensuring that only the
    # new value is selected.
    wider self;

    self.selectedIndices := [];
    newValue := self.entry->get ();

    if (strlen (newValue) >  0) {
      # JAU: Is this strlen() call not working suddenly?!?
      # OK...looks like there's a bug lurking somewhere under gmisc.g
      # when dealing with zero-length strings.  Need to report to Darrell.
      public.add (newValue, select=T);
    }# if strlen > 0
    self.update_display ();
  }

  self.set_disabled_state := function ()
  {
    wider self;

    self.enabled := F;

    if (self.useEnableButton) {
      self.enableButton->state (F);
    }
  }
  const public.disable := ref self.set_disabled_state;

  self.set_enabled_state := function ()
  {
    wider self;

    self.enabled := T;

    if (self.useEnableButton) {
      self.enableButton->state (T);
    }
  }
  const public.enable := ref self.set_enabled_state;

  self.display_item_in_entrybox := function (item, clear=F)
  {
    wider self;

#     empty := (strlen (self.entry->get ()) == 0);
#     self.entry->disabled (F);
# JAU: No longer needed; oldcomboboxes default to single selection mode.
# Will need to work on this to make things clean for multiple again.
#     if (!empty) self.entry->insert (' ');
    if (clear) {
      public.clear_entry ();
    }
    self.entry->insert(item);
  }
  const public.add_to_entry_box := ref self.display_item_in_entrybox;

  self.needs_scrollbar := function ()
  {
    wider self;

    numberOfValues := self.data.size ();

    if (numberOfValues > self.maxVisibleLinesInListbox) {
      return T;
    } else {
      return F;
    }
  }

  self.has_scrollbar := function ()
  {
    wider self;

    if (is_agent (self.listbox_scrollbar)) {
      return T;
    } else {
      return F;
    }
  }

  self.add_scrollbar := function ()
  {
    wider self;

    if (self.has_scrollbar ()) {
      return;
    }
    self.listbox_scrollbar := scrollbar (self.listboxFrame);

    whenever self.listbox->yscroll do {
      self.listbox_scrollbar->view ($value);
    }
    whenever self.listbox_scrollbar->scroll do {
      self.listbox->view ($value);
    }
  }# self.add_scrollbar

  self.show_listbox := function ()
  {
    wider self;

    if (!self.listboxConstructed) {
      self.construct_listbox ();
    }
    self.listboxToggleButton->text ('Hide');
    self.listboxFrame->map ();
    self.listboxDisplayed := T;
  }
  const public.show_listbox := ref self.show_listbox;

  self.construct_listbox := function ()
  {
    wider self;

    if (self.listboxConstructed) {
      return T;
    }
    if (self.data.size () > 0) {
      self.listboxToggleButton->text ('Hide');
      numberOfValues := self.data.size ();
      self.listboxFrame := frame (self.outerFrame,side='left',expand='x');

      if (numberOfValues > self.maxVisibleLinesInListbox) {
	calculatedHeight := self.maxVisibleLinesInListbox;
      } else {
	calculatedHeight := numberOfValues;
      }
      self.listboxInnerFrame := frame (self.listboxFrame, side='top',
				       expand='x');
      if (self.useClearButton) {
	self.clearButton := button (self.listboxFrame, text='Clear',
				    font=self.defaultFont);
      }
      whenever self.clearButton->press do {
	public.delete_all ();
	self.hide_listbox ();
      }
      self.listbox := listbox (self.listboxInnerFrame, height=calculatedHeight,
                               font=self.defaultFont, background='white',
                               mode=self.listboxSelectionMode, fill='x');
      if (self.useHorizontalScrollbars) {
	self.listbox_horizontal_scrollbar := scrollbar (self.listboxInnerFrame,
							orient='horizontal');
      }
      if (numberOfValues > 0) {
	for (i in 1:numberOfValues) {
	  self.listbox->insert (self.data.value (i));
	}
      }
      if (self.needs_scrollbar () && (!self.has_scrollbar ())) {
	self.add_scrollbar ();
      }
      numberOfselectedIndices := len (self.selectedIndices);

      if (numberOfselectedIndices > 0) {
	for (i in 1:numberOfselectedIndices) {
	  self.listbox->select (spaste (self.selectedIndices [i] - 1));
	}
      }
      whenever self.listbox->select do {
	# clear the entry widget; get the current selection, update
	# self.selectedIndices, display current selections in entry
	# widget, disable (visually) the whole oldcombobox if there are no
	# selected items in the listbox (note: listbox deselection *is*
	# selection
        self.selectedIndices := self.listbox->selection () + 1;
	self.do_callbacks (self.selectedIndices);
        numberOfIndices := len (self.selectedIndices);
        self.update_display ();
      }# whenever listbox->select
      if (self.useHorizontalScrollbars) {
	whenever self.listbox->xscroll do {
	  self.listbox_horizontal_scrollbar->view ($value);
	}
	whenever self.listbox_horizontal_scrollbar->scroll do {
	  self.listbox->view ($value);
	}
      }
    }# else: display the listbox
    self.listboxConstructed := T;
    return T;
  }# self.construct_listbox

  self.add := function (newString, attribute=F)
  {
    # add <newString> to the data store, and to the listbox if it exists
    # return
    wider self;

    newIndex := self.data.add (newString, attribute);

    if (is_agent (self.listbox)) {
      if (self.reverseFill) {
	self.listbox->insert (newString, 'start');
      } else {
	self.listbox->insert (newString, 'end');
      }
      sb := self.has_scrollbar ();

      if (!self.needs_scrollbar ()) {
        self.listbox->height (newIndex);
      } else if (!self.has_scrollbar ()) {
	self.add_scrollbar ();
      }
      if (self.reverseFill) {
	self.listbox->see ('start');
      } else {
	self.listbox->see (spaste (newIndex));
      }
    }# if listbox exists
    return newIndex;
  }# self.add

  self.update_display := function ()
  {
    # clear the entry widget
    wider self, public;

    public.clear_entry ();

#     self.entry->disabled (F);
    numberOfIndices := len (self.selectedIndices);

    if (is_agent (self.listbox)) {
#       self.listbox->clear ('start','end');
      public.clear_selections (clearSelectedIndices=F);
    }
    if (numberOfIndices > 0) {
      for (i in 1:numberOfIndices) {
	itemName := self.data.value (self.selectedIndices [i]);
	self.display_item_in_entrybox (itemName);
	if (is_agent (self.listbox)) {
	  listboxZeroBasedIndex := self.selectedIndices [i] - 1;
	  self.listbox->select (spaste (listboxZeroBasedIndex));
	}
      }
    }
#    self.label->foreground (ACTIVE_TEXT_COLOR);
#    self.enableButton->disabled (F);
    if (self.useEnableButton) {
      if (numberOfIndices == 0) {
        self.enableButton->state (F);
#        self.enableButton->disabled (T);
#        self.label->foreground (DISABLED_TEXT_COLOR);
      } else {
        self.enabled := T;
#        self.enableButton->disabled (F);
        self.enableButton->state (T);
#        self.label->foreground (ACTIVE_TEXT_COLOR);
      }# else: at least one selection exists
    }# if: useEnableButton
    #self.entry->disabled (T);
  }# self.update_display

  self.delete_from_listbox_and_data_store := function (index)
  {
    wider self;

    if (is_boolean (index)) {
      return;
    }
    if (index < 1  || index > self.data.size ()) {
      return F;
    }
    if (!is_boolean (self.listbox)) {
      self.listbox->delete (spaste (index-1));
    }
    junk := self.data.delete_item (index);
    numberOfSelections := len (self.selectedIndices);
    newSelectedIndices := [];
    newIndex := 1;
     # remove <index> from selectedIndices if it is there
     # decrement everthing that follows: the entries are always know by
     # their order, and deleting one changes the rank of those that follow
    if (numberOfSelections > 0) {
      for (i in 1:numberOfSelections) {
	currentIndex := self.selectedIndices [i];

	if (currentIndex != index) {
	  if (index < currentIndex) {
	    newSelectedIndices [newIndex] := currentIndex - 1;
	  } else {
	    newSelectedIndices [newIndex] := currentIndex;
	  }
	  newIndex +:= 1;
	}# if !=
      }
    }
    self.selectedIndices := newSelectedIndices;

    return T;
  }# self.delete_from_listbox_and_data_store

  # JAU: Can just do an unmap() now!  CHANGE!
  self.hide_listbox := function ()
  {
    wider self;

    self.listboxToggleButton->text ('List');
#     self.listbox := F;
#     self.clearButton := F;
#     self.listboxInnerFrame := F;
#     self.listboxFrame := F;
#     self.listboxDisplayed := F;
#     self.listbox_scrollbar := F;
#     self.listbox_horizontal_scrollbar := F;
    self.listboxFrame->unmap ();
    self.listboxDisplayed := F;

    return T;
  }

  self.disable_listbox_toggle := function ()
  {
#     wider self;

    self.listboxToggleButton->disabled (T);
  }

  self.enable_listbox_toggle := function ()
  {
#     wider self;

    self.listboxToggleButton->disabled (F);
  }

  # JAU: Rename this damned thing!
  self.maybe_add_entry_box_string_to_listbox := function (scalarString)
  {
    lastIndex := self.data.size ();

    if (lastIndex > 0) {
      if (self.reverseFill) {
	lastItem := self.data.value (1);
      } else {
	lastItem := self.data.value (lastIndex);
      }
    } else {
      lastItem := ' ';
    }
    # Squeeze out excess space for comparison.
    if (self.squeezeWhiteSpace) {
      lastItem ~:= s/ *//g;
      scalarString ~:= s/ *//g;
    }
    if (lastItem != scalarString) {
      self.handle_entry_return (); # OK, we're cheating...no CR but we'll fake.
      return T;			# T means added entry.
    }
    return F;			# F means didn't add entry.
  }

  public.clear_entry := function ()
  {
    # blank out the entry widget
#     wider self;

#     self.entry->disabled (F);
    self.entry->delete ('start', 'end');

    return T;
  }

  public.clear_selections := function (clearSelectedIndices=T)
  {
    # note that this does not clear the entry widget
    wider self;

    if (clearSelectedIndices) {
      self.selectedIndices := [];
    }
    if (is_agent (self.listbox)) {
      self.listbox->clear ('start', 'end');
    }
    return T;
  }

  public.clear := function ()
  {
    # clear the entry widget, zero the selections, de-select all entries in
    # the listbox
#     wider self, public
#     wider public;

    public.clear_entry ();
    public.clear_selections ();

    return T;
  }

  public.get_selected:= function ()
  {
    # return, as an array of strings, the current contents of the entry widget
#     wider public, self;

    if (!public.enabled ()) {
      return split ('');  # a trick to return string [0]
    }
    scalarString := self.entry->get ();
    self.maybe_add_entry_box_string_to_listbox (scalarString);

    return split (scalarString);
  }# oldcombobox.get_selected

  public.get_all := function ()
  {
    # return, as an array of strings, all of the string values in the oldcombobox,
    # whether selected or not.
#     wider self;

    return self.data.all ();
  }# oldcombobox.get_all

#   public.disable := function ()
#   {
#     # the oldcombobox will not return any value:  oldcombobox.get () will be useless
#     wider self;

#     self.set_disabled_state ();
#   }

#   public.enable := function ()
#   {
#     wider self;

#     self.set_enabled_state ();
#   }

  public.enabled := function ()
  {
    # an inquiry function
    wider self;

    return self.enabled;
  }# oldcombobox.public.enabled

#   public.show_listbox := function ()
#   {
#     wider self;

#     self.show_listbox ();

#     return T;
#   }

  public.count := function ()
  {
    wider self;

    return self.data.size ();
  }

  public.see := function (index)
  {
    wider self;

    if (!is_integer (index)) {
      fail "oldcombobox.see requires an integer argument";
    }
    self.listbox->see (spaste (index-1));
  }

  public.set_all_data := function (allData)
  {
    wider self;

    # JAU: Need to check the passed data's type here....
    self.data.set_all_data (allData);
    self.displayAllButton->disabled (F);
  }

  # JAU: Need doCallback argument to block callbacks when desired?
  public.add := function (newString, select=F, attribute=F)
  {
    wider self;

    if (!is_string (newString)) {
      fail "oldcombobox.add requires a string argument";
    }
    if (!is_boolean (select)) {
      fail 'oldcombobox.add:  optional second argument, <select> must be boolean';
    }
    result := self.add (newString, attribute);

    if (self.listboxSelectionMode == 'single' && select) {
      self.selectedIndices := [];
    }
    if (select) {
      if (self.reverseFill) {
	self.selectedIndices [len (self.selectedIndices) + 1] := 1;
      } else {
	self.selectedIndices [len (self.selectedIndices) + 1] := result;
      }
    }
    self.update_display ();
    self.enable_listbox_toggle ();

    return result;
  }# public.add

  # might want to delete a named string;  public.delete_by_name (name)?

  public.delete_item := function (integerIndex)
  {
    wider self;

    if (!is_integer (integerIndex)) {
      fail "oldcombobox.delete_item requires an integer argument";
    }
    result := self.delete_from_listbox_and_data_store (integerIndex);
    self.update_display ();

    if (public.count () == 0) {
      self.hide_listbox ();
      self.disable_listbox_toggle ();
    }
    return result;
  }

  public.delete_all := function ()
  {
    wider self;

    self.selectedIndices := [];
    self.update_display ();
    count := public.count ();
    # delete from the end to the beginning of the list
    if (count > 0) for (index in public.count ():1) {
      self.delete_from_listbox_and_data_store (index);
    }
    self.do_callbacks (self.selectedIndices); # JAU: testing this.
    self.hide_listbox ();
    self.disable_listbox_toggle ();

    return T;
  }# oldcombobox.public.delete_all

  public.set_selection_callback := function (newCallbackFunction, alwaysCall=F,
					     sendAttributes=F)
  {
    # <newCallbackFunction> will be called whenever an item is selected
    # in the listbox
    # alwaysCall should be T if you also want callbacks when an item is
    # inserted into the listbox due to it being entered in the entry
    # box.
    wider self;

    if (!is_function (newCallbackFunction)) {
      fail "oldcombobox.set_selection_callback requires a function argument";
    }
    if (!is_boolean (alwaysCall)) {
      fail 'oldcombobox.set_selection_callback: optional second argument, <alwaysCall> must be boolean';
    }
    if (!is_boolean (sendAttributes)) {
      fail 'oldcombobox.set_selection_callback: optional third argument, <sendAttributes> must be boolean';
    }
    self.alwaysCallSelectionCallback := alwaysCall;
    self.selectionCallback := newCallbackFunction;
    self.callBackWithAttributes := sendAttributes;

    return T;
  }# oldcombobox.public.set_selection_callback

  public.set_default_attribute := function (attribute)
  {
    self.data.set_default_attribute (attribute);

    return T;
  }

  public.set_selection_mode := function (newMode)
  {
    # legal modes: single, multiple, browse, extended
    wider self;

    if (newMode == 'single' || newMode == 'multiple' || newMode == 'browse' ||
	newMode == 'extended') {
      if (is_agent (self.listbox)) {
	self.listbox->mode (newMode);
      }
      self.listboxSelectionMode := newMode;

      if (newMode == 'single') {
        self.selectedIndices := [];
        self.update_display ();
      }
    } else {
      options := '\'single\' \'multiple\' \'browse\' \'extended\'';
      fail spaste ('oldcombobox.set_selection_mode argument must be one of \n',
                   '      ', options);
      return F;
    }
    return T;
  }# public set_selection_mode

  # conditional installation of whenever statement
  if (self.useEnableButton) {
    whenever self.enableButton->press do {
      currentlyEnabled := self.enabled;  #self.enableButton->state ();
      if (currentlyEnabled) {
	public.disable ();
      } else {
#        if (len (self.selectedIndices) > 0 )
	public.enable ();
      }
    }# whenever: enableButton pressed
  } else { # the selection is *always* enabled if the enableButton is absent
    public.enable ();
  }
  public.debug := ref self;	# remove this when the code settles down
  return ref public;
}# oldcombobox

#----------------------------------------------------------------------------
test_oldcombobox := function ()
{
  f := frame (title='test oldcombobox ()',side='top');
  cb1 := oldcombobox (f,'colors',
		   "red blue green yellow amber brown orange saffron");
  cb2 := oldcombobox (f,'COLORS',
		   "RED BLUE GREEN YELLOW AMBER BROWN ORANGE SAFFRON");
  cb3 := oldcombobox (f,'Tables',useEnableButton=F);
  cb4 := oldcombobox (f,'empty');
  junk := cb3.add ('one',T);
  junk := cb3.show_listbox ();
  junk := cb3.add ('two',T);
  junk := cb3.add ('three');
  junk := cb3.add ('four',T);
  junk := cb3.add ('five');
  junk := cb3.add ('six');
  junk := cb3.add ('seven',T);
  callback := function (newValue) {
      print 'listbox selection callback: new selection for cb3:', newValue;}
  #cb3.set_selection_callback (callback);

  return ref [f=f,cb1=cb1,cb2=cb2,cb3=cb3,cb4=cb4,callback=callback]

}# test_oldcombobox
