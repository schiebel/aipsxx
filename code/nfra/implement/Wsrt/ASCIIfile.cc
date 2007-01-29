#include <iostream>
#include <sstream>
#include <fstream>
#include <string>
#include <vector>

#include "ASCIIfile.h"

class Error {
private:
  string p;
  int errnr;
public:
  Error(const string s){p = s;}
  Error(const int nr){errnr = nr; p = "";}
  Error(const int nr, const string s){errnr = nr; p = s;}
  void add(const string s){p = s + p;}
  const string getError(){return p;}
  int getErrNr(){return errnr;}
  void print(){std::cerr << "Error " << errnr << " - " << p << endl;}
};

//----------------------------------------------------------------------
// Constructor: ASCIIfile(fname)
// Load fname in internal buffer, remember filename
//
ASCIIfile::ASCIIfile(string ifname)
{
  fname = ifname;

  //
  // open file
  //
  ifstream infile(fname.c_str());
  if (!infile){
    throw Error(ERR_ASCII_NOTFOUND, "Cannot open file");
  }

  //
  // load file into internal buffer
  // note: .eof() only becomes true when we actually try to read past it.
  // This means that we must first check it before we save the line. 
  //
  string instr;
  bool stop = false;
  try{
    while (!stop){
      getline(infile, instr, '\n');
      if (infile.eof()){
	stop = true;
      } else {                       // no eof -> save the line we just read
	f.push_back(instr);
      }
    }
  }
  catch(...){
    throw Error(ERR_ASCII_NOTREAD, "Cannot read file");
  }

  //
  // close file, prepare line pointer for nextline call
  //
  infile.close();
  rewind();
}

//----------------------------------------------------------------------
// Method: getLine - Get line from buffer by line number
// man
string ASCIIfile::getLine(long i)
{
  //
  // check if line exists
  //
  if ((i < 0) || (i >= long(f.size()))){
    stringstream s;
    s << "Line " << i << " does not exist";
    throw Error(ERR_ASCII_NOSUCHLINE, s.str());
  }

  //
  // return line
  //
  return f[i];
}

//----------------------------------------------------------------------
// Method: currLine - Get the current line from the buffer
//
string ASCIIfile::currLine()
{
  //
  // check if line exists
  //
  if ((lp >= long(f.size())) || (lp < 0)){
    stringstream s;
    s << "Line " << lp << " does not exist";
    throw Error(ERR_ASCII_NOSUCHLINE, s.str());
  }

  //
  // return line
  //
  return f[lp];
}

//----------------------------------------------------------------------
// Method: preLine - get previous line from the buffer
// Decrease line pointer and return the 'current' line
//
string ASCIIfile::prevLine()
{
  lp--;
  return currLine();
}

//----------------------------------------------------------------------
// Method: nextLine - get next line from the buffer
// Increase line pointer and return the 'current' line
//
string ASCIIfile::nextLine()
{
  lp++;
  return currLine();
}

//----------------------------------------------------------------------
// Method: writefile - write the buffer to the file we remember from reading
//
void ASCIIfile::writeFile()
{
  //
  // check if a file name has been specified
  //
  if (fname == ""){
    throw Error(ERR_ASCII_NOFILENAME, "No file name specified");
  }

  //
  // open the file for writing
  //
  ofstream outfile(fname.c_str());
  if (!outfile){
    throw Error(ERR_ASCII_NOTWRITTEN, "Cannot write file: "+fname);
  }

  //
  // write the buffer to the file
  //
  try{
    for (int i = 0; i < long(f.size()); i++){
      outfile << f[i] << endl;
    }
  }
  catch(...){
    outfile.close();
    throw Error(ERR_ASCII_NOTWRITTEN, "Cannot write file: "+fname);
  }

  outfile.close();
}

//----------------------------------------------------------------------
// Method: writeFile(fname) - write buffer to specified file
//
void ASCIIfile::writeFile(string ofname)
{
  //
  // open the file for writing
  //
  ofstream outfile(ofname.c_str());
  if (!outfile){
    throw Error(ERR_ASCII_NOTFOUND, "Cannot open file '"+ofname+"' for writting");
  }

  //
  // write the buffer to the file
  //
  try{
    for (int i = 0; i < long(f.size()); i++){
      outfile << f[i] << endl;
    }
  }
  catch(...){
    outfile.close();
    throw Error(ERR_ASCII_NOTWRITTEN, "Cannot write file '"+ofname+"'");
  }

  outfile.close();
}

//----------------------------------------------------------------------
// Method: writeFile(fname, mode) - write buffe to specified file with
//                                  mode (e.g. 'ios::app'
//
void ASCIIfile::writeFile(string ofname, ios::openmode m = ios::out)
{
  //
  // open the file with mode
  //
  ofstream outfile(ofname.c_str(), m);
  if (!outfile){
    throw Error(ERR_ASCII_NOTFOUND, "Cannot open file '"+ofname+"' for writting");
  }

  //
  // write the buffer to the file
  //
  try{
    for (int i = 0; i < long(f.size()); i++){
      outfile << f[i] << endl;
    }
  }
  catch(...){
    outfile.close();
    throw Error(ERR_ASCII_NOTWRITTEN, "Cannot write file '"+ofname+"'");
  }

  outfile.close();
}
