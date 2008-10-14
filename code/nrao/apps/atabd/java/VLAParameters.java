import java.lang.*;

public class VLAParameters {
    double getLowFreq(String bandID){
       double freq = 0.0;
       double n_freq = 0.0;     //Nominal range
       double s_freq = 0.0;     //Strictest range
       double e_freq = 0.0;     //Extreme range
       double c_freq = 0.0;     //Calibrator nominal
       if(bandID.equalsIgnoreCase("90cm")){
         s_freq = 0.305;
         n_freq = 0.298;
         e_freq = 0.295;
         c_freq = 0.302;
       } else if(bandID.equalsIgnoreCase("20cm")) {
         s_freq = 1.320;
         n_freq = 1.250;
         e_freq = 1.220;
         c_freq = 1.360;
       } else if(bandID.equalsIgnoreCase(" 6cm")) {
         s_freq = 4.500;
         n_freq = 4.250;
         e_freq = 4.200;
         c_freq = 4.810;
       } else if(bandID.equalsIgnoreCase(" 4cm")) {
         s_freq = 8.080;
         n_freq = 7.550;
         e_freq = 6.800;
         c_freq = 8.410;
       } else if(bandID.equalsIgnoreCase(" 2cm")) {
         s_freq = 14.65;
         n_freq = 14.25;
         e_freq = 13.50;
         c_freq = 14.89;
       } else if(bandID.equalsIgnoreCase(" 1cm")) {
         s_freq = 22.00;
         n_freq = 21.70;
         e_freq = 20.80;
         c_freq = 22.41;
       } else if(bandID.equalsIgnoreCase(" 7mm")) {
         s_freq = 40.50;
         n_freq = 40.00;
         e_freq = 38.00;
         c_freq = 43.29;
       }
       return c_freq;
    }

    double getHighFreq(String bandID){
       double freq = 0.0;
       double n_freq = 0.0;     //Nominal range
       double s_freq = 0.0;     //Strictest range
       double e_freq = 0.0;     //Extreme range
       double c_freq = 0.0;     //Calibrator nominal
       if(bandID.equalsIgnoreCase("90cm")){
         s_freq = 0.335;
         n_freq = 0.345;
         e_freq = 0.350;
         c_freq = 0.350;
       } else if(bandID.equalsIgnoreCase("20cm")) {
         s_freq = 1.700;
         n_freq = 1.740;
         e_freq = 1.750;
         c_freq = 1.540;
       } else if(bandID.equalsIgnoreCase(" 6cm")) {
         s_freq = 5.000;
         n_freq = 5.100;
         e_freq = 5.100;
         c_freq = 4.910;
       } else if(bandID.equalsIgnoreCase(" 4cm")) {
         s_freq = 8.750;
         n_freq = 9.050;
         e_freq = 9.600;
         c_freq = 8.510;
       } else if(bandID.equalsIgnoreCase(" 2cm")) {
         s_freq = 15.325;
         n_freq = 15.70;
         e_freq = 16.30;
         c_freq = 14.99;
       } else if(bandID.equalsIgnoreCase(" 1cm")) {
         s_freq = 24.00;
         n_freq = 24.50;
         e_freq = 25.80;
         c_freq = 22.51;
       } else if(bandID.equalsIgnoreCase(" 7mm")) {
         s_freq = 44.50;
         n_freq = 48.00;
         e_freq = 51.90;
         c_freq = 43.39;
       }
       return c_freq;
    }
}
