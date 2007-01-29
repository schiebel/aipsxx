#include <casaacsdefs.h>
#include <casa/Exceptions/Error.h>
#include <casa/BasicSL/String.h>
#include <casadefsC.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/ArrayUtil.h>

using namespace casa;

template <> void casa_wrappers::assignData<String>(CASA::CasaDatum *theData, const String  &theField){ theData->stringVal(theField.chars()); }
template <> void casa_wrappers::assignData<String>(CASA::CasaDatum *theData, const Array<String> &theField){
           try {
           char **theElements = new char *[theField.nelements()];
           //Array<String>::IteratorSTL anIter(theField);
           Int i(0);
           for(Array<String>::const_iterator anIter=theField.begin();anIter!=theField.end();anIter++){
               theElements[i++] = CORBA::string_dup((*anIter).chars());
           }
           theData->stringArr(CASA::StringVec(theField.nelements(), theField.nelements(), theElements, 0));
           } catch( AipsError x ){
              cerr << x.getMesg() << endl;
           }
 }

template <class T> CASA::CasaArray *casa_wrappers::scalarToAA(
                                    CASA::CasaFieldType theType,
                                    T theVals){
   CASA::CasaArray *theArray = new CASA::CasaArray;
   theArray->type = theType;
   Int theShape[] = {1};
   theArray->shape = *(new CASA::IntVec(1,1,theShape, 0));
   theArray->value = casa_wrappers::scalarToSeq(theVals);

   return theArray;
}
template <class T> CASA::CasaArray *casa_wrappers::arrayToAA(
                                    CASA::CasaFieldType theType,
                                    Array<T> &theVals){
        
   CASA::CasaArray *theArray = new CASA::CasaArray;
   switch(theType){
      case CASA::ATYPE_Bool: 
        theArray->type = CASA::ATYPE_ARR_Bool;
         break;
      case CASA::ATYPE_Short: 
        theArray->type = CASA::ATYPE_ARR_Short;
         break;
      case CASA::ATYPE_Int: 
        theArray->type = CASA::ATYPE_ARR_Int;
         break;
      case CASA::ATYPE_UInt: 
        theArray->type = CASA::ATYPE_ARR_UInt;
         break;
      case CASA::ATYPE_Long: 
        theArray->type = CASA::ATYPE_ARR_Long;
         break;
      case CASA::ATYPE_ULong: 
        theArray->type = CASA::ATYPE_ARR_ULong;
         break;
      case CASA::ATYPE_Float: 
        theArray->type = CASA::ATYPE_ARR_Float;
         break;
      case CASA::ATYPE_Complex: 
        theArray->type = CASA::ATYPE_ARR_Complex;
         break;
      case CASA::ATYPE_Double: 
        theArray->type = CASA::ATYPE_ARR_Double;
         break;
      case CASA::ATYPE_DComplex: 
        theArray->type = CASA::ATYPE_ARR_DComplex;
         break;
      default :
        theArray->type = theType;
        break;
   }
   IPosition ashape = theVals.shape();
   theArray->shape = CASA::IntVec(ashape.nelements(),
                                  ashape.nelements(),
                                  ashape.storage(), 0);
   theArray->value = casa_wrappers::arrayToSeq(theType, theVals);
   return theArray;
}
template <class T> CASA::CasaData *casa_wrappers::scalarToSeq(T theVals){
  CASA::CasaData *theArray = new CASA::CasaData(1);
  theArray->length(1);
  theArray[0] = theVals;
  return theArray;
}       
        
template <> CASA::CasaData *casa_wrappers::scalarToSeq<String>(String theVals){
  CASA::CasaDatum *newVal = new CASA::CasaDatum;
  newVal->stringVal(theVals.chars());
  CASA::CasaData *theArray = new CASA::CasaData(1, 1, newVal, 0);
  return theArray;
}       
        
template <> CASA::CasaData *casa_wrappers::scalarToSeq<Complex>(Complex theVals){
  CASA::CasaDatum *newVal = new CASA::CasaDatum;
  newVal->complexVal(toCorbaComplex(theVals));
  CASA::CasaData *theArray = new CASA::CasaData(1, 1, newVal, 0);
  return theArray;
}       
        
template <> CASA::CasaData *casa_wrappers::scalarToSeq<DComplex>(DComplex theVals){
  CASA::CasaDatum *newVal = new CASA::CasaDatum;
  newVal->dcomplexVal(toCorbaDComplex(theVals));
  CASA::CasaData *theArray = new CASA::CasaData(1, 1, newVal, 0);
  return theArray;
}       
/*
    A note to myself (wy). In principle each row in a column should define an CasaDatum and then assign that datum
    into a sequence.  What we are doing here is getting all the data into one big vector and letting the shape held
    by the CasaValue tell the user how to reassemble the data.

    So why not just CasaDatum* instead, well this gives us an option of assembling a sequence of CasaDatum as CasaData 
    which we would not have otherwise. 
*/
template <class T> CASA::CasaData *casa_wrappers::arrayToSeq(CASA::CasaFieldType theType, Array<T> &theVals){
  using CASA::CasaDatum;
  CasaDatum *casaDatum = new CasaDatum;
  switch(theType){
      case CASA::ATYPE_Bool: 
      case CASA::ATYPE_ARR_Bool: 
           casaDatum->boolArr(CASA::BoolVec(theVals.nelements(), theVals.nelements(), (CORBA::Boolean *)theVals.data(), 0));
           break;
       case CASA::ATYPE_Short:
       case CASA::ATYPE_ARR_Short:
           casaDatum->shortArr(CASA::ShortVec(theVals.nelements(), theVals.nelements(), (unsigned short *)theVals.data(), 0)); 
           break;
       case CASA::ATYPE_Int:
       case CASA::ATYPE_ARR_Int:
           casaDatum->intArr(CASA::IntVec(theVals.nelements(), theVals.nelements(), (int *)theVals.data(), 0)); 
           break;
       case CASA::ATYPE_UInt:
       case CASA::ATYPE_ARR_UInt:
           casaDatum->uintArr(CASA::UIntVec(theVals.nelements(), theVals.nelements(), (unsigned int *)theVals.data(), 0)); 
           break;
       case CASA::ATYPE_Long:
       case CASA::ATYPE_ARR_Long:
           casaDatum->longArr( CASA::LongVec(theVals.nelements(), theVals.nelements(), (int *)theVals.data(), 0)); 
           //casaDatum->longArr(CASA::LongVec(theVals.nelements(), theVals.nelements(), (int *)theVals.data(), 0)); 
           break;
       case CASA::ATYPE_ULong:
       case CASA::ATYPE_ARR_ULong:
           casaDatum->ulongArr(CASA::ULongVec(theVals.nelements(), theVals.nelements(), (unsigned int *)theVals.data(), 0)); 
           break;
       case CASA::ATYPE_Float:
       case CASA::ATYPE_ARR_Float:
           casaDatum->floatArr(CASA::FloatVec(theVals.nelements(), theVals.nelements(), (float *)theVals.data(), 0)); 
           break;
       case CASA::ATYPE_Complex:
       case CASA::ATYPE_ARR_Complex:
           casaDatum->complexArr(CASA::ComplexVec(theVals.nelements(), theVals.nelements(), (CASA::complex *)theVals.data(), 0)); 
           break;
       case CASA::ATYPE_Double:
       case CASA::ATYPE_ARR_Double:
           casaDatum->doubleArr(CASA::DoubleVec(theVals.nelements(), theVals.nelements(), (double *)theVals.data(), 0)); 
           break;
       case CASA::ATYPE_DComplex:
       case CASA::ATYPE_ARR_DComplex:
           // casaDatum.dcomplexArr = CasaDatum.dcomplexArr(theVals.nelements(), theVals.nelements(), theVals.data(), 0); 
           break;
       case CASA::ATYPE_ARR_String:
            cerr << "In arrayToSeq general" << endl;
           // casaDatum.stringArr = CasaDatum.stringArr(theVals.nelements(), theVals.nelements(), (char **)theVals.data(), 0); 
           break;
       default :
           cerr << "The type was " << theType << endl;
           throw AipsError("Bad array type");
           break;
  }
  CASA::CasaData *theArray = new CASA::CasaData( 1, 1, casaDatum, 0);
  return theArray;
}

template <> CASA::CasaData *casa_wrappers::arrayToSeq<String>(CASA::CasaFieldType theType, Array<String> &theVals){
  using CASA::CasaDatum;
  try {
  cerr << "In arrayToSeq string specialization" << endl;
  cerr << theVals.shape().nelements() << endl;
  CASA::CasaDatum *casaDatum = new CasaDatum[theVals.nelements()];
  Bool deleteIt;
  uInt myElements(1);
  if(theType == CASA::ATYPE_String){
     String *theStringArray = theVals.getStorage(deleteIt);
     for(unsigned int i=0;i<theVals.nelements();i++){
        assignData(&casaDatum[i], theStringArray[i]);
        // casaDatum[i].stringVal(theStringArray[i].chars());
      } 
      myElements = theVals.nelements();
  } else{ 
     // casaDatum[i].stringArr(theStringArray[i].chars());
     assignData(casaDatum, theVals);
     // cerr << theStringArray[i].chars() << endl;
  }
  CASA::CasaData *theArray = new CASA::CasaData(
  myElements,
  myElements,
  casaDatum, 0);
  cerr << "Array set" << endl;
  // theVals.freeStorage(theStringArray, deleteIt);
  return theArray;
  } catch (AipsError x) {
     cerr << x.getMesg() << endl;
     return 0;
  }
}

  // Need to implement this!!!!!!!!!
CASA::CasaData *casa_wrappers::recordToSeq(const RecordInterface &theRec){
  CASA::CasaData *theArray = new CASA::CasaData;
   std::cerr << "Need to implement recordToSeq" << std::endl;
  return theArray;
}

DataType casa_wrappers::fromAFType(CASA::CasaFieldType ft){
   DataType rStat;
   switch(ft){
      case CASA::ATYPE_Bool :
        rStat = TpBool ;
        break;
      case CASA::ATYPE_Char :
        rStat = TpChar;
        break;
      case CASA::ATYPE_UChar :
        rStat = TpUChar;
        break;
      case CASA::ATYPE_Short :
        rStat = TpShort;
        break;
      case CASA::ATYPE_UShort :
        rStat = TpUShort;
        break;
      case CASA::ATYPE_Int :
      case CASA::ATYPE_Long :
        rStat = TpInt;
        break;
      case CASA::ATYPE_UInt :
      case CASA::ATYPE_ULong :
        rStat = TpUInt;
        break;
      case CASA::ATYPE_Float :
        rStat = TpFloat;
        break;
      case CASA::ATYPE_Double :
        rStat = TpDouble;
        break;
      case CASA::ATYPE_Complex :
        rStat = TpComplex;
        break;
      case CASA::ATYPE_DComplex :
        rStat = TpDComplex;
        break;
      case CASA::ATYPE_String :
        rStat = TpString;
        break;
      case CASA::ATYPE_Table :
        rStat = TpTable;
        break;
      case CASA::ATYPE_ARR_Bool :
        rStat = TpArrayBool;
        break;
      case CASA::ATYPE_ARR_Char :
        rStat = TpArrayChar;
        break;
      case CASA::ATYPE_ARR_UChar :
        rStat = TpArrayUChar;
        break;
      case CASA::ATYPE_ARR_Short :
        rStat = TpArrayShort;
        break;
      case CASA::ATYPE_ARR_UShort :
        rStat = TpArrayUShort;
        break;
      case CASA::ATYPE_ARR_Int :
      case CASA::ATYPE_ARR_Long :
        rStat = TpArrayInt;
        break;
      case CASA::ATYPE_ARR_UInt :
      case CASA::ATYPE_ARR_ULong :
        rStat = TpArrayUInt;
        break;
      case CASA::ATYPE_ARR_Float :
        rStat = TpArrayFloat;
        break;
      case CASA::ATYPE_ARR_Double :
        rStat = TpArrayDouble;
        break;
      case CASA::ATYPE_ARR_Complex :
        rStat = TpArrayComplex;
        break;
      case CASA::ATYPE_ARR_DComplex :
        rStat = TpArrayDComplex;
        break;
      case CASA::ATYPE_ARR_String :
        rStat = TpArrayString;
        break;
      case CASA::ATYPE_Record :
        rStat = TpRecord;
        break;
      case CASA::ATYPE_Other :
        rStat = TpOther;
        break;
   }
   return rStat;
}
CASA::IntVec casa_wrappers::shapeToIntVec(const IPosition &shape){
    Vector<Int> myShape = shape.asVector();
    return(*(new CASA::IntVec(myShape.nelements(), myShape.nelements(), (int *)myShape.data(), 0))); 
}

IPosition & casa_wrappers::intVecToShape(CASA::IntVec shape){
   return *(new IPosition(1, 1));
}

CASA::CasaValue&  casa_wrappers::toAValue(CASA::CasaRecord &aRec){
   CASA::CasaValue_var theVal = new CASA::CasaValue;
   theVal->type = CASA::ATYPE_Record;
   Int *dummy = new Int[1];
   dummy[0] = 1;
   theVal->shape = CASA::IntVec(1,1,dummy,0);
   CASA::CasaDatum *theData = new CASA::CasaDatum;
   theData->recordVal(&aRec);
   theVal->value.length(1);
   theVal->value[0] = *theData;
   return *(theVal._retn());
}

CASA::CasaValue& casa_wrappers::toAValue(String &astring){
   cerr << "Converting to an AValue...";
   CASA::CasaValue_var theVal = new CASA::CasaValue;
   theVal->type = CASA::ATYPE_String;
   Int *dummy = new Int[1];
   dummy[0] = 1;
   theVal->shape = CASA::IntVec(1,1,dummy,0);
   CASA::CasaDatum_var theData = new CASA::CasaDatum;
   theData->stringVal(astring.chars());
   theVal->value.length(1);
   theVal->value[0] = *theData;
   return *(theVal._retn());
}

template <class T> CASA::CasaValue& casa_wrappers::toAValue(DataType dt, const RORecordFieldPtr<T> &theField){
   CASA::CasaValue_var theVal = new CASA::CasaValue;
   theVal->type = casa_wrappers::toAFType(dt);
   Int *dummy = new Int[1];
   dummy[0] = 1;
   CASA::IntVec_var myShape = new CASA::IntVec(1, 1, dummy, 0);
   theVal->shape = *myShape._retn();
   CASA::CasaDatum_var theData = new CASA::CasaDatum;
   std::cerr << " " << *theField << endl;
   T myVal = *theField;
   CASA::CasaDatum *theData_ptr = theData._retn();
   casa_wrappers::assignData(theData_ptr, myVal);
   theVal->value.length(1);
   theVal->value[0] = *theData_ptr;
   return *(theVal._retn());
}
template <class T> CASA::CasaValue& casa_wrappers::toAValue(DataType dt, const RORecordFieldPtr<Array <T> > &theField){
   CASA::CasaValue_var theVal = new CASA::CasaValue;
   Array<T> theArray = *theField;
   theVal->type = casa_wrappers::toAFType(dt);
   theVal->shape = casa_wrappers::shapeToIntVec(theArray.shape());
   CASA::CasaDatum_var theData = new CASA::CasaDatum;
   casa_wrappers::assignData(theData, theArray);
   theVal->value.length(1);
   theVal->value[0] = *theData;
   return *(theVal._retn());
}

CASA::CasaFieldType casa_wrappers::toAFType(DataType dt){
   CASA::CasaFieldType rStat;
   switch(dt){
      case TpBool :
        rStat = CASA::ATYPE_Bool;
        break;
      case TpChar :
        rStat = CASA::ATYPE_Char;
        break;
      case TpUChar :
        rStat = CASA::ATYPE_UChar;
        break;
      case TpShort :
        rStat = CASA::ATYPE_UShort;
        break;
      case TpUShort :
        rStat = CASA::ATYPE_UShort;
        break;
      case TpInt :
        rStat = CASA::ATYPE_Int;
        break;
      case TpUInt :
        rStat = CASA::ATYPE_UInt;
        break;
      case TpFloat :
        rStat = CASA::ATYPE_Float;
        break;
      case TpDouble :
        rStat = CASA::ATYPE_Double;
        break;
      case TpComplex :
        rStat = CASA::ATYPE_Complex;
        break;
      case TpDComplex :
        rStat = CASA::ATYPE_DComplex;
        break;
      case TpString :
        rStat = CASA::ATYPE_String;
        break;
      case TpTable :
        rStat = CASA::ATYPE_Table;
        break;
      case TpArrayBool :
        rStat = CASA::ATYPE_ARR_Bool;
        break;
      case TpArrayChar :
        rStat = CASA::ATYPE_ARR_Char;
        break;
      case TpArrayUChar :
        rStat = CASA::ATYPE_ARR_UChar;
        break;
      case TpArrayShort :
        rStat = CASA::ATYPE_ARR_Short;
        break;
      case TpArrayUShort :
        rStat = CASA::ATYPE_ARR_UShort;
        break;
      case TpArrayInt :
        rStat = CASA::ATYPE_ARR_Int;
        break;
      case TpArrayUInt :
        rStat = CASA::ATYPE_ARR_UInt;
        break;
      case TpArrayFloat :
        rStat = CASA::ATYPE_ARR_Float;
        break;
      case TpArrayDouble :
        rStat = CASA::ATYPE_ARR_Double;
        break;
      case TpArrayComplex :
        rStat = CASA::ATYPE_ARR_Complex;
        break;
      case TpArrayDComplex :
        rStat = CASA::ATYPE_ARR_DComplex;
        break;
      case TpArrayString :
        rStat = CASA::ATYPE_ARR_String;
        break;
      case TpRecord :
        rStat = CASA::ATYPE_Record;
        break;
      case TpOther :
        rStat = CASA::ATYPE_Other;
        break;
   }
   return rStat;
}

CASA::CasaField& casa_wrappers::toAField(const String &fieldname, const CASA::CasaValue &theVal){
   CASA::CasaField_var myField = new CASA::CasaField;
   myField->fieldname = CORBA::string_dup(fieldname.chars());
   myField->comment = CORBA::string_dup("");
   myField->value = theVal;
   return *(myField._retn());
}

CASA::CasaField& casa_wrappers::toAField(const String &fieldname, const CASA::CasaRecord &theVal){
   CASA::CasaField_var myField = new CASA::CasaField;
   myField->fieldname = CORBA::string_dup(fieldname.chars());
   myField->comment = CORBA::string_dup("");
   // myField.value(theVal);
   return *(myField._retn());
}

CASA::dcomplex casa_wrappers::toCorbaDComplex(DComplex a){
   CASA::dcomplex c;
   c.re = a.real();
   c.im = a.imag();
   return c;
}

CASA::complex casa_wrappers::toCorbaComplex(Complex a){
   CASA::complex c;
   c.re = a.real();
   c.im = a.imag();
   return c;
}

DComplex casa_wrappers::toDComplex(CASA::dcomplex a){
  return DComplex(a.re, a.im);
}

Complex casa_wrappers::toComplex(CASA::complex a){
  return Complex(a.re, a.im);
}


template CASA::CasaData *casa_wrappers::arrayToSeq<Bool>(CASA::CasaFieldType, Array<Bool> &);
template CASA::CasaData *casa_wrappers::arrayToSeq<uChar>(CASA::CasaFieldType, Array<uChar> &);
template CASA::CasaData *casa_wrappers::arrayToSeq<uShort>(CASA::CasaFieldType, Array<uShort> &);
template CASA::CasaData *casa_wrappers::arrayToSeq<Short>(CASA::CasaFieldType, Array<Short> &);
template CASA::CasaData *casa_wrappers::arrayToSeq<uInt>(CASA::CasaFieldType, Array<uInt> &);
template CASA::CasaData *casa_wrappers::arrayToSeq<Int>(CASA::CasaFieldType, Array<Int> &);
template CASA::CasaData *casa_wrappers::arrayToSeq<DComplex>(CASA::CasaFieldType, Array<DComplex> &);
template CASA::CasaData *casa_wrappers::arrayToSeq<Complex>(CASA::CasaFieldType, Array<Complex> &);
template CASA::CasaData *casa_wrappers::arrayToSeq<Double>(CASA::CasaFieldType, Array<Double> &);
template CASA::CasaData *casa_wrappers::arrayToSeq<Float>(CASA::CasaFieldType, Array<Float> &);
template CASA::CasaData *casa_wrappers::arrayToSeq<String>(CASA::CasaFieldType, Array<String> &);
//
template CASA::CasaData *casa_wrappers::scalarToSeq<String>(String);
template CASA::CasaData *casa_wrappers::scalarToSeq<Complex>(Complex);
template CASA::CasaData *casa_wrappers::scalarToSeq<DComplex>(DComplex);
template CASA::CasaData *casa_wrappers::scalarToSeq<Float>(Float);
template CASA::CasaData *casa_wrappers::scalarToSeq<Double>(Double);
template CASA::CasaData *casa_wrappers::scalarToSeq<Int>(Int);
template CASA::CasaData *casa_wrappers::scalarToSeq<uInt>(uInt);
template CASA::CasaData *casa_wrappers::scalarToSeq<Short>(Short);
template CASA::CasaData *casa_wrappers::scalarToSeq<uShort>(uShort);
template CASA::CasaData *casa_wrappers::scalarToSeq<Bool>(Bool);
template CASA::CasaData *casa_wrappers::scalarToSeq<uChar>(uChar);
//template CASA::CasaData *casa_wrappers::arrayToSeq(CASA::CasaFieldType, Array<Double> &);


template CASA::CasaArray *casa_wrappers::arrayToAA<Bool>(CASA::CasaFieldType, Array<Bool> &);
template CASA::CasaArray *casa_wrappers::arrayToAA<uChar>(CASA::CasaFieldType, Array<uChar> &);
template CASA::CasaArray *casa_wrappers::arrayToAA<uShort>(CASA::CasaFieldType, Array<uShort> &);
template CASA::CasaArray *casa_wrappers::arrayToAA<Short>(CASA::CasaFieldType, Array<Short> &);
template CASA::CasaArray *casa_wrappers::arrayToAA<uInt>(CASA::CasaFieldType, Array<uInt> &);
template CASA::CasaArray *casa_wrappers::arrayToAA<Int>(CASA::CasaFieldType, Array<Int> &);
template CASA::CasaArray *casa_wrappers::arrayToAA<DComplex>(CASA::CasaFieldType, Array<DComplex> &);
template CASA::CasaArray *casa_wrappers::arrayToAA<Complex>(CASA::CasaFieldType, Array<Complex> &);
template CASA::CasaArray *casa_wrappers::arrayToAA<Double>(CASA::CasaFieldType, Array<Double> &);
template CASA::CasaArray *casa_wrappers::arrayToAA<Float>(CASA::CasaFieldType, Array<Float> &);
template CASA::CasaArray *casa_wrappers::arrayToAA<String>(CASA::CasaFieldType, Array<String> &);
//
template CASA::CasaArray *casa_wrappers::scalarToAA<String>(CASA::CasaFieldType, String);
template CASA::CasaArray *casa_wrappers::scalarToAA<Complex>(CASA::CasaFieldType, Complex);
template CASA::CasaArray *casa_wrappers::scalarToAA<DComplex>(CASA::CasaFieldType, DComplex);
template CASA::CasaArray *casa_wrappers::scalarToAA<Float>(CASA::CasaFieldType, Float);
template CASA::CasaArray *casa_wrappers::scalarToAA<Double>(CASA::CasaFieldType, Double);
template CASA::CasaArray *casa_wrappers::scalarToAA<Int>(CASA::CasaFieldType, Int);
template CASA::CasaArray *casa_wrappers::scalarToAA<uInt>(CASA::CasaFieldType, uInt);
template CASA::CasaArray *casa_wrappers::scalarToAA<Short>(CASA::CasaFieldType, Short);
template CASA::CasaArray *casa_wrappers::scalarToAA<uShort>(CASA::CasaFieldType, uShort);
template CASA::CasaArray *casa_wrappers::scalarToAA<Bool>(CASA::CasaFieldType, Bool);
template CASA::CasaArray *casa_wrappers::scalarToAA<uChar>(CASA::CasaFieldType, uChar);
//template CASA::CasaArray *casa_wrappers::arrayToSeq(CASA::CasaFieldType, Array<Double> &);

template CASA::CasaValue& casa_wrappers::toAValue<Bool>(DataType, const RORecordFieldPtr<Array<Bool> > &);
template CASA::CasaValue& casa_wrappers::toAValue<uChar>(DataType, const RORecordFieldPtr<Array<uChar> > &);
template CASA::CasaValue& casa_wrappers::toAValue<uShort>(DataType, const RORecordFieldPtr<Array<uShort> > &);
template CASA::CasaValue& casa_wrappers::toAValue<Short>(DataType, const RORecordFieldPtr<Array<Short> > &);
template CASA::CasaValue& casa_wrappers::toAValue<uInt>(DataType, const RORecordFieldPtr<Array<uInt> > &);
template CASA::CasaValue& casa_wrappers::toAValue<Int>(DataType, const RORecordFieldPtr<Array<Int> > &);
template CASA::CasaValue& casa_wrappers::toAValue<DComplex>(DataType, const RORecordFieldPtr<Array<DComplex> > &);
template CASA::CasaValue& casa_wrappers::toAValue<Complex>(DataType, const RORecordFieldPtr<Array<Complex> > &);
template CASA::CasaValue& casa_wrappers::toAValue<Double>(DataType, const RORecordFieldPtr<Array<Double> > &);
template CASA::CasaValue& casa_wrappers::toAValue<Float>(DataType, const RORecordFieldPtr<Array<Float> > &);
template CASA::CasaValue& casa_wrappers::toAValue<String>(DataType, const RORecordFieldPtr<Array<String > > &);

template CASA::CasaValue& casa_wrappers::toAValue<Bool>(DataType, const RORecordFieldPtr<Bool> &);
template CASA::CasaValue& casa_wrappers::toAValue<uChar>(DataType, const RORecordFieldPtr<uChar> &);
template CASA::CasaValue& casa_wrappers::toAValue<uShort>(DataType, const RORecordFieldPtr<uShort> &);
template CASA::CasaValue& casa_wrappers::toAValue<Short>(DataType, const RORecordFieldPtr<Short> &);
template CASA::CasaValue& casa_wrappers::toAValue<uInt>(DataType, const RORecordFieldPtr<uInt> &);
template CASA::CasaValue& casa_wrappers::toAValue<Int>(DataType, const RORecordFieldPtr<Int> &);
template CASA::CasaValue& casa_wrappers::toAValue<DComplex>(DataType, const RORecordFieldPtr<DComplex> &);
template CASA::CasaValue& casa_wrappers::toAValue<Complex>(DataType, const RORecordFieldPtr<Complex> &);
template CASA::CasaValue& casa_wrappers::toAValue<Double>(DataType, const RORecordFieldPtr<Double> &);
template CASA::CasaValue& casa_wrappers::toAValue<Float>(DataType, const RORecordFieldPtr<Float> &);
template CASA::CasaValue& casa_wrappers::toAValue<String>(DataType, const RORecordFieldPtr<String> &);

// Data assignments have to be specialized

template <> void casa_wrappers::assignData<Bool>(CASA::CasaDatum *theData, const Bool &theField){ std::cerr << "bool" << endl;theData->boolVal(theField); }
template <> void casa_wrappers::assignData<Char>(CASA::CasaDatum *theData, const Char &theField){ std::cerr << "Char" << endl;theData->charVal(theField); }
template <> void casa_wrappers::assignData<uChar>(CASA::CasaDatum *theData, const uChar &theField){ std::cerr << "uChar" << endl;theData->ucharVal(theField); }
template <> void casa_wrappers::assignData<Short>(CASA::CasaDatum *theData, const Short &theField){ std::cerr << "Short" << endl;theData->shortVal(theField); }
template <> void casa_wrappers::assignData<uShort>(CASA::CasaDatum *theData, const uShort &theField){ std::cerr << "uShort" << endl;theData->ushortVal(theField); }
template <> void casa_wrappers::assignData<Int>(CASA::CasaDatum *theData, const Int &theField){ std::cerr << "Int" << endl;theData->intVal(theField); }
template <> void casa_wrappers::assignData<uInt>(CASA::CasaDatum *theData, const uInt &theField){ std::cerr << "uInt" << endl;theData->uintVal(theField); }
template <> void casa_wrappers::assignData<Float>(CASA::CasaDatum *theData, const Float &theField){ std::cerr << "float:" << theField << endl;theData->floatVal(theField); }
template <> void casa_wrappers::assignData<Double>(CASA::CasaDatum *theData, const Double &theField){ std::cerr << "double" << endl;theData->doubleVal(theField); }
template <> void casa_wrappers::assignData<Complex>(CASA::CasaDatum *theData, const Complex &theField){
   CASA::complex myVal;
   myVal.re = theField.real();
   myVal.im = theField.imag();
   std::cerr << "complex" << endl;theData->complexVal(myVal); }
template <> void casa_wrappers::assignData<DComplex>(CASA::CasaDatum *theData, const DComplex &theField){
   CASA::dcomplex myVal;
   myVal.re = theField.real();
   myVal.im = theField.imag();
   std::cerr << "dcomplex" << endl;theData->dcomplexVal(myVal); }
template <> void casa_wrappers::assignData<CASA::CasaRecord>(CASA::CasaDatum *theData, const CASA::CasaRecord  &theField){ theData->recordVal(&theField); }

template <> void casa_wrappers::assignData<Bool>(CASA::CasaDatum *theData, const Array<Bool> &theField){
           theData->boolArr(CASA::BoolVec(theField.nelements(), theField.nelements(), (CORBA::Boolean *)theField.data(), 0)); }

template <> void casa_wrappers::assignData<Char>(CASA::CasaDatum *theData, const Array<Char> &theField){
           theData->charArr(CASA::CharVec(theField.nelements(), theField.nelements(), (char *)theField.data(), 0)); }
template <> void casa_wrappers::assignData<uChar>(CASA::CasaDatum *theData, const Array<uChar> &theField){
           theData->charArr(CASA::CharVec(theField.nelements(), theField.nelements(), (char *)theField.data(), 0)); }
template <> void casa_wrappers::assignData<Short>(CASA::CasaDatum *theData, const Array<Short> &theField){
           theData->shortArr(CASA::ShortVec(theField.nelements(), theField.nelements(), (short *)theField.data(), 0)); }
template <> void casa_wrappers::assignData<uShort>(CASA::CasaDatum *theData, const Array<uShort> &theField){
           theData->ushortArr(CASA::UShortVec(theField.nelements(), theField.nelements(), (unsigned short *)theField.data(), 0)); }
template <> void casa_wrappers::assignData<Int>(CASA::CasaDatum *theData, const Array<Int> &theField){
           theData->intArr(CASA::IntVec(theField.nelements(), theField.nelements(), (int *)theField.data(), 0)); }
template <> void casa_wrappers::assignData<uInt>(CASA::CasaDatum *theData, const Array<uInt> &theField){
           theData->uintArr(CASA::UIntVec(theField.nelements(), theField.nelements(), (unsigned int *)theField.data(), 0)); }
template <> void casa_wrappers::assignData<Float>(CASA::CasaDatum *theData, const Array<Float> &theField){
           theData->floatArr(CASA::FloatVec(theField.nelements(), theField.nelements(), (float *)theField.data(), 0)); }
template <> void casa_wrappers::assignData<Double>(CASA::CasaDatum *theData, const Array<Double> &theField){
           theData->doubleArr(CASA::DoubleVec(theField.nelements(), theField.nelements(), (double *)theField.data(), 0)); }
template <> void casa_wrappers::assignData<Complex>(CASA::CasaDatum *theData, const Array<Complex> &theField){
           theData->complexArr(CASA::ComplexVec(theField.nelements(), theField.nelements(), (CASA::complex *)theField.data(), 0)); }
template <> void casa_wrappers::assignData<DComplex>(CASA::CasaDatum *theData, const Array<DComplex> &theField){
           theData->dcomplexArr(CASA::DComplexVec(theField.nelements(), theField.nelements(), (CASA::dcomplex *)theField.data(), 0)); }

template <> int casa_wrappers::fromAValue<Bool>(Bool &theBool, const CASA::CasaValue &theVal){
   int r_status = True;
   if(theVal.type == CASA::ATYPE_Bool){
      theBool = theVal.value[0].boolVal();
   } else {
      r_status = False;
   }
   return r_status;
}
template <> int casa_wrappers::fromAValue<Char>(Char &theChar, const CASA::CasaValue &theVal){
   int r_status = True;
   if(theVal.type == CASA::ATYPE_Char){
      theChar = theVal.value[0].charVal();
   } else {
      r_status = False;
   }
   return r_status;
}
template <> int casa_wrappers::fromAValue<uChar>(uChar &theuChar, const CASA::CasaValue &theVal){
   int r_status = True;
   if(theVal.type == CASA::ATYPE_UChar){
      theuChar = theVal.value[0].ucharVal();
   } else {
      r_status = False;
   }
   return r_status;
}
template <> int casa_wrappers::fromAValue<Short>(Short &theShort, const CASA::CasaValue &theVal){
   int r_status = True;
   if(theVal.type == CASA::ATYPE_Short){
      theShort = theVal.value[0].shortVal();
   } else {
      r_status = False;
   }
   return r_status;
}
template <> int casa_wrappers::fromAValue<uShort>(uShort &theuShort, const CASA::CasaValue &theVal){
   int r_status = True;
   if(theVal.type == CASA::ATYPE_UShort){
      theuShort = theVal.value[0].ushortVal();
   } else {
      r_status = False;
   }
   return r_status;
}
template <> int casa_wrappers::fromAValue<Int>(Int &theInt, const CASA::CasaValue &theVal){
   int r_status = True;
   if(theVal.type == CASA::ATYPE_Int){
      theInt = theVal.value[0].intVal();
   } else {
      r_status = False;
   }
   return r_status;
}
template <> int casa_wrappers::fromAValue<uInt>(uInt &theuInt, const CASA::CasaValue &theVal){
   int r_status = True;
   if(theVal.type == CASA::ATYPE_UInt){
      theuInt = theVal.value[0].uintVal();
   } else {
      r_status = False;
   }
   return r_status;
}
template <> int casa_wrappers::fromAValue<Float>(Float &theFloat, const CASA::CasaValue &theVal){
   int r_status = True;
   if(theVal.type == CASA::ATYPE_Float){
      theFloat = theVal.value[0].floatVal();
   } else {
      r_status = False;
   }
   return r_status;
}
template <> int casa_wrappers::fromAValue<Double>(Double &theDouble, const CASA::CasaValue &theVal){
   int r_status = True;
   if(theVal.type == CASA::ATYPE_Double){
      theDouble = theVal.value[0].doubleVal();
   } else {
      r_status = False;
   }
   return r_status;
}
template <> int casa_wrappers::fromAValue<Complex>(Complex &theComplex, const CASA::CasaValue &theVal){
   int r_status = True;
   if(theVal.type == CASA::ATYPE_Complex){
      CASA::complex aComplex = theVal.value[0].complexVal();
      theComplex = Complex(aComplex.re, aComplex.im);
   } else {
      r_status = False;
   }
   return r_status;
}
template <> int casa_wrappers::fromAValue<DComplex>(DComplex &theDComplex, const CASA::CasaValue &theVal){
   int r_status = True;
   if(theVal.type == CASA::ATYPE_DComplex){
      CASA::dcomplex aComplex = theVal.value[0].dcomplexVal();
      theDComplex = DComplex(aComplex.re, aComplex.im);
   } else {
      r_status = False;
   }
   return r_status;
}
template <> int casa_wrappers::fromAValue<String>(String &theString, const CASA::CasaValue &theVal){
   int r_status = True;
   if(theVal.type == CASA::ATYPE_String){
      theString = theVal.value[0].stringVal();
   } else {
      r_status = False;
   }
   return r_status;
}

template <> int casa_wrappers::fromAValue<Bool>(Array<Bool> &theBool, const CASA::CasaValue &theVal){
   int r_status = True;
   if(theVal.type == CASA::ATYPE_ARR_Bool){
      Vector<Int> myShape(IPosition(1,theVal.shape.length()), theVal.shape.get_buffer(1));
      theBool = Array<Bool>(myShape, theVal.value[0].boolArr().get_buffer(1));
      for(uint i=1;i<theVal.value.length();i++)
         theBool = concatenateArray(theBool, Array<Bool>(myShape, theVal.value[i].boolArr().get_buffer(1)));
   } else if(theVal.type == CASA::ATYPE_Bool){
      theBool = Vector< Bool > (theVal.value.length());
      for(uint i=0;i<theVal.value.length(); i++)
         static_cast<Vector<Bool> >(theBool)(i) = theVal.value[i].boolVal();
   } else {
      r_status = False;
   }
   return r_status;
}
template <> int casa_wrappers::fromAValue<Char>(Array<Char> &theChar, const CASA::CasaValue &theVal){
   int r_status = True;
   if(theVal.type == CASA::ATYPE_ARR_Char){
      Vector<Int> myShape(IPosition(1,theVal.shape.length()), theVal.shape.get_buffer(1));
      theChar = Array<Char>(myShape, theVal.value[0].charArr().get_buffer(1));
      for(uint i=1;i<theVal.value.length();i++)
         theChar = concatenateArray(theChar, Array<Char>(myShape, theVal.value[i].charArr().get_buffer(1)));
   } else if(theVal.type == CASA::ATYPE_Char){
      theChar = Vector< Char > (theVal.value.length());
      for(uint i=0;i<theVal.value.length(); i++)
         static_cast<Vector<Char> >(theChar)(i) = theVal.value[i].charVal();
   } else {
      r_status = False;
   }
   return r_status;
}
template <> int casa_wrappers::fromAValue<uChar>(Array<uChar> &theuChar, const CASA::CasaValue &theVal){
   int r_status = True;
   if(theVal.type == CASA::ATYPE_ARR_UChar){
      Vector<Int> myShape(IPosition(1,theVal.shape.length()), theVal.shape.get_buffer(1));
      theuChar = Array<uChar>(myShape, (uChar *)theVal.value[0].ucharArr().get_buffer(1));
      for(uint i=1;i<theVal.value.length();i++)
         theuChar = concatenateArray(theuChar, Array<uChar>(myShape, (uChar *)theVal.value[i].ucharArr().get_buffer(1)));
   } else if(theVal.type == CASA::ATYPE_UChar){
      theuChar = Vector< uChar > (theVal.value.length());
      for(uint i=0;i<theVal.value.length(); i++)
         static_cast<Vector<uChar> >(theuChar)(i) = theVal.value[i].ucharVal();
   } else {
      r_status = False;
   }
   return r_status;
}
template <> int casa_wrappers::fromAValue<Short>(Array<Short> &theShort, const CASA::CasaValue &theVal){
   int r_status = True;
   if(theVal.type == CASA::ATYPE_ARR_Short){
      Vector<Int> myShape(IPosition(1,theVal.shape.length()), theVal.shape.get_buffer(1));
      theShort = Array<Short>(myShape, theVal.value[0].shortArr().get_buffer(1));
      for(uint i=1;i<theVal.value.length();i++)
         theShort = concatenateArray(theShort, Array<Short>(myShape, theVal.value[i].shortArr().get_buffer(1)));
   } else if(theVal.type == CASA::ATYPE_Short){
      theShort = Vector< Short > (theVal.value.length());
      for(uint i=0;i<theVal.value.length(); i++)
         static_cast<Vector<Short> >(theShort)(i) = theVal.value[i].shortVal();
   } else {
      r_status = False;
   }
   return r_status;
}
template <> int casa_wrappers::fromAValue<uShort>(Array<uShort> &theuShort, const CASA::CasaValue &theVal){
   int r_status = True;
   if(theVal.type == CASA::ATYPE_ARR_UShort){
      Vector<Int> myShape(IPosition(1,theVal.shape.length()), theVal.shape.get_buffer(1));
      theuShort = Array<uShort>(myShape, theVal.value[0].ushortArr().get_buffer(1));
      for(uint i=1;i<theVal.value.length();i++)
         theuShort = concatenateArray(theuShort, Array<uShort>(myShape, theVal.value[i].ushortArr().get_buffer(1)));
   } else if(theVal.type == CASA::ATYPE_UShort){
      theuShort = Vector< uShort > (theVal.value.length());
      for(uint i=0;i<theVal.value.length(); i++)
         static_cast<Vector<uShort> >(theuShort)(i) = theVal.value[i].ushortVal();
   } else {
      r_status = False;
   }
   return r_status;
}
template <> int casa_wrappers::fromAValue<Int>(Array<Int> &theInt, const CASA::CasaValue &theVal){
   int r_status = True;
   if(theVal.type == CASA::ATYPE_ARR_Int){
      Vector<Int> myShape(IPosition(1, theVal.shape.length()), theVal.shape.get_buffer(1));
      theInt = Array<Int>(myShape, theVal.value[0].intArr().get_buffer(1));
      for(uint i=1;i<theVal.value.length();i++)
         theInt = concatenateArray(theInt, Array<Int>(myShape, theVal.value[i].intArr().get_buffer(1)));
   } else if(theVal.type == CASA::ATYPE_Int){
      theInt = Vector< Int > (theVal.value.length());
      for(uint i=0;i<theVal.value.length(); i++)
         static_cast<Vector<Int> >(theInt)(i) = theVal.value[i].intVal();
   } else {
      r_status = False;
   }
   return r_status;
}
template <> int casa_wrappers::fromAValue<uInt>(Array<uInt> &theuInt, const CASA::CasaValue &theVal){
   int r_status = True;
   if(theVal.type == CASA::ATYPE_ARR_UInt){
      Vector<Int> myShape(IPosition(1,theVal.shape.length()), theVal.shape.get_buffer(1));
      theuInt = Array<uInt>(myShape, theVal.value[0].uintArr().get_buffer(1));
      for(uint i=1;i<theVal.value.length();i++)
         theuInt = concatenateArray(theuInt, Array<uInt>(myShape, theVal.value[i].uintArr().get_buffer(1)));
   } else if(theVal.type == CASA::ATYPE_UInt){
      theuInt = Vector< uInt > (theVal.value.length());
      for(uint i=0;i<theVal.value.length(); i++)
         static_cast<Vector<uInt> >(theuInt)(i) = theVal.value[i].uintVal();
   } else {
      r_status = False;
   }
   return r_status;
}
template <> int casa_wrappers::fromAValue<Float>(Array<Float> &theFloat, const CASA::CasaValue &theVal){
   int r_status = True;
   if(theVal.type == CASA::ATYPE_ARR_Float){
      Vector<Int> myShape(IPosition(1, theVal.shape.length()), theVal.shape.get_buffer(1));
      theFloat = Array<Float>(myShape, theVal.value[0].floatArr().get_buffer(1));
      for(uint i=1;i<theVal.value.length();i++)
         theFloat = concatenateArray(theFloat, Array<Float>(myShape, theVal.value[i].floatArr().get_buffer(1)));
   } else if(theVal.type == CASA::ATYPE_Float){
      theFloat = Vector< Float > (theVal.value.length());
      for(uint i=0;i<theVal.value.length(); i++)
         static_cast<Vector<Float> >(theFloat)(i) = theVal.value[i].floatVal();
   } else {
      r_status = False;
   }
   return r_status;
}
template <> int casa_wrappers::fromAValue<Double>(Array<Double> &theDouble, const CASA::CasaValue &theVal){
   int r_status = True;
   if(theVal.type == CASA::ATYPE_ARR_Double){
      Vector<Int> myShape(IPosition(1, theVal.shape.length()), theVal.shape.get_buffer(1));
      theDouble = Array<Double>(myShape, theVal.value[0].doubleArr().get_buffer(1));
      for(uint i=1;i<theVal.value.length();i++)
         theDouble = concatenateArray(theDouble, Array<Double>(myShape, theVal.value[i].doubleArr().get_buffer(1)));
   } else if(theVal.type == CASA::ATYPE_Double){
      theDouble = Vector< Double > (theVal.value.length());
      for(uint i=0;i<theVal.value.length(); i++)
         static_cast<Vector<Double> >(theDouble)(i) = theVal.value[i].doubleVal();
   } else {
      r_status = False;
   }
   return r_status;
}
/*
	The complex, dcomplex, and String are a horrible mess because I can find a good way to take the memory
        and do the conversion on the fly so we can run with it.
*/
template <> int casa_wrappers::fromAValue<Complex>(Array<Complex> &theComplex, const CASA::CasaValue &theVal){
   int r_status = True;
   if(theVal.type == CASA::ATYPE_ARR_Complex){
      Vector<Int> myShape(IPosition(1,theVal.shape.length()), theVal.shape.get_buffer(1));
      Bool deleteIt;
      {
       Array<Complex> aComplex = Array<Complex>(myShape);
       Complex *myData = aComplex.getStorage(deleteIt);
       CASA::complex *buff = theVal.value[0].complexArr().get_buffer(0);
       for(uInt i=0;i<aComplex.nelements();i++){
          myData[i] = Complex(buff[i].re, buff[i].im);
       }
       aComplex.putStorage(myData, deleteIt);
       theComplex = aComplex;
      }
      for(uint i=1;i<theVal.value.length();i++){
         Array<Complex> aComplex = Array<Complex>(myShape);
         Complex *myData = aComplex.getStorage(deleteIt);
         CASA::complex *buff = theVal.value[i].complexArr().get_buffer(0);
         for(uInt i=0;i<aComplex.nelements();i++){
             myData[i] = Complex(buff[i].re, buff[i].im);
         }
         aComplex.putStorage(myData, deleteIt);
         theComplex = concatenateArray(theComplex, aComplex);
      }
   } else if(theVal.type == CASA::ATYPE_Complex){
      theComplex = Vector< Complex > (theVal.value.length());
      for(uint i=0;i<theVal.value.length(); i++)
         static_cast<Vector<Complex> >(theComplex)(i) = Complex(theVal.value[i].complexVal().re,
                                                                theVal.value[i].complexVal().im);
   } else {
      r_status = False;
   }
   return r_status;
}
template <> int casa_wrappers::fromAValue<DComplex>(Array<DComplex> &theDComplex, const CASA::CasaValue &theVal){
   int r_status = True;
   if(theVal.type == CASA::ATYPE_ARR_DComplex){
      Vector<Int> myShape(IPosition(1,theVal.shape.length()), theVal.shape.get_buffer(1));
      Bool deleteIt;
      {
       Array<DComplex> aDComplex = Array<DComplex>(myShape);
       DComplex *myData = aDComplex.getStorage(deleteIt);
       CASA::complex *buff = theVal.value[0].complexArr().get_buffer(0);
       for(uInt i=0;i<aDComplex.nelements();i++){
          myData[i] = DComplex(buff[i].re, buff[i].im);
       }
       aDComplex.putStorage(myData, deleteIt);
       theDComplex = aDComplex;
      }
      for(uint i=1;i<theVal.value.length();i++){
         Array<DComplex> aDComplex = Array<DComplex>(myShape);
         DComplex *myData = aDComplex.getStorage(deleteIt);
         CASA::complex *buff = theVal.value[i].complexArr().get_buffer(0);
         for(uInt i=0;i<aDComplex.nelements();i++){
             myData[i] = DComplex(buff[i].re, buff[i].im);
         }
         aDComplex.putStorage(myData, deleteIt);
         theDComplex = concatenateArray(theDComplex, aDComplex);
      }
   } else if(theVal.type == CASA::ATYPE_DComplex){
      theDComplex = Vector< DComplex > (theVal.value.length());
      for(uint i=0;i<theVal.value.length(); i++)
         static_cast<Vector<DComplex> >(theDComplex)(i) = DComplex(theVal.value[i].dcomplexVal().re,
                                                                   theVal.value[i].dcomplexVal().im);
   } else {
      r_status = False;
   }
   return r_status;
}
template <> int casa_wrappers::fromAValue<String>(Array<String> &theString, const CASA::CasaValue &theVal){
   int r_status = True;
   if(theVal.type == CASA::ATYPE_ARR_String){
      Bool deleteIt;
      Vector<Int> myShape(IPosition(theVal.shape.length()), theVal.shape.get_buffer(1));
      {
       Array<String> aString = Array<String>(myShape);
       String *myData = aString.getStorage(deleteIt);
       char **buff = theVal.value[0].stringArr().get_buffer(0);
       for(uInt i=0;i<aString.nelements();i++){
           myData[i] = String(buff[i]);
       }
       aString.putStorage(myData, deleteIt);
       theString = aString;
      }
      for(uint i=1;i<theVal.value.length();i++){
         Array<String> aString = Array<String>(myShape);
         aString = Array<String>(myShape);
         Bool deleteIt;
         String *myData = aString.getStorage(deleteIt);
         char **buff = theVal.value[i].stringArr().get_buffer(0);
         for(uInt i=0;i<aString.nelements();i++){
             myData[i] = String(buff[i]);
         }
         aString.putStorage(myData, deleteIt);
         theString = concatenateArray(theString, aString);
      }
   } else if(theVal.type == CASA::ATYPE_Bool){
      theString = Vector< String > (theVal.value.length());
      for(uint i=0;i<theVal.value.length(); i++)
         static_cast<Vector<String> >(theString)(i) = theVal.value[i].stringVal();
   } else {
      r_status = False;
   }
   return r_status;
}

void casa_wrappers::toRecord(RecordInterface &theRec, const CASA::CasaRecord &aRec){
   CASA::CasaFieldVec_var theFields = aRec.getFields();
   for(unsigned int i=0;i<theFields->length();i++){
       CASA::CasaField &af = theFields[i];
       RecordFieldId rfID(af.fieldname);
       switch(af.value.type){
          case CASA::ATYPE_Bool :
            theRec.define(rfID, af.value.value[0].boolVal());
            break;
          case CASA::ATYPE_Char :
            theRec.define(rfID, af.value.value[0].charVal());
            break;
          case CASA::ATYPE_UChar :
            theRec.define(rfID, af.value.value[0].ucharVal());
            break;
          case CASA::ATYPE_Short :
            theRec.define(rfID, af.value.value[0].shortVal());
            break;
          case CASA::ATYPE_UShort :
            theRec.define(rfID, af.value.value[0].ushortVal());
            break;
          case CASA::ATYPE_Int :
            theRec.define(rfID, af.value.value[0].uintVal());
            break;
          case CASA::ATYPE_Long :
            theRec.define(rfID, af.value.value[0].longVal());
            break;
          case CASA::ATYPE_UInt :
            theRec.define(rfID, af.value.value[0].uintVal());
            break;
          case CASA::ATYPE_ULong :
            theRec.define(rfID, af.value.value[0].ulongVal());
            break;
          case CASA::ATYPE_Float :
            theRec.define(rfID, af.value.value[0].floatVal());
            break;
          case CASA::ATYPE_Double :
            theRec.define(rfID, af.value.value[0].doubleVal());
            break;
          case CASA::ATYPE_Complex :
            theRec.define(rfID, toComplex(af.value.value[0].complexVal()));
            break;
          case CASA::ATYPE_DComplex :
            theRec.define(rfID, toDComplex(af.value.value[0].dcomplexVal()));
            break;
          case CASA::ATYPE_String :
            theRec.define(rfID, af.value.value[0].stringVal());
            break;
          case CASA::ATYPE_Table :
            theRec.define(rfID, af.value.value[0].tableVal());
            break;
          case CASA::ATYPE_ARR_Bool :
            {Array<Bool> tmp;
            fromAValue(tmp, af.value);
            theRec.define(rfID, tmp);}
            break;
          case CASA::ATYPE_ARR_Char :
            {Array<uChar> tmp;
            fromAValue(tmp, af.value);
            theRec.define(rfID, tmp);}
            break;
          case CASA::ATYPE_ARR_UChar :
            {Array<uChar> tmp;
            fromAValue(tmp, af.value);
            theRec.define(rfID, tmp);}
            break;
          case CASA::ATYPE_ARR_Short :
            {Array<Short> tmp;
            fromAValue(tmp, af.value);
            theRec.define(rfID, tmp);}
            break;
          case CASA::ATYPE_ARR_UShort :
            {Array<Short> tmp;
            fromAValue(tmp, af.value);
            theRec.define(rfID, tmp);}
            break;
          case CASA::ATYPE_ARR_Int :
            {Array<Int> tmp;
            fromAValue(tmp, af.value);
            theRec.define(rfID, tmp);}
            break;
          case CASA::ATYPE_ARR_Long :
            {Array<Int> tmp;
            fromAValue(tmp, af.value);
            theRec.define(rfID, tmp);}
            break;
          case CASA::ATYPE_ARR_UInt :
            {Array<uInt> tmp;
            fromAValue(tmp, af.value);
            theRec.define(rfID, tmp);}
            break;
          case CASA::ATYPE_ARR_ULong :
            {Array<uInt> tmp;
            fromAValue(tmp, af.value);
            theRec.define(rfID, tmp);}
            break;
          case CASA::ATYPE_ARR_Float :
            {Array<Float> tmp;
            fromAValue(tmp, af.value);
            theRec.define(rfID, tmp);}
            break;
          case CASA::ATYPE_ARR_Double :
            { Array<Double> tmp;
            fromAValue(tmp, af.value);
            theRec.define(rfID, tmp);}
            break;
          case CASA::ATYPE_ARR_Complex :
            { Array<Complex> tmp;
            fromAValue(tmp, af.value);
            theRec.define(rfID, tmp); }
            break;
          case CASA::ATYPE_ARR_DComplex :
            { Array<DComplex> tmp;
            fromAValue(tmp, af.value);
            theRec.define(rfID, tmp); }
            break;
          case CASA::ATYPE_ARR_String :
            {
            Array<String> tmp;
            fromAValue(tmp, af.value);
            theRec.define(rfID, tmp);
            }
            break;
          case CASA::ATYPE_Record :
            { Record tmp;
            casa_wrappers::toRecord(tmp, *af.value.value[0].recordVal()); 
            theRec.defineRecord(rfID, tmp);}
            break;
          case CASA::ATYPE_Other :
            break;
       }
       theRec.setComment(rfID, String(af.comment));
   }
}

template <class T, class CT> Array<T> &casa_wrappers::fromCASAVec(const CT &cv){
    Vector<Int> myShape(IPosition(1, cv.length()));
    Array<T> *theArray = new Array<T>(myShape, cv.get_buffer(1));
    return *theArray;
}

template <> Array<String> &casa_wrappers::fromCASAVec<String, CASA::StringVec>(const CASA::StringVec &cv){
    Vector<Int> myShape(IPosition(1, cv.length()));
    Bool deleteIt;
    Array<String> *aString = new Array<String>(myShape);
    char **buff = cv.get_buffer(0);
    String *myData = aString->getStorage(deleteIt);
    for(uInt i=0;i<aString->nelements();i++){
           myData[i] = String(buff[i]);
    }
    aString->putStorage(myData, deleteIt);
    return *aString;
}
template Array<Int>    &casa_wrappers::fromCASAVec<Int, CASA::IntVec>(const CASA::IntVec &);
template Array<Bool>   &casa_wrappers::fromCASAVec<Bool, CASA::BoolVec>(const CASA::BoolVec &);
template Array<Float>  &casa_wrappers::fromCASAVec<Float, CASA::FloatVec>(const CASA::FloatVec &);
template Array<Double> &casa_wrappers::fromCASAVec<Double, CASA::DoubleVec>(const CASA::DoubleVec &);


// The following is a patch for some missing templates not found in the system
// They need to be added but to avoid needing to regenerate the RPMS we define
// them here for now.
#ifdef CASA2TEMPLATES
#include <casa/Arrays/ArrayUtil.cc>
template Array<Char> concatenateArray<Char>(Array<Char> const &, Array<Char> const &);
template Array<uChar> concatenateArray<uChar>(Array<uChar> const &, Array<uChar> const &);
template Array<Short> concatenateArray<Short>(Array<Short> const &, Array<Short> const &);
template Array<uShort> concatenateArray<uShort>(Array<uShort> const &, Array<uShort> const &);
#endif
