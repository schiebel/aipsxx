public class Complex{

    public float real;
    public float imag;

    public Complex(float r,  float i){
	real=r;
	imag=i;
	
    }

    public float getReal(){

	return real;
    }

    public float getImag(){
	return imag;

    }

    public void setReal(float f){

        real=f;
    }

    public void setImag(float f){

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
