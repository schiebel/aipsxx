# ftp.g: ftp files
#
#   Copyright (C) 1996,1997,1998,1999,2000
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
#   $Id: ftp.g,v 19.2 2004/08/25 02:08:31 cvsmgr Exp $
#

pragma include once

include 'note.g';
include 'unset.g';

const ftp := function(host='aips2.nrao.edu', user='anonymous', pass=unset,
		      dir='pub', command='ftp -n -v -i',
		      prompt='ftp>', verbose=T) {

  include 'os.g';
  include 'sh.g';

  public := [=];
  private := [=];

  private.verbose := verbose;

  private.host := host;
  private.user := user;
  if(is_string(pass)) {
    private.pass := pass;
  }
  else {
    private.pass := shell('echo ${USER}@`domainname -a`');
  }
  private.dir  := dir;
  private.command := command;
  private.prompt := prompt;

  private.sh := shell('exec sh', async=T);
  listener := subsequence() {
    wider private;
    whenever private.sh->* do {
      if($name=='stdout') {
	if($value==private.prompt) {
	  self->ready();
	}
	else if($value~m/^200/) {
	  if(private.verbose) note('Binary mode');
	  self->ready();
	}
	else if($value~m/^220 FTP server ready/) {
	  if(private.verbose) note('FTP server ready');
	  self->ready();
	}
	else if($value~m/^331/) {
          if(private.verbose) note('Login ok, send password');
	  self->ready();
	}
	else if($value~m/^230 Guest login ok/) {
	  if(private.verbose) note('Guest login complete');
	  self->ready();
	}
	else if($value~m/^230 User/) {
	  if(private.verbose) note('User login complete');
	  self->ready();
	} 
        else if($value~m/^250 CWD command/) {
	  if(private.verbose) note('cd successful');
	  self->ready();
	}
	else if($value~m/^226 Transfer complete/) {
	  if(private.verbose) note('transfer complete');
	  self->ready();
	}
	else if($value~m/^221 Goodbye/) {
	  if(private.verbose) note('Goodbye');
	  self->ready();
	}
	else {
	  if(private.verbose) note('ftp out:   ', $value);
	}
      }
      else if($name=='stderr') {
	note('ftp error: ', $value);
	self->error($value);
      }
    }
  }
  private.listener := listener();
  
  const private.process := function(cmds) {
    wider private;
    for (cmd in cmds) {
      if(private.verbose) {
	note('ftp in:    ', cmd);
      }
      private.sh->stdin(cmd);
      await private.listener->ready, private.listener->error;
      if($name!='ready') {
	return F;
      }
    }
    return T;
  }

  const public.connect := function() {
    wider private;
    cmds := '';
    cmds[1] := paste(private.command, private.host);
    cmds[2] := paste('quote user', private.user);
    cmds[3] := paste('quote pass', private.pass);
    if(private.process(cmds)) {
      note('Connected to ', private.host);
      return T;
    }
    else {
      note('Failed to connect to ', private.host);
      return F;
    }
  }

  const public.disconnect := function() {
    wider private;
    cmd := 'quit';
    return private.process(cmd);
  }

  const public.binary := function() {
    wider private;
    cmd := 'binary';
    return private.process(cmd);
  }

  const public.ascii := function() {
    wider private;
    cmd := 'ascii';
    return private.process(cmd);
  }

  const public.get := function(file) {
    wider private;
    if (dos.fileexists(file)) {
      dos.remove(paste("rm", file), mustexist=F);
    };
    cmd := paste('get ', file);
    if (private.process(cmd)&&!dos.fileexists(file)) {
      note(paste('Did not obtain', file), priority='SEVERE');
      return F;
    };
    note(paste('Obtained', file, 'from', private.host), priority='NORMAL');
    return T;
  };

  const public.send := function(file) {
    wider private;
    if (!dos.fileexists(file)) {
      note(paste(file, 'does not exist'), priority='SEVERE');
      return F;
    };
    cmd := paste('send ', file);
    if (private.process(cmd)) {
      note(paste('Could not send', file), priority='SEVERE');
      return F;
    };
    note(paste('Sent', file, 'to', private.host), priority='NORMAL');
    return T;
  };

  const public.cd := function(dir) {
    wider private;
    cmd := paste('cd', dir);
    if(private.process(cmd)) {
      private.dir := dir;
      return T;
    }
    else {
      return F;
    }
  }

  const public.list := function() {
    wider private;
    cmd := 'ls';
    return private.process(cmd);
  };

  const public.done := function() {
    wider private;
    private.sh->EOF();
    return T;
  }

  public.type := function() {
    return 'ftp';
  }

  return public;
}

ftptest := function(verbose=T) {
  myftp := ftp(verbose=verbose);
  result := myftp.connect()&&
      myftp.cd('linecount')&&
	  myftp.get('source_lines')&&
	      myftp.disconnect()&&
		  myftp.done();
  return result;
}
