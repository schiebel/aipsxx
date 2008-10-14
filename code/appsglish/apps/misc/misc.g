# misc.g: Misc commands
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002
#   Associated Universities, Inc. Washington DC, USA.
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2 of the License, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#   more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Foundation, Inc.,
#   675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
#   Correspondence concerning AIPS++ should be addressed as follows:
#          Internet email: aips2-request@nrao.edu.
#          Postal address: AIPS++ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#   $Id: misc.g,v 19.2 2004/09/20 19:49:46 jmcmulli Exp $
#

# See tmisc.g for the tmisc() test function

pragma include once;
 
include 'note.g';
include 'sh.g';
include 'unset.g';

const misc:=function()
{
   
    public:=[=];
    public::print.limit := 1;
    private:=[=];

###
    const public.escapespecial := function(astring) {
	xspec := s/([\#\*\(\)\|])/\\$1/g
	if (!is_string(astring)) fail "argument must be a string";
	return astring ~ xspec;
    }

###
    const public.shellcmd:=function(command,log=T) 
    {
	if(!is_string(command)) fail "Command must be a string";
	if(!is_boolean(log)) fail "log must be boolean";
	a:=shell(command);
	for (line in a) {
	    if (log) {	
		note(line, priority='NORMAL', origin=command);
	    } else {
		print line;
	    }
	}
	return (a::status==0);
    }

###   
    const public.type := function()
    {
       return 'misc';
    }
   
###
    const public.stripleadingblanks := function (const string)
    {  
	if(!is_string(string)) fail "Argument is not a string";
	return string ~ s/^\s*//;
    }

###
    const public.striptrailingblanks := function (const string)
    {  
	if(!is_string(string)) fail "argument is not a string";
	return string ~ s/\s*$//;
    }

###
    const public.patternmatch := function (const pattern, const strings)
    {  
	if(!is_string(pattern)) fail "First argument is not a string";
	if(!is_string(strings)) fail "Second argument is not a string";
	# turn the pattern into a regular expression
	pattern =~ [ s@([^\\]?)([$)(\.+^])@$1\\$2@g, s/([^\\]?)\?/$1./g, s/([^\\]?)\*/$1.*/g, s/([^\\]?){([^}]*?)}/$1$$(?:$2)$$/g ];
	if ( len(pattern) > 1 )
	    for (i in 1:len(pattern) )
		if ( pattern[i] ~ m/^\(/ )
		    pattern[i] ~:= s/([^\\]?),/$1|/g;
	return strings[strings ~  eval(spaste('m!^',spaste(pattern) ~ s/([^\\]?)!/$1\\!/g,'$!'))];
    }

###
    const public.fileexists := function (const file, opt='-s')
    {  
	if(!is_string(file)) fail "First argument is not a string";
	if(!is_string(opt)) fail "Second argument is not a string";
        result := dsh.command( paste('if [', opt, file,'] \nthen\n echo 1\nelse\necho 0\nfi' ) );
        if (result.status==0) {
	  return as_boolean(as_integer(result.lines));
	}
	else {
          fail paste("Cannot determine existence of file ", file);
	}
    }

###
    const public.dir := function (const directoryname='.')
    {
      if(!is_string(directoryname)) fail "Argument is not a string";
      if(!public.fileexists(directoryname,'-d')) fail "Directory does not exist";
      result:=dsh.command(paste('ls -a1',directoryname));
      files := result.lines;
	return [ directoryname, files[files !~ m/^\.$|^\..$/] ]
    }

###
    const public.thisdir := function (const directoryname='.')
    {  
      if(!is_string(directoryname)) fail "Argument is not a string";
      if(!public.fileexists(directoryname,'-d')) fail "Directory does not exist";
      result:=shell(spaste('cd ',directoryname,'; pwd'));
      if(len(result) > 0) {
        return result;
      }
      else {
        fail "Cannot determine this directory";
      }
    }

###
    const public.parentdir := function (const directoryname='.')
    {  
      if(!is_string(directoryname)) fail "Argument is not a string";
      if(!public.fileexists(directoryname,'-d')) fail "Directory does not exist";
      result:=shell(spaste('cd ',directoryname,'/..; pwd'));
      if(len(result) > 0) {
        return result;
      }
      else {
        fail "Cannot determine parent directory";
      }
    }
    public.parentDir:=public.parentdir;

###
    const public.filetype := function (const filename)
    {  
	if(!is_string(filename)) fail "Argument is not a string";
        sr := stat(filename,follow=T)
        if ( length(sr) > 0 && is_string(sr.type) )
	    {
            if ( sr.type == 'regular' ) return 'Regular File'
            if ( sr.type == 'directory' )
                {
                if (public.fileexists(spaste(filename,'/table.dat'),'-f'))
                    return 'Table'
                return 'Directory'
                }
            return sr.type
            }
	fail "File doesn't exist"
    }
    public.fileType := public.filetype;

###
    const public.readfile := function ( _file_name)
    {
	if(!is_string(_file_name)) fail "Argument is not a string";
        if (!public.fileexists(_file_name,'-f')) fail "File does not exist"
	ret := as_string([])
	f := open(["<",_file_name])
	while ( x := read(f,256,'c') ) ret := [ret, x]
	return ret
    }

###
    const public.fopen := function ( _file_name, _mode )
    {
	if(!is_string(_file_name)) fail "First argument is not a string";
	if(!is_string(_mode)) fail "Second argument is not a string";
        

        if ( _mode == 'r' ) {
           _mode := "<"
           if (!public.fileexists(_file_name,'-f')) fail "File does not exist"
        }
	else if ( _mode == 'w' ) _mode := ">"
	else if ( _mode == 'a' ) _mode := ">>"
	else fail "Bad mode"

	return open([_mode,_file_name])
    }

###
    const public.fclose := function (ref file_id )
    {
	if(!is_file(file_id)) fail "Non-file type";
	# resetting this to some non-file type should close the file
	val file_id := F;
	return T;
    }
    const public.fprintf := fprintf

###
    const public.fgets := function ( _file_id, _filler=' ' )
    {
	if(!is_file(_file_id)) fail "Non-file type"
	if(!is_string(_filler)) fail "Non-string filler"
	if ( ret := read(_file_id) )
		{
		ret =~ s/\n$//
		if ( _filler != ' ' ) ret =~ eval(spaste('s/ /',_filler,'/g'))
		}
	return ret
    }

###
    const public.fread := function ( _file_id, _type, _num_items )
    {
	fail "DEPRECATED"
    }

###
    const public.fwrite := function ( _file_id, _array )
    {
	fail "DEPRECATED"
    }

###
    const public.initspinner := function (interval=1.0)
    {
	wider private;

	local spinner_chars := ['|','/','-','\\\\'];
	local iter := 0;
	local next_char;
  
	private.spinner_timer := client("timer", interval);
	whenever private.spinner_timer->ready do {
	    next_char := spinner_chars[iter % len(spinner_chars) + 1];
	    iter := iter + 1;
	    j:=printf('%s%c', next_char, 8);
	}
    }

###
    const public.killspinner := function ()
    {
	wider private;
	deactivate whenever_stmts(private.spinner_timer).stmt;
	spinner_timer->terminate();
	private.spinner_timer := F;
    }


###
   const public.listfields := function (rec, listdata=T, depth=0)
   {
      if (!is_record(rec)) {
         return throw ('Input is not a record', origin='misc.listfields');
      }
      depth := abs(depth);
#
      depth +:= 1;
      fn := field_names(rec);
      for (f in fn) {
        if (is_record(rec[f])) {
           s := array('', depth*2);
           print s, f
           public.listfields(rec[f], listdata, depth);
        } else {
           s := array('', depth*2);
           if (listdata) {
              print s, f, '=', rec[f]
           } else {
              t := full_type_name(rec[f]);
              print s, f, '=', t
           }
        }
     }
#
     return T;
   }

### 
    const public.timetostring := function (timevalue=time(),
					   form="ymd local") {
      tmp := eval('include \'quanta.g\'');
      if(is_fail(tmp)) fail;
      zero:=dq.quantity('1jan1970');
      qtime := dq.quantity(timevalue, 's');
      return dq.time(dq.add(zero,qtime), prec=6, form=form);
    }


###
   const public.tovector := function (thing, type='string', unsetvalue=unset)
#
# Convert something to a vector.   This should move, in some form, to
# entryparser.g at some point.
#
# Rules:
#  1) if thing is unset you get an empty (length 0) vector back
#  2) if thing is a record, and an individual item is unset, it gets the
#     value unsetvalue.  However, if unsetvalue is unset
#     then an exception is thrown (menaing unset not allowed
#     in individual items   
#  3) vectors, vectors of strings and strings (space and comma delimitered)
#     are allowed 
#
   {
       type2 := to_upper(type);
       tmp2 := thing;
       const n := length(tmp2);
#
       if (is_unset(tmp2)) {
          if (type2=='FLOAT') {
             return as_float([]);
          } else if (type2=='DOUBLE') {
             return as_double([]);
          } else if (type2=='INTEGER') {
             return as_integer([]);
          } else if (type2=='BOOLEAN') {
             return as_boolean([]);
          } else {   
             return "";
          }
       } else {
          if (n==1) {

# Not a vector or vector of length 1

             tmp1 := tmp2;
             if (is_string(tmp1)) {
                if (strlen(tmp1)==0) {
#
# Handle this separately because split(['']) yields something
# of length 0.
#
                   tmp2 := [''];                  # length = 1
                } else {
                   tmp1 =~ s/,/ /g;               # replace commas by 1 space
                   tmp1 =~ s/\s */ /g;            # replace white space by 1 space
                   tmp1 =~ s/^\s*//;              # remove leading blanks
                   tmp1 =~ s/\s*$//;              # remove trailing blanks
                   tmp1 =~ s/\[//g;               # remove leading "["
                   tmp1 =~ s/\]//g;               # remove trailing "["
                   tmp2 := split(tmp1);           # Vector 
                }
             }
          }
#   
# Convince Glish that this thing is a vector.  So even if its just [1]
# give it a shape 1 so that any ensuing C++ will get a vector
# not an Int
#
          tmp2::shape := length(tmp2);
#
# Replace individual unset values if input is a record
#
           if (is_record(tmp2)) {
              if (n>0) {
                 for (i in 1:n) {
                    if (is_unset(tmp2[i])) {
                       if (is_unset(unsetvalue)) {  
                          return throw('unset not allowed',
                                        origin='misc.tovector');
                       } else {
                          tmp2[i] := unsetvalue;
                       }
                     }
                  }
               }
           }
#
# Convert its type
#
          if (type2=='FLOAT') {
             if (is_record(tmp2)) {
                tmp3 := [];
                if (n>0) {
                   for (i in 1:n) tmp3[i] := as_float(tmp2[i]);
                }
                return tmp3;
             } else {
                return as_float(tmp2);
             }
          } else if (type2=='DOUBLE') {
             if (is_record(tmp2)) {
                tmp3 := [];
                if (n>0) {
                   for (i in 1:n) tmp3[i] := as_float(tmp2[i]);
                }
                return tmp3;
             } else {
                return as_double(tmp2);
             }
          } else if (type2=='INTEGER') {
             if (is_record(tmp2)) {
                tmp3 := [];
                if (n>0) {
                   for (i in 1:n) tmp3[i] := as_integer(tmp2[i]);
                }
                return tmp3;
             } else {   
                return as_integer(tmp2);
             }
          } else if (type2=='BOOLEAN') {
             if (is_record(tmp2)) {
                tmp3 := [];
                if (n>0) {
                   for (i in 1:n) tmp3[i] := as_boolean(tmp2[i]);
                }
                return tmp3;
             } else {   
                return as_boolean(tmp2);
             }
          } else if (type2=='STRING') {
             if (is_record(tmp2)) {
                tmp3 := "";
                if (n>0) {
                   for (i in 1:n) tmp3[i] := as_string(tmp2[i]);
                }
                return tmp3;
             } else {
                return as_string(tmp2);
             }
          } else {
             return throw ('Unrecognized type', origin='misc.tovector');
          }
      }
   }

###
#
#  Function fields produces a more human-readable listing of field_names
#  J Braatz

    const public.fields := function(rec) {
     if (!is_record(rec)) {
       print 'not a record'
       return T
       }
     maximum := 0
     flds := sort(field_names(rec))
     for (i in field_names(rec))
       if ((strlen(i)+1)>maximum) maximum := strlen(i)+1
     ncols := min(as_integer(80/maximum),len(flds))
     nrows := as_integer((len(flds)-1)/ncols) + 1
     strformat := spaste('%-',maximum,'s')
     if (len(flds)!=nrows*ncols) {
       for (i in (len(flds)+1):nrows*ncols)
         flds[i] := ' '
       }
     for (i in 1:nrows) {
       for (j in 1:ncols)
         printf(strformat,flds[(j-1)*nrows+i])
       printf('\n')
       } 
     return T
     }

    return public;
}

const defaultmisc:=misc();
const dms:=ref defaultmisc;

# Keep this for a short while only TJC 3/9/99
# Don't copy the type function so that it will be
# invisible to manager and toolmanager.
du:=[=];
for (field in field_names(dms)) {
  if(field!='type') du[field] := ref dms[field];
}
field:=F; #reset global variables

note('defaultmisc (dms) ready', priority='NORMAL', origin='misc');
