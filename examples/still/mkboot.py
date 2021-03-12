#!/usr/bin/env python3
'''
Make a test boot object.
'''

import os
import json
import moo.otypes
here = os.path.dirname(os.path.realpath(__file__))
moo.io.default_load_path.append(here)
moo.otypes.load_types("still-boot-schema.jsonnet")

from still.boot import *

job1 = Job(ident="job1", roles=["zoned", "zzz"], cardinality=2,
           parameters=[Parameter(key="zone",value="local"),
                       Parameter(key="sleeps", value="20")])
job2 = Job(ident="job2", roles=["zoned", 'appfwk'], cardinality=2,
           parameters=[Parameter(key="zone",value="remote")])
boot = Boot(ident="p42",        # set by some external SSOT
            jobs=[job1, job2])

text = json.dumps(boot.pod(), indent=4)
jfile = f'{boot.ident}-boot.json'
open(jfile,'wb').write(text.encode())
print(f'wrote: {jfile}')
