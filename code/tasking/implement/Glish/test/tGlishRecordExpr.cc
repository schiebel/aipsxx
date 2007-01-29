//# tGlishRecordExpr.cc: Test program for the GlishRecord selection
//# Copyright (C) 2000,2001
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This program is free software; you can redistribute it and/or modify it
//# under the terms of the GNU General Public License as published by the Free
//# Software Foundation; either version 2 of the License, or (at your option)
//# any later version.
//#
//# This program is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//# more details.
//#
//# You should have received a copy of the GNU General Public License along
//# with this program; if not, write to the Free Software Foundation, Inc.,
//# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: tGlishRecordExpr.cc,v 19.3 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Glish/GlishRecordExpr.h>
#include <tasking/Glish/GlishRecord.h>
#include <tables/Tables/TableRecord.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Utilities/Assert.h>
#include <casa/iostream.h>

#include <casa/namespace.h>
// <summary>
// Test program for GlishRecord selection.
// </summary>

// This program tests the class GlishRecordExpr to select records from a group
// of GlishRecords.
// It is an adapted copy of Tables/test/tRecordExpr.cc.


void doIt()
{
  GlishRecord grec;
  // Check if it handles a normal record field.
  TableRecord rec;
  rec.define ("fld1", Int(1));
  grec.fromRecord (rec);
  GlishRecordExpr expr(grec, "fld1 == 1");
  AlwaysAssertExit (expr.matches (grec));
  // Check if it can also handle a record where fld1 is e.g. a float.
  rec.removeField ("fld1");
  rec.define ("fld1", Float(1));
  grec.fromRecord (rec);
  AlwaysAssertExit (expr.matches (grec));
  rec.define ("fld1", Float(2));
  grec.fromRecord (rec);
  AlwaysAssertExit (! expr.matches (grec));

  // Check if it handles fields in subrecords.
  TableRecord subrec1, subrec2;
  subrec2.define ("fld1", 1);
  subrec1.defineRecord ("sub2", subrec2);
  rec.defineRecord ("sub1", subrec1);
  grec.fromRecord (rec);
  AlwaysAssertExit (! expr.matches (grec));

  GlishRecordExpr expr1 (grec, "sub1.sub2.fld1 == 1");
  AlwaysAssertExit (expr1.matches (grec));
  GlishRecordExpr expr2 (grec, "sub1.sub2.fld1 == 2");
  AlwaysAssertExit (! expr2.matches (grec));
  GlishRecordExpr expr3 (grec, "sub1.sub2.fld1 == 1  && fld1 > 1");
  AlwaysAssertExit (expr3.matches (grec));
  rec.define ("fld1", Float(1));
  grec.fromRecord (rec);
  AlwaysAssertExit (! expr3.matches (grec));

  // Check if ifDefined behaves correctly.
  GlishRecordExpr expr4a (grec, "isdefined (sub1.sub2.fld1)");
  AlwaysAssertExit (expr4a.matches (grec));
  GlishRecordExpr expr4b (grec, "isdefined (fld1)");
  AlwaysAssertExit (expr4b.matches (grec));
  // Undefined when used on an empty record.
  TableRecord rect;
  TableRecord subrect1, subrect2;
  grec.fromRecord (rect);
  AlwaysAssertExit (! expr4a.matches (grec));
  // Still undefined.
  rect.define ("fld2", True);
  rect.defineRecord ("sub1", subrect1);
  grec.fromRecord (rect);
  AlwaysAssertExit (! expr4a.matches (grec));
  // Still undefined because field has incorrect type.
  subrect2.define ("fld1", True);
  subrect1.defineRecord ("sub2", subrect2);
  rect.defineRecord ("sub1", subrect1);
  grec.fromRecord (rect);
  AlwaysAssertExit (! expr4a.matches (grec));
  // Now it should be defined.
  subrect2.removeField ("fld1");
  subrect2.define ("fld1", 1);
  subrect1.defineRecord ("sub2", subrect2);
  rect.defineRecord ("sub1", subrect1);
  grec.fromRecord (rect);
  AlwaysAssertExit (expr4a.matches (grec));
  // Now undefined again (because sub1 has not correct fieldNumber anymore).
  rect.removeField ("fld2");
  grec.fromRecord (rect);
  AlwaysAssertExit (! expr4a.matches (grec));

  // Check ndim and shape function for a scalar.
  grec.fromRecord (rec);
  GlishRecordExpr expr5a (grec, "ndim (fld1) == 0");
  AlwaysAssertExit (expr5a.matches (grec));
  GlishRecordExpr expr5b (grec, "nelements (shape (fld1)) == 0");
  AlwaysAssertExit (expr5b.matches (grec));

  // Check if array fields are handled correctly.
  Array<Int> arr(IPosition(3,6,8,12));
  indgen (arr);
  rec.define ("arr1", arr);
  grec.fromRecord (rec);
  GlishRecordExpr expr6a (grec, "max (arr1) > 6*8*12");
  AlwaysAssertExit (! expr6a.matches (grec));
  GlishRecordExpr expr6b (grec, "max (arr1) >= 6*8*12-1");
  AlwaysAssertExit (expr6b.matches (grec));
  // Check shape and ndim function.
  GlishRecordExpr expr6c (grec, "7 in shape (arr1)");
  AlwaysAssertExit (! expr6c.matches (grec));
  GlishRecordExpr expr6d (grec, "7 in shape (arr1) - 1  &&  ndim(arr1)==3");
  AlwaysAssertExit (expr6d.matches (grec));
}


main()
{
  try {
    doIt();
  } catch (AipsError x) {
    cout << "Unexpected exception: " << x.getMesg() << endl;
  } catch (...) {
    cout << "Unexpected unknown exception" << endl;
  }
}
