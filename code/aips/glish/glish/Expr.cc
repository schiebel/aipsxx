// $Id: Expr.cc,v 19.14 2004/11/03 20:38:58 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997,1998,2000,2004 Associated Universities Inc.

#include "Glish/glish.h"
RCSID("@(#) $Id: Expr.cc,v 19.14 2004/11/03 20:38:58 cvsmgr Exp $")
#include "system.h"
#include <string.h>
#include <stdlib.h>

#include "Glish/Reporter.h"
#include "Sequencer.h"
#include "Expr.h"
#include "Agent.h"
#include "Func.h"
#include "Frame.h"
#include "Regex.h"
#include "File.h"

int ParseNode::canDelete() const
	{
	return 1;
	}

void back_offsets_type::set( int index, int off, int soff, scope_type type )
	{
	int len = length();
	if ( index < len )
		{
		frame.replace( index, off );
		scope.replace( index, soff );
		s.replace( index, type );
		}
	else if ( index == len )
		{
		frame.append( off );
		scope.append( soff );
		s.append( type );
		}
	else
		glish_fatal->Report( "offset added past end of list in back_offsets_type::set()" );

	}

back_offsets_type &evalOpt::Backrefs( )
	{
	if ( ! backrefs ) backrefs = new back_offsets_type;
	return *backrefs;
	}

evalOpt::~evalOpt( )
	{
	Unref( backrefs );
	}

Expr::~Expr() { }

IValue *Expr::SideEffectsEval( evalOpt &opt )
	{
	const IValue* v = ReadOnlyEval( opt );

	if ( v )
		{
		glish_type t = v->Type();

		if ( t == TYPE_FAIL )
			{
			IValue *ret = copy_value(v);
			ReadOnlyDone( v );
			return ret;
			}

		ReadOnlyDone( v );
		}

	return 0;
	}

IValue* Expr::RefEval( evalOpt &opt, value_reftype val_type )
	{
	IValue* value = CopyEval(opt);
	IValue* result;

	if ( val_type == VAL_VAL || val_type == VAL_CONST )
		{
		result = value;
		Ref( value );
		}

	else
		result = new IValue( value, val_type );

	Unref( value );	// result is now the only pointer to value

	return result;
	}

IValue *Expr::Assign( evalOpt &, IValue * )
	{
	return (IValue*) Fail( this, "is not a valid target for assignment" );
	}

IValue *Expr::ApplyRegx( regexptr* /* ptr */, int /*len*/, RegexMatch & /* match */ )
	{
	return (IValue*) Fail( this, "is not a valid target for regex application" );
	}

int Expr::Invisible() const
	{
	return 0;
	}

int Expr::DoesTrace( ) const
	{
	return 0;
	}

Expr *Expr::BuildFrameInfo( scope_modifier m )
	{
	expr_list dl;
	Expr *ret = DoBuildFrameInfo( m, dl );

	loop_over_list( dl, i )
		Unref( dl[i] );

	return ret;
	}

void Expr::StandAlone( ) { }
	
int Expr::LhsIs( const Expr * ) const { return 0; }

int Expr::FrameOffset( ) const { return -1; }

Expr *Expr::DoBuildFrameInfo( scope_modifier, expr_list & )
	{
	return this;
	}

IValue* Expr::CopyOrRefValue( const IValue* value, evalOpt &opt )
	{
	if ( opt.copy() || opt.copy_preserve() )
		{
		IValue *result = 0;
		if ( value->IsRef() && opt.copy_preserve() )
			result = new IValue( (IValue*) value->Deref(), VAL_REF );
		else
			result = copy_value( value );

// 		if ( value->IsConst() )
// 			result->MakeConst();
		if ( value->IsModConst() )
			result->MakeModConst();
		return result;
		}

	else if ( opt.read_only() || opt.read_only_preserve() )
		{
		IValue* result = (IValue*) value;
		Ref( result );
		return result;
		}

	else
		{
		// SIDE_EFFECTS should've been caught earlier; making it
		// this far indicates that the function erroneously overrode
		// SideEffectsEval().
		glish_fatal->Report( "bad evalOpt::Type in Expr::CopyOrRefValue" );
		return 0;
		}
	}

void Expr::SetChangeNotice(change_var_notice) { }
void Expr::ClearChangeNotice( ) { }

const char *VarExpr::Description() const
	{
	return id;
	}

void VarExpr::PopFrame( )
	{
	int len = frames.length();
	if ( len )
		frames.remove_nth( len - 1 );
	HoldFrames( );
	}

VarExpr::~VarExpr()
	{
	//
	// if scope_offset is less than 0, then this VarExpr is
	// simply a reference to a global variable.
	//
	if ( scope_offset >= 0 )
		free_memory(id);
	}

void VarExpr::change_id( char *newid )
	{
	//
	// if scope_offset is less than 0, then this VarExpr is
	// simply a reference to a global variable.
	//
	if ( scope_offset >= 0 )
		free_memory( id );
	else
		scope_offset = 0;

	id = newid;
	}

VarExpr::VarExpr( char* var_id, scope_type var_scope, int var_scope_offset,
			int var_frame_offset, Sequencer* var_sequencer,
			int bool_initial ) : access(PARSE_ACCESS), init_to_bool(bool_initial)
	{

	id = var_id;
	scope = var_scope;
	frame_offset = var_frame_offset;
	scope_offset = var_scope_offset;
	sequencer = var_sequencer;
	func = 0;
	hold_frames = 0;
	if ( scope_offset < 0 ) sequencer->RegisterBackRef( this );
	}

VarExpr::VarExpr( char* var_id, Sequencer* var_sequencer ) : access(PARSE_ACCESS), init_to_bool( 0 )
	{
	id = string_dup(var_id);
	sequencer = var_sequencer;
	scope = ANY_SCOPE;
	scope_offset = 0;
	func = 0;
	hold_frames = 0;
	if ( scope_offset < 0 ) sequencer->RegisterBackRef( this );
	}

void VarExpr::set( scope_type var_scope, int var_scope_offset,
			int var_frame_offset )
	{
	scope = var_scope;
	frame_offset = var_frame_offset;
	scope_offset = var_scope_offset;
	if ( scope_offset < 0 ) sequencer->RegisterBackRef( this );
	}

IValue* VarExpr::Eval( evalOpt &opt )
	{
	access = USE_ACCESS;
	IValue *value = 0;
	int len = frames.length();
	if ( len && ! hold_frames )
		value = frames[len-1]->FrameElement( frame_offset );
	else
		value = sequencer->FrameElement( scope, scope_offset,
						 frame_offset );

	if ( ! value )
		{
		value = init_to_bool || ! sequencer->FailDefault( ) ? false_ivalue( ) :
			(IValue*) Fail( "uninitialized ", scope == GLOBAL_SCOPE ? "global" : "local",
					" variable", this, "used", ! strcmp(id,"quit") ?
					"; use \"exit\" to quit" : "" );
		value->MarkUninitialized( );
		sequencer->SetFrameElement( scope, scope_offset, 
						frame_offset, value );
		}

	if ( ! opt.read_only_preserve() && ! opt.copy_preserve() )
		value = (IValue*) value->Deref();

	return CopyOrRefValue( value, opt );
	}

IValue* VarExpr::RefEval( evalOpt &opt, value_reftype val_type )
	{
	access = USE_ACCESS;
	IValue* var = 0;
	int len = frames.length();
	if ( len && ! hold_frames )
		var = frames[len-1]->FrameElement( frame_offset );
	else
		var = sequencer->FrameElement( scope, scope_offset,
					       frame_offset );

	if ( ! var )
		{
		// Presumably we're going to be assigning to a subelement.
		var = init_to_bool || opt.bool_initial( ) || ! sequencer->FailDefault( ) ? false_ivalue( ) :
		      (IValue*) Fail( "uninitialized ", scope == GLOBAL_SCOPE ? "global" : "local",
				      " variable", this, "used", ! strcmp(id,"quit") ?
				      "; use \"exit\" to quit" : "" );
		var->MarkUninitialized( );
		sequencer->SetFrameElement( scope, scope_offset,
						frame_offset, var );
		}

	if ( func )
		(*func)( var, var );

	if ( val_type == VAL_VAL || val_type == VAL_CONST )
		return copy_value( var );

	return new IValue( var, val_type );
	}

IValue *VarExpr::Assign( evalOpt &, IValue* new_value )
	{
	access = USE_ACCESS;

	VarExpr *ve = 0;
	if ( scope == GLOBAL_SCOPE && scope_offset != 0 &&
	     (ve = (VarExpr*)(*sequencer->GetScope())[id]) )
		ve->access = USE_ACCESS;

	const char *err = 0;

	int len = frames.length();
	if ( len && ! hold_frames )
		{
		IValue*& frame_value = frames[len-1]->FrameElement( frame_offset );
		IValue *prev_value = frame_value;
		frame_value = new_value;
		Unref( prev_value );
		}
	else
		err = sequencer->SetFrameElement( scope, scope_offset,
						  frame_offset, new_value, func );

	return err ? (IValue*) Fail(err) : 0;
	}

IValue *VarExpr::ApplyRegx( regexptr* rptr, int rlen, RegexMatch &match )
	{
	access = USE_ACCESS;

	IValue *value = 0;
	int len = frames.length();
	if ( len && ! hold_frames )
		value = frames[len-1]->FrameElement( frame_offset );
	else
		value = sequencer->FrameElement( scope, scope_offset,
						 frame_offset );

	if ( ! value )
		{
		value = init_to_bool || ! sequencer->FailDefault( ) ? false_ivalue( ) :
			(IValue*) Fail( "uninitialized ", scope == GLOBAL_SCOPE ? "global" : "local",
					" variable", this, "used" );
		value->MarkUninitialized( );
		sequencer->SetFrameElement( scope, scope_offset, frame_offset, value );
		return (IValue*) Fail( "bad type for regular expression application" );
		}

	value = (IValue*) value->Deref();
	return value->ApplyRegx( rptr, rlen, match );
	}

Expr *VarExpr::DoBuildFrameInfo( scope_modifier m, expr_list &dl )
	{

	if ( scope != ANY_SCOPE )
		return this;

	Expr *ret = 0;

	int created = 0;
	switch ( m )
		{
		case SCOPE_LHS:
			ret = sequencer->LookupVar( string_dup(id), LOCAL_SCOPE,
							this, created );
			break;
		case SCOPE_UNKNOWN:
		case SCOPE_RHS:
			ret = sequencer->LookupVar( string_dup(id), ANY_SCOPE,
							this, created );
			break;
		default:
			glish_fatal->Report("bad scope modifier tag in VarExpr::DoBuildFrameInfo()");
		}

	if ( ret && ret != this )
		{
		if ( ! dl.is_member(this) )
			dl.append( this );

		if ( ! created )
			Ref(ret);

		if ( RefCount() > 1 )
			Unref(this);
		}
	else
		dl.remove( this );

	return ret;
	}

void VarExpr::SetChangeNotice(change_var_notice nf)
	{
	func = nf;
	}

void VarExpr::ClearChangeNotice( )
	{
	func = 0;
	}

int VarExpr::LhsIs( const Expr *e ) const
	{
	return e == this;
	}

int VarExpr::FrameOffset( ) const
	{
	return offset( );
	}

ScriptVarExpr::~ScriptVarExpr() { }

Expr *ScriptVarExpr::DoBuildFrameInfo( scope_modifier m, expr_list &dl )
	{
	Expr *ret = 0;
	if ( sequencer->ScriptCreated() )
		return VarExpr::DoBuildFrameInfo( m, dl );
	else
		{
		sequencer->ScriptCreated( 1 );
		ret = VarExpr::DoBuildFrameInfo( m, dl );
		sequencer->ScriptCreated( 0 );
		}

	if ( ! ret )
		return ret;

	if ( ((VarExpr*)ret)->Scope() == GLOBAL_SCOPE )
		{
		evalOpt opt;
		const IValue *v = ret->ReadOnlyEval(opt);
		if ( v->Type() == TYPE_BOOL )
			sequencer->InitScriptClient( opt );
		ret->ReadOnlyDone( v );
		}

	return ret;
	}

VarExpr *CreateVarExpr( char *id, Sequencer *seq )
	{
	if ( seq->DoingInit() && ! seq->ScriptCreated() &&
			! strcmp( id, "script" ) )
		return new ScriptVarExpr( id, seq );
	return new VarExpr( id, seq );
	}

VarExpr *CreateVarExpr( char *id, scope_type sc, int soff, int foff, 
			Sequencer *seq, change_var_notice f, int bool_initial )
	{
	if ( seq->DoingInit() && ! seq->ScriptCreated() &&
			! strcmp( id, "script" ) )
		return new ScriptVarExpr( id, sc, soff, foff, seq );
	VarExpr *ret = new VarExpr( id, sc, soff, foff, seq, bool_initial );
	if ( f ) ret->SetChangeNotice( f );
	return ret;
	}


const char *ValExpr::Description() const
	{
	return "value";
	}

ValExpr::~ValExpr()
	{
	Unref(val);
	}

IValue* ValExpr::Eval( evalOpt &opt )
	{
	return CopyOrRefValue( val, opt );
	}

IValue* ValExpr::RefEval( evalOpt &opt, value_reftype val_type )
	{
	return new IValue( val, val_type );
	}


ConstExpr::~ConstExpr()
	{
	Unref((GlishObject*)const_value);
	}

const char *ConstExpr::Description() const
	{
	return "constant";
	}

ConstExpr::ConstExpr( const IValue* value )
	{
	const_value = value;
	}

IValue* ConstExpr::Eval( evalOpt &opt )
	{
	opt.set( evalOpt::RESULT_PERISHABLE );
	return CopyOrRefValue( const_value, opt );
	}

int ConstExpr::Describe( OStream &s, const ioOpt &opt ) const
	{
	return const_value->Describe( s, opt );
	}


FuncExpr::~FuncExpr()
	{
	Unref(func);
	Unref(attributes);
	}

const char *FuncExpr::Description() const
	{
	return "function";
	}

FuncExpr::FuncExpr( UserFunc* f, IValue *attr )
	{
	func = f;
	attributes = attr;
	}

IValue* FuncExpr::Eval( evalOpt &opt )
	{
	UserFunc *ret = func->clone();
	ret->EstablishScope();
	IValue *retval = new IValue( ret );
	if ( attributes ) retval->AssignAttributes(copy_value(attributes));
	return retval;
	}

int FuncExpr::Describe( OStream& s, const ioOpt &opt ) const
	{
	if ( opt.prefix() ) s << opt.prefix();
	func->Describe( s, ioOpt(opt.flags(),opt.sep()) );
	return 1;
	}

UnaryExpr::~UnaryExpr()
	{
	NodeUnref( op );
	}

UnaryExpr::UnaryExpr( Expr* operand )
	{
	op = operand;
	}

int UnaryExpr::Describe( OStream &s, const ioOpt &opt ) const
	{
	GlishObject::Describe( s, opt );
	op->Describe( s, ioOpt(opt.flags(),opt.sep()) );
	return 1;
	}

Expr *UnaryExpr::DoBuildFrameInfo( scope_modifier m, expr_list &dl )
	{
	Expr *n = op->DoBuildFrameInfo( m, dl );
	if ( n != op )
		{
		if ( ! dl.is_member(op) )
			dl.append(op);
		op = n;
		}
	return this;
	}

BinaryExpr::~BinaryExpr()
	{
	NodeUnref( left );
	NodeUnref( right );
	}

BinaryExpr::BinaryExpr( Expr* op1, Expr* op2 )
	{
	left = op1;
	right = op2;
	}


int BinaryExpr::Describe( OStream &s, const ioOpt &opt ) const
	{
	if ( opt.prefix() ) s << opt.prefix();
	s << "(";
	left->Describe( s, ioOpt(opt.flags(),opt.sep()) );
	s << " ";
	GlishObject::Describe( s, ioOpt(opt.flags(),opt.sep()) );
	s << " ";
	right->Describe( s, ioOpt(opt.flags(),opt.sep()) );
	s << ")";
	return 1;
	}

Expr *BinaryExpr::DoBuildFrameInfo( scope_modifier m, expr_list &dl )
	{
	left = left->DoBuildFrameInfo( m, dl );
	right = right->DoBuildFrameInfo( m, dl );
	return this;
	}


NegExpr::NegExpr( Expr* operand ) : UnaryExpr( operand )
	{
	}

IValue* NegExpr::Eval( evalOpt &opt )
	{
	IValue* result = op->CopyEval( opt, opt.copy_preserve() );
	result->Negate();
	return result;
	}

const char *NegExpr::Description() const
	{
	return "-";
	}

NotExpr::NotExpr( Expr* operand ) : UnaryExpr( operand )
	{
	}

IValue* NotExpr::Eval( evalOpt &opt )
	{
	IValue* result = op->CopyEval( opt, opt.copy_preserve() );
	result->Not();
	return result;
	}

const char *NotExpr::Description() const
	{
	return "!";
	}

GenerateExpr::GenerateExpr( Expr* operand ) : UnaryExpr( operand )
	{
	}

IValue* GenerateExpr::Eval( evalOpt &opt )
	{
	const IValue* file_val = op->ReadOnlyEval(opt);

	if ( file_val->Type() != TYPE_FILE )
		{
		op->ReadOnlyDone( file_val );
		return (IValue*) Fail( "argument not a file" );
		}

	fileptr file = file_val->FileVal();

	if ( file->type() != File::IN &&
	     file->type() != File::PIN &&
	     file->type() != File::PBOTH )
		{
		op->ReadOnlyDone( file_val );
		return (IValue*) Fail( "cannot read from this file" );
		}

	char *string = file->read_line();
	IValue *result = 0;

	if ( string )
		result = new IValue( string );
	else
		{
		result = empty_ivalue();
		result->Polymorph( TYPE_STRING );
		}

	op->ReadOnlyDone( file_val );
	return result;
	}

const char *GenerateExpr::Description() const
	{
	return "<>";
	}

const char *AssignExpr::Description() const
	{
	return ":=";
	}

AssignExpr::AssignExpr( Expr* op1, Expr* op2 ) : BinaryExpr(op1, op2)
	{
	}

IValue* AssignExpr::Eval( evalOpt &opt )
	{
	evalOpt lopt(opt);		// save state of options

	IValue *r_err = 0;
	opt.set( evalOpt::RHS_RESULT );
	IValue *r = right->CopyEval( opt, left->LhsIs(right) ? 1 : 0 );

	if ( ! r ) return 0;
	if ( r->Type() == TYPE_FAIL )
		r_err = copy_value(r);

	opt = lopt;

	if ( opt.Return() )
		opt.set( evalOpt::RESULT_PERISHABLE );

	evalOpt lhsOpt(opt);
	lhsOpt.set(evalOpt::BOOL_INITIAL);
	IValue *l_err = left->Assign( lhsOpt, r );

	//
	// In this case we had an expression like:
	//
	//	print [a=1,b=2,c=3]:::=[print=[precision=10]]
	//
	if ( l_err && opt.result_perishable( ) )
		{
		if ( ! lopt.side_effects() )
			return l_err;
		else if ( l_err->Type() == TYPE_FAIL )
			return l_err;
		else
			{
			Unref( l_err );
			return 0;
			}
		}
	else if ( r_err )
		return r_err;
	if ( l_err && l_err->Type() == TYPE_FAIL )
		return (IValue*) Fail( l_err );

	if ( lopt.copy() || lopt.copy_preserve() )
		return left->CopyEval(lopt);

	else if ( lopt.read_only() || lopt.read_only_preserve() )
		return (IValue*) left->ReadOnlyEval( lopt, lopt.read_only_preserve() );
	else
		return 0;
	}

IValue *AssignExpr::SideEffectsEval( evalOpt &opt )
	{
	evalOpt lopt(opt);		// save state of options

	lopt.set(evalOpt::SIDE_EFFECTS);

	IValue *ret = Eval(lopt);
	opt.Backrefs() = lopt.Backrefs();

	if ( ret )
		{
		if ( ret->Type() == TYPE_FAIL )
			return ret;
		else if ( lopt.result_perishable( ) )
			return ret;

		glish_fatal->Report(
		"value unexpected returnedly in AssignExpr::SideEffectsEval" );
		}

	return 0;
	}

int AssignExpr::Invisible() const
	{
	return 1;
	}

Expr *AssignExpr::DoBuildFrameInfo( scope_modifier, expr_list &dl )
	{
	Expr *n = right->DoBuildFrameInfo( SCOPE_RHS, dl );
	if ( n != right )
		{
		if ( ! dl.is_member(right) )
			dl.append(right);
		right = n;
		}

	n = left->DoBuildFrameInfo( SCOPE_LHS, dl );
	if ( n != left )
		{
		if ( ! dl.is_member(left) )
			dl.append(left);
		left = n;
		}

	return this;
	}

const char *OrExpr::Description() const
	{
	return "||";
	}

OrExpr::OrExpr( Expr* op1, Expr* op2 ) : BinaryExpr(op1, op2)
	{
	}

IValue* OrExpr::Eval( evalOpt &opt )
	{
	Str err;
	evalOpt lopt(opt);		// save state of options
	const IValue* left_value = left->ReadOnlyEval( opt );

	int cond = left_value->BoolVal(1,err);

	if ( err.chars() )
		{
		left->ReadOnlyDone( left_value );
		return (IValue*) Fail(err.chars());
		}

	if ( cond )
		{
		if ( lopt.copy() || lopt.copy_preserve() )
			{
			IValue* result = copy_value( left_value );
			left->ReadOnlyDone( left_value );
			return result;
			}

		else
			return (IValue*) left_value;
		}

	else
		{
		left->ReadOnlyDone( left_value );
		opt = lopt;
		return right->Eval( opt );
		}
	}

const char *AndExpr::Description() const
	{
	return "&&";
	}

AndExpr::AndExpr( Expr* op1, Expr* op2 ) : BinaryExpr(op1, op2)
	{
	}

IValue* AndExpr::Eval( evalOpt &opt )
	{
	Str err;
	evalOpt lopt(opt);		// save state of options

	const IValue* left_value = left->ReadOnlyEval( opt );
	int left_is_true = left_value->BoolVal(1,err);
	left->ReadOnlyDone( left_value );

	if ( err.chars() )
		return (IValue*) Fail(err.chars());

	if ( lopt.copy() || lopt.copy_preserve() )
		{
		if ( left_is_true )
			return right->CopyEval( opt, lopt.copy_preserve() );
		else
			return false_ivalue();
		}

	else
		{
		if ( left_is_true )
			return (IValue*) right->ReadOnlyEval( opt );
		else
			return false_ivalue();
		}
	}

ConstructExpr::~ConstructExpr()
	{
	if ( args )
		{
		loop_over_list( *args, i )
			NodeUnref( (*args)[i] );
		delete args;
		}
	}

const char *ConstructExpr::Description() const
	{
	return "[construct]";
	}

ConstructExpr::ConstructExpr( parameter_list* arg_args )
	{
	const char *msg = "mixed array/record constructor: ";
	is_array_constructor = 1;
	err = 0;

	args = arg_args;

	if ( args )
		{
		loop_over_list( *args, i )
			{
			if ( (*args)[i]->Name() )
				{
				if ( i > 0 && is_array_constructor )
					{
					err = msg;
					break;
					}

				is_array_constructor = 0;
				}

			else if ( ! is_array_constructor )
				{
				err = msg;
				is_array_constructor = 1;
				break;
				}
			}
		}
	}

IValue* ConstructExpr::Eval( evalOpt &opt )
	{
	if ( err )
		return (IValue*) Fail( err, this );

	opt.set( evalOpt::RESULT_PERISHABLE );

	if ( ! args )
		return create_irecord();

	else if ( args->length() == 0 )
		return empty_ivalue();

	else if ( is_array_constructor )
		return BuildArray( opt );

	else
		return BuildRecord( opt );
	}

int ConstructExpr::Describe( OStream &s, const ioOpt &opt ) const
	{
	if ( opt.prefix() ) s << opt.prefix();
	s << "[";

	if ( args )
		describe_parameter_list( args, s );
	else
		s << "=";

	s << "]";
	return 1;
	}

IValue* ConstructExpr::BuildArray( evalOpt &opt )
	{
	typedef const IValue* const_value_ptr;

	int num_values = 0;

	loop_over_list( *args, i )
		{
		Parameter* arg = (*args)[i];

		if ( arg->IsEllipsis() )
			num_values += (*args)[i]->NumEllipsisVals( opt );
		else
			++num_values;
		}

	const_value_ptr* values = (const_value_ptr*) alloc_ivalueptr( num_values );

	evalOpt nopt(opt);

	if ( args->length() == 1 )
		nopt.set( evalOpt::PRESERVE_FIELDNAMES );

	int total_length = 0;
	for ( LOOPDECL i = 0; i < args->length(); ++i )
		{
		Parameter* arg = (*args)[i];

		if ( arg->IsEllipsis() )
			{
			int len = arg->NumEllipsisVals( opt );

			for ( int j = 0; j < len; ++j )
				{
				values[i+j] = (const IValue*)(arg->NthEllipsisVal(opt,j)->Deref());
				total_length += values[i+j]->Length();
				}
			}
		else
			{
			values[i] = arg->Arg()->ReadOnlyEval( nopt );
			total_length += values[i]->Length();
			}
		}

	glish_type max_type;
	int records = 0;
	IValue *result = TypeCheck( values, num_values, max_type, records );

	if ( ! result )
		{
		if ( records )
			result = ConstructRecord( values, num_values );
		else
			result = ConstructArray( values, num_values, total_length, max_type );
		}

	for ( LOOPDECL i = 0; i < args->length(); ++i )
		if ( ! (*args)[i]->IsEllipsis() )
			(*args)[i]->Arg()->ReadOnlyDone( values[i] );

	free_memory( values );

	return result;
	}

IValue *ConstructExpr::TypeCheck( const IValue* values[], int num_values,
					glish_type& max_type, int &records )
	{
	if ( num_values == 0 )
		{
		max_type = TYPE_BOOL;	// Compatible with the constant F
		return 0;
		}

	int all_records = 1;
	records = 0;

	for ( int i = 0; i < num_values; ++i )
		{
		const IValue* v = values[i];

		if ( all_records && v->Type() != TYPE_RECORD )
			all_records = 0;

		if ( v->Type() == TYPE_FAIL )
			return copy_value(v);

		if ( v->Length() > 0 && v->IsNumeric() )
			return MaxNumeric( values, num_values, max_type );
		}

	IValue *result = AllEquivalent( values, num_values, max_type );

	if ( max_type == TYPE_RECORD )
		{
		if ( all_records )
			{
			records = 1;
			return 0;
			}
		else
			return (IValue*) Fail( "arrays of records are not supported" );
		}

	return result;
	}

IValue *ConstructExpr::MaxNumeric( const IValue* values[], int num_values,
					glish_type& max_type )
	{
	const IValue* v = (const IValue*) (values[0]->VecRefDeref());
	if ( ! v->IsNumeric() )
		return (IValue*) Fail("non-numeric type in array constructor", this);

	max_type = v->Type();

	for ( int i = 1; i < num_values; ++i )
		{
		v = (const IValue*)(values[i]->VecRefDeref());

		if ( ! v->IsNumeric() )
			return (IValue*) Fail( "non-numeric type in array constructor", this );

		max_type = max_numeric_type( v->Type(), max_type );
		}

	return 0;
	}

IValue *ConstructExpr::AllEquivalent( const IValue* values[], int num_values,
					glish_type& max_type )
	{
	max_type = TYPE_BOOL;

	// First pick a candidate type.
	for ( int i = 0; i < num_values; ++i )
		// Ignore empty arrays, as they can be any type.
		if ( values[i]->Length() > 0 || values[i]->Deref()->Type() == TYPE_RECORD )
			{
			max_type = values[i]->VecRefDeref()->Type();
			break;
			}

	// Now check whether all non-empty arrays conform to that type.
	for ( LOOPDECL i = 0; i < num_values; ++i )
		{
		const IValue* v = (const IValue*)(values[i]->VecRefDeref());

		if ( v->Length() > 0 && v->Type() != max_type )
			return (IValue*) Fail( "incompatible types in array constructor", this );
		}

	return 0;
	}

IValue* ConstructExpr::ConstructArray( const IValue* values[],
					int num_values, int total_length,
					glish_type max_type )
	{
	IValue* result;

	int is_copy;
	int i, len;

	switch ( max_type )
		{
#define BUILD_WITH_COERCE_TYPE(tag, type, coercer)			\
	case tag:							\
		{							\
		type* array = (type*) alloc_##type( total_length );	\
		type* array_ptr = array;				\
									\
		for ( i = 0; i < num_values; ++i )			\
			{						\
			len = values[i]->Length();			\
			if ( len > 0 )					\
				(void) values[i]->coercer( is_copy,	\
						len, array_ptr );	\
			array_ptr += len;				\
			}						\
									\
		result = new IValue( array, total_length );		\
									\
		break;							\
		}

#define BUILD_WITH_NON_COERCE_TYPE(tag, type, accessor, storage, do_copy ) \
	case tag:							\
		{							\
		type* array = (type*) alloc_##type( total_length );	\
		type* array_ptr = array;				\
									\
		for ( i = 0; i < num_values; ++i )			\
			{						\
			len = values[i]->Length();			\
			if ( len > 0 )					\
				do_copy( values[i]->accessor,		\
						array_ptr, len, type );	\
			array_ptr += len;				\
			}						\
									\
		result = new IValue( array, total_length, storage );	\
									\
		if ( storage == COPY_ARRAY )				\
			free_memory( array );				\
									\
		break;							\
		}

BUILD_WITH_COERCE_TYPE(TYPE_BOOL, glish_bool, CoerceToBoolArray)
BUILD_WITH_COERCE_TYPE(TYPE_BYTE, byte, CoerceToByteArray)
BUILD_WITH_COERCE_TYPE(TYPE_SHORT, short, CoerceToShortArray)
BUILD_WITH_COERCE_TYPE(TYPE_INT, int, CoerceToIntArray)
BUILD_WITH_COERCE_TYPE(TYPE_FLOAT, float, CoerceToFloatArray)
BUILD_WITH_COERCE_TYPE(TYPE_DOUBLE, double, CoerceToDoubleArray)
BUILD_WITH_COERCE_TYPE(TYPE_COMPLEX, glish_complex, CoerceToComplexArray)
BUILD_WITH_COERCE_TYPE(TYPE_DCOMPLEX, glish_dcomplex, CoerceToDcomplexArray)

// For strings, copy the result so that each string in the array gets
// copied, too.

#define twisted_copy_regexs(src,dest,len,type) \
	copy_regexs( (void*) dest, (void*) src, len )
#define twisted_copy_funcs(src,dest,len,type) \
	copy_funcs( (void*) dest, (void*) src, len )
BUILD_WITH_NON_COERCE_TYPE(TYPE_STRING, charptr, StringPtr(), COPY_ARRAY, copy_array )
BUILD_WITH_NON_COERCE_TYPE(TYPE_REGEX, regexptr, RegexPtr(0), TAKE_OVER_ARRAY, twisted_copy_regexs )
BUILD_WITH_NON_COERCE_TYPE(TYPE_FUNC, funcptr, FuncPtr(), TAKE_OVER_ARRAY, twisted_copy_funcs )

		case TYPE_AGENT:
			return (IValue*) Fail( "can't construct array of agents" );
			break;

		case TYPE_RECORD:
			return (IValue*) Fail( "can't construct array of records" );
			break;

		default:
			glish_fatal->Report(
		    "bad type tag in ConstructExpr::ConstructArray()" );
		}

	return result;
	}

IValue * ConstructExpr::ConstructRecord( const IValue* values[], int num_values )
	{
	recordptr newrec = create_record_dict();
	int unique_count = 1;

	for ( int i=0; i < num_values; ++i )
		{
		if ( values[i]->Type() != TYPE_RECORD )
			glish_fatal->Report( "bad value in ConstructExpr::ConstructRecord()" );
		  
		recordptr rptr = values[i]->RecordPtr(0);
		IterCookie* c = rptr->InitForIteration();

		Value* member;
		const char* key;
		while ( (member = rptr->NextEntry( key, c )) )
			{
			if ( newrec->Lookup( key ) )
				{
				char *buff = alloc_char( strlen(key)+30 );
				sprintf( buff, "%s*%d", key, unique_count++ );
				while ( newrec->Lookup( buff ) )
					sprintf( buff, "%s*%d", key, unique_count++ );
				newrec->Insert( buff, copy_value(member) );
				}
			else
				newrec->Insert( string_dup(key), copy_value(member) );
			}
		}
	return new IValue( newrec );
	}

IValue* ConstructExpr::BuildRecord( evalOpt &opt )
	{
	recordptr rec = create_record_dict();

	loop_over_list( *args, i )
		{
		Parameter* p = (*args)[i];
		IValue *arg = p->Arg()->CopyEval(opt);
		if ( p->ParamType() == VAL_CONST )
			arg->MakeConst();
		rec->Insert( string_dup( p->Name() ), arg );
		}

	return new IValue( rec );
	}


ArrayRefExpr::~ArrayRefExpr()
	{
	if ( args )
		{
		loop_over_list( *args, i )
			NodeUnref( (*args)[i] );
		delete args;
		}
	}

const char *ArrayRefExpr::Description() const
	{
	return "[]";
	}
ArrayRefExpr::ArrayRefExpr( Expr* op1, expr_list* a ) : UnaryExpr(op1)
	{
	args = a;
	}

IValue* ArrayRefExpr::Eval( evalOpt &opt )
	{
	evalOpt lopt(opt);		// save state of options
	const IValue* array = op->ReadOnlyEval( opt );
	IValue* result;

	const attributeptr ptr = array->AttributePtr();
	if ( ptr )
		{
		const IValue* func = (const IValue*)((*ptr)["op[]"]);
		Func* func_val = (func && func->Type() == TYPE_FUNC) ?
					func->FuncVal() : 0;

		if ( func_val && ! func_val->Mark() )
			{ // Subscript operator functions.
			parameter_list pl;

			pl.append( new ActualParameter( VAL_VAL, op ) );

			for ( int i = 0; i < args->length(); ++i )
				{
				Expr* arg = (*args)[i];
				if ( arg )
					pl.append( new ActualParameter(
							VAL_VAL, (*args)[i] ) );
				else
					pl.append( new ActualParameter() );
				}

			opt = lopt;
			result = CallFunc( func_val, opt, &pl );
			if ( ! result )
				{
				if ( lopt.side_effects() )
					result = error_ivalue();
				}
			else
				{
				IValue* tmp = (IValue*)(result->Deref());
				if ( tmp->IsVecRef() )
					{
					tmp->VecRefPolymorph(
						tmp->VecRefPtr()->Type() );
					if ( tmp != result )
						Unref( result );
					result = tmp;
					}
				}

			op->ReadOnlyDone( array );
			return result;
			}

		// Multi-element subscript operation.
		if ( (*ptr)["shape"] && args->length() > 1 )
			{
			const_value_list val_list;
			Expr* arg;

			for ( int i = 0; i < args->length(); ++i )
				{
				arg = (*args)[i];
				val_list.append( arg ?
						arg->ReadOnlyEval(opt) : 0 );
				}

			result = (IValue*)((*array)[&val_list]);
			for ( LOOPDECL i = 0; i < args->length(); ++i )
				if ( (arg = (*args)[i]) )
					arg->ReadOnlyDone( (const IValue*) val_list[i] );

			op->ReadOnlyDone( array );
			return result;
			}
		}

	if ( args->length() != 1 )
		{
		glish_warn->Report( this, "invalid array addressing" );
		op->ReadOnlyDone( array );
		return error_ivalue();
		}

	Expr* arg = (*args)[0];
	if ( ! arg )
		{
		op->ReadOnlyDone( array );
		return (IValue*) Fail( "invalid missing parameter" );
		}

	const IValue* index_val = arg->ReadOnlyEval(opt);
	const attributeptr indx_attr = index_val->AttributePtr();
	const IValue* indx_shape;

	if ( index_val->VecRefDeref()->Type() == TYPE_RECORD )
		{ // Single record element slice operation.
		const_value_list val_list;
		const IValue* val;
		int n = index_val->Length();
		for ( int x = 1; x <= n; ++x )
			if ( (val = (const IValue*)(index_val->NthField( x ))) &&
			     val->Length() > 0 )
				val_list.append( val );
			else
				val_list.append( 0 );
		result = (IValue*)((*array)[&val_list]);
		}

	else if ( indx_attr && (indx_shape = (const IValue*)((*indx_attr)["shape"])) &&
		  indx_shape->IsNumeric() && index_val->Type() != TYPE_BOOL )
		{ // Single element pick operation.
		result = (IValue*)(array->Pick( index_val ));
		if ( result->IsRef() )
			{
			IValue* orig_result = result;
			result = copy_value( (const IValue*) result->Deref() );
			Unref( orig_result );
			}
		}

	else
		{ // Record or array subscripting.
		if ( index_val && index_val->Type() == TYPE_STRING &&
		     index_val->Length() == 1 )
			{ // Return single element belonging to record.
			const IValue* const_result = (const IValue *)
				array->Deref()->ExistingRecordElement( index_val );

			const_result = (const IValue *) (const_result->Deref());
			opt = lopt;
			result = CopyOrRefValue( const_result, opt );
			}
		else
			{ // Array subscripting.
			if ( array->Type() == TYPE_RECORD && opt.preserve_fieldnames() )
				result = ((IValue *)array)->subscript( index_val, 1 );
			else
				result = (IValue *)(*array)[index_val];

			if ( result->IsRef() )
				{
				IValue* orig_result = result;
				result = copy_value( (const IValue*) (result->Deref()) );
				Unref( orig_result );
				}
			}
		}

	arg->ReadOnlyDone( index_val );

	op->ReadOnlyDone( array );
	return result;
	}

IValue* ArrayRefExpr::RefEval( evalOpt &opt, value_reftype val_type )
	{
	IValue* array_ref = op->RefEval( opt, val_type );
	IValue* array = (IValue*) array_ref->Deref();

	IValue* result = 0;

	const attributeptr ptr = array->AttributePtr();
	Expr* arg;

	if ( ptr )
		{
		const IValue* func = (const IValue*)(*ptr)["op[]"];
		Func* func_val = (func && func->Type() == TYPE_FUNC) ?
					func->FuncVal() : 0;

		if ( func_val && ! func_val->Mark() )
			{ // Subscript operator functions.
			parameter_list pl;
			pl.append( new ActualParameter( VAL_VAL, op ) );

			for ( int i = 0; i < args->length(); ++i )
				{
				if ( (arg = (*args)[i]) )
					pl.append( new ActualParameter(
							VAL_VAL, arg ) );
				else
					pl.append( new ActualParameter() );
				}

			Unref( array_ref );
			evalOpt opt(evalOpt::COPY);
			return CallFunc( func_val, opt, &pl );
			}

		if ( (*ptr)["shape"] && args->length() > 1 )
			{ // Multi-element subscript operation.
			const_value_list val_list;
			for ( int i = 0; i < args->length(); ++i )
				{
				arg = (*args)[i];
				val_list.append( arg ?
						arg->ReadOnlyEval(opt) : 0 );
				}

			int err = 0;
			result = (IValue*)(array->SubRef( &val_list, err ));
			for ( LOOPDECL i = 0; i < args->length(); ++i )
				if ( (arg = (*args)[i]) )
					arg->ReadOnlyDone( (const IValue*)(val_list[i]) );

			Unref( array_ref );
			return result;
			}
		}

	if ( args->length() != 1 )
		{
		glish_warn->Report( this, ": invalid array addressing" );
		Unref( array_ref );
		return error_ivalue();
		}

	if ( ! (arg = (*args)[0]) )
		{
		Unref( array_ref );
		return (IValue*) Fail( this, ": invalid missing parameter" );
		}

	const IValue* index_val = arg->ReadOnlyEval(opt);
	const attributeptr indx_attr = index_val->AttributePtr();
	const IValue* indx_shape;

	int err = 0;
	if ( index_val->VecRefDeref()->Type() == TYPE_RECORD )
		{ // Single record element slice operation.
		const_value_list val_list;
		int n = index_val->Length();
		for ( int x = 1; x <= n; ++x )
			{
			const IValue* val = (const IValue*)(index_val->NthField( x ));
			val_list.append( (val && val->Length() > 0) ? val : 0 );
			}

		result = (IValue*)(array->SubRef( &val_list, err ));
		}

	else if ( indx_attr && (indx_shape = (const IValue*)((*indx_attr)["shape"])) &&
	          indx_shape->IsNumeric() && index_val->Type() != TYPE_BOOL  &&
		  array->Type() != TYPE_RECORD )
		// Single element pick operation...
		// PickRef() can't handle a record, though (FEATURE OR BUG?)...
		result = (IValue*)array->PickRef( index_val, err );
	else
		{
		// If we have an uninitalized value and the index is a string,
		// then we know it needs to be coerced to a record...
		if ( array->IsUninitialized( ) && index_val->VecRefDeref()->Type() == TYPE_STRING )
			array->Polymorph( TYPE_RECORD );

		// Currently SubRef does not properly handle multi-element index
		// vectors for record indexing. This causes problems in situations
		// like:
		//
		//		- ec := client('echo_client')
		//		- foo := [ a=1, b=2, c=3, d=4 ]
		//		- foo[[2,3]]
		//		[b=2, c=3]
		//		- ec->hi(foo[[2,3]])
		//		warning, event echo_client.hi (2) dropped
		//
		// It would be better to fix SubRef(), but for now this
		// suffices. It returns a copy rather than a reference, though.
		//
		if ( array->Type() == TYPE_RECORD && index_val->Length() > 1 )
			result = (IValue*)(*array)[index_val];
		else
			{
			result = (IValue*)array->SubRef( index_val, err, val_type );
			}
		}

	arg->ReadOnlyDone( index_val );

	if ( err && result->Deref()->Type( ) == TYPE_FAIL )
		{
		Unref( array_ref );
		return result;
		}

	result = new IValue( result, val_type );

	//## After the creation of this last value, the initial "result" has
	//## a reference count of 2 for TYPE_SUBVEC_REF. Since we want "result"
	//## to go away when the outer reference is deleted, it is unref()ed
	//## here. The use of TYPE_SUBVEC_REF should be clarified to see if the
	//## current behavior is ever necessary.
	if ( result->Deref()->Type() == TYPE_SUBVEC_REF )
		Unref(result->Deref());

	Unref( array_ref );

	return result;
	}

IValue* ArrayRefExpr::CallFunc( Func *fv, evalOpt &opt,
				parameter_list *f_args )
	{
	// Mark the function so that a user-function definition for
	// "op[]" that needs to apply array referencing doesn't endlessly
	// loop.
	fv->Mark( 1 );
	IValue* ret = fv->Call( opt, f_args );
	fv->Mark( 0 );

	return ret;
	}

IValue *ArrayRefExpr::Assign( evalOpt &opt, IValue* new_value )
	{
	IValue* lhs_value_ref = op->RefEval( opt, VAL_REF );
	IValue* lhs_value = (IValue*)(lhs_value_ref->Deref());

	if ( lhs_value_ref->IsConst() || lhs_value->VecRefDeref()->IsConst() ||
	     lhs_value_ref->VecRefDeref()->Type() != TYPE_RECORD &&
	     (lhs_value_ref->IsModConst() || lhs_value->IsModConst()) )
		{
		Unref( lhs_value_ref );
		return (IValue*) Fail( "'const' values cannot be modified." );
		}

	const attributeptr ptr = lhs_value->AttributePtr();

	if ( ptr )
		{
		const IValue* func = (const IValue*)((*ptr)["op[]:="]);
		int do_assign = 1;

		if ( ! func || func->Type() != TYPE_FUNC )
			{
			func = (const IValue*)((*ptr)["op[]"]);
			do_assign = glish_false;
			}

		Func* func_val = (func && func->Type() == TYPE_FUNC) ?
					func->FuncVal() : 0;

		if ( func_val && ! func_val->Mark() )
			{ // Subscript assign operator functions.
			parameter_list pl;

			if ( do_assign )
				pl.append( new ActualParameter( VAL_VAL,
						new ValExpr( new_value ) ) );

			pl.append( new ActualParameter( VAL_VAL, op ) );

			for ( int i = 0; i < args->length(); ++i )
				{
				Expr* arg = (*args)[i];
				if ( arg )
					pl.append( new ActualParameter(
							VAL_VAL, arg ) );
				else
					pl.append( new ActualParameter() );
				}

			evalOpt opt(evalOpt::COPY);
			IValue* vecref = CallFunc( func_val, opt, &pl );

			if ( ! do_assign )
				vecref->Deref()->AssignElements( new_value );
			else
				Unref( new_value );

			Unref( vecref );
			Unref( lhs_value_ref );

			return 0;
			}

		if ( (*ptr)["shape"] && args->length() > 1 )
			{ // Multi-element subscript assign operation.
			const_value_list val_list;
			Expr* arg;
			for ( int i = 0; i < args->length(); ++i )
				{
				arg = (*args)[i];
				val_list.append( arg ?
						arg->ReadOnlyEval(opt) : 0 );
				}

			lhs_value->AssignElements( &val_list, new_value );
			for ( LOOPDECL i = 0; i < args->length(); ++i )
				if ( (arg = (*args)[i]) )
					arg->ReadOnlyDone( (const IValue*)(val_list[i]) );

			Unref( lhs_value_ref );
			return 0;
			}
		}

	if ( args->length() != 1 )
		{
		Unref( new_value );
		Unref( lhs_value_ref );
		return (IValue*) Fail( this, " invalid array addressing" );
		}

	const IValue* index = (*args)[0]->ReadOnlyEval(opt);
	const attributeptr indx_attr = index->AttributePtr();
	const IValue* indx_shape;

	if ( index->VecRefDeref()->Type() == TYPE_RECORD )
		{ // Single record element slice assign operation.
		const_value_list val_list;
		int n = index->Length();
		for ( int x = 1; x <= n; ++x )
			{
			const IValue* val = (const IValue*)(index->NthField( x ));
			val_list.append( (val && val->Length() > 0) ? val : 0 );
			}

		lhs_value->AssignElements( &val_list, new_value );
		}

	else if ( index->Type() != TYPE_BOOL && indx_attr && 
		  (indx_shape = (const IValue*)((*indx_attr)["shape"])) &&
		  indx_shape->IsNumeric() )
		// Single element pick assign operation.
		lhs_value->PickAssign( index, new_value );

	else
		{
		if ( lhs_value->IsUninitialized( ) )
			{
			// ### assume uninitialized variable
			if ( index->Type() == TYPE_STRING )
				lhs_value->Polymorph( TYPE_RECORD );
			else if ( new_value->Type() == TYPE_STRING )
				lhs_value->Polymorph( TYPE_STRING );
			}

		lhs_value->AssignElements( index, new_value );
		}

	(*args)[0]->ReadOnlyDone( index );

	IValue *ret = 0;

	if ( opt.result_perishable( ) )
		ret = copy_value( lhs_value );

	Unref( lhs_value_ref );
	return ret;
	}

IValue *ArrayRefExpr::ApplyRegx( regexptr* /* ptr */, int /*len*/, RegexMatch & /* match */ )
	{
	return (IValue*) Fail( this, "is not a valid target for regex application" );
	}

int ArrayRefExpr::Describe( OStream &s, const ioOpt &opt ) const
	{
	if ( opt.prefix() ) s << opt.prefix();
	op->Describe( s, ioOpt(opt.flags(),opt.sep()) );
	s << "[";
	if ( args )
		describe_expr_list( args, s );
	s << "]";
	return 1;
	}

RecordRefExpr::~RecordRefExpr()
	{
	if ( field )
		free_memory( field );
	}

const char *RecordRefExpr::Description() const
	{
	return ".";
	}

RecordRefExpr::RecordRefExpr( Expr* op_, char* record_field )
    : UnaryExpr(op_)
	{
	field = record_field;
	}

IValue* RecordRefExpr::Eval( evalOpt &opt )
	{
	evalOpt lopt(opt);		// save state of options

	const IValue* record = op->ReadOnlyEval(opt);
	const IValue* const_result = (const IValue*)(record->Deref()->ExistingRecordElement( field ));

	const_result = (const IValue*)(const_result->Deref());

	IValue* result;

	result = CopyOrRefValue( const_result, lopt );

	op->ReadOnlyDone( record );

	return result;
	}

IValue* RecordRefExpr::RefEval( evalOpt &opt, value_reftype val_type )
	{
	IValue* value_ref = op->RefEval( opt, val_type );
	IValue* value = (IValue*)(value_ref->Deref());

	IValue *fieldv = (IValue*)(value->GetOrCreateRecordElement( field ));

	fieldv = new IValue( fieldv, val_type );

	if ( value->IsGlobalValue( ) )
		fieldv->MarkGlobalValue( );

	Unref( value_ref );

	return fieldv;
	}

IValue *RecordRefExpr::Assign( evalOpt &opt, IValue* new_value )
	{
	IValue* lhs_value_ref = op->RefEval( opt, VAL_REF );
	IValue* lhs_value = (IValue*)(lhs_value_ref->Deref());

	if ( lhs_value_ref->IsConst() || lhs_value->VecRefDeref()->IsConst() ||
	     lhs_value_ref->IsRefConst() || lhs_value->VecRefDeref()->IsRefConst() )
		{
		Unref( lhs_value_ref );
		return (IValue*) Fail( "'const' values cannot be modified." );
		}

	if ( lhs_value->VecRefDeref()->IsFieldConst() &&
	     ! lhs_value->VecRefDeref()->HasRecordElement(field) )
		{
		Unref( lhs_value_ref );
		return (IValue*) Fail( "fields cannot be added to a 'const' record." );;
		}

	if ( lhs_value->Deref()->IsUninitialized( ) )
		// ### assume uninitialized variable
		lhs_value->Polymorph( TYPE_RECORD );

	if ( lhs_value->VecRefDeref()->Type() == TYPE_RECORD )
		lhs_value->AssignRecordElement( field, new_value );
	else
		{
		Unref( new_value );
		Unref( lhs_value_ref );
		return (IValue*) Fail( op, "is not a record" );
		}

	Unref( new_value );
	Unref( lhs_value_ref );
	return 0;
	}

int RecordRefExpr::Describe( OStream &s, const ioOpt &opt ) const
	{
	if ( opt.prefix() ) s << opt.prefix();
	op->Describe( s, ioOpt(opt.flags(),opt.sep()) );
	s << "." << field;
	return 1;
	}

AttributeRefExpr::~AttributeRefExpr()
	{
	if ( field )
		free_memory( field );
	} 

const char *AttributeRefExpr::Description() const
	{
	return right ? "::[]" : "::";
	}

AttributeRefExpr::AttributeRefExpr( Expr *op1 ) : BinaryExpr(op1, 0)
	{
	field = 0;
	}

AttributeRefExpr::AttributeRefExpr( Expr* op1, char* attribute ) :
		BinaryExpr(op1, 0)
	{
	field = attribute;
	}

AttributeRefExpr::AttributeRefExpr( Expr* op1, Expr* op2 ) :
		BinaryExpr(op1, op2)
	{
	field = 0;
	}

IValue* AttributeRefExpr::Eval( evalOpt &opt )
	{
	evalOpt lopt(opt);		// save state of options

	const IValue* val = left->ReadOnlyEval(opt);
	IValue* result = 0;
	const IValue* const_result = 0;

	if ( field )
		const_result = (const IValue*)(val->ExistingAttribute( field ));

	else if ( right )
		{
		const IValue* index_val = right->ReadOnlyEval(opt);
		if ( index_val && index_val->Type() == TYPE_STRING &&
		     index_val->Length() == 1  )
			const_result = (const IValue*)(val->ExistingAttribute( index_val ));
		else
			const_result = (const IValue*)(val->AttributeRef( index_val ));

		right->ReadOnlyDone( index_val );
		}

	else
		{
		recordptr new_record = create_record_dict();
		const attributeptr aptr = val->AttributePtr();

		if ( aptr )
			{
			IterCookie* c = aptr->InitForIteration();
			const IValue* member;
			const char* key;
			while ( (member = (const IValue*)(aptr->NextEntry( key, c))) )
				new_record->Insert( string_dup( key ),
						   copy_value( member ) );
			}

		result = new IValue( new_record );
		}

	if ( ! result )
		result = CopyOrRefValue( (const IValue*)(const_result->Deref()), lopt );

	left->ReadOnlyDone( val );
	return result;
	}

IValue* AttributeRefExpr::RefEval( evalOpt &opt, value_reftype val_type )
	{
	IValue* value_ref = left->RefEval( opt, val_type );
	IValue* value = (IValue*)(value_ref->Deref());

	if ( field )
		{
		value = (IValue*)(value->GetOrCreateAttribute( field ));
		value = new IValue( value, val_type );
		}

	else if ( right )
		{
		const IValue* index_val = right->ReadOnlyEval(opt);

		if ( index_val && index_val->Type() == TYPE_STRING &&
		     index_val->Length() == 1  )
			{
			value = (IValue*)(value->GetOrCreateAttribute( index_val ));
			value = new IValue( value, val_type );
			}
		else
			{
			glish_warn->Report( this, " invalid attribute access" );
			value = error_ivalue();
			}

		right->ReadOnlyDone( index_val );
		}

	else
		{
		//
		// ModAttributePtr( ) ensures that an attribute record exists
		//
		value->ModAttributePtr( );
		value = (IValue*) value->AttributeRef( );
		}

	Unref( value_ref );

	return value;
	}

IValue *AttributeRefExpr::Assign( evalOpt &opt, IValue* new_value )
	{
	evalOpt lopt(opt);		// save state of options

	IValue* lhs_value_ref = left->RefEval( lopt, VAL_REF );
	IValue* lhs_value = (IValue*)(lhs_value_ref->Deref());

	if ( field )
		lhs_value->AssignAttribute( field, new_value );

	else if ( right )
		{
		const IValue* index_val = right->ReadOnlyEval(lopt);
		if ( index_val && index_val->Type() == TYPE_STRING &&
		     index_val->Length() == 1  )
			{
			char* str = index_val->StringVal();
			lhs_value->AssignAttribute( str, new_value );
			free_memory( str );
			}

		else
			{
			right->ReadOnlyDone( index_val );
			Unref( new_value );
			Unref( lhs_value_ref );
			return (IValue*) Fail( this, " invalid attribute access" );
			}
		right->ReadOnlyDone( index_val );
		}

	else
		{
		if ( new_value->Type() == TYPE_RECORD )
			{
			if ( new_value->Length() > 0 )
				lhs_value->AssignAttributes(
					copy_value( new_value ) );
			else
				lhs_value->AssignAttributes( 0 );
			}
		else
			{
			Unref( new_value );
			Unref( lhs_value_ref );
			return (IValue*) Fail( this, " invalid attribute assignment" );
			}
		}

	Unref( new_value );

	//
	// When we have an expression like:
	//
	//	print [a=1,b=2,c=3]:::=[print=[precision=10]]
	//
	// we cannot loose the value... the fact that the value is perisable
	// is indicated by an evalOpt flag... or
	//
	//	y := x:::=[foo='bar']
	//
	// where for consistency's sake we want it to return the value rather
	// than the attributes...
	//
	if ( lopt.result_perishable( ) || opt.rhs_result( ) )
		{
		opt.set( evalOpt::RESULT_PERISHABLE );
		Ref(lhs_value);
		}
	else
		lhs_value = 0;

	Unref( lhs_value_ref );
	return lhs_value;
	}

int AttributeRefExpr::Describe( OStream &s, const ioOpt &opt ) const
	{
	if ( opt.prefix() ) s << opt.prefix();
	left->Describe( s, ioOpt(opt.flags(),opt.sep()) );

	if ( field )
		s << "::" << field;

	else if ( right )
		{
		s << "::[";
		right->Describe( s, ioOpt(opt.flags(),opt.sep()) );
		s << "]";
		}
	else
		s << "::";

	return 1;
	}

Expr *AttributeRefExpr::DoBuildFrameInfo( scope_modifier m, expr_list &dl )
	{
	left = left->DoBuildFrameInfo( m, dl );

	if ( right )
		right = right->DoBuildFrameInfo( m, dl );

	return this;
	}

RefExpr::RefExpr( Expr* op_, value_reftype arg_type ) : UnaryExpr(op_)
	{
	type = arg_type;
	}

IValue* RefExpr::Eval( evalOpt &opt )
	{
	IValue *val = op->RefEval( opt, type );

	if ( type == VAL_CONST )
		val->MakeModConst();

	return val;
	}

IValue *RefExpr::Assign( evalOpt &opt, IValue* new_value )
	{
	Str err;
	const char *ret = 0;
	if ( type == VAL_VAL )
		{
		IValue* value = op->RefEval( opt, VAL_REF );

		if ( value->Deref()->Type() == TYPE_FAIL )
			return value;
		else if ( value->VecRefDeref()->IsConst() )
			ret = "'const' values cannot be modified.";
		else if ( value->Deref()->IsVecRef() )
			value->AssignElements( new_value );
		else
			{
			value->Deref()->TakeValue( new_value, err );
			ret = err.chars();
			}

		Unref( value );
		}

	else if ( type == VAL_CONST )
		{
		new_value->MakeConst( );
		return op->Assign( opt, new_value );
		}
	else
		return Expr::Assign( opt, new_value );

	return ret ? (IValue*) Fail( ret ) : 0 ;
	}

int RefExpr::Describe( OStream &s, const ioOpt &opt ) const
	{
	if ( opt.prefix() ) s << opt.prefix();
	if ( type == VAL_CONST )
		s << "const ";
	else if ( type == VAL_REF )
		s << "ref ";
	else
		s << "val ";

	op->Describe( s, ioOpt(opt.flags(),opt.sep()) );
	return 1;
	}

const char *RefExpr::Description() const
	{
	return "ref";
	}

int RefExpr::LhsIs( const Expr *e ) const
	{
	return op == e ? 1 : op->LhsIs(e);
	}

const char *RangeExpr::Description() const
	{
	return ":";
	}

RangeExpr::RangeExpr( Expr* op1, Expr* op2 ) : BinaryExpr(op1, op2)
	{
	}

IValue* RangeExpr::Eval( evalOpt &opt )
	{
	const IValue* left_val = left->ReadOnlyEval(opt);
	const IValue* right_val = right->ReadOnlyEval(opt);

	IValue* result;

	if ( ! left_val->IsNumeric() || ! right_val->IsNumeric() )
		result = (IValue*) Fail( "non-numeric value in", this );
	else if ( left_val->Length() > 1 || right_val->Length() > 1 )
		result = (IValue*) Fail( "non-scalar value in", this );
	else
		{
		Str err;
		int stop = right_val->IntVal(1,err);
		int start = left_val->IntVal(1,err);
		if ( err.chars() )
			{
			left->ReadOnlyDone( left_val );
			right->ReadOnlyDone( right_val );
			return (IValue*) Fail(err.chars());
			}

		int direction = (start > stop) ? -1 : 1;
		int num_values = (stop - start) * direction + 1;
		int* range = alloc_int( num_values );

		int i;
		int index = 0;

		if ( direction < 0 )
			for ( i = start; i >= stop; --i )
				range[index++] = i;

		else
			for ( i = start; i <= stop; ++i )
				range[index++] = i;

		result = new IValue( range, num_values );
		}

	left->ReadOnlyDone( left_val );
	right->ReadOnlyDone( right_val );

	return result;
	}


const char *ApplyRegExpr::Description() const
	{
	return "~";
	}

ApplyRegExpr::ApplyRegExpr( Expr* op1, Expr* op2, Sequencer *s, int in_place_ ) :
			BinaryExpr(op1, op2), sequencer(s), in_place(in_place_)
	{
	}


#define APPLYREG_BAIL( string )							\
	{									\
	IValue *fail = regval->Type() == TYPE_FAIL ? copy_value(regval) :	\
		       strval->Type() == TYPE_FAIL ? copy_value(strval) : 0;	\
	left->ReadOnlyDone( regval );						\
	right->ReadOnlyDone( strval );						\
	return fail ? fail : (IValue*) Fail( string );				\
	}

IValue* ApplyRegExpr::Eval( evalOpt &opt )
	{
	const IValue* strval = left->ReadOnlyEval(opt);
	const IValue* regval = right->ReadOnlyEval(opt);

	IValue* result = 0;

	if ( regval->Type() != TYPE_REGEX )
		{
		if ( in_place )
			APPLYREG_BAIL( "left-hand-side is not a regular expression" )
		else if ( strval->Type() != TYPE_REGEX )
			APPLYREG_BAIL( "no regular expression" )
		else if ( regval->Type() != TYPE_STRING )
			APPLYREG_BAIL( "right-hand-side of '~' is not a string" )
		else
			{
			register const IValue* rtmp = regval;
			regval = strval;
			strval = rtmp;
			register Expr* etmp = left;
			left = right;
			right = etmp;
			}
		}
	else if ( strval->Type() != TYPE_STRING )
		APPLYREG_BAIL( "left-hand-side of '~' is not a string" )

	int rlen = regval->Length();
	int slen = strval->Length();

	if ( rlen < 1 )
		APPLYREG_BAIL( "zero length regular expression" )
	if ( slen < 1 )
		APPLYREG_BAIL( "zero length string" )

	regexptr *regs = regval->RegexPtr(0);
	Regex::regex_type type = regs[0]->Type();
	int splits = regs[0]->Splits() ? 1 : 0;
	int global = regs[0]->Global();

	for ( int i = 1; i < rlen; ++i )
		{
		if ( regs[i]->Type() != type )
			APPLYREG_BAIL( "application contains both matches and substitutions" )
		if ( ! splits ) splits = regs[i]->Splits() ? 1 : 0;
		if ( ! global ) global = regs[i]->Global();
		}

	RegexMatch &match = sequencer->GetMatch();
	match.clear();

	charptr *strs = strval->StringPtr(0);

	if ( type == Regex::MATCH )
		{
		if ( slen == 1 )
			{
			if ( global )
				{  // if we're deailing with a //g, we return the
				   // number of applications
				int *ret = alloc_int( rlen );
				for ( int i=0; i < rlen; ++i )
					ret[i] = regs[i]->Eval( (char**&) strs, slen, &match );
				result = new IValue( ret, rlen );
				}
			else
				{
				glish_bool *ret = alloc_glish_bool( rlen );
				for ( int i=0; i < rlen; ++i )
					ret[i] = regs[i]->Eval( (char**&) strs, slen, &match ) ? glish_true : glish_false;
				result = new IValue( ret, rlen );
				}
			}
		else
			{
			if ( global )
				{
				int *ret = alloc_int( slen * rlen );
				for ( int row=0; row < slen; ++row )
					for ( int col=0; col < rlen; ++col )
						ret[row + col % rlen * slen] =
							regs[col]->Eval( (char**&) strs, slen, &match, row );
				result = new IValue( ret, slen * rlen );
				if ( rlen > 1 )
					{
					int *shape = alloc_int( 2 );
					shape[0] = slen;
					shape[1] = rlen;
					IValue *shapev = new IValue(shape,2);
					result->AssignAttribute("shape", shapev );
					Unref( shapev );
					}
				}
			else
				{
				glish_bool *ret = alloc_glish_bool( slen * rlen );
				for ( int row=0; row < slen; ++row )
					for ( int col=0; col < rlen; ++col )
						ret[row + col % rlen * slen] =
							regs[col]->Eval( (char**&) strs, slen, &match, row ) ?
							glish_true : glish_false;
				result = new IValue( ret, slen * rlen );
				if ( rlen > 1 )
					{
					int *shape = alloc_int( 2 );
					shape[0] = slen;
					shape[1] = rlen;
					IValue *shapev = new IValue(shape,2);
					result->AssignAttribute("shape", shapev );
					Unref( shapev );
					}
				}

			}
		}

	else if ( type == Regex::SUBST )

		if ( ! in_place )
			{
			int nlen = slen;
			charptr *rstrs = 0;

			//
			// This will allocate space for "rstrs", and fill it from "strs"
			//
			int tlen = nlen;
			IValue *err = 0;
			regs[0]->Eval( (char**&) rstrs, nlen, &match, 0, tlen, &err, 0, (char**) strs, slen );

			if ( err ) return err;

			for ( int j=1; j < rlen; ++j )
				{
				tlen = nlen;
				regs[j]->Eval( (char**&) rstrs, nlen, &match, 0, tlen, &err, 0, (char**) strs, slen );
				}

			result = new IValue( rstrs, nlen );
			}
		else
			{
			IValue* strval_ref = left->RefEval( opt, VAL_REF );
			IValue* rstrval = (IValue*) strval_ref->Deref();

			if ( rstrval->Type() != TYPE_SUBVEC_REF )

				result = rstrval->ApplyRegx( regs, rlen, match );

			else
				{
				VecRef *ref = rstrval->VecRefPtr();
				result = ((IValue*)rstrval->VecRefDeref())->ApplyRegx( regs, rlen, match, ref->Indices(), ref->Length() );
				ref->IndexUpdate( );
				}

			Unref( strval_ref );
			}


	else
		glish_fatal->Report( "bad type in ApplyRegExpr::Eval( )" );

	right->ReadOnlyDone( regval );
	left->ReadOnlyDone( strval );

	return result;
	}


CallExpr::~CallExpr()
	{
	if ( args )
		{
		loop_over_list( *args, i )
			NodeUnref( (*args)[i] );
		delete args;
		}
	}

const char *CallExpr::Description() const
	{
	return "func()";
	}

CallExpr::CallExpr( Expr* func, parameter_list* args_args, Sequencer* seq_arg )
    : UnaryExpr(func), sequencer(seq_arg)
	{
	args = args_args;
	}

IValue* CallExpr::Eval( evalOpt &opt )
	{
	evalOpt lopt(opt);
	IValue* func = op->CopyEval(opt);
	Func* func_val = func->FuncVal();

	if ( Sequencer::CurSeq()->System().Trace() )
		if ( Describe(glish_message->Stream(), ioOpt(ioOpt::SHORT(),"\t|-> ")) )
			glish_message->Stream() << endl;

	IValue* result = 0;

	sequencer->PushFuncName( op->Description(), file, line );

	opt = lopt;
	if ( ! func_val || ! (result = func_val->Call(opt,args)) )
		{
		if ( ! lopt.side_effects() )
			result = false_ivalue();
		}

	Unref( func );
	sequencer->PopFuncName( );

	return result;
	}

int CallExpr::DoesTrace( ) const
	{
	return 1;
	}


IValue *CallExpr::SideEffectsEval( evalOpt &opt )
	{
	opt.set(evalOpt::SIDE_EFFECTS);
	IValue* result = Eval( opt );

	if ( result )
		{
		if ( result->Type() == TYPE_FAIL )
			return result;

		Unref( result );
		}

	return 0;
	}

int CallExpr::Describe( OStream &s, const ioOpt &opt ) const
	{
	if ( opt.prefix() ) s << opt.prefix();
	op->Describe( s, ioOpt(opt.flags(),opt.sep()) );
	s << "(";
	loop_over_list( *args, i )
		{
		if ( i > 0 )
			s << ", ";

		(*args)[i]->Describe( s, ioOpt(opt.flags(),opt.sep()) );
		}

	s << ")";
	return 1;
	}


const char *IncludeExpr::Description() const
	{
	return "include ";
	}

IncludeExpr::IncludeExpr( Expr* fle, Sequencer* seq_arg )
    : UnaryExpr(fle), sequencer(seq_arg) { }

IValue* IncludeExpr::Eval( evalOpt &opt )
	{
	evalOpt lopt(opt);
	const IValue* file_val = op->ReadOnlyEval(opt);
	char *fle = file_val->StringVal();
	op->ReadOnlyDone( file_val );

	UserFunc::PushRootList( );
	IValue *ret = sequencer->Include( opt, fle );
	UserFunc::PopRootList( );

	if ( lopt.side_effects() )
		{
		Unref(ret);
		ret = 0;
		}

	free_memory( fle );
	return ret ? ret : new IValue( glish_true );
	}

void SendEventExpr::StandAlone( )
	{
	is_request_reply = 0;
	}

SendEventExpr::~SendEventExpr()
	{
	if ( args )
		{
		loop_over_list( *args, i )
			NodeUnref( (*args)[i] );
		delete args;
		}

	if ( sender )
		Unref( sender );
	} 

const char *SendEventExpr::Description() const
	{
	return "->";
	}

SendEventExpr::SendEventExpr( EventDesignator* arg_sender,
				parameter_list* arg_args )
	{
	sender = arg_sender;
	args = arg_args;
	is_request_reply = 1;
	int sqlen = glish_current_subsequence->length();
	in_subsequence =  sqlen ? (*glish_current_subsequence)[sqlen-1] : 0;
	}

IValue* SendEventExpr::Eval( evalOpt &opt )
	{
	IValue* result = sender->SendEvent( args, is_request_reply, in_subsequence );

	if ( opt.side_effects() && ( ! result || result->Type() != TYPE_FAIL ) )
		{
		Unref( result );
		return 0;
		}

	else
		return result;
	}

IValue *SendEventExpr::SideEffectsEval( evalOpt &opt )
	{
	opt.set(evalOpt::SIDE_EFFECTS);
	IValue *result = Eval(opt);
	if ( result )
		{
		if ( result->Type() == TYPE_FAIL )
			return result;

		glish_fatal->Report(
		"value unexpectedly returned in SendEventExpr::SideEffectsEval" );
		}

	return 0;
	}

int SendEventExpr::Describe( OStream &s, const ioOpt &opt ) const
	{
	if ( is_request_reply )
		s << "request ";

	sender->Describe( s, ioOpt(opt.flags(),opt.sep()) );
	s << "->(";
	describe_parameter_list( args, s );
	s << ")";
	return 1;
	}


LastEventExpr::LastEventExpr( Sequencer* arg_sequencer,
				last_event_type arg_type )
	{
	sequencer = arg_sequencer;
	type = arg_type;
	}

IValue* LastEventExpr::Eval( evalOpt &opt )
	{
	Notification* n = sequencer->LastNotification();

	if ( ! n || ! n->notifier )
		return (IValue*) Fail( this, ": no events have been received" );

	IValue* result;

	switch ( type )
		{
		case EVENT_AGENT:
			result = n->notifier->AgentRecord();

			if ( ! result )
				return (IValue*) Fail( this, ": no events have been received" );

			if ( opt.copy() || opt.copy_preserve() )
				result = copy_value( result );
			else
				Ref( result );
			break;

		case EVENT_NAME:
			result = new IValue( n->field );
			break;

		case EVENT_VALUE:
			result = n->value;

			if ( opt.copy() || opt.copy_preserve() )
				result = copy_value( result );
			else
				Ref( result );
			break;

		default:
			glish_fatal->Report( "bad type in LastEventExpr::Eval" );
		}

	return result;
	}

IValue* LastEventExpr::RefEval( evalOpt &opt, value_reftype val_type )
	{
	Notification* n = sequencer->LastNotification();

	if ( ! n )
		return (IValue*) Fail( this, ": no events have been received" );

	IValue* result;

	if ( type == EVENT_AGENT )
		result = new IValue( n->notifier->AgentRecord(), val_type );

	else if ( type == EVENT_NAME )
		result = new IValue( n->field );

	else if ( type == EVENT_VALUE )
		result = new IValue( n->value, val_type );

	else
		glish_fatal->Report( "bad type in LastEventExpr::RefEval" );

	return result;
	}

int LastEventExpr::Describe( OStream &s, const ioOpt &opt ) const
	{
	if ( opt.prefix() ) s << opt.prefix();

	switch( type )
		{
		case EVENT_AGENT: s << "$agent";
			break;
		case EVENT_NAME:  s << "$name";
			break;
		case EVENT_VALUE: s << "$value";
			break;
		default:          s << "$weird";
		}
	return 1;
	}


const char *LastEventExpr::Description() const
	{
	return "$last_event";
	}

LastRegexExpr::LastRegexExpr( Sequencer* arg_sequencer,
				last_regex_type arg_type )
	{
	sequencer = arg_sequencer;
	type = arg_type;
	}

IValue* LastRegexExpr::Eval( evalOpt &opt )
	{
	RegexMatch &match = sequencer->GetMatch();

	IValue* result;

	if ( type == REGEX_MATCH )
		{
		result = match.get( );
		if ( result )
			{
			if ( opt.copy() || opt.copy_preserve() )
				result = copy_value( result );
			else
				Ref( result );
			}
		else
			result = empty_ivalue();
		}
	else
		glish_fatal->Report( "bad type in LastRegexExpr::Eval" );

	return result;
	}

IValue* LastRegexExpr::RefEval( evalOpt &opt, value_reftype val_type )
	{
	RegexMatch &match = sequencer->GetMatch();

	IValue* result;

	if ( type == REGEX_MATCH )
		{
		IValue *ret = match.get( );
		if ( ret )
			result = new IValue( ret, val_type );
		else
			result = (IValue*) Fail( "no regular expression values" );
		}

	else
		glish_fatal->Report( "bad type in LastRegexExpr::RefEval" );

	return result;
	}

int LastRegexExpr::Describe( OStream &s, const ioOpt &opt ) const
	{
	if ( opt.prefix() ) s << opt.prefix();

	if ( type == REGEX_MATCH )
		s << "$m";
	else
		s << "$strange";

	return 1;
	}

const char *LastRegexExpr::Description() const
	{
	return "$m";
	}


void describe_expr_list( const expr_list* list, OStream& s )
	{
	if ( list )
		loop_over_list( *list, i )
			{
			if ( i > 0 )
				s << ", ";

			if ( (*list)[i] )
				(*list)[i]->Describe( s );
			}
	}
