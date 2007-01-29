# gxml: utility for creating and printing XML
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
# $Id: gxml.g,v 19.2 2004/08/25 02:22:42 cvsmgr Exp $
pragma include once;

include 'unset.g';

gxml := [=];

const gxml.space := function(space='') {
    return gxml.text(space, T);
}

const gxml.text := function(text='', asspace=F) {
    public := [gxml=random()];
    rep := [type='tx', data=text];
    if (asspace) rep.type := 'sp';

    public.converttotext := function() { wider rep; rep.type := 'tx'; }

    public.append := function(str) {
	wider rep;
	rep.data := spaste(rep.data, str);
	return T;
    }

    public.tostring := function(preserve=T, pretty=F, indent=0) {
	wider rep, public;
	if (rep.type == 'sp') {
	    return public.spacetostring(preserve, pretty, indent);
	} else {
	    return rep.data;
	}
    }

    public.spacetostring := function(preserve=T, pretty=F, indent=0) {
	wider rep;
	if (preserve) 
	    return rep.data;
	else 
	    return '';
    }

    public.getrep := function() { wider rep; return ref rep; }

    public.clone := function() { 
        return gxml.text(rep.data, (rep.type == 'sp'));
    }

    return ref public;
}

const gxml.proc := function(target, text='') {
    public := [gxml=random()];
    rep := [type='pi', target=target, data=text];
    public.tostring := function(preserve=T, pretty=F, indent=0) { 
	wider rep
	return spaste('<?', rep.target, ' ', rep.data, ' ?>');
    }
    public.getrep := function() { wider rep; return ref rep; }
    public.clone := function() { 
        return gxml.proc(rep.target, rep.data);
    }

    return ref public;
}

const gxml.comm := function(text='') {
    public := [gxml=random()];
    rep := [type='cm', data=text];
    public.tostring := function(preserve=T, pretty=F, indent=0) { 
	wider rep;
	return spaste('<!-- ', rep.data, ' -->');
    }
    public.getrep := function() { wider rep; return ref rep; }
    public.clone := function() { 
        return gxml.comm(rep.data);
    }
    return ref public;
}

const gxml.doctype := function(root, systemid='', publicid='', decls='') {
    public := [gxml=random()];
    rep := [type='dt', root=root, system=systemid, public=publicid, data=decls];
    public.tostring := function(preserve=T, pretty=F, indent=0) { 
	wider rep;
	local id := '';
	if (strlen(rep.public) > 0) {
	    id := spaste(' PUBLIC "', rep.public, '"');
	    if (strlen(rep.system) > 0) id := spaste(id, '"', rep.system, '"');
	}
	else if (strlen(rep.system) > 0) {
	    id := spaste(' SYSTEM "', rep.system, '"');
	}
	local decls := '';
	if (strlen(decls) > 0) decls := spaste(' ', paste(decls));

	return spaste('<!DOCTYPE ', rep.root, id, decls, '>');
    }
    public.getrep := function() { wider rep; return ref rep; }
    public.clone := function() { 
        return gxml.doctype(rep.root, rep.system, rep.public, rep.data);
    }

    return ref public;
}

const gxml.is_gxml := function(rec) {
    return (is_record(rec) && has_field(rec, 'gxml'));
}

const gxml.is_element := function(rec) {
    return (gxml.is_gxml(rec) && rec.getrep().type == 'el');
}

const gxml.is_space := function(rec) {
    return (gxml.is_gxml(rec) && rec.getrep().type == 'sp');
}

const gxml.is_text := function(rec) {
#      local r := rec.getrep();
#      if (! is_record(r) || ! has_field(r,'type')) {
#  	print '###DBG: gxml rep corrupted!', r;
#      }
    return (gxml.is_gxml(rec) && rec.getrep().type == 'tx');
}

const gxml.is_sptext := function(rec) {
    return (gxml.is_gxml(rec) && 
	    (rec.getrep().type == 'sp' || rec.getrep().type == 'tx'));
}

const gxml.is_document := function(rec) {
    return (gxml.is_gxml(rec) && rec.getrep().type == 'do');
}

const gxml.is_parent := function(rec) {
    return (gxml.is_gxml(rec) && 
	    (rec.getrep().type == 'el' || rec.getrep().type == 'dt'));
}

const gxml.is_doctype := function(rec) {
    return (gxml.is_gxml(rec) && rec.getrep().type == 'dt');
}

const gxml.is_same := function(ref node1, ref node2) {
    if (! gxml.is_gxml(node1) || ! gxml.is_gxml(node2)) return F;
    return (node1.gxml == node2.gxml);
}

const gxml.is_proc := function(rec) {
    return (gxml.is_gxml(rec) && rec.getrep().type == 'pi');
}

#@tool 
# buffer for building an element using gxml storage.
# 
# @constructor
# create a gxml element buffer.
const gxml.element := function(name=unset, type='el') {

    private := [hold=[=]];
    buf := [=];
    private.init := function(type) {
	wider buf;
	buf := [type=type, name='', atts=[=], data=[=]];
    }
    private.init(type);

    #@toolrec public
    public := [gxml=random()];
    if (! is_unset(name)) buf.name := name;

    #@
    # clear all content associated with the element being built
    public.clear := function() { 
	wider private, buf;
	local name := buf.name;
	private.init(buf.type);
	buf.name := name;
	return T;
    }

    #@
    # set the name of the element
    # @inparam elname  the element name.  This must begin with a letter
    #                and should should not end in a number.
    #                @type string
    #                @default none
    # @inparam clear   if true, clear all previously added data
    public.setname := function(elname, clear=T) { 
	wider public, buf;
	if (clear) public.clear();
	buf.name := elname;
	return T;
    }

    #@ 
    # return the name of the element
    ##
    public.getname := function() { return buf.name; }

    #@
    # set an attribute value
    # @inparam attname   the attribute name.  The name must begin with 
    #                    a letter.
    #                    @type string
    # @inparam value     the value of the attribute
    # @inparam default   if true, this value should be considered a default.
    #                    This can used to affect conversion to XML--e.g. one
    #                    may not want to have attributes with default values
    #                    printed out.
    public.setattribute := function(attname, value='', default=F) { 
	wider buf;
 	if (! is_string(attname) || attname !~ m/^\w/) 
 	    fail paste('Illegal attribute name:', attname);
 	buf.atts[attname] := as_string(value);
	return T;
    }

    #@
    # get an attribute value
    # @inparam     attname   the attribute name
    # @optinparam  default   a default value to return if the attribute is 
    #                           not set
    ##
    public.getattribute := function(attname, default='') {
	if (has_field(buf.atts, attname)) return buf.atts[attname];
	else return default;
    }

    #@
    # append a child node
    public.appendchild := function(ref child) {
	wider buf;
	buf.data[len(buf.data)+1] := ref child;
	return T;
    }

    #@ 
    # add some text to the value of the current element
    # @inparam  text   the text to add
    #                  @type any
    #                  @default an empty string
    public.addtext := function(text='') { 
	wider buf;
	buf.data[len(buf.data)+1] := gxml.text(text);
	return T;
    }

    #@ 
    # append a comment to the value of the current element
    # @inparam  text     the comment text to add
    #                  @default an empty string
    public.addcomment := function(text='') { 
	wider buf;
	buf.data[len(buf.data)+1] := gxml.comm(text);
	return T;
    }

    #@ 
    # append a processing instruction to the value of the current element
    # @inparam  text     the processing instruction text to add
    #                  @default none
    #                  @type string
    public.addprocinstruction := function(target, text) { 
	wider buf;
	buf.data[len(buf.data)+1] := gxml.proc(target, text);
	return T;
    }

    #@ 
    # append space to the value of this element
    # @inparam text   the space to add.  In principle, this should contain 
    #                    only space characters ('\s\t\n'), but no check is 
    #                    done to guarantee this.
    public.addspace := function(text=' ') {
	wider buf;
	buf.data[len(buf.data)+1] := gxml.space(text);
	return T;
    }

    #@ 
    # append a child element to the value of the current element
    # @inparam  elname   the element name
    # @inparam  which    replace the which-th element, if it exists;
    #                  otherwise, just add it.
    #                  @default 0, which means append a new processing 
    #                           instruction
    public.addelement := function(elname, which=0) { 
	wider buf;
	buf.data[len(buf.data)+1] := gxml.element(elname);
	return T;
    }

    #@
    # return a the buffer of a child element for editing
    # @inparam elname   the child element name.  If the element has not
    #                     yet been added, it will be.
    # @inparam which    return the which-th element, if it exists;
    #                     otherwise, just add it.  If which < 0, the last
    #                     matching element will be returned.
    # @return tool of type element
    public.childelement := function(elname, which=0) { 
	wider buf;

	# search for matching element
	local n := len(buf.data);
	local el := unset;
	if (n > 0 && which != 0 && n >= which) {
	    local i := 1;
	    local j := 0;
	    while (i <= n) {
		el := ref buf.data[i];
		if (gxml.is_gxml(el) &&
		    el.getrep().type == 'el' && el.getrep().name == elname) 
		{ 
		    j +:= 1;
		    if (j == which) break;
		}
		i +:= 1;
	    }
	    if (i > n && which > 0) el := unset;
	}
	if (is_unset(el)) {
	    public.addelement(elname);
	    return ref buf.data[len(buf.data)];
	} else {
	    return ref el;
	}
    }

    public.getchildelement := public.childelement;
    public.setchildelement := public.childelement;

    #@
    # add and return an element containing a single string as a child
    # @inparam elname  element name
    # @inparam text    the text to add as a child
    # @return gxmlwrapper tool
    ##
    public.addtextelement := function(elname, text='') {
	wider buf, private;
	public.addelement(elname);
	local el := ref buf.data[len(buf.data)];
	el.addtext(text);
	return ref el;
    }

    #@
    # return true if this element only contains text and space children
    public.istextelement := function() {
	wider buf;
	return (len(buf.data) == 1 && gxml.is_text(buf.data[1]));
    }

    #@ 
    # return a list of this element's children as a record vector
    ##
    public.getchildnodes := function() {
	wider buf;
	return buf.data;
    }

    #@
    # return the child elements matching a given tag name.   
    # The returned vector will be zero-length if such elements are not found.
    # @param tag    the tag name to match
    # @param first  if false (default), all matching child elements are 
    #                 returned as a record vector; if true, just the first
    #                 matching element is returned directly (i.e. not in a 
    #                 vector).
    ##
    public.getelementsbytagname := function(tag, first=F) {
	wider buf;
	if (! is_string(tag)) fail paste("Non-string given as tag name:", tag);
	local out := [=];
	if (len(buf.data) == 0) return out;
	for(i in [1:len(buf.data)]) {
	    if (gxml.is_element(buf.data[i]) && 
		buf.data[i].getrep().name == tag) 
	    {
		out[len(out)+1] := ref buf.data[i];
		if (first) break;
	    }
	}

	if (! first || len(out) == 0) {
	    return out;
	} else {
	    return out[1];
	}
    }

    #@ 
    # return the elements matching the given (simplified) path.  
    # @param path   a simplified XPath node path.  Currently, only 
    #                  paths reference direct descendent elements are 
    #                  supported.
    # @param first  if false (default), all matching child elements are 
    #                 returned as a record vector; if true, just the first
    #                 matching element is returned directly (i.e. not in a 
    #                 vector).
    ##
    public.getelementsbypath := function(path, first=F) {
	if (strlen(path) == 0) fail 'getelementsbypath: No path provided';
	path := paste(path);
	path =~ s/\//$$/;
	local children := public.getelementsbytagname(path[1], first);
	if (len(path) == 1 || len(children) == 0) return children;

	if (first) return children.getelementsbypath(path[2]);

	local out := [=];
	local child, matches;
	for (child in children) {
	    matches := child.getelementsbypath(path[2]);
	    if (len(matches) > 0) {
		for (i in [1:len(matches)]) {
		    out[len(out)+1] := ref matches[i];
		}
	    }
	}

	if (first && len(out) > 0) out := ref out[1];
	return out;
    }

    #@ 
    # return a reference of the last child.  F is returned if this element
    # is childless.
    public.lastchild := function() {
	wider buf;
	if (len(buf.data) > 0) {
	    return ref buf.data[len(buf.data)];
	} else {
	    return F;
	}
    }

    #@
    # insert a child element.  F is returned if the reference child is not 
    # found (and therefore the newchild was not inserted).
    # @param newchild   the new child element to insert
    # @param refchild   the reference child--the child to insert in front of.
    ##
    public.insertbefore := function(ref newchild, ref refchild) {
	wider buf;

	local i := 1;
	if (!gxml.is_gxml(refchild)) 
	    fail paste('Unable to locate non-xml nodes:', refchild);
	while (i <= len(buf.data) && 
	       (! gxml.is_gxml(buf.data[i]) || 
		refchild.gxml != buf.data[i].gxml)) 
	{ 
	    i +:= 1;
	}

	if (i > len(buf.data)) return F;

	local tmp := [=];
	local fns := field_names(buf.data);
	if (len(fns) > 0) {
	    for(j in [1:len(fns)]) {
		tmp[fns[j]] := ref buf.data[fns[j]];
	    }
	}
	buf.data := [=];
	j := 1;
	while (j < i) {
	    buf.data[fns[j]] := ref tmp[fns[j]];
	    j +:= 1;
	}
	buf.data[j] := ref newchild;
	while (j <= len(fns)) {
	    buf.data[fns[j]] := ref tmp[fns[j]];
	    j +:= 1;
	}

	return T;
    }

    #@ 
    # insert a new child element before the first occurance of an existing 
    # child element with a name from the given list.
    # @param newchild   the new child to insert
    # @param ellist     a list of element names to look for among the 
    #                      children of this element.  The new child will 
    #                      be inserted before the first child found with a
    #                      name matching one in this list.
    public.insertbeforeelement := function(ref newchild, ellist="") {
	wider buf;
	if (len(ellist) == 0 || all(strlen(ellist)) == 0) {
	    buf.data[len(buf.data)+1] := newchild;
	    return T;
	}

	local i := 1;
	while (i <= len(buf.data)) {
	    if (gxml.is_element(buf.data[i]) && 
		any(buf.data[i].getrep().name == ellist)) 
	      break;
	    i +:= 1;
	}

	if (i > len(buf.data)) {
	    buf.data[len(buf.data)+1] := newchild;
	    return T;
	}
	else {
	    return public.insertbefore(newchild, buf.data[i]);
	}
    }

    #@ 
    # remove the last child from this element
    public.removelast := function() {
	wider buf;
#	local temp := buf.data[len(buf.data)].tostring();
#	print '###DBG: removing', temp, strlen(temp);

	# this mess is to preserve references (ack!)
	local tmp := [=];
	local fns := field_names(buf.data);
	if (len(fns) > 1) {
	    for(i in [1:(len(fns)-1)]) {
		tmp[fns[i]] := ref buf.data[fns[i]];
	    }
	}
	buf.data := [=];
	for(fn in field_names(tmp)) {
	    buf.data[fn] := ref tmp[fn];
	}

	return T;
    }

    #@
    # return element as a formatted string
    # @inparam pretty   if true, add space for multi-line & indented output
    # @inparam preserve if true, preserve space currently part of this element
    public.childrentostring := function(preserve=T, pretty=F, indent=0) {
	wider buf, private, public;
	local indentsp := '';
	if (pretty && indent > 0) indentsp := spaste(rep(' ', indent));

	local children := '';
	local lastsib := unset;
	local j := 0;

	for(i in [1:len(buf.data)]) {
	    if (gxml.is_gxml(buf.data[i])) {
		addspace := (pretty && indent > -4 && 
			     ! gxml.is_space(lastsib) &&
			     buf.data[i].getrep().type != 'sp');

		if (addspace) children[j+:=1] := indentsp;

		children[j+:=1] := 
		    buf.data[i].tostring(preserve, pretty, indent);

		if (addspace && i < len(buf.data)) children[j+:=1] := '\n';
	    }
	    else {
		children[j+:=1] := spaste('<![CDATA[', buf.data[i], ']]>');
	    }

	    lastsib := ref buf.data[i];
	}

	return spaste(children);
    }

    #@
    # return element as a formatted string
    # @inparam pretty   if true, add space for multi-line & indented output
    # @inparam preserve if true, preserve space currently part of this element
    public.tostring := function(preserve=T, pretty=F, indent=0) {
	wider buf, private;
	local indentsp := '';
	if (pretty && indent > 0) indentsp := spaste(rep(' ', indent));

	if (buf.type == 'do') 
	    return public.childrentostring(preserve, pretty, indent);

	local head1 := spaste('<', buf.name);
	local atts := '';
	local fn := field_names(buf.atts);
	if (len(buf.atts) > 0) {
	    for (i in [1:len(fn)]) {
		atts[len(atts)+1] := spaste(fn[i], '="', buf.atts[fn[i]], '"');
	    }
	}

	local head2 := '/>';
	local sp2 := '';
	local sp3 := '';
	local tail := '';
	local children := '';
	j := 1;
	if (len(buf.data) > 0) {
	    head2 := '>';
	    if (public.istextelement()) {
		children := buf.data[1].tostring(); 
	    } 
	    else {
		if (pretty && ! gxml.is_sptext(buf.data[1])) sp2 := '\n';
		children := public.childrentostring(preserve, pretty, indent+4);
		if (pretty) sp3 := indentsp;
	    }
	    tail := spaste('</', buf.name, '>');
	}

	return spaste(head1,paste(atts),head2,sp2,children,sp2,sp3,tail);
    }

    #@
    # return a record representation of the data that is more user-oriented
    public.torec := function(preserve=F) {
	wider buf;
	local ci, child, f;
	local ns := 0;
	local nt := 0;
	local np := 0; 
	local nc := 0;
	local nd := 0;
	local out := [=];

	if (public.istextelement()) {
	    out := buf.data[1].getrep().data;
	}
	else {
	    for(ci in field_names(buf.data)) {
		if (! gxml.is_gxml(buf.data[ci])) {
		    f := '_cdata';
		    if (nd > 0) f := spaste(f, '_', nd);
		    nd +:= 1;
		    out[f] := buf.data[ci];
		    next;
		}

		child := buf.data[ci].getrep();
		if (child.type == 'sp') {
		    if (! preserve) next;
		    f := '_space';
		    if (ns > 0) f := spaste(f, '_', ns);
		    ns +:= 1;
		    out[f] := child.data;
		}

		else if (child.type == 'tx') {
		    f := '_text';
		    if (nt > 0) f := spaste(f, '_', nt);
		    nt +:= 1;
		    out[f] := child.data;
		}

		else if (child.type == 'pi') {
		    f := '_proc';
		    if (np > 0) f := spaste(f, '_', np);
		    np +:= 1;
		    out[f] := [child.target, child.data];
		}

		else if (child.type == 'cm') {
		    f := '_comm';
		    if (nc > 0) f := spaste(f, '_', nc);
		    nc +:= 1;
		    out[f] := child.data;
		}

		else if (child.type == 'dt') {
		    f := '_doctype';
		    out[f] := [root=child.root, public=child.public,
			       system=child.system];
		    if (strlen(child.data) > 0) out[f].decls := child.data;
		}

		else if (child.type == 'el') {
		    f := child.name;
		    if (len(out) > 0) {
			local fn := field_names(out) ~ s/_\d+$//;
			if (len(fn) > 0) {
			    local ne := len(fn[fn == child.name]);
			    if (ne > 0) f := spaste(f, '_', ne);
			}
		    }
		    out[f] := buf.data[ci].torec(preserve);
		}
	    }
        }

	if (buf.type != 'do') out::_name := buf.name;
	for(att in field_names(buf.atts)) {
	    out::[att] := buf.atts[att];
	}

	return out;
    }

    public.getrep := function() { wider buf; return ref buf; }

    public.clone := function() { gxml.fromrec(public.torec()); }

    return ref public;
}

const gxml.textelement := function(elname=unset, text='') {
    el := gxml.element(elname);
    el.addtext(text);
    return ref el;
}

const gxml.doc := function(doxmlproc=T, standalone='', version="1.0") {
    doc := gxml.element('DOC', type='do');
    hold := [=];

    if (doxmlproc) {
	local txt := spaste('version="',version,'" encoding="utf-8"');
	if (standalone != '') 
	    txt := spaste(txt, ' standalone="', standalone, '"');
	doc.addprocinstruction("xml", txt);
    }

    #@
    # return the xml processing instruction (<?xml ...?>) or F if it is not
    # set yet.
    ##
    doc.getxmlproc := function() {
        wider doc;
        local data := ref doc.getrep().data;
        if (len(data) == 0) return F;
        if (! gxml.is_proc(data[1]) || data[1].getrep().target != 'xml')
            return F;
        return ref data[1];
    }

    #@ 
    # set the xml processing instruction
    # @param standalone   if 
    ##
    doc.setxmlproc := function(standalone='', encoding='utf-8', version='1.0')
    {
        wider doc;
        local txt := spaste('version="',version,'" encoding="',encoding,'"');
	if (standalone != '') 
	    txt := spaste(txt, ' standalone="', standalone, '"');
        local xp := doc.getxmlproc();
        if (gxml.is_gxml(xp)) {
            xp.getrep().data := txt; 
        }
        else {
            if (len(doc.getrep().data) > 0) {
		wider hold;
		local n := len(hold)+1;
		hold[n] := gxml.proc('xml', txt);
                doc.insertbefore(hold[n], doc.getrep().data[1]);
            } else {
                doc.addprocinstruction('xml', txt);
            }
        }
        return T;
    }

#    doc.gethold := function() {wider hold; return ref hold; }

    #@
    # return the DOCTYPE node or F if it has not been set yet.
    ## 
    doc.getdoctype := function() {
        wider doc;
        local data := ref doc.getrep().data;
        if (len(data) == 0) return F;
        local i;
        for (i in [1:len(data)]) {
            if (gxml.is_element(data[i])) return F;
            if (data[i].getrep().type == 'dt') return ref data[i];
        }
        return F;
    }

    doc.setdoctype := function(root, systemid=unset, publicid=unset, 
                               decls=unset) 
    {
        wider doc;
        local dt := doc.getdoctype();
        if (gxml.is_gxml(dt)) {
            local rep := dt.getrep();
            rep.root := root;
            if (! is_unset(systemid)) rep.systemid := systemid;
            if (! is_unset(publicid)) rep.publicid := publicid;
            if (! is_unset(decls)) rep.data := decls;
        }
        else {
	    wider hold;
            if (is_unset(systemid)) systemid := '';
            if (is_unset(publicid)) publicid := '';
            if (is_unset(decls)) decls := '';

	    local n := len(hold)+1;
	    hold[n] := gxml.doctype(root, systemid, publicid, decls);

            local rn := doc.getroot();
            if (gxml.is_gxml(rn)) {
                root := rn.getname();
                doc.insertbefore(hold[n], rn);
            } 
            else {
                doc.appendchild(hold[n]);
            }
        }   

	return T;
#        return doc.getdoctype();
    }

    #@ 
    # set and return the root element.  No check is made to ensure that
    # the element name matches that set by the DOCTYPE node.
    ##
    doc.setroot := function(name) {
	wider doc;
	return doc.getchildelement(name);
    }

    #@
    # return the root element or F if not set yet.
    ##
    doc.getroot := function() {
	wider doc;
	local child := F;
	local i;
	for(i in [1:len(doc.getrep().data)]) {
	    child := ref doc.getrep().data[i];
	    if (gxml.is_element(child)) break;
	    child := F;
	}
	return ref child;
    }

    #@
    # return the root element name or an empty string if not set yet.
    ##
    doc.getrootname := function() {
	local root := doc.getroot();
	if (! is_boolean(root)) {
	    return root.getrep().name;
	} else {
	    return '';
	}
    }

    return ref doc;
}

const gxml.fromrec := function(rec, name=unset, doxmlproc=F) {
    if (! is_record(rec)) fail paste('gxml.fromrec: Not a record:', rec);

    out := [=];
    if (is_unset(name) && has_field(rec::, '_name')) 
	name := rec::_name;
    if (is_unset(name)) {
	out := gxml.doc(doxmlproc=doxmlproc);
    } else {
	out := gxml.element(name);
    }

    for (att in field_names(rec::)) {
	if (att ~ m/^_/) next;
	out.setattribute(att, rec::[att]);
    }

    for(fn in field_names(rec)) {
	if (fn ~ m/^_comm(_\d+)?$/) {
	    out.addcomment(rec[fn]);
	}
	else if (fn ~ m/^_proc(_\d+)?$/) {
	    if (len(rec[fn]) > 1) {
		out.addprocinstruction(rec[fn][1], rec[fn][2]);
	    } else {
		out.addprocinstruction(rec[fn]);
	    }
	}
	else if (fn ~ m/^_text(_\d+)?$/) {
	    out.addtext(rec[fn]);
	}
	else if (fn ~ m/^_doctype$/) {
	    local decls := '';
	    local public := '';
	    local system := '';
	    if (has_field(rec[fn], decls)) decls := rec[fn].decls;
	    if (has_field(rec[fn], public)) public := rec[fn].public;
	    if (has_field(rec[fn], system)) system := rec[fn].system;
	    out.appendchild(gxml.doctype(rec[fn].root, system, public, decls));
	}
	else if (fn ~ m/^_cdata(_\d+)?$/) {
	    out.appendchild(rec[fn]);
	}
	else if (fn ~ m/^_/) {
	    fail paste('Unrecognized non-element node type:', fn);
	}
	else {
	    local name := fn ~ s/_\d+$//;
	    if (is_record(rec[fn])) {
		out.appendchild(gxml.fromrec(rec[fn], name));
	    }
	    else {
		local el := out.addtextelement(name, as_string(rec[fn]));
		for (att in field_names(rec[fn]::)) {
		    if (att ~ m/^_/) next;
		    el.setattribute(att, rec[fn]::[att]);
		}
	    }
	}
    }

    return ref out;
}
