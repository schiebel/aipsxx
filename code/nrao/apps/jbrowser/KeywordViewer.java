import java.awt.event.*;
import java.awt.*;
import java.util.Vector;

import javax.swing.JTable;
import javax.swing.JScrollPane;
import javax.swing.JPanel;
import javax.swing.JFrame;
import javax.swing.table.*;
import java.lang.*;
import javax.swing.*;
import java.sql.*;



import javax.swing.ListSelectionModel;
import javax.swing.event.ListSelectionListener;
import javax.swing.event.ListSelectionEvent;

/** This provides a viewer for Table and Column Keywords.
 *
 * @author Jason Ye
 */



public class KeywordViewer extends JInternalFrame implements ActionListener {
  
  
  
    private JScrollPane scrollPane;
    private JTable table;
    private KeywordSet keys;
    private int currentrow;
    private JMenuBar m_menuBar;
    private JMenu m_viewmenu;
    private JMenuItem m_details;
    private TableBrowser m_browser;
   
    /** Construct a KeywordViewer with a reference to the parent TableBrowser
     * browser.
     */

    public KeywordViewer(TableBrowser browser) {
        super("", 
              true, //resizable
              true, //closable
              true, //maximizable
              true);//iconifiable

	m_browser =browser;
	m_menuBar = new JMenuBar();
	this.setJMenuBar(m_menuBar);
	m_viewmenu= new JMenu("View [Z]");
	m_menuBar.add(m_viewmenu);
	m_viewmenu.setMnemonic(KeyEvent.VK_Z);
	m_details =  new JMenuItem("Details [B]", KeyEvent.VK_B);
	m_viewmenu.add(m_details);
	
	m_details.addActionListener(this);
	
	toFront();
	
	
	setVisible(true);


	currentrow=-1;
    


	
    }

    
    /** Maps the button action to the correct methods.
     */

    public void actionPerformed(ActionEvent e){
	JMenuItem source = (JMenuItem)(e.getSource());
	
	if(source==m_details){

	    if(currentrow!=-1){
		if(keys.getType(currentrow).equals("TpTable")){
		    // System.out.println("opening table: "+ keys.getVal(currentrow));
		    m_browser.query(true ,"SELECT FROM "+keys.getVal(currentrow),0,1000);
		}
		
		if(keys.getType(currentrow).startsWith("TpArray")){
		    // System.out.println("showing keyword as array: "+keys.getVal(currentrow));
		    ArrayBrowser arrbrowser = new ArrayBrowser(keys.getVal(currentrow), keys.getType(currentrow));
		    arrbrowser.display(m_browser);
		    m_browser.getDeskTop().add(arrbrowser);
		    try{
			arrbrowser.setSelected(true);
		    } catch(Exception ex){
		       	ex.printStackTrace();
		    }
		}
	    }

	}
    }

    /** Display the keywords in the KeywordSet ks.
     */

    public void display(KeywordSet ks ){
	keys=ks;
	Object[][] data= new Object[ks.numKeywords()][2];
	Object[] columns={"Name", "Value" };
	for(int i= 0; i<ks.numKeywords();i++){
	    data[i][0] = ks.getName(i);
	    if(ks.getType(i).startsWith("TpArray")){
		data[i][1] = "ARRAY";
		
	    }

	    else{
		data[i][1] = ks.getVal(i);
	    }

	}
	
	table = new JTable(data, columns){
		public boolean isCellEditable(int row, int col){
		    return false;
		}

	    };


	table.setPreferredScrollableViewportSize(new Dimension(300, 200));
	setSize(new Dimension(300, 200));
	scrollPane = new JScrollPane(table);

	
	getContentPane().add(scrollPane, BorderLayout.CENTER);

	table.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
	table.doLayout();

	ListSelectionModel rowSM = table.getSelectionModel();


	
	rowSM.addListSelectionListener(new ListSelectionListener() {
                public void valueChanged(ListSelectionEvent e) {
                    //Ignore extra messages.
		    if(e!=null){
			if (e.getValueIsAdjusting()) return;
		    
			ListSelectionModel lsm = (ListSelectionModel)e.getSource();

			
			if (lsm.isSelectionEmpty()) {
			    
			    currentrow=-1;
			}
			else {
			    currentrow = lsm.getMinSelectionIndex();
			  
			    
			}
		    }
		}
            });



	table.setAutoResizeMode(JTable.AUTO_RESIZE_OFF);








	TableColumnModel tcm = table.getColumnModel();
	int numberofcolumns=table.getColumnCount();
	int colsmax=65;
	FontMetrics fm = table.getFontMetrics(table.getFont());
	JTableHeader hed = table.getTableHeader();
	
	
	
	for(int counter=0;counter<numberofcolumns;counter++){
	    TableColumn colmod = tcm.getColumn(counter);
	    String headertext = (String)colmod.getHeaderValue();
	    int nextwidth = fm.stringWidth(headertext);
	    
	    if(nextwidth>colsmax)
		colsmax=nextwidth;
	    for(int roco=0;roco<table.getRowCount();roco++){

		if(fm.stringWidth((String)table.getValueAt(roco,counter))>colsmax)
		    colsmax= fm.stringWidth((String)table.getValueAt(roco,counter));
	    }
	    

	    
	    colmod.setPreferredWidth(colsmax+20);
	    
	}

	






    }

    


}
