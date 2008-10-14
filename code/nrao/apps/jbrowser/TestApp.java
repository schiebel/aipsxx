import java.lang.*;
import java.sql.*;

public class TestApp{


    public TestApp(){
	try{
	    
	    Class.forName("TableDriver");
	    //TableDriver driver = new TableDriver();
	    Connection con = DriverManager.getConnection("bernoulli:7007", "jason", "doesn't matter");
	    
	    String query = "SELECT FROM /users/jye/LE";
	    
	    Statement stmt = con.createStatement();
	    
	    ResultSet rs = stmt.executeQuery(query);
	    
	  
	    rs.beforeFirst();
	    System.out.println("true: " + rs.isBeforeFirst());
	    System.out.println("false: " + rs.isAfterLast());
	    System.out.println("false: " + rs.isFirst());
	    System.out.println("false: " + rs.isLast());
	    String res="";
	    while(rs.next()){
		res="|/|   ";
		for (int j=0;j<((ResultSetMetaData)rs.getMetaData()).getColumnCount();j++){
		    
		    res+= rs.getString(j+1) +"   |/|   "; 
		    
		}
		System.out.println(res);
		
		
	    }
	   
	    System.out.println("==============aftlast===================================");
	    

	    rs.afterLast();
	    System.out.println("false: " + rs.isBeforeFirst());
	    System.out.println("true: " + rs.isAfterLast());
	    System.out.println("false: " + rs.isFirst());
	    System.out.println("false: " + rs.isLast());

	    
	    while(rs.previous()){
		res="|/|   ";
		for (int j=0;j<((ResultSetMetaData)rs.getMetaData()).getColumnCount();j++){
		    
		    res+= rs.getString(j+1) +"   |/|   "; 
		    
		}
		System.out.println(res);
		
		
	    }

	    System.out.println("=======last=========================================");
	    rs.last();
	    System.out.println("false: " + rs.isBeforeFirst());
	    System.out.println("false: " + rs.isAfterLast());
	    System.out.println("false: " + rs.isFirst());
	    System.out.println("true: " + rs.isLast());
	    res="";
	    for (int j=0;j<((ResultSetMetaData)rs.getMetaData()).getColumnCount();j++){
		
		res+= rs.getString(j+1) +"   |/|   "; 
		
	    }
	    System.out.println(res);


	    System.out.println("===========first======================================");
	    rs.first();
	    System.out.println("false: " + rs.isBeforeFirst());
	    System.out.println("false: " + rs.isAfterLast());
	    System.out.println("true: " + rs.isFirst());
	    System.out.println("false: " + rs.isLast());
	    res="";
	    for (int j=0;j<((ResultSetMetaData)rs.getMetaData()).getColumnCount();j++){
		
		res+= rs.getString(j+1) +"   |/|   "; 
		
	    }
	    System.out.println(res);
	    

	   
	    
	    System.out.println("======abs 2===========================================");
	    rs.absolute(2);
	    System.out.println("false: " + rs.isBeforeFirst());
	    System.out.println("false: " + rs.isAfterLast());
	    System.out.println("false: " + rs.isFirst());
	    System.out.println("false: " + rs.isLast());
	    res="";
	    for (int j=0;j<((ResultSetMetaData)rs.getMetaData()).getColumnCount();j++){
		
		res+= rs.getString(j+1) +"   |/|   "; 
		
	    }
	    System.out.println(res);
	    
	    System.out.println("======abs -2===========================================");
	    rs.absolute(-2);
	    System.out.println("false: " + rs.isBeforeFirst());
	    System.out.println("false: " + rs.isAfterLast());
	    System.out.println("false: " + rs.isFirst());
	    System.out.println("false: " + rs.isLast());
	    res="";
	    for (int j=0;j<((ResultSetMetaData)rs.getMetaData()).getColumnCount();j++){
		
		res+= rs.getString(j+1) +"   |/|   "; 
		
	    }
	    System.out.println(res);
	    

	    System.out.println("======rel -2===========================================");
	    rs.relative(-2);
	    System.out.println("false: " + rs.isBeforeFirst());
	    System.out.println("false: " + rs.isAfterLast());
	    System.out.println("true: " + rs.isFirst());
	    System.out.println("false: " + rs.isLast());
	    res="";
	    for (int j=0;j<((ResultSetMetaData)rs.getMetaData()).getColumnCount();j++){
		
		res+= rs.getString(j+1) +"   |/|   "; 
		
	    }
	    System.out.println(res);
	    

	    System.out.println("======rel 3===========================================");
	    rs.relative(3);
	    System.out.println("false: " + rs.isBeforeFirst());
	    System.out.println("false: " + rs.isAfterLast());
	    System.out.println("false: " + rs.isFirst());
	    System.out.println("true: " + rs.isLast());
	    res="";
	    for (int j=0;j<((ResultSetMetaData)rs.getMetaData()).getColumnCount();j++){
		
		res+= rs.getString(j+1) +"   |/|   "; 
		
	    }
	    System.out.println(res);



	    System.out.println("==============first scroll=================================");
	    rs.last();
	    System.out.println("false: " + rs.isBeforeFirst());
	    System.out.println("false: " + rs.isAfterLast());
	    System.out.println("false: " + rs.isFirst());
	    System.out.println("true: " + rs.isLast());
	   
	    while(rs.next()){
		res="|/|   ";
		for (int j=0;j<((ResultSetMetaData)rs.getMetaData()).getColumnCount();j++){
		    
		    res+= rs.getString(j+1) +"   |/|   "; 
		    
		}
		System.out.println(res);
		
		
	    }
	   
	    System.out.println("==============last scroll down=============================");
	    

	    rs.first();
	    System.out.println("false: " + rs.isBeforeFirst());
	    System.out.println("false: " + rs.isAfterLast());
	    System.out.println("true: " + rs.isFirst());
	    System.out.println("false: " + rs.isLast());

	    
	    while(rs.previous()){
		res="|/|   ";
		for (int j=0;j<((ResultSetMetaData)rs.getMetaData()).getColumnCount();j++){
		    
		    res+= rs.getString(j+1) +"   |/|   "; 
		    
		}
		System.out.println(res);
		
		
	    }


	    System.out.println("==============rel -3=====================");
	    
 
	    rs.last();
	    rs.relative(-3);
	    
	    res="|/|   ";
	    res+= rs.getString("ANTENNA2") +"   |/|   "; 
	    
	    res+= rs.getString("ANTENNA1") +"   |/|   "; 
	    System.out.println(res);

	    System.out.println("==============rel 3======================");
	    
 
	    rs.first();
	    rs.relative(3);
	    
	    res="|/|   ";
	    res+= rs.getString("ANTENNA2") +"   |/|   "; 
	    
	    res+= rs.getString("ANTENNA1") +"   |/|   "; 
	    System.out.println(res);

		
	    System.out.println("==============abs 5=====================");
	    
 
	    boolean b = rs.absolute(5);
	    System.out.println("b : " +b);
	    
	    System.out.println("==============abs -5=====================");
	    
 
	    b = rs.absolute(-5);
	    System.out.println("b : " +b);


	    
	    System.out.println("==============abs 0=====================");
	      
 
	    b = rs.absolute(0);
	    System.out.println("b : " +b);

	    
	    System.out.println("==============abs 4=====================");
	      
 
	    b = rs.absolute(4);
	    System.out.println("b : " +b);

	    System.out.println("===============cancelupdate none===================");
	      
 
	    b= rs.first();
	    System.out.println("b : " +b);
	    rs.cancelRowUpdates();
	     
	    System.out.println("===============relative off==================");
	    boolean sd =rs.relative(-5);
	    
	    
	    boolean adf= rs.relative(19);

	    System.out.println("false: "+sd+"    false: "+adf);
	    




	    System.out.println("===============update===================");
	      
	    rs.first();
	    System.out.println("updated?:" +rs.rowUpdated());
	    
	    rs.updateString(1, "9");
	    rs.updateString("ANTENNA2","99");
	    

	    System.out.println("firstrow: " + rs.getString(1) + "  |/|  "+rs.getString(2) );
	  
	    System.out.println("===============update2===================");
	  	    
	    System.out.println(rs.relative(2));
	    rs.first();
	    System.out.println("firstrow: " + rs.getString(1) + "  |/|   "+rs.getString(2) );
	    System.out.println(rs.relative(2));
	    rs.updateString(1, "8");
	   
	    rs.cancelRowUpdates();
	    rs.updateString("ANTENNA2","88");
	    System.out.println("thirdrow: " + rs.getString(1) + "   |/|   "+rs.getString(2) );
	    
	    

	   

	    System.out.println("===============moveto===================");
	    rs.first();
	    System.out.println("firstrow: " + rs.getString(1) + "  |/|   "+rs.getString(2) );
 	    rs.moveToInsertRow();
	    rs.moveToInsertRow();
	    System.out.println("should be -9 : "+rs.getRow() );
	    rs.moveToInsertRow();
 	    rs.moveToCurrentRow();
	    System.out.println("firstrow: " + rs.getString(1) + "  |/|   "+rs.getString(2) );
	    rs.moveToCurrentRow();
	    System.out.println("firstrow: " + rs.getString(1) + "  |/|   "+rs.getString(2) );
	   



	 //    System.out.println("========ins row updates=======================");
   
	   
// 	    rs.moveToInsertRow();
	    
// 	    rs.updateString("Flux_Unit", "myunit");
	    
// 	    System.out.println("insertrow: " + rs.getString("Flux_Unit"));
// 	    rs.insertRow();
// 	    rs.first();
// 	    System.out.println("false: "+ rs.rowInserted());
// 	    rs.last();
// 	    System.out.println("true: "+ rs.rowInserted());
// 	    System.out.println(rs.getString(2));

	    System.out.println("========save row updates=======================");
	    
	    pfwd(rs);
	    rs.first();
	    rs.relative(1);
	    rs.updateString(1, "68");
	    rs.updateString (2,"76");
	    rs.updateRow();
	    rs.last();
	    System.out.println("false: "+ rs.rowUpdated());
	    rs.absolute(2);
	    System.out.println("true: "+ rs.rowUpdated());
	    System.out.println("false: "+ rs.rowDeleted());
	    
	    pfwd(rs);

	    System.out.println("========del row =======================");
	    
	    rs.first();
	    rs.absolute(2);
	    System.out.println("true: "+ rs.rowUpdated());
	    System.out.println("false: "+ rs.rowDeleted());
	    rs.deleteRow();
	    
	    rs.absolute(2);
	    System.out.println("false: "+ rs.rowUpdated());
	    System.out.println("true: "+ rs.rowDeleted());
	    
	    pfwd(rs);



	}
	
	catch(Exception e){
	    e.printStackTrace();
	}
    }
    
    public void pbkd(ResultSet rs){
	try{
	rs.afterLast();
	    

	    
	while(rs.previous()){
	    String res="|/|   ";
	    for (int j=0;j<((ResultSetMetaData)rs.getMetaData()).getColumnCount();j++){
		
		res+= rs.getString(j+1) +"   |/|   "; 
		
	    }
	    System.out.println(res);
		
		
	}
	}
	catch(Exception e){

	    System.out.println("Error in pbkd");
	    e.printStackTrace();  
	}

    }

    public void pfwd(ResultSet rs){
	try{
	    
	    rs.beforeFirst();
	    System.out.println("------------------------");

	    while(rs.next()){
		String res="|/|   ";
		for (int j=0;j<2;j++){//((ResultSetMetaData)rs.getMetaData()).getColumnCount();j++){
		
		    res+= rs.getString(j+1) +"   |/|   "; 
	    
		}
		System.out.println(res);
	    }
	    
	}catch(Exception e){
	    
	    System.out.println("Error in pfwd");
	    e.printStackTrace();
	}
	
    }

    public static void main(String[] args){
	TestApp t = new TestApp();
	
    }
    
}


