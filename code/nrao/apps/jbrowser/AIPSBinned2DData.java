import java.util.*;
import org.freehep.j3d.plot.*;


/**
 * Experimental. Works but not pretty.
 * @author Jason Ye jye@aoc.nrao.edu
 */

public class AIPSBinned2DData implements Binned2DData
{
    private int xBins=20;
    private int yBins=20;
    private Rainbow rainbow ;
    private float[][] data;
    private Vector points;
    private float xmax, xmin, ymax, ymin, zmax, zmin;
    public AIPSBinned2DData(int xbins, int ybins){
	points = new Vector();
	xBins=xbins;
	yBins=ybins;
	data=new float[xBins][yBins];
    }
    public AIPSBinned2DData(int xbins, int ybins, Vector pts){
	points = new Vector();
	xBins=xbins;
	yBins=ybins;
	data=new float[xBins][yBins];
	points=pts;
	initData();
    }

    public void addPoint(float x, float y, float z){
	//	System.out.println("addpoint : "+x+", "+y+", "+ z);
	  
	points.add( new AIPS3DPoint(x,y,z));
	
    }
    
    public void initData(){
	System.out.println("initData called");
	AIPS3DPoint p = (AIPS3DPoint)points.elementAt(0);
	xmax = p.getX();
	xmin = p.getX();
	ymax = p.getY();
	zmax = p.getZ();
	ymin = p.getY();
	zmin = p.getZ();
	
	float x;
	float y;
	float z;
	System.out.println("breal 1");
	for(int i=1;i<points.size();i++){
	    p = (AIPS3DPoint)points.elementAt(i);
	    
	    x = p.getX();
	    y = p.getY();
	    z = p.getZ();
	    if(x<xmin)
		xmin=x;
	    else if(x>xmax)
		xmax =x;

	    if(y<ymin)
		ymin=y;
	    else if(y>ymax)
		ymax =y;
	    
	    if(z<zmin)
		zmin=z;
	    else if(z>zmax)
		zmax =z;
	    
	}
	rainbow=new Rainbow(zmin, zmax);
	for(int j=0;j<xBins;j++){
	    for(int k=0;k<yBins;k++){
		data[j][k]=zmin;

	    }
	}
	initData2();
    }
    public void initData2(){
	
	
	System.out.println("breal 2");
	float xt = xmax-xmin+1;
	float yt = ymax-ymin+1;
	int sz =  points.size();
	System.out.println("breal 2.5 "+ sz);
	
	int[][] count = new int[xBins][yBins];
	for(int w=0;w<xBins;w++){
	    for(int v=0; v<yBins;v++){
		count[w][v]=0;
	    }
	}

	for(int l=0;l<sz;l++){
	    //  System.out.println("loop "+l);
	    AIPS3DPoint p = (AIPS3DPoint)points.elementAt(l);
	    //  System.out.println("loops to "+l);

	    if(p!=null){
		
		float x = p.getX();
		float y = p.getY();
		float z = p.getZ();
		
		int xc = (int)((x-xmin)/xt * (float)xBins);
		
		int yc = (int)((y-ymin)/yt * (float)yBins);
		//	System.out.println("inserting( "+xc+ ", "+yc+", "+z+" )");

		int counter = count[xc][yc];
		if(counter==0){
		    data[xc][yc]=z;
		    count[xc][yc]=1;
		}
		else{
		    //divide first, risk losing precision to prevent overflows
		    float tmp = data[xc][yc];
		    tmp=tmp/((float)(counter+1));
		    tmp=tmp*((float)counter);
		   
		    data[xc][yc]=tmp+z/((float)(counter+1));
		    System.out.println("bin counter = "+counter);
		    count[xc][yc]=counter+1;
		}
		//System.out.println("( "+xc+ ", "+yc+", "+z+" )" );
	    }

	    else{
		System.out.println("null point 3d");
	    }
	}
	
	System.out.println("-==-"+ymin+ ", "+ymax );
	points.clear();
	

    }

    public int xBins()
    {
	return xBins;
    }
    
    public int yBins()
    {
	return yBins;
    }
    
    public float xMin()
    {
	return xmin;
    }
    
    public float xMax()
    {
	return xmax;
    }
    
    public float yMin()
    {
	return ymin;
    }

    public float yMax()
    {
	return ymax;
    }
    
    public float zMin()
    {
	return zmin;
    }
    public float zMax()
    {
	return zmax;
    }
    
    public float zAt(int xIndex, int yIndex)
    {
	return data[xIndex][yIndex];
    }
    
    public javax.vecmath.Color3b colorAt(int xIndex, int yIndex)
    {
		return rainbow.colorFor(zAt(xIndex,yIndex));
    }
}
