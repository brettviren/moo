#!/usr/bin/env python3

def select_path(obj, path):
    '''Select out a part of obj structure based on a path.

    The path is a list or a "."-separated string.

    Any element of the path that looks like an integer will be cast to
    one assuming it indexes an array.

    '''
    if isinstance(path, str):
        path = path.split('.')
    for one in path:
        if not one:
            break
        try:
            one = int(one)
        except ValueError:
            pass
        obj = obj[one]

    return obj
