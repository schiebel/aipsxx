# e2equery: execute TaQL query produced by VLADB (E2E) search tool
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
#   $Id: e2equery.g,v 19.0 2003/07/16 03:44:41 aips2adm Exp $
#
#----------------------------------------------------------------------------

# Experimental draft of Glish script/function that receives a Glish
# record from web-tool directed toward the E2E Archive catalog tables. An
# html file is generated containing the selected observing scans. The
# input record now contains name-value pairs that this function builds
# into TaQL queries.
#
# Example on how to run e2equery :
#
# include 'e2equery.g';
#
# testrec := [PROJECT_CODE='AB973'];
# e2eq    := e2equery(T);
# xx      := open('> e2edb_query.html');
# write(xx, e2eq.perform_query(testrec, 'MSCATALOG'));
# e2eq.done();
#
########################################################################

pragma include once;

include 'table.g';
include 'measures.g';
include 'quanta.g';
include 'e2efuncs.g';
include 'vectime2str.g';


#
# e2equery object
#

const e2equery := function(verbose=F) {
    private := [=];
    public  := [=];

    const private.verbose   := verbose;
    const private.version   := paste("e2equery.g version 2.2.1");
    private.html := paste('<h1>An error occurred during processing : ',
                          private.version);
    ####################################################### PRIVATE INIT
    
    # parses the Record's values
    #
    # builds the query strings obs_query, arch_query, and desc_query
    #
    
    const private.init := function(values) {
        wider private;
        
        #
        # a Glish record containing name-value pairs
        # that parameterize the query to the table
        #
        # TODO:
        #  verify the record; for now, if there are
        #  meaningless values in the record, they
        #  are ignored, and the TaQL query won't
        #  do much
        #
        if( !is_record(values) )
            return throw(paste('values is not a record', values));

        #
        # Do this for now to pass the name/value pairs around..
        #
        private.query_rec := values;

        private.checkq := F;
        private.catalogname := paste("");

        nbands      := 0;
        nconfigs    := 0;
        obs_query   := paste("");
        desc_query  := paste("");
        arch_query  := paste("");
        proj_query  := paste("");
        image_query := paste("");
        archfile_q  := paste("");
        query_type  := paste("ERROR");
        catalogname := paste("NONE");
        cone_parms  := [racenter=0.0, deccenter=0.0, srad=0.0];
        catalogroot := paste("/home/archive/e2e/archive/catalogs/");
#        catalogroot := paste("/users/jbenson/aips2data/");
#
#       Have to read these values in first..
#
        for (field in field_names(values)) {
            if (field == 'CATALOG') {
               catalogname := spaste(catalogroot, values[field]);
            }
            if (field == 'CHECK') {
               private.checkq := T;
            }
            if (field == 'QUERYTYPE') {
               query_type := paste(values[field]);
            }
            else if (field == 'SRAD') {
                sDir := dm.direction('J2000','0h0m0',values[field]);
                sRad := as_double(sDir.m1.value);
                deltaDec := abs(sRad);
                if (deltaDec >  pi/4)
                   deltaDec := pi/4;
                cone_parms['srad'] := deltaDec;
            }
        }
        private.catalogname := paste(catalogname);
        if (private.catalogname == 'NONE') {
            return throw(paste('table ', catalogname, 'was not set'),
                           origin='e2equery.g');
        }

        private.catalog_type := paste("MS");
        if (query_type == 'IMAGELIST') {
           private.catalog_type := paste("IMAGE");
        }

        #
        # verify the catalog argument
        #
        if (private.catalog_type == 'MS') {
           cata_obs  := spaste(private.catalogname);
           if (!tableexists(cata_obs)) {
              return throw(paste('table ', cata_obs, 'does not exist'),
                           origin='e2equery.g');
           }
        }
        else if (private.catalog_type == 'IMAGE') {
           cata_image  := spaste(private.catalogname) ;
           if (!tableexists(cata_image)) {
              return throw(paste('table ', cata_image, 'does not exist'),
                           origin='e2equery.g');
           }
        }

        for (field in field_names(values)) {
            if (private.verbose) print "verbose : ",field, "=", values[field];
            
            if (values[field] == 'ALL')
               continue;
 
            else if (field == 'PROJECT_CODE') {
                obs_query  :=  paste(obs_query, "and",  field,"== pattern");
                obs_query  := spaste(obs_query, "(\'*", values[field],"*\')");
                proj_query :=  paste(proj_query, "and", field,"== pattern");
                proj_query := spaste(proj_query,"(\'*", values[field],"*\')");
                archfile_q :=  paste(archfile_q, "and", field,"== pattern");
                archfile_q := spaste(archfile_q,"(\'*", values[field],"*\')");
                image_query :=  paste(image_query, "and", field,"== pattern");
                image_query := spaste(image_query,"(\'*", values[field],"*\')");
            }
            else if (field == 'SOURCE_ID') {
                obs_query :=  paste(obs_query, "and",  field,"== pattern");
                obs_query := spaste(obs_query, "(\'*", values[field],"*\')");
                image_query :=  paste(image_query, "and  FIELD_ID == pattern");
                image_query := spaste(image_query, "(\'*", values[field],"*\')");
            }
            else if (field == 'CALIB_TYPE') {
#               obs_query := paste(obs_query, "and",field,"in ", 
                                   spaste("[{",values[field],"}]");
            }
            else if (field == 'CENTER_DIR') {
                centerVec := split(values[field]);
                nCenter   := len(centerVec);
                print "centerVec = ", nCenter, centerVec;
                ra1 := 0;
                ra2 := 0;
                dec1:= 0;
                dec2:= 0;

                center_rec := dm.direction('J2000',centerVec[1],
                                                   centerVec[2]);
                raRad      := as_double(center_rec.m0.value);
                decRad     := as_double(center_rec.m1.value);

                print "raRad, decRad = ", raRad, decRad;
                if (decRad >  pi/2) decRad :=  pi/2.01;
                if (decRad < -pi/2) decRad := -pi/2.01;
                dec1 := decRad + deltaDec;
                dec2 := decRad - deltaDec;
                if (dec1 >  pi/2) dec1 :=  pi/2.01;
                if (dec2 < -pi/2) dec2 := -pi/2.01;
 
                if (raRad < 0.00)   raRad := raRad + 2.0*pi;
                if (raRad > 2.0*pi) raRad := raRad - 2.0*pi;
                ra1 := raRad + deltaDec;
                ra2 := raRad - deltaDec;
                if (ra1 > 2.0*pi) ra1 := ra1 - 2.0*pi;
                if (ra2 < 0.00  ) ra2 := ra2 + 2.0*pi;

                cone_parms['racenter']  := raRad;
                cone_parms['deccenter'] := decRad;
                cone_parms['srad']      := deltaDec;

                # RA range doesn't cross RA = 0 hrs
                if (ra1 > ra2) {
                   cone_query := paste("and","CENTER_DIR[1] >=",ra2,
                                       "and CENTER_DIR[1] <=", ra1,
                                       "and CENTER_DIR[2] >=", dec2,
                                       "and CENTER_DIR[2] <=", dec1);
                }
                # RA range crosses RA = 0 hrs
                else if (ra1 < ra2) {
                   cone_query := paste("and",
                                         "((CENTER_DIR[1] >=",ra2,
                                       "and CENTER_DIR[1] <=", 2.0*pi,")",
                                       "or (CENTER_DIR[1] >= 0.0",
                                       "and CENTER_DIR[1] <=", ra1,"))",
                                       "and CENTER_DIR[2] >=", dec2,
                                       "and CENTER_DIR[2] <=", dec1);

                }
                obs_query   := paste(obs_query, cone_query);
                image_query := paste(image_query, cone_query);
            }
            else if (field == 'TIMERANGE1') {
                start_mjd := dq.quantity(values["TIMERANGE1"],'d');
                stop_mjd  := dq.quantity(values["TIMERANGE2"],'d');

                if (start_mjd.value > 0.0 && 
                    stop_mjd.value >= start_mjd.value) {
                   obs_query := paste(obs_query, "and","(STARTTIME >= ",
                                      start_mjd.value," and STARTTIME <= ",
                                      stop_mjd.value, " or STOPTIME >= ",
                                      start_mjd.value," and STOPTIME <= ",
                                      stop_mjd.value,")");
        
                   proj_query := paste(obs_query, "and","(FIRSTTIME >= ",
                                       start_mjd.value," and FIRSTTIME <= ",
                                       stop_mjd.value, " or LASTTIME >= ",
                                       start_mjd.value," and LASTTIME <= ",
                                       stop_mjd.value,")");
                   archfile_q := paste(archfile_q, "and","(STARTTIME >= ",
                                      start_mjd.value," and STARTTIME <= ",
                                      stop_mjd.value, " or STOPTIME >= ",
                                      start_mjd.value," and STOPTIME <= ",
                                      stop_mjd.value,")");
                   image_query := paste(image_query, "and","(OBS_DATE >= ",
                                        start_mjd.value,
                                        " and OBS_DATE <= ",
                                        stop_mjd.value,")");
                }
            }
            else if (field == 'OBS_BANDS') {
                bandvec := split(values[field], ",");
                nbands   := length(bandvec);
                if (nbands > 0) {
                   proj_query := paste(proj_query, 
                                       "and OBS_BANDS == pattern('*");
                   proj_query := spaste(proj_query,values[field],"*')");
                }
            }
            else if (field == 'TELESCOPE_CONFIG') {
                configvec  := split(values[field], ",");
                nconfigs   := length( configvec);
                if (nconfigs > 0) {
                   proj_query := paste(proj_query, 
                                       "and TELESCOPE_CONFIG == pattern('*");
                   proj_query := spaste(proj_query,values[field],"*')");
                }
            }
        }

        if (private.verbose) print "verbose : obs_query =", obs_query;

        obs_queryv := split(obs_query);
        nelements := length(obs_queryv);

        if (nelements > 0) {
            obs_query := spaste("");
            for (i in 2:nelements) {
                obs_query := paste(obs_query, obs_queryv[i]);
            }
        }

        proj_queryv := split(proj_query);
        nelements := length(proj_queryv);

        if (nelements > 0) {
            proj_query := spaste("");
            for (i in 2:nelements) {
                proj_query := paste(proj_query, proj_queryv[i]);
            }
        }
        archfile_qv := split(archfile_q);
        nelements := length(archfile_qv);

        if (nelements > 0) {
            archfile_q := spaste("");
            for (i in 2:nelements) {
                archfile_q := paste(archfile_q, archfile_qv[i]);
            }
        }
        image_queryv := split(image_query);
        nelements := length(image_queryv);

        if (nelements > 0) {
            image_query := spaste("");
            for (i in 2:nelements) {
                image_query := paste(image_query, image_queryv[i]);
            }
        }
        #
        # add the min and max freqs to the desc_query string
        #
        query_string := paste("");
        if (nbands > 0) {
            for (i  in 1:nbands) {
                band_range := bandrange(bandvec[i]);
                query_string := sprintf("(IF_REF_FREQ in [{%12.6e,%12.6e}])", band_range[1]*1.0e6, band_range[2]*1.0e6);

                if (i > 1) desc_query := paste(desc_query," or "); 
                desc_query := paste(desc_query, query_string);
            }
        }
        #
        # load  the query string for the archive files table
        #
        if (nconfigs > 0) {
            arch_query := paste("TELESCOPE_CONFIG in ",spaste("['",configvec[1],"'"));
            if (nconfigs > 1 )
               for (i in  2:nconfigs) {
                   arch_query := spaste(arch_query,",",spaste("'",configvec[i],"'"));
               }
            arch_query := spaste(arch_query,"]");
        }

        ### finally, 

        if (private.verbose) {
            print "verbose : query_type = ", query_type;
            print "verbose : obs_query  = ", obs_query;
            print "verbose : arch_query = ", arch_query;
            print "verbose : desc_query = ", desc_query;
            print "verbose : proj_query = ", proj_query;
            print "verbose : archfile_q = ", archfile_q;
            print "verbose : image_query= ", image_query;
            print "verbose : cone_parms = ", cone_parms;
        }

        private.query_type  := query_type;
        private.obs_query   := obs_query;
        private.arch_query  := arch_query;
        private.desc_query  := desc_query;
        private.proj_query  := proj_query;
        private.archfile_q  := archfile_q;
        private.image_query := image_query;
        #
        # Slip the cone search parameters across
        #
        private.cone_parms  := cone_parms;
        return T;
    }
    #
    ################################################### END PRIVATE INIT


    #################################################### PRIVATE SCANLIST
    # 
    # actually perform the query, puts results into an HTML string
    #
    # TODO: use XML

    const private.scanlist := function() {
        wider private;

        # paste with newline as seperator
        #
        func nlpaste(...) paste(...,sep='\n');

        indx_test := 0;

        html := paste(""); 

        #
        # write out the html header stuff, etc.
        #
        html := nlpaste(html,"<h1>NRAO Archive DB Query Results - Observing Scans</h1><hr>");
        html := nlpaste(html,'<TABLE><TR><TD class=breadcrumb valign=top halign=left>You are here : <a href="http://bernoulli.aoc.nrao.edu/E2E/jmbtest/e2etest.html">Main Page</a>&#160;<span class="greymedium">&#155;</span>&#160;<a href="http://bernoulli.aoc.nrao.edu/E2E/jmbtest/scanlistquery.html">Scan Query</a>&#160;<span class="greymedium">&#155;</span>&#160;Observing Scan List</TD></TR></TABLE>');

        html := nlpaste(html,"<p>You submitted the following Glish Table Queries (",private.version,") :<p>");
        if (private.verbose) {
           html := nlpaste(html,"<pre><b>TaQL Query String 1 :", 
                           private.obs_query, "</b></pre>");
           html := nlpaste(html,"<pre><b>TaQL Query String 2 :", 
                           private.desc_query,"</b></pre>");
           html := nlpaste(html,"<pre><b>TaQL Query String 3 :", 
                           private.arch_query,"</b></pre>");
           html := nlpaste(html,"<pre><b>TaQL Query String 4 :", 
                           private.proj_query,"</b></pre>");
        }
        #
        # write out the html header stuff, etc.
        #
        
        html := nlpaste(html, sprintf("<pre><b>Archive Catalog : %s </b></pre>",
                        private.catalogname));
        
        for (field in field_names(private.query_rec)) {        
           html := nlpaste(html, sprintf("<pre><b>%s  = %s </b></pre>",
                     field,  private.query_rec[field]));
        }

        print "private.catalogname = ", private.catalogname;
        #  
        # query to the observation table
        #
        cata_obs    := spaste( private.catalogname,"/OBSERVATION") ;
        obs_command :=  paste("SELECT PROJECT_CODE,SOURCE_ID,STARTTIME,STOPTIME,CALIB_TYPE,CENTER_DIR,EXPOSURE,ARCH_FILE_ID,DATA_DESC_ID FROM ");
        obs_command :=  paste(obs_command, cata_obs," WHERE ");
        obs_command :=  paste(obs_command, private.obs_query);

        tobs := table(cata_obs);

        if (private.verbose) print "obs_command : ", obs_command;

        t1    := tablecommand(obs_command);

        if (! is_record(t1)) {
            private.html := nlpaste(html, "<h3>Error: no table returned from command</h3>",
                                    "<pre>", obs_command, "</pre>");
            return F;
        }
        #
        html := nlpaste(html, "<p><hr><p><pre>Program..Source.Name..........StartIAT............StopIAT...........TOS....CMode..Freq_AC.BW_AC.Freq_BD.BW_BD.CFG....Epoch.......RA............Dec.........File<p>");

        nrows := t1.nrows();

        if(private.verbose) print "nrows in observation table returned from query : ",
                                   nrows;

        if (nrows <= 0)
            return T;

        starttime := t1.getcol('STARTTIME');
        stoptime  := t1.getcol('STOPTIME');
        center_dir:= t1.getcol('CENTER_DIR');
        idesc     := t1.getcol('DATA_DESC_ID');
        iarch     := t1.getcol('ARCH_FILE_ID');
        project   := t1.getcol('PROJECT_CODE');
        source    := t1.getcol('SOURCE_ID');
        cal_code  := t1.getcol('CALIB_TYPE');
        exposure  := t1.getcol('EXPOSURE');
        t1.done();

        #
        # wake up the datadesc and archive tables
        #
        cata_datadesc := spaste( private.catalogname,"/DATADESC");
        cata_archive  := spaste( private.catalogname,"/ARCHIVE");

        #
        # if there is a query for either of these two tables, present the
        # returned rows to the program instead of the entire table.
        #
        if (strlen(private.desc_query) > 0) {
            dsc_command := paste(private.desc_queryexit);
            tdescall    := table(cata_datadesc);
            tdesc       := tdescall.query(dsc_command);

            if (private.verbose)
                print "desc_command : ", dsc_command;
        }
        #### WARNING
        else {
            tdesc := table(cata_datadesc);
        }
        #
        ndesc := tdesc.nrows();  
        #
        if (ndesc <= 0) {
            print "ERROR: no rows found in datadesc table for this query : ", private.desctbl_query;
            return F;
        }

        if (strlen(private.arch_query) > 0) {
            arch_command    := paste(private.arch_query);
            tarchall        := table(cata_archive);
            tarch           := tarchall.query(arch_command);

            if (private.verbose) print "arch_command : ", arch_command;
        }
        else {
            tarch := table(cata_archive);
        }
        #
        narch := tarch.nrows();  
        #
        if (narch <= 0) {
            print "ERROR: no rows found in archive table for this query : ", private.archtbl_query;
            return F;
        }

        if (private.verbose) print "nobs, narch, ndesc rows selected : ", nrows, narch, ndesc;

        indxdesc := tableindex(tdesc, 'DATA_DESC_ID');
        indxarch := tableindex(tarch, 'ARCH_FILE_ID');

        #
        # make the date/time and ra and dec string here...
        #
        start_str := vectime2str(starttime);
        stop_str  := vectime2str(stoptime);
        ra_str    := vecra2str(center_dir);
        dec_str   := vecdec2str(center_dir);

        if (private.verbose) print "string rendering finished";

        # 
        # Do the last set of the cone search if a search radius has
        # specified.
        #
        iskip_row := array(-1, nrows);
        nskip := 0;
        if (private.cone_parms['srad'] > 0.0) {
            for (i in 1:nrows) {
                xcone  := cos(private.cone_parms['racenter']);
                ycone  := sin(private.cone_parms['racenter']);
                xpos   := cos(center_dir[1,i]);
                ypos   := sin(center_dir[1,i]);
                delra  := acos(xcone*xpos + ycone*ypos);
                if (private.verbose && i < 10) {
                   print"delra1, delra2 = ", delra, 
                                 center_dir[1,i] - private.cone_parms['racenter'];
                }
                deldec := center_dir[2,i] - private.cone_parms['deccenter'];
                rdist  := sqrt(delra*delra + deldec*deldec);
                if (private.verbose && i < 10) {
                   print "cone_parms : ", private.cone_parms;
                   print "center_dir : ", center_dir[1,i], center_dir[2,i];
                   print "rdist      : ", rdist;
                }
                if (rdist >= private.cone_parms['srad']) {
                   iskip_row[i] := 1;
                   nskip := nskip + 1;
                }
            }
        }

        if (private.verbose) print "will skip nskip output rows, cone_search : ", 
                                    nskip;
        # now loop through the rows selected from the
        # catalogname.observations table, and write out display rows
        #
        nwritten := 0;
        for (i in 1:nrows) {

            if (iskip_row[i] == 1)
               continue;

            # get the rows in datadesc and archive tables that match
            # the index numbers in the current observation table row.

            tdesc_rec := [DATA_DESC_ID = idesc[i]];
            desc_rows := indxdesc.rownrs(tdesc_rec);
            ndesc     := length(desc_rows);
            if (ndesc <= 0) continue;
            td1       := tdesc.selectrows(desc_rows);

            tarch_rec := [ARCH_FILE_ID = iarch[i]];
            arch_rows := indxarch.rownrs(tarch_rec);
            narch     := length(arch_rows);
            if (narch <= 0) continue;
            ta1       := tarch.selectrows(arch_rows);

            # now load up values to be displayed in the output page

            arch_file := ta1.getcell('ARCH_FILE',1);
            telescope := ta1.getcell('TELESCOPE',1);
            config    := ta1.getcell('TELESCOPE_CONFIG',1);

            # TODO: replace this spaste by writing both values in
            #       fprintf, someday..
            #
            tele      := spaste(telescope,":",config);

            # get the lowest and highest IF freqs - only two for the
            # VLA-like display
            #
            if_ref_freqs := td1.getcol('IF_REF_FREQ');
            sub_bandw    := td1.getcol('SUB_BANDW');
            sub_pol      := td1.getcol('POL');

            low_freq   := min(if_ref_freqs); 
            high_freq  := max(if_ref_freqs);

            for (jj in 1:ndesc) {
                if (low_freq == if_ref_freqs[jj]) {
                    low_bw  := sub_bandw[jj];
                    low_pol := sub_pol[jj];
                }
                if (high_freq == if_ref_freqs[jj]) {
                    high_bw  := sub_bandw[jj];
                    high_pol := sub_pol[jj];
                }
            }
#
#  write rows to the VLADB-like html string.
#
            row  := sprintf("<a href=\"/vlabd/VLA00001.html\">%7s  %-16s %s %s %6.0f ....%-4s  %6.2f  %6.2f %6.2f %6.2f %-8s 2000 . %s %s %s</a>",
                            project[i],
                            source[i],
                            start_str[i],
                            stop_str[i],
                            exposure[i],
                            cal_code[i],
                            low_freq/1.0e9,
                            low_bw/1.0e6,
                            high_freq/1.0e9,
                            high_bw/1.0e6,
                            tele,
                            ra_str[i],
                            dec_str[i],
                            arch_file);

            html := nlpaste(html, row );
    
            nwritten := nwritten + 1;
            ta1.done();
            td1.done();
        }
        # end for i in 1:nrows


        html := nlpaste(html,
                        "<hr />",
                        sprintf("<pre>%d observing scans satisify queries",
                                nwritten));
  
        if (private.verbose)
            print "Found n scans satisfying input queries : ", nwritten;

        private.html := paste(html);
    }
    #
    ################################################ END PRIVATE SCANLIST


    #################################################### PRIVATE PROJECTLIST
    # 
    # actually perform the query, puts results into an HTML string
    #
    # TODO: use XML

    const private.projectlist := function() {
        wider private;

        # paste with newline as seperator
        #
        func nlpaste(...) paste(...,sep='\n');

        print "inside projectlist()";
        indx_test := 0;

        html := paste(""); 

        #
        # write out the html header stuff, etc.
        #
        html := nlpaste(html,"<h1>NRAO Archive DB Query Results - Project List</h1><hr>");
        html := nlpaste(html,sprintf("Version : %s<p>",private.version)); 
        html := nlpaste(html,'<TABLE><TR><TD class=breadcrumb valign=top halign=left>You are here : <a href="http://bernoulli.aoc.nrao.edu/E2E/jmbtest/http://bernoulli.aoc.nrao.edu/E2E/jmbtest/e2etest.html">Main Page</a>&#160;<span class="greymedium">&#155;</span>&#160;<a href="http://bernoulli.aoc.nrao.edu/E2E/jmbtest/projectlistquery.html">Project Query</a>&#160;<span class="greymedium">&#155;</span>&#160;Project List</TD></TR></TABLE>');
        html := nlpaste(html, "<p>You submitted the following Glish Table Queries (",private.version,") :<p>");
        if (private.verbose) {
           html := nlpaste(html,"<pre><b>TaQL Query String 1 :", 
                           private.obs_query, "</b></pre>");
           html := nlpaste(html,"<pre><b>TaQL Query String 2 :", 
                           private.desc_query,"</b></pre>");
           html := nlpaste(html,"<pre><b>TaQL Query String 3 :", 
                           private.arch_query,"</b></pre>");
           html := nlpaste(html,"<pre><b>TaQL Query String 4 :", 
                           private.proj_query,"</b></pre>");
        }

        if(!tableexists(private.catalogname)) {
            return throw(paste('table ',spaste(private.catalogname,"-(PRJOJECT)") ,
                         'does not exist'),
                         origin='e2equery.g');
        }

        tblproj := table(private.catalogname);

        #  
        if (strlen(private.proj_query) <= 0) {
           start_mjd := dq.quantity('1-jan-1975','d');
           stop_mjd  := dq.quantity('31-dec-2050','d');
           private.proj_query := paste("(FIRSTTIME >= ",start_mjd.value,
                                       " and FIRSTTIME <= ",
                                       stop_mjd.value," or LASTTIME >= ",
                                       start_mjd.value, 
                                       " and ", "LASTTIME <= ", stop_mjd.value,")");

        }
        print "proj_command : ", private.proj_query;
        tblproj_q := tblproj.query(private.proj_query);

        nprojs    := tblproj_q.nrows();

        if (nprojs <= 0) {
           print "NO rows found that satisfy the input query.";
           return T;
        }
        #
        # write out the html header stuff, etc.
        #
        
        html := nlpaste(html, sprintf("<pre><b>Archive Catalog : %s </b></pre>",
                        private.catalogname));
        
        for (field in field_names(private.query_rec)) {        
           html := nlpaste(html, sprintf("<pre><b>%s  = %s </b></pre>",
                     field,  private.query_rec[field]));
        }
        html := nlpaste(html,sprintf("<pre><b>N Rows Found : %d </b></pre>", 
                        nprojs));
        hdr_str:=paste("<p><hr><p><pre>Project......Project First Time.....Project Last Time....Obs Bands......Telescope....Observer...Archive Files<p>"); 
        html := nlpaste(html,hdr_str);
#
        vecstart := tblproj_q.getcol('FIRSTTIME');
        vecstop  := tblproj_q.getcol('LASTTIME');
#
        startdisplay := vectime2str(vecstart);
        stopdisplay  := vectime2str(vecstop);
#
        for (i in [1:nprojs]) {
#
           project := paste(tblproj_q.getcell('PROJECT_CODE',i));

           start_str := startdisplay[i];
           stop_str  := stopdisplay[i];
#
           detailsfile := spaste(sprintf("proj_%s",project),".html");
#
           html := nlpaste(html,
                        sprintf("<a href=\"http://bernoulli.aoc.nrao.edu/E2E/jmbtest/summaries/%-s\">%-12s %s - %s %-16s %5s:%-6s %-16s %d", 
                           detailsfile, 
                           project, start_str, stop_str, 
                           tblproj_q.getcell('OBS_BANDS',i),
                           tblproj_q.getcell('TELESCOPE',i), 
                           tblproj_q.getcell('TELESCOPE_CONFIG',i),
                           tblproj_q.getcell('OBSERVER',i), 
                           tblproj_q.getcell('ARCH_FILES',i)));


        }
        private.html := paste(html);
    }
    #
    ################################################ END PRIVATE PROJECTLIST

  
    #################################################### PRIVATE IMAGELIST
    # 
    # actually perform the query, puts results into an HTML string
    #
    # TODO: use XML

    const private.imagelist := function() {
        wider private;

        # paste with newline as seperator
        #
        func nlpaste(...) paste(...,sep='\n');

        const arcsecrad := 1.0 / 4.848136811095e-06;

        print "inside imagelist()";
        indx_test := 0;

        html := paste(""); 

        #
        # write out the html header stuff, etc.
        #
        html := nlpaste(html,"<h1>NRAO Archive DB Query Results - Image List</h1><hr>");
        html := nlpaste(html,'<TABLE><TR><TD class=breadcrumb valign=top halign=left>You are here : <a href="http://bernoulli.aoc.nrao.edu/E2E/jmbtest/e2etest.html">Main Page</a>&#160;<span class="greymedium">&#155;</span>&#160;<a href="http://bernoulli.aoc.nrao.edu/E2E/jmbtest/imagelistquery.html">Image Query</a>&#160;<span class="greymedium">&#155;</span>&#160;Image List</TD></TR></TABLE>')

        html := nlpaste(html,"<p>You submitted the following Glish Table Queries (",private.version,") :<p>");

        if (private.verbose) {
           html := nlpaste(html,"<pre><b>TaQL Query String 1 :", 
                           private.obs_query, "</b></pre>");
           html := nlpaste(html,"<pre><b>TaQL Query String 2 :", 
                           private.desc_query,"</b></pre>");
           html := nlpaste(html,"<pre><b>TaQL Query String 3 :", 
                           private.arch_query,"</b></pre>");
           html := nlpaste(html,"<pre><b>TaQL Query String 4 :", 
                           private.proj_query,"</b></pre>");
           html := nlpaste(html,"<pre><b>TaQL Query String 5 :", 
                           private.image_query,"</b></pre>");
        }

        if(!tableexists(private.catalogname)) {
            return throw(paste('table ',spaste(private.catalogname,"-(IMAGE)") ,
                         'does not exist'), origin='e2equery.g');
        }

        tblimage := table(private.catalogname);

        #  
        if (strlen(private.image_query) <= 0) {
           start_mjd := dq.quantity('1-jan-1975','d');
           stop_mjd  := dq.quantity('31-dec-2050','d');
           private.image_query := paste("(OBS_DATE >= ",start_mjd.value,
                                       " and OBS_DATE <= ", stop_mjd.value,")");
        }
        print "image_command : ", private.image_query;
        tblimage_q := tblimage.query(private.image_query);

        nimages    := tblimage_q.nrows();
        print "nimages found = ", nimages;

        #
        # write out the html header stuff, etc.
        #
        
        html := nlpaste(html, sprintf("<pre><b>Archive Catalog : %s </b></pre>",
                        private.catalogname));
        
        for (field in field_names(private.query_rec)) {        
           html := nlpaste(html, sprintf("<pre><b>%s  = %s </b></pre>",
                     field,  private.query_rec[field]));
        }
        html := nlpaste(html, sprintf("<pre><b>N image files found : %d</b></pre>",
                        nimages));
        html := nlpaste(html,"<hr><p>");

        if (nimages <= 0) {
           html := nlpaste(html, "<p><hr><p>");
        }
        else { 
           hdr_str:=paste("<p><pre>Field_ID.....Prog...Tele. .........Obs_Date......Field_Size....Resolution  .Image File<p>"); 
           html := nlpaste(html, hdr_str);

           for (i in [1:nimages]) {

              #
              # cone search radial distance check
              #
              if (private.cone_parms['srad'] > 0.0) {
                 temp_pos := tblimage_q.getcell('CENTER_DIR',i);
                 xcone  := cos(private.cone_parms['racenter']);
                 ycone  := sin(private.cone_parms['racenter']);
                 xpos   := cos(temp_pos[1]);
                 ypos   := sin(temp_pos[1]);
                 delra  := acos(xcone*xpos + ycone*ypos);
                 if (private.verbose && i < 10) {
                    print"delra1, delra2 = ", delra, 
                                 temp_pos[1] - private.cone_parms['racenter'];
                 }
                 deldec   := temp_pos[2] - private.cone_parms['deccenter'];
                 rdist    := sqrt(delra*delra + deldec*deldec);
                 if (rdist > private.cone_parms['srad']) 
                    continue;
              }

              project      := spaste(tblimage_q.getcell('PROJECT_CODE',i));
              field_id     := spaste(tblimage_q.getcell('FIELD_ID',i));
              obs_date     := dq.quantity(tblimage_q.getcell('OBS_DATE',i),'d');
              obs_date_str := ingresTime(obs_date.value);
              create_date  := dq.quantity(tblimage_q.getcell('CREATE_DATE',i),'d');
              create_date_str := ingresTime(create_date.value);
              pixel_size   := tblimage_q.getcell('FIELD_SIZE',i);
              pixel_incr   := tblimage_q.getcell('PIXEL_INCR',i); 
              restore_beam := tblimage_q.getcell('RESTORE_BEAM',i);
              field_size[1] := pixel_size[1]*pixel_incr[1]*arcsecrad;            
              field_size[2] := pixel_size[2]*pixel_incr[2]*arcsecrad;      
              spect_window := tblimage_q.getcell('SPECTRAL',i);
              band_str := freq_band(spect_window[3]*1.0e-6);

              detailsfile := spaste(sprintf("im_%s_%s%s",project,
                                             field_id, band_str),".html");
#
              html := nlpaste(html, sprintf("<a href=\"http://bernoulli.aoc.nrao.edu/E2E/jmbtest/summaries/%-s\">%-12s %s  %s %s %s %7.3f - %7.3f  %6.3f - %6.3f %s</a>",
                                         detailsfile,
                                         field_id,
                                         project, 
                                         tblimage_q.getcell('TELESCOPE',i),
                                         band_str,
                                         obs_date_str, 
                                         field_size[1], field_size[2], 
                                         restore_beam[1], restore_beam[2],
                                         tblimage_q.getcell('IMAGE_FILE',i)));
           }
        }
        private.html := paste(html);
    }
    #
    ################################################ END PUBLIC IMAGELIST



    #################################################### PRIVATE ARCHIVELIST
    # 
    # actually perform the query, puts results into an HTML string
    #
    # TODO: use XML

    const private.archivelist := function() {
        wider private;

        # paste with newline as seperator
        #
        func nlpaste(...) paste(...,sep='\n');

        print "inside archivelist()";
        indx_test := 0;


        print "private.catalogname = ", private.catalogname;
        #  
        # query to the observation table
        #
        cata_arch   := spaste( private.catalogname,"/ARCHIVE") ;

        if (!tableexists(cata_arch)) {
            return throw(paste('table ',cata_arch , 'does not exist'),
                         origin='e2equery.g');
        }
        #
        # Open the tables 
        #
        tblarch := table(tablename=cata_arch, readonly=T); 

        #  
        if (strlen(private.archfile_q) <= 0) {
           start_mjd := dq.quantity('1-jan-1975','d');
           stop_mjd  := dq.quantity('31-dec-2050','d');
           private.archfile_q := paste("(STARTTIME >= ",start_mjd.value,
                                       " and STARTTIME <= ",
                                       stop_mjd.value," or STOPTIME >= ",
                                       start_mjd.value, 
                                       " and ", "STOPTIME <= ", stop_mjd.value,")");

        }

        #
        # write out the html header stuff, etc.
        #
        
        html := paste(""); 

        html := nlpaste(html,"<h1>NRAO Archive DB Query Results - Archive File List</h1><hr>");
        html := nlpaste(html,'<TABLE><TR><TD class=breadcrumb valign=top halign=left>You are here : <a href="http://bernoulli.aoc.nrao.edu/E2E/jmbtest/e2etest.html">Main Page</a>&#160;<span class="greymedium">&#155;</span>&#160;<a href="http://bernoulli.aoc.nrao.edu/E2E/jmbtest/archivelistquery.html">Archive File Query</a>&#160;<span class="greymedium">&#155;</span>&#160;Archive File List</TD></TR></TABLE>')

        html := nlpaste(html,"<p>You submitted the following Glish Table Queries (",private.version,") :<p>");

        if (private.verbose) {
           html := nlpaste(html,"<pre><b>TaQL Query String 1 :", 
                           private.obs_query, "</b></pre>");
           html := nlpaste(html,"<pre><b>TaQL Query String 2 :", 
                           private.desc_query,"</b></pre>");
           html := nlpaste(html,"<pre><b>TaQL Query String 3 :", 
                           private.arch_query,"</b></pre>");
           html := nlpaste(html,"<pre><b>TaQL Query String 4 :", 
                           private.archfile_q,"</b></pre>");
        }
        html := nlpaste(html, sprintf("<pre><b>Archive Catalog : %s </b></pre>",
                        private.catalogname));
        
        for (field in field_names(private.query_rec)) {        
           html := nlpaste(html, sprintf("<pre><b>%s  = %s </b></pre>",
                     field,  private.query_rec[field]));
        }

        #
        # TaQL query selecting rows from archive file table
        #

        print "archfile_command : ", private.archfile_q;

        tblarch_q := tblarch.query(private.archfile_q);
        narch := tblarch_q.nrows();
        if (narch <= 0) {
           print "NO rows found that satisfy the input query.";
           return T;
        }
#
        print "Writing ", narch," rows to file : e2edb_archive.html";
        #
        # write out the html header stuff, etc.
        #
        hdr_str := paste("<p><hr><p><pre>Program........Archive File Start.........Archive File Stop......Telescope........Archive File<p>"); 
        html := nlpaste(html, hdr_str);
        for (i in [1:narch]) {
           start := dq.quantity(tblarch_q.getcell('STARTTIME',i),'d');
           start_str := ingresTime(start.value);
           stop  := dq.quantity(tblarch_q.getcell('STOPTIME',i),'d');
           stop_str := ingresTime(stop.value);
           html := nlpaste(html, sprintf("<a href=\"/vlabd/VLA00001.html\">%-12s %s - %s %-16s %s</a>",
            tblarch_q.getcell('PROJECT_CODE',i), start_str, stop_str,
            spaste(tblarch_q.getcell('TELESCOPE',i),":",
                   tblarch_q.getcell('TELESCOPE_CONFIG',i)),
            tblarch_q.getcell('ARCH_FILE',i)));
         }
        html := nlpaste(html,"<hr>");
        private.html := paste(html);
    }
    #
    ################################################ END PUBLIC ARCHIVELIST




    #################################################### PRIVATE CHECKQVALUES
    # 
    # actually perform the query, puts results into an HTML string
    #
    # TODO: use XML

    const private.checkqvalues := function() {
        wider private;
        print "in checkqvalues()";
        # paste with newline as seperator
        #
        func nlpaste(...) paste(...,sep='\n');

        html := paste(""); 

        #
        # write out the html header stuff, etc.
        #
        html := nlpaste(html,"<h1>NRAO Archive DB Query Check - Echo Parameters</h1><hr>");
        html := nlpaste(html,'<TABLE><TR><TD class=breadcrumb valign=top halign=left>You are here : <a href="http://bernoulli.aoc.nrao.edu/E2E/jmbtest/e2etest.html">Main Page</a>&#160;<span class="greymedium">&#155;</span>&#160;<a href="http://bernoulli.aoc.nrao.edu/E2E/jmbtest/imagelistquery.html">Image Query</a>&#160;<span class="greymedium">&#155;</span>&#160;Check Query</TD></TR></TABLE>');
        html := nlpaste(html,"<p>You submitted the following Glish Table Queries (",private.version,") :<p>");

        #
        # write out the html header stuff, etc.
        #
        
        html := nlpaste(html, sprintf("<pre><b>Archive Catalog : %s </b></pre>",
                        private.catalogname));
        
        for (field in field_names(private.query_rec)) {        
           html := nlpaste(html, sprintf("<pre><b>%s  = %s </b></pre>",
                     field,  private.query_rec[field]));
        }
        html := nlpaste(html,"<hr>");
        private.html := paste(html);
    }
    #
    ################################################ END PUBLIC CHECKQVALUES


    ######################################################### PUBLIC DONE
    #
    const public.done := function() {
        wider private, public
        private := F
        public  := F
    }
    #
    ################################################ END PUBLIC DONE


    ################################################ PUBLIC PERFORMQUERY
    #
    const public.perform_query := function(values, catalogname='NONE') {
        wider private;

        private.init(values);
        if (private.checkq) {
            private.checkqvalues();
        }
        else if (private.query_type == 'SCANLIST') {
            private.scanlist();
        }
        else if (private.query_type == 'PROJECTLIST') {
            private.projectlist();
        }
        else if (private.query_type == 'IMAGELIST') {
            private.imagelist();
        }
        else if (private.query_type == 'ARCHIVEFILES') {
            private.archivelist();
        }

        return private.html;
    }
    #
    ############################################ END PUBLIC PERFORMQUERY

    ################################################ END OBJECT DEFS
    ###################################################################

    return public;
}
