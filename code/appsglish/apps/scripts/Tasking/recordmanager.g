# recordmanager.g: Allow saving and retrieval of records to a table
#
#   Copyright (C) 1998,1999,2000,2001,2002
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
#   $Id: recordmanager.g,v 19.2 2004/08/25 02:03:52 cvsmgr Exp $
#

pragma include once;

include 'misc.g';
include 'aipsrc.g';
include 'table.g';
include 'note.g';
include 'widgetserver.g';

recordmanager := function(filename='', maxsize=0, readonly=F,
			  widgetset=dws) {
  
  if(!is_defined('dms')) fail "defaultmisc does not exist";

  private := [=];
  public  := [=];
  
  private.readonly := readonly;

  private.init := function() {
    wider private;
    private.values := [=];
    private.times := [=];
    private.comments := [=];
    private.archive := [=];
    private.readonce := F;
  }
  private.init();

  #
  # Default is no gui
  #
  if(is_string(filename)&&filename!='') {
    private.valuesfile := filename;
  }
  else {
    private.valuesfile := 'aips++.records.table';
    if (!drc.find(private.valuesfile, 'recordmanager.file')) {
      private.valuesfile := 'aips++.records.table';
    }
  }
  #
  # Maximum size for any one item stored in the records
  #
  if(is_numeric(maxsize)&&maxsize>0) {
    private.maxsize := maxsize;
  }
  else {
    private.maxsize := 16384;
    if (!drc.find(private.maxsize, 'recordmanager.maxsize')) {
      private.maxsize := 16384;
    }
  }

  # This is the table description for the records table.
  # Column 1 is time, column 2 is a keyword string, and 
  # column 3 is the records record. 
  private.scd1:=tablecreatescalarcoldesc("Time",time());
  private.scd2:=tablecreatescalarcoldesc("Name","Name");
  private.scd3:=tablecreatescalarcoldesc("Record",[=]);
  private.scd4:=tablecreatescalarcoldesc("Attributes",[=]);
  private.scd5:=tablecreatescalarcoldesc("Comments","Comments");
  private.tabledesc :=
      tablecreatedesc(private.scd1, private.scd2, private.scd3, private.scd4,
		      private.scd5);


#########################################################################

#########################################################################
# Public functions
#
  public.open := function(file, readonly=F) {
    wider private;
    private.valuesfile := file;
    private.readonly := readonly;
    private.init();
    if(has_field(private, 'rcmgui')&&
       is_record(private.rcmgui)&&
       has_field(private.rcmgui, 'done')) {
      private.rcmgui.refresh();
    }
    return T;
  }

  public.openreadonly := function(file) {
    wider public;
    return public.open(file, T);
  }

  public.close := function() {
    wider private;
    private.valuesfile := unset;
    private.init();
    return T;
  }

  public.torecord := function(rec) {
    wider private;
    include 'itemcontainer.g';

    if(!is_record(rec)) return rec;

    if(is_itemcontainer(rec)) {
      ret := rec.torecord();
      ret::'isitem' := T;
      return ret;
        
    }
    else {
      ret := [=];
      for (field in field_names(rec)) {
	ret[field] := public.torecord(rec[field]);
      }
      ret:: := rec::
      return ret;
    }
  }

  public.fromrecord := function(rec) {
    wider private;
    include 'itemcontainer.g';

    if(!is_record(rec)) return rec;

    if(has_field(rec::, 'isitem')&&rec::['isitem']) {
      ret := itemcontainer();
      ret.fromrecord(rec);
      return ret;
    }
    else {
      ret := [=];
      for (field in field_names(rec)) {
	ret[field] := public.fromrecord(rec[field]);
      }
      return ret;
    }
  }

  public.isvalid := function(file) {
    wider private;
    if(!tableexists(file)) return F;
    tab := table(file, ack=F);
    cols := tab.colnames();
    tab.close();
    return any(cols=='Time')&&any(cols=='Name')&&any(cols=='Record')&&
	any(cols=='Attributes')&&any(cols=='Comments');
  }

  # Save the record
  const public.saverecord := function(name, record, comments='', dosave=F, ack=T)
  {
    wider private;

    if(readonly) {
      return throw('Cannot save to readonly file ', private.valuesfile);
    }

    if(name=='') {
      return throw('Name of saved record is blank');
    }

    record := public.torecord(record);

    private.values[name]:=record;
    private.times[name]:= time();
    if(is_string(comments)) {
      private.comments[name]:=comments;
    }
    else {
      private.comments[name]:='';
    }
    private.archive[name]:=T;

    if(has_field(private, 'rcmgui')&&
       is_record(private.rcmgui)&&
       has_field(private.rcmgui, 'refresh')) {
      private.rcmgui.refresh();
    }

    if(dosave||is_boolean(private.readonce)) {
      public.save(ack=ack);
    }
    return T;
  }

  const public.saverecordviagui := function(name, record, comments='',
					    dosave=F, ack=T) {
    wider private;
    if(readonly) {
      return throw('Cannot save to readonly file ', private.valuesfile);
    }
    public.gui();
    return private.rcmgui.insert(name, record, comments);
  }

  const public.restorerecordviagui := function(fn) {
    wider private;
    public.gui();
    return private.rcmgui.setcallback(fn);
  }

  const public.contains := function(name) {
    if(is_unset(private.valuesfile)) {
      return throw ('Name of records file is unset', origin='recordmanager.getrecord');
    }

    if(!tableexists(private.valuesfile)) {
      note ('No repository of records: ', private.valuesfile,
	    origin='recordmanager.get');
      return F;
    }

    tab:=table(private.valuesfile, readonly=T, ack=F);
    if(is_fail(tab)) return tab;
    if (tab.nrows() == 0) { 
      tab.close();
      return F;
    }
    names := tab.getcol('Name');
    tab.close();
    return any(names==name);
  }

  # Get the record
  const public.getrecord := function(name, ref comments='') {

    wider private;

    if(is_unset(private.valuesfile)) {
      return throw ('Name of records file is unset', origin='recordmanager.getrecord');
    }

    if(!tableexists(private.valuesfile)) {
      note ('No repository of records: ', private.valuesfile,
	    origin='recordmanager.get');
      return F;
    }

    tab:=table(private.valuesfile, readonly=private.readonly, ack=F);
    if(is_fail(tab)) return tab;
    st := tab.query(spaste('Name==\'', name, '\''));
    if(is_fail(st)) return st;
    if(st.nrows()==0) {
      return throw ('Repository ', private.valuesfile, ' does not contain ',
		    name, origin='recordmanager.getrecord');
    }
    else if(st.nrows()>1) {
      return throw ('Repository ', private.valuesfile, ' has duplicate records ',
		    name, origin='recordmanager.getrecord');
    }
    private.values[name]:=st.getcell('Record', 1);
    private.times[name]:=st.getcell('Time', 1);
    if(private.times[name]==0) private.times[name]:=time();
    private.values[name]:::=st.getcell('Attributes', 1);
    s := st.getcell('Comments', 1);
    if(is_string(s)) {
      private.comments[name]:=s;
    }
    else {
      private.comments[name]:='';
    }
    private.archive[name]:=F;
    tab.close();

    private.readonce := time();

    val comments := private.comments[name];

    return public.fromrecord(private.values[name]);
  }

# Save all the archivable records to the table. It is assumed that
# none of the records already exists on the table so they are all
# appended to newly created rows.

  const private.appendtotable := function(tab, ack) {
    wider private;
    tab.putkeyword('Version', '1.0');
    names := field_names(private.values);
    rownr := tab.nrows();
    for (name in field_names(private.values)) {
      if (private.archive[name]) {
	rownr +:= 1;
	tab.addrows();
	if (is_fail(tab.putcell('Time', rownr, private.times[name]))) fail;
	if (is_fail(tab.putcell('Name', rownr, name))) fail;
	if (is_fail(tab.putcell('Record', rownr, private.values[name]))) fail;
	if (is_fail(tab.putcell('Attributes', rownr,
			       private.values[name]::))) fail;
	if (is_fail(tab.putcell('Comments', rownr,
			       private.comments[name]))) fail;
	private.archive[name] := F;
      }
    }
  }

  # Save the internally stored records to the table
  const public.save := function(ack=F) 
  {
    wider private;

    if(readonly) {
      return throw('Cannot save to readonly file ', private.valuesfile);
    }

    if(is_unset(private.valuesfile)) {
      return throw ('Name of records file is unset', origin='recordmanager.save');
    }

    if(!tableexists(private.valuesfile)) {
      # New table: we just write everything
      if(ack) {
	note('Creating new records table : ', private.valuesfile,
	     origin='recordmanager.save');
      }
      nrows := length(private.values);
      tab:=table(private.valuesfile, tabledesc=private.tabledesc,
		 nrow=nrows, readonly=private.readonly);
      if(!is_table(tab)) fail paste("Could not open ", private.valuesfile);
      if (is_fail(private.appendtotable(tab, ack))) fail;
    }
    else {
      tab:=table(private.valuesfile, readonly=private.readonly, ack=F);
      # Existing table: first we update existing rows
      # then we write the new rows
      if(!is_table(tab)) fail;
      if (tab.nrows() == 0) {
	ok := private.appendtotable(tab, ack);
	if (is_fail(ok)) fail;
      } else {
	names := tab.getcol('Name');
	rownr := 0;
	for (name in names) {
	  rownr +:= 1;
	  if (has_field(private.values, name) && private.archive[name] == T) {
	    if(is_fail(tab.putcell('Time', rownr, private.times[name]))) fail;
	    if(is_fail(tab.putcell('Name', rownr, name))) fail;
	    if(is_fail(tab.putcell('Record', rownr,
				   private.values[name]))) fail;
	    if(is_fail(tab.putcell('Attributes', rownr,
				   private.values[name]::))) fail;
	    if(is_fail(tab.putcell('Comments', rownr, 
				   private.comments[name]))) fail;
	    private.archive[name] := F;
	  }
	}
	ok := private.appendtotable(tab, ack);
	if (is_fail(ok)) fail;
      }
    }
    ti := [=];
    ti.type := 'Records';
    ti.readme := 'Repository for AIPS++ records';
    if(is_fail(tab.putinfo(ti))) fail;
    if(ack) {
      note ('Saving records to ', private.valuesfile, ' at ',
	    dms.timetostring(time()), origin='recordmanager.save');
    }
    return tab.done();
  }

  const public.delete := function (name) {

    wider private;

    if(readonly) {
      return throw('Cannot delete from readonly file ', private.valuesfile);
    }

    if(is_unset(private.valuesfile)) {
      return throw ('Name of records file is unset', origin='recordmanager.delete');
    }

    if(!tableexists(private.valuesfile)) {
      return throw ('No repository of records: ', private.valuesfile,
		    origin='recordmanager.delete');
    }

    tab:=table(private.valuesfile, readonly=private.readonly, ack=F);
    if(!is_table(tab)) fail;
    if(tab.nrows()==0) {
      return throw ('Repository is empty', origin='recordmanager.delete');
    }
    names := tab.getcol('Name');
    if(!any(names==name)) {
      return throw ('Repository does not contain ', name,
		    origin='recordmanager.delete');
    }
    rows := (1:length(names))[names==name];

    if(is_fail(tab.removerows(rows))) fail;
    note('Successfully deleted rows ', rows, origin='recordmanager.delete');

    if(has_field(private, 'rcmgui')&&
       is_record(private.rcmgui)&&
       has_field(private.rcmgui, 'refresh')) {
      private.rcmgui.refresh();
    }

    return tab.close();
  }

  public.debug := function() {return private;}

  const public.deletetable := function() 
  {
    wider private;

    if(readonly) {
      return throw('Cannot delete readonly file ', private.valuesfile);
    }

    if(is_unset(private.valuesfile)) {
      return throw ('Name of records file is unset', origin='recordmanager.delete');
    }

    if(tableexists(private.valuesfile)) {
      tabledelete(private.valuesfile);
    }

    if(has_field(private, 'rcmgui')&&
       is_record(private.rcmgui)&&
       has_field(private.rcmgui, 'refresh')) {
      private.rcmgui.refresh();
    }

    private.values := [=];
  }

  const public.show := function()
  {
    wider private;

    if(is_unset(private.valuesfile)) {
      return throw ('Name of records file is unset', origin='recordmanager.show');
    }

    if(!tableexists(private.valuesfile)) {
      return throw ('No repository of records: ', private.valuesfile,
		    origin='recordmanager.show');
    }

    tab:=table(private.valuesfile, readonly=private.readonly, ack=F);
    if(!is_table(tab)) fail;
    version := tab.getkeyword('Version');
    if(tab.nrows()==0) {
      return throw ('Repository is empty', origin='recordmanager.show');
    }

    rec := [=];
    widthrow:=5;
    widthname:=10;
    widthtime:=19;
    widthcomments:=21;
    print "Records: version", version
    print "";
    line := sprintf ('%*s', widthrow, 'Row');
    line := paste(line, sprintf('%*s', widthtime, 'Time'));
    print line;
    print "-------------------------------------"
    for (rownr in 1:tab.nrows()) {
      line := sprintf ('%*s', widthrow, as_string(rownr));
      rec.time:=tab.getcell('Time', rownr);
      line := paste(line, sprintf('%*s', widthtime,
				  dms.timetostring(rec.time)));
      rec.name:=tab.getcell('Name', rownr);
      line := paste(line, sprintf('%*s', widthname, rec.name));
      rec.comments:=tab.getcell('Comments', rownr);
      if(!is_string(rec.comments)) {
	rec.comments:='';
      }
      line := paste(line, sprintf('%s', rec.comments));
      print line;
    }
    tab.close();
    return T;
  }

  const public.list := function() 
  {
    wider private;

    rec := [=];

    if(is_unset(private.valuesfile)) {
      return throw ('Name of records file is unset', origin='recordmanager.list');
    }

    if(is_unset(private.valuesfile)) {
      return throw ('Name of records file is unset', origin='recordmanager.list');
    }

    if(!tableexists(private.valuesfile)) {
      note ('No repository of records: ', private.valuesfile,
	    origin='recordmanager.list');
      return rec;
    }

    tab:=table(private.valuesfile, readonly=private.readonly, ack=F);
    if(!is_table(tab)) {
      return throw('Error opening table ', tab::message);
    }
    rec.version := tab.getkeyword('Version');
    if(tab.nrows()==0) {
      note ('Repository is empty', origin='recordmanager.list');
      return rec;
    }

    for (rownr in 1:tab.nrows()) {
      name:=tab.getcell('Name', rownr);
      rec[name].time:=dms.timetostring(tab.getcell('Time', rownr));
      rec[name].comments:=tab.getcell('Comments', rownr);
    }
    tab.close();
    return rec;
  }

  const public.names := function() 
  {
    wider private;

    if(is_unset(private.valuesfile)) {
      return throw ('Name of records file is unset', origin='recordmanager.names');
    }

    names := "";

    if(!tableexists(private.valuesfile)) {
      note ('No repository of records: ', private.valuesfile,
	    origin='recordmanager.names');
      return names;
    }

    tab:=table(private.valuesfile, readonly=private.readonly, ack=F);
    if(!is_table(tab)) fail;
    if(tab.nrows()==0) {
      note ('Repository is empty', origin='recordmanager.names');
      return names;
    }
    names := tab.getcol('Name');
    tab.close();

    return names;
  }

  const public.type := function() {
    return 'recordmanager';
  }

  whenever system->exit do {
    public.save(ack=F);
    private.exitwhenever := current_whenever();
  }

  const public.done := function() {
    deactivate private.exitwhenever;
    if(has_field(private, 'rcmgui')&&
       is_record(private.rcmgui)&&
       has_field(private.rcmgui, 'done')) {
      private.rcmgui.done();
    }
    return public.save();
  }

  const public.name := function() {
    wider private;
    return private.valuesfile;
  }

  const public.readonly := function() {
    wider private;
    return private.readonly;
  }

  const public.gui := function() {
    wider private;
    include 'recordmanagergui.g';
    if(!has_field(private, 'rcmgui')||
       !is_agent(private.rcmgui)) {
      private.rcmgui := recordmanagergui(public);
      if(is_fail(private.rcmgui)) {
	return throw('Error opening gui', private.rcmgui::message);
      }
    }
    private.rcmgui.map();
    return T;
  }

  public.save();

  return ref public;
}

const drcm := recordmanager();
