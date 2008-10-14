//
// History
// =======
//
// 03DEC2003 - upgrade for gcc-3-2 compiler
//

#ifndef __ASCIIfile
#define __ASCIIfile

//#include <vector>
//#include <string>

using namespace std;

//
// errors thrown by this class
//
const int ERR_ASCII_NOTFOUND = 1; // when a named file is not found.
const int ERR_ASCII_NOTREAD = 2; // when a named file cannot be read.
const int ERR_ASCII_NOSUCHLINE = 3; // when a requested line does not exist.
const int ERR_ASCII_NOFILENAME = 4; // when no file name is known
const int ERR_ASCII_NOTWRITTEN = 5; // when a file cannot be written.

//
// definitions of class
//
class ASCIIfile {
private:
  vector<string> f;       // container with all lines
  long lp;                // line pointer for rewind and next/prev/currline
  string fname;           // file where we read from

public:
  //
  // constructors
  //
  ASCIIfile(){};
  ASCIIfile(string);      // read a file

  long size(){return f.size();}  // info on storage
  string getLine(long i);        // get lines by number
  string operator[](long i){return getLine(i);}
                                 // get a line by index

  //
  // get lines in a sequence
  //
  void rewind(){lp = -1;}
  void wind(){lp = f.size();}
  string nextLine();
  string prevLine();
  string currLine();
  long getLineNr(){return lp;}

  //
  // add lines, write file
  //
  void addLine(string s){f.push_back(s);}
  void operator+=(string s){f.push_back(s);}
  void writeFile();
  void writeFile(string);
  void writeFile(string, ios::openmode);
  void clear(){f.clear();}

};

#endif

