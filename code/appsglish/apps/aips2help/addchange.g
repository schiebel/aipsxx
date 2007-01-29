# addchange: glish closure object for adding a changelog entry
# Copyright (C) 2000,2002,2003
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
# $Id: addchange.g,v 19.4 2005/02/02 13:17:24 gvandiep Exp $

include "sysinfo.g"
include "widgetserver.g"
include "os.g"


pragma include once


# We only work if we have a GUI.
const addchange := function()
{
    if (! have_gui()){ 
	fail 'addchange.g needs to be run from a graphical user interface';
    }
    rec := addchangeinit();
    if (len(rec) == 0) {
	return F;
    }
    print 'The changelog files have been checked out successfully\n',
	  'Please fill in and submit the addchange entry form';
    res := addchangegui (rec);
    if (len(res) == 0) {
	return F;
    }
    res := addchangeappend (res);
    if (is_fail(res)) {
	print res;
	return F;
    }
    return T;
}

# Initialization function - load all the standard stuff
const addchangeinit := function()
{
    rec := [=];
    # Get user name.
    rec.who := '';
    if (! getrc.find(rec.who, 'user.info.name')) {
	if (! getrc.find(rec.who, 'userinfo.name')) {
	    # Not defined in aipsrc, so get it from the shell.
	    # Most systems have pinky, but old Solaris systems don't.
	    # 'which' on Solaris always returns 0, so you cannot do:
	    #     which pinky > /dev/null 2>&1  &&  pinky
	    fcom := "";
	    res := shell('which pinky');
	    if (res !~ m/no pinky/) {
		fcom := shell('pinky -f $LOGNAME | grep $LOGNAME');
	    }
	    if (len(fcom) == 0) {
		res := shell('which finger');
		if (res !~ m/no finger/) {
		    fcom := shell('finger -s $LOGNAME | grep $LOGNAME');
		}
	    }
	    if (len(fcom) > 0) {
		if (len(fcom) > 1) {
		    fcom := fcom[1];
		}
		if (strlen(fcom) > 0) {
		    fcom ~:= s/^.*?\s+//;
		    rec.who := fcom ~ s/(  |\t).*//;
		}
	    }
	}
    }
    # Remove trailing whitespace.
    if (strlen(rec.who) == 0) {
	rec.who := shell('echo $LOGNAME');
    }
    rec.who ~:= s/\s+$//;
    # Get date and AIPS++ version.
    date := shell('adate');
    rec.date := split(date)[2];
    s := sysinfo();
    s.version (formatted=form,  dolog=F);
    rec.version := split(form)[1];
    # Get package and module name from working directory.
    rec.islib := F;
    rec.isglish := F;
    rec.isdoc := F;
    rec.issystem := F;
    rec.wd := dos.fullname('.');
    wdparts := rec.wd ~ s@/code/@$$@;     #split string
    rec.srcdir := '';
    if (len(wdparts) == 2) {
	rec.srcdir := wdparts[2];
    }
    rec.area := '';
    rec.pkg := '';
    rec.module := '';
    x := split(rec.srcdir, '/');
    if (x[1] == 'doc') {
        rec.isdoc := T;
	rec.pkg := 'LearnMore';
    } else if (x[1] == 'install') {
        rec.issystem := T;
	rec.pkg := 'System';
    } else {
        rec.pkg := x[1];
        if (len(x) > 1) {
	    if (x[2] == 'glish') {
	        rec.isglish := T;
                rec.pkg := 'Glish';
            } else if (len(x) > 2) {
                if (x[2] ~ m/implement/) {
	            rec.islib := T;
	        }
	        rec.module := x[3];
	    }
	}
    }
    # Find the possible available tools (i.e. glish scripts)
    # in user and system directory.
    rec.tools := '';
    if (!rec.isglish  &&  !rec.isdoc  &&  !rec.issystem) {
        ltools := dos.dir ('.', '*.g', follow=F);
        aipspath := split(environ.AIPSPATH)[1];
        stools := dos.dir (spaste(aipspath, '/code/', rec.srcdir),
                           '*.g', follow=F);
	tools := as_string([ltools, stools])
	if ( len(tools) > 0 ) {
	    tools := [ltools, stools] ~ s/\.g$//;
	    if (len(tools) > 0) {
		# Ignore meta files and test scripts.
		tools := tools[tools !~ m/.*_meta$/];
		ttools := tools ~ s/^t//;
		for (i in 1:len(tools)) {
		    if (any(ttools[i] == tools)) {
			tools[i] := ttools[i];
		    }
		}
	    }
	}

        rec.tools := unique(tools);
    }
    return rec;
}


const addchangegui := function(rec, wgs=dws)
{
    wgs.tk_hold();
    priv := [=];

    # Create the frames, entry widgets, etc...
    priv.title := 'Add an entry to the AIPS++ change log';
    priv.main := wgs.frame(title=priv.title);

    priv.ver := [=];
    priv.ver.f := wgs.frame(priv.main, side='left');
    priv.ver.l := wgs.label(priv.ver.f, 'AIPS++ Version: ', borderwidth=3);
    priv.ver.e := wgs.entry(priv.ver.f, width=10, background='LightGrey');
    priv.ver.e->insert(rec.version);
    priv.ver.e->disable();
    wgs.popuphelp(priv.ver.l, 'Version of AIPS++ you are running');
    wgs.popuphelp(priv.ver.e, 'Version of AIPS++ you are running');

    priv.pkg := [=];
    priv.pkg.f := wgs.frame(priv.main, side='left');
    priv.pkg.l := wgs.label(priv.pkg.f, 'Package:        ', borderwidth=3);
    priv.pkg.e := wgs.entry(priv.pkg.f, width=30, background='LightGrey');
    priv.pkg.e->insert (rec.pkg);
    priv.pkg.e->disable();
    wgs.popuphelp(priv.pkg.l, 'Package you are currently in');
    wgs.popuphelp(priv.pkg.e, 'Package you are currently in');

    priv.area := [=];
    priv.mod := [=];
    priv.area.f := wgs.frame(priv.main, side='left');
    priv.area.l := wgs.label(priv.area.f, 'Area:           ', borderwidth=3);
    priv.mod.f := wgs.frame(priv.main, side='left');
    priv.mod.l := wgs.label(priv.mod.f, '                ', borderwidth=3);
    priv.mod.e := wgs.entry(priv.mod.f, width=30);
    priv.mod.e->disable();

    # Glish, system, and learnmore do not need a menu.
    hlpl := '';
    lnopt := 1;
    if (rec.isglish) {
	options := 'Glish module    ';
        hlpl := ' Changes in glish';
    } else if (rec.isdoc) {
	options := 'LearnMore module';
        hlpl := ' Notes, memos, papers, reports, etc.';
    } else if (rec.issystem) {
	options := 'System module   ';
        hlpl := ' System: system related scripts, etc.';
    } else{
	lnopt := 0;
    }
    if (lnopt > 0) {
	rec.area := options ~ s/ module\s*$//;
	priv.area.e := wgs.entry(priv.area.f, width=30, background='LightGrey');
	priv.area.e->insert (rec.area);
	priv.mod.l->text (options);
        priv.mod.e->enable();
        wgs.popuphelp (priv.mod.l, hlpl);
        wgs.popuphelp (priv.mod.e, hlpl);
    } else {
        options := 'Tool            ';
	lnopt := 1;
        hlpl := ' Tool: a tool (glish script and C++ DO)';
        if (rec.islib) {
	    lnopt +:= 1;
	    options[2] := 'Library module  ';
            hlpl := paste(hlpl, ' Library: modules in C++ libraries',
                          sep='\n');
        }
        options[lnopt+1] := 'System          ';
        hlpl := paste(hlpl, ' System: system related scripts, etc.', sep='\n');
        hlps := 'Choose an area of AIPS++ software';
        wgs.popuphelp (priv.area.l, hlpl, hlps, combi=T);
        labels := array('Choose an area', len(options));
        priv.area.menu := wgs.optionmenu(priv.area.f, labels, options, options,
				         hlp=hlps, hlp2=hlpl);
        hlps := paste('Name of tool or library module, etc.',
	              'Can be used after a area is chosen',
	              sep='\n');
        wgs.popuphelp(priv.mod.l, hlps);
        wgs.popuphelp(priv.mod.e, hlps);
        priv.mod.hlps := hlps;
        priv.mod.ismenu := F;

        whenever priv.area.menu->select do {
            area := $value.value;
	    rec.area := area ~ s/ (module)?\s*$//;
	    if (priv.mod.ismenu) {
	        priv.mod.l.done();
            } else {
	        wgs.popupremove (priv.mod.l);
            }
	    priv.mod.l := F;
	    wgs.popupremove (priv.mod.e);
            priv.mod.e := F;
            priv.mod.ismenu := F;
	    if (rec.area == 'Tool'  &&  len(rec.tools) > 0) {
	        labels := array('Tools          ', len(rec.tools));
	        priv.mod.l := wgs.optionmenu(priv.mod.f, labels,
                                             rec.tools, rec.tools,
					     hlp='Choose a tool');
	        priv.mod.ismenu := T;
	        whenever priv.mod.l->select do {
		    priv.mod.e->delete ('start', 'end');
		    priv.mod.e->insert ($value.value);
	        }
	    } else {
                priv.mod.l := wgs.label(priv.mod.f, area, borderwidth=3);
	        wgs.popuphelp(priv.mod.l, priv.mod.hlps);
            }
            priv.mod.e := wgs.entry(priv.mod.f, width=30);
            wgs.popuphelp(priv.mod.e, priv.mod.hlps);
            if (rec.area == 'Library') {
                priv.mod.e->background ('LightGrey');
		priv.mod.e->disable();
	        priv.mod.e->insert(rec.module);
	    }
        }
    }

    priv.user := [=];
    priv.user.f := wgs.frame(priv.main, side='left');
    priv.user.l := wgs.label(priv.user.f, 'Author:         ', borderwidth=3);
    priv.user.e := wgs.entry(priv.user.f, width=30);
    priv.user.e->insert(rec.who);
    wgs.popuphelp(priv.user.l, 'Author of change');
    wgs.popuphelp(priv.user.e, 'Author of change');

    priv.date := [=];
    priv.date.f := wgs.frame(priv.main, side='left');
    priv.date.l := wgs.label(priv.date.f, 'Date:           ', borderwidth=3);
    priv.date.e := wgs.entry(priv.date.f, width=10);
    priv.date.e->insert (rec.date);
    wgs.popuphelp(priv.date.l, 'Date of change');
    wgs.popuphelp(priv.date.e, 'Date of change');

    if (!rec.isdoc) {
        priv.type := [=];
        priv.type.f := wgs.frame(priv.main, side='left', expand='x');
        priv.type.l := wgs.label(priv.type.f, 'Type:           ');
        wgs.popuphelp(priv.type.l, 'Change types; multiple can be selected');
        priv.type.code := wgs.button(priv.type.f, 'Code', type='check',
			             value='code', relief='flat');
        wgs.popuphelp(priv.type.code, 'The change is about code');
        priv.type.doc := wgs.button(priv.type.f, 'Documentation', type='check',
			            value='documentation', relief='flat');
        wgs.popuphelp(priv.type.doc, 'The change is about ducumentation');
        priv.type.test := wgs.button(priv.type.f, 'Test', type='check',
			             value='test', relief='flat');
        wgs.popuphelp(priv.type.test, 'The change is about tests');
        priv.type.rev := wgs.button(priv.type.f, 'Review', type='check',
			            value='review', relief='flat');
        wgs.popuphelp(priv.type.rev, 'The change is about reviews');
    }

    priv.pr := [=];
    priv.pr.f := wgs.frame(priv.main, side='left', expand='x');
    priv.pr.l := wgs.label(priv.pr.f, 'Category:       ');
    wgs.popuphelp(priv.pr.l, 'Change categories; multiple can be selected');
    priv.pr.new := wgs.button(priv.pr.f, 'New', type='check',
			      value='new', relief='flat');
    wgs.popuphelp(priv.pr.new, 'A new tool or module has been created');
    priv.pr.change := wgs.button(priv.pr.f, 'Change', type='check',
			         value='change', relief='flat');
    wgs.popuphelp(priv.pr.change, 'A tool or module has been changed');
    priv.pr.bug := wgs.button(priv.pr.f, 'Bugfix', type='check',
			      value='bugfix', relief='flat');
    wgs.popuphelp(priv.pr.bug, 'A bug in a tool or module has been fixed');
    priv.pr.removed := wgs.button(priv.pr.f, 'Removed', type='check',
			          value='removed', relief='flat');
    wgs.popuphelp(priv.pr.removed, 'A tool or module has been removed');
    priv.pr.other := wgs.button(priv.pr.f, 'Other', type='check',
			        value='other', relief='flat');
    wgs.popuphelp(priv.pr.other, 'Another type of change is made');

    # Defects resolved
    priv.f1a := wgs.frame(priv.main, side='left', expand='x');
    priv.defects := [=];
    priv.defects.l := wgs.label(priv.f1a, 'Resolved defects: ');
    priv.defects.e := wgs.entry(priv.f1a, width=60);
    wgs.popuphelp(priv.defects.l,
	      'Numbers of the defects (if any) resolved by the change');
    wgs.popuphelp(priv.defects.e,
	      'Numbers of the defects (if any) resolved by the change');

    # A brief summary
    priv.f1b := wgs.frame(priv.main, side='left', expand='x');
    priv.about := [=];
    priv.about.l := wgs.label(priv.f1b, 'Brief Description:');
    priv.about.e := wgs.entry(priv.f1b, width=60);
    wgs.popuphelp(priv.about.l, 'Brief description of the change');
    wgs.popuphelp(priv.about.e, 'Brief description of the change');

    # Make the text box and scrollbar for the question
    priv.f1c := wgs.frame(priv.main, side='left', expand='x');
    priv.f1d := wgs.frame(priv.main, side='left', expand='both');
    priv.details := wgs.label(priv.f1c, 'Detailed Description');
    priv.ask := wgs.text(priv.f1d, background='white');
    wgs.popuphelp(priv.ask, 'Detailed description of the change');
    wgs.popuphelp(priv.details, 'Detailed description of the change');
    priv.vsb := wgs.scrollbar(priv.f1d);

    whenever priv.ask->yscroll do {
        priv.vsb->view($value);
    }
    whenever priv.vsb->scroll do {
        priv.ask->view($value);
    }

    priv.f2 := wgs.frame(priv.main, side='left', expand='x');
    priv.f2a := wgs.frame(priv.f2, side='left', expand='x');
    priv.f2b := wgs.frame(priv.f2, expand='x');
    priv.f2c := wgs.frame(priv.f2, side='right', expand='x');
    # Submit the question and hide
    priv.submit := wgs.button(priv.f2a, text='Submit', type='action');
    wgs.popuphelp(priv.submit, 'Submit the Change Log addition');
    priv.submit.name := 'submit';

    # Clear the text of the question
    priv.clear := wgs.button(priv.f2b, text='Clear');
    wgs.popuphelp(priv.clear, 'Clear the Detailed Description');
    whenever priv.clear->press do {
        priv.ask->delete('start', 'end');
    }

    # Cancel the operation
    priv.dismiss := wgs.button(priv.f2c, text='Cancel', type='dismiss');
    wgs.popuphelp(priv.dismiss, 'Cancel the operation');

    wgs.tk_release();

    cont := T;
    while (cont) {
	cont := F;
	await priv.submit->press, priv.dismiss->press, priv.main->killed;
	if (has_field($agent, 'name')  &&  $agent.name == 'submit') {
	    res := rec;
	    res.module := priv.mod.e->get();
	    res.who := priv.user.e->get();
	    res.date := priv.date.e->get();
	    res.defects := priv.defects.e->get();
	    res.brief := priv.about.e->get();
	    res.full := priv.ask->get ('start', 'end');
            if (rec.isdoc) {
		res.type := 'Documentation';
	    } else {
	        res.type := '';
	        if (priv.type.code->state()) {
		    res.type := paste (res.type, 'Code');
                }
	        if (priv.type.doc->state()) {
		    res.type := paste (res.type, 'Documentation');
                }
	        if (priv.type.test->state()) {
		    res.type := paste (res.type, 'Test');
		}
	        if (priv.type.rev->state()) {
		    res.type := paste (res.type, 'Review');
		}
            }
	    res.type ~:= s/^ //;
	    res.category := ''
	    if (priv.pr.new->state()) {
		res.category := paste (res.category, 'New');
            }
	    if (priv.pr.change->state()) {
		res.category := paste (res.category, 'Change');
            }
	    if (priv.pr.bug->state()) {
		res.category := paste (res.category, 'Bugfix');
            }
	    if (priv.pr.removed->state()) {
		res.category := paste (res.category, 'Removed');
            }
	    if (priv.pr.other->state()) {
		res.category := paste (res.category, 'Other');
            }
	    res.category ~:= s/^ //;
	    msg := '';
	    if (res.area ~ m/^\s*$/) {
		msg := paste (msg, '  Area', sep='\n');
	    }
	    if (res.who ~ m/^\s*$/) {
		msg := paste (msg, '  Author', sep='\n');
	    }
	    if (res.date ~ m/^\s*$/) {
		msg := paste (msg, '  Date', sep='\n');
	    }
	    if (res.type ~ m/^\s*$/) {
		msg := paste (msg, '  At least one type', sep='\n');
	    }
	    if (res.category ~ m/^\s*$/) {
		msg := paste (msg, '  At least one category', sep='\n');
	    }
	    if (res.brief ~ m/^\s*$/) {
		msg := paste (msg, '  Brief description', sep='\n');
	    }
	    if (res.full ~ m/^\s*$/) {
		msg := paste (msg, '  Full description', sep='\n');
	    }
	    if (msg != '') {
                msg := spaste('One or more fields need to be filled in', msg);
		res := [=];
		include 'choice.g';
		answer := choice (paste(msg,
					'\nDo you want to complete the form?',
					sep='\n'),
				  ['yes', 'no']);
		if (answer == 'yes'  ||  answer == 'y') {
		    res := rec;
		    cont := T;
		}
	    }
	} else {
	    res := [=];
	}
    }
    priv := F;
    return res;
}

# Put the form contents into a change log entry file.
addchangeappend := function (rec)
{
    # Remove trailing whitespace.
    # Turn version into a string.
    rec.who     ~:= s/\s+$//;
    rec.defects ~:= s/\s+$//;
    rec.brief   ~:= s/\s+$//;
    rec.full    ~:= s/\s+$//;
    v := split(rec.version, '.');
    if (len(v) > 2) {
	rec.version := paste (v[1:2], sep='.');
    }

    # The id will be filled in later by the script ac.
    # Create an entry for CHANGELOG.LAST.
    f := open ('> changelog.entry-brief');
    if (is_fail(f)) {
	fail;
    }
    write (f, '');
    write (f, 'change id: -_-chid-_-');
    write (f, spaste(' author:   ', rec.who));
    write (f, spaste(' date:     ', rec.date));
    write (f, spaste(' avers:    ', rec.version));
    write (f, spaste(' area:     ', rec.area));
    write (f, spaste(' package:  ', rec.pkg));
    write (f, spaste(' module:   ', rec.module));
    write (f, spaste(' type:     ', rec.type));
    write (f, spaste(' category: ', rec.category));
    if (len(rec.defects) > 0  &&  rec.defects != '') {
	write (f, spaste(' defects:  ', rec.defects));
    }
    write (f, spaste(' summary:  ', rec.brief));
    write (f, rec.full);
    f := F;

    # Append the change to the changelog file.
    f := open ('> changelog.entry-full');
    if (is_fail(f)) {
	fail;
    }
    write (f, '');
    write (f, '<change id=-_-chid-_->');
    write (f, paste(' <author>', rec.who, '</author>'));
    write (f, paste(' <date>', rec.date, '</date>'));
    v := split(rec.version, '.');
    if (len(v) > 2) {
	rec.version := paste (v[1:2], sep='.');
    }
    write (f, paste(' <avers>', rec.version, '</avers>'));
    write (f, paste(' <area>', rec.area, '</area>'));
    write (f, paste(' <package>', rec.pkg, '</package>'));
    write (f, paste(' <module>', rec.module, '</module>'));
    write (f, paste(' <type>', rec.type, '</type>'));
    write (f, paste(' <category>', rec.category, '</category>'));
    write (f, paste(' <defects>', rec.defects, '</defects>'));
    write (f, ' <summary>', rec.brief, ' </summary>');
    rec.full ~:= s/\s+$//;
    write (f, ' <description>', rec.full, ' </description>');
    write (f, '</change>');
    f := F;
}


addchange();
exit;
