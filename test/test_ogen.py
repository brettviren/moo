import pytest
from moo.ogen import TypeBuilder


def test_type_builder():
    sc = [
        dict(path="a.b", name="TF", schema="boolean"),
        dict(path="a.b", name="Bools", schema="sequence", items="a.b.TF"),
        dict(path="a.b", name="Age", schema="number"),
        dict(path="a.b", name="Height", schema="number"),
        dict(path="a.b", name="Email", schema="string", format="email"),
        dict(path="a.b", name="Fruit", schema="enum",
             symbols=["rotten", "apple", "orange"], default="rotten"),
        dict(path="a.b", name="Stuff", schema="record", fields=[
            dict(name="tf", item="a.b.TF"),
            dict(name="many", item="a.b.Bools"),
            dict(name="fruit1", item="a.b.Fruit"),
            dict(name="fruit2", item="a.b.Fruit", default="apple"),
            dict(name="fruit3", item="a.b.Fruit"),
            dict(name="email", item="a.b.Email"),
            dict(name="age", item="a.b.Age"),
            dict(name="defemail", item="a.b.Email", default="me@example.com"),
        ])
    ]
    tb = TypeBuilder()
    for one in sc:
        tb.make(**one)
    tb.promote_all()

    from a.b import TF
    print(TF)
    print(TF("true"))
    print(TF("true").pod())
    assert TF("true").pod()
    assert TF(True).pod()
    assert not TF(False).pod()
    assert not TF("no").pod()

    from a.b import Bools
    somebs = Bools([True, "true", "yes", "on", TF(True)])
    assert all(somebs.pod())

    from a.b import Age, Height
    assert 42 == Age(42).pod()
    with pytest.raises(ValueError):
        Age("really old")
    with pytest.raises(ValueError):
        Age(Height(177.8))

    from a.b import Email
    with pytest.raises(ValueError):
        Email("not-an-email-address")

    from a.b import Fruit
    assert "apple" == Fruit("apple").pod()
    assert "orange" == Fruit("orange").pod()
    assert "rotten" == Fruit().pod()
    with pytest.raises(ValueError):
        Fruit("tomato")         # yes, I know

    from a.b import Stuff
    somestuff = Stuff(tf=TF(True), many=somebs, email="foo@example.com",
                      fruit1="orange")
    print(somestuff)
    sspod = somestuff.pod()
    print(sspod)
    assert all(sspod['many'])
    
    
    ## uncomment to make pytest spit out prints
    # assert False
