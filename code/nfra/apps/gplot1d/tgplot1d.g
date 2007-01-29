# tgplot1d.g: some test functions for gplot1d
#
#   Copyright (C) 1995,1996,1997
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
#   $Id: tgplot1d.g,v 19.0 2003/07/16 03:38:47 aips2adm Exp $
#
#-----------------------------------------------------------------------------
pragma include once

include "gplot1d.g"
#-----------------------------------------------------------------------------
testVector := function (size=10) {

  v := array (1:size)
  for (i in 1:size) v [i] := i * i * i;

  rec := [data=v, name="test vector"];
  plotClient->vector (rec)
  await plotClient->vector_result;
  return $value;
}
#------------------------------------------------------------------------------
sin1 := function (size, name_) {

  v := array (1:size)
  for (i in 1:size) v [i] := sin (i * 4 / 57);

  rec := [data=v, name=name_];
  plotClient->vector (rec)
  await plotClient->vector_result;
  print "vector dataset ", $value, " added";

}
#------------------------------------------------------------------------------
cos1 := function (size=10, freq=1, name_="cos") {

  v := array (1:size)
  for (i in 1:size) v [i] := cos (i * 4 * freq / 57);

  rec := [data = v, name = paste (name_, size)];
  plotClient->vector (rec)
  await plotClient->vector_result;
  print "vector dataset ", $value, " added";
}
#------------------------------------------------------------------------------
testxy := function (size=8, name_ = "simple xy") {

  x_ := array (1:size);

  midpoint := size / 2;
  y_ := array (1:size);
  for (i in 1:size) {
    if (i < midpoint)
       y_ [i] := i + midpoint;
    else
       y_ [i] :=  midpoint - i;
    }

  dataSetNumber := plotxy (x_, y_, name_);

  ignore := setPointSize (dataSetNumber,7);
  ignore := setPointColor (dataSetNumber,"red");
  ignore := setPointStyle (dataSetNumber,"square");
  return dataSetNumber;
}
#------------------------------------------------------------------------------
testxy2 := function (size=8, name_ = "simple xy2") {

  x_ := array (1:size);

  midpoint := size / 1.2;
  y_ := array (1:size);
  for (i in 1:size) {
    if (i < midpoint)
       y_ [i] := i + midpoint;
    else
       y_ [i] :=  midpoint - i;
    }

  y_ *:= 543;
  dataSetNumber := plotxy2 (x_, y_, name_); 

  if (dataSetNumber >= 0) {
    ignore := setPointSize (dataSetNumber,10);
    ignore := setPointColor (dataSetNumber,"black");
    ignore := setPointStyle (dataSetNumber,"square");
    }

  return dataSetNumber;
}
#------------------------------------------------------------------------------
testHistogram := function (size=8, name_="histogram") {

  x_ := array (1:size);
  for (i in 1:size) x_ [i] := i;

  midpoint := size / 2;
  y_ := array (1:size);
  for (i in 1:size) {
    if (i < midpoint)
       y_ [i] := i + midpoint;
    else
       y_ [i] :=  midpoint - i;
    }
  rec := [x = x_, y = y_, name = name_, style = "histogram"];
  plotClient->xy (rec)
  await plotClient->xy_result;
  print "histogram:  dataSet number ", $value , " created";

}
#------------------------------------------------------------------------------
lines := function (size=12) {

  freq := 4;
  x_ := array (1:size)
  for (i in 1:size) x_ [i] := cos (i * 4 * freq / 57);

  y_ := array (1:size)
  for (i in 1:size) y_ [i] := sin (i * 4 * freq / 57);


  rec := [x = x_, y = y_, name = "style: lines", style="lines"];
  plotClient->xy (rec)
  await plotClient->xy_result;

  print "xy:  dataSet number ", $value , " created";
}
#------------------------------------------------------------------------------
points := function (size=12) {

  freq := 4;
  x_ := array (1:size)
  for (i in 1:size) x_ [i] := cos (i * 4 * freq / 57);

  y_ := array (1:size)
  for (i in 1:size) y_ [i] := sin (i * 4 * freq / 57);

  y_ := y_ * 0.8;

  rec := [x = x_, y = y_, name = "style: points", style="points"];
  plotClient->xy (rec)
  await plotClient->xy_result;

  print "xy:  dataSet number ", $value , " created";
}
#------------------------------------------------------------------------------
linespoints := function (size=12)
{
  freq := 4;
  x_ := array (1:size)
  for (i in 1:size) x_ [i] := cos (i * 4 * freq / 57);

  y_ := array (1:size)
  for (i in 1:size) y_ [i] := sin (i * 4 * freq / 57);

  y_ := y_ * 0.6;

  rec := [x = x_, y = y_, name = "style: linespoints", style="linespoints"];
  plotClient->xy (rec)
  await plotClient->xy_result;

  print "xy:  dataSet number ", $value , " created";
}
#------------------------------------------------------------------------------
testStyles := function ()
{
  junk := points ();
  junk := lines ();
  junk := linespoints ();
  return T;
}
#------------------------------------------------------------------------------
testAxes := function ()
{
  print "x axis at y min";
  plotClient->setXAxis ([strategy = "min"]);
  await plotClient->setXAxis_result;
  sleep (2);

  print "x axis at y max";
  plotClient->setXAxis ([strategy = "max"]);
  await plotClient->setXAxis_result;
  sleep (2);

  print "x axis at y=10.0"
  plotClient->setXAxis ([strategy = "explicit", where = 10.0]);
  await plotClient->setXAxis_result;
  sleep (2);

  print "x axis auto positioned"
  plotClient->setXAxis ([strategy = "auto"]);
  await plotClient->setXAxis_result;
  sleep (2);

  print "y axis at x max";
  plotClient->setYAxis ([strategy = "max"]);
  await plotClient->setYAxis_result;
  sleep (2);

  print "y axis at x min";
  plotClient->setYAxis ([strategy = "min"]);
  await plotClient->setYAxis_result;
  sleep (2);

  print "y axis at x=10.0"
  plotClient->setYAxis ([strategy = "explicit", where = 10.0]);
  await plotClient->setYAxis_result;
  sleep (2);

  print "y axis auto positioned";
  plotClient->setYAxis ([strategy = "auto"]);
  await plotClient->setYAxis_result;
  sleep (2);

  return T;
}
#------------------------------------------------------------------------------
w43 := function ()
{

 # -299.1644920
 # 5.2028607319
 numberOfChannels := 128;
 x_ := array (1:numberOfChannels);
 y_ := array (1:numberOfChannels);
 
 y_ [ 1] := -0.573624700   
 y_ [ 2] := 0.0169003538   
 y_ [ 3] := -0.003071939   
 y_ [ 4] := 0.0059647047   
 y_ [ 5] := -0.010733442   
 y_ [ 6] := -0.003137422   
 y_ [ 7] := -0.002875490   
 y_ [ 8] := 0.0105485097   
 y_ [ 9] := 0.0072088803   
 y_ [10] := -0.000583588   
 y_ [11] := -0.029592525   
 y_ [12] := 0.0166384221   
 y_ [13] := 0.0029524899   
 y_ [14] := 0.0072088803   
 y_ [15] := -0.005625773   
 y_ [16] := -0.018984291   
 y_ [17] := 0.0053753583   
 y_ [18] := 0.0035418363   
 y_ [19] := -0.001107451   
 y_ [20] := 0.0161800416   
 y_ [21] := 0.0071433974   
 y_ [22] := -0.001958729   
 y_ [23] := 0.0186683929   
 y_ [24] := -0.010340544   
 y_ [25] := -0.124804704   
 y_ [26] := -0.213992454   
 y_ [27] := -0.249615167   
 y_ [28] := -0.327081472   
 y_ [29] := -0.334088146   
 y_ [30] := -0.248240026   
 y_ [31] := -0.334481043   
 y_ [32] := -0.515279410   
 y_ [33] := -0.637208624   
 y_ [34] := -0.775377605   
 y_ [35] := -0.977981787   
 y_ [36] := -0.906867326   
 y_ [37] := -0.985774256   
 y_ [38] := -0.527131820   
 y_ [39] := -0.289625237   
 y_ [40] := -0.310841706   
 y_ [41] := -0.335332321   
 y_ [42] := -0.409589963   
 y_ [43] := -0.275218992   
 y_ [44] := -0.252430933   
 y_ [45] := -0.221784922   
 y_ [46] := -0.180072296   
 y_ [47] := -0.127358538   
 y_ [48] := -0.182364199   
 y_ [49] := -0.043867804   
 y_ [50] := -0.042885560   
 y_ [51] := -0.057553736   
 y_ [52] := -0.009882164   
 y_ [53] := -0.041117521   
 y_ [54] := -0.007721227   
 y_ [55] := -0.001434866   
 y_ [56] := -0.012370515   
 y_ [57] := 0.0041966656   
 y_ [58] := -0.013352759   
 y_ [59] := -0.017740115   
 y_ [60] := -0.045439394   
 y_ [61] := -0.083419493   
 y_ [62] := -0.044719082   
 y_ [63] := -0.082044351   
 y_ [64] := -0.113672606   
 y_ [65] := -0.142092197   
 y_ [66] := -0.503885381   
 y_ [67] := -0.850290075   
 y_ [68] := -0.766340960   
 y_ [69] := -0.581875549   
 y_ [70] := -0.727836998   
 y_ [71] := -0.815846055   
 y_ [72] := -0.383789689   
 y_ [73] := -0.191204394   
 y_ [74] := -0.243656220   
 y_ [75] := -0.281832768   
 y_ [76] := -0.453005145   
 y_ [77] := -0.775115673   
 y_ [78] := -0.816042504   
 y_ [79] := -0.651942283   
 y_ [80] := -0.453201594   
 y_ [81] := -0.381104889   
 y_ [82] := -0.455689945   
 y_ [83] := -0.558563626   
 y_ [84] := -0.495372600   
 y_ [85] := -0.631380644   
 y_ [86] := -0.878578701   
 y_ [87] := -0.972939602   
 y_ [88] := -0.959253669   
 y_ [89] := -1.000000000   
 y_ [90] := -0.957158216   
 y_ [91] := -0.973070567   
 y_ [92] := -0.949431230   
 y_ [93] := -0.935024986   
 y_ [94] := -0.999984051   
 y_ [95] := -0.939805239   
 y_ [96] := -0.879691911   
 y_ [97] := -0.838437665   
 y_ [98] := -0.780354307   
 y_ [99] := -0.808381001   
 y_ [100] := -0.859850583   
 y_ [101] := -0.876286798   
 y_ [102] := -0.921273571   
 y_ [103] := -0.785134561   
 y_ [104] := -0.619528233   
 y_ [105] := -0.432705437   
 y_ [106] := -0.186948004   
 y_ [107] := -0.021014262   
 y_ [108] := -0.000125207   
 y_ [109] := 0.0117926853   
 y_ [110] := -0.018460427   
 y_ [111] := 0.0085185389   
 y_ [112] := 0.0077327437   
 y_ [113] := -0.019180740   
 y_ [114] := -0.013614691   
 y_ [115] := 0.0079291925   
 y_ [116] := 0.0182754953   
 y_ [117] := 0.0143465196   
 y_ [118] := 0.0071433974   
 y_ [119] := -0.015186281   
 y_ [120] := -0.037254028   
 y_ [121] := -0.014007588   
 y_ [122] := 0.0028870070   
 y_ [123] := 0.0055718071   
 y_ [124] := 0.0043276314   
 y_ [125] := 0.0032144216   
 y_ [126] := 0.0110068902   
 y_ [127] := -0.000059724   
 y_ [128] := 0.0190612905   

  rec := [x = x_, y = y_, name = "w43", style = "histogram"];
  plotClient->xy (rec)
  await plotClient->xy_result;
  print "histogram:  dataSet number ", $value , " created";

}
#------------------------------------------------------------------------------
giantHill := function ()
{
  numberOfChannels := 116;
  x_ := array (1:numberOfChannels);
  y_ := array (1:numberOfChannels);

  # -299.1644920
  # 5.2028607319
 
  y_ [1] := 0.0238761287
  y_ [2] := 0.0219698273
  y_ [3] := 0.0541046227
  y_ [4] := 0.0173402381
  y_ [5] := 0.0410328415
  y_ [6] := 0.0451177731
  y_ [7] := 0.0189742108
  y_ [8] := -0.070621955
  y_ [9] := -0.057550174
  y_ [10] := 0.0265994164
  y_ [11] := -0.032223598
  y_ [12] := -0.001178118
  y_ [13] := 0.0225144848
  y_ [14] := 0.0059024296
  y_ [15] := 0.0304120193
  y_ [16] := 0.0905966784
  y_ [17] := 0.1978942155
  y_ [18] := 0.3329692876
  y_ [19] := 0.4677720308
  y_ [20] := 0.4969112097
  y_ [21] := 0.5837840887
  y_ [22] := 0.6777375158
  y_ [23] := 0.7539895726
  y_ [24] := 0.7411901202
  y_ [25] := 0.7338372433
  y_ [26] := 0.7264843664
  y_ [27] := 0.4707676473
  y_ [28] := 0.3514876442
  y_ [29] := 0.4500706605
  y_ [30] := 0.5225101144
  y_ [31] := 0.8280629992
  y_ [32] := 1.2991917787
  y_ [33] := 1.6289819243
  y_ [34] := 1.3005534225
  y_ [35] := 1.2790394494
  y_ [36] := 0.9239227277
  y_ [37] := 0.6889029955
  y_ [38] := 0.8871583432
  y_ [39] := 1.1061106777
  y_ [40] := 1.3062723268
  y_ [41] := 1.1771884878
  y_ [42] := 1.3305095877
  y_ [43] := 1.0644443753
  y_ [44] := 1.3375901358
  y_ [45] := 1.3487556156
  y_ [46] := 1.5423813741
  y_ [47] := 2.6077315391
  y_ [48] := 2.5794093465
  y_ [49] := 3.2441638845
  y_ [50] := 3.9887107534
  y_ [51] := 5.5205601087
  y_ [52] := 2.6959660619
  y_ [53] := 0.8139019029
  y_ [54] := 4.2267261021
  y_ [55] := 7.6392779725
  y_ [56] := 7.1384653566
  y_ [57] := 2.6319688000
  y_ [58] := 0.2787758615
  y_ [59] := 6.6872165777
  y_ [60] := 11.797738356
  y_ [61] := 12.153944392
  y_ [62] := 13.748974023
  y_ [63] := 14.588835963
  y_ [64] := 15.960283670
  y_ [65] := 17.721706182
  y_ [66] := 17.599975220
  y_ [67] := 17.612502344
  y_ [68] := 17.360325899
  y_ [69] := 16.101077647
  y_ [70] := 13.718200872
  y_ [71] := 11.407763551
  y_ [72] := 10.025422693
  y_ [73] := 9.5736292562
  y_ [74] := 8.8917180054
  y_ [75] := 6.8089475398
  y_ [76] := 4.5292833703
  y_ [77] := 3.4475934789
  y_ [78] := 2.5736904423
  y_ [79] := 1.6567594593
  y_ [80] := 1.0339435525
  y_ [81] := 0.5595468277
  y_ [82] := 0.4203868241
  y_ [83] := 0.3975112071
  y_ [84] := 0.3977835358
  y_ [85] := 0.5944049109
  y_ [86] := 1.4990810990
  y_ [87] := 1.0897709513
  y_ [88] := 1.3065446556
  y_ [89] := 1.4914558933
  y_ [90] := 2.5788646890
  y_ [91] := 2.7912811329
  y_ [92] := 2.3588230394
  y_ [93] := 1.4010427403
  y_ [94] := 0.5666273759
  y_ [95] := 0.1929922976
  y_ [96] := 0.0965879114
  y_ [97] := 0.0543769514
  y_ [98] := -0.003901406
  y_ [99] := 0.0769802397
  y_ [100] := -0.009075652
  y_ [101] := 0.0383095537
  y_ [102] := 0.0557385953
  y_ [103] := 0.0952262676
  y_ [104] := 0.0481133896
  y_ [105] := 0.0440284580
  y_ [106] := 0.0124383202
  y_ [107] := -0.053737571
  y_ [108] := 0.0184295532
  y_ [109] := -0.033857571
  y_ [110] := 0.0015451692
  y_ [111] := 0.0110766763
  y_ [112] := 0.0497473623
  y_ [113] := 0.0453901019
  y_ [114] := -0.035219215
  y_ [115] := 0.0380372250
  y_ [116] := 0.0511090061

  rec := [x = x_, y = y_, name = "Giant Hill", style = "histogram"];
  plotClient->xy (rec)
  await plotClient->xy_result;
  print "histogram:  dataSet number ", $value , " created";

}
#------------------------------------------------------------------------------
testSelectAndFit := function (repetitions = 10)
{
  for (i in 1:repetitions) {
    print "******************** iteration: ", i;
    s := getSelection ();
    c2 := fit (s.x, s.y, 2);
    f2 := evalPoly (s.x, c2xf);
    plotxy (s.x, f2, "auto f 2");
    sleep (2);
    }

}
#------------------------------------------------------------------------------
testRawAxisWith2YAxes := function ()
{

  x := array (0.0, 20)
  for (i in 1:len (x)) { x[i] +:= (i * 0.01); }
  y1 := array (100, 20);
  for (i in 1:len (y1)) y1 [i] *:= cos (i);
  dataSet1 := plotxy (x,y1, "x vs. y1")
  junk := setYAxisLabel ("y1 axis");
  junk := setPointSize (dataSet1, 6);
  y2 := array (20:1, 20);
  y2 *:= -109.876;
  dataSet2 := plotxy2 (x, y2, "x vs. y2");
  y3 := y1 * -1.0;
  junk := plotxy(x, y3, "x vs. y1a")
  y4 := y2 * -1.0;
  junk := plotxy2 (x, y4, "x vs. y2a")

}
#--------------------------------------------------------------------------
testTimeAxisWith2YAxes := function ()
{

  t := array (49891.0, 20)
  for (i in 1:len (t)) { t[i] +:= (i * 0.0001); }
  y1 := array (100, 20);
  for (i in 1:len (y1)) y1 [i] *:= cos (i);
  dataSet1 := timeY (t,y1, "time vs. y1")
  junk := setYAxisLabel ("y1 axis");
  junk := setPointSize (dataSet1, 6);
  y2 := array (20:1, 20);
  y2 *:= -109.876;
  dataSet2 := timeY2 (t, y2, "time vs. y2")
  junk := setY2AxisLabel ("y2 axis");
  y3 := y1 * -1.0;
  junk := timeY (t, y3, "time vs. y1a")
  y4 := y2 * -1.0;
  junk := timeY2 (t, y4, "time vs. y2a")

}
#--------------------------------------------------------------------------
test2AxisStyleControl := function ()
# make sure to run 'testTimeAxis' before calling this function
{
  junk := setLineColor  (0, "black");
  junk := setLineStyle  (0, "dotted");
  junk := setLineWidth  (0, 3);
  junk := setPointColor (0, "red");
  junk := setPointStyle (0, "box");
  junk := setPointSize  (0, 5);

  junk := setLineColor  (1, "red");
  junk := setLineStyle  (1, "dashed");
  junk := setLineWidth  (1, "8");
  junk := setPointColor (1, "purple");
  junk := setPointStyle (1, "star");
  junk := setPointSize  (1, 20);

  junk := setLineColor  (2, "purple");
  junk := setLineStyle  (2, "dotted");
  junk := setLineWidth  (2, 3);
  junk := setPointColor (2, "red");
  junk := setPointStyle (2, "diamond");
  junk := setPointSize  (2, 5);

  junk := setLineColor  (3, "blue");
  junk := setLineStyle  (3, "dashed");
  junk := setLineWidth  (3, "8");
  junk := setPointColor (3, "green");
  junk := setPointStyle (3, "square");
  junk := setPointSize  (3, 20);

}
#--------------------------------------------------------------------------
test2YAxes := function ()
{
  junk := clear ();
  testTimeAxisWith2YAxes ();
  test2AxisStyleControl ();
  junk := deleteDataSet (1);
  sleep (1);
  junk := deleteDataSet (0);
  sleep (1);
  junk := deleteDataSet (3);
  sleep (1);
  junk := deleteDataSet (2);

}
#--------------------------------------------------------------------------
testTimeAxisFromTable := function (points_ = 200, fragmentStart_ = 100, 
                                   fragmentLength_ = 50, scale_ = 4)
# note!  this function requires functions provided by
#    gdate.g
#    tableClient.g
#    table-helper.g
{
  junk := clear ();
  tbl := openTable ("/aips++/local/data/receiver-with-weather");

  if (is_record (tbl)) {
    print "---------------------------------------------------------"
    print "getting all time and wind velocity from table..."
    t := getColumn (tbl, "Time") [100:(100+points_)];
    print "---------------------------------------------------------"
    print "  main selection from full data has ", len (t), " points"
    print "initial time of main wind data: ", toLocal (t [1])
    print "    end time of main wind data: ", toLocal (t [len(t)])
    wind := getColumn (tbl, "Weather1_WINDVEL") [100:(100+points_)];
    print "plotting time and wind..."
    local windDataSet := timeY (t, wind, "wind velocity");
    print "---------------------------------------------------------"
    local fragmentStartIndex := fragmentStart_;
    local fragmentEndIndex   := fragmentStart_ + fragmentLength_;
    t1 := t [fragmentStartIndex:fragmentEndIndex]
    print "extracting a later, short fragment of time and wind: ", len (t1),
          " points"
    print "initial time of fragment: ", toLocal (t1 [1])
    print "    end time of fragment: ", toLocal (t1 [len(t1)])
    wind1 := wind [fragmentStartIndex:fragmentEndIndex]
    print "---------------------------------------------------------"
    print "scaling wind velocity in fragment by factor of 2..."
    wind1 *:= scale_;
    print "plotting fragment..."
    print "len (t1): ", len (t1)
    print "len (wind1): ", len (wind1)
    local fragmentDataSet := timeY (t1,wind1, "fragment");
    junk := closeAllTables ();
    return T;
    }
  else {
    print "could not open table, giving up testTimeAxis...";
    return F;
    }
}
#--------------------------------------------------------------------------
testDCRTime := function ()
{
  tbl := openTable ("test_Dcr.Table");
  if (is_record (tbl)) {  # necessary but not sufficient test of success
    print "getting data from test_Dcr.Table";
    columnNames (tbl);
    t := getColumn (tbl, "Time")
    d := getColumn (tbl, "DATA")
    utcStart := getColumn (tbl, "UTCSTART")
    timeMask := utcStart == utcStart [len (utcStart)]      
    goodData := d [timeMask]
    goodTime := t [timeMask]
    local dcrDataSet := timeY (goodTime, goodData, "dcr", "points")
    return T;
    }
  else {
    print "could not open table, giving up testDCRTime...";
    return F;
    }
}
#--------------------------------------------------------------------------
#testAppend := function (count = 100)
#{
#  setXScale (0,10+count);
#  junk := testVector ();
#  for (i in 1:count) {
#     #sleep (1);
#     junk := appendxy (0, 10+i,500 *sin (i));
#     #redraw ();
#     }
#  return T;
#}
#--------------------------------------------------------------------------
testAxisLabels := function ()
{
  junk := setYAxisLabel ("y axis");
  junk := setY2AxisLabel ("y2 axis");
  junk := setXAxisLabel ("x axis");

}
#--------------------------------------------------------------------------
#testAxisPositions := function ()
#{
#  junk := clear ();
#  data := [0,10,20,30,40,50,60,70,80,90,100];
#  junk := plotxy (data, data*data, "axis position test");
#  junk := setYAxisLabel ("y axis min position");
#  junk := setYAxisPosition ("min");
#  sleep (3);
#  junk := setYAxisLabel ("y axis max position");
#  junk := setYAxisPosition ("max");
#  sleep (3);
#  junk := setYAxisLabel ("y axis explicit position: 50.0");
#  junk := setYAxisPosition ("explicit", 50.0);
#  sleep (3);
#  junk := setYAxisLabel ("y axis auto position");
#  junk := setYAxisPosition ("auto");
#
#  sleep (3);
#  junk := setXAxisLabel ("x axis min position");
#  junk := setXAxisPosition ("min");
#  sleep (3);
#  junk := setXAxisLabel ("x axis max position");
#  junk := setXAxisPosition ("max");
#  sleep (3);
#  junk := setXAxisLabel ("x axis explicit position: 5000.0");
#  junk := setXAxisPosition ("explicit", 5000.0);
#  sleep (3);
#  junk := setXAxisLabel ("x axis auto position");
#  junk := setXAxisPosition ("auto");
#
#}
#--------------------------------------------------------------------------
testDeleteDataSet := function ()
# create 10 datasets, and then delete them in an erratic manner.
# 'clear' sets the numberOfDataSets back to zero, making it possible
# to call the present function repetitively
{
  for (i in 1:10) {
    junk := testVector (10);
    }

  junk := deleteDataSet (0);
  junk := deleteDataSet (9);
  junk := deleteDataSet (1);
  junk := deleteDataSet (8);
  junk := deleteDataSet (2);
  junk := deleteDataSet (7);
  junk := deleteDataSet (3);
  junk := deleteDataSet (6);
  junk := deleteDataSet (4);
  junk := deleteDataSet (5);
 
  junk := clear ();

  return T;
}
#--------------------------------------------------------------------------
torture := function (times=5)
{
  for (i in 1:times) {
    #print "iteration", i;
    junk := clear ();
    junk := testTimeAxis ();
    #sleep (1);
    junk := clear ();
    junk := testVector ();
    #sleep (1);
    }
}
#--------------------------------------------------------------------------
#dd := deleteDataSet
#qd := queryData
print 'test 2 yaxes, #1'
test2YAxes ();
print 'testing 2 yaxes, #2'
testRawAxisWith2YAxes ();
print 'testing axis labels'
testAxisLabels ();
