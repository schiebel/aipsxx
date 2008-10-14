#
#   Copyright (C) 1996,1997,1998,1999
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
#   $Id: vlacalflux.g,v 19.0 2003/07/16 03:42:38 aips2adm Exp $
#

pragma include once

include "note.g"
include "statistics.g"
include "table.g"
#
#vlacalflux.findscan is a routine for figuring out when scans occur in the
#calibrator flux table.
#
vlacalflux.loadcalflux := function(in_table, out_table)
{  if(!tableexists(in_table)){
       note('Can\'t open table', in_table);
       fail;
   }
   if(!tableexists(out_table)){
      sumTable := vlacalflux.make_summary_table(out_table);
   }else{
      sumTable := table(out_table, readonly=F);
   }
   calRow := tablerow(sumTable);
   calRec := [=];
   antsol := table(in_table);
   for(subarray in 1:4){
      query := spaste('subarray == ', subarray);
      antsol.sa := antsol.query(query, '/tmp/dummy');
      if(antsol.sa.nrows() > 1){
        note('Doing subarray', subarray);
        source := antsol.sa.getcol('source');
        corr_mode := antsol.sa.getcol('correlator_mode');
        epoch := antsol.sa.getcol('epoch');
        iat := antsol.sa.getcol('iat');
        mjad := antsol.sa.getcol('mjad');len
        calflux := antsol.sa.getcol('calflux');
        freq := antsol.sa.getcol('skyfreq');
        nant := antsol.sa.getcol('nant');
        goodif := antsol.sa.getcol('goodif');
        elev := antsol.sa.getcol('el');
        
        dsource := (source[1:(len(source)-1)] != source[2:len(source)]);

        dcorr_mode := (corr_mode[1:(len(corr_mode)-1)] !=
                       corr_mode[2:len(corr_mode)]);
        dfreq := (abs(freq[1:1,1:(len(freq)/4-1)]-freq[1:1,2:(len(freq)/4)]) > 0.000001);

        i:=0;
        hit := 0;  
        beg := 1;
        dsource[len(dsource)] := T;
        for(i in 1:len(dsource)){
          if(dsource[i] || dcorr_mode[i] || dfreq[i]){
             hit :=  hit+1;
             fin := i;
             if((fin-beg) > 5)
                beg := beg+1;
             aflux := calflux[1:1, beg:fin]
             agood := goodif[1:1, beg:fin]
             aflux := aflux[agood == 1]
             aflux := aflux[aflux < 40];

             bflux := calflux[2:2, beg:fin]
             bgood := goodif[2:2, beg:fin]
             bflux := bflux[bgood == 1]
             bflux := bflux[bflux < 40];

             cflux := calflux[3:3, beg:fin]
             cgood := goodif[3:3, beg:fin]
             cflux := cflux[cgood == 1]
             cflux := cflux[cflux < 40];

             dflux := calflux[4:4, beg:fin]
             dgood := goodif[4:4, beg:fin]
             dflux := dflux[dgood == 1]
             dflux := dflux[dflux < 40];
           
             calRec.Source          :=  split(source[beg]);
             calRec.Epoch           :=  epoch[beg];
             calRec.Correlator_Mode :=  corr_mode[beg];
             if(calRec.Correlator_Mode == '' || 
                calRec.Correlator_Mode ~ m/ */ )
                calRec.Correlator_Mode := 'CONT';
             calRec.MJAD           :=  mjad[beg];
             calRec.Start          :=  iat[beg];
             calRec.End            :=  iat[fin];
             calRec.El_End         :=  elev[fin]
#
             calRec.AC_Frequency   :=  freq[1:1, beg:beg];
             if((len(aflux) + len(cflux)) > 0){
                calRec.Mean_AC_Flux   :=  mean(aflux, cflux);
                calRec.Stddev_AC_Flux :=  stddev(aflux, cflux);
             } else {
                calRec.Mean_BD_Flux   :=  -1.0;
                calRec.Stddev_BD_Flux :=  -1.0;
             }
#
             calRec.BD_Frequency   :=  freq[2:2, beg:beg];
             if((len(bflux) + len(bflux)) > 0){
                calRec.Mean_BD_Flux   :=  mean(bflux, dflux);
                calRec.Stddev_BD_Flux :=  stddev(bflux, dflux);
             } else {
                calRec.Mean_BD_Flux   :=  -1.0;
                calRec.Stddev_BD_Flux :=  -1.0;
             }
             calRec.Antennas       :=  nant[fin:fin];
#
             dum := sumTable.addrows(1);
             dum := calRow.put(sumTable.nrows(), calRec);

             note(hit, calRec.Source, vlacalflux.hms(iat[beg]),
		  vlacalflux.hms(iat[fin]), fin-beg);
             beg := fin+1;
          }
        }
      }
   }
   sumTable.close();
   antsol.close();
}

# Create the summary table 

vlacalflux.make_summary_table := function(summary_table_name)
{ if(tableexists(summary_table_name))fail;
 col1 := tablecreatescalarcoldesc('Source' ,' ');
 col2 := tablecreatescalarcoldesc('Epoch' , 2000);
 col3 := tablecreatescalarcoldesc('Correlator_Mode' , ' ');
 col4 := tablecreatescalarcoldesc('MJAD' , 50000);
 col5 := tablecreatescalarcoldesc('Start' ,0.0);
 col6 := tablecreatescalarcoldesc('End' ,6.28);
 col7 := tablecreatescalarcoldesc('El_End' ,0.00);
 col8 := tablecreatescalarcoldesc('AC_Frequency' , 0.00);
 col9 := tablecreatescalarcoldesc('Mean_AC_Flux' ,0.00);
 cola := tablecreatescalarcoldesc('Stddev_AC_Flux' ,0.00);
 colb := tablecreatescalarcoldesc('BD_Frequency' , 0.00);
 colc := tablecreatescalarcoldesc('Mean_BD_Flux' ,0.00);
 cold := tablecreatescalarcoldesc('Stddev_BD_Flux' ,0.00);
 cole := tablecreatescalarcoldesc('Antennas' , 0);
 td := tablecreatedesc(col1, col2, col3, col4, col5, col6, col7, col8, col9,
                       cola, colb, colc, cold, cole);
 return table(summary_table_name, td);
}

#Get data from the summary table

vlacalflux.fetch_data := function(sum_table_name, source_name, mjad_start=0,
                                  iat_start=0.0, mjad_stop=60000,
                                  iat_stop=6.29)
{
   master := table(sum_table_name);
   query := spaste(' Source == \'', source_name, '\'')
# '\' && MJAD >= ', mjad_start,
#                   ' && Start >= ', iat_start, ' && MJAD <= ', mjad_stop,
#                   ' && End <= ',iat_stop);
   return master.query(query);
}

#turns radians into something a bit more readable

vlacalflux.hms := function(rad)
{
   hr := 12*rad/3.1415;
   mn := hr - floor(hr);
   hr := floor(hr);
   mn := 60*mn;
   sec := 60*(mn - floor(mn));
   mn := floor(mn);
   hms_format := sprintf("%02d:%02d:%06.3f", hr, mn, sec);
   return hms_format;
}

const vlacalflux := vlacalflux;
const vcf := vlacalflux;

