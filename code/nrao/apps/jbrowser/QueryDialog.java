import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;
import java.io.*;

/** This class models a TaQL query dialog that is used to open
 *  tables for the Table Browser. <p>
 * @author Jason Ye
 */


public class QueryDialog extends JDialog implements ActionListener{

    private JPanel panel;
    private JTextField select, table, where, orderby, giving, rowperpage;
    private JButton from, ok, cancel, clear, lastquery;
    private TableBrowser browser;
    private JCheckBox newwindow;
    
    /** The constructor displays the visual components of the dialog,
     *  then awaits user input.
     */
   
    public QueryDialog(TableBrowser b){

	super(b,"Query Table");

	// show visual components
	
	browser = b;

	panel = new JPanel();
	
	GridBagLayout gridbag =  new GridBagLayout();
	panel.setLayout(gridbag);
	
	GridBagConstraints c = new GridBagConstraints();
	
	c.fill = GridBagConstraints.NONE; 
	c.weightx = 0.3;

	JLabel slab = new JLabel("SELECT");
	c.gridx = 0;
	c.gridy = 0;
	
	gridbag.setConstraints(slab  , c);

	
	
	panel.add(slab);

	
	select = new JTextField();
	select.setPreferredSize(new Dimension(350, (int)select.getPreferredSize().getHeight()));
	c.gridx = 1;
	c.weightx = 0.7;
	c.gridy = 0;
	
	gridbag.setConstraints(select, c);
	panel.add(select);
	
	from = new JButton("FROM");
	from.setToolTipText("Click to browse");
	
	from.addActionListener(this);
	c.weightx = 0.3;
	c.gridx = 0;
	c.gridy = 1;
	gridbag.setConstraints(from, c);

	panel.add(from);
	
	
	table =  new JTextField();
	table.setPreferredSize(new Dimension(350, (int)table.getPreferredSize().getHeight()));
	BrowserChild ch = browser.getCurrent();
	if(ch!=null)
	    table.setText(ch.getTitle());

	
	c.gridx = 1;
	c.gridy = 1;
	c.weightx = 0.7;

	gridbag.setConstraints(table, c);
	
	panel.add(table);
	
	JLabel wlab = new JLabel("WHERE");
	c.weightx = 0.3;
	c.gridx = 0;
	c.gridy = 2;
	gridbag.setConstraints(wlab, c);


	panel.add(wlab);
	
	where = new JTextField();
	where.setPreferredSize(new Dimension(350, (int)where.getPreferredSize().getHeight()));
	c.gridx = 1;
	c.weightx = 0.7;
	c.gridy = 2;
	gridbag.setConstraints(where, c);
	
	
	panel.add(where);
	
	JLabel olab = new JLabel("ORDERBY");
	c.weightx = 0.3;
	c.gridx = 0;
	c.gridy = 3;
	gridbag.setConstraints(olab, c);


	
	
	panel.add(olab);
	
	orderby = new JTextField();
	orderby.setPreferredSize(new Dimension(350, (int)orderby.getPreferredSize().getHeight()));
	c.gridx = 1;
	c.weightx = 0.7;
	c.gridy = 3;
	gridbag.setConstraints(orderby, c);


	panel.add(orderby);

	JLabel glab = new JLabel("GIVING");
	c.weightx = 0.3;
	c.gridx = 0;
	
	c.gridy = 4;
	gridbag.setConstraints(glab, c);

	
	panel.add(glab);
	

	giving = new JTextField();
	giving.setPreferredSize(new Dimension(350, (int)giving.getPreferredSize().getHeight()));
	c.gridx = 1;
	c.weightx = 0.7;
	c.gridy = 4;
	gridbag.setConstraints(giving, c);



	panel.add(giving);
	

	newwindow = new JCheckBox("New Window");
	c.gridx = 1;
	c.gridy = 5;
	gridbag.setConstraints(newwindow, c);
	panel.add(newwindow);
	    
	JLabel numlab = new JLabel("Rows/Page:");
	c.weightx = 0.3;
	c.gridx = 0;
	c.gridy = 6;
	gridbag.setConstraints(numlab, c);
	panel.add(numlab);

	rowperpage = new JTextField("1000");
	rowperpage.setPreferredSize(new Dimension(300, (int)rowperpage.getPreferredSize().getHeight()));
	c.gridx = 1;
	c.gridy = 6;
	gridbag.setConstraints(rowperpage, c);
	panel.add(rowperpage);

	JToolBar tb = new JToolBar();
	tb.addSeparator();
	getContentPane().add(tb, BorderLayout.SOUTH);
 	cancel = new JButton("Cancel");
// 	c.gridx = 0;
// 	c.gridy = 7;
// 	c.insets = new Insets(20,30,0,0);  
// 	gridbag.setConstraints(cancel, c);
 	cancel.addActionListener(this);
	tb.add(cancel);
	// 	panel.add(cancel);
	tb.addSeparator();
 	clear = new JButton("Clear");
// 	c.gridx = 1;
// 	c.gridy = 7;
// 	c.insets = new Insets(20,0,0,0);  
// 	gridbag.setConstraints(clear, c);
	clear.addActionListener(this);
// 	panel.add(clear);
	tb.add(clear);
	tb.addSeparator();
 	lastquery = new JButton("Last Query");
// 	c.gridx = 2;
// 	c.gridy = 7;
// 	c.insets = new Insets(20,30,0,0);  
// 	gridbag.setConstraints(lastquery, c);
 	lastquery.addActionListener(this);
// 	panel.add(clear);
	tb.add(lastquery);
	
	tb.addSeparator();
	ok = new JButton("Open");
// 	c.gridx = 3;
// 	c.gridy = 7;
// 	c.weightx=.5;
// 	c.anchor = GridBagConstraints.SOUTH; 
//         c.insets = new Insets(20,0,0,0);  
// 	gridbag.setConstraints(ok, c);
	
	
	ok.addActionListener(this);
	tb.add(ok);
	//	panel.add(ok);
	

	
	this.getContentPane().add(panel, BorderLayout.CENTER);
	
	
	
	this.setSize(475,275);
	this.setResizable(false);
	this.setVisible(true);
	
	
	
    }
    
    /** Responds to user input. If a valid query is entered, it will
     *  direct the TableBrowser to submit this query to the database. 
     */
    


    public void actionPerformed(ActionEvent e){
	if(e.getSource()==cancel){
	    this.dispose();

	}

	else if(e.getSource()==from){
	   
	    // open a file dialog to browse for a table name
	    
	    JFileChooser chooser = new JFileChooser(table.getText().trim());
	    chooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
	    int res= chooser.showOpenDialog(this);
	    if(res==JFileChooser.APPROVE_OPTION){
		File f = chooser.getSelectedFile();
		String tablename = f.getAbsolutePath();
		//	System.out.println("chooser got file: "+tablename);
		table.setText(tablename);
		
	    }
	}

	else if(e.getSource()==clear){
	    select.setText("");
	    table.setText("");
	    where.setText("");
	    orderby.setText("");
	    giving.setText("");
	   
  

	}

	else if(e.getSource()==lastquery){
	    String s = browser.getLastQuery();
	    
	    String sub="";
	    int index=-1;
	    
	    index = s.indexOf("GIVING");
	    if(index!=-1){
		sub = s.substring(index);
		s=s.replaceFirst(sub, "");
		sub= (sub.replaceFirst("GIVING", "")).trim();
		giving.setText(sub);
	
	    }

	    index = s.indexOf("ORDERBY");
	    if(index!=-1){
		sub = s.substring(index);
		s=s.replaceFirst(sub, "");
		sub= (sub.replaceFirst("ORDERBY", "")).trim();
		orderby.setText(sub);
	
	    }
	    index = s.indexOf("WHERE");
	    if(index!=-1){
		sub = s.substring(index);
		s=s.replaceFirst(sub, "");
		sub= (sub.replaceFirst("WHERE", "")).trim();
		where.setText(sub);
	
	    }
	    index = s.indexOf("FROM");
	    if(index!=-1){
		sub = s.substring(index);
		s=s.replaceFirst(sub, "");
		sub= (sub.replaceFirst("FROM", "")).trim();
		table.setText(sub);
	
	    }
	    
	    index = s.indexOf("SELECT");
	    if(index!=-1){
		sub = s.substring(index);
		s=s.replaceFirst(sub, "");
		sub= (sub.replaceFirst("SELECT", "")).trim();
		select.setText(sub);
	
	    }
	    
	    
	    
	}

	else if(e.getSource()==ok){
	    
	    boolean err=false;
	    String query="";
	    Vector ret = new Vector();
	    
	    // parse query to find validity

	    if(!table.getText().trim().equalsIgnoreCase("")){
		query+="SELECT "+select.getText().trim();
		query+=" FROM "+table.getText().trim();
		if(!where.getText().trim().equalsIgnoreCase("")){
		    query+= " WHERE "+ where.getText().trim(); 
		}
		
		if(!orderby.getText().trim().equalsIgnoreCase("")){
		    query+=" ORDERBY "+orderby.getText().trim();
		}
		if(!giving.getText().trim().equalsIgnoreCase("")){
		    query+=" GIVING "+giving.getText().trim();
		}
	    
		boolean nw =false;
		if(newwindow.isSelected()){
		    nw=true;
		}
		if(!rowperpage.getText().trim().equalsIgnoreCase("")){
		    Integer rp=new Integer(0);
		    if(!rowperpage.getText().trim().equalsIgnoreCase("ALL")){
			
		    

		    try{
			
			rp = new Integer(rowperpage.getText().trim());
			if(rp.intValue()<1){
			    JOptionPane.showMessageDialog(browser, "Enter a valid number of rows to show per page.", "Query Error", JOptionPane.WARNING_MESSAGE);	
			    err=true;
			    
			}
		    }
		    catch(NumberFormatException ex){
			JOptionPane.showMessageDialog(browser, "Enter a valid number of rows to show per page.", "Query Error", JOptionPane.WARNING_MESSAGE);	
			err=true;
		    }
		    }
		    if(!err){
			
			// no error, TableBrowser should submit query
			
			this.setCursor(new Cursor(Cursor.WAIT_CURSOR));
			browser.setCursor(new Cursor(Cursor.WAIT_CURSOR));
			ret.add(query);
			ret.add(new Boolean(nw));
			ret.add(rp);
			browser.delegateQuery(ret);
			this.setCursor(new Cursor(Cursor.DEFAULT_CURSOR));
			browser.setCursor(new Cursor(Cursor.DEFAULT_CURSOR));
		
			this.dispose();
		    }
		}
	    
		
		else{
		    JOptionPane.showMessageDialog(browser, "Enter a valid number of rows to show per page.", "Query Error", JOptionPane.WARNING_MESSAGE);	
		    
		}
		
	    }

	    else{

		JOptionPane.showMessageDialog(browser, "Enter a valid query.", "Query Error", JOptionPane.WARNING_MESSAGE);	

	    }
	}
	
    }

    /** This static method calls the constructor. The constructor
     *  in turn, gets the TaQL query and tells the TableBrowser to
     *  submit the query.
     */
    
   

    public static void getQuery(TableBrowser b){
	QueryDialog qd = new QueryDialog(b);

	
    }


}
