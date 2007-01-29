# makeSampleTable.g:  create a table suitable for testing browsers
#------------------------------------------------------------------------------
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
#   $Id: makeSampleTable.g,v 19.1 2004/08/25 01:18:29 cvsmgr Exp $
#
#------------------------------------------------------------------------------
pragma include once
include "gtable.g"
#---------------------------------------------------------------------------
ROWS := 300;

#embeddedTable := createTable ("embedded", 
#                                tableDesc (scalarColumnDesc ("I",0)));
#closeTable (embeddedTable);

tbl := createTable ("sample",
                    tableDesc (scalarColumnDesc("N",0),
                               scalarColumnDesc("N^2",0),
                               scalarColumnDesc("N^3",0),
#                               scalarColumnDesc("Table",embeddedTable),
                               arrayColumnDesc ("Vector", 1,0,[20]),
                               arrayColumnDesc ("Matrix", 1,0,[5,30])));

# columnDesc := arrayColumnDesc("arr1",1,0,[2,3,4]);';
# creates a description for a column containing 3-d arrays';
# with shape [2,3,4].';


data := array (1:ROWS,ROWS);
x := addRows (tbl,ROWS);
vector := array (1:20, 20);
matrix := array (1:150,5,30);


x := putColumn (tbl, "N", data);
x := putColumn (tbl, "N^2", data * data);
x := putColumn (tbl, "N^3", data * data * data);

for (i in 1:ROWS) {
   x := putCell (tbl, "Vector", i, vector);
   x := putCell (tbl, "Matrix", i, matrix);
   }

column1Keywords := [units='janskys',created='1995/03/05',array=[1:3]];
x := putColumnKeywordSet (tbl, "N", column1Keywords);

column2Keywords := [units='janskys',created='1995/03/08',array=[1:10]];
x := putColumnKeywordSet (tbl, "N^2", column2Keywords);

column3Keywords := [column=3,created='1995/03/08',array=[1:10]];
x := putColumnKeywordSet (tbl, "N^3", column3Keywords);

tableKeywords := [originalName='SAMPLE',
                  author='Paul Shannon',
                  bigArray=[1:1000],
                  modified='1996/03/05'];

x := putTableKeywordSet (tbl,tableKeywords);

print 'added', numberOfRows (tbl), 'rows';

x := closeAllTables ();

exit;
