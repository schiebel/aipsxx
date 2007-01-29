#ifndef AcsLogSink_h_
#define AcsLogSink_h_

#include <casa/Logging/LogSinkInterface.h>

namespace casa {
class LogFilter;
class LogMessage;
};

class AcsLogSink : public casa::LogSinkInterface {
public:

    AcsLogSink( );
    AcsLogSink( const casa::LogFilter &filter );

    AcsLogSink( const AcsLogSink &other );
    AcsLogSink &operator=( const AcsLogSink &other );

    ~AcsLogSink();

    virtual casa::Bool postLocally(const casa::LogMessage &message);

    virtual void flush();

  // Returns the id for this class...
  static casa::String localId( );
  // Returns the id of the LogSink in use...
  casa::String id( ) const;

private:

};

#endif
