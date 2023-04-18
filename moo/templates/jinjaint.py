import os
from jinja2 import meta, Environment, FileSystemLoader

from . import cpp
from . import python
from . import jsonnet
from .util import find_type, listify, relpath, debug
from moo.util import search_path

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
    env.filters['debug'] = debug
    env.globals.update(find_type=find_type,
                       cpp=cpp, py=python, jsonnet=jsonnet)
    return env


# def make_path(template, tpath = None):
#     'Build template search path from representative template and existing'
#     path = tpath or list()
#     path = list(path)
#     for bi in search_path(template):
#         if bi not in path:
#             path.append(bi)
#     return path

def render(template, model, tpath=None):
    'Render template against dictionary of model parameters'
    path = search_path(template, tpath)
    style_params = get_style(template)
    env = make_env(path, **style_params)
    tmpl = env.get_template(os.path.basename(template))
    return tmpl.render(**model)


from moo.util import resolve
def imports(template, tpath=None):
    'Return all files imported by template'
    #print(f'jinja imports for {template} with {tpath}')
    path = search_path(template, tpath)
    style_params = get_style(template)
    env = make_env(path, **style_params)
    ast = env.parse(open(template, 'rb').read().decode())
    subs = meta.find_referenced_templates(ast)
    # Note: this probably violates Jinja API as the env does not
    # expose the loader and certainly not its type.  But, we make the
    # loader so let's use it to make sure it knows how to find imports
    # correctly.  If this breaks, then we instead may pass tpath to
    # moo's resolve().
    return [env.loader.get_source(env, s)[1] for s in subs]
    # ret = [resolve(one) for one in subs]
    # return ret
