public class DComplex{

    public double real;
    public double imag;
    public DComplex(double r,  double i){
	real=r;
	imag=i;
	
    }

    public double getReal(){

	return real;
    }

    public double getImag(){
	return imag;

    }

    public void setReal(double f){

        real=f;
    }

    public void setImag(double f){

	imag=f;
    }

    public String toString(){
	String ret = "";
	if(imag>=0){
	    ret =String.valueOf(real) + " +" +String.valueOf(imag) +"i";
	}

	else{
	    ret = String.valueOf(real) + " "  +String.valueOf(imag) +"i";
	}
	return ret;
    }

}
