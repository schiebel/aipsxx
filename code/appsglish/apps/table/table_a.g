# table_a.g: table function to do tabletoascii
#
#   Copyright (C) 1995,1996,1997,1998,1999,2000,2001,2002
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
#   $Id: table_a.g,v 19.1 2004/08/25 01:55:13 cvsmgr Exp $
#
#----------------------------------------------------------------------------

# Still to be done: 

pragma include once

include "table.g"


const tabletoascii := function(tab, asciifile, headerfile='', columns='',
			       sep=' ')
{


    if(!is_string(asciifile)  ||  len(asciifile) == 0) {
      return throw('asciifile must be a non-empty string', origin='table.toascii');
    }
    
#          S for Short Integer data 
#          I for Integer data 
#          R for Real data 
#          D for Double Precision data 
#          X for Complex data (Real followed by Imaginary) 
#          Z for Complex data (Amplitude then Phase) 
#         DX for Double Complex data (Real followed by Imaginary) 
#         DZ for Double Complex data (Amplitude then Phase) 
#          A for ASCII data (is enclosed in quotes if it contains whitespace)
#          B for Boolean data (T or F)
    private := [=];
    private.types:= [=];
    private.types['short'] := 'S';
    private.types['integer'] := 'I';
    private.types['double'] := 'D';
    private.types['float'] := 'R';
    private.types['complex'] := 'X';
    private.types['dcomplex'] := 'DX';
    private.types['polar'] := 'Z';
    private.types['dpolar'] := 'DZ';
    private.types['string'] := 'A';
    private.types['boolean'] := 'B';
    
    #######################
    private.readheader := function(infile, ref format, ref columns) {
      
      # Open the input file
      f:=open(paste("< ", infile));
    
      headerline := read(f);
      formatline := read(f);
      if(is_string(headerline) && strlen(headerline) &&
	 is_string(formatline) && strlen(formatline)) {
	val columns := split(headerline);
	types   := split(formatline);
	if(length(columns) != length(types)) {
	  throw('Mismatch in first and second lines of header file',
		origin='table.toascii.readheader');
	  return F;
	}
	iformat := [=];
	for (col in 1:length(columns)) {
	  iformat[columns[col]] := types[col];
	}
      }
      f:=F;
      val format := iformat;
      return T;
    }
    
    #######################
    # Write the header
    private.writeheader := function(tab, outfile, ref format, ref columns) {
      
      wider private;
      
      iformat := [=];
      
      ncols := length(columns);
      
      # Read one row to get the header information
      trw:=tablerow(tab, columns);
      row := trw.get(1);
      trw.close();
      
      # Write the header and type line
      headerline := array('', ncols);
      typeline := array('', ncols);
      
      for (col in 1:ncols) {
	value := row[columns[col]];
	type := type_name(value);
	headerline[col] := columns[col];
	if(has_field(private.types, type)) {
	  typeline[col] := private.types[type];
	  iformat[columns[col]] := private.types[type];
	} else {
	  return throw(paste('Cannot process type', type),
		       origin='table.toascii.writeheader');
	}
      }
      # Now write the results
      
      f:=open(paste('>>', outfile));
      write(f, paste(headerline));
      write(f, paste(typeline));
      f:=F;
      
      val format := iformat;
      
      return T;
    }
    
    #######################
    private.writevalue := function(value, type) {
      if(type=='Z' || type=='X' || type=='DZ' || type=='DX') {
	if(!is_complex(value)&&(!is_dcomplex(value))) {
	  return throw(paste('Illegal type', type, 'for complex value'),
		       origin='table.toascii.writevalue');
        }
	x := real(value);
	y := imag(value);
	if (type=='Z' || type=='DZ') {
	  rad := sqrt(x*x+y*y);
	  phi := atan2(y,x);
	  return paste(rad, phi);
        } else {
	  return paste(x, y);
	}
      } else if(type=='A') {
	return as_evalstr(value);
      } else {
	return as_string(value);
      }
    }
    
    #######################
    private.writekeyword := function(keyword, value) {
      wider private;
      type := type_name(value);
#
#          S for Short Integer data 
#          I for Integer data 
#          R for Real data 
#          D for Double Precision data 
#          X for Complex data (Real followed by Imaginary) 
#          Z for Complex data (Amplitude then Phase) 
#         DX for Double Complex data (Real followed by Imaginary) 
#         DZ for Double Complex data (Amplitude then Phase) 
#          A for ASCII data (is enclosed in quotes if it contains whitespace)
#          B for Boolean data (T or F)
      if(has_field(private.types, type)) {
	tp := private.types[type];
	return paste(keyword, tp, private.writevalue(value, tp));
      } else {
	note (paste('Cannot process type', type, 'of keyword', keyword),
	      origin='table.toascii.writekeyword');
	return '';
      }
    }
    
    #######################
    private.writerow := function(row, format, sep) {
      wider private;
#
#          S for Short Integer data 
#          I for Integer data 
#          R for Real data 
#          D for Double Precision data 
#          X for Complex data (Real followed by Imaginary) 
#          Z for Complex data (Amplitude then Phase) 
#         DX for Double Complex data (Real followed by Imaginary) 
#         DZ for Double Complex data (Amplitude then Phase) 
#          A for ASCII data (is enclosed in quotes if it contains whitespace)
#          B for Boolean data (T or F)
      ncols := length(row);
      line := array('', ncols);
      for (col in 1:ncols) {
	returnval := private.writevalue(row[col], format[col]);
	if(is_fail(returnval)) return returnval;
	if(!is_string(returnval)) return throw('Value not a string',
					       origin='table.toascii.writerow');
	line[col] := returnval;
      }
      line := paste(line,sep=sep);
      return line;
    }
    
    #######################
    private.writekeyvalues := function(keywords, colname, ref f) {
      if(is_record(keywords)&&length(keywords)>0) {
        write(f, paste('.keywords', colname));
	for(keyword in field_names(keywords)) {
	  line := private.writekeyword(keyword, keywords[keyword]);
	  if(is_string(line)&&strlen(line)) {
	    write(f, line);
	  }
        }
	write(f, '.endkeywords');
      }
      return T;
    }
    
    private.writekeywords := function(ref tab, columns, outfile) {
      
      wider private;
      f := open(paste('>', outfile));
      keywords := tab.getkeywords();
      private.writekeyvalues (keywords, '', f);
      for (col in columns) {
	keywords := tab.getcolkeywords(col);
	private.writekeyvalues (keywords, col, f);
      }
      f := F;        # close file
      return T;
    }
      
    #######################
    private.writerows := function(tab, asciifile, format, columns, sep) {
      wider private;
      
      if(length(format)!=length(columns)) {
	return throw('Format does not match the columns', origin='table.toascii.writerows');
      }
      f:=open(paste('>>', asciifile));
      
      # Make a table row iterator
      trw := tablerow(tab, columns);
      if(is_fail(trw)) fail;
      
      # Write all the rows
      nwritten := 0;
      for (row in 1:tab.nrows()) {
	rowrec := trw.get(row);
	if(is_fail(rowrec)) fail;
	line := private.writerow(rowrec, format, sep);
	if(is_string(line)&&strlen(line)) {
	  write(f, line);
	  nwritten +:=1;
	} else {
	  if(is_fail(line)) return line;
	}
      }
      
      # Close the tablerow iterator
      trw.close();
      
      f:=F;
      
      return nwritten;
    }
    
    ######################
    
    if(!is_string(columns) || sum(strlen(columns))==0) {
      columns := tab.colnames();
    }
    # Remove columns containing arrays.
    for (i in ind(columns)) {
      if (!tab.isscalarcol(columns[i])) {
	note(paste('Column',columns[i],'ignored as it is not a scalar column'),
	     origin='table.toascii');
	columns[i] := ''
      }
    }
    columns := columns[columns!=''];
    ncols := length(columns);
    if(ncols==0) {
      return throw('No columns to write', origin='table.toascii');
    }
    print columns
    
    # Open and write
    local format
    outfile := asciifile;
    if(is_string(headerfile) && strlen(headerfile)) {
      include "os.g";
      if(dos.fileexists(headerfile)&&private.readheader(headerfile, format, columns)) {
	note(paste('Read header from', headerfile));
      } else {
	note(paste('Writing keywords to', headerfile));
	if(is_fail(private.writekeywords(tab, columns, headerfile))) fail;
	note(paste('Writing header to', headerfile));
	if(is_fail(private.writeheader(tab, headerfile, format, columns))) fail;
      }
    } else {
      note(paste('Writing keywords to', asciifile));
      if(is_fail(private.writekeywords(tab, columns, asciifile))) fail;
      note(paste('Writing header to', asciifile));
      if(is_fail(private.writeheader(tab, asciifile, format, columns))) fail;
    }
    
    note(paste('Output format:', format));
    
    # Write the table rows
    note(paste('Writing table rows to', asciifile));
    nrows := private.writerows(tab, asciifile, format, columns, sep);
    
    if(nrows>0) {
      note(paste('Wrote', nrows, 'rows'));
      return nrows;
    } else {
      return throw('Could not write any rows', origin='table.toascii');
    }
    return T;
  }
