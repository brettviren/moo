import os
from jinja2 import meta, Environment, FileSystemLoader

styles = dict(
    normal = dict(),
    latex = dict(comment_start_string = '~{#',
                 comment_end_string = '#}~',
                 block_start_string='~{',
                 block_end_string='}~',
                 variable_start_string='~{{',
                 variable_end_string='}}~')
)

def get_style(filename):
    style = "normal"
    if '.tex' in filename:
        style = "latex"
    return styles[style]


def render(template, params):
    path = os.path.dirname(os.path.realpath(template))
    env =  Environment(loader = FileSystemLoader(path),
                       trim_blocks = True, 
                       lstrip_blocks = True,
                       extensions=['jinja2.ext.do', 'jinja2.ext.loopcontrols'],
                       **get_style(template))
    tmpl = env.get_template(os.path.basename(template))
    return tmpl.render(**params)

def imports(template, tpath):
    path = os.path.dirname(os.path.realpath(template))
    
    env =  Environment(loader = FileSystemLoader([path]+list(tpath)),
                       trim_blocks = True, 
                       lstrip_blocks = True,
                       extensions=['jinja2.ext.do', 'jinja2.ext.loopcontrols'],
                       **get_style(template))
    ast = env.parse(open(template,'rb').read().decode())
    subs = meta.find_referenced_templates(ast)
    return [os.path.join(path,one) for one in subs]

