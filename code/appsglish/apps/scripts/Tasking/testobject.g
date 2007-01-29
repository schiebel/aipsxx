testclient := client("testServer")

func make_squarer()
{
    obj := [=]
    self := [=];
    testclient->create("squarer");
    await testclient->*;
    self.id := $value
    self.type := "squarer"

    obj.id := func() {return self.id;}
    obj.type := func() {return self.type;}
    obj.run := func(inval) {
	wider self;        
        rec := [=];
        inputs := [=];
        inputs.inval := inval;
        rec.object := self.id
        rec.method := "run";
        rec.inputs := inputs;
        testclient->runMethod(rec)
        await testclient->*;
        return $value.retval;
    }

    return obj
}

x := make_squarer()
print x.id();
print x.type();
print x.run(10);
print x.run(-5)
