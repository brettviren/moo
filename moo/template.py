import os
from jinja2 import Environment, FileSystemLoader

def render(template, params):
    path = os.path.dirname(os.path.realpath(template))

    env =  Environment(loader = FileSystemLoader(path),
                       trim_blocks = True, 
                       lstrip_blocks = True,
                       extensions=['jinja2.ext.do'])
                       
    tmpl = env.get_template(os.path.basename(template))
    return tmpl.render(**params)

