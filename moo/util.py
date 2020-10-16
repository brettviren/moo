#!/usr/bin/env python3

import os
import moo
import importlib
import json
import jsonpointer


def select_path(obj, path, delim='.'):
    '''Select out a part of obj structure based on a path.

    The path is a list or a delim-separated string.

    Any element of the path that looks like an integer will be cast to
    one assuming it indexes an array.

    '''
    if isinstance(path, str):
        path = path.split(delim)
    for one in path:
        if one == '':
            continue
        try:
            one = int(one)
        except ValueError:
            pass
        obj = obj[one]

    return obj


def validate(model, schema, validator="jsonschema"):
    'Validate model against schema with validator'
    if validator == "jsonschema":
        from jsonschema import validate as js_validate
        from jsonschema import draft7_format_checker
        return js_validate(instance=model, schema=schema,
                           format_checker=draft7_format_checker)
    if validator == "fastjsonschema":
        from fastjsonschema import validate as fjs_validate
        return fjs_validate(schema, model)
    raise ValueError(f"unknown validator: {validator}")


def clean_paths(paths):
    '''Return list of paths made absolute with cwd as first.

    Input may be :-separated string or list'''
    if isinstance(paths, str):
        paths = paths.split(":")
    paths = [os.path.realpath(p) for p in paths]
    cwd = os.path.realpath(os.path.curdir)
    if cwd not in paths:
        paths.insert(0, cwd)

    return paths


def resolve(filename, paths=()):
    '''
    Resolve filename against paths.

    Return None if fail to locate file.
    '''
    paths = list(paths)
    if not filename:
        raise ValueError("no file name provided")
    if filename.startswith('/'):
        return filename
    if filename.endswith(".jsonnet"):
        paths.insert(0, os.path.join(os.path.dirname(__file__),
                                     "jsonnet-code"))
    if filename.endswith(".j2"):
        paths.insert(0, os.path.join(os.path.dirname(__file__),
                                     "templates"))

    for maybe in clean_paths(paths):
        fp = os.path.join(maybe, filename)
        if os.path.exists(fp):
            return fp
    raise ValueError(f"file not found: {filename}")


# def deref(data, path=None):
#     defs = data.pop("definitions")
#     data = deref_defs(data, defs)
#     if path in ("yes", "true"):
#         return data
#     return select_path(data, path)


def deref_defs(ctx, defs):
    '''
    Convert special form substructure:

    {"$ref":"#/definitions/<def>"}

    To the value of attribute <def> of defs.
    '''
    if type(ctx) in [int, float, str, bool]:
        return ctx
    if isinstance(ctx, list):
        return [deref_defs(ele, defs) for ele in ctx]
    ret = dict()
    for key, val in ctx.items():
        if isinstance(val, dict) and "$ref" in val:
            ref = val["$ref"]
            ref = ref[len("#/definitions/"):]
            val = select_path(defs, ref, "/")
        ret[key] = deref_defs(val, defs)
    return ret


def tla_pack(tlas, jpath):
    '''Pack list of things like var=value or var=file.jsonnet into
    keyword arguments suitable for passing to jsonnet.  A value is
    guessed to be either Jsonnet code or a simple string.
    '''
    tla_vars = dict()
    tla_codes = dict()
    for one in tlas:
        k,v = one.split("=",1)


        chunks = v.split(".")
        if len(chunks) > 1:
            ext = chunks[-1]
            if ext in [".jsonnet", ".json"]:
                fname = resolve(v, jpath)
                tla_codes[k] = open(fname).read()
            elif ext in moo.known_extensions:
                v = moo.io.load(v, jpath)
                tla_codes[k] = json.dumps(v)

        elif v[0] in '{["]}':   # inline code
            tla_codes[k] = v;   
        else:                   # string
            tla_vars[k] = v

    # these keywords are what jsonnet.evaluate_file() expects
    return dict(tla_vars=tla_vars, tla_codes=tla_codes)


def transform(model, transforms):
    '''Transform a model

    The transform may be a single transform or a sequence of
    transforms.  As a sequence it represents a pipeline.  First
    transform is applied to model and its result is passed into
    the second, etc.

    A transform may be a string or a callable.  If a callable, it is
    applied as-is.

    If the transform is a string it is interpreted as:

        [<prefix>:][<modmeth>[|<modmeth>|...]]

    The <prefix> is a JSON Pointer into the model and if not given
    refers to the entire model.  For details about JSON Pointer see
    https://tools.ietf.org/html/rfc6901

    The <modmeth> is a dotted-path of modules with a final leaf that
    is a function.  The modules must be available and the function
    must take a single argument, which is the model (or pointed
    portion if <prefix>) is used and the function must return a stat
    strucutre.

    If multiple <modmeth> are provided, separated by a pipe ("|"), the
    output of one provides the input to the next.

    An example which applies three consecutive transforms to the first
    element of a "types" array.

        /types/0:moo.oschema.typify|moo.oschema.graph|moo.schema.namespacify

    If a pipeline gets much longer, best to provide it in a Python module.

    '''
    from collections.abc import Sequence
    if not transforms:
        return model
    if not isinstance(transforms, Sequence):
        transforms = [transforms]
    for t in transforms:
        if isinstance(t, str):
            t = transform_parse(t)
        model = t(model)
    return model


def graft(model, pointer, branch):
    '''Add branch to model at pointer.

    Note, pointer must have already support in model.  Ie, there is no
    'mkdir'.

    '''
    if not pointer:
        return branch
    return jsonpointer.set_pointer(model, pointer, branch)


def parse_ptr_spec(text):
    '''
    Parse pointer spec as used by CLI
    '''
    parts = text.split(":",1)
    if len(parts) == 2:
        return parts
    return "", parts[0]


def transform_parse(tspec):
    '''
    Parse transform spec.  See @ref tranform() for details
    '''
    ptr, tspec = parse_ptr_spec(tspec)

    meths = list()
    for modmeth in tspec.split("|"):
        parts = modmeth.rsplit(".", 1)
        if len(parts) != 2:
            raise RuntimeError("transform should a '.' path to a function")
        mod = importlib.import_module(parts[0])
        meth = getattr(mod, parts[1])
        meths.append(meth)

    def trans(model):
        branch = jsonpointer.resolve_pointer(model, ptr)
        for meth in meths:
            branch = meth(branch)
        model = graft(model, ptr, branch)
        return model
    return trans

