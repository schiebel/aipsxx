import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.lang.*;
import org.freehep.j3d.plot.*;

public class SurfacePlotter extends JInternalFrame implements ActionListener{

    
    private JButton rows=null;
    private JTextField startfield, endfield;
    private SurfacePlot plot;
    private SurfaceData data;
  
    public SurfacePlotter(ArrayBrowser ab){
	super("Surface Plotter", true, true, true, true);
	try{



	JToolBar toolBar = new JToolBar();
	toolBar.setVisible(true);
        toolBar.setFloatable(false);
	this.getContentPane().add(toolBar, BorderLayout.SOUTH);
 
	toolBar.add(new Label("Slice:"));
        
	startfield= new JTextField();
	toolBar.add(startfield);
	
	toolBar.add(new Label(":"));
	
	endfield= new JTextField();
	toolBar.add(endfield);
	
	rows = new JButton("PLOT");
	rows.addActionListener(this);
	toolBar.add(rows);


	toolBar.addSeparator();
	
	data=new SurfaceData(ab);
	
	int[] a;
	a= new int[3];
	int[] b;
	b=new int[3];
       	this.plotSlice(a, b);
        
	
	

	
	

	this.pack();
	this.setVisible(true);
	}
	catch(Exception ex){
	    ex.printStackTrace();
	}
	
    }

    public void plotSlice(int[] start, int[]end){
	this.getContentPane().remove(plot);
	plot= new SurfacePlot();
	data.setSlice(start, end);
	plot.setData(data);
	this.getContentPane().add(plot, BorderLayout.CENTER);
		
	this.getContentPane().repaint();	

    }

     public void actionPerformed(ActionEvent e) {


    }
   

    
}
