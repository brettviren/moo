#!/usr/bin/env python3
'''
Generate artifacts from models.
'''
import os
import sys
import jsonnet
from jinja2 import Environment, FileSystemLoader

def render_protobuf(template, params):
    env =  Environment(loader = FileSystemLoader(os.path.dirname(template)))
    tmpl = env.get_template(os.path.basename(template))
    return tmpl.render(**params)


for one in sys.argv[1:]:
    dat = jsonnet.load(one)

    render = eval("render_" + dat["renderer"])
    text = render(dat["template"], dat["params"])
    open(dat["artifact"], 'w').write(text.encode('utf-8'))


