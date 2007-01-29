# os.g: OS commands
#
#   Copyright (C) 1999,2000,2001,2002,2003
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
#   $Id: os.g,v 19.2 2004/08/25 01:34:51 cvsmgr Exp $
#

# See tos.g for the tos() test function

pragma include once;

include 'servers.g' 
include 'note.g';


const os := function (host='', forcenewserver=F)
{
    public := [=];
    public::print.limit := 1;	
    private := [=];

    private.agent := defaultservers.activate('misc', host, forcenewserver);
    private.id := defaultservers.create(private.agent, 'os');
    private.asyncs := [=];

#------------------------------------------------------------------------------
    const public.type := function ()
    {
       return 'os';
    }
#------------------------------------------------------------------------------
    private.isvalidpathnameRec := [_method = 'isvalidpathname',
				   _sequence=private.id._sequence];
    const public.isvalidpathname := function (const pathname)
    {
	wider private;
	private.isvalidpathnameRec.pathname := pathname;
	return defaultservers.run(private.agent, private.isvalidpathnameRec);
    }
#------------------------------------------------------------------------------
    private.fileexistsRec := [_method = 'fileexists',
			      _sequence=private.id._sequence];
    const public.fileexists := function (const file, const follow=T)
    {
	wider private;
	private.fileexistsRec.pathname := file;
	private.fileexistsRec.follow := follow;
	return defaultservers.run(private.agent, private.fileexistsRec);
    }
#------------------------------------------------------------------------------
    private.filetypeRec := [_method = 'filetype',
			    _sequence=private.id._sequence];
    const public.filetype := function (const filename, const follow=T)
    {
	wider private;
	private.filetypeRec.pathname := filename;
	private.filetypeRec.follow := follow;
	return defaultservers.run(private.agent, private.filetypeRec);
    }
#------------------------------------------------------------------------------
    private.dirRec := [_method = 'dir',
		       _sequence=private.id._sequence];
    const public.dir := function (const directoryname='.',
				  const pattern='', const types='',
				  const all=F, const follow=T)
    {
	wider private;
	private.dirRec.directory := directoryname;
	private.dirRec.pattern := pattern;
	private.dirRec.types := types;
	private.dirRec.all := all;
	private.dirRec.follow := follow;
	return defaultservers.run(private.agent, private.dirRec);
    }
#------------------------------------------------------------------------------
    private.mkdirRec := [_method = 'mkdir',
			 _sequence=private.id._sequence];
    const public.mkdir := function (const directoryname, const makeparent=F)
    {
	wider private;
	private.mkdirRec.directory := directoryname;
	private.mkdirRec.makeparent := makeparent;
	return defaultservers.run(private.agent, private.mkdirRec);
    }
#------------------------------------------------------------------------------
    private.fullnameRec := [_method = 'fullname',
			   _sequence=private.id._sequence];
    const public.fullname := function (const pathname='.')
    {
	wider private;
	private.fullnameRec.pathname := pathname;
	return defaultservers.run(private.agent, private.fullnameRec);
    }
#------------------------------------------------------------------------------
    private.dirnameRec := [_method = 'dirname',
			     _sequence=private.id._sequence];
    const public.dirname := function (const pathname='.')
    {  
	wider private;
	private.dirnameRec.pathname := pathname;
	return defaultservers.run(private.agent, private.dirnameRec);
    }
#------------------------------------------------------------------------------
    private.basenameRec := [_method = 'basename',
			     _sequence=private.id._sequence];
    const public.basename := function (const pathname='.')
    {  
	wider private;
	private.basenameRec.pathname := pathname;
	return defaultservers.run(private.agent, private.basenameRec);
    }
#------------------------------------------------------------------------------
    private.filetimeRec := [_method = 'filetime',
			    _sequence=private.id._sequence];
    const public.filetime := function (const pathname='.',
				       const whichtime=2, const follow=T)
    {  
	wider private;
	private.filetimeRec.pathname := pathname;
	private.filetimeRec.whichtime := whichtime;
	private.filetimeRec.follow := follow;
	return defaultservers.run(private.agent, private.filetimeRec);
    }
#------------------------------------------------------------------------------
    private.filetimestringRec := [_method = 'filetimestring',
				  _sequence=private.id._sequence];
    const public.filetimestring := function (const pathname='.',
					     const whichtime=2, const follow=T)
    {  
	wider private;
	private.filetimestringRec.pathname := pathname;
	private.filetimestringRec.whichtime := whichtime;
	private.filetimestringRec.follow := follow;
	return defaultservers.run(private.agent, private.filetimestringRec);
    }
#------------------------------------------------------------------------------
    private.sizeRec := [_method = 'size',
			_sequence=private.id._sequence];
    const public.size := function (const pathname='.', const follow=T)
    {  
	wider private;
	private.sizeRec.pathname := pathname;
	private.sizeRec.follow := follow;
	return defaultservers.run(private.agent, private.sizeRec);
    }
#------------------------------------------------------------------------------
    private.freespaceRec := [_method = 'freespace',
			     _sequence=private.id._sequence];
    const public.freespace := function (const pathname='.', const follow=T)
    {  
	wider private;
	private.freespaceRec.pathname := pathname;
	private.freespaceRec.follow := follow;
	return defaultservers.run(private.agent, private.freespaceRec);
    }
#------------------------------------------------------------------------------
    private.copyRec := [_method = 'copy',
			_sequence=private.id._sequence];
    const public.copy := function (const source, const target,
				   const overwrite=F, const follow=T)
    {  
	wider private;
	private.copyRec.target := target;
	private.copyRec.source := source;
	private.copyRec.overwrite := overwrite;
	private.copyRec.follow := follow;
	return defaultservers.run(private.agent, private.copyRec);
    }
#------------------------------------------------------------------------------
    private.moveRec := [_method = 'move',
			_sequence=private.id._sequence];
    const public.move := function (const source, const target,
				   const overwrite=F, const follow=T)
    {  
	wider private;
	private.moveRec.target := target;
	private.moveRec.source := source;
	private.moveRec.overwrite := overwrite;
	private.moveRec.follow := follow;
	return defaultservers.run(private.agent, private.moveRec);
    }
#------------------------------------------------------------------------------
    private.removeRec := [_method = 'remove',
			  _sequence=private.id._sequence];
    const public.remove := function (const pathname, const recursive=T,
				     const mustexist=T, const follow=T)
    {  
	wider private;

        # Fail if the pathname is empty as bad things can happen or if it's . or ..

        if(strlen(pathname) == 0 || 
           pathname == '.' || pathname == '..' ||
           pathname == './' || pathname == '../' ||
           len(split(pathname)) == 0 ){
           msg := 'Blank name, current or parent directory, deletion not allowed.';
	   note(msg, priority='SEVERE', origin='os');
           fail;
        }
	# It is possible to specify wildcards.
	# For the time being no wildcard can be given in possible directories.
        # Get the directory and the base name.
	dirname := pathname ~ s%//+%/%g;        # get single slashes
	basename := '';
	if (dirname != '/') {
	    dirname := dirname ~ s%/$%%;        # remove trailing slash
	    basename := dirname ~ s%.*/%%;      # get basename part
	    dirname := dirname ~ s%[^/]+$%%;    # get directory part
	}
	if (dirname == '') {
	  dirname := './';
        } else {
	  if (dirname ~ m/[][*?{}]/) {
	    msg := paste('Directory part of', pathname,
			  'contains wildcards, which is not supported yet');
	    note(msg, priority='SEVERE', origin='os');
	    fail;
          }
        }
	# Expand the name if it has wildcards.
	# Otherwise get the full name.
        names := basename;
        if (pathname~m/[][*?{}]/) {
          names1 := public.dir (dirname, basename);
	  if (is_fail(names1)) {
            note(spaste("'", pathname, "' is used as a regular file name"),
		 priority='WARNING', origin='os');
          } else {
            names := names1;
	  }
	}
	if (len(names) == 0) {
	  if (mustexist) {
	    msg := spaste("No matching file names found for '", pathname, "'");
	    note(msg, priority='SEVERE', origin='os');
	    fail;
	  }
	  return T;
        }
	for (i in 1:len(names)) {
	  names[i] := spaste(dirname, names[i]);
        }
	private.removeRec.pathname  := names;
	private.removeRec.recursive := recursive;
	private.removeRec.mustexist := mustexist;
	private.removeRec.follow := follow;
	return defaultservers.run(private.agent, private.removeRec);
    }
#------------------------------------------------------------------------------
    private.lockinfoRec := [_method = 'lockinfo',
			    _sequence=private.id._sequence];
    const public.lockinfo := function (const tablename)
    {  
	wider private;
	private.lockinfoRec.tablename := tablename;
	return defaultservers.run(private.agent, private.lockinfoRec);
    }
#------------------------------------------------------------------------------
    const public.showtableuse := function (const tablename)
    {  
	wider private;
	res := public.lockinfo (tablename);
	if (is_fail(res)) {
	    return F;
	}
	perm := '';
	if (res[3] == 1) {
	    perm := 'permanently ';
	}
	if (res[1] == 1) {
	    note (spaste ('Table ', tablename,
			 ' is opened (but not locked) in process ', res[2]));
	} else if (res[1] == 2) {
	    note (spaste ('Table ', tablename,
			 ' is ', perm, ' read-locked in process ', res[2]));
	} else if (res[1] == 3) {
	    note (spaste ('Table ', tablename,
			 ' is ', perm, 'write-locked in process ', res[2]));
	} else {
	    note (spaste ('Table ', tablename,
			 ' is not used in another process'));
	}
	return T;
    }
#------------------------------------------------------------------------------
      # Start an edit session (asynchronously) for a file.
      # If no editor is given, the one defined in the environment
      # variable EDITOR is used. If still undefined, emacs is used.
    const public.edit := function (const file, editor='emacs')
    {
        if (!have_gui()) {
	  fail 'Cannot start editor in a non-gui environment';
        }
        if (editor == '') {
          if (has_field (environ, 'EDITOR')) {
            editor := environ.EDITOR;
          }
          if (editor == '') {
            editor := 'emacs'
          }
        }
        edagent := shell (paste(editor, file), async=T);
	wider private;
	inx := 0;
	nr := len(private.asyncs);
        if (nr>0) {
	  for (i in 1:nr) {
	    if (private.asyncs[i].active == 0) {
	      inx := i;
              break;
            }
          }
        }
	if (inx == 0) {
	  inx := nr+1;
        }
	private.asyncs[inx] := edagent;
	whenever private.asyncs[inx]->stdout do {
	  throw ('Cannot start editor; probably it needs a tty.\n Try setting editor in .aipsrc to xterm -e vi or emacs');
	  private.asyncs[inx]->terminate();
	  deactivate;
	}
	whenever private.asyncs[inx]->stderr do {
	  throw (spaste('Cannot start editor; ',$value,'\n Try setting editor in .aipsrc to xterm -e vi or emacs'));
	  private.asyncs[inx]->terminate();
	  deactivate;
	}
        return T;
    }
#------------------------------------------------------------------------------
      # interface to the mail system
      # kludged for now using shell.
    const public.mail := function (const message, const recipient,
                                   sender=F, subject='', cc='', bcc='')
    {
        whatToSend := '';
	if (is_boolean(sender)) {
            whatToSend := ref message;
	} else {
	    if (sender != '') {
		whatToSend := paste('Reply-To:', sender);
	    }
	    whatToSend := paste(whatToSend, '\nTo:',
				paste(recipient,sep=','));
	    if (cc != '') {
		whatToSend := paste(whatToSend, '\nCc:',
				    paste(cc,sep=','));
	    }
	    whatToSend := spaste(whatToSend, '\nSubject: ', subject);
	    whatToSend := spaste(whatToSend, '\nDescription: \n',
				 message, '\n');
        }
        tmpFile := spaste('/tmp/mailmessage.',sender);
        fp := open(paste('>', tmpFile));
        if (is_fail(fp)){
            note (paste('Failed to open file:', tmpFile), 'ERROR');
            fail;
        } else {
            write (fp, whatToSend);
	    fp := 0;                # close the file
               # First try mailer defined by sneeze logmailer (default mailx).
	    include 'aipsrc.g'
	    local mailer;
	    drc.find (mailer, "os.mailer", "mailx");
            include 'sh.g'
            mysh := sh();
	    a := mysh.command(paste(mailer, '-s \"', subject, '\"',
				    recipient, cc, bcc, '<', tmpFile));
               # Then try just mail
            if(a.status != 0){
              a := mysh.command (paste('mail', recipient, cc, bcc, '<', tmpFile));
            }
	    public.remove (tmpFile, F, F);
	    if (a.status != 0) {
                 # Give up 
	        throw (paste('Failed to send mail to', recipient));
	    }
        }
        return T;
    }
#------------------------------------------------------------------------------
# Unix-like ls command, alphabetized and collimated
# J Braatz - 15Jul02

    const public.ls := function(dir='.') {
     maximum := 0
     flds := sort(shell(paste('ls',dir)))
     maximum := max(strlen(flds))+1
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

#------------------------------------------------------------------------------

    const public.done := function() {
	wider private, public;
	val private := F;
	val public := F;
	return T;
    }

    return ref public;
}

const defaultos:=os();
const dos:=ref defaultos;

note('defaultos (dos) ready', priority='NORMAL', origin='os');
