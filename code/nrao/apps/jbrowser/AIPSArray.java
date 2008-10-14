import java.util.*;
import java.lang.*;
import java.sql.*;



/** This class represents an n-dimensional array. It provides methods
 * for slicing, editing and graphically viewing the array.
 * 
 *<p> 
 *@author Jason Ye
 */


public class AIPSArray {
  
  
  
   
    private int dim;
    private int[] indexingFactors;
    private Vector entries;
    private int[] axisLengths;
    private int[] m_sliceStart;
    private int[] m_sliceEnd;
    private String m_type;
    private String m_arrayinfo;
    private boolean invalid;
    /** Construct an AIPSArray from a string s and with the datatype type.
     *  s must be in the same format produced by C++ code, when an AIPS++ Array 
     *  is fed into a stream. 
     */


    public AIPSArray(String s, String type) {
	m_arrayinfo =s;

	this.setType(type);
	this.silentInitiate(m_arrayinfo);
	invalid=false;
    }

   


    /** Set the type of the array.
     */
    
    public void setType(String s){
	m_type=s;
	
    }
    
    /** Get the type of the array.
     */

    public String getType(){
	return m_type;
    }

    public String linearForm(){
	
	String ret="";
	if(invalid){
	    ret ="Invalid Array";
	    //System.out.println("invalid array");
	}
	else{
	    for(int i=0;i<entries.size();i++){
		Vector temp = (Vector)entries.elementAt(i);
		for(int j=0;j<temp.size();j++){
		    ret+=(String)temp.elementAt(j)+" ";
		}
	    }
	    ret.trim();
	}
	return ret;
    }

    
    public void setEntry(int[] arr, Object newVal){
	if(dim==1){
	    Vector temp = (Vector)entries.elementAt(0);
	    temp.removeElementAt(arr[0]);
	    // System.out.println("putting: "+newVal+ " at "+arr[0]);
	    temp.insertElementAt(newVal, arr[0]);
	}
	else if( dim==2){
	    Vector temp = (Vector)entries.elementAt(arr[0]);
	    temp.removeElementAt(arr[1]);
	    // System.out.println("putting: "+newVal+ " at "+arr[0]);
	    temp.insertElementAt(newVal, arr[1]);
	}
	else{
	    int len = indexingFactors.length;
	    for (int a=0;a<arr.length;a++){
		//	System.out.println("entry: arr["+a+"] : "+arr[a] );
	    }
	    
	    int index=0;
	    for (int i=0;i<len;i++){
		//	System.out.println("indexingF["+i+"]="+indexingFactors[i]);
		index+=indexingFactors[i]*arr[i+2];
		
	    }
	    
	    index+=arr[1];
	    // System.out.println("index : "+index);
	    //System.out.println("size of Entries: "+entries.size());
	
	    Vector temp = (Vector)entries.elementAt(index);
	    
	    temp.removeElementAt(arr[0]);
	    //System.out.println("putting: "+newVal+ " at "+arr[0]);
	    temp.insertElementAt(newVal, arr[0]);
	}
    }
    

    
  
    /** Get a Vector from the slice starting at arrStart and
	ending at arr. The returned Vector is readily displayable
	by this an ArrayTable without futher manipulation.
    */


    public void silentInitiate(String s){
	try{
	Vector columns = new Vector();
	Vector data = new Vector();
	entries = new Vector();
	//	System.out.println("ArrayBrowser parsing string: " + s);
	if(s.startsWith("[")){
	    dim =1;
	    axisLengths= new int[dim];
	    //  System.out.println("1D array type: "+m_type);
	   
	    // System.out.println("1-D");
	    int end = s.indexOf(']');
	    s = s.substring(0,end+1);
	    //System.out.println("1D string is:\n "+s );
	    int i=0;
	    if (m_type.trim().equals("TpArrayComplex")||m_type.trim().equals("TpArrayDComplex")){
		//System.out.println("1d if entered");
		StringTokenizer tok = new StringTokenizer(s, "[(,)]", true);
		String val= "";
		
		String ival="";
		String com="";
		Vector tempVector = new Vector();
		entries.add(tempVector);
		
		while(tok.hasMoreTokens()){
		    val = tok.nextToken();
		    if(val.trim().equals("(")){
			val=tok.nextToken().trim();
			com = tok.nextToken();
			ival= tok.nextToken().trim();
			tempVector.add("("+val+","+ival+")");
			i++;
		    }
		}
		
	    }
	    
	    else{
	   
	    StringTokenizer tok = new StringTokenizer(s, "[,]");
	    String val="";
	  
	    
	    Vector tempVector = new Vector();
	    entries.add(tempVector);
	    while(tok.hasMoreTokens()){
		
		val = tok.nextToken();
		
		//System.out.println("array token: "+ val);
		tempVector.add(val);
	
		i++;
		
	    }

	    }
	    axisLengths[0]=i;
	    
	    indexingFactors=null;
	    int[] stest = new int[1];
	    stest[0]=0;
	    m_sliceStart=stest;
            m_sliceEnd = new int[1];
	    
	    m_sliceEnd[0] = (axisLengths[0]-1);
	    
	    data=getSlice(m_sliceEnd, m_sliceStart );
	    
	    
	   
	    for(int ewk = 0; ewk < axisLengths[0]; ewk++){
		columns.add(String.valueOf(ewk));

	    }
	    



	    
	}
	
	else if(s.startsWith("Axis Lengths:")){
	    //System.out.println("2-D");
	    dim=2;
	    axisLengths=new int[dim];
	    StringTokenizer tok = new StringTokenizer(s, "[,]");
	    String val="";
	    val=tok.nextToken();
	    //System.out.println("arraytoken: "+val);
	   
	   
	    int rowNum = (new Integer(tok.nextToken().trim())).intValue();
	    axisLengths[0]=rowNum;
	    //System.out.println("row number: "+rowNum);
	   
	    int colNum = (new Integer(tok.nextToken().trim())).intValue();
	    axisLengths[1]=colNum;
	    //System.out.println("col number: "+colNum);
	    for (int i=0; i<rowNum;i++){
		entries.add(new Vector());
	    }
	    val=tok.nextToken();
	    //System.out.println("arraytoken: "+val);
	    
	    for (int j=0; j<rowNum;j++){
		for(int k=0; k<colNum;k++){
		    val=tok.nextToken(" \n[]").trim();
		    if(val.endsWith(",")){
			int end = val.lastIndexOf(',');
			val = val.substring(0,end);
		    }
		    //    System.out.println("arraytoken: "+val);
		    ((Vector)entries.elementAt(j)).add(val);
		    
		}
	    }
	  
	    indexingFactors=null;
	    int[] stest = new int[dim];
	    stest[0]=0;
	    stest[1]=0;
	    m_sliceStart=stest;
            m_sliceEnd = new int[dim];
	    m_sliceEnd[0]= axisLengths[0]-1;
	    m_sliceEnd[1]= axisLengths[1]-1;
	    data=getSlice(m_sliceEnd, m_sliceStart);
	    for(int ewk = 0; ewk<axisLengths[1]; ewk++){
		columns.add(new Integer(ewk));
	    }
		
	}

	else if(s.startsWith("Ndim=")){
	    //System.out.println("Multi_D");
	 
	    StringTokenizer tok= new StringTokenizer(s, "= ");
	    String val="";
	    val=tok.nextToken();
	    //System.out.println("Ndim: "+val);
	    dim =  (new Integer(tok.nextToken().trim())).intValue();
	    //System.out.println("dim  number: "+dim);
	    axisLengths = new int[dim];
	    String temp = tok.nextToken("[,]");
	    int numElements=1;
	    for (int a=0;a<dim;a++){
		temp = tok.nextToken("[,]");
		//System.out.println("Axis length: " +temp);
		axisLengths[a]= (new Integer(temp.trim())).intValue();
		numElements=numElements*(new Integer(temp.trim())).intValue();
	    }


	    if(axisLengths[0]==0){
// 		for(int jk=0;jk<axisLengths.length;jk++){
// 		    System.out.print(axisLengths[jk]+" ");
// 		}
// 		System.out.println("");
// 		System.out.println(m_arrayinfo);
// 		System.exit(1);
		invalid=true;
	    }
	    for(int b=0;b<(numElements/axisLengths[0]);b++){
		for(int c=0; c<dim; c++){
		    //skip tokens
		    temp = tok.nextToken("[,]");
		    if(temp.trim().equals(""))
			temp = tok.nextToken("[,]");
		    //  System.out.println("skipping: " +temp);   

		}
		Vector tempVector = new Vector();
		entries.add(tempVector);
		for(int d=0;d<axisLengths[0];d++){
		    temp = tok.nextToken("[,]");
		    // System.out.println("the goods: " +temp);   
		    tempVector.add(temp.trim());
		    
		}
	       

	    }

	    indexingFactors = new int[dim-2];
	    indexingFactors[0] = axisLengths[1];
	    for(int f=1;f<dim-2;f++){
		
		indexingFactors[f]=indexingFactors[f-1]*axisLengths[f+1];


	    }

	    int[] stest = new int[dim];
	    for(int fa=0;fa<dim;fa++){
		stest[fa]=0;
	    }
	    m_sliceStart=stest;
	    m_sliceEnd = stest;
	    data=getSlice(stest, stest);
	    for(int x=0;x<((Vector)data.elementAt(0)).size();x++){
		columns.add(String.valueOf(x));
	    }
	    for(int y=0;y<data.size();y++){
		
		//	System.out.println("------------------");
		Vector t=(Vector)data.elementAt(y);
		for(int z=0;z<t.size();z++){
		    
		    //  System.out.println(t.elementAt(z));
		}

	    }
	}
	
	else if(s.trim().startsWith("AipsError")){
	    
	    System.out.println("database error");
	}
	
	}
	catch(ArithmeticException e){
	    //e.printStackTrace();
	    invalid=true;
	}
	    
    }

    public Vector getSlice(int[] arr, int[] arrStart){
	Vector data = new Vector();
	if(!invalid){
	//check to see if they satisfy the axis info
	m_sliceStart = arrStart;
	m_sliceEnd =arr;

	int index1=0;
	int index2=0;
	int numEl1=0;
	int numEl2=0;
	int whichIndex=0;
	int extra=0;
	for(int i=0;i<arr.length; i++){
	    if(arr[i]!=0){
		if(whichIndex==0){
		    index1= i;
		    numEl1=arr[i];
		    whichIndex=1;
		}

		else if (whichIndex==1){
		    index2=i;
		    numEl2=arr[i];
		    whichIndex=2;
		}

		else{

		    extra=1;
		}
	    }

	}
	

	int sindex1=index1;
	int sindex2=index2;
	int snumEl1=arrStart[sindex1];
	int snumEl2=arrStart[sindex2];
	if(arr.length==1||sindex1==sindex2){
	    snumEl2=0;
	    numEl2=0;
	}

// 	System.out.println("snumEl1: "+snumEl1+ " at "+ sindex1);
// 	System.out.println("snumEl2: "+snumEl2+ " at "+sindex2);

// 	System.out.println("numEl1: "+numEl1+" at "+ index1);
// 	System.out.println("numEl2: "+numEl2+"at "+ index2);
// 	System.out.println("extra: "+extra);
	if(numEl1<=axisLengths[index1]&&numEl2<=axisLengths[index2]&&extra==0&&snumEl1<=numEl1&&snumEl2<=numEl2){
	    int[] entry = new int[dim];
	    if(dim ==1){
		
		Vector newVec = new Vector();
		data.add(newVec);
		for(int k=arrStart[0];k<arr[0]+1;k++){
		    entry[0]=k;
		    newVec.add(getEntry(entry));
		    //   System.out.println("1dslice");
		}
	    }
	    else{
	    for(int k=snumEl1;k<numEl1+1;k++){
	    
		for (int j=0;j<dim;j++){
		    entry[j]=0;

		}
		entry[index1]=k;
		Vector newVec = new Vector();
		
	
		data.add(newVec);
		for(int l=snumEl2;l<numEl2+1;l++){
		   //  System.out.println("arr["+index1+"] = "+k);
// 		    System.out.println("arr["+index2+"] = "+l);
// 		    System.out.println("=================");
		    if(whichIndex==1){
			//second index not assigned
			
		    }
		    else{
			entry[index2]=l;
		    }
		    newVec.add(getEntry(entry));
		    
		}
		
		}
	    }
	}
	else{
	    System.out.println("Invalid Slice.");
	    invalid=true;
	}
	}
	return data;
	
    }

    /** Get the enty indicated by index arr*/

    public String getEntry(int[] arr){

	String ret="";
	try{
	if(!invalid){
	if(1==dim){
	    Vector temp =  (Vector)entries.elementAt(0);
	    ret = (String)temp.elementAt(arr[0]);
	    
	}
	    
	else if(2==dim){

	    Vector temp =(Vector)entries.elementAt(arr[0]);
	    ret =(String)temp.elementAt(arr[1]);
	}
	else{	
	    int len = indexingFactors.length;
	    for (int a=0;a<arr.length;a++){
		// System.out.println("entry: arr["+a+"] : "+arr[a] );
	    }
	  
	    int index=0;
	    for (int i=0;i<len;i++){
		// System.out.println("indexingF["+i+"]="+indexingFactors[i]);
		index+=indexingFactors[i]*arr[i+2];
		
	    }
	    
	    index+=arr[1];
	    //	System.out.println("index : "+index);
	    //	System.out.println("size of Entries: "+entries.size());
	    
	    Vector temp = (Vector)entries.elementAt(index);
	
	    ret= (String)temp.elementAt(arr[0]);
	    //	System.out.println("ret : "+ret);
	}
	}
	}
	catch(Exception ex){
	    System.out.println("Slicing Error");
	}
	return ret;
	
	
    }
    /** Get the int array representing the start of current slice.*/

    public int[] getStartSlice(){
	return m_sliceStart;
    }

    /** Get the int array representing the end of current slice.*/
    public int[] getEndSlice(){
	return m_sliceEnd;

    }
      
    public int[] getAxisLengths(){
	return axisLengths;
    }
    public int getDimN(){
	return dim;
    }
}
