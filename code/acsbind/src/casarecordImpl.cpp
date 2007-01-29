#include <casa/Containers/RecordInterface.h>
#include <casa/Containers/RecordField.h>
#include <tables/Tables/TableRecord.h>
#include <casaacsdefs.h>
#include <tables/Tables/Table.h>
#include <casa/Exceptions/Error.h>
#include <casadefsC.h>
#include <casadefsS.h>
//#include <casadefsImpl.h>

using namespace casa;

void casa_wrappers::fromRecord(CASA::CasaRecord * ARec, const RecordInterface &theRec){
    std::cerr << "translating" << std::endl;
    RecordDesc desc = theRec.description();
    uInt nf = desc.nfields();
    // We could eliminate code by using template functions.
    CASA::CasaFieldVec_var theAField = new CASA::CasaFieldVec(nf);
    theAField->length(nf);
    std::cerr << "number of fields " << nf << std::endl;
    for (uInt i=0; i<nf; i++) {
      DataType dt(desc.type(i));
      std::cerr << i << " data type is " << dt << std::endl;
      switch(dt) {
      case TpRecord:
        {
          CASA::CasaRecord *tmp = casa_wrappers::newAR();
          // Recursively descend into sub-records.
          // Use the correct type.
          const TableRecord* trecp = dynamic_cast<const TableRecord*>(&theRec);
          if (trecp != 0) {
            RORecordFieldPtr<TableRecord> field (*trecp, i);
            casa_wrappers::fromRecord(tmp, *field);
          } else {
            const Record* recp = dynamic_cast<const Record*>(&theRec);
            if (recp != 0) {
              RORecordFieldPtr<Record> field (*recp, i);
              casa_wrappers::fromRecord(tmp, *field);
            } else {
              Record rec(theRec);
              RORecordFieldPtr<Record> field (rec, i);
              casa_wrappers::fromRecord(tmp, *field);
            }
          }
          theAField[i] = toAField(desc.name(i), toAValue(*tmp));
           // Unclear if we need to delete tmp
        }
        break;
      case TpBool:
        { 
          RORecordFieldPtr<Bool> field(theRec, i);
          theAField[i] = toAField(desc.name(i), casa_wrappers::toAValue(dt,field));
        }
        break;
      case TpUChar:
        {
          RORecordFieldPtr<uChar> field(theRec, i);
          theAField[i] = toAField(desc.name(i), casa_wrappers::toAValue(dt,field));
        }
        break;
      case TpShort:
        {
          RORecordFieldPtr<Short> field(theRec, i);
          theAField[i] = toAField(desc.name(i), casa_wrappers::toAValue(dt,field));
        }
        break;
      case TpInt:
        {
          RORecordFieldPtr<Int> field(theRec, i);
          theAField[i] = toAField(desc.name(i), casa_wrappers::toAValue(dt,field));
        }
        break;
      case TpUInt:
        {
          RORecordFieldPtr<uInt> field(theRec, i);
          theAField[i] = toAField(desc.name(i), casa_wrappers::toAValue(dt,field));
        }
        break;
      case TpFloat:
        {
          RORecordFieldPtr<Float> field(theRec, i);
          theAField[i] = toAField(desc.name(i), casa_wrappers::toAValue(dt,field));
        }
        break;
      case TpDouble:
        {
          RORecordFieldPtr<Double> field(theRec, i);
          theAField[i] = toAField(desc.name(i), casa_wrappers::toAValue(dt,field));
        }
        break;
      case TpComplex:
        {
          RORecordFieldPtr<Complex> field(theRec, i);
          theAField[i] = toAField(desc.name(i), casa_wrappers::toAValue(dt,field));
        }
        break;
      case TpDComplex:
        {
          RORecordFieldPtr<DComplex> field(theRec, i);
          theAField[i] = toAField(desc.name(i), casa_wrappers::toAValue(dt,field));
        }
        break;
      case TpString:
        {
          RORecordFieldPtr<String> field(theRec, i);
          theAField[i] = toAField(desc.name(i), casa_wrappers::toAValue(dt,field));
        }
        break;
      case TpArrayBool:
        {
          RORecordFieldPtr<Array<Bool> > field(theRec, i);
          theAField[i] = toAField(desc.name(i), casa_wrappers::toAValue(dt,field));
        }
        break;
      case TpArrayUChar:
        {
          RORecordFieldPtr<Array<uChar> > field(theRec, i);
          theAField[i] = toAField(desc.name(i), casa_wrappers::toAValue(dt,field));
        }
        break;
      case TpArrayShort:
        {
          RORecordFieldPtr<Array<Short> > field(theRec, i);
          theAField[i] = toAField(desc.name(i), casa_wrappers::toAValue(dt,field));
        }
        break;
      case TpArrayInt:
        {
          RORecordFieldPtr<Array<Int> > field(theRec, i);
          theAField[i] = toAField(desc.name(i), casa_wrappers::toAValue(dt,field));
        }
        break;
      case TpArrayFloat:
        {
          RORecordFieldPtr<Array<Float> > field(theRec, i);
          theAField[i] = toAField(desc.name(i), casa_wrappers::toAValue(dt,field));
        }
        break;
      case TpArrayDouble:
        {
          RORecordFieldPtr<Array<Double> > field(theRec, i);
          theAField[i] = toAField(desc.name(i), casa_wrappers::toAValue(dt,field));
        }
        break;
      case TpArrayComplex:
        {
          RORecordFieldPtr<Array<Complex> > field(theRec, i);
          theAField[i] = toAField(desc.name(i), casa_wrappers::toAValue(dt,field));
        }
        break;
      case TpArrayDComplex:
        {
          RORecordFieldPtr<Array<DComplex> > field(theRec, i);
          theAField[i] = toAField(desc.name(i), casa_wrappers::toAValue(dt,field));
        }
        break;
      case TpArrayString:
        {
          RORecordFieldPtr<Array<String> > field(theRec, i);
          theAField[i] = toAField(desc.name(i), casa_wrappers::toAValue(dt,field));
        }
        break;
      case TpTable:
        // If it's a table, return the table's name as is done for
        // keywords. NOTE: It's assumed that record is actually a TableRecord.
         {
         const TableKeyword *kw =
                        (const TableKeyword*) theRec.get_pointer(i, TpTable);
          String tname = kw->tableName();
          String name = "Table: " + tname;
          theAField[i] = toAField(desc.name(i), casa_wrappers::toAValue(name));
          }
        break;
      default:
          throw(AipsError("GlishRecord::fromRecord - unrecognized type"));
      }
   }
   std::cerr << "assigning fields ..." << std::endl;
   CASA::CasaFieldVec_var myFields = new CASA::CasaFieldVec(nf > 0 ? nf : 1);
   if(nf > 0){
      myFields->length(nf);
      for(unsigned int i=0; i<nf;i++){
         myFields[i] = theAField[i];
         std::cerr << i << std::endl;
       }
   }
   std::cerr << ARec << std::endl;
   ARec->setName("");
   std::cerr << "Names set" << std::endl;
   ARec->setComment("");
   std::cerr << "Fields created" << std::endl;
   CASA::CasaFieldVec *myFields_ptr = myFields._retn();
   ARec->setFields(*myFields_ptr);
   std::cerr << "Fields assigned" << std::endl;
}

CASA::CasaRecord *casa_wrappers::recordToAR(const RecordInterface &theRec){
  CASA::CasaRecord *theRecord = casa_wrappers::newAR();
  std::cerr << "The corba casarecord is created" << std::endl;
  casa_wrappers::fromRecord(theRecord, theRec);
  std::cerr << "Data  passed into corba casarecord" << std::endl;
  return theRecord;
}

