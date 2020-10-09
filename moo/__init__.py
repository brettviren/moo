import moo.jsonnet
import moo.template
import moo.util
import moo.io
import moo.csv

known_extensions = ["jsonnet", "json", "csv", "xml", "yaml", "ini"]
try:
    import moo.xls
except ImportError:
    print("moo: no support for loading spreadsheets")
    pass
else:
    known_extensions += ["xls", "xlsx"]

def imports(filename, path, style=None):
    if filename.endswith('.jsonnet'):
        return moo.jsonnet.imports(filename, path)
    if filename.endswith('.j2'):
        return moo.template.imports(filename, path, style)
    raise ValueError(f'unknown file type: {filename}')
