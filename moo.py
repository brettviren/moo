#!/usr/bin/env python3
'''
Generate artifacts from models.
'''
import os
import sys
import jsonnet
from jinja2 import Environment, FileSystemLoader

def render_default(template, params):
    path = os.path.dirname(os.path.realpath(template))
    path = os.path.join(path, "templates")

    env =  Environment(loader = FileSystemLoader(path),
                       extensions=['jinja2.ext.do'])
                       
    tmpl = env.get_template(os.path.basename(template))
    return tmpl.render(**params)



for one in sys.argv[1:]:
    dat = jsonnet.load(one)

    if isinstance(dat, dict):
        dat = [dat]
    for onedat in dat:
        render = eval("render_" + onedat.get("renderer", "default"))
        text = render(onedat["template"], onedat["params"])
        output = onedat["artifact"]
        open(onedat["artifact"], 'wb').write(text.encode('utf-8'))
        print (output)

