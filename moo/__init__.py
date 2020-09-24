import moo.jsonnet
import moo.template
import moo.util
import moo.io
import moo.csv


def imports(filename, path):
    if filename.endswith('.jsonnet'):
        return moo.jsonnet.imports(filename, path)
    if filename.endswith('.j2'):
        return moo.template.imports(filename, path)
    raise ValueError(f'unknown file type: {filename}')
