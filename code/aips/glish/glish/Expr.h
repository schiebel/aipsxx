// $Id: Expr.h,v 19.12 2004/11/03 20:38:58 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997,1998,2000 Associated Universities Inc.
#ifndef expr_h
#define expr_h

#include "Glish/Dict.h"
#include "IValue.h"
#include "Frame.h"
#include "Regex.h"

class Stmt;
class Expr;
class Func;
class UserFunc;
class EventDesignator;
class Sequencer;
class ParameterPList;
class Frame;

glish_declare(PList,Expr);
glish_declare(PDict,Expr);

typedef PList(Expr) expr_list;

extern int shutting_glish_down;

class ParseNode : public GlishObject {
    public:
	ParseNode() { }
	virtual int canDelete() const;
	};

inline void NodeRef( GlishObject *obj )
	{
	Ref( obj );
	}
inline void NodeUnref( GlishObject *obj )
	{
	Unref( obj );
	}
inline void NodeUnref( ParseNode *obj )
	{
	if ( obj && obj->canDelete() )
		Unref( obj );
	}

// Different variable access; used by the VarExpr
//	PARSE_ACCESS --  the variable has been parsed for the purpose of
//			 constructing a frame
//      USE_ACCESS   --  the variable has been used in an expression
//
typedef enum { PARSE_ACCESS, USE_ACCESS } access_type;

// Various ways the scope of a value can be modified
//      SCOPE_UNKNOWN --  no particular modification
//      SCOPE_LHS     --  left hand side of an assignment
//      SCOPE_RHS     --  right hand side of an assignment
//
typedef enum { SCOPE_UNKNOWN, SCOPE_LHS, SCOPE_RHS } scope_modifier;

inline void *scope_type_to_void(scope_type i)
	{
	void *ret = 0;
	*((int*)&ret) = i;
	return ret;
	}

inline scope_type void_to_scope_type(void *v)
	{
	return (scope_type) *(int*)&v;
	}

glish_declare(List,scope_type);
typedef List(scope_type) scope_type_list;

class back_offsets_type : public GlishRef {
    public:
	back_offsets_type( int size=3 ) : scope(size), frame(size), s(size) { }
	int length( ) const { return s.length(); }
	void set( int index, int off, int soff, scope_type type );
	int offset( int i ) { return frame[i]; }
	int soffset( int i ) { return scope[i]; }
	scope_type type( int i ) { return  s[i]; }
    private:
	offset_list scope;
	offset_list frame;
	scope_type_list s;
};

class evalOpt {
    public:
	// Different types of expression evaluation: evaluate and return a
	// modifiable copy of the result; evaluate and return a read-only
	// version of the result (which will subsequently be released using
	// Expr::ReadOnlyDone); or evaluate for side effects only, and return
	enum exprType { COPY=0, READ_ONLY=1, SIDE_EFFECTS=2,
			READ_ONLY_PRESERVE=3, COPY_PRESERVE=4 };

	// Different types of flags used in the evaluation of statements. These
	// are primarily for flow control, e.g. continue with loop or stop.
	// VALUE_NEEDED is included because it is the only outstanding statement
	// evaluation flag, it indicates if a return value is expected or not.
	enum flowType { NEXT=5, LOOP=6, BREAK=7, RETURN=8 };
	enum returnType { VALUE_NEEDED=9, RESULT_PERISHABLE=10, RHS_RESULT=11, PRESERVE_FIELDNAMES=12, BOOL_INITIAL=13 };

	evalOpt( ) : mask(0), fcount(0), backrefs(0) { }
	evalOpt( exprType t ) : mask(1<<t), fcount(0), backrefs(0) { }
	evalOpt( flowType t ) : mask(1<<t), fcount(0), backrefs(0) { }
	evalOpt( returnType t ) : mask(1<<t), fcount(0), backrefs(0) { }

	// This is sort of messed up... the copy ctor preserves all flags
	// but the assignment operator doesn't fiddle with the flow flags.
	// This is due to the semantics of Expr and Stmt flags, Stmt functions
	// were built using reference semantics while Expr functions used
	// value semantics... need to work on this...
	evalOpt( const evalOpt &o ) : mask(o.mask), fcount(o.fcount), backrefs(o.backrefs) { if ( backrefs ) Ref(backrefs); }
	evalOpt &operator=( const evalOpt &o ) { mask = o.mask & ~0x1e0 | mask & 0x1e0; fcount = o.fcount; return *this; }

	void clear_backrefs( ) { if ( backrefs ) Unref(backrefs); backrefs=0; }

	void set( flowType t ) { mask = mask & ~0x1e0 | 1<<t; }
	void set( exprType t ) { mask = mask & ~0x1f | 1<<t; }

	void clear( returnType t ) { mask &= ~1<<t; }
	void set( returnType t ) { mask |= 1<<t; }

	// handle the function depth count
	void clearfc( ) { fcount = 0; }
	unsigned int getfc( ) { return fcount; }
	void incfc( ) { ++fcount; }
	void decfc( ) { --fcount; }

	// evaluation types/modes
	inline static unsigned short mCOPY( unsigned short mask=~((unsigned short) 0) ) { return mask & 1<<COPY; }
	inline static unsigned short mREAD_ONLY( unsigned short mask=~((unsigned short) 0) ) { return mask & 1<<READ_ONLY; }
	inline static unsigned short mSIDE_EFFECTS( unsigned short mask=~((unsigned short) 0) ) { return mask & 1<<SIDE_EFFECTS; }
	inline static unsigned short mREAD_ONLY_PRESERVE( unsigned short mask=~((unsigned short) 0) ) { return mask & 1<<READ_ONLY_PRESERVE; }
	inline static unsigned short mCOPY_PRESERVE( unsigned short mask=~((unsigned short) 0) ) { return mask & 1<<COPY_PRESERVE; }
	// statement flow types
	inline static unsigned short mNEXT( unsigned short mask=~((unsigned short) 0) ) { return mask & 1<<NEXT; }
	inline static unsigned short mLOOP( unsigned short mask=~((unsigned short) 0) ) { return mask & 1<<LOOP; }
	inline static unsigned short mBREAK( unsigned short mask=~((unsigned short) 0) ) { return mask & 1<<BREAK; }
	inline static unsigned short mRETURN( unsigned short mask=~((unsigned short) 0) ) { return mask & 1<<RETURN; }
	// statement return mode
	inline static unsigned short mVALUE_NEEDED( unsigned short mask=~((unsigned short) 0) ) { return mask & 1<<VALUE_NEEDED; }
	inline static unsigned short mRESULT_PERISHABLE( unsigned short mask=~((unsigned short) 0) ) { return mask & 1<<RESULT_PERISHABLE; }
	inline static unsigned short mRHS_RESULT( unsigned short mask=~((unsigned short) 0) ) { return mask & 1<<RHS_RESULT; }
	inline static unsigned short mPRESERVE_FIELDNAMES( unsigned short mask=~((unsigned short) 0) ) { return mask & 1<<PRESERVE_FIELDNAMES; }
	inline static unsigned short mBOOL_INITIAL( unsigned short mask=~((unsigned short) 0) ) { return mask & 1<<BOOL_INITIAL; }

	// evaluation types/modes
	int copy() const { return mCOPY(mask); }
	int read_only() const { return mREAD_ONLY(mask); }
	int side_effects() const { return mSIDE_EFFECTS(mask); }
	int read_only_preserve() const { return mREAD_ONLY_PRESERVE(mask); }
        int copy_preserve() const { return mCOPY_PRESERVE(mask); }

	// statement flow types
	int Next() const { return mNEXT(mask); }		// continue on to next statement
	int Loop() const { return mLOOP(mask); }		// go to top of loop
	int Break() const { return mBREAK(mask); }		// break out of loop
	int Return() const { return mRETURN(mask); }		// return from function

	// statement return mode
	int value_needed() const { return mVALUE_NEEDED(mask); }
	int result_perishable() const { return mRESULT_PERISHABLE(mask); }
	int rhs_result() const { return mRHS_RESULT(mask); }
	int preserve_fieldnames() const { return mPRESERVE_FIELDNAMES(mask); }
	int bool_initial() const { return mBOOL_INITIAL(mask); }

	// References to global or wider values discovered while evaluating
	back_offsets_type &Backrefs( );
	int HaveBackRefs( ) const { return backrefs ? 1 : 0; }
	back_offsets_type *TakeBackrefs( ) { back_offsets_type *t = backrefs; backrefs = 0; return t; }

	~evalOpt( );

    protected:
	unsigned short mask;
	// count of function depth
	unsigned int fcount;
	back_offsets_type *backrefs;
};

typedef void (*change_var_notice)(IValue*,IValue*);
class Expr : public ParseNode {
    public:
	Expr( ) { }

	// Returns a copy of the present value of the event expression.
	// The caller is responsible for deleting the copy when done
	// using it.
	//
	// If 'perserve' is true, it implies that no Deref()s etc. (which
	// would otherwise be harmless) should be done.
	IValue* CopyEval( evalOpt &opt, int preserve = 0 )
		{ opt.set(preserve ? evalOpt::COPY_PRESERVE : evalOpt::COPY); return Eval(opt); }

	// Returns a read-only copy (i.e., the original) of the present
	// value of the event expression.  The caller is responsible for
	// later calling ReadOnlyDone() when the copy is no longer needed.
	//
	// If 'perserve' is true, it implies that no Deref()s etc. (which
	// would otherwise be harmless) should be done.
	const IValue* ReadOnlyEval( evalOpt &opt, int preserve = 0 )
		{ opt.set(preserve ? evalOpt::READ_ONLY_PRESERVE : evalOpt::READ_ONLY); return Eval(opt); }

	// Declares that the previously returned ReadOnlyEval() value
	// is no longer needed.
	void ReadOnlyDone( const IValue* returned_value )
		{ Unref( (IValue*) returned_value ); }


	// Returns the present value of the event expression.  If
	// "modifiable" is true then a modifiable version of the value is
	// returned; otherwise, a read-only copy.
	virtual IValue* Eval( evalOpt &opt ) = 0;

	// Returns true if this expression is going to do an echo of itself
	// AS PART OF EVALUATION, I.E. "Eval()", if trace is turned on.
	virtual int DoesTrace( ) const;

	// Evaluates the Expr just for side-effects.
	virtual IValue *SideEffectsEval( evalOpt & );


	// Returns a reference to the value of the event expression.
	// If val_type is VAL_REF then a "ref" reference is returned,
	// otherwise a "const" reference.
	//
	// The reference should be Unref()'d once done using it.
	virtual IValue* RefEval( evalOpt &opt, value_reftype val_type );


	// Assigns a new value to the variable (LHS) corresponding
	// to this event expression, if appropriate.  The passed
	// value becomes the property of the Expr, which must
	// subsequently take care of garbage collecting it as necessary
	// (in particular, next time a value is Assign()'d, the value
	// should be deleted).
	//
	// Note that new_value can be nil (providing that index is nil,
	// too), in which case the old value
	// is deleted and the value set to nil.  Used for things like
	// formal parameters where it's desirable to free up the memory
	// used by their values as soon as the function call is complete,
	// rather than waiting for the next call to the function (and
	// subsequent assignment to the formal parameters).
	virtual IValue *Assign( evalOpt &opt, IValue* new_value );

	// Applies a regular expression to the expression. This is done
	// here because the regular expression lilely modifies the value
	// beneath the regular expression.
	virtual IValue *ApplyRegx( regexptr *ptr, int len, RegexMatch &match );

	// Returns true if, when evaluated as a statement, this expression's
	// value should be "invisible" - i.e., the statement's value is "no
	// value" (false).
	virtual int Invisible() const;

	// Because the scoping of a value can be determined by its location
	// within an expression, e.g. LHS or RHS, this function is a wrapper
	// around the function which actually does the work, i.e.
	// DoBuildFrameInfo(). DoBuildFrameInfo() traverses the tree and
	// fixes up any unresolved variables. This wrapper is required
	// so that any "Expr*"s which removed from the tree and placed on
	// the deletion list can be cleaned up. "VarExpr"s can be pruned
	// from the tree as their scope is resolved.
	Expr *BuildFrameInfo( scope_modifier );

	// Used by SendEventExpr to decide if this is a "send" event or
	// a "request" event, i.e. is a return value expected.
	virtual void StandAlone( );

	// Used by AssignExpr::Eval() to prevent assignments like:
	//
	//	y := y
	//	const y := y
	//	etc:
	//
	// from messing up the ref'ness of the RHS
	virtual int LhsIs( const Expr * ) const;

	virtual int FrameOffset( ) const;

	// This should not be called outside of the Expr hierarchy. Use
	// BuildFrameInfo() instead.
	virtual Expr *DoBuildFrameInfo( scope_modifier, expr_list & );

	virtual ~Expr();

	// Where it is important, these functions allow a notify function
	// to be set which will be called when the Expr is modified.
	virtual void SetChangeNotice(change_var_notice);
	virtual void ClearChangeNotice( );

    protected:
	// Return either a copy of the given value, or a reference to
	// it, depending on opt.  If opt is SIDE_EFFECTS, a
	// warning is generated and 0 returned.
	IValue* CopyOrRefValue( const IValue* value, evalOpt &opt );
	};


class VarExpr : public Expr {
    public:
	VarExpr( char* var_id, scope_type scope, int scope_offset,
			int frame_offset, Sequencer* sequencer, int bool_initial = 0 );

	VarExpr( char *var_id, Sequencer *sequencer );

	~VarExpr();

	const char *Description() const;

	IValue* Eval( evalOpt &opt );
	IValue* RefEval( evalOpt &opt, value_reftype val_type );

	const char* VarID()	 { return id; }
	int FrameOffset( ) const;
	int offset() const	 { return frame_offset; }
	int soffset() const	 { return scope_offset; }
	scope_type Scope() const { return scope; }
	change_var_notice change_func() const { return func; }
	void set( scope_type scope, int scope_offset, int frame_offset );

	Expr *DoBuildFrameInfo( scope_modifier, expr_list & );

	access_type Access() { return access; }

	// Used by Sequencer::DeleteVal (and in turn by 'symbol_delete()')
	void change_id( char * );

	void SetChangeNotice(change_var_notice);
	void ClearChangeNotice( );

	//
	// These prevent/allow these preliminary frames to be used
	// in preference to 'sequencer'. It is necessary to disable
	// these preliminary frames when "invoking" the function
	// (i.e. just after the parameters have been assigned) due
	// to recursive function calls.
	//
	void HoldFrames( ) { hold_frames = 1; }
	void ReleaseFrames( ) { hold_frames = 0; }

	//
	// These are local frames which are only used in the process
	// of establishing invocation parameters for a function.
	// 'PopFrame()' does an implicit 'HoldFrames()' because this
	// is typically what you want when filling function parameters,
	// and 'PushFrame()' does an implicit 'ReleaseFrames()'.
	//
	// These 'Push/PopFrame()', 'Hold/ReleaseFrame()' functions
	// were needed for function invocation to handle things like:
	//
	//	func foo( x, y = x * 8 ) { return y }
	//
	//
	void PushFrame( Frame *f ) { frames.append(f); ReleaseFrames(); }
	void PopFrame( );

	IValue *Assign( evalOpt &opt, IValue* new_value );
	IValue *ApplyRegx( regexptr *rptr, int rlen, RegexMatch &match );

	// This Assignment forces VarExpr to use 'f' instead of going
	// to the 'sequencer'. This result in a 'PushFrame(f)' too.
	IValue *Assign( evalOpt &opt, IValue* new_value, Frame *f )
		{ PushFrame( f ); return Assign( opt, new_value ); }

	int LhsIs( const Expr * ) const;

    protected:
	char* id;
	scope_type scope;
	int frame_offset;
	int scope_offset;
	Sequencer* sequencer;
	access_type access;
	change_var_notice func;
	frame_list frames;
	int hold_frames;
	int init_to_bool;
	};


class ScriptVarExpr : public VarExpr {
    public:
	ScriptVarExpr( char* vid, scope_type sc, int soff, 
			int foff, Sequencer* sq ) 
		: VarExpr( vid, sc, soff, foff, sq ) { }

	ScriptVarExpr( char *vid, Sequencer *sq )
		: VarExpr ( vid, sq ) { }

	Expr *DoBuildFrameInfo( scope_modifier, expr_list & );

	~ScriptVarExpr();
	};


// These functions are used to create the VarExpr. There may be times
// when a  variable must be initialized just before it is first used,
// e.g. "script" which cannot be initialized earlier because it isn't
// known if it is multithreaded or not.
VarExpr *CreateVarExpr( char *id, Sequencer *seq );
VarExpr *CreateVarExpr( char *id, scope_type scope, int scope_offset,
			int frame_offset, Sequencer *seq,
			change_var_notice f=0, int bool_initial=0 );

class ValExpr : public Expr {
    public:
	ValExpr( IValue *v ) : val(v) { Ref(val); }

	~ValExpr();

	const char *Description() const;

	IValue* Eval( evalOpt &opt );
	IValue* RefEval( evalOpt &opt, value_reftype val_type );

    protected:
	IValue *val;
	};

class ConstExpr : public Expr {
    public:
	ConstExpr( const IValue* const_value );

	IValue* Eval( evalOpt &opt );
	int Describe( OStream &s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	~ConstExpr();

	const char *Description() const;

    protected:
	const IValue* const_value;
	};


class FuncExpr : public Expr {
    public:
	FuncExpr( UserFunc* f, IValue *attr=0 );

	IValue* Eval( evalOpt &opt );
	int Describe( OStream &s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	~FuncExpr();

	const char *Description() const;

    protected:
	UserFunc* func;
	IValue *attributes;
	};


class UnaryExpr : public Expr {
    public:
	UnaryExpr( Expr* operand );

	IValue* Eval( evalOpt &opt ) = 0;
	int Describe( OStream &s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	Expr *DoBuildFrameInfo( scope_modifier, expr_list & );

	~UnaryExpr();

    protected:
	Expr* op;
	};


class BinaryExpr : public Expr {
    public:
	BinaryExpr( Expr* op1, Expr* op2 );

	IValue* Eval( evalOpt &opt ) = 0;
	int Describe( OStream &s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	Expr *DoBuildFrameInfo( scope_modifier, expr_list & );

	~BinaryExpr();

    protected:
	Expr* left;
	Expr* right;
	};



class NegExpr : public UnaryExpr {
    public:
	NegExpr( Expr* operand );

	IValue* Eval( evalOpt &opt );

	const char *Description() const;
	};


class NotExpr : public UnaryExpr {
    public:
	NotExpr( Expr* operand );

	IValue* Eval( evalOpt &opt );

	const char *Description() const;
	};

class GenerateExpr : public UnaryExpr {
    public:
	GenerateExpr( Expr* operand );

	IValue* Eval( evalOpt &opt );

	const char *Description() const;
	};


class AssignExpr : public BinaryExpr {
    public:
	AssignExpr( Expr* op1, Expr* op2 );

	IValue* Eval( evalOpt &opt );
	IValue *SideEffectsEval( evalOpt & );
	int Invisible() const;

	Expr *DoBuildFrameInfo( scope_modifier, expr_list & );

	const char *Description() const;
	};


class OrExpr : public BinaryExpr {
    public:
	OrExpr( Expr* op1, Expr* op2 );

	IValue* Eval( evalOpt &opt );

	const char *Description() const;
	};


class AndExpr : public BinaryExpr {
    public:
	AndExpr( Expr* op1, Expr* op2 );

	IValue* Eval( evalOpt &opt );

	const char *Description() const;
	};


class ConstructExpr : public Expr {
    public:
	ConstructExpr( ParameterPList* args );

	IValue* Eval( evalOpt &opt );
	int Describe( OStream &s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	~ConstructExpr();

	const char *Description() const;

    protected:
	IValue* BuildArray( evalOpt &opt );
	IValue* BuildRecord( evalOpt &opt );

	//
	//  0 => OK, !0 == error value
	//
	IValue *AllEquivalent( const IValue* values[], int num_values,
				glish_type& max_type );
	IValue *TypeCheck( const IValue* values[], int num_values,
			       glish_type& max_type, int &records );
	IValue *MaxNumeric( const IValue* values[], int num_values,
				glish_type& max_type );

	IValue* ConstructArray( const IValue* values[], int num_values,
				int total_length, glish_type max_type );

	IValue* ConstructRecord( const IValue* values[], int num_values );

	int is_array_constructor;
	ParameterPList* args;
	const char *err;
	};


class ArrayRefExpr : public UnaryExpr {
    public:
	ArrayRefExpr( Expr* op1, expr_list* a );

	IValue* Eval( evalOpt &opt );
	IValue* RefEval( evalOpt &opt, value_reftype val_type );

	IValue *Assign( evalOpt &opt, IValue* new_value );
	IValue *ApplyRegx( regexptr *ptr, int len, RegexMatch &match );

	int Describe( OStream &s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	~ArrayRefExpr();

	const char *Description() const;

    protected:
	IValue *CallFunc(Func *fv, evalOpt &opt, ParameterPList *);
	expr_list* args;
	};


class RecordRefExpr : public UnaryExpr {
    public:
	RecordRefExpr( Expr* op, char* record_field );

	IValue* Eval( evalOpt &opt );
	IValue* RefEval( evalOpt &opt, value_reftype val_type );

	IValue *Assign( evalOpt &opt, IValue* new_value );

	int Describe( OStream &s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	~RecordRefExpr();

	const char *Description() const;

    protected:
	char* field;
	};


class AttributeRefExpr : public BinaryExpr {
    public:
	AttributeRefExpr( Expr* op1 );
	AttributeRefExpr( Expr* op1, Expr* op2 );
	AttributeRefExpr( Expr* op, char* attribute );

	IValue* Eval( evalOpt &opt );
	IValue* RefEval( evalOpt &opt, value_reftype val_type );

	IValue *Assign( evalOpt &opt, IValue* new_value );

	int Describe( OStream &s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	Expr *DoBuildFrameInfo( scope_modifier, expr_list & );

	~AttributeRefExpr();

	const char *Description() const;

    protected:
	char* field;
	};


class RefExpr : public UnaryExpr {
    public:
	RefExpr( Expr* op, value_reftype type );

	IValue* Eval( evalOpt &opt );
	IValue *Assign( evalOpt &opt, IValue* new_value );

	int Describe( OStream &s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	const char *Description() const;

	int LhsIs( const Expr * ) const;

    protected:
	value_reftype type;
	};


class RangeExpr : public BinaryExpr {
    public:
	RangeExpr( Expr* op1, Expr* op2 );

	IValue* Eval( evalOpt &opt );

	const char *Description() const;
	};


class ApplyRegExpr : public BinaryExpr {
    public:
	ApplyRegExpr( Expr* op1, Expr* op2, Sequencer *s, int in_place_ = 0 );

	IValue* Eval( evalOpt &opt );

	const char *Description() const;
    protected:
	Sequencer *sequencer;
	int in_place;
	};


class CallExpr : public UnaryExpr {
    public:
	CallExpr( Expr* func, ParameterPList* args, Sequencer *seq_arg );

	IValue* Eval( evalOpt &opt );
	IValue *SideEffectsEval( evalOpt & );
	int DoesTrace( ) const;

	int Describe( OStream &s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	~CallExpr();

	const char *Description() const;

    protected:
	ParameterPList* args;
	Sequencer* sequencer;
	};

class IncludeExpr : public UnaryExpr {
    public:
	IncludeExpr( Expr* file, Sequencer *seq_arg );
	IValue* Eval( evalOpt &opt );
	const char *Description() const;
    protected:
	Sequencer* sequencer;
	};


class SendEventExpr : public Expr {
    public:
	SendEventExpr( EventDesignator* sender, ParameterPList* args );

	IValue* Eval( evalOpt &opt );
	IValue* SideEffectsEval( evalOpt & );

	void StandAlone( );

	int Describe( OStream &s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	~SendEventExpr();

	const char *Description() const;

    protected:
	EventDesignator* sender;
	ParameterPList* args;
	int is_request_reply;
	Expr *in_subsequence;
	};


typedef enum { EVENT_AGENT, EVENT_NAME, EVENT_VALUE } last_event_type;

class LastEventExpr : public Expr {
    public:
	LastEventExpr( Sequencer* sequencer, last_event_type type );

	IValue* Eval( evalOpt &opt );
	IValue* RefEval( evalOpt &opt, value_reftype val_type );
	int Describe( OStream &s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	const char *Description() const;

    protected:
	Sequencer* sequencer;
	last_event_type type;
	};

typedef enum { REGEX_MATCH } last_regex_type;

class LastRegexExpr : public Expr {
    public:
	LastRegexExpr( Sequencer* sequencer, last_regex_type type );

	IValue* Eval( evalOpt &opt );
	IValue* RefEval( evalOpt &opt, value_reftype val_type );
	int Describe( OStream &s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	const char *Description() const;

    protected:
	Sequencer* sequencer;
	last_regex_type type;
	};


extern void describe_expr_list( const expr_list* list, OStream& s );


#endif /* expr_h */
