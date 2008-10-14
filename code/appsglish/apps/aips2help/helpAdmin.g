#   helpAdmin.g
#
#   Copyright (C) 1997,1998,1999
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
#   $Id: helpAdmin.g,v 19.1 2004/08/25 00:54:21 cvsmgr Exp $
#

pragma include once
include "gmisc.g"
write_help_latex := function(destDir='.')
{  
   disclaimer := '\
\\vspace*{\\fill}\n\
Copyright \\copyright 1996 AIPS++ Consortium\n\
\n\
\\aipspp\\ User Reference Manual.\n';
   disclaimer := spaste(disclaimer,
'\n\
Permission is granted to make and distribute verbatim copies of\n\
this manual provided the copyright notice and this permission notice\n\
are preserved on all copies.\n\
 \n');
   disclaimer := spaste(disclaimer,
'Permission is granted to copy and distribute modified versions of this\n\
manual under the conditions for verbatim copying, provided that the entire\n\
resulting derived work is distributed under the terms of a permission\n\
notice identical to this one.\n\
 \n');
   disclaimer := spaste(disclaimer,
'Permission is granted to copy and distribute translations of this manual\n\
into another language, under the above conditions for modified versions,\n\
except that this permission notice may be stated in a translation approved\n\
by the \\aipspp\\ Consortium.\n\
 \n');
   disclaimer := spaste(disclaimer,
'The \\aipspp\\ consortium may be reached by email at aips2-request@nrao.edu.\n\
The postal address is: \\aipspp\\ Consortium, c/o NRAO, 520 Edgemont Rd.,\n\
Charlottesville, Va. 22903-2475 USA.\ n\
');

   local masterText := '\\documentclass{article}\n\\usepackage{html}\n';
   masterText := spaste(masterText, '\\usepackage{makeidx}\n\\makeindex\n');
   masterText := spaste(masterText, '\\newcommand{\\aipspp}{{\\textsc{aips}\\texttt{++}}}\n');
   masterText := spaste(masterText, '\\begin{document}\n');
   masterText := spaste(masterText, '\\title{AIPS++ User Reference Manual}\n');
   masterText := spaste(masterText, '\\author{AIPS++ Group, eds}\n');
   masterText := spaste(masterText, '\\maketitle\n');
   masterText := spaste(masterText, '\\begin{htmlonly}\n');
   masterText := spaste(masterText, 'A \\htmladdnormallink{postscript version}{../helpatoms.ps} is available.\n');
   masterText := spaste(masterText, '\\end{htmlonly}\n');
   masterText := spaste(masterText, '\\newpage\n');
   masterText := spaste(masterText, disclaimer);
   masterText := spaste(masterText, '\\newpage\n');
   masterText := spaste(masterText, '\\tableofcontents\n');
    systemHelp := aips2help.openDB();
    gettop := spaste('SELECT FROM ', tableName(systemHelp),
                     ' WHERE parent == \'none\'');
    packages := tableCommand(gettop);
    packagesRow := makeTableRow(packages);
    for(i in 1:numberOfRows(packages)){
       package := getRow(packagesRow, i);
       getChildren := spaste('SELECT FROM ', tableName(systemHelp),
                      ' WHERE parent == \'', package.helpAtom, '\'');
       packageChildren := tableCommand(getChildren);
       topHelp := getRow(packagesRow, i);
       helpTable := openTable(getCell(packages, 'helpText', i));
       rowHelp := makeTableRow(helpTable);
       helpData := getRow(rowHelp, 1);
       ignore := closeTable(helpTable);
       masterText := spaste(masterText, do_work(topHelp, helpData, destDir));
       if(numberOfRows(packageChildren) > 0){
          childRow := makeTableRow(packageChildren);
          for(j in 1:numberOfRows(packageChildren)){
             topHelp := getRow(childRow, j);
             helpTable := openTable(getCell(packageChildren, 'helpText', j));
             rowHelp := makeTableRow(helpTable);
             helpData := getRow(rowHelp, 1);
             ignore := closeTable(helpTable);
             masterText := spaste(masterText, do_work(topHelp, helpData, 
                                                      destDir));
          }
       }
   }
   masterText := spaste(masterText, '\n\\printindex\n\\end{document}');
   fp := fopen(spaste(destDir, '/', 'helpatoms.latex'), "w");
   ignore := fwrite(fp, masterText);
   ignore := fclose(fp);
   closeTable(systemHelp);
}
do_work := function(topHelp, helpData, destDir)
{
    rootName :=  spaste(topHelp.helpAtom, '_', topHelp.type);
    fileName := spaste(destDir, '/', rootName, '.tex');
    header := ' - ';
    if(topHelp.parent != 'none')
       header := spaste(header, topHelp.parent);
    header :=  spaste(header, ':Function');
    synopsis := spaste('\n\\subsubsection*{Synopsis}\n',
                       topHelp.helpAtom , '(', getArgList(helpData), ')');
    labelText := topHelp.helpAtom;
    if(topHelp.type == 'object'){
       header := ' - ';
       if(topHelp.parent != 'none'){
          header := spaste(header, topHelp.parent);
          labelText := spaste(topHelp.parent, ':', topHelp.helpAtom);
       }
       header :=  spaste(header, ':Tool');
       synopsis := F;
    } else if(topHelp.type == 'function'){
       if(topHelp.parent != 'none'){
          labelText := spaste(topHelp.parent, ':', topHelp.helpAtom);
       }
    } else if(topHelp.type == 'package'){
       header := ' -- Package';
       synopsis := F;
    }

    if(topHelp.parent == 'none'){
       text2print := spaste('\\section{',topHelp.helpAtom, header,
                            '\\label{',labelText,'}}\\index{',
                            topHelp.helpAtom,'}\n');
    }else{
       if(topHelp.type == 'function' || topHelp.type == 'object'){
           text2print := spaste('\\subsection{');
       }else{
           text2print := spaste('\\subsubsection{');
       }
       text2print := spaste(text2print, topHelp.helpAtom, header,
                            '\\label{',labelText,'}}\\index{',
                            topHelp.helpAtom,'}\n');
    }
    text2print := spaste(text2print, '{\\itshape Version  ', 
                         topHelp.version,'}\n\\\\\\\\');
    text2print := spaste(text2print, topHelp.oneline, '\n');
        
    if(len(as_byte(topHelp.include)) > 0){
       text2print := spaste(text2print, '\\\\\ninclude \"', topHelp.include, 
                            '\";');
    }
    if(is_string(synopsis))
       text2print := spaste(text2print, synopsis);
    text2print := spaste(text2print, '\\subsubsection*{Category}\n',
                         topHelp.category,'\n');
    methodText := F;
    if(len(topHelp.objects) > 0){
       text2print := spaste(text2print, '\\subsubsection*{Tools}\n');
       text2print := spaste(text2print, '\\begin{tabular}{ll}\n');
       for(object in topHelp.objects){
           objectName := split(object, ':');
           objectLabel := spaste(topHelp.helpAtom, ':', objectName[1]);
           text2print := spaste(text2print, '\\htmlref{',
                                objectName[1], '}{',objectLabel,'} & ',
                                objectName[2],'\\\\\n');
       }
       text2print := spaste(text2print, '\\end{tabular}\n');
    }
    if(len(topHelp.methods) > 0){
       if(topHelp.type != 'package'){
          methodText := '';
       }
       if(topHelp.type == 'object')
          text2print := spaste(text2print, '\\subsubsection*{Functions}\n');
       else
          text2print := spaste(text2print, '\\subsubsection*{Functions}\n');
       text2print := spaste(text2print, '\\begin{tabular}{ll}\n');
       for(method in topHelp.methods){
           methodName := split(method, ':');
           methodLabel := spaste(topHelp.helpAtom, ':', methodName[1]);
           text2print := spaste(text2print, '\\htmlref{',
                                methodName[1], '}{',methodLabel,'} & ',
                                methodName[2],'\\\\\n');
           if(topHelp.type != 'package'){
              methodFull := spaste(topHelp.helpAtom, '.', methodName[1]);
              methodFile := spaste(aips2help.systemHelpDir,'/',methodFull);
              methodTable := openTable(methodFile);
              methodHelp := makeTableRow(methodTable);
              methodData := getRow(methodHelp, 1);
              methodText := spaste(methodText, '\\subsubsection{', 
                                methodName[1], '(', getArgList(methodData),
                                ' )\\label{',methodLabel,'}}\\index{',
                                methodFull,'}\n');
              methodText := spaste(methodText, genText(methodData, T));
              ignore := closeTable(methodTable);
           } 
       }
       text2print := spaste(text2print, '\\end{tabular}\n');
    }
    text2print := spaste(text2print, genText(helpData));
    if(is_string(methodText)){
       text2print := spaste(text2print, 
                            '\n\\subsubsection*{Function Descriptions}\n');
       text2print := spaste(text2print, methodText);
    }
    text2print := spaste(text2print, '\n');
    out_file := spaste(destDir, '/', 'file.tex'); 
    fp := fopen(out_file, "w");
    ignore := fwrite(fp, text2print);
    ignore := fclose(fp);
    # shellCommand := spaste('sed -e \'s/_/\\\\_/g\' -e \'s/>/$>$/g\' -e \'s/</$<$/g\' -e \'s/\\\\n//g\' ', out_file, ' >', fileName);
    sedCommand := 'sed -e \'s/_/\\\\_/g\' -e \'s/>/$>$/g\'';
    sedCommand := spaste(sedCommand, ' -e \'s/</$<$/g\'');
    sedCommand := spaste(sedCommand, ' -e \'s/\\#/\\\\#/g\'');
    sedCommand := spaste(sedCommand, ' -e \'s/\\^/\\\\verb\+^\+/g\'');
    sedCommand := spaste(sedCommand, ' -e\'/\\\\label/{ h; s/.*\\(\\\\label{.*}}\\).*/\\1/;s/\\\\_/_/g;G;s/\\(.*\\)\\n\\(.*\\)\\(\\\\label{.*}}\\)\\(.*\\)/\\2\\1\\4/;}\'');
    shellCommand := spaste(sedCommand, ' ', out_file, ' >', fileName);
    # print shellCommand;
    shell(shellCommand);
    return(spaste('\n\\include{',rootName,'}'));
}
genText := function(helpData, methodFlag=F)
{
   heading := '\\subsubsection*';
   if(methodFlag)
      heading := '\\subparagraph*';
   text2print := '';
   if(has_field(helpData, 'full') && len(as_byte(helpData.full))){
      text2print := spaste(text2print, '\n{\\samepage\n');
      text2print := spaste(text2print, heading, '{Description}\n',
                           helpData.full, '\n');
      text2print := spaste(text2print, '\n}\n');
   }
   if(has_field(helpData, 'args') && len(as_byte(helpData.args))){
      text2print := spaste(text2print, '\n{\\samepage\n');
      text2print := spaste(text2print, '\n',heading, '{Arguments}\n\n');
      text2print := spaste(text2print, makeArgTable(helpData));
      text2print := spaste(text2print, makeArgTable(helpData, 'html'));
      text2print := spaste(text2print, '\n}\n');
   }
   
   if(has_field(helpData, 'return_value')  && 
            len(as_byte(helpData.return_value))){
      text2print := spaste(text2print, '\n{\\samepage\n');
      text2print := spaste(text2print, '\n', heading, '{Returns}');
      text2print := spaste(text2print, '\t',helpData.return_value,'\n');
      text2print := spaste(text2print, '\n}\n');
   }
   text2print := spaste(text2print, '\n{\\samepage\n');
   if(has_field(helpData, 'code') && len(as_byte(helpData.code))){
      text2print := spaste(text2print, '\n', heading, '{Example}\n');
      text2print := spaste(text2print, '\\begin{verbatim}\n');
      text2print := spaste(text2print, helpData.code,'\n\n');
      text2print := spaste(text2print, '\\end{verbatim}\n');
      if(has_field(helpData, 'comments') && len(as_byte(helpData.comments))){
         text2print := spaste(text2print, '\n\n',helpData.comments,'\n');
      }
   }
   text2print := spaste(text2print, '\n}\n');
   if(has_field(helpData, 'see_also') && len(as_byte(helpData.see_also))){
      text2print := spaste(text2print, '\n{\\samepage\n');
      text2print := spaste(text2print, '\n', heading, '{See Also}\n');
      text2print := spaste(text2print, helpData.see_also,'\n');
      text2print := spaste(text2print, '\n}\n');
   }
   text2print := spaste(text2print, '\n\\vspace{.18in}\n\\hrule\n');
   return text2print;
}

getArgList := function(helpData)
{ argList := '';
   if(has_field(helpData, 'args') && len(as_byte(helpData.args))){
       for(arg in 1:len(helpData.args)){
           buf := split(helpData.args[arg], ':');  
           argList := paste(argList, buf[1]);
           if(arg < len(helpData.args))
              argList := spaste(argList, ',');
       }
  }
  return argList;
}

makeArgTable := function(helpData, whatkind = 'latex2e')
{
   if(whatkind == 'latex2e'){
     output := 'latexonly';
     table_env := 'tabular*';
     linewidth := '{4.70in}';
     col_flag := 'p{1.59in}|';
     col1_flag := 'p{1in}|';
     col_kludge := 'p{3.36in}|'
     # linewidth := '';
   } else {
     output := 'htmlonly';
     table_env := 'tabular';
     col_flag := 'l|';
     col1_flag := 'l|';
     col_kludge := 'l|';
     linewidth := '';
   }
   argTable := spaste('\\hfill  \\\\\\\\\n\\begin{', output, '}\n');
   argTable := spaste(argTable, '\\begin{', table_env, 
                      '}',linewidth, '{|',col1_flag, col_flag, col_flag,'}\n');
   argTable := spaste(argTable, '\\hline\n');
   for(arg in 1:len(helpData.args)){
      argsNfun := split(helpData.args[arg], ':');
      argTable := spaste(argTable, argsNfun[1], ' & ');
      if(any(argsNfun[4:5] != 'F')){
         argTable := spaste(argTable, '\\multicolumn{2}{', col_kludge,'}{', 
                      argsNfun[len(argsNfun)-1],'}\\\\\n');
         argTable := spaste(argTable, '\\cline{2-3} & ');
         argTable := spaste(argTable,
            'Default Value& Allowed Values\\\\\n');
         argTable := spaste(argTable, '\\cline{2-3} & ');
         for(i in 4:5){
            if(argsNfun[i] != 'F')
               argTable := spaste(argTable, argsNfun[i])
            if(i < 5)
               argTable := spaste(argTable,' &');
         }
         argTable := spaste(argTable, '\\\\\n');
      } else {
         if(argsNfun[len(argsNfun)-1] == 'F'){
            argTable := spaste(argTable, '\\multicolumn{2}{', col_kludge,
                               '}{ }\\\\\n');
         } else {
            argTable := spaste(argTable, '\\multicolumn{2}{', col_kludge, '}{', 
                         argsNfun[len(argsNfun)-1],'}\\\\\n');
         }
      }
      argTable := spaste(argTable, '\\hline\n');
   }
   argTable := spaste(argTable, '\\end{', table_env, '}\n');
   argTable := spaste(argTable, '\\end{', output,'}\n');

   return argTable;
}
