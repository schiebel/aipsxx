#ifndef comdefs_h_
#define comdefs_h_

#define SP " "

#define HANDLE_CTOR_ERROR(STR)					\
		{						\
		frame = 0;					\
		SetError( new Value( STR ) );			\
		return;						\
		}

#define InvalidArg( num )						\
	{								\
	global_store->Error( "invalid type for argument " #num );	\
	return;								\
	}

#define InvalidNumberOfArgs( num )					\
	{								\
	global_store->Error( "invalid number of arguments, expected " #num ); \
	return;								\
	}

#define SETINIT								\
        VecRef *ref = args->Type() == TYPE_SUBVEC_REF ? args->VecRefPtr( ) : 0; \
	Value *args_ = ref ? args->VecRefDeref() : args;		\
	if ( args_->Type() != TYPE_RECORD )				\
		{							\
		global_store->Error("bad value #10");  			\
		return;							\
		}							\
									\
	Ref( args_ );							\
	recordptr rptr = args_->RecordPtr(0);				\
	int c = 0, erri=0, tx_index = 0;				\
	const char *key;

#define SETDONE Unref(args_);

#define SETVAL(var,condition)						\
	const Value *var##_raw_ = rptr->NthEntry( c++, key )->Deref();	\
	VecRef *var##_ref_ = var##_raw_->Type() == TYPE_SUBVEC_REF ? var##_raw_->VecRefPtr( ) : 0; \
	const Value *var = var##_ref_ ? var##_raw_->VecRefDeref() : var##_raw_; \
	if ( ! (condition) )						\
		InvalidArg(c-1);

//########HERE WE ARE########
#define gtkType(var) (var->Type( ))
#define gtkLength(var) (var##_raw_->Length( ))
#define gtkIsNumeric(var) (var->IsNumeric( ))
#define gtkAccessV(proxy,lhs,var,accessor,result) lhs = var##_raw_->accessor;
#define gtkAccess(proxy,lhs,var,accessor,idx,result)			\
	erri = 0;							\
	tx_index = var##_ref_ ? var##_ref_->TranslateIndex( idx, &erri ) : idx; \
	if ( erri )							\
		{							\
		proxy->Error( "invalid sub_vector" );			\
		return result;						\
		}							\
	lhs = (var->accessor)[ tx_index ];

//########HERE WE ARE########

#define SETSTR(var)							\
	SETVAL(var##_v_, gtkType(var##_v_) == TYPE_STRING &&		\
			 gtkLength(var##_v_) > 0 )			\
	gtkAccess( global_store,charptr var,var##_v_,StringPtr(0),0,)

#define SETDIM(var)							\
	SETVAL(var##_v_, gtkType(var##_v_) == TYPE_STRING &&		\
			 gtkLength(var##_v_) > 0   ||			\
			 gtkIsNumeric(var##_v_))			\
	char var##_char_[30];						\
	charptr var = 0;						\
	if ( gtkType(var##_v_) == TYPE_STRING )				\
		{							\
		gtkAccess(global_store,var,var##_v_,StringPtr(0),0,)	\
		}							\
	else								\
		{							\
		gtkAccessV(global_store,int v,var##_v_,IntVal(),)	\
		sprintf(var##_char_,"%d", v);				\
		var = var##_char_;					\
		}
#define SETINT(var)							\
	SETVAL(var##_v_, gtkIsNumeric(var##_v_) &&			\
				gtkLength(var##_v_) > 0 )		\
	gtkAccessV(global_store,int var,var##_v_,IntVal(),)

#define SETDOUBLE(var)							\
	SETVAL(var##_v_, gtkIsNumeric(var##_v_) &&			\
				gtkLength(var##_v_) > 0 )		\
	gtkAccessV(global_store,double var,var##_v_,DoubleVal(),)

#define EXPRINIT(proxy,EVENT)						\
	int erri=0, tx_index = 0;					\
	if ( args->Deref()->Type() != TYPE_RECORD )			\
		{							\
		proxy->Error("bad value #1");				\
		return 0;						\
		}							\
									\
	/*Ref(args);*/							\
	recordptr rptr = args->Deref()->RecordPtr(0);			\
	int c = 0;							\
	const char *key;

#define EXPRVAL(proxy, var,EVENT)					\
	const Value *var##_raw_ = rptr->NthEntry( c++, key )->Deref( ); \
	VecRef *var##_ref_ = var##_raw_->Type() == TYPE_SUBVEC_REF ? var##_raw_->VecRefPtr( ) : 0; \
	const Value *var = var##_ref_ ? var##_raw_->VecRefDeref() : var##_raw_; \
	if ( ! var )							\
		{							\
		proxy->Error("bad value #2");				\
		return 0;						\
		}

#define EXPRSTRVALXX(proxy,var,EVENT,LINE)				\
	EXPRVAL(proxy,var,EVENT);					\
	LINE								\
	if ( gtkType(var) != TYPE_STRING || gtkLength(var) <= 0 )	\
		{							\
		proxy->Error("bad value #3 %d", (char*) gtkType(var));	\
		proxy->Error("bad value #3 %s", var->StringVal());	\
		proxy->Error("bad value #3");				\
		sleep(120);						\
		return 0;						\
		}

#define EXPRSTRVAL(proxy,var,EVENT) EXPRSTRVALXX(proxy,var,EVENT,)

#define EXPRSTR(proxy, var,EVENT)					\
	charptr var = 0;						\
	EXPRSTRVALXX(proxy, var##_val_, EVENT,)				\
	gtkAccess(proxy,var,var##_val_,StringPtr(0),0,0)

#define EXPRDIM(var,EVENT)						\
	EXPRVAL(global_store,var##_val_,EVENT)				\
	charptr var = 0;						\
	char var##_char_[30];						\
	if ( gtkType(var##_val_) != TYPE_STRING && ! gtkIsNumeric(var##_val_) || \
		gtkLength(var##_val_) <= 0 )				\
		{							\
		global_store->Error("bad value #4");			\
		return 0;						\
		}							\
	else								\
		if ( gtkType(var##_val_) == TYPE_STRING	)		\
			{						\
			gtkAccess(global_store,var,var##_val_,StringPtr(0),0,0) \
			}						\
		else							\
			{						\
			gtkAccessV(global_store,int v,var##_val_,IntVal(),0) \
			sprintf(var##_char_,"%d", v);			\
			var = var##_char_;				\
			}

#define EXPRINTVALXX(proxy,var,EVENT,LINE)				\
	EXPRVAL(proxy,var,EVENT)					\
	LINE								\
	if ( ! gtkIsNumeric(var) || gtkLength(var) <= 0 )		\
		{							\
		proxy->Error("bad value #5");				\
		return 0;						\
		}

#define EXPRINTVAL(proxy,var,EVENT)  EXPRINTVALXX(proxy,var,EVENT, const Value *var##_val_ = var;)

#define EXPRINT(proxy,var,EVENT)					\
	EXPRINTVALXX(proxy,var##_val_,EVENT,)				\
	gtkAccessV(proxy,int var,var##_val_,IntVal(),0)

#define EXPRINT2(proxy,var,EVENT)					\
	EXPRVAL(proxy,var##_val_,EVENT)					\
        char var##_char_[30];						\
	charptr var = 0;						\
	if ( gtkLength(var##_val_) <= 0 )				\
		{							\
		proxy->Error("bad value #6");				\
		return 0;						\
		}							\
	if ( gtkIsNumeric(var##_val_) )					\
		{							\
		gtkAccessV(proxy,int var##_int_,var##_val_,IntVal(),0)	\
		var = var##_char_;					\
		sprintf(var##_char_,"%d",var##_int_);			\
		}							\
	else if ( gtkType(var##_val_) == TYPE_STRING )			\
		{							\
		gtkAccess(proxy,var,var##_val_,StringPtr(0),0,0)	\
		}							\
	else								\
		{							\
		proxy->Error("bad type: %s", EVENT);			\
		return 0;						\
		}

#define EXPR_DONE(var)

#define HASARG( proxy, args, cond )				\
	if ( ! (args->Length() cond) )				\
		{						\
		proxy->Error("wrong number of arguments");	\
		return 0;					\
		}

#define DEFINE_DTOR(CLASS,FREE)				\
CLASS::~CLASS( )					\
	{						\
	if ( frame )					\
		{					\
		frame->RemoveElement( this );		\
		frame->Pack();				\
		}					\
	UnMap();					\
	FREE						\
	}

#define CREATE_RETURN						\
	if ( ! ret || ! ret->IsValid() )			\
		{						\
		Value *err = ret->GetError();			\
		if ( err )					\
			{					\
			global_store->Error( err );		\
			Unref( err );				\
			}					\
		else						\
			global_store->Error( "tk widget creation failed" ); \
		}						\
	else							\
		ret->SendCtor("newtk");				\
								\
	SETDONE

#define GENERATE_TAG(BUFFER,CANVAS,TYPE) 		\
	sprintf(BUFFER,"c%x%s%x",CANVAS->WidgetCount(),TYPE,CANVAS->NewItemCount(TYPE));


extern Value *glishtk_tkcast( const char *tk );

#endif
