# ttable.g: test script for table.g
#
#   Copyright (C) 1995,1996,1997,1998,1999,2000,2001
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
#   $Id: ttable.g,v 19.3 2006/04/18 09:23:35 gvandiep Exp $
#
#----------------------------------------------------------------------------

pragma include once

include "table.g";
include "gtable.g";

#----------------------------------------------------------------------------
dotabletest := function()
{

    col1:=tablecreatescalarcoldesc("N",0);
    col2:=tablecreatescalarcoldesc("N^2",0);
    col3:=tablecreatescalarcoldesc("N^3",0);
    col4:=tablecreatearraycoldesc("Vector", 1,1,[20]);
    col5:=tablecreatearraycoldesc ("Matrix", 1,2,[5,30]);
    td := tablecreatedesc (col1, col2, col3, col4, col5);
    tbl := table('sample', td);
#----------------------------------------------------------------------------
    
# Create 2 tables.
    hand0 := table("tab.data",
		   tablecreatedesc (tablecreatescalarcoldesc("col1",1.2+3i,comment="a"),
				    tablecreatearraycoldesc ("col2","a",,,"IncrementalStMan"),
				    tablecreatearraycoldesc ("col3",2,2,[2,3]),
				    tablecreatearraycoldesc ("col4",T,2)));
    if(is_fail(hand0)) fail;
    if(is_fail(hand0.getdesc())) fail;
    
    hand1a := table("tab1.data",
		   tablecreatedesc (tablecreatescalarcoldesc ("col1",1),
				    tablecreatescalarcoldesc ("col2","aa")));
    
# Show and define the table info.
    if(is_fail(hand1a)) fail;
    if(is_fail(hand1a.flush())) fail;
    
    hand1 := table("tab1.data");
    info:=[=];
    info.type := "tab1type";
    info.subType := "tab1Subtype";
    info.readme := '';
    if(is_fail(hand1)) fail;
    if(is_fail(hand1.putinfo (info))) fail;
    if(is_fail(hand1.info ())) fail;
    info.readme := 'readme line 1'
    if(is_fail(hand1.putinfo(info))) fail;
    if(is_fail(hand1.info())) fail;
    if(is_fail(hand1.addreadmeline ('readme line 2'))) fail;
    if(is_fail(hand1.flush())) fail;
    if(is_fail(tableinfo ("tab1.data"))) fail;
    if(is_fail(hand1.info())) fail;
    
# Some erronous descriptions.
#    shape < 0
    if(!is_fail(table ("tab2.data",
		 tablecreatedesc (tablecreatearraycoldesc ("col3",2,,[-1,2])))))
	fail "erroneous create succeeded";
#    ndim != shape.nelements()
    if(!is_fail(table ("tab2.data",
		 tablecreatedesc (tablecreatearraycoldesc ("col3",2,1,[2,2])))))
	fail "erroneous create succeeded";

# Creation or opening the same table should fail.
    if(!is_fail(table ("tab.data",
		       tablecreatedesc(tablecreatescalarcoldesc("col1",1)))))
	fail "Opening the same table succeeded";

# Show their descriptions.
    if(is_fail(hand1.getdesc ())) fail;
    if(is_fail(hand1.colnames ())) fail;
    if(is_fail(hand1.getcoldesc ("col1"))) fail;
    if(is_fail(hand1.getcoldesc ("col2"))) fail;

# Add a column to the empty table (i.e. no rows yet).
    dc1:=tablecreatescalarcoldesc('C1',1)
    hand1.addcols(dc1)
    if(is_fail(hand1.getcoldesc ("C1"))) fail;

# Show all table names.
    if(is_fail(hand0.name ())) fail;
    if(is_fail(hand1.name ())) fail;
    if(is_fail(tableopentables())) fail;
    
# Write some data into the table
    if(is_fail(hand1.nrows ())) fail;
    if(is_fail(hand1.addrows (10))) fail;
    if(is_fail(hand1.nrows ())) fail;
    if(is_fail(hand1.putcol ("col1", [0,10,20,30,40,50,60,70,80,90]))) fail;
    if(is_fail(hand1.getcol ("col1"))) fail;
    if(is_fail(hand1.putcol ("col1", hand1.getcol('col1')+1.))) fail;
    if(is_fail(hand1.putcol ("col1", as_short(hand1.getcol('col1')+1.)))) fail;
    if(is_fail(hand1.getcell ("col1", 8))) fail;
    if(is_fail(hand1.putcell ("col1", 8, 75))) fail;
    if(is_fail(hand1.getcol ("col1"))) fail;
    if(is_fail(hand1.flush())) fail;

# Add 2 columns and test if they have been added.
    dc2:=tablecreatescalarcoldesc('C2','a') 
    dc3:=tablecreatearraycoldesc ('C3',as_float(0), 2, [10,5])   
    hand1.addcols(tablecreatedesc(dc2, dc3))
    if(is_fail(hand1.getcoldesc ("C1"))) fail;
    if(is_fail(hand1.getcoldesc ("C2"))) fail;
    if(is_fail(hand1.getcoldesc ("C3"))) fail;

# Write/read some table keywords.
    if(is_fail(hand0.putkeyword ("key0", "value0"))) fail;
    if(is_fail(hand0.putkeyword ("key1", [3+1i,4]))) fail;
    if(is_fail(hand0.getkeyword ("key0"))) fail;
    if(hand0.getkeyword("key0") != "value0") fail "key0 mismatches"
    if(is_fail(hand0.getkeyword ("key1"))) fail;
    if(is_fail(hand0.getkeywords ())) fail;
    if(is_fail(hand1.getkeywords ())) fail;
    if(is_fail(hand1.putkeywords (hand0.getkeywords()))) fail;
    if(is_fail(hand1.getkeywords ())) fail;
    if(is_fail(hand1.keywordnames ())) fail;
    if(any(hand1.keywordnames() != "key0 key1")) fail "keywordnames mismatch"
    if(is_fail(hand1.putkeyword ("key2.s1.s2.s3.f1", "value0", T))) fail;
    if(is_fail(hand1.putkeyword ("key2.s1.t2.f2", "value0", T))) fail;
    if(is_fail(hand1.removekeyword ("key1"))) fail;
    if(any(hand1.keywordnames() != "key0 key2")) fail "keywordnames mismatch"
    if(any(hand1.fieldnames("key2.s1") != "s2 t2")) fail "fieldnames mismatch"
    if(is_fail(hand1.removekeyword ("key2.s1"))) fail;
    if(any(hand1.keywordnames() != "key0 key2")) fail "keywordnames mismatch"

# Write/read some column keywords.
    if(is_fail(hand0.putcolkeyword ("col1", "colkey0", "valueCol1"))) fail;
    if(is_fail(hand0.putcolkeyword ("col1", "colkey1", [3.5+2i,5]))) fail;
    if(is_fail(hand0.getcolkeyword ("col1", "colkey0"))) fail;
    if(hand0.getcolkeyword("col1", "colkey0") != "valueCol1") fail "colkey0 mismatches"
    if(is_fail(hand0.getcolkeyword ("col1", "colkey1"))) fail;
    if(is_fail(hand0.getcolkeywords ("col1"))) fail;
    if(is_fail(hand1.getcolkeywords ("col1"))) fail;
    if(is_fail(hand1.putcolkeywords ("col1", hand0.getcolkeywords ("col1")))) fail;
    if(is_fail(hand1.getcolkeywords ("col1"))) fail;
    if(any(hand1.colkeywordnames("col1") != "colkey0 colkey1")) fail "colkeywordnames mismatch"

# Do some iteration.
    if(is_fail(hand1.putcol ("col1", [0,10,20,20,10,0,10,10,20,0]))) fail;
    if(is_fail(hand1.putcol ("col2", ['r0','r1','r2','r3','r4','r5','r6','r7','r8','r9']))) fail;
    iter := tableiterator (hand1, "col1");
    if(is_fail(iter)) fail;
    while (iter.next()) {
	subtable:=iter.table();
	if(is_fail(subtable)) fail;
	if(is_fail(subtable.getcol ("col2"))) fail;
    }
    iter := tableiterator (hand1, "col1");
    if(is_fail(iter)) fail;
    while (iter.next()) {
	subtable:=iter.table();
	if(is_fail(subtable)) fail;
	if(is_fail(subtable.getcol ("col2"))) fail;
    }
    # The following next and terminate should not do anything.
    if (is_fail(iter.next())) fail;
    if (is_fail(iter.terminate())) fail;
    iter1 := tableiterator (hand1, "col1");
    if(is_fail(iter1)) fail;
    if(is_fail(iter1.terminate())) fail;

    # Do some TableRow operations.
    row1 := tablerow(hand1);
    if(is_fail(row1.get (1))) fail;
    rowrec0 := row1.get (10);;
    if(is_fail(rowrec0)) fail;
    rowrec.col1 := 100;
    if(is_fail(row1.put (10, rowrec))) fail;
    if(is_fail(row1.put (10, rowrec, matchingfields=T))) fail;
    if(is_fail(row1.get (10))) fail;
    rowrec.col2 := "xxyy";
    if(is_fail(row1.put (10, rowrec))) fail;
    if(is_fail(row1.get (10))) fail;
    if(is_fail(row1.put (10, rowrec0))) fail;
    if(is_fail(row1.get (10))) fail;
    if(is_fail(row1.close ())) fail;
    
# Execute a table command.
# Execute another to see if parser is re-entrant.
# This will also do projection (i.e. column selection).

    hand2:=hand1.query('col1<=10', 'tab2.data', 'col2 desc');
    if(is_fail(hand2)) fail;
    if(is_fail(hand2.getcol ("col1"))) fail;
    if(is_fail(hand2.getcol ("col2"))) fail;
    if(is_fail(hand2.close())) fail;
    
    hand3:=hand1.query('col1>10', 'tab3.data');
    if(is_fail(hand3)) fail;
    if(is_fail(hand3.getcol ("col1"))) fail;
    if(is_fail(hand3.getcol ("col2"))) fail;
    if(is_fail(hand3.close ())) fail;

    if(is_fail(tableexists ("tab3.data"))) fail;
    
    hand3:=table("tab3.data",ack=F);
    if(is_fail(hand3)) fail;
    if(is_fail(hand3.getdesc())) fail;
    if(is_fail(hand3.getcol ("col1"))) fail;
    if(is_fail(hand3.getcol ("col2"))) fail;
    if(is_fail(hand3.close())) fail;
    
    hand4:=table("tab3.data",ack=F).query('', "tab4.data", 'col1 desc');
    if(is_fail(hand4)) fail;
    if(is_fail(hand4.info())) fail;
    if(is_fail(hand4.getdesc ())) fail;
    if(is_fail(hand4.getcol ("col1"))) fail;
    if(is_fail(hand4.close())) fail;
    
# Fails (nothing selected/sorted).
    hand4:=hand1.query('a=', 'tab4.data')
    if(!is_fail(hand4)) fail "Fallible tableCommand succeeded";

# Execute a command directly on the table.
    hand5:=tablecommand('select from tab1.data where col1>0');
    if(is_fail(hand5)) fail;
    if(is_fail(hand5.getcol ("col1"))) fail;
    if(is_fail(hand5.getcol ("col2"))) fail;
    if(is_fail(hand5.close ())) fail;

# Execute a command on the table handle (needs a global variable).
    global tabletest_handle := hand1;
    hand5:=tablecommand('select from $tabletest_handle where col1>0');
    if(is_fail(hand5)) fail;
    if(is_fail(hand5.getcol ("col1"))) fail;
    if(is_fail(hand5.getcol ("col2"))) fail;
    if(is_fail(hand5.close ())) fail;

    
# Test if table exists and is writable
    if(is_fail(tableiswritable("tab1.data"))) fail;
    if(is_fail(tableexists("tab1.data"))) fail;
    
# Reopen the table
    hand1b := table("tab1.data",ack=F);
    if(is_fail(hand1b)) fail;
    
# Clone/copy tests
    if(is_fail(tablecopy("tab3.data","tab5.data"))) fail;
    hand5:=table("tab5.data",ack=F);
    if(is_fail(hand5)) fail;
    
# Delete the tables created.
    closeAllTables();
    if(is_fail(tabledelete("sample"))) fail;
    if(is_fail(tabledelete("tab5.data"))) fail;
    if(is_fail(tabledelete("tab4.data"))) fail;
    if(is_fail(tabledelete("tab3.data"))) fail;
    if(is_fail(tabledelete("tab2.data"))) fail;
    if(is_fail(tabledelete("tab1.data"))) fail;
    if(is_fail(tabledelete("tab.data"))) fail;

    headerline :=[=];
    headerline[1] := 'U     V      W         TIME        ANT1       ANT2      VISIBILITY';
    headerline[2] := 'R     R      R          D           I          I            X';
    headerline[3] := '.keywords';
    headerline[4] := 'DATE        A  "97/1/16"';
    headerline[5] := 'REVISION    D 2.01';
    headerline[6] := 'AUTHOR      A "Tim Cornwell"';
    headerline[7] := 'INSTRUMENT  A "VLA"';
    headerline[8] := '.endkeywords';

    dataline :=[=];
    dataline[1] := '124.011 54560.0  3477.1  43456789.0990    1      2        4.327 -0.1132';
    dataline[2] := '34561.0 45629.3  3900.5  43456789.0990    1      3        5.398 0.4521';

    f:=open('> tableasciitest.ascii.header');
    for (line in headerline) write(f, line);
    f:=F;
    f:=open('> tableasciitest.ascii.data');
    for (line in dataline) write(f, line);
    f:=F;

    note('Try creating table with autoheader', origin='tableasciitest');
    result := tablefromascii('tableasciitest.table',
			     'tableasciitest.ascii.data',
			     autoheader=T);
    if(is_fail(result)) fail;
    result.close();
    tabledelete('tableasciitest.table');
  
    note('Try creating table without autoheader', origin='tableasciitest');
    result := tablefromascii('tableasciitest.table',
			     'tableasciitest.ascii.data',
			     'tableasciitest.ascii.header');
    if(is_fail(result)) fail;
    result.close();
  
    dos.remove("tableasciitest.ascii.newheader", T, F);
    dos.remove("tableasciitest.ascii.newdata", T, F);
  
    note('Try writing table and header', origin='tableasciitest');
    tab := table('tableasciitest.table');
    result := tab.toascii('tableasciitest.ascii.newdata',
			  'tableasciitest.ascii.newheader');
  
    if(is_fail(result)) fail;
  
    note('Try writing table and header in one file', origin='tableasciitest');
    result := tab.toascii('tableasciitest.ascii.newalldata');
  
    if(is_fail(result)) fail;
    tab.close();

    dos.remove ('tableasciitest.ascii.data', F, F);
    dos.remove ('tableasciitest.ascii.header', F, F);
    dos.remove ('tableasciitest.ascii.newalldata', F, F);
    dos.remove ('tableasciitest.ascii.newdata', F, F);
    dos.remove ('tableasciitest.ascii.newheader', F, F);
    dos.remove ('tableasciitest.table', T, F);
  
  #    if(is_fail(hand1.close())) fail;
  #    if(is_fail(hand1a.close())) fail;
  #    if(is_fail(hand1b.close())) fail;
  #    if(is_fail(hand5.close())) fail;
    
  note('tabletest ready');
  
}
