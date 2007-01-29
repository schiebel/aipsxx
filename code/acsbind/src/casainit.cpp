#include <casainit.h>
#include <AcsLogSink.h>
#include <casa/Logging/LogSink.h>

//##   #0  0x44798ff6 in twiddle_thumbs() ()
//##       at /home/casa++/stable/code/casa/implement/Logging/StreamLogSink.cc:36
//##   #1  0x447991ce in StreamLogSink (this=0x817f6c8, filter=@0xbeffdefc, theStream=0x413bccc0)
//##       at /home/casa++/stable/code/casa/implement/Logging/StreamLogSink.cc:53
//##   #2  0x443a6d63 in LogSink (this=0x4373d360)
//##       at /home/casa++/stable/code/casa/implement/Logging/LogSink.cc:56
//##   #3  0x443a3159 in LogIO (this=0x4373d360, OR=@0xbeffdf8c)
//##       at /home/casa++/stable/code/casa/implement/Logging/LogIO.cc:46
//##   #4  0x432009c6 in __static_initialization_and_destruction_0(int, int) ()
//##      from /home/casa++/stable/linux/lib/libtrial.so
//##   #5  0x43200d44 in _GLOBAL__I__ZN10RFFlagCube4flagE () from /home/casa++/stable/linux/lib/libtrial.so
//##   #6  0x43442205 in __do_global_ctors_aux () from /home/casa++/stable/linux/lib/libtrial.so
//##   #7  0x428f78a5 in _init () from /home/casa++/stable/linux/lib/libtrial.so

using namespace casa;

void *casa_wrappers::casainit::sink = 0;

casa_wrappers::casainit::casainit( ) {
    if ( LogSink::nullGlobalSink( ) ) {
	if ( ! sink ) sink = new AcsLogSink( );
	LogSink::globalSink( (LogSinkInterface*) sink );
    } else {
	if ( LogSink::globalSink( ).id( )  != AcsLogSink::localId( ) ) {
	    if ( ! sink ) sink = new AcsLogSink( );
	    LogSink::globalSink( (LogSinkInterface*) sink );
	}
    }
}
