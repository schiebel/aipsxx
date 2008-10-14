
import org.freehep.j3d.plot.*;
import java.io.*;
import java.util.*;
import java.lang.*;
/**
 *   @author Jason Ye jye@aoc.nrao.edu
 * 
 */

public class SurfaceData implements Binned2DData{

    
    private Rainbow rainbow;
    private Vector data;
    private ArrayBrowser array;
    private int[] startslice;
    private int[] endslice;
    private int xmin;
    private int xmax;
    private int ymin;
    private int ymax;
    private double zmin;
    private double zmax;
    
    public SurfaceData(ArrayBrowser b)    {

	array=b;
	
    }

    public void setSlice(int[] start, int[] end){
	data = array.getSlice(end, start);
	startslice=start;
	endslice=end;
	
	xmin=0;
	ymin=0;
	xmax= data.size();
	ymax=((Vector)data.elementAt(0)).size();
	int xindex=-1;
	int yindex=-1;
	for(int q=0;q<start.length;q++){
	    if(start[q]!=end[q]){
		xindex=q;
	    }
	    
	}
	for(int w=xindex;w<start.length;w++){
	    if(start[w]!=end[w]){
		yindex=w;
	    }
	
	}

	if(xindex!=-1){
	    xmin=start[xindex];
	    xmax=end[xindex];
	}
	if(xindex!=yindex){
	    ymin=start[yindex];
	    ymax=end[yindex];

	}


	zmin=(new Double((String)((Vector)data.elementAt(0)).elementAt(0))).doubleValue();
	zmax=(new Double((String)((Vector)data.elementAt(0)).elementAt(0))).doubleValue();

	for(int i=0;i<data.size();i++){
	    Vector v =((Vector)data.elementAt(0));
	    for(int j=0;j<v.size();j++){
		double temp = (new Double((String)v.elementAt(j))).doubleValue();
		if(temp<zmin)
		    zmin=temp;
		if(temp>zmax)
		    zmax=temp;
	    }

	}

    }

    public int xBins()    {
	int a=-1;
	if(data!=null)
	    a=data.size();
	
	return a;

    }
    
    public int yBins()
    {
	int a=-1;
	if(data!=null){
	 
	    Vector b = (Vector)data.elementAt(0);
	    a=b.size();
	}
	return a;

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
	return (float)zmin;	
    }
    public float zMax()
    {	

	return (float)zmax;
	
    }
    
    public float zAt(int xIndex, int yIndex)
    {
	String value = (String)((Vector)data.elementAt(xIndex)).elementAt(yIndex);
	Double d = new Double(value);
	return d.floatValue();
    }
    
    public javax.vecmath.Color3b colorAt(int xIndex, int yIndex)
    {
	return rainbow.colorFor(zAt(xIndex,yIndex));
    }
}
