import moo.jsonnet
import moo.template
import moo.util
import moo.io
import moo.csvio
import moo.oschema
import moo.otypes
from moo.version import version

__version__ = version

known_extensions = ["jsonnet", "json", "csv", "xml", "yaml", "ini"]
try:
    import moo.xls
except ImportError:
    print("moo: no support for loading spreadsheets")
else:
    known_extensions += ["xls", "xlsx"]


def imports(filename, path):
    'Return list of files imported by a file'
    if filename.endswith('.jsonnet'):
        return moo.jsonnet.imports(filename, path)
    if filename.endswith('.j2'):
        return moo.template.imports(filename, path)
    raise ValueError(f'unknown file type: {filename}')
