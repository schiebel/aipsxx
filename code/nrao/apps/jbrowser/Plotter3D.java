import org.jfree.data.*;
import org.jfree.chart.*;
import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.lang.*;
import java.util.*;
import org.freehep.j3d.plot.*;


public class Plotter3D extends JInternalFrame implements ItemListener, ActionListener{

    //private JPanel pan=null;
    private JButton rows=null;
    private JTextField startfield, endfield, xslice, yslice, zslice;
    private JButton m_previous, m_next;
    private DataSet ds;
    private int xvarcol;
    private int firstrow;
    private int lastrow;
    private int yvarcol;
    private int zvarcol;
    
    private int[] xindex;
    private int[] yindex;
    private int[] zindex;
    private TableBrowser parent;
    private String query,tablename, whereclause;
    private Vector colNames;
    private Hashtable arraycols;
    private JComboBox xvarbox, var, zvar;
    private boolean scrollable;
    private int xbin, ybin;
    private LegoPlot plot=null;
    
    
    public Plotter3D(Vector cn, Hashtable ht, String q,TableBrowser browser){
	super("Plotter3D", true, true, true, true);
	try{
	    xbin=100;
	    ybin=100;
	colNames=cn;
	arraycols=ht;
	parent=browser;
	scrollable=false;
	if(-1!=q.indexOf("ORDERBY"))
	    q = q.replaceFirst(q.substring(q.indexOf("ORDERBY")), "");
	if(-1!=q.indexOf("GIVING"))
	    q = q.replaceFirst(q.substring(q.indexOf("GIVING")), "");
	
	int whereindex = q.indexOf("WHERE");
	if(-1!=whereindex){
	    whereclause = q.substring(whereindex);
	    whereclause= whereclause.replaceFirst("WHERE", "");
	    
	    
	    System.out.println(whereclause);
	    q = q.replaceFirst(q.substring(q.indexOf("WHERE")), "");
	    
	}
	
	tablename=q.substring(q.indexOf("FROM"));
	tablename= (tablename.replaceFirst("FROM", "")).trim();
	System.out.println("table: "+tablename +" where: "+whereclause);
			      

	
       	JToolBar toolBar = new JToolBar();
	toolBar.setVisible(true);
        toolBar.setFloatable(false);
	this.getContentPane().add(toolBar, BorderLayout.SOUTH);
        m_previous = new JButton(new ImageIcon("icons/left.gif"));
	m_previous.setToolTipText("Previous Page");
	
	toolBar.add(m_previous);
	m_previous.addActionListener(this);

	m_next = new JButton(new ImageIcon("icons/right.gif"));
	m_next.setToolTipText("Next Page");
	m_next.addActionListener(this);
	
	toolBar.add(m_next);
	
	toolBar.addSeparator();
	toolBar.add(new Label("Rows:"));
        
	startfield= new JTextField();
	toolBar.add(startfield);
	
	toolBar.add(new Label("to"));
	
	endfield= new JTextField();
	toolBar.add(endfield);
	
	toolBar.addSeparator();
	rows = new JButton("PLOT");
	rows.addActionListener(this);
	toolBar.add(rows);
	

	toolBar.addSeparator();
	toolBar.add(new Label ("X:"));
	xvarbox = new JComboBox();
	toolBar.add(xvarbox);
	//xvarbox.addItemListener(new PlotterXChanger(this));
	xslice= new JTextField();
	toolBar.add(xslice);
	
	toolBar.add(new Label("Y:"));
	var = new JComboBox();
	var.addItemListener(this);
	toolBar.add(var);
	yslice= new JTextField();
	toolBar.add(yslice);
	
	toolBar.add(new Label("Z:"));
	zvar = new JComboBox();
	zvar.addItemListener(this);
	toolBar.add(zvar);
	zslice= new JTextField();
	toolBar.add(zslice);
	
	for(int i=0; i<colNames.size();i++){
	    
	    var.addItem(colNames.elementAt(i));
	    xvarbox.addItem(colNames.elementAt(i));
	    zvar.addItem(colNames.elementAt(i));
   
	}
	
	
	
	
	//getContentPane().add(new GraphCanvas(null, 0 ,null, 0 ,null,0 ,0),BorderLayout.CENTER);
	this.pack();
	this.setVisible(true);
	setSize(700,400);
	
	}
	catch(Exception ex){
	    ex.printStackTrace();
	}
	

    }
    public void setYBin(int i){
	if(i>0)
	    ybin=i;
    }

    public void setXBin(int i){
	if(i>0)
	    xbin=i;
    
    }
    public void setQuery(String s){
	query=s;
    }

    public void setVarNames(Vector v)
    {
	colNames=v;
    }



    public AIPSBinned2DData makeScatterPlot(int xc,int[]xind,  int yc, int[] yind, int zc, int[] zind, int start, int end){

	AIPSBinned2DData ret=new AIPSBinned2DData(xbin, ybin);
	try{
	    //date stuff
	    GregorianCalendar cal = new GregorianCalendar();
	    StringTokenizer tok=null;
	    int year=-1;
	    int mon=-1;
	    int day=-1;
	    int hour=-1;
	    int min=-1;
	    int sec=-1;
	    //end date stuff

	    
	String xtype = ds.getMetaData().getColumnTypeName(xc);
	String ytype = ds.getMetaData().getColumnTypeName(yc);
	String ztype = ds.getMetaData().getColumnTypeName(zc);

	if(1>=start||start>ds.getTotalRows())
	    ds.beforeFirst();
	else
	    ds.absolute(start-1);
	

	Vector pts = new Vector();
	int curr = start-1;
	Number x=null;
	Number y=null;
	Number z=null;
	while(ds.next()){
	    //  System.out.println("end between");
	    curr++;
	    //System.out.println("current: "+curr);
	    if(xtype.equals("TpShort")||xtype.equals("TpUShort")){
		x = new Short(ds.getString(xc));
	    }
	    else if(xtype.equals("TpInt")||xtype.equals("TpUInt")||xtype.equals("TpBool")){
		x = new Integer(ds.getString(xc));
	    }

	    else if(xtype.equals("TpFloat")){
		x = new Float(ds.getString(xc));
	    }
	    
	    else if(xtype.equals("TpDouble")){
		x = new Double(ds.getString(xc));
	    }

	    else if(xtype.equals("TpDate")){
		String s =ds.getString(xc);
		tok=new StringTokenizer(s, "-: ");
		if(tok.countTokens()!=6)
		    throw new Exception("Bad Date: "+s);
		year = (new Integer(tok.nextToken())).intValue();
		mon = (new Integer(tok.nextToken())).intValue();
		day=(new Integer(tok.nextToken())).intValue();
		hour=(new Integer(tok.nextToken())).intValue();
		min=(new Integer(tok.nextToken())).intValue();
		sec=(new Integer(tok.nextToken())).intValue();

	
		cal.set(year,mon,day,hour,min,sec);
		x = new Long(cal.getTimeInMillis());
		
	    }


	    else if(xtype.equals("TpArrayDouble")){
		AIPSArray aa=(AIPSArray)ds.getArray(xc).getArray();
		if( xind.length!=aa.getDimN()){
		    JOptionPane.showMessageDialog(this, "Invalid slice: array is "+aa.getDimN()+"-dimensional", "Array Cell Plotting Error", JOptionPane.WARNING_MESSAGE);	
		    throw new Exception("Array Cell Plotting Error: Invalid Slice");
		}
		
		x = new Double(aa.getEntry(xind));
		//	System.out.println(x);
	    }
	    else if(xtype.equals("TpArrayFloat")){
		AIPSArray aa=(AIPSArray)ds.getArray(xc).getArray();
		if( xind.length!=aa.getDimN()){
		    JOptionPane.showMessageDialog(this, "Invalid slice: array is "+aa.getDimN()+"-dimensional", "Array Cell Plotting Error", JOptionPane.WARNING_MESSAGE);	
		    throw new Exception("Array Cell Plotting Error: Invalid Slice");
		}
		x = new Float(aa.getEntry(xind));
	    }
	    else if(xtype.equals("TpArrayInt")||xtype.equals("TpArrayUInt")||xtype.equals("TpArrayBool")){
		AIPSArray aa=(AIPSArray)ds.getArray(xc).getArray();
		if( xind.length!=aa.getDimN()){
		    JOptionPane.showMessageDialog(this, "Invalid slice: array is "+aa.getDimN()+"-dimensional", "Array Cell Plotting Error", JOptionPane.WARNING_MESSAGE);	
		    throw new Exception("Array Cell Plotting Error: Invalid Slice");
		}
		x = new Integer(aa.getEntry(xind));
	    }
	    
	    else if(xtype.equals("TpArrayShort")||xtype.equals("TpArrayUShort")){
		AIPSArray aa=(AIPSArray)ds.getArray(xc).getArray();
		if( xind.length!=aa.getDimN()){
		    JOptionPane.showMessageDialog(this, "Invalid slice: array is "+aa.getDimN()+"-dimensional", "Array Cell Plotting Error", JOptionPane.WARNING_MESSAGE);	
		    throw new Exception("Array Cell Plotting Error: Invalid Slice");
		}
		x = new Short(aa.getEntry(xind));
	    }

	    
	    if(ytype.equals("TpShort")||ytype.equals("TpUShort")){
		y = new Short(ds.getString(yc));
	    }
	    else if(ytype.equals("TpInt")||ytype.equals("TpUInt")||ytype.equals("TpBool")){
		y = new Integer(ds.getString(yc));
	    }
	    
	    else if(ytype.equals("TpFloat")){
		y = new Float(ds.getString(yc));
	    }
	    
	    else if(ytype.equals("TpDouble")){
		y = new Double(ds.getString(yc));
	    }

	    else if(ytype.equals("TpDate")){
		String s =ds.getString(yc);
		tok=new StringTokenizer(s, "-: ");
		if(tok.countTokens()!=6)
		    throw new Exception("Bad Date: "+s);

		year = (new Integer(tok.nextToken())).intValue();
		mon = (new Integer(tok.nextToken())).intValue();
		day=(new Integer(tok.nextToken())).intValue();
		hour=(new Integer(tok.nextToken())).intValue();
		min=(new Integer(tok.nextToken())).intValue();
		sec=(new Integer(tok.nextToken())).intValue();


	
		cal.set(year,mon,day,hour,min,sec);
		y = new Long(cal.getTimeInMillis());
		
	    }

	    else if(ytype.equals("TpArrayDouble")){
		AIPSArray aa=(AIPSArray)ds.getArray(yc).getArray();
		if( yind.length!=aa.getDimN()){
		    JOptionPane.showMessageDialog(this, "Invalid slice: array is "+aa.getDimN()+"-dimensional", "Array Cell Plotting Error", JOptionPane.WARNING_MESSAGE);	
		    throw new Exception("Array Cell Plotting Error: Invalid Slice");
		}
		y = new Double(aa.getEntry(yind));
		//	System.out.println(y);
	    }
	    else if(ytype.equals("TpArrayFloat")){
		AIPSArray aa=(AIPSArray)ds.getArray(yc).getArray();
		if( yind.length!=aa.getDimN()){
		    JOptionPane.showMessageDialog(this, "Invalid slice: array is "+aa.getDimN()+"-dimensional", "Array Cell Plotting Error", JOptionPane.WARNING_MESSAGE);	
		    throw new Exception("Array Cell Plotting Error: Invalid Slice");
		}
		y = new Float(aa.getEntry(yind));
	    }
	    else if(ytype.equals("TpArrayInt")||ytype.equals("TpArrayUInt")||ytype.equals("TpArrayBool")){
		AIPSArray aa=(AIPSArray)ds.getArray(yc).getArray();
		if( yind.length!=aa.getDimN()){
		    JOptionPane.showMessageDialog(this, "Invalid slice: array is "+aa.getDimN()+"-dimensional", "Array Cell Plotting Error", JOptionPane.WARNING_MESSAGE);	
		    throw new Exception("Array Cell Plotting Error: Invalid Slice");
		}
		y = new Integer(aa.getEntry(yind));
	    }
	    
	    else if(ytype.equals("TpArrayShort")||ytype.equals("TpArrayUShort")){
		AIPSArray aa=(AIPSArray)ds.getArray(yc).getArray();
		if( yind.length!=aa.getDimN()){
		    JOptionPane.showMessageDialog(this, "Invalid slice: array is "+aa.getDimN()+"-dimensional", "Array Cell Plotting Error", JOptionPane.WARNING_MESSAGE);	
		    throw new Exception("Array Cell Plotting Error: Invalid Slice");
		}
		y = new Short(aa.getEntry(yind));
	    } 

	    if(ztype.equals("TpShort")||ztype.equals("TpUShort")){
		z = new Short(ds.getString(zc));
	    }
	    else if(ztype.equals("TpInt")||ztype.equals("TpUInt")||ztype.equals("TpBool")){
		z = new Integer(ds.getString(zc));
	    }
	    
	    else if(ztype.equals("TpFloat")){
		z = new Float(ds.getString(zc));
	    }
	    
	    else if(ztype.equals("TpDouble")){
		z = new Double(ds.getString(zc));
	    }

	    else if(ztype.equals("TpDate")){
		String s =ds.getString(zc);
		tok=new StringTokenizer(s, "-: ");
		if(tok.countTokens()!=6)
		    throw new Exception("Bad Date: "+s);

		year = (new Integer(tok.nextToken())).intValue();
		mon = (new Integer(tok.nextToken())).intValue();
		day=(new Integer(tok.nextToken())).intValue();
		hour=(new Integer(tok.nextToken())).intValue();
		min=(new Integer(tok.nextToken())).intValue();
		sec=(new Integer(tok.nextToken())).intValue();


	
		cal.set(year,mon,day,hour,min,sec);
		z = new Long(cal.getTimeInMillis());
		
	    }

	    else if(ztype.equals("TpArrayDouble")){
		AIPSArray aa=(AIPSArray)ds.getArray(zc).getArray();
		if( zind.length!=aa.getDimN()){
		    JOptionPane.showMessageDialog(this, "Invalid slice: array is "+aa.getDimN()+"-dimensional", "Array Cell Plotting Error", JOptionPane.WARNING_MESSAGE);	
		    throw new Exception("Array Cell Plotting Error: Invalid Slice");
		}
		z = new Double(aa.getEntry(zind));
		//	System.out.println(y);
	    }
	    else if(ztype.equals("TpArrayFloat")){
		AIPSArray aa=(AIPSArray)ds.getArray(zc).getArray();
		if( zind.length!=aa.getDimN()){
		    JOptionPane.showMessageDialog(this, "Invalid slice: array is "+aa.getDimN()+"-dimensional", "Array Cell Plotting Error", JOptionPane.WARNING_MESSAGE);	
		    throw new Exception("Array Cell Plotting Error: Invalid Slice");
		}
		z = new Float(aa.getEntry(zind));
	    }
	    else if(ztype.equals("TpArrayInt")||ztype.equals("TpArrayUInt")||ztype.equals("TpArrayBool")){
		AIPSArray aa=(AIPSArray)ds.getArray(zc).getArray();
		if( zind.length!=aa.getDimN()){
		    JOptionPane.showMessageDialog(this, "Invalid slice: array is "+aa.getDimN()+"-dimensional", "Array Cell Plotting Error", JOptionPane.WARNING_MESSAGE);	
		    throw new Exception("Array Cell Plotting Error: Invalid Slice");
		}
		z = new Integer(aa.getEntry(zind));
	    }
	    
	    else if(ztype.equals("TpArrayShort")||ztype.equals("TpArrayUShort")){
		AIPSArray aa=(AIPSArray)ds.getArray(zc).getArray();
		if( zind.length!=aa.getDimN()){
		    JOptionPane.showMessageDialog(this, "Invalid slice: array is "+aa.getDimN()+"-dimensional", "Array Cell Plotting Error", JOptionPane.WARNING_MESSAGE);	
		    throw new Exception("Array Cell Plotting Error: Invalid Slice");
		}
		z = new Short(aa.getEntry(zind));
	    }

	    //	    System.out.println(curr+" : "+x.floatValue()+", "+y.floatValue()+", "+ z.floatValue());
	    ret.addPoint(x.floatValue(),y.floatValue(), z.floatValue());
	    
	    //pts.add( new AIPS3DPoint(x.floatValue(),y.floatValue(),z.floatValue()));
	    
	    //System.out.println("added");
	    
	    if(curr==end)
		break;
	}     
		     

	
	ret.initData();

	System.out.println("=-=0=-0=-0=-initialized()");
	
	}
	catch(Exception exc){
	    
	    if(exc instanceof NumberFormatException ){
		JOptionPane.showMessageDialog(this, "Invalid slice: out of bounds.", "Array Cell Plotting Error", JOptionPane.WARNING_MESSAGE);	
		  
	    }
	    else{
		System.out.println(exc.getMessage());
	    }
	}
	return ret;
    }


    public void actionPerformed(ActionEvent e) {

	if(e.getSource()==m_next){
	    if(scrollable){
		LegoPlot tmp=plot;
		plot=null;
		if(tmp!=null)
		    getContentPane().remove(tmp);

	    int temp=firstrow;
	    
	    int tmpfirstrow=lastrow+1;
	    if(tmpfirstrow<=ds.getTotalRows()){
		firstrow=tmpfirstrow;
		lastrow=lastrow +lastrow-temp+1;
		System.out.println("firstrow: "+firstrow+" lastrow: "+lastrow);
		AIPSBinned2DData chart = makeScatterPlot(xvarcol, xindex, yvarcol, yindex, zvarcol,zindex, firstrow, lastrow );

		plot = new LegoPlot();
		plot.setDrawBlocks(true);
		plot.setLinesWhileAnim(true);
		plot.setSparsifyThreshold(600);
		plot.setData(chart);
		//pan = new JPanel();
		
		//pan.add(lego, BorderLayout.CENTER);	


		//pan= new ChartPanel(chart);
		this.getContentPane().add(plot,BorderLayout.CENTER );
		this.pack();
		

	    }
	    
	    }
	}

	else if(e.getSource()==m_previous){
	    if(scrollable){
		LegoPlot tmp=plot;
		plot=null;
		if(tmp!=null)
		    getContentPane().remove(tmp);

	    int temp=lastrow;
	    
	    int tmplastrow=firstrow-1;
	    if(tmplastrow>0){
		lastrow=tmplastrow;
		
		int tmpfirstrow=firstrow -temp+firstrow;
		if(tmpfirstrow<1)
		    firstrow=1;
		else
		    firstrow=tmpfirstrow;
		
		System.out.println("firstrow: "+firstrow+" lastrow: "+lastrow);
		AIPSBinned2DData chart = makeScatterPlot(xvarcol, xindex, yvarcol, yindex, zvarcol, zindex, firstrow, lastrow );
	
		plot = new LegoPlot();
		plot.setDrawBlocks(true);
		plot.setLinesWhileAnim(true);
		plot.setSparsifyThreshold(600);
		plot.setData(chart);
		//pan = new JPanel();
		
		//pan.add(lego, BorderLayout.CENTER);	


		//pan= new ChartPanel(chart);
		this.getContentPane().add(plot,BorderLayout.CENTER );


		this.pack();
		
	    }
	    }

	}

	if(e.getSource()==rows){
	    try{
		LegoPlot tmp=plot;
		plot=null;
		if(tmp!=null)
		    getContentPane().remove(tmp);
	
		lastrow=(new Integer(endfield.getText()).intValue());
		firstrow=(new Integer(startfield.getText()).intValue());
		if(lastrow>firstrow){
	    
		    setCursor(new Cursor(Cursor.WAIT_CURSOR));
		    parent.setCursor(new Cursor(Cursor.WAIT_CURSOR));
	
		    		    
		    String xco = (String)xvarbox.getSelectedItem();
		    
		    String yco =(String)var.getSelectedItem();
		    String zco =(String)var.getSelectedItem();
		    
		    String qury="SELECT "+xco;
		    
		    if(!(yco.equalsIgnoreCase(xco)))
			qury+=", " +yco;
		    if(!(zco.equalsIgnoreCase(xco)||zco.equalsIgnoreCase(yco)))
			qury+=", " +zco;
		    
		    qury+=" FROM "+tablename;
		    
		    if(whereclause!=null&&!(whereclause.trim().equalsIgnoreCase("")))
			qury+=" WHERE "+whereclause;
		    
		    ds=parent.getPlottingSet(qury, lastrow-firstrow+2);
		    System.out.println("query: "+qury);
		    System.out.println("firstrow: "+firstrow+" lastrow: "+lastrow);
		    System.out.println("xco "+xco);
		    System.out.println("yco "+yco);
		    System.out.println("zco "+zco);
		    
		    //slice parameters
		    
		    xindex=new int[1];
		    yindex=new int[1];
		    zindex=new int[1];
		    xindex[0]=-1;
		    yindex[0]=-1;
		    zindex[0]=-1;
		    try{
			if(arraycols.containsKey(xco.trim())){
			String xi = (String)xslice.getText();
			if(!xi.trim().equalsIgnoreCase("")){
			    StringTokenizer tok = new StringTokenizer(xi,": ");
			    int dim = tok.countTokens();
			    if(dim>0){
				xindex=new int[dim];
				int count=0;
				while (tok.hasMoreTokens()){
				    xindex[count]=(new Integer(tok.nextToken())).intValue();
				    count++;
				}
				
		    
				
			    }
			}
			}
			else{
			    
			    xslice.setText("");
			}
			if(arraycols.containsKey(yco.trim())){
			String yi = (String)yslice.getText();
			if(!yi.trim().equalsIgnoreCase("")){
			    StringTokenizer ytok = new StringTokenizer(yi,": ");
			    int dim = ytok.countTokens();
			    if(dim>0){
				yindex=new int[dim];
				int count=0;
				while (ytok.hasMoreTokens()){
				    yindex[count]=(new Integer(ytok.nextToken())).intValue();
				    count++;
				}
				
		    
				
			    }
			}
			}
			else{
			    
   
			    yslice.setText("");
			}
			
			if(arraycols.containsKey(zco.trim())){
			String zi = (String)zslice.getText();
			if(!zi.trim().equalsIgnoreCase("")){
			    StringTokenizer ztok = new StringTokenizer(zi,": ");
			    int dim = ztok.countTokens();
			    if(dim>0){
				zindex=new int[dim];
				int count=0;
				while (ztok.hasMoreTokens()){
				    zindex[count]=(new Integer(ztok.nextToken())).intValue();
				    count++;
				}
				
		    
				
			    }
			}
			}
			else{
			    
   
			    zslice.setText("");
			}



		    }
		    catch(NumberFormatException ecds){
			JOptionPane.showMessageDialog(this, "Invalid slice syntax.", "Plot Error", JOptionPane.WARNING_MESSAGE);	
			throw new NullPointerException();
		    }
		    System.out.println("xindex:");
		    for(int w=0;w<xindex.length;w++){
			System.out.print(xindex[w]+" ");
		    }
		    System.out.println("");

		    System.out.println("yindex:");
		    for(int w=0;w<yindex.length;w++){
			System.out.print(yindex[w]+" ");
		    }
		    System.out.println("");
		    
		    System.out.println("zindex:");
		    
		    for(int w=0;w<zindex.length;w++){
			System.out.print(zindex[w]+" ");
		    }
		    System.out.println("");


		    //end slice parameters
		    

		    xvarcol=ds.findColumn(xco);
		    yvarcol=ds.findColumn(yco);
		    zvarcol=ds.findColumn(zco);
		    AIPSBinned2DData chart = makeScatterPlot(xvarcol, xindex, yvarcol, yindex, zvarcol, zindex,firstrow, lastrow );

		    plot = new LegoPlot();
		   
		    
		  
		    plot.setDrawBlocks(true);
		    plot.setLinesWhileAnim(true);
		    plot.setSparsifyThreshold(600);
		    plot.setData(chart);
		    
		    this.getContentPane().add(plot,BorderLayout.CENTER );
		    
		    

 
		    this.pack();
		    scrollable=true;
		    System.out.println("done");
		    

		    setCursor(new Cursor(Cursor.DEFAULT_CURSOR));
		    parent.setCursor(new Cursor(Cursor.DEFAULT_CURSOR));
	
		}

		else{
		    JOptionPane.showMessageDialog(this, "Invalid row numbers.", "Plot Error", JOptionPane.WARNING_MESSAGE);	
		    
		}


	    }
	    
	    catch(Exception ex){
		if((ex instanceof NumberFormatException))
		    JOptionPane.showMessageDialog(this, "Invalid row numbers.", "Plot Error", JOptionPane.WARNING_MESSAGE);	
		

		else if((ex instanceof NullPointerException)){
		    System.out.println("Plot Error");
		    ex.printStackTrace();
		}
		else{
		    ex.printStackTrace();
		    
		}
	    }
	    
	}


    }
               
    public void itemStateChanged(ItemEvent e){


	
	
    }

 

    
}
