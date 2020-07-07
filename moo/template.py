import os
from jinja2 import meta, Environment, FileSystemLoader

def render(template, params):
    path = os.path.dirname(os.path.realpath(template))
    env =  Environment(loader = FileSystemLoader(path),
                       trim_blocks = True, 
                       lstrip_blocks = True,
                       extensions=['jinja2.ext.do', 'jinja2.ext.loopcontrols'])
    tmpl = env.get_template(os.path.basename(template))
    return tmpl.render(**params)

def imports(template, tpath):
    path = os.path.dirname(os.path.realpath(template))
    
    env =  Environment(loader = FileSystemLoader([path]+list(tpath)),
                       trim_blocks = True, 
                       lstrip_blocks = True,
                       extensions=['jinja2.ext.do', 'jinja2.ext.loopcontrols'])
    ast = env.parse(open(template,'rb').read().decode())
    subs = meta.find_referenced_templates(ast)
    return [os.path.join(path,one) for one in subs]

