local c = import "app.jsonnet";
local car1 = c.app.Vehicle(model="Justy", type="slow");
c.app.Person(email="brett.viren@gmail.com", vehicle=car1)


