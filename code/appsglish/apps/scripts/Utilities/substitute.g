# substitute.g: substitute glish variables and expressions
# Copyright (C) 1998,1999
# Associated Universities, Inc. Washington DC, USA.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
# License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation,
# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: substitute.g,v 19.2 2004/08/25 02:10:23 cvsmgr Exp $

pragma include once


# This function tries to substitute $name by its value.
# The following rules apply:
# 1. A name must start with an underscore or alphabetic, followed
#    by zero or more alphanumerics and underscores.
# 2. Parts enclosed in single or double quotes are left untouched.
#    Furthermore a $ can be escaped by a backslash, which is useful
#    when an environment variable is used. Note that glish
#    requires an extra backslash to escape the backslash.
#    The output contains the quotes and backslashes.
# 3. When name has a vector value, its substitution is enclosed in
#    square brackets and separated by commas.
# 4. A string value is enclosed in double quotes. When the value
#    contains a double quote, that quote is enclosed in single quotes.
# 5. When the name has a record value representing an object (e.g. table),
#    it is substituted by $n (n is a sequence number), while the table-id
#    is added to idrec. The first field in idrec is 'nr' containing
#    the number of substituted table-id's. The other fields contain
#    the table-id's at each sequence number. The fields are
#    unnamed, but can be accessed with the index operator such that:
#        field[n+1] contains the table-id of $n.
# 6. When the name is unknown or has an unknown type, it is left untouched
#    (thus the result contains $name).
#
# Furthermore it substitutes $(expression) by the expression result.
# It correctly handles parentheses and quotes in the expression.
# E.g.   $(a+b)
#        $((a+b)*(a+b))
#        $(len("ab cd( de"))
# Similar escape rules as above apply.
#
# Substitution is NOT recursive. E.g. if a:=1 and b:="$a",
# the result of substitute("$a") is "$a" and not 1.

const substitute := function (const string, const type='', const startseqnr=1, ref idrec=[=])
{
# Initialize output record (no table substitutions yet).
# Add possibly missing fields, so we can add fields to idrec using [].
  val idrec := [=];
  idrec.nr := max(1,startseqnr) - 1;
  if (idrec.nr > 0) {
    for (i in 1:(idrec.nr)) {
      idrec[i+1] := 0;
    }
  }
# Split the string into its individual characters.
# Initialize some variables.
  s := split(string,'');
  l := len(s);
  backslash := F;
  dollar := F;
  nparen := 0;
  name := '';
  evalstr := '';
  squote := F;
  dquote := F;
  out := '';
  for (i in 1:l) {
    tmp := s[i];

# When a dollar was found, we might have a name.
# Alphabetics and underscore are always part of name.
    if (dollar) {
      if (tmp=='_'  ||  (tmp>='a' && tmp<='z')  ||  (tmp>='A' && tmp<='Z')) {
        name := spaste(name, tmp);
        tmp := '';
      } else {
# Numerics are only part when not first character.
        if (tmp>='0' && tmp<='9' && name!='') {
          name := spaste(name, tmp);
          tmp := '';
        } else {
          if (tmp=='(' && name=='') {
# $( indicates the start of a subexpression to evaluate.
            nparen := 1;
            evalstr := '';
            tmp := '';
            dollar := F;
          } else {
# End of name found. Try to substitute.
            dollar := F;
            out := spaste (out,substitutename(name,type,idrec));
          }
        }
      }
    }

    if (tmp != '') {
# Handle possible single or double quotes.
      if (tmp == '"'  &&  !squote) {
        dquote := !dquote
      } else {
        if (tmp == "'"  &&  !dquote) {
          squote := !squote;
        } else {
          if (!dquote && !squote) {
# Count the number of balanced parentheses (outside quoted strings)
# in the subexpression.
            if (nparen > 0) {
              if (tmp == '(') {
                nparen +:= 1;
              } else {
                if (tmp == ')') {
                  nparen -:= 1;
                  if (nparen == 0) {
# The last closing parenthese is found.
# Evaluate the subexpression and if successful put the result in the output.
                    t := eval (evalstr);
                    ts := substitutevar(t);
                    if (ts == 0) {
                      out := spaste (out,'$(',evalstr,')');
                    } else {
                      out := spaste (out,ts);
                    }
                    tmp := '';
                  }
                }
              }
            } else {
# Set a switch if we have a dollar (outside quoted and eval strings)
# that is not preceeded by a backslash.
              if (tmp == '$'  &&  !backslash) {
                dollar := T;
                name := '';
                tmp := '';
              }
            }
          }
        }
      }
    }
# Add the character to output or eval string.
# Set a switch if we have a backslash.
    if (tmp != '') {
      if (nparen > 0) {
        evalstr := spaste (evalstr, tmp);
      } else {
        out := spaste (out, tmp);
      }
    }
    backslash := (tmp == '\\');
  }

# The entire string has been handled.
# Substitute a possible last name.
# Insert a possible incomplete eval string as such.
  if (dollar) {
    out := spaste (out,substitutename(name,type,idrec));
  } else {
    if (nparen > 0) {
      out := spaste (out,'$(',evalstr);
    }
  }
  return out;
}



# This function tries to substitute the given name using
# the rules described in the description of function substitute.
const substitutename := function (const name, const type='', ref idrec=[=])
{
# When the name is empty, return a single dollar.
  if (len(name) == 0  ||  name == '') {
    return '$';
  }
# When the name is undefined, return the original.
  if (!is_defined(name)) {
    return spaste ('$', name);
  }
  v := symbol_value (name);
  if (is_string(v)  ||  is_numeric(v)  ||  is_boolean(v)) {
    return substitutevar(v);
  }

# A record might indicate a table.
# If so, add its id to idrec and return its sequence number.
  if (len(type) > 0  &&  type != ''  &&  is_record(v)) {
    if (any (type == 'table')) {
      if (has_field (v, "handle")) {
        h := v.handle();
        if (has_field(h, "type")  &&  h.type == 'table') {
          if (has_field(h, "id")) {
            idrec.nr +:= 1;
            idrec[idrec.nr+1] := h.id;
            return spaste ('$', idrec.nr);
          }
        }
      }
    }
# A record might indicate a region.
# If so, add it to idrec and return its sequence number.
    if (any (type == 'region')) {
      if (has_field (v, "type")  &&  v.type() == 'itemcontainer') {
        if (has_field(v, "has_item")  &&  v.has_item('isRegion')) {
          idrec.nr +:= 1;
          idrec[idrec.nr+1] := v.torecord();
          return spaste ('$REGION#', idrec.nr);
        }
      }
    }
# If the record is an object with a matching type, substitute it
# by its object id. In C++ the function ObjectID::extractIDs can be
# used to extract the object id's.
    if (has_field(v, "type")  &&  any(v.type() == type)) {
      if (has_field(v, "id")) {
        return spaste ("'ObjectID=", as_string(v.id()), "'");
      }  
    }
  }
# The value has an unknown type.
# Return the original name.
  return spaste ('$', name);
}



# Substitute a string, numeric, or boolean value.
const substitutevar := function (const v)
{
# A string needs to be enclosed in quotes.
# A vector value is enclosed in square brackets and separated by commas.
  if (is_string(v)) {
    if (len(v) == 1) {
      return substitutestring (v);
    }
    out := spaste('[',substitutestring(v[1]));
    for (i in 2:len(v)) {
      out := spaste (out,',',substitutestring(v[i]));
    }
    out := spaste (out,']');
    return out;
  }

# A numeric or boolean value is converted to a string.
# A vector value is enclosed in square brackets and separated by commas.
# Take care we have enough precision.
  if (is_numeric(v)  ||  is_boolean(v)) {
    if (len(v) == 1) {
      tmp := v;
      tmp::print.precision:=15
      return spaste (tmp);
    }
    tmp := v[1];
    tmp::print.precision:=15
    out := spaste('[',tmp);
    for (i in 2:len(v)) {
      tmp := v[i];
      tmp::print.precision:=15
      out := spaste (out,',',tmp);
    }
    out := spaste (out,']');
    return out;
  }

# The value has an unknown type.
  return 0;
}



# Enclose a string in double quotes.
# When the string contains double quotes, enclose them in single quotes.
# E.g.             ab"cd
# is returned as   "ab"'"'"cd"
# which is according to the TaQL rules for strings.
const substitutestring := function (const value)
{
  out:='"';
  v := split (value,'');
  for (i in 1:len(v)) {
    if (v[i] == '"') {
      out := spaste (out,'"',"'",'"',"'",'"');
    } else {
      out := spaste (out, v[i]);
    }
  }
  return spaste(out,'"');
}
