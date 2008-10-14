#include "tkUtil.h"
#include "comdefs.h"

Value *glishtk_str( const char *str )
	{
	return new Value( str );
	}

Value *glishtk_strtoint( const char *str )
	{
	return new Value( atoi(str) );
	}

const char *glishtk_onestr( TkProxy *proxy, const char *cmd, Value *args )
	{
	char *ret = 0;

	if ( args->Type() == TYPE_STRING )
		{
		const char *str = args->StringPtr(0)[0];
		tcl_VarEval( proxy, Tk_PathName(proxy->Self( )), " config ", cmd, " {", str, "}", (char *)NULL );
		ret = Tcl_GetStringResult(proxy->Interp( ));
		}
	else
		{
		tcl_VarEval( proxy, Tk_PathName(proxy->Self( )), " cget ", cmd, (char *)NULL );
		ret = Tcl_GetStringResult(proxy->Interp( ));
		}

	return ret;
	}

const char *glishtk_onedim(TkProxy *proxy, const char *cmd, Value *args )
	{
	char *ret = 0;

	if ( args->Type() == TYPE_STRING )
		tcl_VarEval( proxy, Tk_PathName(proxy->Self( )), " config ", cmd, SP, args->StringPtr(0)[0], (char *)NULL );
	else if ( args->IsNumeric() && args->Length() > 0 )
		{
		char buf[30];
		sprintf(buf,"%d",args->IntVal());
		tcl_VarEval( proxy, Tk_PathName(proxy->Self( )), " config ", cmd, SP, buf, (char *)NULL );
		}
	else
		{
		tcl_VarEval( proxy, Tk_PathName(proxy->Self( )), " cget ", cmd, (char *)NULL );
		ret = Tcl_GetStringResult(proxy->Interp( ));
		}

	return ret;
	}

