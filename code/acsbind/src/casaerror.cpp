#include <stdlib.h>
#include <string.h>
#include <casaerror.h>
#include <casa/Exceptions/Error.h>
#include <ACSErrTypeCommonC.h>

using namespace casa;

casa_wrappers::error::error( const casa_wrappers::error &other ) :
			message_(strdup(other.message_)), type_(other.type_) { }

casa_wrappers::error &casa_wrappers::error::operator=( const error &other ) {
    message_ = strdup( other.message_ );
    type_ = other.type_;
    return *this;
}

casa_wrappers::error::error( const AipsError &err ) {
    message_ = strdup( err.getMesg( ).chars( ) );
    switch ( err.getCategory( ) ) {
      case AipsError::BOUNDARY:
	type_ = ACSErrTypeCommon::OutOfBounds;
	break;
      case AipsError::INITIALIZATION:
	type_ = ACSErrTypeCommon::OutOfBounds;
	break;
      case AipsError::INVALID_ARGUMENT:
	type_ = ACSErrTypeCommon::OutOfBounds;
	break;
      case AipsError::CONFORMANCE:
	type_ = ACSErrTypeCommon::OutOfBounds;
	break;
      case AipsError::ENVIRONMENT:
	type_ = ACSErrTypeCommon::OutOfBounds;
	break;
      case AipsError::SYSTEM:
	type_ = ACSErrTypeCommon::OutOfBounds;
	break;
      case AipsError::PERMISSION:
	type_ = ACSErrTypeCommon::OutOfBounds;
	break;
      default:
	type_ = ACSErrTypeCommon::OutOfBounds;
    }
}

casa_wrappers::error::error( const char *m, Type t ) {
    message_ = strdup(m);
    switch ( t ) {
      case BOUNDARY:
	type_ = ACSErrTypeCommon::OutOfBounds;
	break;
      case INITIALIZATION:
	type_ = ACSErrTypeCommon::OutOfBounds;
	break;
      case INVALID_ARGUMENT:
	type_ = ACSErrTypeCommon::OutOfBounds;
	break;
      case CONFORMANCE:
	type_ = ACSErrTypeCommon::OutOfBounds;
	break;
      case ENVIRONMENT:
	type_ = ACSErrTypeCommon::OutOfBounds;
	break;
      case SYSTEM:
	type_ = ACSErrTypeCommon::OutOfBounds;
	break;
      case PERMISSION:
	type_ = ACSErrTypeCommon::OutOfBounds;
	break;
      default:
	type_ = ACSErrTypeCommon::OutOfBounds;
    }
}

casa_wrappers::error::~error( ) { free(message_); }
