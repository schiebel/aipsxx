# displaylist.g: Maintain an editable list of items.
#
#   Copyright (C) 1996,1997,1998,1999,2000
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
#   $Id: displaylist.g,v 19.2 2004/08/25 01:58:34 cvsmgr Exp $
#

pragma include once;

# summary:
# list     := displaylist(parentframe=F,formatfunction=as_string);
# length   := list.add(value, todrawlist=T);
# count    := list.lastchange();
# value    := list.get(number, fromdrawlist=T);
# ok       := list.set(number, value);
#             list.clear();
# length   := list.ndrawlist();
# length   := list.nclipboard();
# length   := list.cut(numbers);
# length   := list.copy(drawnums);
# length   := list.paste();
#             list.clearclipboard();
#             list.compact();
# length   := list.apply(function, dodraw=T);
#             list.gui(frame);
#             list.nogui();
# ok       := list.save(filename);
# ok       := list.restore(filename);
#             list.setselectcallback(callback);
#             list.setrefressback(callback);
#             list.done();

include 'widgetserver.g';
include 'note.g';

const displaylist := function(parentframe=F,formatfunction=as_string,
			      shorthelp=F, widgetset=dws)
{
    private := [=];
    public := [=];
    private.items := [=];
    private.gui := F;
    private.selectcallback := [drawlist=F, clipboard=T];
    private.refreshcallback := [drawlist=F, clipboard=T];
    private.changecallback := [drawlist=F, clipboard=T];
    private.shorthelp := shorthelp;

    if (!is_function(formatfunction)) formatfunction := as_string;
    # Used to turn the display list into strings for the listboxes
    private.fmtfunc := formatfunction;
    
    private.guientry := widgetset.guientry();

    ## indexes into items
    private.drawlist := []
    private.clipboard := []

    private.lastchange := 0;

    private.change := function(type='drawlist') {
	wider private;
	private.lastchange +:= 1;
	if (is_function(private.changecallback[type])) {
	    private.changecallback[type]();
	    private.changecallback[type] := F;
	}
    }

    public.add := function(value, todrawlist=T)
    {
        wider private
        which := length(private.items) + 1
        private.items[which] := value
	if (todrawlist) {
	    private.change();
            newlen := length(private.drawlist) + 1
            private.drawlist[newlen] := which
	    if (private.gui) {
		private.drawbox->insert(private.fmtfunc(value))
	        private.drawbox->see('end')
	    }
	} else {
            newlen := length(private.clipboard) + 1
            private.clipboard[newlen] := which
	    if (private.gui) {
		private.clipbox->insert(private.fmtfunc(value))
	        private.clipbox->see('end')
	    }
	}

        return newlen
    }

    public.get := function(num, fromdrawlist=T)
    {
	wider private
	if (!is_integer(num) || !(length(num)==1)) {
	    fail 'public.get(num) - num must be a scalar integer'
        }
	if (fromdrawlist) {
	    if (num < 0 || num>length(private.drawlist)) {
	        fail 'public.get(num) - num is out of range'
            }
	    which := private.drawlist[num]
	} else {
	    if (num < 0 || num>length(private.clipboard)) {
	        fail 'public.get(num) - num is out of range'
            }
	    which := private.clipboard[num]
	}
	return private.items[which]
    }

    public.set := function(num, value)
    {
	wider private
	if (num < 0 || num>length(private.drawlist)) {
	    fail 'public.set(num) - num is out of range'
	}
	which := private.drawlist[num]
	private.items[which] := value
	    private.change();
        if (private.gui) {
	    private.drawbox->insert(private.fmtfunc(value), as_string(num-1))
	    private.drawbox->delete(as_string(num))
	    private.drawbox->see(as_string(num-1))
	}
	return T	
    }

    public.clear := function()
    {
	wider private
	private.items := [=]
	private.drawlist := []
	private.clipboard := []
	    private.change();
	if (private.gui) {
	    private.drawbox->delete('0', 'end')
	    private.clipbox->delete('0', 'end')
	}
	return T;
    }

    public.ndrawlist := function()
    {
	wider private
	return length(private.drawlist)
    }

    public.nclipboard := function()
    {
	wider private
	return length(private.clipboard)
    }

    public.cut := function(drawnums)
    {
        wider private
        if (! is_integer(drawnums)) {
	    fail 'displaylist.cut(drawnums) - drawnums must be integer array'
        }
	private.change();
        drawnums := unique(drawnums)
        n := length(private.drawlist)
        if (min(drawnums) < 1 || max(drawnums) > n || length(drawnums)<0) {
	    fail 'displaylist.cut() - drawnums is outside of range'
        }
        if (private.gui) {
	    for (i in drawnums) {
		private.clipbox->insert(private.fmtfunc(
                               private.items[private.drawlist[i]]))
            }
	    count := 1
	    for (i in drawnums) {
		private.drawbox->delete(as_string(i-count),as_string(i-count));
                count +:= 1
            }
#	    private.clipbox->see('end')
#           private.drawbox->see('end')
        }

	for (i in drawnums) {
	    private.clipboard[len(private.clipboard)+1] := private.drawlist[i]
	    private.drawlist[i] := -1
        }        
	private.drawlist := private.drawlist[private.drawlist > 0]

        if (is_function(private.refreshcallback['drawlist']))
	    private.refreshcallback['drawlist']()
 	return length(drawnums)
    }

    public.delete := function(drawnums)
    {
        wider private
        if (!is_integer(drawnums)){# || len(drawnums)<1) {
print 'here'
	    fail 'displaylist.delete(drawnums) - drawnums must be integer array'
        }
	private.change();
        drawnums := unique(drawnums)
        n := length(private.drawlist)
        if (min(drawnums) < 1 || max(drawnums) > n || length(drawnums)<0) {
	    fail 'displaylist.delete() - drawnums is outside of range'
        }
        if (private.gui) {
	    count := 1
	    for (i in drawnums)
		{
	        private.drawbox->delete(as_string(i-count),as_string(i-count));
		count +:= 1
		}
#	    private.clipbox->see('end')
#           private.drawbox->see('end')
        }
	for (i in 1:length(drawnums))
	    private.drawlist[drawnums[i]] := -1
	private.drawlist := private.drawlist[private.drawlist > 0]

        if (is_function(private.refreshcallback['drawlist']))
	    private.refreshcallback['drawlist']()
 	return length(drawnums)
    }

    public.copy := function(drawnums)
    {
        wider private
	wider public
        if (! is_integer(drawnums)) {
	    fail 'displaylist.copy(drawnums) - drawnums must be integer array'
        }
        drawnums := unique(drawnums)
        n := length(private.drawlist)
        if (min(drawnums) < 1 || max(drawnums) > n || length(drawnums)<0) {
	    fail 'displaylist.cut() - drawnums is outside of range'
        }
	
	for (i in 1:length(drawnums)) {
            nxt := length(private.items) + 1
            private.items[nxt] := private.items[private.drawlist[drawnums[i]]]
            private.clipboard[length(private.clipboard)+1] := nxt
	    if (private.gui) {
		private.clipbox->insert(private.fmtfunc(
                                 private.items[private.drawlist[drawnums[i]]]))
	    }
	    private.clipbox->see('end')
        }        

	return length(drawnums)
    }

    public.paste := function()
    {
	wider private
	private.change();
	private.drawlist := [private.drawlist, private.clipboard]
        if (private.gui) {
            insertindex:=private.drawbox->selection();
            if (len(insertindex)!=1) {
	       for (i in private.clipboard) {
		   private.drawbox->insert(private.fmtfunc(private.items[i]))
               }
	    } else {
               draw1:=private.drawlist[ind(private.drawlist)<=(insertindex+1)];
               draw2:=private.drawlist[ind(private.drawlist)>(insertindex+1)];
               private.drawlist:=[draw1,private.clipboard,draw2];
	       for (i in private.clipboard) {
		   private.drawbox->insert(private.fmtfunc(private.items[i]),as_string(insertindex+1));
	           insertindex+:=1;
               }
            }
#	    private.drawbox->see('end')
        }

        if (is_function(private.refreshcallback['drawlist']))
	    private.refreshcallback['drawlist']()

        return length(private.drawlist)
    }

    public.deletedrawlist := function()
    {
	wider public, private
        private.change();
        s := private.drawbox->selection()
	s +:= 1
	public.delete(s)
	return public.compact()
    }

    public.cleardrawlist := function()
    {
	wider public, private
        private.change();
        if (private.gui) 
          private.drawbox->delete('0', as_string(length(private.drawlist)))
	private.drawlist := []
	return public.compact()
    }

    public.clearclipboard := function()
    {
	wider public
	wider private
        if (private.gui) 
          private.clipbox->delete('0', as_string(length(private.clipboard)))
	private.clipboard := []
	return public.compact()
    }

    public.compact := function()
    {
	wider private
        n := length(private.items)
        if (n < 1) return T
	copyme := array(F, n)
        tmp := [=]
	copyme[private.drawlist] := T
	copyme[private.clipboard] := T
# use mask to remove old commands
        private.items:=private.items[copyme];
        for (i in 1:n) {
	    if (copyme[i]) {
		index := length(tmp) + 1
		tmp[index] := private.items[i]
                ## Probably not the most efficient way to do this
		private.drawlist[private.drawlist == i] := index
		private.clipboard[private.clipboard == i] := index
            }
        }
	return T
    }

    public.apply := function(fun, dodraw=T)
    {
	wider private
        if (! is_function(fun)) {
	    fail 'displaylist.apply(fun) - fun is not a function'
        }
        if (dodraw) {
	    tmp := ref private.drawlist
        } else {
	    tmp := ref private.clipboard
        }
	n := length(tmp)
        if (n <= 0) return 0
        for (i in 1:n) {
	    ok := fun(private.items[tmp[i]]);
	    if (is_fail(ok)) fail;
        }
	return n
    }

    public.lastchange := function() {
	wider private;
	private.change();
    }

    ## Set up the GUI if requested
    public.gui := function(ref parentframe)
    {
	wider public
	wider private
        if (! is_agent(parentframe)) {
	    fail 'displaylist.attachframe(parentframe) - not a frame'
        }
        private.parentframe := ref parentframe
	private.wholeframe := widgetset.frame(parentframe, side='left',expand='none')
	private.wholedrawframe := widgetset.frame(private.wholeframe, side='top',
					expand='none')
        private.drawlabel := widgetset.label(private.wholedrawframe, 'Drawlist')
	private.drawlabel.shorthelp := 'List of plot commands';
        private.buttonframe := widgetset.frame(private.wholeframe, side='top',
				     expand='none')
        private.buttonpadframe := widgetset.frame(private.buttonframe, height=20);
	private.wholeclipframe := widgetset.frame(private.wholeframe,side='top',
					expand='none')
        private.cliplabel := widgetset.label(private.wholeclipframe, 'Clipboard');
	private.cliplabel.shorthelp := 'Scratch area for commands';
        private.clipframe := widgetset.frame(private.wholeclipframe, side='left',
				   expand='none',
				expand='none')
        private.clipbox := widgetset.listbox(private.clipframe, height=10)
	if (is_function(private.shorthelp)) 
	    private.clipbox.shorthelp := private.shorthelp;
	private.clipbox.private := ref private
        whenever private.clipbox->select do {
#	  joe:=private.drawbox->clear('0', 'end');
	  joe:=private.clipbox->selection();
	  if (is_function($agent.private.selectcallback['clipboard']))
	      $agent.private.selectcallback['clipboard']($value[length($value)]+1)
        }
        ## This turns off selection in the clipbox
#	whenever private.clipbox->select do {
#	    $agent.private.clipbox->clear(as_string($value))
#        }
	private.clipsb := widgetset.scrollbar(private.clipframe)
        whenever private.clipsb->scroll do
	    private.clipbox->view($value)
        whenever private.clipbox->yscroll do
	    private.clipsb->view($value)

        private.clearclipbutton := widgetset.button(private.wholeclipframe,
						    'Clear');
# A place holder for the clipboard delete button follows:
        private.deleteclipbutton := widgetset.button(private.wholeclipframe,
	 '',relief='flat');
        whenever private.clearclipbutton->press do {
	    public.clearclipboard()
        }
        private.buttonspace := widgetset.label(private.buttonframe, '')
        private.pastebutton := widgetset.button(private.buttonframe, '<< Paste',width=8)
        private.pastebutton.shorthelp := 'Paste the command selected in the clipboard to just after the commmand selected in the drawlist';
        private.pastebutton.private := ref private
        private.pastebutton.public := ref public
        whenever private.pastebutton->press do {
	    $agent.public.paste()
        }

        private.cutbutton := widgetset.button(private.buttonframe, 'Cut  >>',width=8)
        private.cutbutton.shorthelp := 'Cut the commmand selected in the drawlist';
        private.cutbutton.private := ref private
        private.cutbutton.public := ref public
        whenever private.cutbutton->press do {
            s := $agent.private.drawbox->selection()
	    s +:= 1
	    if (len(s) >= 1) $agent.public.cut(s)
        }
        private.copybutton := widgetset.button(private.buttonframe, 'Copy >>',width=8)
        private.copybutton.shorthelp := 'Copy the commmand selected in the drawlist';
        private.copybutton.private := ref private
        private.copybutton.public := ref public
        whenever private.copybutton->press do {
            s := $agent.private.drawbox->selection()
            s +:= 1
            if (length(s) >= 1) $agent.public.copy(s)
            $agent.private.drawbox->clear('0', 'end')
        }

        private.drawframe := widgetset.frame(private.wholedrawframe, side='left',
				   expand='none')
        private.drawbox := widgetset.listbox(private.drawframe, height=10,mode='extended')
        private.drawbox.private := ref private
	if (is_function(private.shorthelp)) 
	    private.drawbox.shorthelp := private.shorthelp;
        whenever private.drawbox->select do {
#            joe:=private.clipbox->clear('0', 'end');
            joe:=private.drawbox->selection();
	    if (is_function($agent.private.selectcallback['drawlist']))
		$agent.private.selectcallback['drawlist']($value[length($value)]+1)
        }
	private.drawsb := widgetset.scrollbar(private.drawframe)
        whenever private.drawsb->scroll do
	    private.drawbox->view($value)
        whenever private.drawbox->yscroll do
	    private.drawsb->view($value)
        private.cleardrawbutton := widgetset.button(private.wholedrawframe,
						    'Clear');
        whenever private.cleardrawbutton->press do {
	    public.cleardrawlist()
        }
        private.deletedrawbutton := widgetset.button(private.wholedrawframe,
						    'Delete');
        whenever private.deletedrawbutton->press do {
	    public.deletedrawlist()
        }
	private.gui := T

        if (length(private.drawlist) > 0) {
	    for (i in 1:length(private.drawlist)) {
	        private.drawbox->insert(
                         private.fmtfunc(private.items[private.drawlist[i]]))
            }
	}
        if (length(private.clipboard) > 0) {
	    for (i in 1:length(private.clipboard)) {
	        private.clipbox->insert(
                         private.fmtfunc(private.items[private.clipboard[i]]))
            }
	}

	private.clipbox->mode('extended');
	private.drawbox->mode('extended');

	widgetset.addpopuphelp(private);

	return T
    }

    public.nogui := function()
    {
	wider private
	private.gui := F
	val private.parentframe := F
	private.wholeframe := F
	return T
    }

    public.save := function(filename)
    {

      wider private;

      if (!is_string(filename) || length(filename) != 1)
	  fail spaste('displaylist.save: invalid filename (', filename, ')');
      
      include 'os.g';
      dos.remove (filename, T, F);

      include 'table.g';
      scd1 := tablecreatescalarcoldesc('Items', [=]);
      scd2 := tablecreatescalarcoldesc('Drawlist', 1);
      scd3 := tablecreatescalarcoldesc('Clipboard', 1);
      td :=  tablecreatedesc(scd1, scd2, scd3);

      nrow := length(private.items);


      tab := table(filename, tabledesc=td, nrow=nrow, readonly=F, ack=T);

      if(!is_table(tab)) fail paste("Could not open ", filename);

      # Now add the table info
      ti := [=];
      ti.type := 'Plot file';
      ti.subType := '';
      ti.readme := 'Repository for plot files';

      tab.putinfo(ti);

      # Save the data
      
      for (row in 1:nrow) {
	f := tab.putcell("Items", row, private.items[row]);
	if(is_fail(f)) return throw(paste('displaylist.save ', f::message));
      }

      dw := array(0, nrow);
      dw[private.drawlist] := 1;
      f := tab.putcol("Drawlist", dw);
      if(is_fail(f)) return throw(paste('displaylist.save ', f::message));

      cb := array(0, nrow);
      cb[private.clipboard] := 1;
      f := tab.putcol("Clipboard", cb);
      if(is_fail(f)) return throw(paste('displaylist.save ', f::message));

      f := tab.close();
      if(is_fail(f)) return throw(paste('displaylist.save ', f::message));

      return T;
    }

    public.restore := function(filename)
    {
	if (!is_string(filename) || length(is_string) != 1)
	    fail spaste('displaylist.restore: invalid filename (', filename, 
			')')
	wider private;
	private.change();
        # Try reading as a table
	include 'table.g';
	if(tableexists(filename)) {
	  tab := table(filename, readonly=T);
          if(is_fail(tab)) fail;
          items := [=];
          nrow := tab.nrows();
	  # Get records cell by cell
          for (row in 1:nrow) {
	    items[row] := tab.getcell('Items', row);
	  }

	  cb := tab.getcol('Clipboard')*(1:nrow);
	  dw := tab.getcol('Drawlist')*(1:nrow);

	  private.items := items;
	  private.drawlist := dw[dw>0];
	  private.clipboard := cb[cb>0];
	  return T;
	}
	return F;
    }

    # The change callback is only called ONCE on the first change. It is
    # assumed the "user" will reset it when he "saves" the list.
    public.setchangecallback := function(ref callback, type='drawlist') {
	wider private;
	private.changecallback[type] := ref callback;
    }

    public.setselectcallback := function(ref callback, type='drawlist')
    {
	wider private
	if (! is_function(callback)) {
	    fail spaste('displaylist.setselectcallback(callback) ',
			'- callback is not a function');
        }
	private.selectcallback[type] := ref callback
	return T
    }

    public.setrefreshcallback := function(ref callback, type='drawlist')
    {
	wider private
	if (! is_function(callback)) {
	    fail spaste('displaylist.setrefreshcallback(callback) - ',
			'callback is not a function');
        }
	private.refreshcallback[type] := ref callback
	return T
    }

    if (is_agent(parentframe) && have_gui()) {
	public.gui(parentframe)
    }

    public.done := function()
    {
	wider private, public;
	public.nogui();
	val private := F;
	val public := F;
	return T;
    }

    return ref public
}

const displaylisttest := function(widgetset=dws)
{
    if (!have_gui()) {
	return T;
    }
    
    fmt := function(value) {return spaste(value.name, '=', value.value);}
    f := widgetset.frame(side='top');
    list := displaylist(f, formatfunction=fmt);
    lrf := widgetset.frame(f, side='left');
    lab := widgetset.label(lrf, 'SELECTION');
    lab2 := widgetset.label(lrf, 'TOTAL');
    rlf := widgetset.frame(lrf, side='right');
    dismiss := widgetset.button(rlf, 'Dismiss', type='dismiss');
    whenever f->killed, dismiss->press do {
	f := F;
	list.done();
    }

    list.add([name='a', value=1]);
    list.add([name='b', value=2]);
    list.add([name='c', value=3]);
    total := 0;
    apply := function(value) {
	wider total;
	total +:= value.value;
	lab2->text(spaste('total=',total));
    }
    list.apply(apply);

    slct := function(num) {lab->text(spaste('row=',num));}
    list.setselectcallback(slct);
    refresh := function() {
	wider total;
	total := 0;
	list.apply(apply);
    }
    list.setrefreshcallback(refresh);

    return T;
}
