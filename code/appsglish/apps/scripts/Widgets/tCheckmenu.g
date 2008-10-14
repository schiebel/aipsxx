include 'timer.g'
include 'widgetserver.g'
#
const doit := function(ref error, m, label, names, values)
{
   if (m.getlabel()!=label) {
      val error := 'getlabel failed';
      return F;
   }
#
   if (m.getstate(1)) {
      val error := 'getstate failed'
       return F;
   }
#
   nNames := length(names);
   nValues := length(values);
#
   states := array(F,nNames);
   if (m.getstates() != states) {
      error := 'getstates failed';
      return F;
   }
#
   if (m.getnames()!=names) {
      val error := 'getnames failed';
      return F;
   }
#   
   if (m.getvalues()!=values) {
      val error := 'getvalues failed';
      return F;
   }
#
   if (m.findname(names[nNames]) != nNames) {
      val error := 'findname failed';
      return F;
   }
#
   if (m.findvalue(values[nValues]) != nValues) {
      val error := 'findvalue failed';
      return F;
   }
#
   m.selectindex(nNames, T);
   if (!m.getstate(nNames)) {
      val error := 'selectindex failed';
      return F;
   }
#
   m.selectname(names[nNames], T);
   if (!m.getstate(nNames)) {
      val error := 'selectname failed';
      return F;
   }
#
   m.selectvalue(values[nValues], T);
   if (!m.getstate(nNames)) {
      val error := 'selectvalue failed';
      return F;
   }
#
   l := m.getlabel();
   m.setlabel('doggies');
   if (m.getlabel()!='doggies') {
      val error := 'setlabel failed';
      return F;
   }
   m.setlabel(l);
#
   m.reset();
   states := array(F,nNames);
   if (m.getstates() != states) {
      error := 'reset failed';
      return F;
   }
#
   return T;  
}
#
#
#
f := dws.frame();
lab := 'Names';
names := "name1 name2 name3"
values := [1,2,3];
helpText := 'A nice menu'
m := dws.checkmenu(f, lab, names, values, helpText)
whenever m->select do {
   print 'selection made, value=', $value
}
whenever m->replaced do {
   print 'replacement done, value=', $value
}
#
print 'disable, wait 2 seconds, enable'
m.disabled(T);
timer.wait(2);
m.disabled(F);
print ' '
#
print 'foreground red, wait 2 seconds, foreground black'
m.setforeground('red');
timer.wait(2);
m.setforeground('black');
print ' '
#
print 'background red, wait 2 seconds, background grey'
m.setbackground('red');
timer.wait(2);
m.setbackground('lightgrey');
print ' '
#
print 'test basic menu'
ok1 := doit(error, m, lab, names, values)
if (!ok1) {
  print 'failed because', error
}
#
print ' '
print 'test extended menu'
lab2 := lab;
names2 := "names4 names5";
values2 := [4,5];
m.extend(names2, values2);
m.reset();
ok2 := doit(error, m, lab2, [names,names2], [values,values2]);
if (!ok2) {
  print 'failed because', error
}
#
print ' '
print 'test replace menu'
lab3 := "Letters";
names3 := "xx yy zz";
values3 := [10,20,30];
m.replace (lab3, names3, values3);
m.reset();
ok3 := doit(error, m, lab3, names3, values3);
if (!ok3) {
  print 'failed because', error
}
#
print ' '
ok := (ok1 & ok2 & ok3)
if (ok) {
   print 'ok'
} else {
   print 'not ok'
}
