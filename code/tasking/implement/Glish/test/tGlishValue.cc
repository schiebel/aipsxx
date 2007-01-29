//# tGlishValue.cc: Test classes GlishValue, GlishArray, and GlishRecord
//# Copyright (C) 1994,1995,1996,1998,1999,2000,2001
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
//# $Id: tGlishValue.cc,v 19.4 2004/11/30 17:51:11 ddebonis Exp $

#if !defined(AIPS_DEBUG)
#define AIPS_DEBUG
#endif

#include <tasking/Glish.h>
#include <casa/BasicSL/String.h>
#include <casa/Utilities/Assert.h>
#include <casa/Arrays/ArrayLogical.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Cube.h>
#include <casa/Arrays/IPosition.h>
#include <casa/Containers/Record.h>
#include <casa/Containers/RecordDesc.h>
#include <casa/Containers/RecordField.h>
#include <tables/Tables/TableRecord.h>
#include <casa/iostream.h>


#include <casa/namespace.h>
void testGlishValue()
{
    //                           GlishValue::
    //                                       GlishValue()
    GlishValue gv;
    //                                       nelements()
    //                                       type()
    AlwaysAssertExit(gv.nelements() == 1 && gv.type() == GlishValue::ARRAY);
    //                                       GlishValue(const GlishValue &)
    const Value *oldval = gv.value();
    GlishArray ga = gv;
    AlwaysAssertExit(oldval == ga.value() && oldval == gv.value());
    Bool bval;
    ga.get(bval);
    AlwaysAssertExit(bval == False);
    Vector<Bool> vb(1);
    ga.get(vb);
    vb(0) = True;
    ga = vb;
    oldval = ga.value();
    //                                       operator=(const GlishValue &)
    gv = ga;
    ga = gv;
    AlwaysAssertExit(oldval == ga.value() && oldval == gv.value());
    ga.get(bval);
    AlwaysAssertExit(bval == True);
    //                                       addAttribute(const String&)
    gv.addAttribute("foo", ga);
    //                                       attributeExists(const String&)
    AlwaysAssertExit(gv.attributeExists("foo") == True);
    AlwaysAssertExit(gv.attributeExists("bar") == False);
    //                                       getAttribute(const String&)
    ga = gv.getAttribute("foo");
    ga.get(bval);
    AlwaysAssertExit(bval == True);
    ga = gv.getAttribute("bar");
    ga.get(bval);
    AlwaysAssertExit(bval == False);
    //                                       format()
    AlwaysAssertExit(gv.format() == "T");
    //                                       ok()
    AlwaysAssertExit(ga.ok() && gv.ok());
    //                                       ~GlishValue()
    //                                       (called implicitly; look for leaks)
}

void testGlishArray()
{
    //                           GlishArray::
    //                                       GlishArray()
    //                                       elementType()
    GlishArray ga;
    AlwaysAssertExit(ga.nelements()==1 && ga.elementType() == GlishArray::BOOL);
    Bool bval; uChar byval; Short shval; Int ival; Float fval; Double dval;
    Complex cval; DComplex dcval;
    String sval;
    Vector<Bool> bvector(1);
    bvector(0) = True;
    //                                       get(Bool &, uInt)
    ga.get(bval);
    AlwaysAssertExit(bval == False);
    //                                       GlishArray(Array<Bool> &)
    //                                       operator=(const GlishArray &)
    ga = bvector;
    //                                       GlishArray(const GlishArray &)
    const Value *oldval = ga.value();
    GlishArray ga2 = ga;
    AlwaysAssertExit(oldval == ga2.value() && oldval == ga.value());
    ga2.get(bval);
    AlwaysAssertExit(bval == True);

    Cube<Bool> bcube(3,3,3), bcube2(3,3,3);        bcube = True;
    Cube<uChar> bycube(3,3,3), bycube2(3,3,3);     bycube = 255;
    Cube<Short> shcube(3,3,3), shcube2(3,3,3);     shcube = 99;
    Cube<Int> icube(3,3,3), icube2(3,3,3);         icube = 11;
    Cube<Float> fcube(3,3,3), fcube2(3,3,3);       fcube = 3.0f;
    Cube<Double> dcube(3,3,3), dcube2(3,3,3);      dcube = 4.0;
    Cube<Complex> ccube(3,3,3), ccube2(3,3,3);     ccube = Complex(6.0, 6.0);
    Cube<DComplex> dccube(3,3,3),dccube2(3,3,3);  dccube = DComplex(7.0, 7.0);
    Cube<String> scube(3,3,3), scube2(3,3,3);      scube = "world";
    //                                        GlishArray(const Array<T> &)
    //                                        shape()
    //                                        get(Array<T> &)
    //                                        get(T &, uInt)
    GlishArray barray(bcube);
    AlwaysAssertExit(barray.shape() == 3 && barray.elementType() == GlishArray::BOOL);
    AlwaysAssertExit(barray.type() == GlishValue::ARRAY);
    barray.get(bcube2);
    AlwaysAssertExit(allEQ(bcube, bcube2));
    barray.get(bval, 2); AlwaysAssertExit(bval == True);

    GlishArray byarray(bycube);
    AlwaysAssertExit(byarray.shape() == 3 && byarray.elementType() == GlishArray::BYTE);
    AlwaysAssertExit(byarray.type() == GlishValue::ARRAY);
    byarray.get(bycube2);
    AlwaysAssertExit(allEQ(bycube, bycube2));
    byarray.get(byval, 2); AlwaysAssertExit(byval == 255);

    GlishArray sharray(shcube);
    AlwaysAssertExit(sharray.shape() == 3 && sharray.elementType() == GlishArray::SHORT);
    AlwaysAssertExit(sharray.type() == GlishValue::ARRAY);
    sharray.get(shcube2);
    AlwaysAssertExit(allEQ(shcube, shcube2));
    sharray.get(shval, 2); AlwaysAssertExit(shval == 99);

    GlishArray iarray(icube);
    AlwaysAssertExit(iarray.shape() == 3 && iarray.elementType() == GlishArray::INT);
    iarray.get(icube2);
    AlwaysAssertExit(allEQ(icube, icube2));
    iarray.get(ival, 2); AlwaysAssertExit(ival == 11);

    GlishArray farray(fcube);
    AlwaysAssertExit(farray.shape() == 3 && farray.elementType() == GlishArray::FLOAT);
    farray.get(fcube2);
    AlwaysAssertExit(allEQ(fcube, fcube2));
    farray.get(fval, 2); AlwaysAssertExit(fval == 3.0f);

    GlishArray darray(dcube);
    AlwaysAssertExit(darray.shape() == 3 && darray.elementType() == GlishArray::DOUBLE);
    darray.get(dcube2);
    AlwaysAssertExit(allEQ(dcube, dcube2));
    darray.get(dval, 2); AlwaysAssertExit(dval == 4.0);

    GlishArray carray(ccube);
    AlwaysAssertExit(carray.shape() == 3 && carray.elementType() == GlishArray::COMPLEX);
    carray.get(ccube2);
    AlwaysAssertExit(allEQ(ccube, ccube2));
    carray.get(cval, 2); AlwaysAssertExit(cval == Complex(6.0,6.0));

    GlishArray dcarray(dccube);
    AlwaysAssertExit(dcarray.shape()== 3 && dcarray.elementType() ==GlishArray::DCOMPLEX);
    dcarray.get(dccube2);
    AlwaysAssertExit(allEQ(dccube, dccube2));
    dcarray.get(dcval, 2); AlwaysAssertExit(dcval == DComplex(7.0,7.0));

    GlishArray sarray(scube);
    AlwaysAssertExit(sarray.shape()== 3 && sarray.elementType() == GlishArray::STRING);
    sarray.get(scube2);
    AlwaysAssertExit(allEQ(scube, scube2));
    sarray.get(sval, 2); AlwaysAssertExit(sval == "world");
    //                                       GlishArray(const GlishValue &)
    GlishValue gv(sarray);
    GlishArray sarray3(gv);
    AlwaysAssertExit(sarray3.get(scube2) && allEQ(scube2,scube));
    //                                       operator=(const GlishValue &)
    oldval = gv.value();
    sarray3 = gv;
    AlwaysAssertExit(sarray3.value() == oldval && oldval == gv.value());
    AlwaysAssertExit(sarray3.get(scube2) && allEQ(scube2,scube));
    sarray3.addAttribute("foo", sarray3); // force a copy
    AlwaysAssertExit(sarray3.value() != oldval);
    //                                       operator=(const GlishArray &)
    oldval = sarray.value();
    sarray3 = sarray;
    AlwaysAssertExit(sarray3.value() == oldval && oldval == sarray.value());
    //                                       reset()
    sarray3.reset();
    AlwaysAssertExit(sarray3.nelements()==1 && sarray3.elementType() == GlishArray::BOOL);
    //                                       ok()
    AlwaysAssertExit(carray.ok());
    //                                       ~GlishArray() # implicit
}

void testGlishRecord()
{
    //                                       GlishRecord()
    GlishRecord record, record2;
    AlwaysAssertExit(record.type() == GlishValue::RECORD &&
	   record.nelements() == 0);

    Vector<Int> vi(10);
    vi = 11;
    //                                       add(const String&,constGlishArray&)
    record.add("hello", vi);
    AlwaysAssertExit(record.nelements() == 1);
    //                                       exists(const String &name)
    AlwaysAssertExit(record.exists("hello") && !record.exists("world"));
    //                                       add(const String&,const GlishValu&)
    record.add("there", record2);
    AlwaysAssertExit(record.exists("hello") && record.exists("there"));
    //                                       get(const String &name)
    AlwaysAssertExit(record.get("there").type() == GlishValue::RECORD);
    //                                       GlishRecord(const GlishRecord &)
    const Value *oldval = record.value();
    GlishRecord record3(record);
    AlwaysAssertExit(oldval == record3.value());
    //                                       GlishRecord(const GlishValue &)
    GlishValue gv(record3);
    GlishRecord record4(gv);
    AlwaysAssertExit(oldval == record4.value());
    //                                       operator=(const GlishRecord &)
    record3 = record4;
    AlwaysAssertExit(oldval == record3.value());
    //                                       operator=(const GlishValue &)
    record3 = gv;
    AlwaysAssertExit(oldval == record3.value());
    //                                       name(uInt fieldNumber)
    AlwaysAssertExit(record.name(1) == "there");
    //                                       get(uInt fieldNumber)
    GlishArray tmp = record.get(0);
    Vector<Int> vi2(10);
    AlwaysAssertExit(tmp.get(vi2));
    AlwaysAssertExit(allEQ(vi2, 11));
    //                                       ok()
    AlwaysAssertExit(record.ok());
    //                                       ~GlishRecord()   # implicit
}

void testGlishRecordConversion()
{
    RecordDesc desc;
    desc.addField("TpBool", TpBool);
    desc.addField("TpUChar", TpUChar);
    desc.addField("TpShort", TpShort);
    desc.addField("TpInt", TpInt);
    desc.addField("TpFloat", TpFloat);
    desc.addField("TpDouble", TpDouble);
    desc.addField("TpComplex", TpComplex);
    desc.addField("TpDComplex", TpDComplex);
    desc.addField("TpString", TpString);
    desc.addField("TpArrayBool", TpArrayBool);
    desc.addField("TpArrayUChar", TpArrayUChar);
    desc.addField("TpArrayShort", TpArrayShort);
    desc.addField("TpArrayInt", TpArrayInt);
    desc.addField("TpArrayFloat", TpArrayFloat);
    desc.addField("TpArrayDouble", TpArrayDouble);
    desc.addField("TpArrayComplex", TpArrayComplex);
    desc.addField("TpArrayDComplex", TpArrayDComplex);
    desc.addField("TpArrayString", TpArrayString);
    RecordDesc subdesc; subdesc.addField("String", TpString);
    desc.addField("TpRecord", subdesc);
    
    Record record(desc);

    RecordFieldPtr<Bool> BoolField(record, 0);
    RecordFieldPtr<uChar> UCharField(record, 1);
    RecordFieldPtr<Short> ShortField(record, 2);
    RecordFieldPtr<Int> IntField(record, 3);
    RecordFieldPtr<Float> FloatField(record, 4);
    RecordFieldPtr<Double> DoubleField(record, 5);
    RecordFieldPtr<Complex> ComplexField(record, 6);
    RecordFieldPtr<DComplex> DComplexField(record, 7);
    RecordFieldPtr<String> StringField(record, 8);
    RecordFieldPtr<Array<Bool> > ArrayBoolField(record, 9);
    RecordFieldPtr<Array<uChar> > ArrayUCharField(record, 10);
    RecordFieldPtr<Array<Short> > ArrayShortField(record, 11);
    RecordFieldPtr<Array<Int> > ArrayIntField(record, 12);
    RecordFieldPtr<Array<Float> > ArrayFloatField(record, 13);
    RecordFieldPtr<Array<Double> > ArrayDoubleField(record, 14);
    RecordFieldPtr<Array<Complex> > ArrayComplexField(record, 15);
    RecordFieldPtr<Array<DComplex> > ArrayDComplexField(record, 16);
    RecordFieldPtr<Array<String> > ArrayStringField(record, 17);
    RecordFieldPtr<Record> RecordField(record, 18);

    *BoolField = True;
    *UCharField = uChar(255);
    *ShortField = 20001;
    *IntField = 123456789;
    *FloatField = -1.0;
    *DoubleField = -11.0;
    *ComplexField = Complex (1.0, -1.0);
    *DComplexField = Complex (2.0, -2.0);
    *StringField = "Hello World";
    (*ArrayBoolField).resize(IPosition(2,2,2)); *ArrayBoolField = True;
    (*ArrayUCharField).resize(IPosition(2,3,2)); *ArrayUCharField = uChar(255);
    (*ArrayShortField).resize(IPosition(2,3,3)); *ArrayShortField = 29999;
    (*ArrayIntField).resize(IPosition(2,3,4)); *ArrayIntField = 123456789;
    (*ArrayFloatField).resize(IPosition(2,3,5)); *ArrayFloatField = 5.0;
    (*ArrayDoubleField).resize(IPosition(2,3,6)); *ArrayDoubleField = 11.0;
    (*ArrayComplexField).resize(IPosition(2,3,7));
    *ArrayComplexField = Complex(11,7);
    (*ArrayDComplexField).resize(IPosition(2,3,8));
    *ArrayDComplexField = DComplex(9,9);
    (*ArrayStringField).resize(IPosition(2,3,9));
    *ArrayStringField = "World Hello";
    RecordFieldPtr<String> substring(*RecordField, 0);
    *substring = "Howdy!";

    
    GlishRecord glishrec;
    //                                       fromRecord()
    glishrec.fromRecord(record);
    Record record2;
    //                                       toRecord()
    glishrec.toRecord(record2);
    AlwaysAssertExit(record2.conform(record));
    {
      TableRecord trec (record);
      GlishRecord grec;
      grec.fromRecord (trec);
      TableRecord trec2;
      grec.toRecord (trec2);
      AlwaysAssertExit(trec2.conform(trec));
    }
    
    RecordFieldPtr<Bool> BoolField2(record2, 0);
    RecordFieldPtr<uChar> UCharField2(record2, 1);
    RecordFieldPtr<Short> ShortField2(record2, 2);
    RecordFieldPtr<Int> IntField2(record2, 3);
    RecordFieldPtr<Float> FloatField2(record2, 4);
    RecordFieldPtr<Double> DoubleField2(record2, 5);
    RecordFieldPtr<Complex> ComplexField2(record2, 6);
    RecordFieldPtr<DComplex> DComplexField2(record2, 7);
    RecordFieldPtr<String> StringField2(record2, 8);
    RecordFieldPtr<Array<Bool> > ArrayBoolField2(record2, 9);
    RecordFieldPtr<Array<uChar> > ArrayUCharField2(record2, 10);
    RecordFieldPtr<Array<Short> > ArrayShortField2(record2, 11);
    RecordFieldPtr<Array<Int> > ArrayIntField2(record2, 12);
    RecordFieldPtr<Array<Float> > ArrayFloatField2(record2, 13);
    RecordFieldPtr<Array<Double> > ArrayDoubleField2(record2, 14);
    RecordFieldPtr<Array<Complex> > ArrayComplexField2(record2, 15);
    RecordFieldPtr<Array<DComplex> > ArrayDComplexField2(record2, 16);
    RecordFieldPtr<Array<String> > ArrayStringField2(record2, 17);
    RecordFieldPtr<Record> RecordField2(record2, 18);
    RecordFieldPtr<String> substring2(*RecordField2, 0);

    AlwaysAssertExit(*BoolField == *BoolField2);
    AlwaysAssertExit(*UCharField == *UCharField2);
    AlwaysAssertExit(*ShortField == *ShortField2);
    AlwaysAssertExit(*IntField == *IntField2);
    AlwaysAssertExit(*FloatField == *FloatField2);
    AlwaysAssertExit(*DoubleField == *DoubleField2);
    AlwaysAssertExit(*ComplexField == *ComplexField2);
    AlwaysAssertExit(*DComplexField == *DComplexField2);
    AlwaysAssertExit(*StringField == *StringField2);
    AlwaysAssertExit(allEQ(*ArrayBoolField, *ArrayBoolField2));
    AlwaysAssertExit(allEQ(*ArrayUCharField, *ArrayUCharField2));
    AlwaysAssertExit(allEQ(*ArrayShortField, *ArrayShortField2));
    AlwaysAssertExit(allEQ(*ArrayIntField, *ArrayIntField2));
    AlwaysAssertExit(allEQ(*ArrayFloatField, *ArrayFloatField2));
    AlwaysAssertExit(allEQ(*ArrayDoubleField, *ArrayDoubleField2));
    AlwaysAssertExit(allEQ(*ArrayComplexField, *ArrayComplexField2));
    AlwaysAssertExit(allEQ(*ArrayDComplexField, *ArrayDComplexField2));
    AlwaysAssertExit(allEQ(*ArrayStringField, *ArrayStringField2));
    AlwaysAssertExit(*substring2 == *substring && *substring2 == "Howdy!");
}


void testUnset()
{
    GlishRecord rec;
    AlwaysAssertExit(! rec.isUnset());
    GlishValue gv;
    AlwaysAssertExit(! gv.isUnset());
    const GlishRecord& gr = GlishValue::getUnset();
    AlwaysAssertExit(gr.isUnset());
    GlishRecord grc = gr;
    AlwaysAssertExit(grc.isUnset());
    grc.add ("fld2", True);
    AlwaysAssertExit(! grc.isUnset());
    AlwaysAssertExit(gr.isUnset());
    const GlishRecord& gr2 = GlishValue::getUnset();
    AlwaysAssertExit (&gr == &gr2);
    AlwaysAssertExit(gr2.isUnset());
}


int main(int argc, char **argv)
{
    try {
	GlishSysEventSource events(argc, argv);
	testGlishValue();
	testGlishArray();
	testGlishRecord();
	testGlishRecordConversion();
	testUnset();
    } catch (AipsError x) {
	cout << "ERROR: " << x.getMesg() << endl;
	return 1;
    } 
    cout << "OK" << endl;
    return 0;
}
