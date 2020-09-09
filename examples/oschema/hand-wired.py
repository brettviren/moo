import moo.oschema as mo

s = mo.Number("Count", "u4")
d2 = s.to_dict()
print(f'object:\n\t{s!r}\ndata out:\n\t{d2}')
