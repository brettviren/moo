#!/usr/bin/env python
'''A mock up of a process manager.

It works by taking a boot command and producing a foreman/shoreman
conf file.

Do not look upon this code as an example to follow for anything real!
'''
import os
import sys
import json


# dumbest possible mock of Nomad
backend = dict(
    zone_hosts = dict(local="localhost", remote="localhost"),
    zone_launch = dict(local=None, remote="ssh {user}@{hostname}"),
    role_cmds = (
        ("zzz", "sleep {sleeps}"),
        ("appfwk", "daq_application --commandFacility=http://{hostname}:{port}"),
    ))

def get_params(job):
    params = job.get('parameters',[])
    params = {p['key']:p['value'] for p in params}
    # a real system would set user based on role
    params['user'] = os.environ['USER']
    return params

# well, of course this should be handed smarter than we do here
next_port=9000

boot = json.loads(open(sys.argv[1],'rb').read().decode())
part_ident = boot['ident']
part_summary = list()
jobs = boot['jobs']
lines = list()
for job in jobs:
    job_ident = job['ident']    # required
    roles = job['roles']        # required
    params = get_params(job)    # role-specific

    job_summary = list()

    zone = "local"
    if "zoned" in roles:
        zone = params['zone']
    zl = backend['zone_launch'][zone]

    for index in range(job.get('cardinality', 1)):
        taskname=f'{job_ident}-{index:03d}'


        # something more real might select on a per-host, per-role port range.
        params['port'] = next_port
        next_port += 1

        # something more real might select based on some pool
        params['hostname'] = backend['zone_hosts'][zone]

        # Iterate known roles to build up some command.  Here, this is
        # simple aggregation but roles may also be interpreted to
        # provide some partial command line info of a single command.
        # Every role implies some data structure we must make
        # available keyed by job and task name
        cmds=list()
        for role_maybe, role_cmd in backend['role_cmds']:
            if role_maybe not in roles:
                continue
            cmd = role_cmd.format(**params)
            cmds.append(cmd)

        cmdline=' && '.join(cmds)

        # something more real might use some kind of service-based launcher
        if zl:                  # here we maybe simply ssh
            zl = zl.format(**params)
            payload = f'{zl} "{cmdline}"'
        else:
            payload = f'{cmdline}'
        line = f'{taskname}: {payload}'
        lines.append(line)

        task_summary=dict(ident=taskname, cmds=cmds, zl=zl, params=params)
        job_summary.append(task_summary)
    part_summary.append(job_summary)


text = '\n'.join(lines) + '\n'
pfile = f'Procfile.{part_ident}'
open(pfile,'wb').write(text.encode())
print(f'wrote: {pfile}')

text = json.dumps(part_summary, indent=4)
jfile = f'{part_ident}-data.json'
open(jfile,'wb').write(text.encode())
print(f'wrote: {jfile}')
