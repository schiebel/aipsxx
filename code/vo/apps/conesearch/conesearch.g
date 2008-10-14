# conesearch: NVO conesearch access
# Copyright (C) 2002,2003
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
#        Postal address: APS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: conesearch.g,v 19.1 2004/02/23 23:18:43 nkilleen Exp $

pragma include once
    

include 'note.g';
include 'os.g';

conesearch := function() {

  include 'gxmlparser.g';

  public := [=];
  private := [=];
  
#
# Read the cone service registry of services 
#
  private.getregistry := function() {
    wider private, public;
    url := 'http://voservices.org/cone/show/getprofile.asp?format=xml';
    rec:=private.getvotable(url);
    if (is_fail(rec)) fail;
#
    if(!has_field(rec, 'root')||!has_field(rec.root, 'Answer')) {
      return throw('Failed to retrieve registry of cone services');
    }
    private.registry := [=];
    i:=1;
    for (field in field_names(rec.root.Answer)) {
      private.registry[i]:=rec.root.Answer[field]::;
      i+:=1;
    }
    note('Successfully read registry of conesearch services');
    return T;
  }

#
# Get the VOTable from a particular URL.
#
  private.getvotable := function(url) {
    wider private, public;
    url ~:= s/&amp;//g;
    note('Web request will be sent to ', url);
    outFile := 'search.xml';
    command := spaste('wget -nv -Q0 -O- ', url, ' > ', outFile);
    stime:=time();
    result:=shell(command);
    if(is_fail(result)) {
      return throw('Error in getting information from URL: ', result::message);
    }
#
    note('Received answer in ', time()-stime, ' seconds');
    if (dos.size(outFile)==0) {
       ok := dos.remove (outFile, mustexist=F);          # Clean up
       return throw ('The output XML file is empty - possibly the web service failed');
    }
#
    gp := gxmlparser();
    note('Start parsing VOTable');
    ok := gp.parsefile(outFile);
    if (is_fail(ok)) fail;
    result := gp.getdoc().torec();
    gp.done();
    ok := dos.remove (outFile, mustexist=F); 
    if(is_fail(result)) return throw('Failed to parse VOTable : ', result::message);
    if (length(result)==0) {
       return throw ('Output from parsing of VOTable is empty - possibly the web service failed');
    }
#
    note('Successfully parsed VOTable');
    return result;
  }

#
# List all the registered services
#
  public.list := function() {
    wider private, public;
    result := [''];
    for (i in 1:len(private.registry)) {
      note('Service ', i, ': ', private.registry[i].ServiceName);
    }
    return T;
  }
#
# Return all information
#
  public.all := function() {return private.registry;}
#
# Show all information about a particular service
#
  public.info := function(service=1) {
    wider private, public;
    if(service<1||service>len(private.registry)) {
      return throw('Index into registry services is out of the allowed range');
    }
    for (field in field_names(private.registry[service])) {
      note(field, ': ', private.registry[service][field]);
    }
    return T;
  }
#
# Query a particular service, indexed by number or by url
#
  public.query := function(i=1, ra=200, dec=40, sr=10, url=F, extra=F) {
    wider private, public;
    if(!is_string(url)) {
      if(i<1||i>len(private.registry)) {
	return throw('Index into registry services is out of the allowed range');
      }
      if(is_string(extra)) {
	url := spaste('\"', private.registry[i].BaseURL, '&RA=', ra, '&DEC=', dec, '&SR=', sr,
		      '&', extra, '\"');
      }
      else {
	url := spaste('\"', private.registry[i].BaseURL, '&RA=', ra, '&DEC=', dec, '&SR=', sr, '\"');
      }
    }
    else {
      if(is_string(extra)) {
	url := spaste('\"', url, '&RA=', ra, '&DEC=', dec, '&SR=', sr,
		      '&', extra, '\"');
      }
      else {
	url := spaste('\"', url, '&RA=', ra, '&DEC=', dec, '&SR=', sr, '\"');
      }
    }
    url ~ s/ /%20/g;
    return private.getvotable(url);
  }

  public.type := function() {return "conesearch"};

  public.done := function() {return T;};

  note('Getting registry of VO cone services');

  if(is_fail(private.getregistry())) fail;

  return ref public;
}

conesearchtest := function(service=1, sr=1) {
  cs:=conesearch();
  cs.list();
  cs.info(service);
  gr:=cs.query(service, sr=sr);
  include 'widgetserver.g';
  rb:=dws.recordbrowser(therecord=gr);
  return T;
}
