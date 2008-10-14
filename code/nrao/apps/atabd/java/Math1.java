public class Math1 extends Object{

                           //Test returns a (type double) 1.0 if True else 0.0;
    public static double Test(boolean x) {
        if (x == true) return 1.0;
        return 0.0;
    }
                            //Sign of argument (returns -1.0 for negative,
                            //                           1.0 for zero or positive)   public static double Sign(double x) {
    public static double Sign(double x) {
        if (x < 0.0) return -1.0; else return 1.0;
    }
    public static float Sign(float x) {
        if (x < 0.0) return (float)-1.0; else return (float)1.0;
    }   

                               //Frac gives the fractional part of a double
    public static double Frac(double x) {
        double s, y;
        s = 1.0;  if (x < 0.0) s = -1.0;
        x = Math.abs(x);
        y = x - (x % 1);
        return s*(x - y);
    }
                            //Modulus function for doubles (Remainder of y/x)
    public static double Mod(double x, double y) {
        return y * Frac(1.0 + Frac(x/y));
    }
  
                            // Sine of angle (argument in degrees)
    public static double SinDeg(double x) {
        return Math.sin(x*Math.PI/180.0);
    }
    
                             //Cosine of angle (argument in degrees)
    public static double CosDeg(double x) {
        return Math.cos(x*Math.PI/180.0);
    }
    
                             //Tangent of angle (argument in degrees)
    public static double TanDeg(double x) {
        return Math.sin(x*Math.PI/180.0) / Math.cos(x*Math.PI/180.0);
    }
  
                                //Arc tangent of angle (returned in degrees)
    public static double ATanDeg(double x) {
        return Math.atan(x)*180.0/Math.PI;
    }
    
                                  //Arc tangent of y/x (returned in degrees)
    public static double ATan2Deg(double x, double y) {
        double t1, t2, t3;
        if (x == 0.0) return 90.0 * Sign(y);
        if (y == 0.0) t1 = 1.0; else t1 = 0.0;
        if (x < 0.0) t2 = 1.0; else t2 = 0.0;
        t3 = 180.0 * t2 * (t1 + Sign(y));
        return ATanDeg(y / x) + t3;
    }
    
                                     //Arc sine in degrees
    public static double ASinDeg(double x) {
        if (Math.abs(x) == 1.0) return 90.0*x;
        return Math.atan(x / Math.sqrt(1.0-x*x)) * 180.0 / Math.PI;
    }
    
                                    //Arc cosine in degrees
    public static double ACosDeg(double x) {
        double sx;
        if (x == 0.0) return 90.0;
        sx = Test(x < 0.0);
        return Math.atan(Math.sqrt(1.0-x*x)/x) * 180.0 / Math.PI + sx; 
    }
    
                               //AnglRec rectifies an angle to range between 
                               // 1) 0 and 360 degrees if switch = 0 or
                               // 2) -180 and 180 degrees if switch = 1
    public static double AngleRec(double angle, int swtch) { 
        double temp1, temp2;
        temp1 = Mod(angle, 360.0);
        if (swtch == 0) return temp1;
        temp2 = 360.0 * Test(temp1 > 180.0);
        return temp1 - temp2;
    }
    
}
