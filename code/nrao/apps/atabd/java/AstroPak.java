import Math1;
import java.awt.*;
import java.util.*;

public class AstroPak extends Object {

	
    public static void SetColors(int Red[], int Blue[], int Green[]) {
        float code;
        int i, j;
        
	code = 0;
        for (i=0; i<11; i++) Blue[i] = 0;
        for (i=11; i<66; i++) {
		j = (int)(code + 0.5);  if (j > 255) j = 255;
		Blue[i] =j;  
		code = (float)(code + 255.0 / (65.0 - 11.0));
	}
	code = 255;
        for (i=66; i<121; i++) {
		code = (float)(code - 255.0 / (120.0 - 65.0));  
		j = (int)(code + 0.5); if (j < 0)  j = 0; 
		Blue[i] = j;
	}
        for (i=121; i<256; i++) Blue[i] = 0;

	
	code = 0;
        for (i=0; i<75; i++) Green[i] = 0;
        for (i=75; i<96; i++) {
		j = (int)(code + 0.5);   if (j > 255) j = 255;
		Green[i] = j;  
		code = (float)(code + 255.0 / (95.0 - 75.0)); 
	}
	code = 255;
        for (i=96; i<181; i++) Green[i] = 255;
	for (i=181; i<211; i++) {
		code = (float)(code - 255.0 / (210.0 - 181.0)); 
		j = (int)(code + 0.5);   if (j < 0) j = 0; 
		Green[i] = j;
        }
        for (i=211; i<256; i++) Green[i] = 0;

	
        for (i=0; i<111; i++) Red[i] = 0;
	code = 0;
        for (i=111; i<171; i++) {
		code = (float)(code + 255.0 / (170.0 - 111.0));
		j = (int)(code + 0.5);  if (j > 255) j = 255;
		Red[i] = j;
	}
        for (i=171; i<256; i++) Red[i] = 255;
    }

                                //This should probably be in a version
                                //of util routines   
    public static long Entier(double x) {
        return (long)(x - (x % 1.0));
    }

                                //This should probably be in a version
                                //of util routines
    public static String doubleToString(double dbl) {
        StringBuffer string = new StringBuffer();
        int value, index;
        long lng = 0;
        if (dbl < 0.0) {
            dbl = Math.abs(dbl);
            string.insert(0, "-");
        }
        if (dbl < 1.0) {
            string.append("0.");
        }
        else {
            lng = (long)dbl;
            string.append(lng);
            string.append(".");
        }

        for (int i = 0; i < 6; i++) {
            dbl = (dbl - (double)lng) * 10.0;
            lng = (long)dbl;
            string.append(lng);
        }
      
        return string.toString();  
    }


                                       //the constrain routines should
                                       // be utilities also
    public static void constrain(Container container, Component component,
                int grid_x, int grid_y, int grid_width, int grid_height,
                int fill, int anchor, double weight_x, double weight_y,
                int top, int left, int bottom, int right) {
        GridBagConstraints c = new GridBagConstraints();
        c.gridx = grid_x; c.gridy = grid_y;
        c.gridwidth = grid_width; c.gridheight = grid_height;
        c.fill = fill; c.anchor = anchor;
        c.weightx = weight_x; c.weighty = weight_y;
        if (top + bottom + left + right > 0)
            c.insets = new Insets(top, left, bottom, right);
            
        ((GridBagLayout)container.getLayout()).setConstraints(component,c);
        container.add(component);
    }
    
    public static void constrain(Container container, Component component,
                int grid_x, int grid_y, int grid_width, int grid_height){
        constrain(container, component, grid_x, grid_y,
                grid_width, grid_height, GridBagConstraints.NONE,
                GridBagConstraints.CENTER, 0.0, 0.0, 0, 0, 0, 0);
    }
    
    public static void constrain(Container container, Component component,
                int grid_x, int grid_y, int grid_width, int grid_height,
                int top, int left, int bottom, int right) {
        constrain(container, component, grid_x, grid_y,
                grid_width, grid_height, GridBagConstraints.NONE,
                GridBagConstraints.CENTER, 0.0, 0.0, top, left, bottom, right);
    }
    
    
    
                                    // Computes lunar mean age in days
    public static double LunarAge (double JD) {
        return Math1.Mod(JD-2415020.76, 29.53058867);
    }


                                //Convert a decimal angle to DD:MM:SS.ss... string
                                //n is the number of decimals in the seconds
    public static String HMSstring(double a, long n) {
        double nn, angle;
        int i, j, k, p;
        angle = a + Math1.Sign(a) / (7200.0 * Math.pow(10, n));
        
        return " ";
    }

                                    //Takes decimal time (>=0) and
                                    //makes a corresponding string of the
                                    //form HH:MM
    public static String HMstring (double x) {
        double xx;
        int h, m;
        xx = Math1.Mod(x, 24.0);
        h = (int)xx;
        m = (int) (60.0 * Math1.Frac(xx) +0.5);
        if (m >= 60) {
            m = m - 60;
            xx = h + 1;
            h = (int) (Math1.Mod(x, 24.0));
        }
        
        StringBuffer string = new StringBuffer();
        string.append(h);
        string.append(":");
        if (m < 10) string.append("0");
        string.append(m);
        return string.toString();
    }
    
    
                                    // Eq --> Altaz conversion
                                    //Parameters in decimal degrees
    public static void EqAltAz (double lat, double dec, double HA, double ara[]) {
        double x, y, z;
        x = Math1.CosDeg(lat) * Math1.SinDeg(dec);
        x -= Math1.SinDeg(lat) * Math1.CosDeg(dec) * Math1.CosDeg(HA);
        y = -(Math1.CosDeg(dec) * Math1.SinDeg(HA));
        z = Math1.SinDeg(lat) * Math1.SinDeg(dec);
        z += Math1.CosDeg(lat) * Math1.CosDeg(dec) * Math1.CosDeg(HA);
        ara[0] = Math1.ASinDeg(z);                                   //Alt
        ara[1] = Math1.ATan2Deg(x,y) + Math1.Test(y < 0) * 360.0;    // Az
    }
    
    
                                    //Greenwich Mean Siderial Time
                                    //in decimal hours.
    public static double GMST (double JD){
        double T, ut;
        T = (JD - 2451545.0) / 36525.0;
        ut = Math1.Mod(24.0*Math1.Frac(JD-0.5), 24.0);  
        return Math1.Mod(6.69737455833 + 2400.05133691*T + 2.586222E-5*T*T + ut, 24.0);
    }
 
    
                                   //Greenwich Apparent Siderial Time
                                   //in decimal hours.
                                   //Error should not exceed 0.01 seconds
    public static double GAST (double JD) {
        double T, x;
        T = (JD - 2451545.0) / 36525.0;
        x = Math1.SinDeg(125.04 - 1934.138*T);
        x += 0.0767 * Math1.SinDeg(200.9 + 72001.54*T);
        x += 2.0 * 0.0132 * Math1.SinDeg(76.6 + 962535.76*T);
        x -= 0.0120 * Math1.SinDeg(250.1 - 3868.28*T);
        x -= 0.0083 * Math1.SinDeg(357.5 + 35999.05*T);
        return Math1.Mod(GMST(JD) - 2922E-4*x,24.0);
    }
                                   
                                   //Converts JD to calendar date (on
                                   //Julian calendar through 1582 0ct 04,
                                   //on Gregorian thereafter.
    public static String JDtoDate(double value) {
        String mos[] = {"Jan", "Feb", "Mar", "Apr", "May", "Jun",
                        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};
        long A, B, C, D, E, Z, alpha;
        int year, mon, day;
        Z = Entier(value + 0.5);
        alpha = Entier(((double)Z - 1867216.25)/36524.25);
        A = Z + Entier(Math1.Test(Z >= 2299161)) * (1 + alpha - alpha/4);
        B = A + 1524;
        C = Entier(((double)B - 122.1)/365.25);
        D = Entier(365.25 * (double)C);
        E = Entier((double)(B-D)/30.6001);
        mon = (int)(E - 1 - Entier(Math1.Test(E>13)) * 12);
        year = (int)(C - 4716 + Entier(Math1.Test(mon<=2)));
        day = (int)(Entier(30.6001 * (double)E));
        day = (int)(B - D) - day;
        String month2 = new String(mos[mon-1]);
        String year2 = new String(String.valueOf(year));
        if (day < 10) {
            String day1 = "0" + new String(String.valueOf(day));
            return year2 + " " + month2 + " " + day1;
        } 
        else {
            String day2 = new String(String.valueOf(day));
            return year2 + " " + month2 + " " + day2;
        }
    }
    
                             //Convert from YYYY MMM DD or YYY/MMM/DD
                             // where MMM may be capitalized or a 
                             //two-digit number  i.e. Jan or JAN or 01                            
    public static double convertDate(String str) {
        String months[] = {"JAN", "FEB", "MAR", "APR", "MAY", "JUN",
                           "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"};
        String mos[] = {"01", "02", "03", "04", "05", "06",
                        "07", "08", "09", "10", "11", "12"};
        StringTokenizer token = new StringTokenizer(str," /.");
        double dbl, thisMonth = 0; 
        int value;
        value = Integer.parseInt(token.nextToken());
        dbl = (double) value;
        String month = new String(token.nextToken());
        for (int i = 0; i < 12; i++) {
            if (month.equalsIgnoreCase(months[i])) thisMonth = (double)(i + 1);
        }
        if (thisMonth == 0) {
            for (int i = 0; i < 12; i++) {
                if (month.equalsIgnoreCase(mos[i])) thisMonth =(double)(i+1);
            }
        }
        value = Integer.parseInt(token.nextToken());
            
        dbl = dbl + thisMonth/100.0;
        dbl = dbl + (double) value / 10000.0;
        
        if (token.hasMoreTokens()) {
            value = Integer.parseInt(token.nextToken());
            dbl = dbl + (double) value / 100000.0;
        }
        
        return dbl;
    }
    
                                //decimal degrees --> DDD.MMSSss
    public static double DegDMS(double angle) {
        double a, d, m, s, sn;
        sn = 1.0; if (angle < 0.0) sn = -1.0;
        a = Math.abs(angle);
        d = angle % 1.0;
        m = ((a - d)* 60.0) % 1;
        s = 3600.0 * (a - d - m/60.0);
        return sn * (d + m/100.0 + s/10000.0);      
    }
    
                                        //DDD.MMSSss --> decimal degrees    
    public static double DMSDeg(double angle) {
        double t, d, m, s;
        t = Math.abs(angle);
        d = angle % 1.0;
        t = (t - d) * 100;
        m = t % 1.0;
        s = (t - m) * 100;
        t = 1.0; if (angle < 0.0) t = -1.0;
        return t * (d + m/60.0 + s/3600.0);       
    }
 

                                    // fraction of day from time in HH.MMSS form
    public static double DayFrac (double UT) {
        return DMSDeg(UT) / 24.0;
    }
        
    
                               // Convert decimal angle to DD MM SS.ss..string                                
                               // n is the number of decimal places in seconds
    public static String DecToSexa(double angle, int n) {
        double angle2;
        long temp;
        int p, i, j;
        char x;
        StringBuffer sb = new StringBuffer();
        angle2 = angle + Math1.Sign(angle) / (7200.0 * Math.pow(10.0,(double) n));

        if (angle2 >= 0.0) sb.insert(0,' ');    //Insert sign or space
        else {
            sb.insert(0,'-');
            angle2 = -angle2;
        }

        temp = (long) (angle2 - Math1.Frac(angle2));        // Insert degrees
        sb.append(temp);  sb.append(' ');

        angle2 = (angle2 - (double)temp) * 60.0;  // Insert minutes;      
        temp = (long)(angle2 - Math1.Frac(angle2));
        sb.append(temp); sb.append(' ');
 
        angle2 = (angle2 - (double)temp) * 60.0;  // Insert seconds
        temp = (long)(angle2 - Math1.Frac(angle2));
        sb.append(temp); 
 
        if (n > 0) {                       // Insert fractional part if needed
            sb.append('.');
            angle2 = (angle2 - (double) temp) * Math.pow(10.0,n); 
            temp = (long)(angle2 - Math1.Frac(angle2));
            sb.append(temp);
        }
        String s = new String(sb.toString());
        return s.trim();
    }

   
                                  //Convert DD MM SS.ss... or DD.MMSSss (string)
                                  //to DD.ddd...(double)   
    public static double SexaToDec(String inString) {
        int pos, x1, x2;
        double xx, x3;
        String seconds = new String();
        String mins = new String();
        StringTokenizer st = new StringTokenizer(inString.trim(),".: \n\t\r",true);
        String degrees = new String(st.nextToken());
        String tok = new String(st.nextToken()); 
        String min1 = new String(st.nextToken());
        if (tok.equalsIgnoreCase(".")) {
            seconds = new String(min1.substring(2,min1.length()));
            x3 = (double)Integer.parseInt(seconds);           
            mins = new String(min1.substring(0,2));
        }
        else {
            mins = new String(min1);
            tok = st.nextToken();
            String sec2 = new String(st.nextToken());
            if (st.hasMoreTokens()){
                seconds = new String(sec2 + st.nextToken() + st.nextToken());
                x3 = Float.valueOf(seconds).doubleValue();
            }
            else { 
                seconds = new String(sec2);
                x3 = (double)Integer.parseInt(seconds);
            }
        }
        
        x1 = Integer.parseInt(degrees);
        x2 = Integer.parseInt(mins);
        
        xx = (double) x1;
        xx += (((double) x2) / 60.0) * Math1.Sign(xx);
        xx += (x3 / 3600.0) * Math1.Sign(xx);;
        
        return xx;
    }    
        
                                        //Breaks numbers given as aaa.bbcc
                                        //into component parts a[0], a[1], a[2]
    public static void BreakNumber(double inNum, long a[]) {
        double num;
        num = inNum + 0.00005;
        a[0] = (long)num;
        num = (num - a[0]) * 100.0;
        a[1] = (long)num;
        num = (num - a[1]) * 100.0;
        a[2] = (long)num; 
    }
    
                                        //JD at 000 UT, given date in 
                                        //the form YYY.MMDD
    public static double JD0(double date) {
        long y=0, m=0, d=0, a, b;
        long ar[] = new long[3];
        double x1, x2;
        BreakNumber(date, ar);
        y = ar[0]; m = ar[1]; d = ar[2];
        if (m <= 0) return -1.0;
        if (m > 12) return -1.0;
        if (d <= 0) return -1.0;
        if (d > 31) return -1.0;
        y = y - (long)Math1.Test(m<3);
        m = m + 12*(long)Math1.Test(m<3);   
        a = y / 100;
        b = (long)Math1.Test(date >=1582.1015);
        b *= (2 - a + a/4);      
        x1 = 365.25 * y - 0.75 * Math1.Test(y<0);
        x1 = x1 - (x1 % 1.0);
        x2 = 30.6001 * (double)(m+1);
        x2 = x2 - (x2 % 1.0) + d + b;
        return x1 + x2 + 1720994.5;  
    }
   
   
                                            //Change-over epoch is J1979.0 = JD 2444200.5
                                            //AB, AJ: right ascension in decimal degrees
                                            //DB, DJ: declinations in decimal degrees   
    public static void B1950ToJ2000(double AB, double DB, double J[]) {
        double ET[] = {-1.62557E-6, -0.31919E-6, -0.13843E-6};
        double MM[][] = 
            {{0.999925678715, -0.011181827661, -0.004858371822},
             {0.011181827639, 0.999937481042, -0.000027168218},
             {0.004858371872, -0.000027159278, 0.999988197673}};
        double R0[] = new double[3];
        double R[] = new double[3];
        double C, P;
 
        //Form B1950 vector
        R0[0] = Math1.CosDeg(DB) * Math1.CosDeg(AB);
        R0[1] = Math1.CosDeg(DB) * Math1.SinDeg(AB);
        R0[2] = Math1.SinDeg(DB);
        
        //Remove E-terms
        P = 1.0;
        for (int i=0; i<3; i++) P += ET[i]*R0[i];
        for (int i=0; i<3; i++) R0[i] = R0[i]*P - ET[i];
        for (int i=0; i<3; i++) {
            R[i] = 0.0;
            for (int j=0; j<3; j++) R[i] += MM[i][j]*R0[j];
        }
        
        //Form J2000 coordinates
        if (Math.abs(R[2]) >= 1.0) {J[0] = 0.0; J[1] = 90.0 * Math1.Sign(R[2]);}
        else {
            J[0] = Math1.AngleRec(Math1.ATan2Deg(R[0], R[1]), 0);
            J[1] = Math1.ASinDeg(R[2]);
        }
    }
    
                                            //Change-over epoch is J1979.0 = JD 2444200.5
                                            //AB, AJ: right ascension in decimal degrees
                                            //DB, DJ: declinations in decimal degrees       
   public static void J2000ToB1950(double AJ, double DJ, double B[]) {
        double ET[] = {-1.62557E-6, -0.31919E-6, -0.13843E-6};
        double MM[][] = 
            {{0.999925678715, 0.011181827639, 0.004858371872},
             {-0.011181827661, 0.999937481042, -0.000027159278},
             {-0.004858371822, -0.000027168218, 0.999988197673}};
        double R0[] = new double[3];
        double R[] = new double[3];
        double S[] = new double[3];
        double S1[] = new double[3];
        double P;
 
        //Form J2000 vector
        R0[0] = Math1.CosDeg(DJ) * Math1.CosDeg(AJ);
        R0[1] = Math1.CosDeg(DJ) * Math1.SinDeg(AJ);
        R0[2] = Math1.SinDeg(DJ);
        
        //Form B1950 vector
        for (int i=0; i<3; i++) {
            R[i] = 0.0;
            for (int j = 0; j<3; j++) R[i] += MM[i][j] * R0[j];
        }
        
        //Insert E-terms
        for (int i = 0; i<3; i++) S1[i] = R[i];
        for (int j = 0; j<2; j++) {
            for (int i = 0; i<3; i++) S[i] = R[i];
            P = ET[0]*S[0] + ET[1]*S[1] + ET[2]*S[2];
            R[0] = S1[0] + ET[0] - P * S[0];
            R[1] = S1[1] + ET[1] - P * S[1]; 
            R[2] = S1[2] + ET[2] - P * S[2];
        }
            
        //Form B1950 coordinates
        if (Math.abs(R[2]) >= 1.0) {B[0] = 0.0; B[1] = 90.0 * Math1.Sign(R[2]);}
        else {
            B[0] = Math1.AngleRec(Math1.ATan2Deg(R[0], R[1]), 0);
            B[1] = Math1.ASinDeg(R[2]);
        } 
    
    }
 
                                // Convert B1950 equatorial coordinates to galactic
                                // coordinates.  All arguments are in decimal degrees
    public static void EqToGal(double A, double D, double ara[]) {
        double x, y, z, x0, y0, z0;
        x0 = Math1.CosDeg(D)*Math1.CosDeg(A-192.25);
        y0 = Math1.CosDeg(D)*Math1.SinDeg(A-192.25);
        z0 = Math1.SinDeg(D);
        x = y0;
        y = -0.4601998*x0 + 0.8878154*z0;
        z = 0.8878154*x0 + 0.4601998* z0;
        ara[0] = Math1.AngleRec(Math1.ATan2Deg(x,y) + 33.0, 0);
        ara[1] = Math1.ASinDeg(z);
    }
    
 
                                // Convert galactic coordinates to B1950 equatorial
                                // coordinates.  All arguments are in decimal degrees
    public static void GalToEq(double L, double B, double ara[]) {
        double x, y, z, x0, y0, z0;
        x0 = Math1.CosDeg(B)*Math1.CosDeg(L-33.0);
        y0 = Math1.CosDeg(B)*Math1.SinDeg(L-33.0);
        z0 = Math1.SinDeg(B);
        y = x0;
        x = -0.4601998*y0 + 0.8878154*z0;
        z = 0.8878154*y0 + 0.4601998* z0;
        ara[0] = Math1.AngleRec(Math1.ATan2Deg(x,y) + 192.25, 0);
        ara[1] = Math1.ASinDeg(z);
    }


                                // Convert equatorial to ecliptic coordinates
                                // both for the equator and equinox of date.
                                // All arguments are in decimal degrees.
    public static void EqToEcl(double JD, double RA, double Dec, double ara[]) {
        double x, y, z, obl;
        obl = 23.439291 - (JD - 2451545.0) / 2808715.0;
        x = Math1.CosDeg(Dec) * Math1.CosDeg(RA);
        y = Math1.CosDeg(obl) * Math1.CosDeg(Dec) * Math1.SinDeg(RA);
        y += Math1.SinDeg(obl) * Math1.SinDeg(Dec);
        z = Math1.CosDeg(obl) * Math1.SinDeg(Dec);
        z -= Math1.SinDeg(obl) * Math1.CosDeg(Dec) * Math1.SinDeg(RA);
        ara[0] = Math1.Mod(Math1.ATan2Deg(x,y), 360.0);
        ara[1] = Math1.ASinDeg(z);
    }
    
    
                                // Convert equatorial to ecliptic coordinates
                                // both for the equator and equinox of date.
                                // All arguments are in decimal degrees.                                // Convert galactic coordinates to B1950 equatorial
    public static void EclToEq(double JD, double L, double B, double ara[]) {
        double x, y, z, obl;
        obl = 23.439291 - (JD - 2451545.0) / 2808715.0;
        x = Math1.CosDeg(B) * Math1.CosDeg(L);
        y = Math1.CosDeg(obl) * Math1.CosDeg(B) * Math1.SinDeg(L);
        y -= Math1.SinDeg(obl) * Math1.SinDeg(B);
        z = Math1.SinDeg(obl) * Math1.CosDeg(B) * Math1.SinDeg(L); 
        z += Math1.CosDeg(obl) * Math1.SinDeg(B);
        ara[0] = Math1.Mod(Math1.ATan2Deg(x,y), 360.0);
        ara[1] = Math1.ASinDeg(z);
    }

    
                                //ob = true obliquity; ln = longitude; lt = latitude
                                //ra = right ascension; dc = declination;
                                //All quantities in decimal degrees
    public static void EclipticToEquatorial
        (double ob, double ln, double lt, double ara[]) {
        double x, y, z;
        x = Math1.CosDeg(lt) * Math1.CosDeg(ln);
        y = Math1.CosDeg(ob) * Math1.CosDeg(lt) * Math1.SinDeg(ln);
        y -= Math1.SinDeg(ob) * Math1.SinDeg(lt);
        z = Math1.SinDeg(ob) * Math1.CosDeg(lt) * Math1.SinDeg(ln); 
        z += Math1.CosDeg(ob) * Math1.SinDeg(lt);
        ara[0] = Math1.Mod(Math1.ATan2Deg(x,y), 360.0);
        ara[1] = Math1.ASinDeg(z);
    }


                                //Get ET - UT in seconds of time
    public static double DeltaT(double JD) {
        double T1, corr, base=0.0;
        T1 = (JD - 2415020.0)/36525.0;
        corr = 0.0;
        if (T1 < -9.5)
            base = 1360.0 + 320.0*(T1+1.0) + 44.3*(T1+1.0)*(T1+1.0);
        if ((T1 >= -9.5) & (T1 < -2.7))
            base = 25.5*(T1+1.0)*(T1+1.0);
        if (T1 >= -2.7)
            base = -17.0 + 25.0*(T1+0.8)*(T1+0.8);

        if ((T1 >= -2.7) & (T1 < -2.2)) corr = -32.0*(T1+2.7);
        if ((T1 >= -2.2) & (T1 < -1.15)) corr = 46.0*(T1+1.85);
        if ((T1 >= -1.15) & (T1 < -0.4)) corr = -16.0*(T1-0.9);
        if ((T1 >= -0.4) & (T1 < -0.05)) corr = -62.0*(T1+0.1);
        if ((T1 >= -0.05) & (T1 < 0.2)) corr = 80.0*T1;
        if ((T1 >= 0.2) & (T1 < 1.0)) corr = -16.0*(T1-0.9);
        
        return base+corr;
    }
    
    
    public static void SunPos (double JD, double UT, double ara[]) {
        double sinob, t, l, m, x;
        t = (JD + DeltaT(JD)/86400.0 + UT/24.0 - 2415020.0) / 36525.0;
        sinob = Math1.SinDeg(23.452 - 0.013*t);
        l = Math1.AngleRec(279.691 + 36000.7689*t + 0.00030*t*t, 0);
        m = Math1.AngleRec(358.476 + 35999.0498*t - 0.00015*t*t, 0);
        x = l + (1.9195 - 0.0048*t) * Math1.SinDeg(m);
        x += 0.020 * Math1.SinDeg(2.0 * m);
        ara[1] = Math1.ASinDeg(sinob*Math1.SinDeg(x));
        
        x = 15.0*UT + 180.0 + (2.468 - 0.0028*t) * Math1.SinDeg(2.0*l);
        x -= (1.920 - 0.0048*t) * Math1.SinDeg(m);
        x += (0.165 - 0.0006*t) * Math1.SinDeg(m)*Math1.CosDeg(2.0*l);
        x -= 0.053 * Math1.SinDeg(4.0*l);
        x -= 0.020 * Math1.SinDeg(2.0*m);
        x += 0.002 * Math1.SinDeg(6.0*l);
        ara[0] = Math1.AngleRec(x, 0);    
    }
    
}