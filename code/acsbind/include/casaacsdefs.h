#include <casa/Utilities/DataType.h>
#include <casa/Arrays/Vector.h>
#include <casa/Containers/RecordInterface.h>
#include <casa/Containers/RecordField.h>
#include <tables/Tables/TableKeyword.h>
#include <casadefsC.h>

namespace casa_wrappers {
   template <class T> CASA::CasaData *scalarToSeq(T theVec);
   template <class T>  CASA::CasaData *arrayToSeq(CASA::CasaFieldType, casa::Array<T> &theVec);
   template <class T> CASA::CasaArray *scalarToAA(CASA::CasaFieldType, T theVec);
   template <class T>  CASA::CasaArray *arrayToAA(CASA::CasaFieldType, casa::Array<T> &theVec);
   CASA::CasaRecord *recordToAR(const casa::RecordInterface &theRec);
   CASA::CasaData *recordToSeq(const casa::RecordInterface &theRec);
   CASA::complex toCorbaComplex(casa::Complex );
   CASA::dcomplex toCorbaDComplex(casa::DComplex );
   casa::Complex toComplex(CASA::complex );
   casa::DComplex toDComplex(CASA::dcomplex );
   CASA::CasaRecord *newAR();
   // CASA::CasaField *newAF();
   CASA::CasaFieldType toAFType(casa::DataType);
   casa::DataType fromAFType(CASA::CasaFieldType);
   CASA::IntVec shapeToIntVec(const casa::IPosition &);
   casa::IPosition &intVecToShape(CASA::IntVec);
   void fromRecord(CASA::CasaRecord *, const casa::RecordInterface &);
   void toRecord(casa::RecordInterface &, const CASA::CasaRecord & );
   template <class T> CASA::CasaValue& toAValue( casa::DataType, const casa::RORecordFieldPtr<T>  &theField);
   template <class T> CASA::CasaValue& toAValue( casa::DataType, const casa::RORecordFieldPtr<casa::Array<T> >  &theField);
   template <class T> void assignData(CASA::CasaDatum *, const T &);
   template <class T> void assignData(CASA::CasaDatum *, const casa::Array<T> &);
   CASA::CasaValue& toAValue(casa::String  &astring);
   CASA::CasaValue& toAValue(CASA::CasaRecord &theRec);
   //CASA::CasaField toAField( char *, const CASA::CasaValue &theVal);
   //CASA::CasaField toAField( char *, const CASA::CasaRecord &theVal);
   CASA::CasaField& toAField( const casa::String &, const CASA::CasaValue &theVal);
   CASA::CasaField& toAField( const casa::String &, const CASA::CasaRecord &theVal);
   template <class T> int fromAValue(T &a, const CASA::CasaValue &theVal);
   template <class T> int fromAValue(casa::Array<T> &a, const CASA::CasaValue &theVal);
   template <class T, class CASAT> casa::Array<T> &fromCASAVec(const CASAT &);
};
