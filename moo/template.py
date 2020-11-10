import os
from jinja2 import meta, Environment, FileSystemLoader

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


def find_type(types, fqn):
    'In list of types return one with matching fully qualified name'
    path, name = fqn.rsplit('.', 1)
    for typ in types:
        if '.'.join(typ['path']) == path and typ['name'] == name:
            return typ
    print(types)
    raise KeyError(f"no such type: {type(fqn)} {fqn}")


# fixme: move this into a sub-module and make available to template as
# cpp.*, also add in what is provided by ocpp.jsonnet now.
# maybe needs template.py to be made template/__init__.py
# and then move language support under temlate/lang/cpp.py
def cpp_literal_value(types, fqn, val):
    '''Convert val of type typ to a C++ literal syntax.'''
    typ = find_type(types, fqn)
    schema = typ['schema']
    print("literal:", typ, schema, type(val), val)

    if schema == "sequence":
        if val is None:
            return '{}'
        seq = ', '.join([cpp_literal_value(types, typ['items'], ele) for ele in val])
        return '{%s}' % seq

    if schema == "number":
        # fixme truncate if int?
        if val is None:
            return "0"
        return f'{val}'

    if schema == "string":
        if val is None:
            return '""'
        return f'"{val}"'

    if schema == "enum":
        if val is None:
            val = typ.get('default', None)
        if val is None:
            val = typ.symbols[0]
        nsp = list(typ['path']) + [typ['name'], val]
        return '::'.join(nsp)

    if schema == "record":
        val = val or dict()
        seq = list()
        for f in typ['fields']:
            fval = val.get(f['name'], f.get('default', None))
            if fval is None:
                break
            cppval = cpp_literal_value(types, f['item'], fval)
            seq.append(cppval)
        return '{%s}' % (', '.join(seq))

    if schema == "any":
        return '{}'

    return val                  # go fish


def cpp_field_default(types, field):
    'Return a field default as C++ syntax'
    return cpp_literal_value(types, field['item'], field.get('default', None))


def make_env(path):
    'Create and return Jinja environment for template at path'
    env = Environment(loader=FileSystemLoader(path),
                      trim_blocks=True,
                      lstrip_blocks=True,
                      extensions=['jinja2.ext.do', 'jinja2.ext.loopcontrols'],
                      **get_style(path))
    env.globals.update(find_type=find_type,
                       cpp_literal_value=cpp_literal_value,
                       cpp_field_default=cpp_field_default)
    return env


def render(template, params):
    'Render template against dictionary of parameters'
    path = os.path.dirname(os.path.realpath(template))
    env = make_env(path)
    tmpl = env.get_template(os.path.basename(template))
    return tmpl.render(**params)


def imports(template, tpath=None):
    'Return all files imported by template'
    path = os.path.dirname(os.path.realpath(template))
    env = make_env(path)
    ast = env.parse(open(template, 'rb').read().decode())
    subs = meta.find_referenced_templates(ast)
    return [os.path.join(path, one) for one in subs]
