//# tGlishRecord2Expr.cc: Test program for performance of the GlishRecord selection
//# Copyright (C) 2000,2001,2004
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
//# $Id: tGlishRecord2Expr.cc,v 19.4 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Glish/GlishRecordExpr.h>
#include <tasking/Glish/GlishRecord.h>
#include <tables/Tables/TableRecord.h>
#include <tables/Tables/ExprNode.h>
#include <tables/Tables/RecordGram.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Utilities/Assert.h>
#include <casa/OS/Timer.h>
#include <casa/iostream.h>
#include <casa/sstream.h>


#include <casa/namespace.h>
void doIt (uInt nr, const String& expr, const Record& rec)
{
  {
    GlishRecord grec;
    grec.fromRecord (rec);
    GlishRecordExpr gexpr(grec, expr);
    Timer timer;
    for (uInt i=0; i<nr; i++) {
      gexpr.matches (grec);
    }
    timer.show ("glishrecord");
  }
  {
    TableExprNode texpr (RecordGram::parse(rec, expr));
    Bool result;
    Timer timer;
    for (uInt i=0; i<nr; i++) {
      texpr.get (rec, result);
    }
    timer.show ("record     ");
  }
}


int main (int argc, char* argv[])
{
  uInt nr = 1000;
  if (argc > 1) {
    istringstream istr(argv[1]);
    istr >> nr;
  }
  try {
    Record ifrec;
    ifrec.define ("TOTAL_POWER", float(2.5));

    Record correc;
    correc.define ("SAMPLER", Int(1));
    Vector<Float> arr(8193);
    arr = 1;
    arr(1) = 2;
    correc.define ("FLOAT_DATA", arr);
    correc.define ("EXPOSURE", double(0.050));
    correc.define ("INTERVAL", double(0.01));

    Record antrec;
    antrec.define ("ON_SOURCE", False);
    antrec.define ("RA", double(1.02));
    antrec.define ("DEC", double(0.044));
    antrec.define ("IMAGE_ROTATOR", double(0.1));

    Record ferec;
    ferec.define ("LOAD", "SKY");
    ferec.define ("JCOLD", float(270.0));
    ferec.define ("JHOT", float(290.0));

    Record rec;
    rec.defineRecord ("corr_data", correc);
    rec.defineRecord ("if_data", ifrec);
    rec.defineRecord ("ant_data", antrec);
    rec.defineRecord ("fe_data", ferec);

    rec.define ("SOURCER0", "SYNC");
    rec.define ("FEED1", 1);
    rec.define ("SPECTRAL_WINDOW_ID", 0);
    rec.define ("SCAN_NUMBER", 2);
    rec.define ("SEQ", 3);
    rec.define ("TIME", double(4));

    doIt (nr, "FEED1==1", rec);
    doIt (nr, "SOURCER0=='SYNC'", rec);
    doIt (nr, "fe_data.LOAD=='SKY'", rec);

  } catch (AipsError x) {
    cout << "Unexpected exception: " << x.getMesg() << endl;
  } catch (...) {
    cout << "Unexpected unknown exception" << endl;
  }
}
