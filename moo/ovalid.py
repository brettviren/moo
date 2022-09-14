#!/usr/bin/env python3
'''
Methods to validate models against schema.
'''

import moo.jsonschema 

from moo.jsonschema import ValidationError

def validate(models, targets, context=None, throw=True, validator="jsonschema"):
    '''
    Validate models against schema.

    The targets are either oschema objects relying on a larger oschema context (eg, for resolving dependencies) or are pre-made, self-contained JSON Schema objects.

    Models and targets may be each a single object or matched sequences of objects.

    By default, a Boolean is returned (or sequence thereof) indicating validity.

    If "throw" is True, a ValueError is raised on first failure and only return True (or sequence or True) may be returned.

    The validator string names the validation engine to use in ("jsonschema", "fastjsonschema").
    '''
    sequence = True
    if not isinstance(targets, (list,tuple)):
        sequence = False
        models = [models]
        targets = [targets]

    res = list()
    for model, target in zip(models, targets):

        js = moo.jsonschema.convert(target, context)

        if throw:
            moo.jsonschema.validate(model, js, validator)
            res.append(True)
            continue
        try:
            moo.jsonschema.validate(model, js, validator)
        except ValidationError:
            res.append(False)
        else:
            res.append(True)

    if sequence:
        return res
    return res[0]
