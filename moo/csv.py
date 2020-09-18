import csv

def load(filename, paths, **kwds):
    '''
    Load a CSV file.

    Return an array of objects.

    Objects have key names as given in the first column.
    '''
    head = None
    ret = list()
    for row in csv.reader(open(filename)):
        if head is None:
            head = [r.strip() for r in row]
            continue
        one = {k:v for k,v in zip(head, row)}
        ret.append(one)
    return ret

