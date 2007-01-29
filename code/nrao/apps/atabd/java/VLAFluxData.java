import java.util.*;
import java.lang.*;

public final class VLAFluxData extends Object{
  private boolean goodData = true;
  public String Source;
  public double mjad;
  public String correlator_mode;
  public double el_end;
  public double obs_start;
  public double obs_end;
  public double time_obs;
  public double ac_freq;
  public double bd_freq;
  public double ac_flux;
  public double ac_flux_stddev;
  public double bd_flux;
  public double bd_flux_stddev;

  public VLAFluxData(String s){
     System.out.println(s);
     StringTokenizer dataIn = new StringTokenizer(s);
     if(dataIn.countTokens() != 12)
        goodData = false;
     if(goodData){
       goodData = false;
       try {
        ac_freq         = Double.valueOf(dataIn.nextToken()).doubleValue(); 
        bd_freq         = Double.valueOf(dataIn.nextToken()).doubleValue(); 
        correlator_mode = new String(dataIn.nextToken());
        el_end          = Double.valueOf(dataIn.nextToken()).doubleValue(); 
        obs_end         = Double.valueOf(dataIn.nextToken()).doubleValue(); 
        mjad            = Double.valueOf(dataIn.nextToken()).doubleValue(); 
        ac_flux         = Double.valueOf(dataIn.nextToken()).doubleValue(); 
        bd_flux         = Double.valueOf(dataIn.nextToken()).doubleValue(); 
        Source          = new String(dataIn.nextToken()); 
        obs_start       = Double.valueOf(dataIn.nextToken()).doubleValue(); 
        ac_flux_stddev  = Double.valueOf(dataIn.nextToken()).doubleValue(); 
        bd_flux_stddev  = Double.valueOf(dataIn.nextToken()).doubleValue(); 
        goodData = true;
       } catch (NumberFormatException e) {
         goodData = false;
       }
     }
     if(goodData){
        if(obs_end < obs_start)
           obs_end += 2.0*Math.PI;
        double ac_fudge = 25.6;
        double bd_fudge = 25.6;

           // The following section of code reflects a change Ken Sowinski made
           // in the on-line system on April 9, 1997.  He basically got the
           // the numbers to all agree for all bands and all observing modes
           // so we only need apply the correction to data taken before this
           // change.  wky 97/04/16

           // Correct data to proper values for data taken before 97/04/09
           // 
        if((mjad < 50547) || (mjad == 50547 && obs_start < 4.199)){
           if(ac_freq < 0.500)
                ac_fudge = 2.56;
           if(bd_freq < 0.500)
                bd_fudge = 2.56;
        //
        // Here we take into account that spectral line fluxes are down by a
        // factor of 2.0*0.85;
        //
           if(!correlator_mode.equals("CONT")){
              ac_fudge /= (2.0*0.85);
              bd_fudge /= (2.0*0.85);
           }
        } else {
           //
           // He then readjusted the correction for P and 4 bands around Feb 11
           // 1998 to allow more head room. wky 98/04/27
           //
           if(mjad > 50855){
              if(ac_freq < 0.500)
                 ac_fudge = 2.56;
              if(bd_freq < 0.500)
                 bd_fudge = 2.56;
           }
           if(!correlator_mode.equals("CONT")){
              ac_fudge /= (1.0*0.85);
              bd_fudge /= (1.0*0.85);
           }
        }
 
        if(ac_flux > 0.0){
           ac_flux *= ac_flux/ac_fudge;
           ac_flux_stddev *= 2.0*ac_flux/ac_fudge;
        }
        if(bd_flux > 0.0){
           bd_flux *= bd_flux/bd_fudge;
           bd_flux_stddev *= 2.0*bd_flux/bd_fudge;
        }
        time_obs = mjad + (obs_start + (obs_end - obs_start)/2.0)/(2.0*Math.PI);
     
        if(ac_freq >= 1.35 && ac_freq <= 1.55){
           double ac_corr = (0.8434*ac_freq - 0.225);
           ac_flux *= ac_corr;
           ac_flux_stddev *= ac_corr*ac_corr;
        }
        if(bd_freq >= 1.35 && bd_freq <= 1.55){
           double bd_corr = (0.8434*bd_freq - 0.225);
           bd_flux *= bd_corr;
           bd_flux_stddev *= bd_corr*bd_corr;
        }
     }
     return;
  }

  public boolean goodData(){
     if(goodData){
        if(ac_freq > 10.0 || bd_freq > 10.0){
              // Exclude data < 30deg and > 80deg in elevation
           if(el_end < Math.PI/6.0 || el_end > 4.0*Math.PI/9.0)
              return false;
        }
        return true;
     } else {
        return false;
     }
  }
}
