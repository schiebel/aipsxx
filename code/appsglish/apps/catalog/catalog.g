# catalog.g: a glish convenience script for logging 
# Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
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
# $Id: catalog.g,v 19.2 2006/06/22 22:23:31 wyoung Exp $

pragma include once

include 'table.g';
include 'sh.g';
include 'misc.g';
include 'os.g';
include 'aipsrc.g';
include 'note.g';
include 'serverexists.g'

#defaultservers.trace(T);


catalog := function()
{
    if (!serverexists('dos', 'os', dos)) {
       return throw('The operating system server "dos" is not running',
                     origin='catalog.g');
    }
    if (!serverexists('dms', 'misc', dms)) {
       return throw('The misc server "dms" is not running',
                     origin='catalog.g');
    }
#
    public  := [=];    # Public member functions
    private := [=];    # Private data

    private.initialized := F;
    private.selectcallback := F;

    private.selection:='';
    private.mask:='*';

    private.use_gui := F
    private.dir := '.';
    private.show_types := 'All';

    private.view := [=];
    private.edit := [=];

    private.images := [=];
    private.tmpimage := F;

    private.asyncs := [=];

    const private.less := function (file)
    {
	print paste('reading file', file, '...');
	print ''
	size := dos.size(file);
	if (size > 100000) {
	    fail paste('File', file, ' too large to view as text in this window');
	}
	fd := open(['<',file]);
	contents := '';
	while ( <fd> ) contents := spaste(contents,_);
	return contents;
    }

    const private.tr_confirm := function (confirm)
    {
      if (is_boolean(confirm)) {
	if (confirm) {
	  return 'yes';
	}
	return 'no';
      }
      if (is_string(confirm)) {
	confirm := to_lower(confirm);
	if (! any(confirm == "yes directory no")) {
	  fail paste("invalid confirm argument", confirm,
		     "(must be yes, directory, or no)");
	}
      }
      return confirm;
    }


    const public.gui := function (refresh=F, show_types=unset,
				  vscrollbarright=unset) {
      wider private;
      private.init();
      wrflag := is_boolean(refresh);
      if (private.use_gui) {
	private.guisink.activate();
	if (wrflag) {
	  if (!refresh  &&  is_string(show_types)) {
	    types := private.makeshowtypes (show_types);
	    for (tp in types) {
	      if (any (tp != private.show_types)) {
	        refresh := T;
	      }
	    }
	  }
	  if (refresh) {
	    public.show(private.dir, types);
	  }
	}
	return T;
      }
      if (have_gui()) {
	rscr := private.vscrollbarright;
	if (is_boolean (vscrollbarright)) {
	  rscr := vscrollbarright;
	}
        private.guisink := guicatalogsink(public, rscr);
	private.guisink.setparent(public);
	private.use_gui := T;
	if (wrflag) {
	  public.show(private.dir, show_types);
        }
	return T;
      }
      private.guisink := F;
      return F;
    }

    const public.screen := function() {
      wider private;
      private.init();
      if(private.use_gui) {
	private.guisink.deactivate();
	private.guisink := F;
      }
      private.use_gui := F;
      return T;
    };
    const public.cli := function() {return public.screen();}

#
# Try to reduce the file name to a canonical form
# This probably needs some more work!
    const public.canonicalize := function(file='.') {
     if (file=='') file:='.';
     cfile := dos.fullname(file);
     if (is_fail(cfile) || !is_string(cfile)) {
       return '.';
     } else {
       if (cfile == '') cfile := '/';
       return cfile;
     }
    }

    const public.whatis := function (file='.', dir='.') {
      if(!is_string(file)) {
         return throw ('Argument must be a string', origin='catalog.whatis');
      }
      if(is_string(dir) && dir!='.') {
        file := spaste(dir,'/',file);
        file ~:= s!//!/!g;
      }
      rec:=[=];
      rec.istable:=F;
      rec.date:='';
      rec.size:='0';
      rec.type:='Non-existent';
      # Expand $ and ~ (because glish does not do that).
      if (file ~ m/^\$/  ||  file ~ m/^~/) {
	  file := dos.fullname(file);
      }
      sr:=stat(file,follow=T);
      if(length(sr)==0) {
	sr:=stat(file,follow=F);
        if(length(sr)==0) {
	  return rec;
	}
      }
      rec.type:=sr.type;
      rec.size:=as_string(sr.size);
      rec.time:=sr.time.modify;

      if (is_string(sr.type)) {
	if (sr.type == 'regular') {
	  rec.type := 'Regular File';
	} else if (sr.type == 'directory') {
	  if (length(stat(spaste(file,'/table.dat'),'-f'))) {
	    ti:=tableinfo(file);
	    rec.istable:=T;
            if(!is_fail(ti)){
	       rec.type:=paste(ti.type);
	       if(rec.type=='') {
	         rec.type:='Other Table';
               }
	    } else {
	         rec.type:='Bad Table';
            }
	  } else if (length(stat(spaste(file,'/header'),'-f'))
		     && length(stat(spaste(file,'/image'),'-f'))) {
	    rec.type:='Miriad Image'; 
	  } else if (length(stat(spaste(file,'/header'),'-f'))
		     && length(stat(spaste(file,'/visdata'),'-f'))) {
	    rec.type:='Miriad Vis'; 
	  } else {
	    rec.type:='Directory';
	  }
	  return rec;
	} else {
	  rec.type:=sr.type;
	}
      }
# Is this a glish file?
      if((rec.type=='ascii') && (file~m/.g$/)) {
	rec.type:='Glish';
	return rec;
      }
# Is this a postscript file?
      if((rec.type=='ascii') && (file~m/.ps$/)) {
	rec.type:='PostScript';
	return rec;
      }
# Is this a graphics file?
      if((rec.type=='ascii' || rec.type=='Regular File') 
	 && (file~m/.(gif|tif|tiff|jpg|jpeg|ppm|xbm|xpm|bmp)$/i)) {
	rec.type:='Graphics';
	return rec;
      }
      if ((rec.type=='ascii' || rec.type=='Regular File') 
	   && (file~m/.descr$/)) {
	  tmp := file ~ s/\.descr$/\.image/;
	  if (length(stat(tmp,'-f'))) {
	      rec.type := 'Gipsy';
	      return rec;
	  }
      }
      if ((rec.type=='ascii' || rec.type=='Regular File')
	  && (file~m/.image$/)) { 
	  tmp := file ~ s/\.image$/\.descr/;
	  if (length(stat(tmp,'-f'))) {
	      rec.type := 'Gipsy';
	      return rec;
	  }
      }
# A VLA archive file looks like a binary file. The first 2 bytes must
# be zero and one. As this is not a conclusive test I also require a
# case insensitive suffix of .vla
      if ((rec.type=='Regular File') && (file~m/.vla$/i)) { 
        if (as_integer(rec.size) > 1) {
          f := open(spaste('< ',file));
          header := read(f, num=2, what='b');
          f:=F;
          if (header[1] == 0 && header[2] == 1) {
            rec.type := 'VLA archive';
          }
        }
      }
# Various ugly heuristics go here.
# Check for FITS file by trying to find /SIMPLE=T card.
      if(rec.type=='ascii') {
	f := open(spaste('< ',file));
	header := read(f, num=2880, what='c');
	f:=F;
	# Make sure it has SIMPLE=T

# The glish read function returns a string vector (with no elements),
# rather than a string when it cannot read any more characters. This
# happens for zero length files and thats what the first check in the
# following 'if' statement looks for.
	if(length(header) > 0 && header ~ m/^SIMPLE *= *T/) {
	  rec.type:='FITS';
	  return rec;
	}
      }
      return rec;
    }

    const public.whatisfull := function (file='.', dir='.') {
      wider private;
      if(!is_string(file)) {
         return throw ('Argument must be a string', origin='catalog.whatisfull');
      }
      if(is_string(dir) && dir!='.') {
        file := spaste(dir,'/',file);
        file ~:= s!//!/!g;
      }
      rec := public.whatis (file, '.');
      if (is_fail(rec)) {
	fail;
      }
      if (!has_field(rec,'time')) {
	return rec;
      }
      rec.date:=dms.timetostring(rec.time);
      if (rec.istable) {
	rec.size := '';
	if(private.tablesizeoption == 'bytes') {
	  rec.size:=as_string(dos.size(file));
        } else if(private.tablesizeoption == 'shape') {
	  if (rec.type=='Image') {
	      # Avoid restarting image client for each image by
	      # keeping the tool around and use open/close.
	    include 'image.g';
	    if (is_boolean(private.tmpimage)) {
              private.tmpimage:=image(file);
	    } else {
              private.tmpimage.open(file);
	    }
	    if (is_fail(private.tmpimage)) {
	      rec.size:='failed';
	      private.tmpimage:=F;
	    } else {
	      rec.size:=spaste(private.tmpimage.shape());
	      private.tmpimage.close();
	    }
	  } else {
	    t:=table(file,ack=F);
	    if (is_fail(t)) {
	      rec.size:='failed';
	    } else {
	      rec.size:=spaste('[',t.ncols(),',',t.nrows(),']');
	      t.close();
	    }
	  }
        }
      }
      return rec;
    }

    const public.list := function(files='.', listtypes='All', strippath=unset)
    {
      result := "";
      if (! is_boolean(strippath)) {
	strippath := len(files) <= 1;
      }
      for (name in files) {
	# It is possible to specify wildcards.
	# For the time being no wildcard can be given in possible directories.
        # Get the directory and the base name.
	dirname := name ~ s%//+%/%g;          # get single slashes
	basename := '';
	if (dirname != '/') {
	  dirname := dirname ~ s%/$%%;        # remove trailing slash
	  dir := dirname ~ s%[^/]+$%%;        # get directory part
	  if (dir != '/') {                   # not something like /usr
	    basename := dirname ~ s%.+/%%;    # get basename part
	    dirname := dir ~ s%/$%%;          # remove trailing slash
	  }
	}
	dir := dirname;
	fdir := basename;
	if (dir == '') {
	  dirname := '.';
	} else {
	  if (dir ~ m/[][*?{}]/) {
	    msg := paste('Directory part of', name,
			  'contains wildcards, which is not supported yet');
	    note(msg, priority='SEVERE', origin='os');
	    fail;
          }
	  fdir := spaste(dir,'/',basename);
        }
	# Test if basename is empty
        if (basename == ''  ||  basename == '.') {
	  names := public.dirlist (dirname, '*', listtypes, F);
        } else {
          if (basename ~ m/[][*?{}]/) {
	    # Name has wildcards, so use that as mask.
           names := public.dirlist (dirname, basename, listtypes, F);
          } else {
	    dirtype := dos.filetype(fdir);
	    if (dirtype == 'Directory') {
	      dirname := fdir;
	      names := public.dirlist (dirname, '*', listtypes, F);
	    } else if ( dirtype == 'Invalid' ) {
	      return throw ('Not a file or directory', origin='catalog.list');
	    } else {
	      names := public.dirlist (dirname, basename, listtypes, F);
            }
	  }
	}
	# Skip .. (which is first entry).
	st := 1;
	if (len(names.names) > 0  &&  names.names[1] == '..') {
	  st := 2;
	}
	if (len(names.names) >= st) {
	  if (! strippath) {
	    dirname := dos.fullname(dirname);
	    for (i in st:len(names.names)) {
	      names.names[i] := spaste (dirname,'/',names.names[i]);
	    }
	  }
	  result := [result, names.names[st:len(names.names)]];
        }
      }
      return unique(result);
    }

    const public.dirlist := function(dir='.', mask, listtypes, listattr)
    {
      wider public;
      wider private;
      if(any(to_lower(listtypes)=='<any table>')) {
        any_table := T;
      } else {
        any_table := F;
      }
      dir:=public.canonicalize(dir);
      dirtype:=dos.filetype(dir);
      if((dirtype!='Table') && (dirtype!='Directory')) {
         return throw ('Not a directory', origin='catalog.list');
      }
      # dos.dir returns a list of short names (i.e. without the
      # directory appended). It only returns the ones matching the
      # mask (i.e. filter).
      that:=sort(dos.dir(dir, mask));
      if(is_fail(that)) fail;
      nfiles := length(that);
      this := array('',nfiles+1);
      this[1] := '..';
      if(nfiles>0) {
        this[2:(nfiles+1)] := that;
      } 
      slot:=0;
      lnames:=array('',1);
      ltypes:=array('',1);
      lsizes:=array('',1);
      ldates:=array('',1);
      listables:=array(F,1);
      for (file in this) {
        class:=public.whatis(file, dir);
        if(is_fail(class)) return class;
	ok := any_table && class.istable;
	if (!ok) {
	  ok := any(listtypes=='All');
          if (!ok) {            
	    ok := any(class.type == listtypes);
	  }
        }
        if (ok) {
	  slot +:= 1;
	  lnames[slot]:=file;
	  ltypes[slot]:=class.type;
	  if (listattr) {
	    class:=public.whatisfull(file, dir);
	    listables[slot]:=class.istable;
	    lsizes[slot]:=class.size;
	    ldates[slot]:=class.date;
	  }
	}
      }
      if (listattr && private.sortbytype) {
        lnames:=sort_pair(ltypes, lnames);
        lsizes:=sort_pair(ltypes, lsizes);
        ldates:=sort_pair(ltypes, ldates);
        listables:=sort_pair(ltypes, listables);
        ltypes:=sort(ltypes);
      }
      list:=[directory=dir, count=slot, names=lnames,
	     istables=listables, types=ltypes,
	     sizes=lsizes, dates=ldates];
      return list;
    }

    const public.show := function(dir='.', show_types=unset, writestatus=T) 
    {
      wider private;
      private.init();
      dir:=public.canonicalize(dir);
      private.dir:=dir;
      types := private.makeshowtypes(show_types);
      if (len(types) > 0) {
	private.show_types := types;
      } else {
	types := private.show_types;
      }
      if (private.alwaysshowdir) {
	types[len(types)+1] := 'Directory';
      }
      wasbusy := F;
      if(private.use_gui) {
	wasbusy := private.guisink.busy(T);
	if (writestatus) {
          private.guisink.writetostatus();
          private.guisink.writetostatus('Loading...');
        }
        private.guisink.setdirectory(dir);
        private.guisink.setshowtypes(private.show_types);
      }
      list:=public.dirlist(dir, private.mask, types, T)
      if(is_fail(list)) {
	if(private.use_gui) {
	  private.guisink.busy(F, wasbusy);
        }
	fail;
      }
      if(private.use_gui) {
        private.guisink.write(list.names, list.types, list.sizes, list.dates);
	private.guisink.busy(F, wasbusy);
	if (writestatus) {
          private.guisink.writetostatus();
        }
      } else {
        private.textsink.setdirectory(list.directory);
        private.textsink.write(list.names, list.types, list.sizes, list.dates);
      }
      return T;
    }

    const public.setmask := function(mask='') {
      wider private;
      private.mask:=paste(mask);
      if(private.use_gui) {
        private.guisink.setmask(mask);
      }
      return T;
    }

    const public.getmask := function() {
      return private.mask;
    }

    const public.setconfirm := function(confirm='yes') {
      wider private;
      confirm := private.tr_confirm(confirm);
      if (is_fail(confirm)) fail;
      if (!is_string(confirm)) {
	fail "setconfirm: invalid confirm argument";
      }
      private.confirm := confirm;
      private.init();
      if(private.use_gui) {
        private.guisink.setoptions(confirm=private.confirm);
      } else {
        private.textsink.setoptions(confirm=private.confirm);
      }
      return T;
    }

    const public.getconfirm := function() {
      return private.confirm;
    }

    const public.settablesizeoption := function(tablesizeoption='shape') {
      wider private;
      if (tablesizeoption == 'shape' || tablesizeoption == 'bytes') {
	private.tablesizeoption:=tablesizeoption;
      } else {
	private.tablesizeoption:='no';
      }
      private.init();
      if(private.use_gui) {
        private.guisink.setoptions(tablesizeoption=private.tablesizeoption);
      } else {
        private.textsink.setoptions(tablesizeoption=private.tablesizeoption);
      }
      return T;
    }

    const public.gettablesizeoption := function() {
      return private.tablesizeoption;
    }

    const public.setalwaysshowdir := function(alwaysshowdir=T) {
      wider private;
      private.alwaysshowdir:=alwaysshowdir;
      private.init();
      if(private.use_gui) {
        private.guisink.setoptions(alwaysshowdir=private.alwaysshowdir);
      } else {
        private.textsink.setoptions(alwaysshowdir=private.alwaysshowdir);
      }
      return T;
    }

    const public.getalwaysshowdir := function() {
      return private.alwaysshowdir;
    }

    const public.setsortbytype := function(sortbytype=T) {
      wider private;
      private.sortbytype:=sortbytype;
      private.init();
      if(private.use_gui) {
        private.guisink.setoptions(sortbytype=private.sortbytype);
      } else {
        private.textsink.setoptions(sortbytype=private.sortbytype);
      }
      return T;
    }

    const public.getsortbytype := function() {
      return private.sortbytype;
    }

    const public.refresh := function() {
      private.init();
      return public.show(private.dir);
    }

    const public.lastdirectory := function() {return private.dir};

    const public.lastshowtypes := function() {return private.show_types};

    const public.delete:=function(files, refreshgui=T, confirm=unset)
    {
      private.init();
      if(!is_string(files)) {
         return throw ('files must be a string', origin='catalog.lastdirectory');
      }
      confirm := private.tr_confirm (confirm);
      if (is_fail(confirm)) fail;
      if (! is_string(confirm)) {
	confirm := private.confirm;
      }
      nrdel := 0;
      status := T;
      cancel := F;
      failmsg := '';
      for (name in files) {
	# It is possible to specify wildcards.
	# For the time being no wildcard can be given in possible directories.
        # Get the directory and the base name.
	dirname := name ~ s%//+%/%g;            # get single slashes
	basename := '';
	if (dirname != '/') {
	  dirname := dirname ~ s%/$%%;        # remove trailing slash
	  dir := dirname ~ s%[^/]+$%%;        # get directory part
	  if (dir != '/') {                   # not something like /usr
	    basename := dirname ~ s%.+/%%;    # get basename part
	    dirname := dir ~ s%/$%%;          # remove trailing slash
	  }
	}
	if (dirname != '') {
	  if (dirname ~ m/[][*?{}]/) {
	    msg := paste('Directory part of', name,
			  'contains wildcards, which is not supported yet');
	    note(msg, priority='SEVERE', origin='os');
	    fail;
          }
        }
	# Expand the name if it has wildcards.
	# Otherwise get the full name.
	# Expand possible ~ or $ used as single file name.
	names := basename;
	if (basename != '') {
	  if (basename ~ m/[][*?{}]/) {
            names := dos.dir (dirname, basename);
          } else if (dirname == ''  &&  basename ~ m/^[$~]/) {
	    names := dos.fullname (basename);
	  }
	}
	if (len(names) == 0) {
	  msg := paste('No matching file names found for', name);
	  note(msg, priority='SEVERE', origin='catalog');
	  failmsg := spaste(failmsg, msg, '; ');
          status := F;
        } else {
          for (file in names) {
	    if (dirname != ''  &&  dirname != '.') {
              file := spaste(dirname, '/', file);
            }
	    what:= public.whatis(file);
            if(is_fail(what)) return what;
            doit:=T;
	    if (what.type == 'Non-existent') {
	      doit:=F;
	      msg := paste('File', name, 'does not exist');
	      note(msg, priority='SEVERE', origin='catalog');
	      failmsg := spaste(failmsg, msg, '; ');
	      status := F;
	    } else {
              if (confirm == 'yes'  ||
                       (confirm=='directory' && what.type=='Directory')) {
	        if(private.use_gui) {
		  doit:=private.guisink.query(spaste('Delete (', what.type,
						    ') ', file, '?'));
	        } else {
		  doit:=private.textsink.query(spaste('Delete (', what.type,
						      ') ', file, '?'));
	        }
                if(doit=='cancel') {
                  cancel:=T;
                  break;
                }
                doit := (doit=='yes');
	      }
	    }
            if(doit) {
	      if(what.istable) {
		# If a table is not correct, it fails to open.
		# In that case it'll be tried to delete it by dos.remove.
		t:=table(file,readonly=F,ack=F);
		if (! is_fail(t)) {
		  doit:=F;
		  t.close();
		  result := tabledelete(file);
		  if (is_fail(result)) {
		    note(paste('Error deleting', file, result::message),
			 priority='SEVERE',origin='catalog');
		    failmsg := spaste(failmsg, result::message, '; ');
                    status:=F;
		  } else {
		    nrdel +:= 1;
		  }
		}
	      }
	      if (doit) {
	        result:=dos.remove(file);
	        if(is_fail(result)) {
	          note(paste('Error deleting', file, result::message),
		       priority='SEVERE',origin='catalog');
		  failmsg := spaste(failmsg, result::message, '; ');
                  status := F;
	        } else {
		  nrdel +:= 1;
                }
              }
	    }
	  }
	}
	if (cancel) break;
      }
      if(refreshgui && private.use_gui) {
        private.guisink.showdir();
      }
      if (!status) {
	fail failmsg;
      }
      return nrdel;
    }

    private.copy:=function(file, newfile, operation='copy', confirm=unset)
    {
      wider public, private;
      private.init();
      if(!is_string(file)) {
         return throw ('file must be a string', origin='catalog.copy');
      }
      if(!is_string(newfile)) {
         return throw ('newfile must be a string', origin='catalog.copy');
      }
      confirm := private.tr_confirm (confirm);
      if (is_fail(confirm)) fail;
      if (! is_string(confirm)) {
	confirm := private.confirm;
      }
      # Do the multiple file case first
      if(len(file)>1) {
	note('Cannot handle a', operation, 'of multiple files yet ',
	     priority='SEVERE',origin='catalog');
#        newwhat := public.whatis(newfile);
#        if(is_fail(newwhat) || newwhat.type!='Directory') {
#	  note('Cannot', operation, 'more than one file to a single file name',
#	       priority='SEVERE',origin='catalog');
#          return F;
#	} else {
#	  if(is_fail(dos[operation](file, newfile)) || 
#	     length(stat(newfile))) {
#	    fail paste('Failed to', operation, file, 'to', newfile);
#	  }
#	  return T;
#	}
      } else {
	doit:=F;
        if ((confirm == 'yes'  ||
            (confirm=='directory' && what.type=='Directory'))  &&
	       dos.fileexists(newfile)) {
	  if(private.use_gui) {
	    doit:=private.guisink.query(paste('Overwrite ', newfile, '?'));
	  } else {
	    doit:=private.textsink.query(paste('Overwrite ', newfile, '?'));
	  }
	  if(doit=='cancel') return F;
	  doit := (doit=='yes');
	} else {
	  doit := T;
	}
	if(doit) {
	  note(paste(operation, file, 'to ', newfile),
	       priority='NORMAL',origin='catalog');
	  if(is_fail(dos[operation](file, newfile, doit)) || 
            length(stat(public.canonicalize(newfile)))==0) {
	    msg := paste('Failed to ', operation, file, 'to', newfile);
	    return throw (msg, origin='catalog.copy');
	  }
	  return T;
	}
      }
      if(private.use_gui) {
        private.guisink.showdir();
      }
      return F;
    }

    const public.copy:=function(file, newfile, confirm=unset)
    {
      return private.copy(file, newfile, confirm=confirm);
    }

    const public.rename:=function(file, newfile, confirm=unset)
    {
      return private.copy(file, newfile, operation='move', confirm=confirm);
    }

    const public.summary:=function(file) {
      if(!is_string(file)) {
         return throw ('file must be a string', origin='catalog.summary');
      }
      file:=public.canonicalize(file);
      what:=public.whatis(file)
      if(is_fail(what)) return what;
      if(what.type=='Image') {
        include 'image.g';
	if (is_boolean(private.tmpimage)) {
	  private.tmpimage:=image(file);
        } else {
	  private.tmpimage.open(file);
        }
        if(!is_record(private.tmpimage)) {
           msg := spaste('Cannot construct an image from ', file);
           return throw (msg, origin='catalog.summary');
        }
        private.tmpimage.summary();
	private.tmpimage.close();
        return T;
      }
      if(what.type=='Measurement Set') {
        include 'ms.g';
        m:=ms(file);
        if(!is_record(m)) {
           msg := spaste('Cannot construct an ms from ', file);
           return throw (msg, origin='catalog.summary');
        }
        m.summary(verbose=T);
	m.close();
        return T;
      }
      if(what.istable) {
        t := table(file,ack=F);
	r := t.summary();
	t.close();
        return r;
      }
      note (spaste(file,':  ', what));
      return T;
    }

    const public.create:=function(file, type='ascii', refreshgui=T) {
      if(!is_string(file)) {
         return throw ('file must be a string', origin='catalog.create');
      }
      if(!is_string(type)) {
         return throw ('type must be a string', origin='catalog.create');
      }
      status:=T;
      if(type=='Ascii' || type=='ascii') {
        status := dos.edit (file, private.edit.ascii);
      } else if(type=='Glish' || type=='glish') {
        status := dos.edit (file, private.edit.Glish);
      } else if(type=='Directory') {
        result:=dos.mkdir (file);
        if(is_fail(result)) {
           msg := spaste('Create of directory ', file, ' failed');
           return throw (msg, origin='catalog.create');
        }
      } else {
        msg := spaste('Cannot create type ', type);
        return throw (msg, origin='catalog.create');
      }
      if (refreshgui && private.use_gui) {
        private.guisink.showdir();
      }
    }

    const public.edit:=function(file) {
      wider private;
      private.init();
      if(!is_string(file)) {
         return throw ('file must be a string', origin='catalog.edit');
      }
      file:=public.canonicalize(file);
      what:=public.whatis(file)
      if(what.istable) {
        if(have_gui()) {
	    include 'tablebrowser.g';
	    return tablebrowser(file,readonly=F);
        }
        return throw('No GUI: cannot edit tables', origin='catalog.edit');
      }
      if(what.type=='ascii') {
        return dos.edit (file, private.edit.ascii);
      }
      if(what.type=='Glish') {
        return dos.edit (file, private.edit.Glish);
      }
      # Plot file
      if(what.type=='Plot file') {
        if(have_gui()) {
	  ok := include 'pgplotter.g';
          if(ok) {
	    t:=pgplotter(file);
	    if(is_record(t)) return T;
            msg := spaste ('Cannot plot ', file, ' : not a Plot file?');
            return throw (msg, origin='catalog.edit');        
	  } else {
	    return throw ('Include pgplotter.g failed', origin='catalog.edit');
	  }
        }
        return throw ('No gui: cannot edit plot file', origin='catalog.edit');
      }
      return throw (spaste('Cannot edit ', file), origin='catalog.edit');
    }

    const public.execute:=function(file) {
      private.init();
      if(!is_string(file)) {
         return throw ('file must be a string', origin='catalog.execute');
      }
      file:=public.canonicalize(file);
      what:=public.whatis(file)
      if(what.type=='Glish') {
        result:=eval(spaste('include \'', file, '\''));
        if(!result) {
          msg := spaste('Include of ', file, ' failed');
          return throw (msg, origin='catalog.execute');
        }
        return T;
      }
      msg := spaste('Cannot execute ', file);
      return throw (msg, origin='catalog.execute');
    }

    const public.availabletypes := function()
    {
	return ['Image',
		'Measurement Set',
		'Calibration',
		'Log message',
		'Other Table',
		'FITS',
		'Miriad Image',
		'Miriad Vis',
		'Gipsy',
		'Plot file',
		'Postscript',
		'Graphics',
		'Glish',
		'ascii',
		'Regular File',
		'Directory'];
    }

    const public.view:=function(file) {
      wider private;
      if(!is_string(file)) {
         return throw ('file must be a string', origin='catalog.view');
      }
      file:=public.canonicalize(file);
      what:=public.whatis(file)
      if(is_fail(what)) fail;
      # Directory
      if(what.type=='Directory') {
	  print public.show(file);
          return T;
      }
      # Image
      if(what.type=='Image') {
        if(have_gui()) {
          if (private.view.image == '') {
	    return throw ('Viewer for image files is unset in aipsrc');
	  }
          if(private.view.image=='aipsview') {
	    note(paste('Using aipsview to display image', file));
            include 'aipsview.g';
            if (!serverexists('dd', 'display', dd)) {
               return throw('The display server "dd" is not running',
                            origin='catalog.view');
            }
            dd.image(file);
	  } else if(private.view.image=='defaultviewer') {
	    note(paste('Using default viewer to display image', file));
            include 'viewer.g';
            if (!serverexists('dv', 'viewer', dv)) {
               return throw('The viewer server "dv" is not running',
                            origin='catalog.view');
            }
            idd := dv.loaddata(file, 'raster');
            if (is_fail(idd)) fail;
            idp := dv.newdisplaypanel();
            if (is_fail(idp)) fail;
            ok := idp.register(idd);
            if (is_fail(ok)) fail;
#
# Make sure that when displaypanel is done that the display
# data is destroyed too so that the image is not locked
#
            whenever idp->done do {
               idd.done();
            }
	  } else {
	    note(paste('Using image.view to display image', file));
            include 'image.g';
	    nr := length(private.images)+1;
            private.images[nr]:=image(file);
            if (is_fail(private.images[nr])) {
              return throw(paste('Cannot open image', file,
				 'for viewing'), origin='catalog.view');
	    }
            private.images[nr].view(raster=T, hasdismiss=F);  
            private.images[nr].unlock();
#
# We must not leave the image  tool floating about because
# it will lock up the image.  SO when user kills the display,
# do in the image tool as well.  This is also why we don't give them
# the dismiss button on the display (it would leave image locked)
#
            whenever private.images[nr]->viewerdone do {
               private.images[nr].done();
            }
	  }
          return T;
        }
        return throw('No gui: cannot view Images', origin='catalog.view');
      }

      # Postscript
      if(what.type=='PostScript') {
        if(have_gui()) {
          if (private.view.PostScript == '') {
	    return throw ('Viewer for postscript files is unset in aipsrc');
	  }
          vwagent := shell (paste(private.view.PostScript, file), async=T);
	  wider private;
	  nr := len(private.asyncs);
          if (nr>0) {
	    for (i in 1:nr) {
	      if (private.asyncs[i].active == 0) {
	        private.asyncs[i] := vwagent;
                return T;
              }
            }
          }
	  private.asyncs[nr+1] := vwagent;
          return T;
        }
        return throw ('No gui: cannot view postscript files', origin='catalog.view');
      }

      # Graphics
      if(what.type=='Graphics') {
        if(have_gui()) {
          if (private.view.Graphics == '') {
	    return throw ('Viewer for graphics files is unset in aipsrc');
	  }
          vwagent := shell (paste(private.view.Graphics, file), async=T);
	  wider private;
	  nr := len(private.asyncs);
          if (nr>0) {
	    for (i in 1:nr) {
	      if (private.asyncs[i].active == 0) {
	        private.asyncs[i] := vwagent;
                return T;
              }
            }
          }
	  private.asyncs[nr+1] := vwagent;
          return T;
        }
        return throw ('No gui: cannot view graphics files', origin='catalog.view');
      }

      # Plot file
      if(what.type=='Plot file') {
        if(have_gui()) {
	  ok := include 'pgplotter.g';
          if(ok) {
	    t:=pgplotter(file);
            if(is_record(t)) return T;
            msg := spaste('Cannot plot ', file, ' : not a Plot file?');
    	    return throw (msg, origin='catalog.view');
	  } else {
	    return throw ('Include pgplotter.g failed', origin='catalog.view');
	  }
        }
        fail 'No gui: cannot plot file';
      }

      # Glish
      if(what.type=='Glish') {
        if(have_gui() && private.view.Glish != 'text') {
	  if (!is_fail (dos.edit (file, private.view.Glish))) {
	    return T;
	  }
        }
	print private.less(file);
	return T;
      }

      # Ascii
      if(what.type=='ascii') {
        if(have_gui() && private.view.ascii != 'text') {
	  if (!is_fail (dos.edit (file, private.view.ascii))) {
	    return T;
	  }
	}
	print private.less(file);
	return T;
      }

      # FITS
      if(what.type=='FITS') {
	f := open(spaste('< ',file));
	header := read(f, num=2880, what='c');
	f:=F;
        print header;
        return T;
      }

      # Table
      if(what.istable) {
        if(have_gui()) {
	    include 'tablebrowser.g';
	    return tablebrowser(file);
        }
        fail 'No GUI: cannot view tables';
      }

      # Nothing worked!
      msg := spaste('Cannot view ', what.type, ' files');
      return throw (msg, origin='catalog.view');
    }

    const public.tool:=function(file) {
      wider private;
      if(!is_string(file)) {
         return throw ('file must be a string', origin='catalog.view');
      }
      file:=public.canonicalize(file);
      what:=public.whatis(file)
      if(is_fail(what)) fail;
      # Directory
      if(what.istable) {
	include 'toolmanager.g';
	return tm.show(file);
      }
      # Nothing worked!
      msg := spaste('Cannot make tool from ', what.type, ' files');
      return throw (msg, origin='catalog.tool');
    }

    private.makeshowtypes := function(show_types)
    {
      types := "";
      if (is_string(show_types)) {
	for (tp in show_types) {
	  if (strlen(tp) > 0  &&  tp !~ m/^ *$/) {
	    types[len(types) + 1] := tp;
	  }
        }
      }
      return types;
    }

    # Only init when first called
    private.init := function() {   
      if(!private.initialized) {
	wider private;
        include 'catalogsink.g';
	private.textsink := textcatalogsink();
	private.textsink.setoptions(confirm=private.confirm,
				    tablesizeoption=private.tablesizeoption,
				    alwaysshowdir=private.alwaysshowdir,
				    sortbytype=private.sortbytype);
	if (private.use_gui) {
	  private.guisink  := guicatalogsink(public, private.vscrollbarright);
	  if (is_fail(private.guisink)) fail;
	  private.guisink.setparent(public);
	  private.guisink.setoptions(confirm=private.confirm,
				     tablesizeoption=private.tablesizeoption,
				     alwaysshowdir=private.alwaysshowdir,
				     sortbytype=private.sortbytype);
	} else {
	  private.guisink := F;
	}
	private.initialized := T;
      }
    }

    const public.type := function() {
        return 'catalog';
    }

    const public.done := function() {
      wider public, private;
      for (i in ind(private.images)) {
#
# These internal images may have already been
# destroyed by the user killing the viewer display
# (See function view)
#
	include 'image.g';
	if (is_image(private.images[i])) private.images[i].done();
      }
      if (private.use_gui) {
	private.guisink.deactivate();
	private.guisink := F;
      }
      val private := F;
      val public := F;
      return T;
    }

    const public.select := function() {
      wider private;
      if (private.use_gui) {
        private.guisink.select();
	return ref private.guisink;
      } else {
	return ref private.textsink;
      }
    }

    const public.dismiss := function() {
      wider private;
      if (private.use_gui) {
        private.guisink.deactivate();
      }
      return T;
    }

    const public.setselectcallback := function (fun) {
      wider private;
      if(is_function(fun)) {
	if (private.use_gui) {
	  private.guisink.select();
	}
        private.selectcallback := ref fun;
      } else {
	if (private.use_gui) {
	  private.guisink.noselect();
	}
	private.selectcallback := F;
      }
      return T;
    }

    const public.selectcallback := function () {
      wider private;
      return ref private.selectcallback;
    }

    # Find initial values from aipsrc file.

    arc := aipsrc();

    arc.find (private.confirm, 'catalog.confirm', 'yes');
    private.confirm := to_lower(private.confirm);
    if (private.confirm == 't') {
      private.confirm := 'yes';
    } else if (private.confirm == 'f') {
      private.confirm := 'no';
    }
    arc.find (private.tablesizeoption, 'catalog.tablesizeoption', 'no');
    arc.findbool (private.alwaysshowdir, 'catalog.alwaysshowdir', T);
    arc.findbool (private.sortbytype, 'catalog.sortbytype', F);

    private.vscrollbarright := T;
    scr := '';
    arc.find (scr, 'catalog.vscrollbar', 'right');
    if (scr == 'left') {
      private.vscrollbarright := F;
    }
    arc.find (private.view.PostScript, 'catalog.view.PostScript', 'ghostview');
    arc.find (private.view.Graphics, 'catalog.view.Graphics', 'xv');
#
    arc.find (private.view.image, 'catalog.view.image', 'imageview');
    if(private.view.image!='' && private.view.image!='aipsview' && private.view.image!='defaultviewer') {
      private.view.image := 'imageview';
    }
#
    arc.find (private.edit.ascii, 'catalog.edit.ascii', '');
    arc.find (private.edit.Glish, 'catalog.edit.Glish', private.edit.ascii);
    arc.find (private.view.ascii, 'catalog.view.ascii', private.edit.ascii);
    arc.find (private.view.Glish, 'catalog.view.Glish', private.edit.Glish);
    arc.done();

    return ref public;
}


# Make the catalog
const dc:=catalog();

# Make defaultcatalog a reference for dc
const defaultcatalog:=ref dc;
note('defaultcatalog (dc) ready', priority='NORMAL', origin='catalog');

#
# Start up Gui if defined in .aipsrc or globally set
#
# Logics to get gui:
#	global_use_gui defined && numeric && T && have_gui()    else
#	aipsrc variable set to gui && have_gui()
  if (is_defined("global_use_gui") && is_numeric(global_use_gui)) {
    if (global_use_gui) dc.gui();
  } else if (drc.find(what,"catalog.default") && what == 'gui') {
    dc.gui();
  }

# Add defaultquanta to the GUI if necessary
if (any(symbol_names(is_record)=='objrepository') &&
    has_field(objrepository, 'notice')) {
	objrepository.notice('defaultcatalog', 'catalog');
};

# global functions
cat:=ref dc.show;

icat:=function(dir='.') {return dc.show(dir,'Image');};
ccat:=function(dir='.') {return dc.show(dir,'Calibration');};
dcat:=function(dir='.') {return dc.show(dir,'Directory');};
mscat:=function(dir='.') {return dc.show(dir,'Measurement Set');};
fcat:=function(dir='.') {return dc.show(dir,'FITS');};
gcat:=function(dir='.') {return dc.show(dir,'Glish');};
tcat:=function(dir='.') {return dc.show(dir,'<Any Table>');};
