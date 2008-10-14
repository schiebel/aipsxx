# app.g: Command line parameter setting shell
#
#   Copyright (C) 1998
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
#   $Id: 
#

pragma include once

include 'apputil.g';

const unset := [i_am_unset='i_am_unset'];
const is_unset := function(v) { return is_record(v) && length(unset)==1 && 
			      has_field(v, 'i_am_unset'); }

app := function (fullmethod, object=unset)
{
   private := [=];

   # Function to read meta information and .g script
   private.readmeta := function (class)
   {
      tmp := spaste (class, '.g');
      if (!include tmp)
         return throw ('private.readmeta - error reading [class].g file');
      tmp := spaste (class, '_meta.g');
      if (!include tmp)
         return throw ('private.readmeta - error reading [class]_meta.g file');
      
      return types.meta (class);
   }

   # Function to set default parameter values
   private.setdefault := function (metainfo, method)
   {
      wider private;
      # eval only works with global variables for now
      global _meta, _method, _field, _var;
      _meta := metainfo;
      _method := method;

      # Initialize parameter record
      private.parms := [=];
 
      # Check if pre-requisite parameters needed
      vars := ["data"];
      if (!private.obj && has_field(metainfo[method], "prereq")) 
         vars[2] := "prereq";
      
      for (var in vars) {
         fields := field_names (metainfo[method][var]);
         for (field in fields) {
            _field := field;
            _var := var;
            cmd := spaste ('_', field, 
               ':= _meta[_method][_var][_field].default');
            if (has_field(metainfo[method][var][field], "default")) {
               if (!eval (cmd))
                  return throw ('private.setdefault - invalid default');

               # Fill parameter record
               private.parms[field] := metainfo[method][var][field].default;
            } else {
               private.parms[field] := 
                  valuetypes.default (metainfo[method][var][field].type);
            };
         }
      }
      return T;
   }

   # Function to display the input parameters on stdout
   private.display := function (ref obj, class, method, object)
   {
      wider private;
      vstring := obj.format (method, private.parms, 72, 5);
      nlines := length (vstring);
      print;
      print spaste ('Method:   ', class, '.', method);
      if (private.obj) print spaste ('Object:   ', object);
      print;
      for (j in 1:nlines) {
         print vstring[j];
      };
      print;
      return T;
   }

   # Function to update the parameter record
   private.update := function ()
   {
      wider private;
      # Glish eval command only works for global variables for now
      global _parms;
      _parms := private.parms;

      fields := field_names (private.parms);
      for (field in fields) {
         cmd := spaste ('_parms.', field, ' := _', field);
         if (!eval (cmd))
            return throw ('private.update - invalid update');
      };
      # Copy back to private.parms
      private.parms := _parms;
      return T;
   };

   # Check if implicit object provided
   private.obj := !is_unset (object);

   # Create refernce to implicit object, if specified
   if (private.obj) {
      global _obj;
      cmd := spaste ('_obj := ref ', object);
      if (!eval (cmd))
         throw ('Error initializing implicit object');
   };

   # Extract class name
   dotcount := (fullmethod ~ m/\./g);
   if (dotcount == 0) {
      class := fullmethod;
      method := fullmethod;
   } else {
      tmp := split (fullmethod, '.');
      class := tmp[1];
      method := tmp[2];
   }
   
   # Get meta information
   meta := private.readmeta (class);

   # Set default parameter values
   private.setdefault (meta, method);

   # Create application utility distributed object
   au := apputil (meta);

   # Display to stdout for now
   private.display (au, class, method, object);

   # Loop, reading input commands
   endloop := F;
   while (!endloop) {

      # Read command from stdin; parse into sub-commands
      cmd := au.readcmd();
      subcmd := au.parse (private.parms, cmd);
      j := 1;
      ncmd := length (subcmd);

      while (j <= ncmd && !endloop) {
 
         # Process command
         # Command TGET:
         if (subcmd[j] == 'tget') {
            j := j + 1;

         # Command TPUT:
         } else if (subcmd[j] == 'tput') {
            j := j + 1;

         # Command INP:
         } else if (subcmd[j] == 'inp') {
            private.display (au, class, method, object);

         # Command GO:
         } else if (subcmd[j] == 'go') {
            endloop := T;

         # Command SETPARM:
         } else if (subcmd[j] == 'setparm') {
            j := j + 1;
            if (!eval (subcmd[j])) 
               print 'Syntax error: ',subcmd[j];
            private.update();

         # Command QUIT:
         } else if (subcmd[j] == 'quit') {
            endloop := T;
         };
         j := j + 1;
      } # if (subcmd[j]...
   }; # while (!endloop)...

   # Execute "go" command if necessary
   if (endloop && subcmd[j-1] == 'go') {
   
      # If implicit object provided, then execute method directly
      if (private.obj) {
         # eval only works for global variables for now
         fields := field_names (meta[method].data);
         nfields := length (fields);
         cmd := spaste ('_obj.', method, '(');
         j := 1;
         while (j <= nfields) {
            cmd := spaste (cmd, '_', fields[j]);
            if (j != nfields) cmd := spaste (cmd, ',');
            j := j + 1;
         };
         cmd := spaste (cmd, ')');
         if (!eval (cmd))
            print 'Syntax error: ', cmd;
      } else {
         # No object specified; execute script
         if (has_field (meta[method], 'script')) {
            nscript := length (meta[method].script);
            for (j in 1:nscript) {
               if (!eval (meta[method].script[j]))
                  return throw ('Error executing meta script');
            };
         } else {
            print 'Implicit object must be supplied for this method';
         }; # if (has_field(meta[method]...
      }; # if (private.obj)...
   }; # if (endloop && subcmd[j-1] == 'go')...

   return T;
}; # main









