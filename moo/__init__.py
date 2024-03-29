import moo.jsonnet
import moo.templates
import moo.util
import moo.io
import moo.csvio
import moo.oschema
import moo.otypes
import moo.ovalid
import moo.jsonschema
from moo.version import version

__version__ = version

# note: schema is an alias for jsonnet
known_extensions = ["jsonnet", "json", "csv", "xml", "yaml", "ini",
                    "schema"]
try:
    import moo.xls
except ImportError:
    print("moo: no support for loading spreadsheets")
else:
    known_extensions += ["xls", "xlsx"]


def imports(filename, path, **kwds):
    '''Return list of files imported by a file
    
    The file type is guessed and a corresponding import scan is run. 

    For Jsonnet files, kwds may provide TLAs.
    '''
    if filename.endswith('.jsonnet'):
        return moo.jsonnet.imports(filename, path, **kwds)
    if filename.endswith('.j2'):
        return moo.templates.imports(filename, path)
    raise ValueError(f'unknown file type: {filename}')
