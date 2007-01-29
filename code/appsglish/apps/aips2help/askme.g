# askme: glish closure object for the ask function
# Copyright (C) 1999,2000,2001,2002,2003
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
# $Id: askme.g,v 19.1 2004/08/25 00:54:01 cvsmgr Exp $

include "sysinfo.g"
include "aipsrc.g"
include "widgetserver.g"

include "popuphelp.g"
include "guiframework.g"
include "infowindow.g"
#include "choicewindow.g"

pragma include once

askme_g_included := 'yes';

  #
  # The ask gui.  Probably ought to be combined with bug (since it uses
  # the same general interface)
  #
  # events handled: map, unmap, destroy (or should it be killed)
  #
askme := subsequence(bug=F, register=F, e2ebug=F)
{
  public := [=];
  priv   := [=];

  priv.bug := bug;
  priv.register := register;
  priv.e2ebug := e2ebug;

    #Initialization function - load all the standard stuff
  priv.init := function(){
       # all of these should probably be defined using os.g
    wider priv;
    priv.user := [=];
    if(!getrc.find(priv.user.email, 'user.info.email')){
       if(!getrc.find(priv.user.email, 'userinfo.email')){
          priv.user.email := shell('echo $LOGNAME@$DOMAIN');
       }
    }
    if(!getrc.find(priv.user.contact, 'system.local.contact')){
       priv.user.contact := priv.user.email;
    }
    priv.user.fcom := shell('getuinfo $LOGNAME');
    if(!priv.user.fcom::status){
       if(!getrc.find(priv.user.who, 'user.info.name')){
          if(!getrc.find(priv.user.who, 'userinfo.name')){
          # if $LOGNAME isn't define either the following ensures that
          # the who field just contains the empty string
	     if (len(priv.user.fcom) > 1) {
	        priv.user.fcom := priv.user.fcom[1];
             }              
	     priv.user.fcom ~:= s/,.*$//;
	     priv.user.who := priv.user.fcom ~ s/(  |\t).*//;
          }
       }
    } else {
      priv.user.who := '';
    }
    priv.self := self;
    if(!getrc.find(priv.user.org, 'user.info.org')){
       if(!getrc.find(priv.user.org, 'userinfo.org')){
          priv.user.org := '';
       }
    }
    if(!getrc.find(priv.user.group, 'user.info.group')){
       if(!getrc.find(priv.user.group, 'userinfo.group')){
          a1 := split(drc.aipssite(), "/");
          priv.user.group := a1[len(a1)];;
       }
    }
    priv.user.sysinfo := sysinfo();
    priv.user.sysinfo.version(formatted=form,  dolog=F);
    priv.user.version := spaste(form);
    priv.user.version := paste(priv.user.version, priv.user.sysinfo.arch());
    priv.user.os := shell('uname -sr');
    
  } # priv.init

    # Create the frames, entry widgets, etc...
  priv.createGUI := function() {
     wider priv;
     if(priv.bug) 
        priv.title := 'Report a Problem/Request an Enhancement to AIPS++';
     else if(priv.register) 
        priv.title := 'Register AIPS++';
     else if(priv.e2ebug) 
        priv.title := 'Report a Problem/Request an Enhancement to NRAO-E2E';
     else
        priv.title := 'Ask an AIPS++ Expert';
#
     priv.main := dws.frame(title=priv.title);
     priv.f1z := dws.frame(priv.main, relief='ridge', expand='x');
     priv.f := dws.frame(priv.f1z, side='left',height=30, expand='x')
     priv.f0 := dws.frame(priv.f1z, expand='x', height=10);
     priv.f1 := dws.frame(priv.f1z, side='left', expand='x', height=30);
#
     priv.userID := [=];
     priv.userID.f := dws.frame(priv.f, side='left',height=30)
     priv.userID.l1 := dws.label(priv.userID.f, 'Name');
     priv.userID.e := dws.entry(priv.userID.f, width=30);
     priv.userID.e->insert(priv.user.who);
     priv.userID.help := popuphelp(priv.userID.e, 'Your name');
#
     priv.email := [=];
     priv.email.f := dws.frame(priv.f, side='left', expand='x', height=30);
     priv.email.l := dws.label(priv.email.f, 'Email');
     priv.email.e := dws.entry(priv.email.f, width=30);
     if(priv.register)
        priv.email.e->insert(priv.user.contact);
     else 
        priv.email.e->insert(priv.user.email);
     priv.email.help := popuphelp(priv.email.e, 'Your email address');
#
     priv.n := dws.frame(priv.f1z, side='left', height=30)
     priv.org := [=];
     priv.org.f := dws.frame(priv.n, side='left', expand='x', height=30);
     priv.org.l := dws.label(priv.org.f, 'Organization');
     priv.org.e := dws.entry(priv.org.f, width=20);
     priv.org.e->insert(priv.user.org);
     priv.org.help := popuphelp(priv.org.e, 'Name of your organization');
#
     priv.group := [=];
     priv.group.f := dws.frame(priv.n, side='left', expand='x', height=30); 
     priv.group.l := dws.label(priv.group.f, 'Site');
     priv.group.e := dws.entry(priv.group.f, width=20);
     priv.group.e->insert(priv.user.group);
     priv.group.help := popuphelp(priv.group.e, 'Name of your AIPS++ site');
#
     priv.f4 := dws.frame(priv.f1z, side='left', expand='x', height=30);
     priv.ver := [=];
     priv.ver.f := dws.frame(priv.f4, side='left', expand='x', height=30);
     priv.ver.l := dws.label(priv.ver.f, 'AIPS++ Version');
     priv.ver.e := dws.entry(priv.ver.f, width=23);
     priv.ver.e->insert(priv.user.version);
     priv.ver.help := popuphelp(priv.ver.e, 'Version of AIPS++ you are running');
#
     priv.os := [=];
     priv.os.f := dws.frame(priv.f4, side='right', expand='x', height=30);
     priv.os.e := dws.entry(priv.os.f, width=10);
     priv.os.l := dws.label(priv.os.f, 'Operating System');
     priv.os.e->insert(priv.user.os);
     priv.os.help := popuphelp(priv.os.e, 'Version of OS you are running (uname -sr)');
#
     priv.f1 := dws.frame(priv.main, expand='both', relief='ridge');
#
     priv.cc := [=];
     priv.cc.f := dws.frame(priv.f1z, side='right', expand='x', height=30);
     priv.cc.bn := dws.button(priv.cc.f, text='No', type='radio');
     priv.cc.by := dws.button(priv.cc.f, text='Yes', type='radio');
     priv.cc.l := dws.label(priv.cc.f, 'Copy to myself');
     priv.cc.by->state(T);
     priv.cc.help := popuphelp(priv.cc.f, 'Send me a copy');
#
     priv.f1sa := dws.frame(priv.f1, side='left', expand='x', height=10);
     if(priv.bug || priv.e2ebug){
        priv.f1a := dws.frame(priv.f1, expand='x', height=30);
        priv.f1sb := dws.frame(priv.f1, side='left', expand='x', height=10);
     }
     priv.f1b := dws.frame(priv.f1, side='left', expand='x', height=30);
     priv.f1c := dws.frame(priv.f1, side='left', expand='x');
     priv.f1d := dws.frame(priv.f1, side='left', expand='both');

     priv.f2 := dws.frame(priv.main, side='left', expand='x');
     priv.f2a := dws.frame(priv.f2, side='left', expand='x');
     priv.f2b := dws.frame(priv.f2, expand='x');
     priv.f2c := dws.frame(priv.f2, side='right', expand='x');

       # A brief summary
     priv.about := [=];
     priv.about.l := dws.label(priv.f1b, 'Brief Description:');
     priv.about.e := dws.entry(priv.f1b);
     if(priv.register){
        priv.about.e->insert('AIPS++ Registration');
        priv.about.help := popuphelp(priv.about.e, 'Brief description of your AIPS++ site');
     } else if(priv.bug || priv.e2ebug){
        # priv.about.e->insert('AIPS++ Bug Report');
        priv.about.help := popuphelp(priv.about.e, 'Brief description of your problem');
     } else {
        # priv.about.e->insert('AIPS++ question');
        priv.about.help := popuphelp(priv.about.e, 'Brief description of your question');
     }

        # Here we add some fields needed for bug reporting;
     if(priv.bug || priv.e2ebug){
          
        priv.f5 := dws.frame(priv.f1a, side='left', expand='x', height=30);

        priv.pr := dws.frame(priv.f5, side='left', expand='x', height=30);
        priv.pr.bug := dws.button(priv.pr, 'Problem', type='radio',
                                  value='problem', relief='flat');
        priv.pr.enhancement := dws.button(priv.pr, 'Enhancement', type='radio',
                                          value='enhancement', relief='flat');
        priv.pr.help := popuphelp(priv.pr,
                                 'Problem or enhancement?');
        priv.pr.bug->state(T);
  
        priv.f6 := dws.frame(priv.f1a, side='left', expand='x', height=30);
        priv.severe := dws.frame(priv.f6, side='left', expand='x', height=30);
        priv.severe.catastrophic := dws.button(priv.severe, 'Catastrophic',
                                           type='radio', value='catastrophic',
                                           relief='flat');
        priv.severe.critical := dws.button(priv.severe, 'Critical', type='radio',
                                       value='critical', relief='flat');
        priv.severe.serious := dws.button(priv.severe, 'Serious', type='radio',
                                       value='serious', relief='flat');
        priv.severe.not2bad := dws.button(priv.severe, 'Non-serious',
                                 type='radio', value='not2bad', relief='flat');
        priv.severe.cosmetic := dws.button(priv.severe, 'Cosmetic',
                                 type='radio', value='trivial', relief='flat');
        priv.severe.critical->state(T);
        priv.severe.text := '2';
        priv.severe.help := popuphelp(priv.severe,
                                 'How bad is the problem?');

        priv.severe.catastrophic.help := popuphelp(priv.severe.catastrophic,
                                   'i.e. system crash or lost user data');
        priv.severe.critical.help := popuphelp(priv.severe.critical,
                                   'i.e. can\'t use major product function');
        priv.severe.serious.help := popuphelp(priv.severe.serious,
                                   'i.e. your data must be modified to work');
        priv.severe.not2bad.help := popuphelp(priv.severe.not2bad,
                                   'i.e. error messages aren\'t very clear ');
        priv.severe.cosmetic.help := popuphelp(priv.severe.cosmetic,
                                   'i.e. bad layout or misuse of grammar in manual');

        priv.f7 := dws.frame(priv.f1a, side='left', expand='x', height=30);
        priv.tool := dws.frame(priv.f7, side='left', expand='x', height=30);
        priv.tool.label := dws.label(priv.tool, 'Tool');
        priv.tool.entry := dws.entry(priv.tool, width=30);
        priv.tool.help := popuphelp(priv.tool.entry,
                                 'Name of tool you were using (blank is OK)');
        priv.fun := dws.frame(priv.f7, side='left', expand='x', height=30);
        priv.fun.label := dws.label(priv.fun, 'Function');
        priv.fun.entry := dws.entry(priv.fun, width=30);
        priv.fun.help := popuphelp(priv.fun.entry, 
                             'Name of function you were using (blank is OK)');


        whenever priv.severe.catastrophic->press do {
           priv.severe.catastrophic->state(T);
           priv.severe.text := '1';
        }

        whenever priv.severe.critical->press do {
           priv.severe.critical->state(T);
           priv.severe.text := '2';
        }

        whenever priv.severe.serious->press do {
           priv.severe.serious->state(T);
           priv.severe.text := '3';
        }

        whenever priv.severe.not2bad->press do {
           priv.severe.not2bad->state(T);
           priv.severe.text := '4';
        }

        whenever priv.severe.cosmetic->press do {
           priv.severe.cosmetic->state(T);
           priv.severe.text := '5';
        }

     }

#
       # Drive the browser to the FAQ
     priv.faq := dws.button(priv.f1b, text='Check FAQ');
     priv.faq.help := popuphelp(priv.faq,
                                   'Drive your browser to the AIPS++ FAQ');
     whenever priv.faq->press do {
        faq();
     }
#   
       # Make the text box and scrollbar for the question
     if(priv.register){
        priv.details := dws.label(priv.f1c, 'Comments about registration');
     } else {
        priv.details := dws.label(priv.f1c, 'Detailed Description');
     }
     priv.ask := dws.text(priv.f1d, background='white');
     if(priv.register){
     } else {
          priv.ask.help := popuphelp(priv.ask,
                                   'Comments about installing AIPS++');
       if(priv.bug || priv.e2ebug){
helpstring1:= 'HOW TO SUBMIT AN EFFECTIVE DEFECT \n \n These guidelines will help to make sure that we can\n address submitted defects as effectively and efficiently\n as possible. The important parts of submitting an\n effective defect are:\n \n';
helpstring2:= '1) Use bug() from the AIPS++ command line to ensure\n that system and build information are automatically\n recorded.\n \n';
helpstring3:=' 2) Provide sufficient information to allow a developer to be\n able to reproduce the defect fully on another system.\n This includes Glish scripts to capture the defect, and\n ftp locations where we can download the datasets involved.\n \n';
helpstring4:= '3) Try to rule out configuration problems, such as build\n failures, by running the script on another release or\n AIPS++ system. Include any further diagnostic information\n that will help to classify the defect.\n \n '; 
helpstring5:=' 4) Remember that a professional collegue will read the \n defect; write a defect in language you would personally be comfortable receiving.  \n ';
	bighelp:=spaste(helpstring1,helpstring2,helpstring3,helpstring4,helpstring5);
          priv.ask.help := popuphelp(priv.ask,bighelp);
       } else {
          priv.ask.help := popuphelp(priv.ask,
                                   'Detailed description of your question');
       }
     }
     priv.vsb := dws.scrollbar(priv.f1d);

     whenever priv.ask->yscroll do {
        priv.vsb->view($value);
     }

     whenever priv.vsb->scroll do {
        priv.ask->view($value);
     }
#
#
        # Submit the question and hide
     priv.submit := dws.button(priv.f2a, text='Submit', type='action');
     if(priv.register){
           priv.submit.help := popuphelp(priv.submit,
                                  'Submit AIPS++ registration');
     } else {
        if(priv.bug){
           priv.submit.help := popuphelp(priv.submit,
                                  'Submit the Problem report to AIPS++');
        } else if(priv.e2ebug){
           priv.submit.help := popuphelp(priv.submit,
                                  'Submit the Problem report to NRAO-E2E');
        } else {
           priv.submit.help := popuphelp(priv.submit,
                                  'Submit the question to an AIPS++ expert');
        }
     }
     whenever priv.submit->press do {
        priv.main->cursor('watch')
        priv.main->disable()
        if(priv.sendquery()){
           priv.main->enable()
           priv.main->cursor('left_ptr')
           priv.main->unmap();
           priv.self->submitted(T);
        } else {
           priv.main->enable()
           priv.main->cursor('left_ptr')
        }
     }
#
        # Clear the text of the question
     priv.clear := dws.button(priv.f2b, text='Clear');
     priv.clear.help := popuphelp(priv.clear,
                                  'Clear the Brief and Detailed Descriptions');
     whenever priv.clear->press do {
        priv.ask->delete('start', 'end');
        priv.about.e->delete('start', 'end');
        if(priv.bug || priv.e2ebug){
           priv.tool.entry->delete('start', 'end');
           priv.fun.entry->delete('start', 'end');
        }
     }
#
        # Hide the window
     priv.dismiss := dws.button(priv.f2c, text='Dismiss', type='dismiss');
     priv.dismiss.help := popuphelp(priv.dismiss,
                                  'Hide this window');
     whenever priv.dismiss->press do {
        priv.main->unmap();
     }

        # Handle the event if the main window is killed by the window manager
     whenever priv.main->killed do {
        priv.main := 0;
     }
#include 'findfails.g'
#findfails(priv)
  } # priv.createGUI

     # Collect the info and send the question to the appropriate folks
  priv.sendquery := function(){
    wider priv;
    email := priv.email.e->get()
    if(priv.register)
       priv.user.contact := email;
    subject := priv.about.e->get();
    question := priv.ask->get('start', 'end')
    os := priv.os.e->get();
    os := os ~ s/ *//;
    org := priv.org.e->get();
    org := org ~ s/ *//;
    group := priv.group.e->get();
    group := group ~ s/ *//;
    version := priv.ver.e->get();
    version := version ~ s/ *//;
    name := priv.userID.e->get();

    priv.sendIt := T;
    if(priv.register){
       warningMessage := 'The following fields are need to register:';
    } else {
       warningMessage := 'The following fields are needed to submit:';
    }
    if(!(strlen(email))){
       warningMessage := spaste(warningMessage, '\n\tE-mail address');
       priv.sendIt := F;
    } else {
       if(!(email ~ m/\w+@\w+\.\w+/)){
          warningMessage := spaste(warningMessage, '\n\tBad E-mail address: ', email, '?');
          priv.sendIt := F;
       }
    }
    if(!(strlen(subject))){
       warningMessage := spaste(warningMessage, '\n\tBrief description');
       priv.sendIt := F;
    }
    if(!priv.register && !(sum(strlen(split(question))))){
       warningMessage := spaste(warningMessage, '\n\tDetailed description');
       priv.sendIt := F;
    }

    if(!(strlen(group)) && priv.register){
       warningMessage := spaste(warningMessage, '\n\tGroup (use none if none)');
       priv.sendIt := F;
    }
    if(!(strlen(os)) && priv.register){
       warningMessage := spaste(warningMessage, '\n\tOperating System');
       priv.sendIt := F;
    }
    if(!(strlen(org)) && priv.register){
       warningMessage := spaste(warningMessage, '\n\tOrganization');
       priv.sendIt := F;
    }
    if(!(strlen(version)) && priv.register){
       warningMessage := spaste(warningMessage, '\n\tAIPS++ version');
       priv.sendIt := F;
    }
    if(!priv.sendIt){
       mb := infowindow(warningMessage, paste('Info for: ', priv.title),
                        selfdestruct=T);
       note(warningMessage);
    }
    if(priv.sendIt){
       if((priv.bug || priv.e2ebug) || !priv.register){
          towhom := 'ddts@aoc.nrao.edu'
          aipsCentre := priv.getCentre();
          if(!priv.bug){
             # If no one is specified send it to the help desk
             localhelp := 'aips2-help@aoc.nrao.edu';
             if(getrc.find(tmp, 'system.local.contact')){
               localhelp := tmp;
             }
             towhom := paste(localhelp, towhom);
             severity := '3';
             theTool := 'Question';
             theFun := 'Question';
          } else {
             severity := priv.severe.text;
             isEnhancement := 'N';
             if(priv.pr.enhancement->state()){
                isEnhancement := 'Y';
             }
             theTool := priv.tool.entry->get();
             theFun := priv.fun.entry->get();
          }
          isShowStopper := 'N';
          phone := 'none';
          theBadOne := 'Unknown';
          include "measures.g"
          dummy := dq.time(dm.epoch('utc', 'today').m0, form='ymd');
          timestamp := as_string(as_byte(dummy)[[3,4,6,7,9,10]]);
          submitterid := split(email, '@')[1];
          question := question ~ s/\n/\n /g
          if(strlen(group)){
             org := paste(org, '-', group);
          }
          helpRequest := spaste('Subject: ', subject,
                         '\nTo: ', towhom,
                         '\nReply-to: ', email,
                         '\nProject: ',  aipsCentre.project,
                         '\nClass: ', aipsCentre.class,
                         '\nSoftware: AIPS++',
                         '\nVersion: ', version,
                         '\nShowstopper: ', isShowStopper,
                         '\nEnclosure-count: 1',
                         '\nCR_platform: ',
                         '\nHeadline: ', subject,
                         '\nHow-found: customer use',
                         '\nWhen-found: post-release',
                         '\nSeverity: ', severity,
                         '\nOS-version: ', os,
                         '\nSubmitter-name: ', name,
                         '\nSubmitter-org: ', org,
                         '\nSubmitter-phone: ', phone,
                         '\nSubmitter-id: bug',
                         '\nSubmitter-mail: ', email,
                         '\nEnhancement: ', isEnhancement,
                         '\nStatus: S', 
                         '\nTest-name: ', spaste(theTool, '.', theFun),
                         '\nTest-system: ', sysinfo().host(),
                         '\nNotify-submitter: N', 
                         '\nType: ALLOCATE',
                         '\nTimestamp: 1',
                         '\nHistory::::',
                         '\n bugs ', timestamp,' 000000 Submitted to ',
                         'problems by ', email,
                         '\nUpdated-by: x',
                         '\nRelated-file::Added ', timestamp,
                           ' by ', submitterid, '::CR_Description',
                         '\n ', question,
                         '\nSubmitted-on: ', timestamp,
                         '\nLast-mod: ', timestamp,
                         '\nDDTs-mail-to: AOCso ddts@aoc.nrao.edu',
                         '\nDDTs-mail-from: ANYon customer@nowhere');
       } else if(priv.register){
             towhom := 'aips2-register@aoc.nrao.edu';
             helpRequest := spaste( 'Subject: ', subject,
                         '\n>Category: Registration',
                         '\n>Synopsis: ', subject,
                         '\n>Confidential: no',
                         '\n>Priority: low',
                         '\n>Class: registration',
                         '\n>Originator: ', name,
                         '\n>Organization: ', org,
                         '\n>Group: ', group,
                         '\n>Reply-to: ', email,
                         '\n>Release: ', version,
                         '\n>Environment: ', os,
                         '\n>Description: \n', question, '\n',
                         '\nglish system: \n', as_string(system));
       }
       if(is_string(towhom)){
          theMessage := '';
          a := 0;
          metoo := email;
          if(priv.cc.bn->state()){
             metoo := '';
          }
          #cw := choicewindow("Send", "Yes No");
          #print cw;
          a := dos.mail(helpRequest, towhom, subject=subject, cc=metoo);
             # If mail failed, note it.
          #print helpRequest;
          if(is_fail(a)){
             theMessage := paste('Unable to send question to', towhom);
             theMessage := paste(theMessage, '\nAbout', subject);
             theMessage := paste(theMessage, '\n', question);
             priv.sendIt := F;
          } else {
             if(!priv.register){
                if(priv.bug || priv.e2ebug){
                   theMessage := paste('Your problem about ', subject,
                                       ' has been sent.');
                } else {
                   theMessage := paste('Your question about ', subject,
                                       ' has been sent.');
                }
             } else {
                   theMessage := 'You have successfully registered AIPS++!';
               
             }
          }
       }
       if(strlen(theMessage)){
          mb := infowindow(theMessage, paste('Info for: ', priv.title), selfdestruct=T);
          note(theMessage);
       }
    }
    return priv.sendIt;
  } # priv.sendquery

     # We only work if we have a GUI.
  if(have_gui()){ 
     tk_hold();
     ok := priv.init();
     if (is_fail(ok)) fail;
     ok := priv.createGUI();
     if (is_fail(ok)) fail;
     tk_release();

        # Handle some common events
     whenever self->map do {
        if(is_agent(priv.main)){
           priv.main->map();
        } else {
           tk_hold();
           priv.createGUI();
           tk_release();
        }
     }

     whenever self->unmap do {
        priv.main->unmap();
     }


     whenever self->destroy, self->killed do {
        priv.main := 0;
     }

     whenever self->getOS do {
        self->getOS(priv.user.sysinfo.arch())
     }

     whenever self->getContact do {
        self->getContact(priv.user.contact);
     }

  } else { 
     fail 'askme needs to be run from a graphic user interface';
  }

  # Get the local AIPS++ centre based on either an aipsrc or maybe 
  # some other email rule.

  priv.getCentre := function(){
     aipscentre := [=];
     if(priv.e2ebug){
        aipscentre.class := 'end-to-end'
        aipscentre.project := 'calibrator';
     } else {
        aipscentre.project := 'aips2-namerica';
        if(getrc.find(tmp, 'system.aipscentre')){
            aipscentre.project := tmp;
        } else if(getrc.find(tmp, 'system.aipscenter')){ 
            aipscentre.project := tmp;
        } else {
            aipscentre.project := 'aips2-namerica';
        }
        if(aipscentre.project == 'aips2-namerica' || aipscentre.project == 'namerica'){
           aipscentre.project := 'aips2-namerica'
           aipscentre.class := 'namerica'
        } else if(aipscentre.project == 'aips2-europe' || aipscentre.project == 'europe') {
           aipscentre.project := 'aips2-europe'
           aipscentre.class := 'europe'
        } else if(aipscentre.project == 'aips2-oz' || aipscentre.project == 'australia') {
           aipscentre.project := 'aips2-oz'
           aipscentre.class := 'australia'
        } else {
           aipscentre.project := 'aips2-namerica'
           aipscentre.class := 'namerica'
        }
     }
     return aipscentre;
  }
} # End the subsequence

  # The ask function itself, hangs around after a question has been asked 
  # mapping and unmapping itself as neede.

_askme := F;
_bugform := F;

const ask := function(){
   global _askme;
   if(is_defined('_askme') && is_agent(_askme)){
      _askme->map();
   } else {
      _askme := askme();
   }
   return T; Gnats
}

   # The faq function, drives the browser to the FAQ page
const faq := function() {
   include "aips2help.g";
   if(getrc.find(tmp, 'help.server')){
      myserver := tmp;
   } else {
      myserver := 'file:';
   }
   if(getrc.find(tmp, 'help.directory')){
      mydir := tmp;
   } else {
      include 'aipsrc.g'
      mydir := drc.aipsroot();
   }
   help(spaste(myserver, mydir, '/docs/faq/faq.html'));
}

const e2ebug := function(){
   global _e2e_bugform;
   if(is_defined('_e2e_bugform') && is_agent(_e2e_bugform)){
      _e2e_bugform->map();
   } else {
      _e2e_bugform := askme(e2ebug=T);
   }
   return T;
  }

const ddtsbug := function(){
   global _bugform;
   if(is_defined('_bugform') && is_agent(_bugform)){
      _bugform->map();
   } else {
      _bugform := askme(bug=T);
   }
   return T;
  }

const knownbugs := function(look4=F){
  if(is_boolean(look4)){
     webPage :=
     'http://aips2.nrao.edu/docs/html/navpages/communicate/ddtstrackabug.html';
  } else {
     webPage := 'http://aips2.nrao.edu/ddts/ddts_main?LastForm=FormQuery&REMOTE_USER=nobody&GenerateAndRun=Run&Status=R&StatusOperator=notequal&Conjunction=%26%26&Test_nameOperator=has&Test_name=';
     webPage := spaste(webPage, look4);
  }
  help(webPage);
}

const register := function(force=F){
   include "aipsrc.g";
   register := F;
   if(is_fail(dos) || is_fail(drc)){
      print "Something is terribly wrong with your aips++ installation."
   } else {
      if(!getrc.find(tmp, 'system.local.registered') || force){
         register := askme(register=T);
      } else {
         if(tmp != sysinfo().arch()){
            register := askme(register=T);
         }
      }
      if(is_agent(register)){
         whenever register->submitted do {
            os := register->getOS();
            contact := register->getContact();
            if(strlen(tmp)){
               arcRegistered :=  paste('system.local.registered:', tmp, os);
               arcContact := paste('system.local.contact:', contact);
            } else {
               arcRegistered :=  paste('system.local.registered:', os);
               arcContact := paste('system.local.contact:', contact);
            }
            # Now go looking for an aipsrc file to update
            arfiles[1] := spaste(drc.aipsroot(), '/.aipsrc');
            arfiles[2] := spaste(drc.aipsarch(), '/aipsrc');
            arfiles[3] := spaste(drc.aipssite(), '/aipsrc');
            arfiles[4] := '~/.aipsrc';

            for(i in 1:len(arfiles)){
               r := dsh.command(paste('grep system.local.registered',
                                arfiles[i]));
               hasRegistered := len(r.lines) > 0;
               r := dsh.command(paste('grep system.local.contact',
                                arfiles[i]));
               hasContact := len(r.lines) > 0;

               if(!hasRegistered && !hasContact){
                  fp := open( [">>", arfiles[i]]);
                  if(!is_fail(fp)){
                     write(fp, arcRegistered);
                     write(fp, arcContact);
                     break;
                  }
                } else {
                   lCount := 1;
                   fpi := open([ "<", arfiles[i]])
                   if(!is_fail(fpi)){
                      while(lines[lCount] := read(fpi)){
                         lCount +:= 1;
                       }
                       fp := open([">",arfiles[i]]);
                       if(!is_fail(fp)){
                          for(lCount in 1:len(lines)){
                             if(hasRegistered && lines[lCount] ~ m/system.local.registered/){
                                lines[lCount] := arcRegistered;
                             }
                             if(hasContact && lines[lCount] ~ m/system.local.contact/){
                                lines[lCount] := arcContact;
                             }
                             write(fp, lines[lCount] ~ s/\n//);
                             lCount +:= 1;
                          }
                          if(!hasRegistered)
                             write(fp, arcRegistered);
                          if(!hasContact)
                             write(fp, arcContact);
                          break;
                       }
                       break;
                   }
                }
            }
         }
      }
   }
}

# This is the hook for access to bug() from aips++init.g
const _int_bug := ddtsbug

if ( ! is_defined( 'bug' ) ) {
    # To avoid some error messages about ddtsbug not being defined.
    const bug := ddtsbug;
}
