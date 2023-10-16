#!/usr/bin/env python3
from .util import unflatten, pathify

# We 'borrow' jsonschema exception as our own
from jsonschema.exceptions import ValidationError

import jsonschema

# Without this, format="..." will be ignored.
# Older versions of jsonschema (eg 3.2.0) lack it.
try:
    format_checker = jsonschema.Draft7Validator.FORMAT_CHECKER
except AttributeError:
    import sys
    sys.stderr.write("WARNING: your jsonschema is old.  string format constraints will be ignored")
    format_checker = None

def ref(oschema):
    '''
    Return the "$ref" value for a schema
    '''
    if isinstance(oschema, str):
        path = oschema.split(".")
    else:
        path = list(oschema["path"])
        path.append(oschema["name"])
    path = "/".join(path)
    #defs = "definitions"
    defs = "$defs"
    return f"#/{defs}/{path}"


def boolean(oschema):
    return {"type":"boolean"}


def number(num):
    '''
    Return JSON Schema for number type oschema.
    '''
    js = dict(type='number')
    dtype = num.get("dtype", "f8")
    dt = dtype[0]
    size = int(dtype[1])           # fixme set constraints based on size
    constraints = num.get("constraints", {})
    if dtype[0] in ('i', 'u'):
        js['type'] = "integer"
    if dtype[0] in ('u',):
        constraints.setdefault('minimum', 0)
    js.update(constraints)
    return js


def string(s):
    '''
    Return JSON Schema for string type oschema.
    '''
    js = dict(type='string')
    for key in ('format', 'pattern'):
        if key in s:
            js[key] = s[key]
    return js


def sequence(s):
    '''
    Return JSON Schema for sequence type oschema.
    '''
    js = dict(type='array')
    js['items'] = {'$ref': ref(s['items'])}
    return js


def field(f):
    '''
    Return JSON Schema for oschema field
    '''
    item = f["item"]
    name = f["name"]
    js = {'$ref': ref(item),
          "title": name[0].upper() + name[1:].replace("_", " "),
          "description": "%s (type: %s)" % (f.get("doc",''), item.split(".")[-1])}
    return js


def record(r):
    '''
    Return JSON Schema for oschema record
    '''
    js = dict(type='object',
              properties = { f["name"]: field(f) for f in r["fields"] })
    return js


def enum(e):
    return {type: "string", enum: e['symbols']}


def any(a):
    return {}


def xxxOf(of, a):
    return {of:[{"$ref":ref(t)} for t in a['types']]}

def anyOf(a): return xxxOf("anyOf", a)
def allOf(a): return xxxOf("allOf", a)
def oneOf(a): return xxxOf("oneOf", a)

def typify(o):
    tn = o["schema"]
    return globals()[tn](o)


def get_all_deps(flat, deps):
    ret = set(deps)
    for dep in deps:
        fdep = flat[dep]
        more = fdep.get('deps',[])
        ret = ret.union(get_all_deps(flat,more))
    ret = list(ret)
    ret.sort()
    return ret


def convert(target, context=None, id=None):
    """
    Convert a target moo oschema in a moo schema context to a JSON Schema form or pass through JSON Schema.

    @param target:the moo schema to form the top-level JSON Schema or an already made JSON Schema

    @param context:a sequence or object with values that of individual moo schema.

    """

    if '$schema' in target:
        return target           # already JSON Schema

    js = {"$schema": "http://json-schema.org/draft-07/schema#"}
    if id is not None:
        js['$id'] = id

    if context is not None:
        flat = pathify(context)
        deps = get_all_deps(flat, target.get('deps',[]))
        flatdeps = {n:typify(flat[n]) for n in deps}
        js['$defs'] = unflatten(flatdeps)
    last = typify(target)
    js.update(last)
    return js

def make_validator_jsonschema():
    '''
    Return a generic looking validator using jsonschema
    '''
    from jsonschema.exceptions import SchemaError
    from jsonschema import validate as js_validate
    def validate(model, schema={}):
        try:
            return js_validate(instance=model, schema=schema,format_checker=format_checker)
        except SchemaError as err:
            raise ValidationError('invalid') from err
    return validate

def make_validator_fastjsonschema():
    from fastjsonschema import validate as fjs_validate
    def validate(model, schema={}):
        return fjs_validate(schema, model)
    return validate

def make_validator(name=None):
    if name is None or name == "jsonschema":
        return make_validator_jsonschema()
    if name == "fastjsonschema":
        return make_validator_fastjsonschema()
    raise ValueError(f'unknown validator: {name}')

def validate(model, jschema, validator="jsonschema"):
    'Validate model against schema with validator'
    if isinstance(validator, str):
        validator = make_validator(validator)
    return validator(model, jschema)

