import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import java.util.*;

public class ShowColumnDialog extends JDialog implements ActionListener{
    
    private Vector v;
    private JButton show, cancel;
    private BrowserChild m_browser;
    public ShowColumnDialog(BrowserChild browser, Hashtable colToShow) {
	m_browser= browser;
	JPanel innerpanel = new JPanel();
	JPanel buttonpanel = new JPanel();
	JScrollPane spane = new JScrollPane(innerpanel);
	innerpanel.setLayout(new GridLayout(0,1));
	buttonpanel.setLayout(new GridLayout(1,0));
	v = new Vector();
	for(int i=1; i<colToShow.size();i++){
	    if(-1==((Integer)colToShow.get(new Integer(i))).intValue()){
		JCheckBox cb = new JCheckBox((String)browser.getColNames(i-1));
		cb.setToolTipText(String.valueOf(i));
		innerpanel.add(cb);
		v.add(cb);
	    }
	    
	}
	setTitle("Show Columns");
	cancel = new JButton("CANCEL");
	cancel.addActionListener(this);
	show = new JButton ("SHOW");
	show.addActionListener(this);
	buttonpanel.add(cancel);
	buttonpanel.add(show);
	getContentPane().setLayout(new BorderLayout());
	getContentPane().add(spane, BorderLayout.CENTER);
	getContentPane().add(buttonpanel, BorderLayout.SOUTH);
	setSize(200, 300);
	setResizable(false);
	setVisible(true);

    }

    public void actionPerformed(ActionEvent e){
	Object source = (e.getSource());
	if(source==show){
	    
	    for(int i=0;i<v.size();i++){
		JCheckBox cb = (JCheckBox)v.elementAt(i);
		if(cb.isSelected()){
		    try{
			int in = (new Integer(cb.getToolTipText())).intValue();
			m_browser.setColumnVisible(in);
		    }

		    catch(Exception f){
			System.err.println("unable to show column: "+cb.getText());
		    }
		}
	 
	    }
	    m_browser.refreshDisplay();
	    dispose();
	}

	else if(source == cancel){

	    this.dispose();
	}
	    

    }

}
