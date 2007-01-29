# include guard
pragma include once

include 'types.g';
dish:='';
types.class('dish').includefile('dish.g');

#Constructor
types.method('ctor_dish');

#Group=basic

#Methods
types.group('basic').method('addop','Add an operation to DISH tool').
	string('includefile').string('ctorname');
#types.method('busy','Disable/enable DISH GUI').boolean('tOrF',F);
#types.method('dologging','Enable/disable logging to scripter').
#	boolean('tOrF',F)
types.method('done','Close down the tool');
types.method('gui','Fire up the GUI').boolean('parent',F);
types.method('logcommand','Write commands to the scripter').string('method').
	record('data');
types.method('message','Post a message to the DISH tool GUI').string('msg');
types.method('open','Open a data file').string('fullPathname').
	string('access','r').boolean('new',F);
#types.method('ops');
#types.method('plotter');
#types.method('rm');
types.method('restorestate','Restore state of dish tool');
types.method('savesate','Save state of dish tool');
types.method('statefile','Specify file for state saving').
	string('fullPathname');
#types.method('type','Toolmanager essential');
#types.method('view_sdrec','Plot an SDRECORD to the dish tool plotter').
#	record('data',unset,allowunset=T).string('name').boolean('overlay',F).
#	boolean('refocus',T).boolean('frombase',F);

#Group = ops
types.group('operations').method('average','constructor for average tool');
types.method('baseline','constructor for baseline tool');
types.method('calculator','constructor for calculator tool');
#types.method('columnden','constructor for columnden tool');
types.method('function','constructor for function tool');
types.method('gauss','constructor for gauss tool');
#types.method('mapit','constructor for mapit tool');
#types.method('multiop','constructor for multiop tool');
types.method('print','constructor for print tool');
types.method('regrid','constructor for regrid tool');
types.method('select','constructor for select tool');
types.method('save','constructor for save tool');
types.method('smooth','constructor for smooth tool');
types.method('stats','constructor for stats tool');

#Group = rm
types.group('resultsmanager').method('rm','Access to dish tool results manager');
types.method('add','Add an SDRecord or SDIterator to the results manager').
	string('name').string('description').record('value').string('type');
types.method('delete','Delete an item or items from the results manager').
	vector_string('items');
types.method('size','Obtain the number of items in the results manager');
types.method('selectionsize','Obtain the number of items selected in the results manager');
types.method('getselectionnames','Get the names associated with the selections');
types.method('getselectionvalues','Get the value associated with selections (returned in a record)');
types.method('getselectiondescriptions','Get the descriptions associated with the selections');
types.method('getnames','Get the names corresponding to the given indices').vector_integer('indices');
types.method('getdescriptions','Get the descriptions corresponding to the given indices').vector_integer('indices');
types.method('copy','Copy the current selections to the clipboard');
types.method('paste','Paste from the clipboard to the results manager');
types.method('getvalues','Get values associated with given indices').vector_integer('indices');
#types.method('select','Select the given indices').vector_integer('indices');
types.method('selectbyname','Select a single entry by name').string('name');
types.method('getlastviewed','Return last viewed item');
#types.method('done','Destroy and cleanup after results manager');

#Group = plotter
types.group('plotter').method('plotter','Access to dish tool plotter');
