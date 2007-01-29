# tablecomparer: tool to compare tables
# Copyright (C) 2000,2001,2002
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

pragma include once;
include 'table.g';

const _define_tablecomparer := function(test, model, label, verbose) {

    public := [=];
    private := [=];

    private.this := 'tablecomparer';
    private.model := [=];
    private.test := [=];
    private.verbose := verbose;
    private.details.test := [=];
    private.details.model := [=];
    private.details.diff := [=];
    private.summary := [=];
    private.model[label].subtables := [];
    private.test[label].subtables := [];

    private.select.checkonlycols := [];
    private.select.nocheckcols := [];

    private.precision.double := 0;
    private.precision.float := 0;
    private.precision.complex := 0;
    private.precision.dcomplex := 0;
    private.precision.specificcols := [=];
    private.precision::isset := F;

    private.test.tabletool := table(test);
    if(is_fail(private.test.tabletool)) fail private.test.tabletool::message;
    private.model.tabletool := table(model);
    if(is_fail(private.model.tabletool)) fail private.model.tabletool::message;
    
    const private.setcolnames := function() {
        wider private;
        if(!has_field(private.model,label)) private.model[label] := [=];
        if(!has_field(private.model[label],'colnames')) 
            private.model[label].colnames := private.model.tabletool.colnames();
        if(!has_field(private.test,label)) private.test[label] := [=];
        if(!has_field(private.test[label],'colnames')) 
            private.test[label].colnames := private.test.tabletool.colnames();
        return T;
    }

    const private.setkeywords := function() {
        wider private;
        if(!has_field(private.model,label)) private.model[label] := [=];
        if(!has_field(private.model[label],'keywords')) 
            private.model[label].keywords := private.model.tabletool.
                getkeywords();
        if(!has_field(private.test,label)) private.test[label] := [=];
        if(!has_field(private.test[label],'keywords')) 
            private.test[label].keywords := private.test.tabletool.
                getkeywords();
        return T;
    }

    const private.setsubtablenames := function() {
        wider private;
        if(len(private.model[label].subtables) == 0 && 
           len(private.test[label].subtables) == 0) {
            private.setkeywords();
            for(f in field_names(private.model[label].keywords)) {
                v := private.model[label].keywords[f];
                if(is_string(v) && v ~ m/^Table:/)
                    private.model[label].subtables := 
                        [private.model[label].subtables,f];
            }
            for(f in field_names(private.test[label].keywords)) {
                v := private.test[label].keywords[f];
                if(is_string(v) && v ~ m/^Table:/)
                    private.test[label].subtables := 
                        [private.test[label].subtables,f];
            }
        }
        return T;
    }

    const private.splice := function(ref target,addition) {
        for(f in field_names(addition)) {
            if(!has_field(target,f)) 
                target[f] := addition[f];
            else 
                private.splice(target[f],addition[f]);
        }
        return T;
    }

    private.checkcol := function(col) {
        wider private;
        if(len(private.select.checkonlycols) > 0) {
            if(is_record(private.select.checkonlycols)) {
                if(!has_field(private.select.checkonlycols, label)) return F;
                else if(!any(private.select.checkonlycols[label] == col)) 
                    return F;
                else return T;
            } 
            else return any(private.select.checkonlycols == col);
        }
        if(len(private.select.nocheckcols) > 0) {
            if(is_record(private.select.nocheckcols)) {
                if(has_field(private.select.nocheckcols, label)
                   && any(private.select.nocheckcols[label] == col)) return F;
                else return T;
            } else return !any(private.select.nocheckcols == col);
        }

        return T;
    }

    const public.checkcolnames := function(checksubtables=T) {
        wider private;
        private.setcolnames();
        if((len(private.test[label].colnames) == 
            len(private.model[label].colnames)) &&
           all(private.test[label].colnames == private.model[label].colnames)) 
        {
            private.summary[label].COLNAMES := T;
            if(private.verbose > 1) note(spaste('Column name test passed ',
                                                'on table ',label),
                                         origin=private.this);
        } else {
            private.summary[label].COLNAMES := F;
            if(private.verbose > 0) 
                note(spaste('Column name test failed on table ', label),
                     priority='SEVERE',origin=private.this);   
            if(private.verbose > 1) {
                note(spaste('TEST TABLE COLS: ',
                            private.test[label].colnames), priority='SEVERE',
                            origin=private.this);
                note(spaste('MODEL TABLE COLS: ',
                            private.model[label].colnames), priority='SEVERE',
                            origin=private.this);
            }
        }
        ok := private.summary[label].COLNAMES;
        if(checksubtables) {
            private.setsubtablenames();
            for(t in private.test[label].subtables) { 
                if(any(t == private.model[label].subtables)) {
                    print 'Opening ',t;
                    tc := tablecomparer(private.test.tabletool.getkeyword(t),
                                        private.model.tabletool.getkeyword(t),
                                        t, private.verbose);
                    res := tc.checkcolnames();
                    private.splice(private.summary,tc.summary());
                    tc.done();
                    if(!res) ok := F;
                }
            }
        }
        return ok;
    }
               
    const public.checkcolkeywordnames := function(checksubtables=T) {
        wider private;
        private.setcolnames();
        private.summary[label].COLKEYWORDNAMES := [=];
        ok := T;
        for (c in private.model[label].colnames) {
            if(!private.checkcol(c)) {
                if(verbose > 1) 
                    note(spaste('Skipping column ',c,' of table ',label,
                                ' because of selection.'),origin=private.this);
                next;
            }
            if(any(c == private.test[label].colnames)) {
                testcolkeywordnames := private.test.tabletool.
                    colkeywordnames(c);
                modelcolkeywordnames := private.model.tabletool.
                    colkeywordnames(c);
                if(all(testcolkeywordnames == modelcolkeywordnames)) {
                    private.summary[label].COLKEYWORDNAMES[c] := T;
                    if(private.verbose > 1) 
                        note(spaste('Column keyword name test passed on ',
                                    'table ',label,' column ',c),
                             origin=private.this);
                } else {
                    ok := F;
                    private.summary[label].COLKEYWORDNAMES[c] := F;
                    if(private.verbose > 0)  
                        note(spaste('Column keyword name test failed on ',
                                    'table ', label,' column ',c),
                             origin=private.this,priority='SEVERE');   
                    if(private.verbose > 1) {
                        note(spaste('TEST  ', testcolkeywordnames,
                                    origin=private.this));
                        note(spaste('MODEL ', modelcolkeywordnames,
                                    origin=private.this));
                    }
                }
            }
        }
        if(checksubtables) {
            private.setsubtablenames();
            for(t in private.test[label].subtables) { 
                if(any(t == private.model[label].subtables)) {
                    tc := tablecomparer(private.test.tabletool.getkeyword(t),
                                        private.model.tabletool.getkeyword(t),
                                        t, private.verbose);
                    tc.select(private.select.checkonlycols,
                              private.select.checkonlycols);
                    res := tc.checkcolkeywordnames();
                    private.splice(private.summary,tc.summary());
                    tc.done();
                    if(!res) ok := F;
                }
            }
        }
        return ok;
    }


    const public.checkcoldata := function(checksubtables=T) {
        wider private,public;
        ok := T;
        if(!has_field(private.summary,label)) private.summary[label] := [=];
        if(!has_field(private.details.model,label)) 
            private.details.model[label] := [=];
        if(!has_field(private.details.test,label)) 
            private.details.test[label] := [=];
        if(!has_field(private.details.diff,label)) 
            private.details.diff[label] := [=];
        private.setcolnames();
        for (c in private.model[label].colnames) {
            if(!private.checkcol(c)) {
                if(verbose > 1) 
                    note(spaste('Skipping column ',c,' of table ',label,
                                ' because of selection.'),origin=private.this);
                next;
            }
            if(verbose > 2) note(spaste('Checking column ',c));
            passed := T;
            
            epsilon := public.tolerance(c);
            usetolerance := epsilon > 0;

            if(verbose > 2 && usetolerance) 
                note(spaste('Using tolerance ',epsilon,
                            ' on table ',label,' column ',c));
            if(private.model.tabletool.isvarcol(c)) {
                modelcol := private.model.tabletool.getvarcol(c);
                testcol := private.test.tabletool.getvarcol(c);
                if(usetolerance) {
                    for (f in field_names(testcol)) {
                        if(is_unset(testcol[f]) && is_unset(modelcol[f]))
                            next;
                        if(!all(abs(testcol[f] - modelcol[f]) < epsilon)) {
                            passed := F;
                            break;
                        }
                    }
                } else {
                    for (f in field_names(testcol)) {
                        if(is_unset(testcol[f]) && is_unset(modelcol[f]))
                            next;
                        if(!all(testcol[f] == modelcol[f])) {
                            passed := F;
                            break;
                        }
                    }
                }
            } else {
                modelcol := private.model.tabletool.getcol(c);
                testcol := private.test.tabletool.getcol(c);
                if(usetolerance) 
                    if(!all(abs(testcol - modelcol) < epsilon)) passed := F;
                else
                    if(!all(testcol == modelcol)) passed := F;
            }
            if(is_fail(modelcol)) fail(modelcol::message);
            if(is_fail(testcol)) fail(testcol::message);
            if(passed) {
                private.summary[label].COLVALUES[c] := T;
                if(private.verbose > 1) 
                    note(spaste('Column data test passed on ',
                                'table ',label,' column ',c),
                         origin=private.this);
            } else {
                ok := F;
                private.summary[label].COLVALUES[c] := F;
                private.details.test[label][c] := testcol;
                private.details.model[label][c] := modelcol;
                if(len(testcol) == len(modelcol) && !is_record(testcol) &&
                   is_numeric(testcol)) 
                    private.details.diff[label][c] := testcol-modelcol;
                if(private.verbose > 0) 
                    note(spaste('Column data test failed on ',
                                'table ', label,' column ',c),
                         origin=private.this,priority='SEVERE');
            }
        }
        if(checksubtables) {
            private.setsubtablenames();
            for(t in private.test[label].subtables) { 
                if(any(t == private.model[label].subtables)) {
                    tc := tablecomparer(private.test.tabletool.getkeyword(t),
                                        private.model.tabletool.getkeyword(t),
                                        t, private.verbose);
                    tc.select(private.select.checkonlycols);
                    tc.settolerance(private.precision.float, 
                                    private.precision.double, 
                                    private.precision.complex, 
                                    private.precision.dcomplex, 
                                    private.precision.specificcols);  
                    res := tc.checkcoldata();
                    private.splice(private.summary,tc.summary());
                    private.splice(private.details,tc.details());
                    tc.done();
                    if(!res) ok := F;
                }
            }
        }
        return ok;
    }

    const public.checkkeywordnames := function(checksubtables=T) {
        wider private;
        private.setkeywords();
        ok := T;
        if(all(sort(field_names(private.test[label].keywords)) 
               == sort(field_names(private.model[label].keywords)))) {
            private.summary[label].KEYWORDFIELDNAMES := T;
            if(private.verbose > 1) 
                note(spaste('Keyword field names test passed for ',
                            'table ',label),origin=private.this);
        } else {
            private.summary[label].KEYWORDFIELDNAMES := F;
            ok := F;
            if(private.verbose > 0) 
                note(spaste('Keyword field names test failed on ',
                            'table ',label),origin=private.this,
                     priority='SEVER');   
            if(private.verbose > 1) {
                note(spaste('TEST  ', 
                            field_names(private.test[label].keywords)),
                            origin=private.this,priority='SEVERE');
                note(spaste('MODEL ', 
                            field_names(private.model[label].keywords)),
                     origin=private.this,priority='SEVERE');
            }
        }
        if(checksubtables) {
            private.setsubtablenames();
            for(t in private.test[label].subtables) { 
                if(any(t == private.model[label].subtables)) {
                    tc := tablecomparer(private.test.tabletool.getkeyword(t),
                                        private.model.tabletool.getkeyword(t),
                                        t, private.verbose);
                    res := tc.checkkeywordnames(T);
                    private.splice(private.summary,tc.summary());
                    tc.done();
                    if(!res) ok := F;
                }
            }
        }
        return ok;
    }

    #@
    # deprecated, use public.settolerance()

    const public.setprecision := function(float=0, double=0, complex=0,
                                          dcomplex=0, cols=[=]) {
        wider public;
        public.settolerance(float, double, complex, dcomplex, cols);
    }

        

    const public.settolerance := function(float=0, double=0, complex=0,
                                          dcomplex=0, cols=[=]) {
        wider private;
        private.precision.float := float;
        private.precision.double := double;
        private.precision.complex := complex;
        private.precision.dcomplex := dcomplex;
        private.precision.specificcols := cols;
        private.precision::isset := float > 0 || double > 0 || complex > 0 ||
            dcomplex > 0 || len(cols) > 0;
        return T;
    }

    const public.select := function(checkonlycols=[], nocheckcols=[]) {
        wider private;
        if(is_record(checkonlycols)) 
            private.select.checkonlycols := [=];
        private.select.checkonlycols := checkonlycols;
        if(is_record(nocheckcols)) 
            private.select.nocheckcols := [=];
        private.select.nocheckcols := nocheckcols;
        if(len(checkonlycols) > 0 && len(nocheckcols) > 0)
            note(spaste('Both checkonlycols and nocheckcols were specified, ',
                        'but only checkonlycols will be used'),
                 origin=private.this,priority='WARN');
        return T;
    }


    const public.tolerance := function(col,tlabel='') {
        wider private;
        if(tlabel == '') tlabel := label;
        if(!private.precision::isset) return 0;
        if(has_field(private.precision.specificcols,tlabel) &&
           has_field(private.precision.specificcols[tlabel],col))
            return private.precision.specificcols[tlabel][col];
        type := private.test.tabletool.coldatatype(col);
        if(type == 'float') return private.precision.float;
        if(type == 'double') return private.precision.double ;
        if(type == 'complex') return private.precision.complex;
        if(type == 'dcomplex') return private.precision.dcomplex;
        return 0;
    }

    #@
    # do the actual comparisons, function recursively calls itself for subtable
    # checking
    # @param checksubtables also check subtables?
    # @param checkcolnames do column name check?
    # @param checkcolkeywordnames check column keywords?
    # @param checkcoldata compare column data?
    # @param checktablekeywordnames do table keyword check?

    const public.compare := function(checksubtables=T, checkcolnames=T, 
                                     checkcolkeywordnames=T, checkcoldata=T, 
                                     checktablekeywordnames=T) {
        # compare column names
        wider private;
        ok := T;

        if(checkcolnames) {
            res := public.checkcolnames(F);
            if(!res) ok := F;
        }
            
        if(checkcolkeywordnames) {
            res := public.checkcolkeywordnames(F);
            if(!res) ok := F;
        }

        if(checkcoldata) {
            res := public.checkcoldata(F);
            if(!res) ok := F;
        }

        if(checktablekeywordnames) {
            res := public.checkkeywordnames(F);
            if(!res) ok := F;
        }

        if(checksubtables) {
            private.setsubtablenames();
            for(t in private.test[label].subtables) { 
                if(any(t == private.model[label].subtables)) {
                    tc := tablecomparer(private.test.tabletool.getkeyword(t),
                                        private.model.tabletool.getkeyword(t),
                                        t, private.verbose);
                    tc.select(private.select.checkonlycols,
                              private.select.nocheckcols);
                    tc.settolerance(private.precision.float, 
                                    private.precision.double, 
                                    private.precision.complex, 
                                    private.precision.dcomplex, 
                                    private.precision.specificcols);  
                    res := tc.compare(checksubtables, checkcolnames,
                                      checkcolkeywordnames, checkcoldata,
                                      checktablekeywordnames);
                    private.splice(private.summary,tc.summary());
                    private.splice(private.details,tc.details());
                    tc.done();
                    if(!res) ok := F;
                }
            }
        }

        return ok;
    }

    const private.logit := function(rec,label='') {
        wider private;
        label := label ~ s/^\.//;
        for(f in field_names(rec)) {
            if(is_record(rec[f]))
                private.logit(rec[f],spaste(label,'.',f));
            else
                note(spaste(label,'.',f,': ',rec[f]),origin=private.this);
        }
    }


    const public.details := function() {
        wider private;
        return private.details;
    }

    const public.summary := function(dolog=F) {
        wider private;
        if(dolog) private.logit(private.summary);
        return private.summary;
    }

    const public.close := function() {
        private.model.tabletool.close();
        private.test.tabletool.close();
    }        

    const public.done := function() {
        wider public, private;
        public.close();
        private.model.tabletool.done();
        private.test.tabletool.done();
        private := F;
        val public := F;
        return T;
    }

    return ref public;
}

const tablecomparer := function(test, model, label='TABLE', verbose=1) {
    _define_tablecomparer(test, model, label, verbose);
}

