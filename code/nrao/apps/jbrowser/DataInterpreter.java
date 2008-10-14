

import java.sql.*;
import java.util.*;

/** DataInterpreter is a parser for the VO Table style XML output
 * from ATABD.
 */


public class DataInterpreter{
  
  
    private StringTokenizer tokenizer;
    private int counter=1;
    private DataSet ds;
    private DataSetMetaData md;
    private KeywordSet ks;
    private boolean fullinfo;
    /** Constructor.
     */

    public DataInterpreter(){
	ds=null;
	md=null;
	ks=null;
	fullinfo=false;
    }

    public void setFullInfo(boolean b){
	fullinfo=b;
    }

    /** Parse the given XML String into the DataSet dset and returns it
     * as a ResultSet. If DataSet is null, creates a new DataSet.
     * @param query XML string to parse
     * @param dset DataSet to parse into
     * @return ResultSet containing table described in query
    */
    
    public ResultSet parseResult(String query, DataSet dset){
	
	if(dset==null)
	    ds = new DataSet();
	else{

	  
	    ds=dset;
	}
	ds.setFullInfo(fullinfo);
	try{
	    ks = ((DataSetMetaData)ds.getMetaData()).getTableKW();
	}
	catch(SQLException ecs){
	    ks=null;
	}
	if(query.startsWith("AipsError")){
	    query = query.replaceAll("thats.all.folks", "");
	    try{
		((DataSetMetaData)ds.getMetaData()).setErrorMessage(query);
	    }
	    catch(SQLException e){
		System.err.println("Error message: "+query);
		System.err.println("Confused by earlier errors, exitting...");
		System.exit(1);
	    }
	}
	
	else{
	    try{
		md = (DataSetMetaData)ds.getMetaData();
	    }
	    catch(SQLException e){
		System.err.println("Error message: "+query);
		System.err.println("Confused by earlier errors, exitting...");
		System.exit(1);
	    }

	    tokenizer= new StringTokenizer(query, "<>", true);

	    
	    if(dset==null)
		this.parseMetaData();

	    while(tokenizer.hasMoreTokens()){
		if(eat("<")){
		    if(eat("TR")){
			if(eat(">")){
			    this.parseRow();
			}
			
			else
			    err(2);
		    }
		    
		    
		}
		
		else{
		  
		}
		
		
	   
	    }
	    
	    
	   
	    if(dset!=null){
		
		dset.setDataVector(ds.getDataVector());
	    }
	  
	}try{
	
	}

	catch(Exception e){
	    System.out.println("exit parse with error");
	}
	
	return ds;
    }

    /** Print an error and a number a.
     */

    public void err(int a){

	System.out.println("parse error at: " +a);
    }


    /** Compare the next token to s. If it matches return true, otherwise
     * return false. Do not call explicitly.
     *@param s the string to compare to 
     *@return true if matches, false if not
     *
     */

    public boolean eat(String s){
	boolean ret=true;
	String token =(tokenizer.nextToken()).trim();

	if(0==token.length()){
	    ret=false;
	    if(tokenizer.hasMoreTokens()){
		token =(tokenizer.nextToken()).trim();
	
		ret = true;
	    }
	}
	
	counter++;
	if(!token.equalsIgnoreCase(s))
	    ret=false;
	return ret;
    }

    /** Parse the next row of data. Do not call explicitly.
     */

    public void parseRow(){

	ds.addRow();
	ds.next();
	int colcount=1;
	while(tokenizer.hasMoreTokens()){
	    
	    if(eat("<")){
		String tag = (tokenizer.nextToken()).trim();
		if(tag.equalsIgnoreCase("TD")){
		    if(eat(">")){
			// jan 2004
			try{
			    String coltp=  md.getColumnTypeName(colcount);
			    
			if(fullinfo&&coltp.startsWith("TpArray")){
			    // System.out.println(coltp);
			    String arrayinfo=(tokenizer.nextToken()).trim();
			    //System.out.println(arrayinfo);
			    AIPSArray arr = new AIPSArray(arrayinfo, coltp);
			    TableArray a = new TableArray();
			    a.setArray(arr);
			    a.setBaseTypeName(coltp);
			    ds.insertIntoRow(a);
			    //insertarray
			    
			    
			}
			else{
			
			    ds.insertIntoRow((tokenizer.nextToken()).trim());
			}
			colcount++;
			//end jan 2004
			if(!eat("<"))
			    err(4);
			if(!eat("/TD"))
			    err(5);
			if(!eat(">"))
			    err(6);
			}
			catch(Exception ex){
			    ex.printStackTrace();
			}

		    }
		}
		
		else if(tag.equalsIgnoreCase("/TR")){
		   
		    if(!eat(">")){
			err(7);
		    }
		    break;
		    
		}
		
	    }
	    else{
		err(3);
	
		
	    }
	}

    }
    
    /** Parse the meta data associated with the table. Do not calll
     * explicitly.
     */

    public void parseMetaData(){

	String temp="";
	try{
	    temp=tokenizer.nextToken();
	}

	catch(Exception ecs){

	    System.err.println("Fatal Database Error. Shutting Down...");
	    System.exit(1);
	}
	String field;
	String keyword;
	String ins;
	String colkw;
	
	while(!temp.trim().equalsIgnoreCase("DATA")){
	  
	    if(temp.endsWith("/")){
	
		field=temp.substring(0,5);
		keyword = temp.substring(0,7);
		ins=temp.substring(0,6);
		colkw = temp.substring(0,8);
		//	System.out.println("colkw: "+colkw);
		
	
		if(field.trim().equalsIgnoreCase("TABLE")){
		    //  System.out.println("table detected");
		    StringTokenizer fieldtokens = new StringTokenizer(temp,"\"= ", false );
		    while(fieldtokens.hasMoreTokens()){
			String tk=fieldtokens.nextToken();
			tk.trim();
			if(tk.equalsIgnoreCase("name")){
			    String tname = fieldtokens.nextToken();
			    
			    // System.out.println("Table Name is: "+tname);
			    try{
			    ((DataSetMetaData)ds.getMetaData()).setTableName(tname);
			    }

			    catch(SQLException e){
				e.printStackTrace();
				System.err.println("Confused by earlier errors, exitting...");
				System.exit(1);
			    }

			}
			
		    }
		}

		else if(field.trim().equalsIgnoreCase("TOTAL")){
		    // System.out.println("total detected");
		    StringTokenizer fieldtokens = new StringTokenizer(temp,"\"= ", false );
		    while(fieldtokens.hasMoreTokens()){
			String tk=fieldtokens.nextToken();
			tk.trim();
			if(tk.equalsIgnoreCase("row")){
			    String tnum = fieldtokens.nextToken().trim();
			    int nnum=0;
			    try{
				nnum = (new Integer(tnum)).intValue();
				}

			    catch(NumberFormatException exc){
				System.err.println("WARNING: INVALID TOTAL NUMBER OF ROWS");
				    }
			    //    System.out.println("Total is: "+nnum);
			    ds.setTotalRows(nnum);
			    
			}

		    }

		    
		}

		else if(field.trim().equalsIgnoreCase("FIELD")){
		    //System.out.println("pmd 3");
		    //System.out.println("field token: "+temp);
		    StringTokenizer fieldtokens = new StringTokenizer(temp,"\"= ", false );
		    while(fieldtokens.hasMoreTokens()){
			//	System.out.println("pmd 4");
			String tk=fieldtokens.nextToken();
			tk.trim();
			//	System.out.println("tk :" +tk);
			if(tk.equalsIgnoreCase("name")){
			    String a=fieldtokens.nextToken().trim();
			    //   System.out.println("NAME OF COL: " + a);
			    try{
				md.insertColumnName(a);
			    } catch(Exception e){e.printStackTrace();}
			}
			else if(tk.equalsIgnoreCase("datatype")){
			    String a=fieldtokens.nextToken().trim();
			    // System.out.println("Type of column: "+a); 
			    try{
				md.insertColumnTypeName(a);
			    } catch(Exception e){e.printStackTrace();}
			}
		    }

		}

		else if(keyword.trim().equalsIgnoreCase("KEYWORD")){

		    StringTokenizer fieldtokens = new StringTokenizer(temp,"\"= ", false );
		    while(fieldtokens.hasMoreTokens()){
			//	System.out.println("pmd 4");
			String tk=fieldtokens.nextToken();
			tk.trim();
			//	System.out.println("tk :" +tk);
			if(tk.equalsIgnoreCase("type")){
			    String a=fieldtokens.nextToken().trim();
			    //   System.out.println("Keyword Type: " + a);
			    ks.insertType(a);
			    
			}
			else if(tk.equalsIgnoreCase("name")){
			    String a=fieldtokens.nextToken().trim();
			    // System.out.println("Keyword name: "+a); 
			    ks.insertName(a);

			}
			else if(tk.equalsIgnoreCase("val")){
			    String a=fieldtokens.nextToken("\"=").trim();
			    while(a.equalsIgnoreCase("")){
				if(fieldtokens.hasMoreTokens())
				    a=fieldtokens.nextToken("\"=").trim();
			    }
			    //   System.out.println("Keyword val: "+a); 
			    ks.insertVal(a);

			}
			
		    }

		}

		else if(colkw.trim().equalsIgnoreCase("COLUMNKW")){

		   
		    StringTokenizer fieldtokens = new StringTokenizer(temp,"\"= ", false );
		    KeywordSet colkwset= new KeywordSet();
		    int colnum=-1;
		    while(fieldtokens.hasMoreTokens()){
		       
			String tk=fieldtokens.nextToken();
			tk.trim();
			//	System.out.println("tk :" +tk);
			if(tk.equalsIgnoreCase("col")){
			    String a=fieldtokens.nextToken().trim();
			    colnum = (new Integer(a)).intValue();
			    
			    // System.out.println("Keywd col num: " + colnum);
			    
			}
			
		
			else if(tk.equalsIgnoreCase("type")){
			    String a=fieldtokens.nextToken().trim();
			    //   System.out.println("Keyword Type: " + a);
			    colkwset.insertType(a);
			    
			}
			else if(tk.equalsIgnoreCase("name")){
			    String a=fieldtokens.nextToken().trim();
			    // System.out.println("Keyword name: "+a); 
			    colkwset.insertName(a);

			}
			else if(tk.equalsIgnoreCase("val")){
			    String a=fieldtokens.nextToken("\"=").trim();
			    while(a.equalsIgnoreCase("")){
				if(fieldtokens.hasMoreTokens())
				    a=fieldtokens.nextToken("\"=").trim();
			    }
			    // System.out.println("Col Keyword val: "+a); 
			    colkwset.insertVal(a);

			}
			
		    }
		    
		    ds.insertColKW(colkwset, colnum);
		   
   
		}



		else if(ins.trim().equalsIgnoreCase("RWINFO")){
		    StringTokenizer fieldtokens = new StringTokenizer(temp,"\"= ", false );
		   while(fieldtokens.hasMoreTokens()){
			
			String tk=fieldtokens.nextToken();
			tk.trim();
			//	System.out.println("tk :" +tk);
			if(tk.equalsIgnoreCase("insertRow")){
			    String a=fieldtokens.nextToken().trim();
			    //   System.out.println("Keyword Type: " + a);
			    try{
			    ((DataSetMetaData)ds.getMetaData()).setInsRow((Boolean.valueOf(a)).booleanValue());
			    }

			    catch(SQLException e){
				System.err.println("ResultSet lost its meta data");
				System.err.println("Confused by earlier errors, exitting...");
				System.exit(1);
	    }
			    
			}
			else if(tk.equalsIgnoreCase("removeRow")){
			    String a=fieldtokens.nextToken().trim();
			    // System.out.println("Keyword name: "+a); 
			    try{
			    ((DataSetMetaData)ds.getMetaData()).setDelRow((Boolean.valueOf(a)).booleanValue());
			    }

			     catch(SQLException e){
				System.err.println("ResultSet lost its meta data");
				System.err.println("Confused by earlier errors, exitting...");
				System.exit(1);
	    }

			}
		
			
		   } 
		 
		   
   
		}

	    }
	    temp=tokenizer.nextToken();
	}
	
	
    }


}


