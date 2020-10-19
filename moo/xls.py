'''
Load spreadsheets
'''
from openpyxl import load_workbook

def load(filename, paths, **kwds):
    '''Load spreadsheet

    Return array of objects.

    Each object is a row with keys associated to columns, and named
    based on first non-empty row.

    Note, follows the same pattern as moo.csvio.load().
    '''

    wb = load_workbook(filename)
    sheet = list(wb)[0]

    head = None
    ret = list()

    for row in sheet:
        if head is None:
            head = [c.value.strip() for c in row]
            continue
        one = {k:v.value for k,v in zip(head, row)}
        if all([v is None for v in one.values()]):
            continue

        ret.append(one)
    return ret
