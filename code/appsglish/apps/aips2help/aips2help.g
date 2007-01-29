#
#   Copyright (C) 1996,1997,1998,1999,2000,2002,2003
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
#          Postal address: AIPS++/ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#   $Id: aips2help.g,v 19.1 2004/08/25 00:53:51 cvsmgr Exp $
#

pragma include once;

include "os.g";
include "note.g"

const web := function() { 
  help(help::current.URL);
  return T;
}

# Uninitialized, will self-init on first help
helpsystem := F

const help := function(_what='missing',
		       browser=helpsystem::browser,
		       server=helpsystem::server)
{ 
  global helpsystem;
  
  # Initialize the help system if necessary
  if (!is_record(helpsystem)) {
    global helpsystem;
    # Need to get browser and server from aipsrc file.
    # use getrc to avoid recursive dependencies
    include "getrc.g";
    local dfltbrowser;
    local dfltserver;
    local docsroot;
    if(!getrc.find(dfltbrowser, 'help.browser')) dfltbrowser := 'netscape';
    if(!getrc.find(dfltserver, 'help.server')) dfltserver := 'file:';
    if(!getrc.find(docsroot, 'help.directory')) docsroot := F;

    helpsystem := showhelp(dfltbrowser, dfltserver, docsroot);

    # Call help again with the right server and browser
    if (!is_string(browser)) browser := helpsystem::browser;
    if (!is_string(server)) server := helpsystem::server;
    return help(_what, browser, server);
  }


  if(is_string(_what) && _what != 'missing'){
     if(helpsystem.usebrowser()){
        helpsystem.browse(_what, browser, server);
     }
  } else {
     if(!is_string(_what)){
        print ;
        print '\tWe\'re currently unable to parse your help request. Please provide';
        print '\tthe argument to help as a string i.e. in \'\'s. Thanks.\n';
     } else {
     print 'Please provide an argument to help.  If you type\n';
     print ' help(\'general\')';
     print '\twill summarize the modules available in the general package.';
     print '\tOther packages available are utility, synthesis and nrao. You may also';
     print '\tsupply a function, object, or module name in place of aips and';
     print '\thave help about that argument printed.';
     print '\n';
     print ' help(\'Refman:\')';
     print '\tit will give you the WWW address and drive your WWW browser';
     print '\tto the AIPS++ User\'s Reference Manual';
     print '\n';
     print ' help(\'Glish:\')';
     print '\twill give you the WWW address manual and drive your WWW browser';
     print '\tto the Glish User Manual.\n';
     }
  }
}

help::pkg := [=];
help::atoms := [];

help::current := [=];
help::current.package := 'general';
help::current.module := '*';
help::current.object := '';
help::current.URL := 'Refman:';


showhelp := function(browser='netscape', server='file:', docsroot=F)
{

  self := [=];


  self.note := function(...) {
    msg := "";
    for (i in 1:num_args(...)) {
      msg := spaste(msg, as_string(nth_arg(i, ...)));
    }
    
    note(msg);
  }
  global help;

  doInitializationMessage := F;
  if(length(help::pkg) == 0){
    doInitializationMessage := T;
    self.note('Initializing help system...');
  }
  
  
  helpPackages := 'alma dish atnf bima general nfra nrao synthesis utility display';
  #
  # At some point we may want to limit help packages 
  #drc.find(helpPackages, 'system.packages', def=helpPackages);
  for (package in split(helpPackages)) {
    if(!has_field(help::pkg, package)) {
      help::pkg[package] := F;
      include "finclude.g";
      dfi.include(help::pkg[package],
		  spaste('atoms', package, '.g'),
		  spaste('atoms', package, '.gc'));
    }
  }

  public := [=];
  public::cached := [=];      # Holds the cached manuals and nodes
#public::manuals              Holds the fully qualified manual names
  public::loaded := F;        # Flag to tell wheather to find the manual names
  public::browser := F;       # What browser to use
  public::server := F;        # What server to use
  public::docsroot := docsroot;

  volumes := [=];
  volumes.refman := 'Refman:';
  volumes.display := 'Display:';
  volumes.dish := 'Dish:';
  volumes.synthesis := 'SynthesisRef:';
  volumes.utility := 'Utility:';
  volumes.general := 'General:';
  volumes.alma := 'ALMA:';
  volumes.atnf := 'ATNF:';
  volumes.bima := 'BIMA:';
  volumes.nfra := 'NFRA:';
  volumes.nrao := 'NRAO:';
  
  
  # Initialize help.  Find the fully qualified path names of the manuals
  
  self.initialize := function(browser, server)
  { wider public;
    if(!public::loaded){
      aipspath := environ.AIPSPATH;
      if(is_boolean(public::docsroot)){
        docsroot := split(aipspath);
        public::docsroot := docsroot[1];
      }
      #findcommand := spaste( 'find ', docsroot[1],
      #'/docs -name labels.pl -print');
      mans := open(spaste('<', public::docsroot,'/docs/aips/labels4help.txt'));
      if(!is_fail(mans)){
        i := 1;
        while(<mans>){
	  public::manuals[i] := _;
	  i := i+1;
        }
        for(i in 1:len(public::manuals))
	    public::manuals[i] := spaste(public::docsroot, '/', public::manuals[i]);
      } else {
	public::manuals := 0;
      }
      public::loaded := T;
      public::searchPage := spaste(public::docsroot, '/docs/search/search.html');
    }
    public::browser := browser;
    public::server := server;
    self.mkvec();
  }
  
  #  Collect all the help atoms and put them into help::atoms attribute
  
  self.mkvec := function(){
    global help;
    packages := field_names(help::pkg);
    alltext := '';
    i := 1;
    for(package in packages){
      modules := field_names(help::pkg[package]);
      alltext := paste(alltext, package);
      for(module in modules){
	text := paste(package, module, sep='.');
	alltext := paste(alltext, text);
	for(fun in field_names(help::pkg[package][module].funs)){
	  text := paste(package, module, fun, sep='.');
	  alltext := paste(alltext, text);
	}
	for(obj in field_names(help::pkg[package][module].objs)){
	  text := paste(package, module, obj,  sep='.');
	  alltext := paste(alltext, text);
            # need to add explicit constructor/funtion to the atoms list
            # so we don't confuse the two.
	  if(has_field(help::pkg[package][module].objs[obj], 'c')){
	    for(met in field_names(help::pkg[package][module].objs[obj].c)){
	      #text := paste(package, module, obj, met, sep='.');
	      #alltext := paste(alltext, text);
	      text := paste(package, module, obj, met, 'constructor', sep='.');
	      alltext := paste(alltext, text);
	    }
	  }
	  if(has_field(help::pkg[package][module].objs[obj], 'm')){
	    for(met in field_names(help::pkg[package][module].objs[obj].m)){
	      #text := paste(package, module, obj, met, sep='.');
	      #alltext := paste(alltext, text);
	      text := paste(package, module, obj, met, 'function', sep='.');
	      alltext := paste(alltext, text);
	    }
          }
	}
      }
    }
    help::atoms := split(alltext);
  }
  
  # Does help on the command line
  
  self.clHelp := function(look4what, findFirstURL=F){
    global help;
    helpMsg := '';
    looking4 := split(look4what, ".");
    
    # print 'self.clHelp: ',look4what;
    # Convert * to regular expressions
    
    daBytes := as_byte(look4what);
    
    # Form the permutations if we're not searching the entire DB
    
    if(daBytes[1] != as_byte('*')){
      ss := '';
      if(len(looking4) == 1){
	ss1 := paste(help::current.package, help::current.module,
		     help::current.object, look4what, sep='\\..');
	ss2 := paste(help::current.package, help::current.module,
		     look4what, sep='\\..');
	ss3 := paste(help::current.package, look4what, sep='\\..');
	ss4 := look4what;
	ss := paste(ss1, ss2, ss3, ss4)
	  }
      if(len(looking4) == 2){
	ss1 := paste(help::current.package,
		     help::current.module, look4what, sep='\\..');
	ss2 := paste(help::current.package, look4what, sep='\\..');
	ss3 := look4what;
	ss := paste(ss1, ss2, ss3)
	    help::current.object := '*'
	      }
      if(len(looking4) == 3){
	ss1 := paste(help::current.package, look4what, sep='\\..');
	ss2 := look4what;
	ss := paste(ss1, ss2)
            help::current.module := '*'
	      }
      if(len(looking4) == 4){
	 ss := look4what;
	 help::current.package := '*'
      }
      if( len(looking4) == 5){
	 ss := look4what;
	 help::current.package := '*'
      }
      searchString := split(ss);
    } else {
      searchString := spaste('.',look4what);
    }
    for(i in 1:len(searchString)){
      # print 'clHelp: ',searchString[i];
      hitFlags := help::atoms ~ eval(spaste('m/',searchString[i],'/'));
      hits := help::atoms[hitFlags];
      if(len(hits) > 0){
        dum := hits ~ eval(spaste('m/',searchString[i], '$/'));
	if(any(dum)){
	  hits := hits[dum];
	}
	break;
      }
    }
    if(len(hits) == 0){
      helpMsg := spaste(helpMsg, '\nSorry no help available for ', look4what,
			'\n');
      helpMsg := spaste(helpMsg, '\nYou might try searching for ', look4what,
			' using the AIPS++ search page.\n\n   web()\n\n will drive your browser there.\n');
      help::current.URL := 'Not Found';
    } else if(len(hits) == 1) {
      # print 'clHelp: ', hits;
      helpMsg := self.printHelp(hits)
	  return helpMsg;
      break;
    } else {
      if(len(hits) == 2){
         if(hits[1] == hits[2]){
            helpMsg := self.printHelp(hits[1])
	    return helpMsg;
         }
      }
      helpMsg := spaste(helpMsg, '\nThere are ', len(hits),
                        ' matches. Please choose from:');
      if(findFirstURL){
         helpMsg := self.printHelp(hits[1]);
      } else {
         for(hit in hits){
	   helpMsg := spaste(helpMsg, '\n  ', hit);
         }
      }
    }
    return helpMsg;
  }
  
# prints the help in the command window.
  getVolume := function(){
    wider volumes;
    theVolume := 'Refman:';
    if(has_field(volumes, help::current.package)){
      theVolume := volumes[help::current.package];
    }
    return theVolume;
  }
  
  self.printHelp := function(look4what){
    global help;
    #print look4what;
    look4 := split(look4what, ".");
    #print look4;
    helpMsg := '';
    if(len(look4) == 5){
      help::current.package := look4[1];
      help::current.module := look4[2];
      help::current.object := look4[3];
      help::current.URL := spaste(getVolume(), look4[2], '.', look4[3], '.', 
                                  look4[4], '.', look4[5]);
      #if(look4[4] == look4[3]){
      if(look4[5] == 'constructor' &&
         has_field(help::pkg[look4[1]][look4[2]].objs[look4[3]], 'c') &&
	 has_field(help::pkg[look4[1]][look4[2]].objs[look4[3]].c, look4[4])){
	method := help::pkg[look4[1]][look4[2]].objs[look4[3]].c[look4[4]];
	packmod := ' -- Constructor -- ';
      } else {
	method := help::pkg[look4[1]][look4[2]].objs[look4[3]].m[look4[4]];
	packmod := ' -- Function -- ';
      }
      #} else {
      #   method := help::pkg[look4[1]][look4[2]].objs[look4[3]].m[look4[4]];
      #}
      packmod := spaste(packmod, look4[1],'.', look4[2],
                        '.', look4[3]);
      helpMsg := spaste(helpMsg, '\n ',look4[4], packmod);
      if(is_record(method)&&has_field(method, 'd')) 
	  helpMsg := spaste(helpMsg, '\n  ', method.d);
      helpMsg := spaste(helpMsg, '\n Useage:  ',method.s);
      if(has_field(method, 'a'))
	  self.help_args(helpMsg, method.a);
    }
    if(len(look4) == 4){
      help::current.package := look4[1];
      help::current.module := look4[2];
      help::current.object := look4[3];
      help::current.URL := spaste(getVolume(), look4[2], '.', look4[3], '.', 
                                  look4[4]);
      #if(look4[4] == look4[3]){
      if(has_field(help::pkg[look4[1]][look4[2]].objs[look4[3]], 'c') &&
	 has_field(help::pkg[look4[1]][look4[2]].objs[look4[3]].c, look4[4])){
	method := help::pkg[look4[1]][look4[2]].objs[look4[3]].c[look4[4]];
	packmod := ' -- Constructor -- ';
      } else {
	method := help::pkg[look4[1]][look4[2]].objs[look4[3]].m[look4[4]];
	packmod := ' -- Function -- ';
      }
      #} else {
      #   method := help::pkg[look4[1]][look4[2]].objs[look4[3]].m[look4[4]];
      #}
      packmod := spaste(packmod, look4[1],'.', look4[2],
                        '.', look4[3]);
      helpMsg := spaste(helpMsg, '\n ',look4[4], packmod);
      if(is_record(method)&&has_field(method, 'd')) 
	  helpMsg := spaste(helpMsg, '\n  ', method.d);
      helpMsg := spaste(helpMsg, '\n Useage:  ',method.s);
      if(has_field(method, 'a'))
	  self.help_args(helpMsg, method.a);
    }
    if(len(look4) == 3){
      packmod := spaste(' -- ', look4[1], '.', look4[2]);
      help::current.package := look4[1];
      help::current.module := look4[2];
      help::current.URL := spaste(getVolume(), look4[2], '.', look4[3]);
      if(has_field(help::pkg[look4[1]][look4[2]].funs, look4[3])){
	help::current.object := '';
	method := help::pkg[look4[1]][look4[2]].funs[look4[3]];
	helpMsg := spaste(helpMsg, '\n ',look4[3], ' -- Function ', packmod);
	if(is_record(method)&&has_field(method, 'd')) 
	    helpMsg := spaste(helpMsg, '\n  ', method.d);
	helpMsg := spaste(helpMsg, '\n Useage:  ',method.s);
	if(has_field(method, 'a'))
            self.help_args(helpMsg, method.a);
      } else {
	help::current.object := look4[3];
	obj := help::pkg[look4[1]][look4[2]].objs[look4[3]];
	helpMsg := spaste(helpMsg, '\n ',look4[3], ' -- Tool ', packmod);
	if(is_record(obj)&&has_field(obj, 'd')) 
	    helpMsg := spaste(helpMsg, '\n  ', obj.d);
	if(has_field(obj, 'c')){
	  helpMsg :=  spaste(helpMsg, '\n Constructor');
	  methods := field_names(obj.c);
	  for(method in methods){
	    if(is_record(obj.c[method])&&has_field(obj.c[method], 'd')) 
		helpMsg := spaste(helpMsg, '\n   ', method, ' \t', obj.c[method].d);
	  }
	}
        if(has_field(obj, 'm')){
	methods := field_names(obj.m);
	  if(len(methods) > 0){
	    helpMsg :=  spaste(helpMsg, '\n Functions');
	    for(method in methods){
	      if(is_record(obj.m[method])&&has_field(obj.m[method], 'd')) 
		  helpMsg := spaste(helpMsg, '\n   ', method, ' \t',
				    obj.m[method].d);
	    }
	  }
        }
      }
    } 
    if(len(look4) == 2){
      help::current.package := look4[1];
      help::current.module := look4[2];
      help::current.object := '';
      help::current.URL := spaste(getVolume(), look4[2]);
      modu := help::pkg[look4[1]][look4[2]];
      helpMsg := spaste(helpMsg, '\n ',look4[2], ' -- Module -- ', look4[1]);
      helpMsg := spaste(helpMsg, '\n   ', modu.d, '\n');
      objs := field_names(modu.objs);
      funs := field_names(modu.funs);
      if(len(objs) > 0){
	helpMsg := spaste(helpMsg, '\n Tools');
	for(obj in objs){
	  if(is_record(modu.objs[objs])&&has_field(modu.objs[obj], 'd')) 
	      helpMsg := spaste(helpMsg, '\n    ', obj, '\t\t', modu.objs[obj].d);
	}
      }
      if(len(funs) > 0){
	helpMsg := spaste(helpMsg, '\n\n Functions');
	for(fun in funs){
	  if(is_record(modu.funs[funs])&&has_field(modu.funs[fun], 'd')) 
	      helpMsg := spaste(helpMsg, '\n    ', fun, '\t\t', modu.funs[fun].d);
	}
      }
    }
    if(len(look4) == 1){
      help::current.package := look4;
      help::current.module := '';
      help::current.object := '';
      help::current.URL := getVolume();
      pkg := help::pkg[look4];
      helpMsg := spaste(helpMsg, '\n\n ', look4, ' -- Package\n');
      helpMsg := spaste(helpMsg, '\n Modules');
      for(modu in field_names(pkg)){
	if(is_record(pkg[modu])&&has_field(pkg[modu], 'd')) 
	    helpMsg := spaste(helpMsg, '\n    ', modu, '\t', pkg[modu].d);
      }
    }
    helpMsg := spaste(helpMsg, '\n\nYou may find more information in the on-line documentation available');
    helpMsg := spaste(helpMsg, '\nvia your web browser.  Type the command\n\n   web()\n');
    helpMsg := spaste(helpMsg, '\nto view more about ', look4what, '.\n');
    return helpMsg;
  }
  
  # Prints the arguments of a function/method
  
  self.help_args := function(ref helpMsg, theArgs){
    args := field_names(theArgs);
    if(len(args) > 0){
      helpMsg := spaste(helpMsg, '\n\n Argument Description(s)');
      for(arg in args){
	if(is_record(theArgs[arg])&&has_field(theArgs[arg], 'd')) 
	    helpMsg := spaste(helpMsg, '\n\n  ', arg, '\t', theArgs[arg].d);
	if(len(as_byte(theArgs[arg].def)) > 0)
            helpMsg := spaste(helpMsg, '\n    Default:  ', theArgs[arg].def);
	if(len(as_byte(theArgs[arg].a)) > 0)
            helpMsg := spaste(helpMsg, '\n    Allowed:  ', theArgs[arg].a);
      }
    }
  }
  
  # Get the URL of the label format is Manual:label.label.label
  
  self.get_url := function(_what, ref public)
  { isURL := F;
    url := 'unknown';
    if(any(as_byte(_what) == as_byte(':')))
	isURL := T;
    else if(is_string(self.where(_what))){  # Here there are no : let's see
      isURL := T;                          # if it's a registered manual
    }
    if(_what == 'Not Found'){
      url := spaste(public::server, public::searchPage);
    }
    # print _what, isURL;
    if(isURL){
      manlabel := split(_what, ' :.');   #Remove spaces, :, and . 
      man := manlabel[1]                 #First one is always the manual
      if(len(manlabel) > 1){             #Assemble the label ala latex2html
	 if(len(manlabel) == 2){
	    label := manlabel[2];
	 } else {
	    label := paste(manlabel[3:len(manlabel)], sep='.');
	    label := spaste(manlabel[2], ':', label);
	 }
      } else {
	 label := F;
      }
      if((man ~ m/^[Hh][Tt][Tt][Pp]/) || (man ~ m/^[Ff][Ii][Ll][Ee]/)){
	#Since it's already a URL just return it.
	url := _what;
      }else {
        theLabelsFile := self.where(man);  #Get the fully qualified labels.pl
	# path
	
	#If not cached read in the label/node pairs and cache them
	
        if(is_string(theLabelsFile)){
	  if(!has_field(public::cached, man)){
            if(strlen(which_client('perl')) > 0){
	       command := spaste('perl -S getnodes.pl ',theLabelsFile);
	       nodes := shell(command);
               if(len(nodes) > 2){
	          nodes::shape := [2, len(nodes)/2]
            
		   for(i in 1:(len(nodes)/2)){
		     public::cached[man][nodes[1,i]] := nodes[2,i];
		   }
               } else {
                  public::cached[man][1] := '';
               }
            } else {
               public::cached[man][1] := '';
            }
	 } 
	  
	  # Remove labels.pl from the fully qualified path.
	  dir := ''
	      dum := split(theLabelsFile, '/');
	  for(i in 1:(len(dum)-1)){
	    dir := spaste(dir, '/', dum[i]);
	  }
	  
	  #Get the URL
	  if(has_field(public::cached, man)){
            # print  'Label: ', label;
            # print  'Label: ', public::cached[man];
	    if(is_string(label) && has_field(public::cached[man], label)){
	      url := spaste(public::server, dir,
			    public::cached[man][label], '\#', label);
	    } else {
                # if .constructor or .function is not there and we don't
                # have a hit add the .constructor and .function and see
                # if we get any hits before giving up 
	      if(is_string(label)){
                 labelc := spaste(label, '.constructor');
                 if(has_field(public::cached[man], labelc)){
	            url := spaste(public::server, dir,
			    public::cached[man][labelc], '\#', labelc);
                 } else {
                   labelf := spaste(label, '.function');
                   if(has_field(public::cached[man], labelf)){
	              url := spaste(public::server, dir,
			    public::cached[man][labelf], '\#', labelf);
                   } else {
		      self.note('Unable to find ',_what,'. Reverting to ', man,
                            ' top.');
	              url := spaste(public::server, dir, '/', man, '.html');
                   }
                 }
              } else {
	         url := spaste(public::server, dir, '/', man, '.html');
              }
	    }
	  } else {
	    self.note('Unable to find ', _what, '.');
	    url := 'unknown';
	  }
        }else{
	  url := 'unknown';
	  self.note('Unable to find ', _what, '.');
        }
      }
    }
    return url;
  }
  
  # Make netscape go the url
  self.drive_netscape := function(url)
  {  global system;
     wider public;
     self.note('Driving ', public::browser, ' to: ', url);
     netcommand := spaste(public::browser, ' -remote \"openURL(',url,')\" 2> /dev/null');
     eh := shell(netcommand);
     #print 'shell returned *', eh::, '*';
     if(!is_record(eh::)||(eh::status != 0)){
       netcommand := spaste(public::browser,' ', url);
       system.NS := shell(netcommand, async=T);
       #self.note(spaste('shell returned *', system.NS, '*'));
       #self.note(spaste('shell returned *', system.NS::, '*'));
       whenever system.NS->stderr, system.NS->stdout do {
          self.note(paste('Netscape --', $value));
       }
       if(!is_record(system.NS::)||(system.NS::status != 0)){
	 self.note('Unable to drive netscape to URL ', url);
       }
     }
   }

  
  # Make mosaic go the url
  self.drive_mosaic := function(url)
  { global system;
    wider public;
    pid := shell('cat $HOME/.mosaicpid');
    self.note('Driving mosaic to: ', url);
    if(pid::status == 0){
      mFile := spaste('/tmp/Mosaic.', pid);
      fp := open('>', mFile);
      printf(fp, 'goto\n%s\n', url);
      fp:=F;
      netcommand := spaste('kill -USR1 ', pid, ' 2> /dev/null');
      eh := shell(netcommand);
     if(!is_record(eh::)||(eh::status != 0)){
	netcommand := spaste(public::browser,' -home ',url,' 2> /dev/null &');
	system.NS := shell(netcommand);
	if(!is_record(system.NS::)||(system.NS::status != 0)){
	  self.note('Unable to drive mosaic to URL ', url);
	}
      }
      eh := dos.remove(mFile);
    }
  }
  
  # Find the fully qualified path of the manual
  # This is a kludge for now.
  self.where := function(_whichone)
  {  rval := F;
     for(i in 1:len(public::manuals)){
       b := split(public::manuals[i], '/')
	   c := b[_whichone == b ]
	       if(len(c)> 0 && len(b) > 1 && b[len(b)-1] == _whichone){
           #print _whichone, b, b[len(b)-1]
           #print (_whichone == b)
		 rval := public::manuals[i];
		 break;
	       }
     }
    # print rval;
     return rval;
   }
  
  # Public functions
  
  # Do I use a browser to view help????
  public.usebrowser := function()
  {  wider public;
     if(is_string(public::browser))
	 return T;
     return public::browser;
   }
  
  #Drive the browser to a given url
  
  public.browse := function(_what, browser=public::browser,
                            server=public::server)
  {  helpMsg := F;
     wider public;
    if(_what ~ m/Refman/){  # Looking for a user reference manual entry
       if(!(_what == 'Refman' || _what == 'Refman:') ){
          _what := _what ~ s/Refman://;   # Strip away the Refman since we split it up.
          helpMsg := self.clHelp(_what, T);
          _what := help::current.URL;
          helpMsg := F;                   # ignore the help
       }
     } 
     url := self.get_url(_what, public);
     public::browser := browser;
     public::server := server;
     if(url != 'unknown'){
       if(have_gui()){
         if(browser ~ m/.*netscape.*/ || browser ~m/.*mozilla.*/){
	   self.drive_netscape(url)
	     }else if(browser ~ m/.*mosaic.*/){
	       self.drive_mosaic(url)
		 }else{
		   self.note( 'Driving your browser ', browser,
			     ' is not implemented. Please point your browser to ', url);
		 }
       } else {
	 self.note('Unable to drive your browser.');
	 self.note('Please point your browser to ', url);
       }
     } else {
       helpMsg := self.clHelp(_what);
     }
     return helpMsg;
   }
  
# end of showhelp functions
  
    # initialize the help system
  self.initialize(browser, server)
  if(have_gui()){
     f:= F;
  }
  if(doInitializationMessage){
     self.note('help system initialized');
  }
  
  # return the public bits.
  return ref public;
}

  #include the ask/faq functions
include 'askme.g';
