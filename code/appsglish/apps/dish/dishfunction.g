# dishfunction.g: the dish function operation.
#------------------------------------------------------------------------------
#   Copyright (C) 1999,2000,2001,2003
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
#    $Id: dishfunction.g,v 19.1 2004/08/25 01:09:59 cvsmgr Exp $
#
#------------------------------------------------------------------------------
pragma include once;

include 'dishfunctiongui.g';

const dishfunction := function(ref itsdish)
{
    public := [=];
    private := [=];

    # the default is to start off without the GUI
    private.gui := F;

    private.dish := itsdish;
    private.sdutil := F;
    private.fn := unset;
    private.history := unset;
    private.selection := unset;

    private.append := function(ref list, thing) {
	# appends thing to list
	for (i in 1:len(thing)) {
	    list[len(list)+i] := thing;
	}
    }

  # the function which actually does the work
  # parser(thefunction, recname) This substitutes all tokens in thefunction with

  #   the appropriate sdrecord field name using recname as the top-level name.
  #   The following tokens (which must be upper case) are recognized:
  #       DATA -> recname.data
  #       DESC -> recname.desc
  #       ARR  -> recname.data.arr
  #       HEADER -> recname.header
  #       NS_HEADER -> recname.ns_header
  #    Min-match is used (i.e. DA == DATA, A=ARR, etc).  The result is put into
  #    all lower case since all variables in an SDRecord must be in lower case.
  #    (this allows users to forget and use TSYS when they meant tsys).  A replacement
  #    only occurs if the nearest non-whitespace character on either side of thetoken is a
  #    non alphanumeric character (i.e. DATA ARR would not be replaced [there's no operation
  #    there, so it makes no sense] but DATA, ARR would be (this might be some function
  #    parameterization indicated by this syntax).
  # The result is returned and evaluated.
  private.parser := function(thefunction, recname)
  {
      everything := paste(thefunction);
      trailW := m/\W$/;
      leadW := m/^\W/;
      # min-match tokens
      tokens := ['(?:A)|(?:AR)|(?:ARR)',
                 '(?:DA)|(?:DAT)|(?:DATA)',
                 '(?:DE)|(?:DES)|(?:DESC)',
                 '(?:F)|(?:FL)|(?:FLA)|(?:FLAG)',
                 '(?:H)|(?:HE)|(?:HEA)|(?:HEAD)|(?:HEADE)|(?:HEADER)',
                 '(?:N)|(?:NS)|(?:NS_)|(?:NS_H)|(?:NS_HE)|(?:NS_HEA)|(?:NS_HEAD)|(?:NS_HEADE)|(?:NS_HEADER)'];
      values := [spaste(recname,'.data.arr'),
                 spaste(recname,'.data'),
                 spaste(recname,'.data.desc'),
                 spaste(recname,'.data.flag'),
                 spaste(recname,'.header'),
                 spaste(recname,'.ns_header')];

      s := split(thefunction);
      for (i in 1:len(s)) {
          if ((s[i] !~ leadW) && i > 1 && (s[i-1] !~ trailW)) continue;
          if ((s[i] !~ trailW) && i < len(s) && (s[i+1] !~ leadW)) continue;
          for (j in 1:len(tokens)) {
              basetok := spaste('/((?:^)|(?:\\w*\\W+))(',tokens[j],')((?:\\W+\\w*)|(?:$))/');
              thistok := eval(spaste('s',basetok,'$1',values[j],'$3/g'));
              thismatch := eval(spaste('m',basetok));
              count := 0;
              while (count < 1000 && (s[i] ~ thismatch)) {
                  s[i] := s[i] ~ thistok;
                  count +:= 1;
              }
          }
      }
      # translate to all lower case
      return tr('[A-Z]','[a-z]',spaste(s,' '));
  }

    private.updateGUIstate := function() {
	wider private;
	if (is_agent(private.gui)) {
	    private.gui.setfn(private.fn);
	    private.gui.sethistory(private.history);
	    private.gui.setselection(private.selection);
	}
    }

# lv: if boolean, get last selected, otherwise an SDRECORD/SDITERATOR has been
#     provided as lv; outf: if an SDITERATOR, can optionally provide an output
#     workingset.
    public.apply := function(lv=F,outf=F) {
        wider private;
        # the GUI always sets the state here before actually invoking apply
        # so we can rely on the private state to be correct
        if (is_boolean(lv)) {
           if (private.dish.doselect()) {
                if (private.dish.rm().selectionsize()==1) {
                        lv := private.dish.rm().getselectionvalues();
			nominee:=ref lv;
                        nname:=private.dish.rm().getselectionnames();
                } else {
                        return throw('did not work');
                }
           } else {
                lv := private.dish.rm().getlastviewed();
                nominee := ref lv.value;
                name := lv.name;
           }
        } else {
                nominee := ref lv;
                nname:='temp';
        }
        # This global is currently necessary because eval does its work
        # only on global things
                global __sdfunctemp__ := nominee;
        #
        if (is_boolean(__sdfunctemp__)) {
            private.dish.message('Error!  An SDRecord has not yet been viewed');
        # sditerator enabled
        } else if (is_sditerator(__sdfunctemp__)) {
            sdlength:=__sdfunctemp__.length();
            ok:=__sdfunctemp__.setlocation(1);
            if (is_boolean(outf)) {
                ok:=private.dish.open(spaste(nname,'_fn'),new=T);
            } else {
                ok:=private.dish.open(outf,new=T);
            }
            if (is_fail(ok))
            print 'did that fail somehow ',is_fail(ok);
#               return throw('Error: Couldn't create working set');
            if (is_boolean(private.sdutil)) private.sdutil := sdutil();
            if (is_unset(private.fn)) private.fn := '';
            for (i in 1:sdlength) {
                ok:=__sdfunctemp__.setlocation(i);
                global __temprec__:=__sdfunctemp__.get();
                todo := private.parser(private.fn,"__temprec__");
                newArr := eval(todo);
                theOpp := spaste('The operation, ', private.fn, ', ');
                if (is_fail(newArr)) {
                   private.dish.message(spaste(theOpp,' failed.'));
                return;
                }
                if (!is_numeric(newArr)) {
                        private.dish.message(spaste(theOpp,
                                ' did not return a numeric result.'));
                        return;
                }
            # we require the resulting shape to be the same as the original
            # shape for now
                if (!(has_field(newArr::,"shape") &&
                  len(newArr::shape) == len(__temprec__.data.arr::shape) &&
                  newArr::shape == __temprec__.data.arr::shape)) {
                  private.dish.message(spaste(theOpp,
                        ' resulted in an array of the wrong shape.'));
                  return;
                }
                __temprec__.data.arr := newArr;
                # insert this into the workingset
            rmlen:=private.dish.rm().size();
           ok:=private.dish.ops().save.setws(private.dish.rm().getnames(rmlen));
           ok:=private.dish.ops().save.apply(__temprec__);
            } # loop through iterator!
        } else if (is_sdrecord(__sdfunctemp__)) {
            if (is_boolean(private.sdutil)) private.sdutil := sdutil();

            if (is_unset(private.fn)) private.fn := '';
            todo := private.parser(private.fn,"__sdfunctemp__");
            newArr := eval(todo);
            theOpp := spaste('The operation, ', private.fn, ', ');
            if (is_fail(newArr)) {
                private.dish.message(spaste(theOpp,' failed.'));
                return;
            }
            if (!is_numeric(newArr)) {
                private.dish.message(spaste(theOpp,' did not return a numeric result.'));
                return;
            }
            # we require the resulting shape to be the same as the original shape for now
            if (!(has_field(newArr::,"shape") &&
                  len(newArr::shape) == len(__sdfunctemp__.data.arr::shape) &&
                  newArr::shape == __sdfunctemp__.data.arr::shape)) {
                private.dish.message(spaste(theOpp,' resulted in an array of the wrong shape.'));
                return;
            }
            __sdfunctemp__.data.arr := newArr;

            # insert this into the results manager
            # set the history line
            private.append(__sdfunctemp__.hist, as_string(private.dish.history('dish.ops().function.setfn',[fn=private.fn])));
	    private.append(__sdfunctemp__.hist, as_string(private.dish.history('dish.ops().function.apply')));
            resultDescription := spaste('function applied to data.');
            resultName := private.dish.rm().add('applyfunc',resultDescription,
                                                __sdfunctemp__, 'SDRECORD');
            # show the result and set current focus to it
            # this should always be at the 'end'
            private.dish.rm().select('end');

            private.dish.message(resultDescription);
        } else {
            private.dish.message('Applying a function is not supported on the current selection in the results manager');
        }

        return T;
    }

    # dismiss the gui
    public.dismissgui := function() {
        wider private;
        if (is_agent(private.gui)) {
            private.gui.done();
        }
        private.gui := F;
        return T;
    }

    # done with this closure, this makes it impossible to use the public
    # part of this after invoking this function
    public.done := function() {
        wider private;
        wider public;
        public.dismissgui();
        val private := F;
        val public := F;
        return T;
    }

    public.getfn := function() {
        wider private;
        if (is_agent(private.gui)) {
            private.fn := private.gui.getfn();
        }
        return private.fn;
    }

    # return any state information as a record
    public.getstate := function() {
        wider private, public;
        state := [=];
	if (is_agent(private.gui)) {
        	state.fn := public.getfn();
	}
        state.history := unset;
        state.selection := unset;
        if (is_agent(private.gui)) {
            state.history := private.gui.gethistory();
            state.selection := private.gui.getselection();
        }
        return state;
    }

    public.gui := function(parent, widgetset=dws) {
        wider private;
        wider public;
        # don't build one if we already have one or there is no display
        if (!is_agent(private.gui) && widgetset.have_gui()) {
            private.gui := dishfunctiongui(parent, public,
                                           itsdish.logcommand,
                                           widgetset);
            private.updateGUIstate();
            whenever private.gui->done do {
		wider private;
		if (is_record(private)) private.gui := F;
            }

        }
        return private.gui;
    }

    public.opmenuname := function() { return 'Function';}

    public.opfuncname := function() { return 'function';}

    public.setfn := function(fn, updateGUI=T) {
        wider private;
        if (is_string(fn)) {
            private.fn := fn;
            if (updateGUI && is_agent(private.gui)) {
                private.gui.setfn(private.fn);
            }
        }
        return T;
    }

    # set the state from the indicated record
    # invoking this with an empty record should reset this to its
    # initial state
    public.setstate := function(state) {
	wider public, private;
	result := F;
	if (is_record(state)) {
	    # default values;
	    private.fn := unset;
	    private.history := unset;
	    private.selection := unset;
	    if (has_field(state,'fn')) {
		private.fn := state.fn;
	    }
	    if (has_field(state, 'history')) {
		private.history := state.history;
	    }
	    if (has_field(state, 'selection')) {
		private.selection := state.selection;
	    }
	    private.updateGUIstate();
	    result := T;
	}
	return result;
    }

    # initialize to the default state
    public.setstate([=]);

#    public.debug := function() { wider private; return private;}

    # return the public interface
    return public;
}
