# tgtable.g: test script for table.g
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
#   $Id: tgtable.g,v 19.1 2004/08/25 00:53:31 cvsmgr Exp $

include "gtable.g"
#----------------------------------------------------------------------------
testForGlishDictionaryBug := function ()
# april 1996: changes to glish (adding copy-on-write) caused a failure
# in creating a table description from certain column descriptions.
# test for this failure here
{
td := tableDesc (scalarColumnDesc("N",0),
                 scalarColumnDesc("N^2",0),
                 scalarColumnDesc("N^3",0),
                 arrayColumnDesc ("Vector", 1,1,[20]),
                 arrayColumnDesc ("Matrix", 1,2,[5,30]));

tbl := createTable ('sample', td);

if (is_boolean(tbl) && tbl == F) {
  print 'failed to create table'
  exit;
  }

deleteTable ('sample');

}
#----------------------------------------------------------------------------
# testForGlishDictionaryBug ();

# Create 2 tables.
hand0 := createTable ("tab.data",
                      tableDesc (scalarColumnDesc("col1",1.2+3i,,,,"a"),
                                 arrayColumnDesc ("col2","a",,,"StManMirAIO"),
                                 arrayColumnDesc ("col3",2,2,[2,3]),
                                 arrayColumnDesc ("col4",T,2)));
print getTableDesc (hand0);

hand1 := createTable ("tab1.data",
                       tableDesc (scalarColumnDesc ("col1",1),
                       scalarColumnDesc("col2","aa")));

# Show and define the table info.
print tableInfo (hand1);
info.type := "tab1type";
info.subType := "tab1Subtype";
info.readme := "";
print putTableInfo (hand1, info);
print tableInfo (hand1);
info1.readme := 'readme line 1'
print putTableInfo (hand1, info);
print tableInfo (hand1);
print addReadmeLine (hand1, 'readme line 2');
print tableInfo ("tab1.data");

# Some erronous descriptions.
#    ndim < 0
print createTable ("tab2.data",
                   tableDesc (arrayColumnDesc ("col3",2,-1)))
#    shape < 0
print createTable ("tab2.data",
                    tableDesc (arrayColumnDesc ("col3",2,,[-1,2])))
#    ndim != shape.nelements()
print createTable ("tab2.data",
                   tableDesc (arrayColumnDesc ("col3",2,1,[2,2])))

# Creation or opening the same table should fail.
print createTable ("tab.data", tableDesc(scalarColumnDesc("col1",1)))
print openTable ("tab.data");
print openTableForUpdate ("tab.data");

# Show their descriptions.
print getTableDesc (hand1);
print columnNames (hand1);
print getColumnDesc (hand1, "col1");
print getColumnDesc (hand1, "col2");
#print getColumnDesc (hand1, "col3");    # does not exist

# Show all table names.
print tableName (hand0);
print tableName (hand1);
print tableNames();

# Get the id and name of a table.
handRecovered := recoverTableHandle ("tab1.data");
print handRecovered;
print tableName (handRecovered);
print recoverTableHandle ("tab2.data");


# Write some data into the table.
print addRows (hand1, 10);
print tableShape (hand1);
print putColumn (hand1, "col1", [0,10,20,30,40,50,60,70,80,90]);
print getColumn (hand1, "col1");
print getCell (hand1, "col1", 8);
print putCell (hand1, "col1", 8, 75);
print getColumn (hand1, "col1");

# Write/read some table keywords.
print putTableKeyword (hand0, "key0", "value0");
print putTableKeyword (hand0, "key1", [3+1i,4]);
print getTableKeyword (hand0, "key0");
print getTableKeyword (hand0, "key1");
print getTableKeywordSet (hand0);
print getTableKeywordSet (hand1);
print putTableKeywordSet (hand1, getTableKeywordSet (hand0));
print getTableKeywordSet (hand1);

# Write/read some column keywords.
print putColumnKeyword (hand0, "col1", "colkey0", "valueCol1");
print putColumnKeyword (hand0, "col1", "colkey1", [3.5+2i,5]);
print getColumnKeyword (hand0, "col1", "colkey0");
print getColumnKeyword (hand0, "col1", "colkey1");
print getColumnKeywordSet (hand0, "col1");
print getColumnKeywordSet (hand1, "col1");
print putColumnKeywordSet (hand1, "col1", getColumnKeywordSet (hand0, "col1"));
print getColumnKeywordSet (hand1, "col1");

# Do some iteration.
print '------------- table iterator tests ----------------------'
print putColumn (hand1, "col1", [0,10,20,20,10,0,10,10,20,0]);
print putColumn (hand1, "col2", ['r0','r1','r2','r3','r4','r5','r6','r7','r8','r9']);
iter := makeTableIterator (hand1, "col1");
while (stepTableIterator (iter)) {
    print getColumn (iter.handle, "col2");
}
iter1 := makeTableIterator (hand1, "col1");
print closeTableIterator (iter1);

# Do some TableRow operations.
print '------------- table row tests ----------------------'
row1 := makeTableRow (hand1);
print getRow (row1, 1);
rowrec0 := getRow (row1, 10);
print rowrec0;
rowrec.col1 := 100;
print putRow (row1, 10, rowrec);
print putRowMatchingFields (row1, 10, rowrec);
print getRow (row1, 10);
rowrec.col2 := "xxyy";
print putRow (row1, 10, rowrec);
print getRow (row1, 10);
print putRow (row1, 10, rowrec0);
print getRow (row1, 10);
print closeTableRow (row1);


# Execute a table command.
# Execute another to see if parser if re-entrant.
# This will also do projection (i.e. column selection).
print '------------- table selection tests ----------------------'
hand2 := tableCommand ('select from tab1.data where col1<=10 orderby col2 desc');
print getColumn (hand2, "col1");
print getColumn (hand2, "col2");
hand3 := tableCommand ('select col1 from tab1.data where col1>10');
print getColumn (hand3, "col1");
print getColumn (hand3, "col2");
print closeTable (hand3);
hand3 := tableCommand ('select col1 from tab1.data giving tab3.data');
print tableExists ("tab3.data");
print closeTable (hand3);
print tableExists ("tab3.data");
hand3 := openTable ("tab3.data");
print getTableDesc (hand3);
print getColumn (hand3, "col1");
print getColumn (hand3, "col2");
hand4 := tableCommand ('select from tab3.data orderby col1 desc');
print getTableDesc (hand4);
print getColumn (hand4, "col1");

# Fails (nothing selected/sorted).
print '---------- tableCommand guaranteed to fail -----------------';
print tableCommand ('select from tab1.data giving tab4.data');

# Test if table exists and is writable.
print '---------- existence and writable tests -----------------';
print tableIsWritable(hand1);
print tableExists(hand1);
print closeAllTables();
print tableIsWritable("tab1.data");
print tableExists("tab1.data");

# Reopen the table.
hand1 := openTable ("tab1.data");
print tableIsWritable(hand1);
print tableExists(hand1);
print getColumn (hand1, "col1");

# Delete the tables created.
print '---------- deleteTable tests  -----------------';
print closeAllTables();
print deleteTable ("tab.data");
print deleteTable ("tab1.data");
print deleteTable ("tab3.data");


exit
