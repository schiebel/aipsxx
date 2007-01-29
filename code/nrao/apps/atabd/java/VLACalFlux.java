import java.awt.*;
import java.applet.*;
import java.util.*;
import java.net.URL;

import graph.*;
import VLAFluxData;
import QueryTable;
import VLAParameters;
import AstroPak;
/*
**************************************************************************
**
**                      Applet parse1d
**
**************************************************************************
**    Copyright (C) 1995, 1996 Leigh Brookshaw
**
**    This program is free software; you can redistribute it and/or modify
**    it under the terms of the GNU General Public License as published by
**    the Free Software Foundation; either version 2 of the License, or
**    (at your option) any later version.
**
**    This program is distributed in the hope that it will be useful,
**    but WITHOUT ANY WARRANTY; without even the implied warranty of
**    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**    GNU General Public License for more details.
**
**    You should have received a copy of the GNU General Public License
**    along with this program; if not, write to the Free Software
**    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
**************************************************************************
*
* This applet uses the ParseFunction class to parse an input string
* and plot the result.
*
*************************************************************************/

public class VLACalFlux extends Applet {

      G2Dint graph         = new G2Dint();   // Graph class to do the plotting
      Axis xaxis;
      Axis yaxis;
      DataSet data1;
      DataSet data1plus;
      DataSet data1minus;
      DataSet data2;
      DataSet data2plus;
      DataSet data2minus;
      String  dataTable;
      String  aliasTable;

      Choice band     = new Choice();       // Number of points 

      Label title;
      Label gLabel = new Label();
      TextField tStart   = new TextField(20);      // Minimum x value input
      TextField tStop   = new TextField(20);      // Maximum x value input
      TextField tSource;      // Input for the function to plot
      Button plot          = new Button("Plot It!"); // Button to plot it.
      QueryTable table;
      String tableserver;
      URL markerURL;
      VLAParameters vla    = new VLAParameters();





      public void init() {
      	 title                = new Label("VLA Calibrator Flux",Label.CENTER);
      	 Panel panel            = new Panel();
         GridBagLayout gridbag  = new GridBagLayout();
         GridBagConstraints  c  = new GridBagConstraints();
         Font font              = new Font("Helvetica",Font.PLAIN,15);

         title.setFont(new Font("Helvetica",Font.PLAIN,18));
         // tStart.setEditable(false);
         // tStop.setEditable(false);
          
         try {
            String mfile    = getParameter("MARKERS");
            markerURL = new URL(getDocumentBase(),mfile);
            graph.setMarkers(new Markers(markerURL));
         } catch(Exception e) {
            System.out.println("Failed to create Marker URL!");
         }
 
         
         table     = new QueryTable(getParameter("TABLESERVER"), 7002);
         aliasTable = new String(getParameter("aliasTable"));
         dataTable = new String(getParameter("dataTable"));
        
         setLayout(new BorderLayout() );
         add("North",title);
         add("Center",panel);

          Date today = new Date();
          double bd = 1900 + ((double)today.getYear()) + ((double)today.getMonth()+1)/100.0
                                      + ((double)today.getDate())/10000.0;
          double jdStop =  AstroPak.JD0(bd);
          double jdStart =  jdStop - 60;
          tStart.setText(AstroPak.JDtoDate(jdStart));
          tStop.setText(AstroPak.JDtoDate(jdStop));
//        tStart.setText(getParameter("StartTime")); 
//        tStop.setText(getParameter("StopTime")); 


         
         
         panel.setLayout(gridbag);

         Label lFreq   = new Label("Frequency");         
         Label lStart = new Label("Start Time");
         Label lStop = new Label("Stop Time");
         Label lSource   = new Label("Source");
         
         lFreq.setFont(font);
         lSource.setFont(font);
         lStart.setFont(font);
         lStop.setFont(font);
         
         band.setFont(font);
         band.setBackground(Color.lightGray);
         band.addItem("90cm");
         band.addItem("20cm");
         band.addItem(" 6cm");
         band.addItem(" 4cm");
         band.addItem(" 2cm");
         band.addItem(" 1cm");
         band.addItem(" 7mm");
         band.select(" 6cm");
//
         c.weightx = 1.0;
         c.weighty = 1.0;
         c.gridwidth = 1;
         c.gridwidth=GridBagConstraints.REMAINDER;
         c.fill  =  GridBagConstraints.BOTH;
         
         gridbag.setConstraints(graph,c);
//        
         c.fill  =  GridBagConstraints.NONE;
         c.weightx=0.0;
         c.weighty=0.0;
         c.gridheight=1;

         c.anchor = GridBagConstraints.WEST;
         c.fill  =  GridBagConstraints.BOTH;
         gridbag.setConstraints(gLabel,c);
//
         tSource     = new TextField(18);
         tSource.setFont(font);
         tSource.setBackground(Color.lightGray);
         tSource.resize(tSource.minimumSize(14));
         tStart.setFont(font);
         tStart.setBackground(Color.lightGray);
         tStop.setFont(font);
         tStop.setBackground(Color.lightGray);
         plot.setFont(font);
         plot.setBackground(Color.green);

         c.weightx = 1.0;
         c.weighty = 1.0;
         c.gridwidth = 3;
         c.gridwidth=GridBagConstraints.REMAINDER;
         c.fill  =  GridBagConstraints.BOTH;
         
         gridbag.setConstraints(graph,c);
         
         c.fill  =  GridBagConstraints.NONE;
         c.weightx=0.0;
         c.weighty=0.0;
         c.gridheight=1;
         
         c.gridwidth=1;
         c.anchor = GridBagConstraints.EAST;
         gridbag.setConstraints(lSource,c);
         
         c.anchor = GridBagConstraints.CENTER;
         c.gridwidth=GridBagConstraints.RELATIVE;
         c.fill  =  GridBagConstraints.HORIZONTAL;
         gridbag.setConstraints(tSource,c);
         
         c.fill = GridBagConstraints.NONE;
         c.gridwidth=GridBagConstraints.REMAINDER;

         gridbag.setConstraints(plot,c);

         
         c.gridwidth=1;
         c.anchor = GridBagConstraints.EAST;
         gridbag.setConstraints(lFreq,c);
         c.gridwidth=2;
         c.anchor = GridBagConstraints.WEST;
         c.gridwidth=GridBagConstraints.REMAINDER;
         gridbag.setConstraints(band,c);
         
         c.gridwidth=1;
         c.anchor = GridBagConstraints.EAST;
         gridbag.setConstraints(lStart,c);
         c.gridwidth=2;
         c.anchor = GridBagConstraints.WEST;
         c.gridwidth=GridBagConstraints.REMAINDER;
         gridbag.setConstraints(tStart,c);
         
         c.gridwidth=1;
         c.anchor = GridBagConstraints.EAST;
         gridbag.setConstraints(lStop,c);
         c.gridwidth=2;
         c.anchor = GridBagConstraints.WEST;
         c.gridwidth=GridBagConstraints.REMAINDER;
         gridbag.setConstraints(tStop,c);
         
         
         panel.add(graph);
         panel.add(gLabel);
         panel.add(lSource);
         panel.add(tSource);
         panel.add(plot);
         panel.add(lFreq);
         panel.add(band);
         panel.add(lStart);
         panel.add(tStart);
         panel.add(lStop);
         panel.add(tStop);

         xaxis = graph.createXAxis();
         xaxis.setTitleText("Days since");
         xaxis.setManualRange(true);

         yaxis = graph.createYAxis();
         yaxis.setTitleText("Flux (Jy)");
         yaxis.setManualRange(true);


         data1 = new DataSet();
         data1.linestyle = 0;
         data1.marker = 4;
         data1.markerscale = 1.0;
         data1.legend(90, 30, "AC Flux    For calibration and planning purposes only.");

         xaxis.attachDataSet(data1);
         yaxis.attachDataSet(data1);
         graph.attachDataSet(data1);

         data1plus = new DataSet();
         data1plus.linestyle = 0;
         data1plus.marker = 9;
         data1plus.markerscale = 1.5;

         xaxis.attachDataSet(data1plus);
         yaxis.attachDataSet(data1plus);
         graph.attachDataSet(data1plus);

         data1minus = new DataSet();
         data1minus.linestyle = 0;
         data1minus.marker = 10;
         data1minus.markerscale = 1.5;

         xaxis.attachDataSet(data1minus);
         yaxis.attachDataSet(data1minus);
         graph.attachDataSet(data1minus);

         data2 = new DataSet();
         data2.linestyle = 0;
         data2.marker = 5;
         data2.markerscale = 1.0;
         data2.legend(90, 42, "BD Flux");

         xaxis.attachDataSet(data2);
         yaxis.attachDataSet(data2);
         graph.attachDataSet(data2);

         data2plus = new DataSet();
         data2plus.linestyle = 0;
         data2plus.marker = 9;
         data2plus.markerscale = 1.5;

         xaxis.attachDataSet(data2plus);
         yaxis.attachDataSet(data2plus);
         graph.attachDataSet(data2plus);

         data2minus = new DataSet();
         data2minus.linestyle = 0;
         data2minus.marker = 10;
         data2minus.markerscale = 1.5;

         xaxis.attachDataSet(data2minus);
         yaxis.attachDataSet(data2minus);
         graph.attachDataSet(data2minus);


         graph.setDataBackground(new Color(255,200,175));
         graph.setBackground(new Color(200,150,100));

      }


     public boolean action(Event e, Object a) {

         if(e.target instanceof Button) {
             if( plot.equals(e.target) ) {
                  this.showStatus("Reading Data from AIPS++ table");
                  doPlot();
                  return true;
             }
         }

         if(e.target instanceof Choice) {
             if( band.equals(e.target) ) {
                  this.showStatus("Reading Data from AIPS++ table");
                  doPlot();
                  return true;
             }
         }

         if(e.target instanceof TextField) {
             if( tSource.equals(e.target) ) {
                  this.showStatus("Reading Data from AIPS++ table");
                  doPlot();
                  return true;
             }
         }


         return false;
       }


   private void doPlot(){
     
     StringTokenizer hits = new StringTokenizer(doQuery(), ":");
     Vector calData = new Vector();
     double xmin = 0.0;

     data1.deleteData();
     data1plus.deleteData();
     data1minus.deleteData();
     data2.deleteData();
     data2plus.deleteData();
     data2minus.deleteData();

     while(hits.hasMoreTokens()){
        VLAFluxData dataPt = new VLAFluxData(hits.nextToken());
        if(dataPt.goodData())
           calData.addElement(dataPt);
     }

     double dataAC[] = new double[2*calData.size()];
     double dataBD[] = new double[2*calData.size()];
     double acMinus[] = new double[2*calData.size()];
     double acPlus[] = new double[2*calData.size()];
     double bdMinus[] = new double[2*calData.size()];
     double bdPlus[] = new double[2*calData.size()];
     int acCount = 0;
     int bdCount = 0;
     double lowFreq = vla.getLowFreq(band.getSelectedItem());
     double hiFreq = vla.getHighFreq(band.getSelectedItem());

     for(int i=0;i<calData.size();i++){
        VLAFluxData member = (VLAFluxData)calData.elementAt(i);


        if(member.ac_freq >= lowFreq && member.ac_freq <= hiFreq && member.ac_flux > 0.001){
           int t = 2*acCount;
           int y = 2*acCount+1;
           acCount += 1;
           dataAC[t]  = member.time_obs;
           dataAC[y]  = member.ac_flux;
           acMinus[t] = member.time_obs;
           acMinus[y] = member.ac_flux - member.ac_flux_stddev;
           acPlus[t]  = member.time_obs;
           acPlus[y]  = member.ac_flux + member.ac_flux_stddev;
        }

        if(member.bd_freq >= lowFreq && member.bd_freq <= hiFreq && member.bd_flux > 0.001){
           int t = 2*bdCount;
           int y = 2*bdCount+1;
           bdCount += 1;
           dataBD[t]  = member.time_obs;
           dataBD[y]  = member.bd_flux;
           bdMinus[t] = member.time_obs;
           bdMinus[y] = member.bd_flux - member.bd_flux_stddev;
           bdPlus[t]  = member.time_obs;
           bdPlus[y]  = member.bd_flux + member.bd_flux_stddev;
        }

        if(i== 0)
           xmin = member.mjad;
        else{
           if(member.mjad < xaxis.minimum)
              xmin =  member.mjad;
        }
     }
     if(calData.size() > 0){
        try {
           for(int i=0;i<2*acCount;i+=2){
              dataAC[i]  -= xmin;
              acMinus[i] -= xmin;
              acPlus[i]  -= xmin;
           }
           for(int i=0;i<2*bdCount;i+=2){
              dataBD[i]  -= xmin;
              bdMinus[i] -= xmin;
              bdPlus[i]  -= xmin;
           }
           try{
              if(acCount > 0){
                 data1.append(dataAC, acCount);
                 data1plus.append(acPlus, acCount);
                 data1minus.append(acMinus, acCount);
              }

              if(bdCount > 0){
                 data2.append(dataBD, bdCount);
                 data2plus.append(bdPlus, bdCount);
                 data2minus.append(bdMinus, bdCount);
              }
           }catch(Exception e){
             System.out.println(acCount + " " + bdCount);
             this.showStatus("Error while really appending data!"); 
             System.out.println("Error while really appending data!");
             return;
           }

           double ac_max = data1plus.getYmax();
           double bd_max = data2plus.getYmax();
           double ac_min = data1minus.getYmin();
           double bd_min = data2minus.getYmin();
           if(acCount == 0){
              ac_max = bd_max;
              ac_min = bd_min;
           }
           if(bdCount == 0){
              bd_max = ac_max;
              bd_min = ac_min;
           }

           if(ac_min < bd_min)
              yaxis.minimum = 0.9*ac_min;
           else
              yaxis.minimum = 0.9*bd_min;

           if(ac_max > bd_max)
              yaxis.maximum = 1.1*ac_max;
           else
              yaxis.maximum = 1.1*bd_max;

           if(acCount > 0){
              xaxis.minimum = Math.floor(data1.getXmin());
              xaxis.maximum = Math.ceil(data1.getXmax());
           } else {
              xaxis.minimum = Math.floor(data2.getXmin());
              xaxis.maximum = Math.ceil(data2.getXmax());
           }
           xaxis.setTitleText("Days since " + xmin + "MJD");
        }catch(Exception e) {
             this.showStatus("Error while appending data!"); 
             System.out.println("Error while appending data!");
             return;
        }
        this.showStatus("Data read from AIPS++ table");
     } else {
         this.showStatus("No Data Found!"); 
         title.setText("No data for " + tSource.getText() + " at " +
                       band.getSelectedItem());
     }
     
     double xmax = Math.ceil(data1.getXmax())+xmin;
     if(calData.size() > 0)
        gLabel.setText(calData.size() + " points plotted from " +
                    AstroPak.JDtoDate(xmin+2400000.5) +
                    " to " + AstroPak.JDtoDate(xmax+2400000.5));
     else
        gLabel.setText("No data found between " + tStart.getText() 
                        + " and  " + tStop.getText());

     graph.repaint();
     return;
   }

   private String doQuery(){
         double lowFreq = vla.getLowFreq(band.getSelectedItem());
         double hiFreq = vla.getHighFreq(band.getSelectedItem());
         String startTime = tStart.getText();
         String stopTime = tStop.getText();
         double mjdStart = AstroPak.JD0(AstroPak.convertDate(startTime))
                           - 2400000.5;
         double mjdStop = AstroPak.JD0(AstroPak.convertDate(stopTime))
                          - 2400000.5;
         String dateQuery = new String (" MJAD > " + mjdStart + " && MJAD < " 
                                     + mjdStop + " ");
         title.setText("Fluxes for " + tSource.getText() + " at " +
                       band.getSelectedItem());
         String look4 = tSource.getText().toUpperCase();
         String sourceNames;
         if(look4.startsWith("J")){
            int startI = 0;
            if(look4.startsWith("J"))
               startI = look4.indexOf('J');
            String query = new String(" select from " + aliasTable + " where J2000 == \"" + look4.substring(startI+1) + "\"");
            sourceNames = new String(table.queryTable(query));
         }else if(look4.startsWith("B")){
            int startI = 0;
            if(look4.startsWith("B"))
               startI = look4.indexOf('B');
            sourceNames = new String(table.queryTable(new String(" select from " + aliasTable + " where B1950 == \"" + look4.substring(startI+1) +"\"")));
         }else{
            sourceNames = new String(table.queryTable(new String(" select from " + aliasTable + " where J2000 == \"" + look4 +"\" || B1950 == \"" + look4 + "\" || Alias == \"" + look4 + "\"")));
         }
         String aliases[] = new String [3];
         String querySource;
         StringTokenizer dataIn = new StringTokenizer(sourceNames);
         if(dataIn.hasMoreTokens()){
            aliases[0] = new String(dataIn.nextToken());
            aliases[1] = new String(dataIn.nextToken());
            aliases[2] = new String(dataIn.nextToken());
            if(aliases[2].equals(":")){
               querySource = new String("(Source == \"" + aliases[0] + "\" || Source == \"" + aliases[1] +"\")");
            } else {
               querySource = new String("(Source == \"" + aliases[1] + "\" || Source == \"" + aliases[2] +"\" || Source == \""+ aliases[0] +"\")");
            }
         } else {
            querySource = new String("Source == \"No match\"");
         }
         String query = new String("select Source, MJAD, Start, End, Correlator_Mode, El_End, AC_Frequency, BD_Frequency, Mean_AC_Flux, Stddev_AC_Flux, Mean_BD_Flux, Stddev_BD_Flux from " + dataTable + " where " + querySource + " && ((AC_Frequency >= " + lowFreq + " && AC_Frequency <= " + hiFreq + ") || (BD_Frequency >= " + lowFreq + " && BD_Frequency <= " + hiFreq + ")) && " + dateQuery);
         return table.queryTable(query);
   }

}




