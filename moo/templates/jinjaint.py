import os
from jinja2 import meta, Environment, FileSystemLoader

from . import cpp
from .util import find_type, listify, relpath

styles = dict(
    normal=dict(),
    latex=dict(comment_start_string='~{#',
               comment_end_string='#}~',
               block_start_string='~{',
               block_end_string='}~',
               variable_start_string='~{{',
               variable_end_string='}}~')
)


def get_style(filename):
    'Return the markup style to use for a template file'
    style = "normal"
    if '.tex' in filename:
        style = "latex"
    return styles[style]



def make_env(path, **kwds):
    'Create and return Jinja environment for template at path'
    env = Environment(loader=FileSystemLoader(path),
                      trim_blocks=True,
                      lstrip_blocks=True,
                      extensions=['jinja2.ext.do', 'jinja2.ext.loopcontrols'],
                      **kwds)
    env.filters["listify"] = listify
    env.filters["relpath"] = relpath
    env.globals.update(find_type=find_type,
                       cpp=cpp)
    return env


def make_path(template, tpath = None):
    'Build template search path from representative template and existing'
    path = tpath or list()
    path = list(path)
    path.insert(0, os.path.dirname(os.path.realpath(template)))
    return path

def render(template, model, tpath=None):
    'Render template against dictionary of model parameters'
    path = make_path(template, tpath)
    style_params = get_style(template)
    env = make_env(path, **style_params)
    tmpl = env.get_template(os.path.basename(template))
    return tmpl.render(**model)


from moo.util import resolve
def imports(template, tpath=None):
    'Return all files imported by template'
    # env = env_from_tmplfile(template, tpath)
    # ...
    path = make_path(template, tpath)
    style_params = get_style(template)
    env = make_env(path, **style_params)
    ast = env.parse(open(template, 'rb').read().decode())
    subs = meta.find_referenced_templates(ast)
    ret = [resolve(one) for one in subs]
    return ret
