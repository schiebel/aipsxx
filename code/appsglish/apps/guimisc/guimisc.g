#            show_message, show_error, show_warning windows
#
#   Copyright (C) 1995,1996,1997,1998,1999,2001,2002
#   Associated Universities, Inc. Washington DC, USA.
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2 of the License, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#   more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Foundation, Inc.,
#   675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
#   Correspondence concerning AIPS++ should be addressed as follows:
#          Internet email: aips2-request@nrao.edu.
#          Postal address: AIPS++ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#   $Id: guimisc.g,v 19.1 2004/08/25 01:18:54 cvsmgr Exp $
#

pragma include once;

include "gmisc.g";
include "widgetserver.g";

gui_misc_start_client := function()
{ 
    if(!is_defined("guimiscClient_started")){
	global guimiscClient_started := 'yes';
	global guimiscClient := client("guimisc");
    }
}


const chooser := subsequence(dirName = ".", restrictions=[data=F, tables=F], 
			     theTitle='', writeOK=F, multi=F, filter='*', 
			     selected='', access='r', ws=dws)
{

    #
    # Main routine for making data selection in AIPS++
    #

    tk_hold();
    gui_misc_start_client();
    private := [=];
    fc := [=];
    fc.dirName := dirName;
    fc.frame := ws.frame(title=theTitle);
    fc.frame->cursor('watch');
    fc.menubar := [=];
    fc.menubar := ws.frame(fc.frame, side='left', relief='groove', expand='x');
    if(restrictions.data){

	fc.datafilter := [=];
	fc.datafilter.menu  := ws.button(fc.menubar, type='menu', text='Data Filter',
				      relief='flat');

	fc.datafilter.blank2 := ws.button(fc.datafilter.menu, text='', disabled=T);
	fc.datafilter.table := ws.button(fc.datafilter.menu, type='cascade',
				      text='Other Tables');
	fc.datafilter.table := ws.button(fc.datafilter.menu, type='cascade',
				      text='Other Tables');
	fc.datafilter.image := ws.button(fc.datafilter.menu, type='cascade',
				      text='Image');
	fc.datafilter.meas_set := ws.button(fc.datafilter.menu, type='cascade',
					 text='Measurement Set');
	fc.datafilter.calibration := ws.button(fc.datafilter.menu, type='cascade',
					    text='Calibration Information');
	fc.datafilter.refdata := ws.button(fc.datafilter.menu, type='cascade',
					text='Reference Data');

    }

    # A bit more than the normal file chooser with options for what to
    # see in the file list

    fc.showopts := [=];
    fc.showopts.menu := ws.button(fc.menubar, type='menu',
                               text='View', relief='flat');
    fc.showopts.blank2 := ws.button(fc.showopts.menu, text='', disabled=T);
    fc.showopts.date := ws.button(fc.showopts.menu, type='check', text='Date',
			       relief='flat', relief='raised');
    fc.showopts.size := ws.button(fc.showopts.menu, type='check', text='Size',
			       relief='flat', relief='raised');
    if(restrictions.data){

        fc.showopts.type := ws.button(fc.showopts.menu, type='check', text='Type',
			           relief='flat');

        whenever fc.showopts.type->press do{
	    fc.showopts.state.type := fc.showopts.type->state();
	    fc.dirName := private.show_dir(fc.dirName, fc, restrictions, access, '');
        }
    }

    fc.showopts.state := [=];
    fc.showopts.state.date := F;
    fc.showopts.state.size := F;
    fc.showopts.state.type := F;

    fc.showopts.date->state(fc.showopts.state.date);
    fc.showopts.size->state(fc.showopts.state.size);
    if(has_field(fc.showopts, 'type')){
       fc.showopts.type->state(fc.showopts.state.type);
    }

    whenever fc.showopts.date->press do{
	fc.showopts.state.date := fc.showopts.date->state();
	fc.dirName := private.show_dir(fc.dirName, fc, restrictions, access, '');
    }
    whenever fc.showopts.size->press do{
	fc.showopts.state.size := fc.showopts.size->state();
	fc.dirName := private.show_dir(fc.dirName, fc, restrictions, access, '');
    }

    # Data chooser stuff only

    if(restrictions.data){
	fc.showopts.blank := ws.button(fc.showopts.menu, text='', disabled=T);
	fc.showopts.table := ws.button(fc.showopts.menu, type='check',
                                    text='Tables', relief='raised');
	fc.showopts.file := ws.button(fc.showopts.menu, type='check',
				   text='Files', relief='raised');
#
	fc.showopts.state.table := restrictions.tables;
	fc.showopts.state.file  := restrictions.data;
#
	fc.showopts.table->state(fc.showopts.state.table);
	fc.showopts.file->state(fc.showopts.state.file);

#

	whenever fc.showopts.table->press do{
	    restrictions.tables := fc.showopts.table->state();
	    fc.dirName := private.show_dir(fc.dirName, fc, restrictions, access,'');
	}
	whenever fc.showopts.file->press do{
	    restrictions.data := fc.showopts.file->state();
	    fc.dirName := private.show_dir(fc.dirName, fc, restrictions, access, '');
	}
    }

    fc.filterFrame := ws.frame(fc.frame, expand='both');
    fc.filterFrame2 := ws.frame(fc.filterFrame, side='left',expand='x');
    if(restrictions.data)
	fc.filterLabel := ws.label(fc.filterFrame2, text='File Filter');
    else 
       fc.filterLabel := ws.label(fc.filterFrame2, text='Filter');
    fc.filterFrame3 := ws.frame(fc.filterFrame, side='left', expand='x');
    fc.filterEntry := ws.entry(fc.filterFrame3, fill='x', width=50);
    fc.filterEntry->insert(spaste(shell('pwd'),"/",filter));
#
    fc.megaFrame1 := ws.frame(fc.filterFrame, side='left', expand='both');
    fc.megaFrame2 := ws.frame(fc.megaFrame1, side='top', expand='y');
    fc.megaFrame3 := ws.frame(fc.megaFrame1, side='top', expand='both');

#
    fc.dirFrame    := ws.frame(fc.megaFrame2, side='top', expand='y');
    fc.dirFrame2   := ws.frame(fc.dirFrame, side='left', expand='x');
    fc.dirLabel    := ws.label(fc.dirFrame2, text='Directories');
    fc.dirFrame3   := ws.frame(fc.dirFrame, side='left', expand='y');
    fc.dirList     := ws.scrolllistbox(fc.dirFrame3,fill='y',font='fixed');


    textLabel := 'Files';
    if(restrictions.data || restrictions.tables)
	textLabel := 'Files or Tables';

    fc.fileFrame   := ws.frame(fc.megaFrame3, side='top', expand='both');
    fc.fileFrame2  := ws.frame(fc.fileFrame, side='left', expand='x');
    fc.fileLabel   := ws.label(fc.fileFrame2, text=textLabel);
    fc.fileFrame3  := ws.frame(fc.fileFrame, side='left', expand='both');
    fc.fileList    := ws.scrolllistbox(fc.fileFrame3,fill='both',font='fixed');
    if(multi)
	fc.fileList->mode('multiple');

#

#
    fc.selectFrame := ws.frame(fc.frame, expand='x');
    fc.selectFrame2 := ws.frame(fc.selectFrame, side='left');
    fc.selectLabel := ws.label(fc.selectFrame2, text='Selection');
    fc.selectFrame3 := ws.frame(fc.selectFrame, side='left', expand='x');
    fc.selectEntry := ws.entry(fc.selectFrame3, fill='x', width=50);
    fc.selectEntry->insert(spaste(shell('pwd'),"/", selected));
#
    fc.buttonFrame := ws.frame(fc.frame, side='left', relief='groove', expand='x');
    fc.padleft     := ws.frame(fc.buttonFrame, height=1, width=1, expand='x');
    fc.innerFrame  := ws.frame(fc.buttonFrame, side='left',expand='none')
    fc.ok          := ws.button(fc.innerFrame, text='OK');
    fc.filter      := ws.button(fc.innerFrame, text='Filter');
    fc.cancel      := ws.button(fc.innerFrame, text='Cancel');
    fc.padright     := ws.frame(fc.buttonFrame, height=1, width=1, expand='x');
#

    fc.dirList->bind('<Double-ButtonPress>', 'doubleclick');
    fc.dirList->bind('<ButtonPress>', 'singleclick');
    fc.getdirselect := T;

    whenever fc.ok->press do { 
	fileName := fc.selectEntry->get();
	if(multi){
	    picked := fc.fileList->get(fc.fileList->selection());
	    fileName := array('blank', len(picked));
	    for(i in 1:len(picked)){
		noblanks := split(picked[i]);
		fileName[i] := spaste(fc.dirName, '/', noblanks);
	    }
	}
	if (private.check_file(fc, fileName)) {
           fc.dirName := private.show_dir(fc.dirName, fc, restrictions, access, '');
        }
    }

    whenever fc.filter->press do {
	filterName := fc.filterEntry->get();
	fc.dirName := private.show_dir(filterName, fc, restrictions, access, '');
    }
         
    whenever fc.cancel->press do { 
	self->returns([guiReturns=F]);
	fc.frame := 0;
    }

    whenever fc.dirList->select do {
        if(fc.getdirselect){
	   fc.dirName := fc.dirList->get($value);
	   fc.dirName := private.show_dir(fc.dirName, fc, restrictions, access, '');
        }
    }

    whenever fc.dirList->doubleclick do {
        if(fc.getdirselect)
           fc.getdirselect := F;
        else
           fc.getdirselect := T;
	#fc.dirName := fc.dirList->get($value);
	#fc.dirName := private.show_dir(fc.dirName, fc, restrictions, access, '');
    }

    whenever fc.fileList->select do {
	choiceIs := split(fc.fileList->get($value));
	fc.selectEntry->delete("start","end");
	fileName := choiceIs[len(choiceIs)];
	fc.selectEntry->insert(spaste(fc.dirName, "/", fileName));
    }

    whenever fc.filterEntry->return do {
	filterName := fc.filterEntry->get();
	fc.dirName := private.show_dir(filterName, fc, restrictions, access, '');
    }

    whenever fc.selectEntry->return do {
	fileName := fc.selectEntry->get();
	if(private.check_file(fc, fileName))
	    fc.dirName := private.show_dir(fc.dirName, fc, restrictions, access, '');
    }


    #
    # chooser.check_file
    # Given a fileName it checks to see if it's valid and posts it if it is
    # otherwise displays an error or changes directories
    #

    private.check_file := function(ref fc, ref fileName)
    {  
	wider self;

# Use the first element as this may also be called
# with a vector of items

	if(fileType(fileName[1]) == "unknown" && !writeOK) { 
	    show_warning(spaste('File not found: ', fileName[1]));
	} else if(fileType(fileName[1]) == "Directory") {
	    fc.dirName := fileName;
	    return T;
	} else {
	    fc.frame->unmap();
	    self->returns([guiReturns=fileName]);
	    fc.frame := 0;
	}
	return F;
    }

    #
    # chooser.show_data
    # Displays information about the various Tables and files
    #

    private.show_data := function(showopts, files, fileInfo)
    {  
	wider private;
	i := 1;

	displayList := files;
	for (theFile in files){
	    infoField := split(fileInfo[i]);
	    displayList[i] := '';
	    if(has_field(showopts, 'type') && showopts.type){
		displayList[i] := sprintf( '%s%-6.5s', displayList[i], infoField[1] );
	    }
	    if(showopts.date){
		displayList[i] := sprintf( '%s%-12.11s', displayList[i],
					   paste(infoField[4],infoField[5],infoField[7]) );
	    }
	    if(showopts.size){
		displayList[i] := sprintf( '%s%11.9s', displayList[i], infoField[2] );
	    }
	    displayList[i] := paste(displayList[i], theFile);
	    i := i+1;
	}
	return displayList;
    }

    #
    # private.fetch_dir_info
    # returns directory and file information from the guimisc client
    #

    private.fetch_dir_info := function(dir = ".", filter_= "*", 
				       restrictions=[data=F, tables=F],
				       access='r')
    {  
	guimiscClient->dirops(directory=dir,
			      filefilter=filter_,
			      tablesonly=restrictions.tables,
			      dataonly=restrictions.data,
			      access=access);
	await guimiscClient->dirops_result;
	return $value;
    }


    #
    # private.show_dir
    # Shows directory and file information in the two display lists
    #

    private.show_dir := function(dirName, ref fc, restrictions, access, selected)
    {     
	wider private;
	filterName := fc.filterEntry->get();
	dirsAndFiles := private.fetch_dir_info(dirName, filterName, 
					       restrictions, access);
	if(!has_field(dirsAndFiles, "Error")){
	    # sort things
	    dirsAndFiles.Dirs := sort(dirsAndFiles.Dirs);
	    if (len(dirsAndFiles.Files)) {
		fileOrder := order(dirsAndFiles.Files);
		dirsAndFiles.Files := dirsAndFiles.Files[fileOrder];
		dirsAndFiles.FileInfo := dirsAndFiles.FileInfo[fileOrder];
	    }
	    fc.dirList->delete("start","end");
	    fc.fileList->delete("start","end");
	    fc.dirList->insert(dirsAndFiles.Dirs);
	    what2Display := private.show_data(fc.showopts.state,
					      dirsAndFiles.Files,
					      dirsAndFiles.FileInfo);
	    fc.fileList->insert(what2Display);
	    if (len(dirsAndFiles.Files)) {
		theSelected := ind(dirsAndFiles.Files)[dirsAndFiles.Files==selected];
		if(len(theSelected) > 0){
		    fc.fileList->select(as_string(theSelected));
		}
	    }
	    fc.filterEntry->delete("start","end");
	    fc.filterEntry->insert(spaste(dirsAndFiles.Directory,"/",
					  dirsAndFiles.Filter));
	    fc.selectEntry->delete("start","end");
	    fc.selectEntry->insert(spaste(dirsAndFiles.Directory, "/", selected));
	    dirName := dirsAndFiles.Directory;
	} else {
	    show_error(dirsAndFiles.Error);
	}
	return dirName;
    }

    fc.dirName := private.show_dir(fc.dirName, fc, restrictions, access, selected);
    tk_release();
    dum := fc.frame->cursor('left_ptr');

} #End of chooser;

#
# filechooser general purpose file chooser utility
#


const filechooser := function(dirName = ".", restrictions=[data=F,tables=F], 
			      title='AIPS++ File Chooser', wait=T, writeOK=F, multi=F, 
			      filter='*', selected='',access='r')
{
    fc := chooser(dirName,restrictions, title, writeOK=writeOK, multi=multi, 
		  filter=filter, selected=selected, access=access);
    if(wait){
	await fc->returns;
	return $value;
    } else {
	return ref fc;
    }
}

#
# Data chooser is just a specialized form of the filechooser
#
const datachooser := function(dirName = ".", title="AIPS++ Data Chooser", 
			      wait=T, writeOK=F, multi=F, access='r')
{ 
    return ref filechooser(dirName, restrictions=[data=T, tables=T], 
			   title=title, wait=wait, writeOK=writeOK, multi=multi,
			   access=access); 
}


#
# TAble chooser is just a specialized form of the filechooser
#
const tablechooser := function(dirName = ".", title="AIPS++ Data Chooser", 
			       wait=T, writeOK=F, multi=F, filter='*', selected='',
			       access='r')
{ 
    return ref filechooser(dirName, restrictions=[data=F, tables=T], 
			   title=title, wait=wait, writeOK=writeOK, multi=multi, 
			   filter=filter, selected=selected, access=access); 
}

#
#  Error and Warning Dialogs
#

const show_error := function(errorString)
{
    show_message("Error", errorString);
}
#
const show_warning := function(errorString)
{
    show_message("Warning", errorString);
}

#
const show_message := function(firstLabel, secondLabel)
{
    titleLabel := paste(firstLabel);
    global notice := [=];
    notice.topFrame := frame(title=titleLabel, width='3i', side='top');
    notice.mFrame := frame(notice.topFrame, width='3i');
    notice.notice := message(notice.mFrame, text=secondLabel);
    notice.bFrame := frame(notice.topFrame, width='3i');
    notice.ok    := button(notice.bFrame, "OK");
    whenever notice.ok->press do { notice.topFrame->unmap(); notice.topFrame := 0;}
   
}
