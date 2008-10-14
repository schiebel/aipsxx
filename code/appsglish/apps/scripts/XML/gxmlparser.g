# gxmlparser: utility for parsing XML
# Copyright (C) 2002
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
# $Id: gxmlparser.g,v 19.2 2004/08/25 02:22:52 cvsmgr Exp $
pragma include once
include 'gxml.g';

const gxmlparser := function(preserve=F) {
    xml := gxml.doc(doxmlproc=F);
    private := [stack=[top=ref xml], preserve=preserve, 
		pending='', doattrs=F, last=[=]];
    public := [=];

    private.cur := function() {
	wider private;
#  	if (len(private.stack) == 0) {
#  	    print '###DBG: empty stack!';
#  	    fail 'empty stack!';
#  	}
#  	if (! gxml.is_gxml(private.stack[len(private.stack)])) {
#  	    print '###DBG: corrupted stack:', 
#  		private.stack[len(private.stack)];
#  	    fail 'corrupted stack';
#  	}
	return ref private.stack[len(private.stack)];
    }

    private.pop := function() {
	wider private;
	if (len(private.stack) > 2) {
	    private.stack := private.stack[1:(len(private.stack)-1)];
	}
	else if (len(private.stack) > 1) {
	    private.stack := [top=ref private.stack[1]];
	}
#  	if (! gxml.is_gxml(private.stack[len(private.stack)])) {
#  	    print '###DBG: pop corrupted stack:', 
#  		private.stack[len(private.stack)];
#  	    fail 'corrupted stack';
#  	}
	return T;
    }

    private.push := function(ref nxt) {
	wider private;
#  	if (! gxml.is_element(nxt)) {
#  	    print '###DBG: pushing non-element onto element stack:', nxt;
#  	    fail paste('pushing non-element onto element stack:', nxt);
#  	}
	private.stack[len(private.stack)+1] := ref nxt;
	return T;
    }

    public.setpreserve := function(preserve) {
	wider private;
	private.preserve := as_boolean(preserve);
	return T;
    }

    public.parseline := function(line, lno=0) {
	wider private;

	line := spaste(private.pending, spaste(line));
	private.pending := '';
	while (strlen(line) > 0) {
	    if (private.doattrs) {
		# we're in the middle of assembling attributes
		local att;
		while (strlen(line) > 0) {
#		    print '###DBG: n =', n;
		    line =~ s/^\s+//;
		    if (line ~ m/^\/?>/) {
			if (line ~ m/^\/>/) private.pop();
			private.doattrs := F;
			line =~ s/^\/?>//;
#			printf('###DBG: finished el at %10s...\n', 
#			       split(line,'\n')[1]);
			break;
		    }
#		    n := n+1;
		    if (line !~ m/^[\w:]/) {
			local msg := 'illegal attribute name';
			if (lno > 0) 
			    msg[len(msg)+1] := spaste('at line ', lno);
			msg[len(msg)+1] := sprintf(': %10s', line);
			fail msg;
		    }
		    line =~ s/^(\w[^=\s]*)/$1$$/;
		    att := line[1];
		    line := line[2];
		    if (line !~ m/^\s*=/) {
			local msg := 'missing attribute value';
			if (lno > 0) 
			    msg[len(msg)+1] := spaste('at line ', lno);
			msg[len(msg)+1] := spaste('for: ', line);
			fail msg;
		    }
		    line =~ s/^\s*=\s*//;
		    if (line ~ m/^'/) {         #'
			line =~ s/'/$$'$$/g;    #'
		    } else if (line ~ m/^"/) {  #") {
			line =~ s/"/$$"$$/g;
		    } else {
			line := ['', '', split(line)[1], split(line)];
		    }
#		    print '###DBG: adding attribute:', att;
		    private.cur().setattribute(att, line[3]);
		    line := spaste(line[5:len(line)]);
		    line =~ s/^\s*//;
		}
	    }
	    else {
		if (line ~ m/^\s+/) {
		    line =~ s/^(\s*)/$1$$/;
		    if (gxml.is_sptext(private.last)) {
#			print '###DBG: appending space to text';
			private.last.append(line[1]);
		    }
#		    else if (private.preserve || gxml.is_space(private.last)) {
		    else {
#			print '###DBG: adding space:',line[1],strlen(line[1]);
			private.last := gxml.space(line[1])
			private.cur().appendchild(private.last);
		    }
		    line := spaste(line[2:len(line)]);
		    if (strlen(line) == 0) break;
		}

		if (line ~ m/^</) {
		    local parts := '';
		    if (line ~ m/^<!--/) {
			line =~ s/^<!--\s*//;
			if (line ~ m/-->/) {
			    line =~ s/(\s*-->)/$$$1/;
#			    print '###DBG: adding comment:', line[1];
			    if (! private.preserve && 
				gxml.is_space(private.last)) 
				    private.cur().removelast();
			    private.cur().addcomment(line[1]);
			    private.last := private.cur().lastchild();
			    line := line[2];
			    line =~ s/\s*-->//;
			} else {
			    private.pending := spaste('<!-- ', line);
#			    print '###DBG: pending:', private.pending;
			    return T;
			}
		    }

		    else if (line ~ m/<!\[CDATA\[/) {
			line =~ s/<!\[CDATA\[//;
			if (line ~ m/\]\]>/) {
			    line =~ s/(\]\]>)/$$$1/;
			    if (! private.preserve && 
				gxml.is_space(private.last)) 
				    private.cur().removelast();
			    private.cur().appendchild(line[1]);
			    line := line[2];
			    line =~ s/\]\]>//;
			} else {
			    private.pending := spaste('<![CDATA[', line);
#			    print '###DBG: pending:', private.pending;
			    return T;
			}
		    }

		    else if (line ~ m/<!DOCTYPE/) {
			line =~ s/<!DOCTYPE\s*//;
			if (line ~ m/>/) {
			    line =~ s/(\s*>)/$$$1$$/;
			    local parts := split(line[1]);
			    local public := '';
			    local system := '';
			    local decls := '';
			    if (len(parts) > 1) {
				if (parts[2] == 'SYSTEM') {
				    system := parts[3];
				    if (system ~ m/^".*"$/) {
					system =~ s/^"//;     # "
					system =~ s/"$//;     # "
				    }
				    if (len(parts) > 3) 
					decls := paste(parts[3:len(parts)]);
				}
				else if (parts[2] == 'PUBLIC') {
				    public := parts[3];
				    if (len(parts) > 3) {
					if (parts[4] !~ m/^\[/) {
					  system := parts[4];
					  if (len(parts) > 4) 
					    decls := paste(parts[5:len(parts)]);
				        } else {
					  decls := paste(parts[4:len(parts)]);
				        }
				    }
				}
				else {
				    decls := paste(parts[2:len(parts)]);
				}
			    }
#			    print '###DBG: adding doctype';
			    if (! private.preserve && 
				gxml.is_space(private.last)) 
				    private.cur().removelast();
			    private.last := gxml.doctype(parts[1], system,
							 public, decls);
			    private.cur().appendchild(private.last);
			    line := line[3];
			}
			else {
			    private.pending := spaste('<!DOCTYPE ', line);
#			    print '###DBG: pending:', private.pending;
			    return T;
			}
		    }

		    else if (line ~ m/^<\?/) {
			line =~ s/^<\?\s*//;
			if (line ~ m/\?>/) {
			    line =~ s/(\s*\?>)/$$$1/;
			    local w := split(line[1]);
			    if (len(w) == 1) w[2] := '';
#			    print '###DBG: adding instr:', w[1];
			    if (! private.preserve && 
				gxml.is_space(private.last)) 
				    private.cur().removelast();
			    private.cur().addprocinstruction(w[1], w[2:len(w)]);
			    private.last := private.cur().lastchild();
			    line := line[2];
			    line =~ s/\s*\?>//;
			} else {
			    private.pending := spaste('<\? ', line);
#			    print '###DBG: pending:', private.pending;
			    return T;
			}
		    }

		    else if (line ~ m/^<\//) {
			line =~ s/^<\/\s*//;
			if (strlen(line) == 0 || line !~ m/>/) {
			    private.pending := '</';
#			    print '###DBG: pending:', private.pending;
			    return T;
			}
			line =~ s/^([^>]*)/$1$$/;
			if (private.cur().getrep().name != line[1]) {
			    local msg := 'mismatched elements';
			    if (lno > 0) 
				msg[len(msg)+1] := spaste(' at line ', lno);
			    msg[len(msg)+1] := 
				spaste('; expected ', 
				       private.cur().getrep().name, 
				       ', found ', line[1]);
			    fail msg;
			}
#			print '###DBG: ending element:', line[1];
			if (! private.preserve && 
			    gxml.is_space(private.last)) 
			        private.cur().removelast();
			private.last := private.cur();
			private.pop();
			line := line[2];
			line =~ s/[^>]*>//;
		    }

		    else {
			line =~ s/^<\s*//;
			if (line !~ m/^[\w:]/) {
			    local msg := 'illegal element name';
			    if (lno > 0) 
				msg[len(msg)+1] := spaste(' at line ', lno);
			    msg[len(msg)+1] := spaste(': <', line);
			    fail msg;
			}
			line =~ s/([\w:]+)\s*/$1$$/;
#			print '###DBG: adding element:', line[1];
			if (! private.preserve && 
			    gxml.is_space(private.last)) 
			        private.cur().removelast();
			private.last := private.cur().getchildelement(line[1]);
			private.push(private.last);
			private.doattrs := T;
			line := line[2];
		    }
		}
		else if (len(line) > 0) {
		    # load text
		    line =~ s/(<)/$$$1/;
#		    if (len(line) == 1) line =~ s/(\s+)$/$$$1/;
		    if (gxml.is_space(private.last)) {
#			print '###DBG: converting space to text:';
			private.last.converttotext();
		    }
		    if (gxml.is_text(private.last)) {
#			print '###DBG: appendng text:',line[1],strlen(line[1]);
			private.last.append(line[1]);
		    }
		    else {
#		        print '###DBG: adding text:', line[1], strlen(line[1]);
			private.cur().addtext(line[1]);
			private.last := private.cur().lastchild();
		    }
		    if (len(line) > 1) 
			line := line[2:len(line)];
		    else 
			line := '';
		}
	    }
#	    printf('###DBG: going on: %10s...\n', split(line, '\n')[1]);
	}

	return T;
    }

    public.parsefile := function(file) {
	local fh := open(paste('<', file));
	if (is_fail(fh)) return fh;
	local lno := 0;

	line := read(fh);
#	if (len(line) == 0) print '###DBG: empty file!';
	while ( len(line) > 0 ) {
	    lno +:= 1;
	    ok := public.parseline(line, lno);
	    if (is_fail(ok)) return ok;
	    line := read(fh);
	}
	return T;
    }

    public.getdoc := function() { return xml; }

    public.done := function() { 
	wider xml,private,public;
	xml := F;
	private := F;
	val public := F;
    }

#    public.private := ref private;
#    public.xml := ref xml;

    return ref public;
}
