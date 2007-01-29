import java.util.*;
import javax.swing.*;
import javax.swing.table.*;

/** Models a delete row action.
 *<p>
 *@author Jason Ye
 */

public class DelRowAction extends TableAction{

    private int m_row;
    private Vector m_rowElements;
    private BrowserTable m_table;

    public DelRowAction(int row, Vector rowElements, BrowserTable table){


	m_row =row;
	m_rowElements =rowElements;
	m_table = table;

    }


    public void undo(){
	//	System.out.println("undoing remove row at:" + m_row);
	m_table.insertRows(m_row, m_rowElements, false);
    }
    
    public void redo(){
	//	System.out.println("redoing remove row at:" + m_row);
	m_table.deleteRows (m_row);
	
    }

    public String toUpdateString(){
	String ret="";
	ret+="<DELROW "+m_row+ " >\n";
	return ret;

    }










}
