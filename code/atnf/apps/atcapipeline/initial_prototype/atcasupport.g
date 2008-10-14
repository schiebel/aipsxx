pragma include once

include 'misc.g'
include 'note.g'
include 'os.g'
include 'serverexists.g'


atcasupport := subsequence ()
{
   if (!serverexists('dos', 'os', dos)) {
      return throw('The os server "dos" is either not running or not valid', 
                    origin='atcacalibrater.g');
   }
   if (!serverexists('dms', 'misc', dms)) {
      return throw('The misc server "dms" is either not running or not valid', 
                    origin='atcacalibrater.g');
   }


# Private

   its:=[=]
# 

# Public

###
   const self.deletefiles := function (filenames)
   {
      if (length(filenames) > 0) {
         for (name in filenames) {
            ok := dos.remove (pathname=name, mustexist=F);
            if (is_fail(ok)) fail;
         }
      }
#
      return T;
   }

###
   const self.directoryname := function (filename)
   {
      return dos.dirname(filename);
   }



###
   const self.findID := function (idrec, names)
#
# Converts names to field_id
# Use with the record returned by self.createMSRec
#
   {
      n1 := length(names)
      if (n1<1) fail 'No names given';

# Don't do this with direct Glish vector indexing functions
# since there may be entries in names that aren't in the 
# record list

      k := 1;
      list := [];
      n2 := length(idrec.fields.names);
      for (i in 1:n1) {
         name := to_upper(names[i]);
         for (j in 1:n2) { 
            if (to_upper(idrec.fields.names[j])==name) { 
               list[k] := idrec.fields.ids[j];
               k +:= 1;
            }
         }
      }   
#
      if (length(list)==0) fail 'No matches in list';
      return list;
   }      

###
   const self.createMSRec := function (filename)
#
# Returns things from the MS
#
# Fields are:
#   num_chan
#   num_corr
#   data_desc_id
#   chan_freq
#   ref_frequency
#   spwids
#   spwidSource
#   fields.{names,ids}
# 
   {
      rec := [=];

# First access DATA_DESCRIPTION table

      include 'table.g'
      t := table(spaste(filename, '/DATA_DESCRIPTION'));
      if (is_fail(t)) fail;

# Find list of spectral window IDs

      spwIDs := t.getcol('SPECTRAL_WINDOW_ID') + 1;   # Convert to 1-rel
      if (is_fail(spwIDs)) fail;
      rec.spwids := spwIDs;
#
      t.done();

 # Get stuff from MS

      include 'ms.g'
      msTool := ms(filename);
      if (is_fail(msTool)) fail;

# Now find which fields exist per spwid

      nDataDesc := length(spwIDs);
      rec2 := [=];
      for (i in 1:nDataDesc) {
         ok := msTool.selectinit (datadescid=i);
         if (is_fail(ok)) fail;
#
         fieldIDs:= msTool.range(items='FIELD_ID');
         if (is_fail(fieldIDs)) fail;
#
         fieldNames:= msTool.range(items='FIELDS');
         if (is_fail(fieldNames)) fail;
#
         spwid := spaste(spwIDs[i]);
         rec2[spwid] := [=];
         rec2[spwid].ids := fieldIDs.field_id;
         rec2[spwid].names := fieldNames.fields;
      }
      rec.spwidSource := rec2;

# Reset

      ok := msTool.selectinit (reset=T);
      if (is_fail(ok)) fail;

# Now find a list of names that match the field IDs in the data

      names := msTool.range(items='FIELDS');
      if (is_fail(names)) fail;
      ids := msTool.range(items='FIELD_ID');
      if (is_fail(ids)) fail;
#
      x := names.fields;
      y := ids.field_id;
      newNames := "";
      for (i in 1:length(y)) {
        newNames[i] := x[y[i]];
      }
      rec.fields := [=];
      rec.fields.ids := y;
      rec.fields.names := newNames;

# Correlator things

      r := msTool.range(items='num_chan');
      if (is_fail(r)) fail;
      rec.num_chan := r.num_chan;
#
      r := msTool.range(items='num_corr');
      if (is_fail(r)) fail;
      rec.num_corr := r.num_corr;
#
      r := msTool.range(items='data_desc_id');
      if (is_fail(r)) fail;
      rec.data_desc_id := r.data_desc_id;
#
      r := msTool.range(items='chan_freq');
      if (is_fail(r)) fail;
      rec.chan_freq := r.chan_freq;
#
      r := msTool.range(items='ref_frequency');
      if (is_fail(r)) fail;
      rec.ref_frequency := r.ref_frequency;

# Done with MS tool

      ok := msTool.done(); 
      if (is_fail(ok)) fail;
#
      return rec;
   }

#
   const self.done := function ()
   {
      wider its;
      wider self;
#
      val its := F;
      val self := F;
      return T;
   }


# Constructor

}
