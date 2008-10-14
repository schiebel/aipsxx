# bimafillerGUI.g: GUI for file chooser for bimafiller.
#
#   Copyright (C) 1999,2000
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
pragma include once;

include "guicomponents.g";
include "guimisc.g";
    
const mirchooser := subsequence(dirName = ".",
				restrictions=[data=F, tables=F], 
				theTitle='', 
				writeOK=F, multi=F, filter='*', 
				selected='', access='r') {

    #
    # Main routine for making data selection in AIPS++
    #
    theTitle := 'Select MIRIAD uv dataset';
    tk_hold();
    gui_misc_start_client();
    private := [=];
    fc := [=];
    fc.dirName := dirName;
    fc.frame := frame(title=theTitle);
    fc.frame->cursor('watch');
    fc.menubar := [=];
    fc.menubar := frame(fc.frame, side='left', relief='groove', expand='x');
    if(restrictions.data){
	fc.datafilter := [=];
	fc.datafilter.menu  := button(fc.menubar, type='menu',
				      text='Data Filter',
				      relief='flat');
	fc.datafilter.blank2 := button(fc.datafilter.menu, text='',
				       disabled=T);
	fc.datafilter.table := button(fc.datafilter.menu, type='cascade',
				      text='Other Tables');
	fc.datafilter.table := button(fc.datafilter.menu, type='cascade',
				      text='Other Tables');
	fc.datafilter.image := button(fc.datafilter.menu, type='cascade',
				      text='Image');
	fc.datafilter.meas_set := button(fc.datafilter.menu, type='cascade',
					 text='Measurement Set');
	fc.datafilter.calibration := button(fc.datafilter.menu, type='cascade',
					    text='Calibration Information');
	fc.datafilter.refdata := button(fc.datafilter.menu, type='cascade',
					text='Reference Data');
    }
    # A bit more than the normal file chooser with options for what to
    # see in the file list
    fc.showopts := [=];
    fc.showopts.menu := button(fc.menubar, type='menu',
                               text='View', relief='flat');
    fc.showopts.blank2 := button(fc.showopts.menu, text='', disabled=T);
    fc.showopts.date := button(fc.showopts.menu, type='check', text='Date',
			       relief='flat', relief='raised');
    fc.showopts.size := button(fc.showopts.menu, type='check', text='Size',
			       relief='flat', relief='raised');
    fc.showopts.type := button(fc.showopts.menu, type='check', text='Type',
			       relief='flat');
    fc.showopts.state := [=];
    fc.showopts.state.date := F;
    fc.showopts.state.size := F;
    fc.showopts.state.type := F;
    fc.showopts.date->state(fc.showopts.state.date);
    fc.showopts.size->state(fc.showopts.state.size);
    fc.showopts.type->state(fc.showopts.state.type);
    whenever fc.showopts.date->press do {
	fc.showopts.state.date := fc.showopts.date->state();
	fc.dirName := private.show_dir(fc.dirName, fc, restrictions, access,
				       '');
    }
    whenever fc.showopts.size->press do {
	fc.showopts.state.size := fc.showopts.size->state();
	fc.dirName := private.show_dir(fc.dirName, fc, restrictions, access,
				       '');
    }
    whenever fc.showopts.type->press do {
	fc.showopts.state.type := fc.showopts.type->state();
	fc.dirName := private.show_dir(fc.dirName, fc, restrictions, access,
				       '');
    }
    # Data chooser stuff only
    if(restrictions.data){
	fc.showopts.blank := button(fc.showopts.menu, text='', disabled=T);
	fc.showopts.table := button(fc.showopts.menu, type='check',
                                    text='Tables', relief='raised');
	fc.showopts.file := button(fc.showopts.menu, type='check',
				   text='Files', relief='raised');
	fc.showopts.state.table := restrictions.tables;
	fc.showopts.state.file  := restrictions.data;
	fc.showopts.table->state(fc.showopts.state.table);
	fc.showopts.file->state(fc.showopts.state.file);
	whenever fc.showopts.table->press do {
	    restrictions.tables := fc.showopts.table->state();
	    fc.dirName := private.show_dir(fc.dirName, fc, restrictions,
					   access,'');
	}
	whenever fc.showopts.file->press do {
	    restrictions.data := fc.showopts.file->state();
	    fc.dirName := private.show_dir(fc.dirName, fc, restrictions,
					   access, '');
	}
    }
    fc.filterFrame := frame(fc.frame, expand='both');
    fc.filterFrame2 := frame(fc.filterFrame, side='left',expand='x');
    if(restrictions.data) {
	fc.filterLabel := label(fc.filterFrame2, text='File Filter');
    } else {
	fc.filterLabel := label(fc.filterFrame2, text='Filter');
    }
    fc.filterFrame3 := frame(fc.filterFrame, side='left', expand='x');
    fc.filterEntry := entry(fc.filterFrame3, fill='x', width=50);
    fc.filterEntry->insert(filter);
    fc.megaFrame1 := frame(fc.filterFrame, side='left', expand='both');
    fc.megaFrame2 := frame(fc.megaFrame1, side='top', expand='both');
    fc.megaFrame3 := frame(fc.megaFrame1, side='top', expand='both');
    fc.dirFrame    := frame(fc.megaFrame2, side='top', expand='both');
    fc.dirFrame2   := frame(fc.dirFrame, side='left', expand='x');
    fc.dirLabel    := label(fc.dirFrame2, text='Directories');
    fc.dirFrame3   := frame(fc.dirFrame, side='left', expand='both');
    fc.dirList     := listbox(fc.dirFrame3,fill='both');
    fc.dirYSB      := scrollbar(fc.dirFrame3, orient='vertical');
    fc.dirXSB      := scrollbar(fc.dirFrame, orient='horizontal');
    whenever fc.dirList->xscroll do {
	fc.dirXSB->view($value);
    }
    whenever fc.dirList->yscroll do {
	fc.dirYSB->view($value);
    }
    whenever fc.dirXSB->scroll do {
	fc.dirList->view($value);
    }
    whenever fc.dirYSB->scroll do {
	fc.dirList->view($value);
    }
    textLabel := 'Files';
    if(restrictions.data || restrictions.tables) {
	textLabel := 'Files or Tables';
    }
    fc.fileFrame   := frame(fc.megaFrame3, side='top', expand='both');
    fc.fileFrame2  := frame(fc.fileFrame, side='left', expand='x');
    fc.fileLabel   := label(fc.fileFrame2, text=textLabel);
    fc.fileFrame3  := frame(fc.fileFrame, side='left', expand='both');
    fc.fileList    := listbox(fc.fileFrame3,fill='both');
    if(multi) {
	fc.fileList->mode('multiple');
    }
    fc.fileYSB     := scrollbar(fc.fileFrame3, orient='vertical');
    fc.fileXSB     := scrollbar(fc.fileFrame, orient='horizontal');
    whenever fc.fileList->xscroll do {
	fc.fileXSB->view($value);
    }
    whenever fc.fileList->yscroll do { 
	fc.fileYSB->view($value);
    }
    whenever fc.fileXSB->scroll do {
	fc.fileList->view($value);
    }
    whenever fc.fileYSB->scroll do {
	fc.fileList->view($value);
    }
    fc.selectFrame := frame(fc.frame, expand='x');
    fc.selectFrame2 := frame(fc.selectFrame, side='left');
    fc.selectLabel := label(fc.selectFrame2, text='Selection');
    fc.selectFrame3 := frame(fc.selectFrame, side='left', expand='x');
    fc.selectEntry := entry(fc.selectFrame3, fill='x', width=50);
    fc.selectEntry->insert(spaste(shell('pwd'),"/", selected));
    fc.buttonFrame := frame(fc.frame, side='left', relief='groove', 
			    expand='x');
    fc.padleft     := frame(fc.buttonFrame, height=1, width=1, expand='x');
    fc.innerFrame  := frame(fc.buttonFrame, side='left',expand='none')
    fc.ok          := button(fc.innerFrame, text='OK');
    fc.filter      := button(fc.innerFrame, text='Filter');
    fc.cancel      := button(fc.innerFrame, text='Cancel');
    fc.padright     := frame(fc.buttonFrame, height=1, width=1, expand='x');
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
	if(private.check_file(fc, fileName))
	    fc.dirName := private.show_dir(fc.dirName, fc, restrictions, 
					   access, '');
    }
    whenever fc.filter->press do {
	filterName := fc.filterEntry->get();
	fc.dirName := private.show_dir(filterName, fc, restrictions, access, 
				       '');
    }
    whenever fc.cancel->press do { 
	self->returns([guiReturns=F]);
	fc.frame := 0;
    }
    whenever fc.dirList->select do {
	fc.dirName := fc.dirList->get($value);
	fc.dirName := private.show_dir(fc.dirName, fc, restrictions, access, 
				       '');
    }
    whenever fc.fileList->select do {
	choiceIs := split(fc.fileList->get($value));
	fc.selectEntry->delete("start","end");
	fileName := choiceIs[len(choiceIs)];
	fc.selectEntry->insert(spaste(fc.dirName, "/", fileName));
    }
    whenever fc.filterEntry->return do {
	filterName := fc.filterEntry->get();
	fc.dirName := private.show_dir(filterName, fc, restrictions, access,
				       '');
    }
    whenever fc.selectEntry->return do {
	fileName := fc.selectEntry->get();
	if(private.check_file(fc, fileName))
	    fc.dirName := private.show_dir(fc.dirName, fc, restrictions, 
					   access, '');
    }
    #
    # chooser.check_file
    # Given a fileName it checks to see if it's valid and posts it if it is
    # otherwise displays an error or changes directories
    #
    private.check_file := function(ref fc, ref fileName) {  
	wider self;
	if(fileType(fileName) == "unknown" && !writeOK) { 
	    show_warning(spaste('File not found: ', fileName));
	} else if(fileType(fileName) == "Directory") {
	    #
	    # Check to see if directory contains "visdata" file, in which case
	    # it is a miriad visibility dataset.
	    #
	    isMiriadVis := sh().command(spaste('test -f ', fileName, 
					       '/visdata'));
	    if (isMiriadVis.status != 0) {
		fc.dirName := fileName;
		defaultlogger.note(spaste('Selected file ',fileName, 
					  ' is not a MIRIAD uv dataset'));
		return T;
	    } else {
		fc.frame->unmap();
		self->returns([guiReturns=fileName]);
		fc.frame := F;
	    }
	} else {
	    fc.frame->unmap();
	    self->returns([guiReturns=fileName]);
	    fc.frame := F;
	}
	return F;
    }
    #
    # chooser.show_data
    # Displays information about the various Tables and files
    #
    private.show_data := function(showopts, files, fileInfo) {  
	wider private;
	i := 1;
	displayList := files;
	for (theFile in files){
	    infoField := split(fileInfo[i]);
	    displayList[i] := '';
	    if(showopts.type){
		displayList[i] := paste(displayList[i], infoField[1], "\t");
	    }
	    if(showopts.date){
		displayList[i] := paste(displayList[i], infoField[4], 
					infoField[5], infoField[7]);
	    }
	    if(showopts.size){
		displayList[i] := paste(displayList[i], infoField[2], "\t");
	    }
	    displayList[i] := paste(displayList[i], theFile, "\t");
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
				       access='r') {  
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
    private.show_dir := function(dirName, ref fc, restrictions, access,
				 selected) {     
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
		theSelected := 
		    ind(dirsAndFiles.Files)[dirsAndFiles.Files==selected];
		if(len(theSelected) > 0) {
		    fc.fileList->select(as_string(theSelected));
		}
	    }
	    fc.filterEntry->delete("start","end");
	    fc.filterEntry->insert(dirsAndFiles.Filter);
	    fc.selectEntry->delete("start","end");
	    fc.selectEntry->insert(spaste(dirsAndFiles.Directory, "/", 
					  selected));
	    dirName := dirsAndFiles.Directory;
	} else {
	    show_error(dirsAndFiles.Error);
	}
	return dirName;
    }

    fc.dirName := private.show_dir(fc.dirName, fc, restrictions, access,
				   selected);
    tk_release();
    dum := fc.frame->cursor('left_ptr');
} # mirchooser;
