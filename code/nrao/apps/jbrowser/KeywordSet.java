import java.util.*;
import java.lang.*;

/** Models a set of Table or Column Keywords for an AIPS++ table.
 * 
 * @author Jason Ye
 */

public class KeywordSet{
    private Vector m_types;
    private Vector m_names;
    private Vector m_val;

    /** Constructor.
     */

    public KeywordSet(){
	
	m_types = new Vector();
	m_names = new Vector();
	m_val = new Vector();
    }

    /** Get the size of the KeywordSet.
     */

    public int numKeywords(){
	return m_types.size();

    }

    /** Insert the next keyword's type as a string.
     */

    public void insertType(String s){
	m_types.add(s);
    }

    /** Insert the next keyword's name as a string.
     */

    public void insertName(String s){
	m_names.add(s);
    }


    /** Insert the value of the next keyword as a string.
     */

    public void insertVal(String s){
	m_val.add(s);

    }
    
    //indices start at 0

    /** Get the type of the keyword at index i. The first i is 0.
     */

    public String getType(int i){
	return (String)m_types.elementAt(i);
    }

     /** Get the name of the keyword at index i. The first i is 0.
     */


    public String getName(int i){
	return (String)m_names.elementAt(i);
    }


     /** Get the value of the keyword at index i. The first i is 0.
     */

    public String getVal(int i){
	return (String)m_val.elementAt(i);
    }

}
