#!/usr/bin/env waf

import time
# fixme: better to be a waf tool
import moo
from waflib.Task import Task
from waflib.TaskGen import taskgen_method, extension

APPNAME = 'moo'

def options(opt):
    opt.load('compiler_cxx')    

def configure(cfg):
    cfg.env.CXXFLAGS += ['-std=c++17', '-ggdb3',
                         '-Wall', '-Wpedantic', '-Werror']
    cfg.load('compiler_cxx')
    cfg.find_program('moo', var='MOO', mandatory=True)
    cfg.find_program('clang-format', var='CLANG_FORMAT', mandatory=False)
    p = dict(mandatory=True, args='--cflags --libs')
    cfg.check_cfg(package='libzmq', uselib_store='ZMQ', **p);


class codegen(Task): 
    color   = 'PINK'

    def run(self):
        model = self.inputs[0]
        templ = self.inputs[1]
        data = moo.jsonnet.load(model.abspath(), ('.'))
        text = moo.template.render(templ.abspath(), data)
        with open(self.outputs[0].abspath(), 'wb') as fp:
            fp.write(text.encode())

        

    def scan(self):
        deps = list()
        print(f"scan: {self.inputs}")
        for maybe in self.inputs:
            if not maybe.name.endswith('.jsonnet'):
                continue
            print("maybe:", type(maybe), maybe.abspath())
            extra = moo.jsonnet.imports(maybe.abspath()) # need to give a JPATH
            print ("extra:", type(extra), extra)
            for one in extra:
                node = self.generator.bld.root.find_resource(one)
                assert(node)
                print ("extra node:", node)
                deps.append(node)
        print (f'DEPS: {deps}')
        return (deps,time.time())


@extension('.jsonnet')
def add_jsonnet_deps(tgen, model):
    print (f'TGEN {tgen}')
    tgt = tgen.bld.path.find_or_declare(tgen.target)
    print (type(model),model)
    tmpl = tgen.bld.path.find_resource(tgen.template)
    print (type(tmpl), tmpl)
    print (type(tgt), tgt)
    tsk = tgen.create_task('codegen', [model, tmpl], tgt)


def build(bld):

    bld(source="examples/echo-ctxsml.jsonnet",
        template="templates/ctxsml.hpp.j2",
        target="echo-ctxsml.hpp")
