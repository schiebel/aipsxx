import java.util.*;
import javax.swing.*;

/** Models an insert row action for the AIPS++ tables.
 *  @author Jason Ye
 */

public class InsRowAction extends TableAction{

    private int m_row;
    private BrowserTable m_table;

    public InsRowAction(int row, BrowserTable table){


	m_row =row;
	m_table = table;

    }


    public void undo(){
	m_table.deleteRows(m_row);
	
    }
    
    public void redo(){
	
	m_table.insertRows(m_row, null, false);
    }

    public String toUpdateString(){
	String ret="";
	ret+="<ADDROW>\n";
	return ret;
    }
}
