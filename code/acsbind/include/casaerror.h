#ifndef  casaerror_h_
#define  casaerror_h_
/******************************************************************************
*    ALMA - Atacama Large Millimiter Array
*
* "@(#) $Id: casaerror.h,v 1.1 2005/05/27 22:51:08 wyoung Exp $"
*
* who       when          what
* --------  --------      ----------------------------------------------
* darrell   2003-11-06    added header
*/

namespace casa {
class AipsError;

};

namespace casa_wrappers {

    class error {
      public:
	enum Type {
	  BOUNDARY, INITIALIZATION, INVALID_ARGUMENT, CONFORMANCE,
	  ENVIRONMENT, SYSTEM, PERMISSION, GENERAL
	};

	error( const error & );
	error &operator=( const error & );
	error( const ::casa::AipsError & );
	error( const char *, Type t=GENERAL );
	~error( );

	const char *message( ) const { return message_; }
	unsigned int type( ) const { return type_; }

      private:
	error( );
        char *message_;
	unsigned int type_;
    };
};

#endif
