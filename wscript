#!/usr/bin/env waf
import os
import time
# fixme: better to be a waf tool
import moo
from waflib.Task import Task
from waflib.TaskGen import taskgen_method, extension, declare_chain

APPNAME = 'moo'

def options(opt):
    opt.load('compiler_cxx')    

def configure(cfg):
    cfg.env.CXXFLAGS += ['-std=c++17', '-ggdb3',
                         '-Wall', '-Wpedantic', '-Werror']
    cfg.load('compiler_cxx')
    cfg.find_program('moo', var='MOO', mandatory=True)
    cfg.find_program('dot', var='DOT', mandatory=True)
    cfg.find_program('clang-format', var='CLANG_FORMAT', mandatory=False)
    p = dict(mandatory=True, args='--cflags --libs')
    cfg.check_cfg(package='libzmq', uselib_store='ZMQ', **p);


class codegen(Task): 
    color   = 'PINK'

    def run(self):
        model = self.inputs[0]
        templ = self.inputs[1]
        top = self.generator.bld.path.abspath()
        mpath = [os.path.join(top, "models")]
        data = moo.jsonnet.load(model.abspath(),mpath)
        text = moo.template.render(templ.abspath(), data)
        with open(self.outputs[0].abspath(), 'wb') as fp:
            fp.write(text.encode())

    def scan(self):
        deps = list()
        for maybe in self.inputs:
            extra = list()
            top = self.generator.bld.path.abspath()
            mpath = [os.path.join(top, "models")]
            tpath = [os.path.join(top, "templates")]
            if maybe.name.endswith('.jsonnet'):
                extra = moo.jsonnet.imports(maybe.abspath(),mpath)
            if maybe.name.endswith('.j2'):
                extra = moo.template.imports(maybe.abspath(),tpath)
            for one in extra:
                node = self.generator.bld.root.find_resource(one)
                deps.append(node)
        return (deps,time.time())


@extension('.jsonnet')
def add_jsonnet_deps(tgen, model):
    assert(model)
    tgt = tgen.bld.path.find_or_declare(tgen.target)
    assert(tgt)
    tmpl = tgen.bld.path.find_resource(tgen.template)
    if not tmpl:
        raise ValueError(f"file not found: {tgen.template}")
    tsk = tgen.create_task('codegen', [model, tmpl], tgt)


@extension('.dot')
def make_dotters(tgen, dot):
    for ext in ["png", "pdf", "svg"]:
        out = dot.change_ext('.'+ext)
        tsk = tgen.create_task('dotter', dot, [out])
        tsk.env.DOT_FMT=ext


class dotter(Task):
    run_str = "${DOT} -T${DOT_FMT} -o ${TGT} ${SRC}"


def build(bld):

    # need to generate target file name with like:
    # moo compile -S -p classname models/yodel/codec.jsonnet
    bld(source="models/yodel/codec.jsonnet",
        template=f"templates/codec.hpp.j2",
        target=f"mex/YodelCodec.hpp")
    bld(source="models/yodel/codec.jsonnet",
        template=f"templates/codec.cpp.j2",
        target="src/YodelCodec.cpp")
    bld(source="models/yodel/codec.jsonnet",
        template=f"templates/test_codec.cpp.j2",
        target="test/test_YodelCodec.cpp")

    cpps = bld.path.ant_glob('src/*.cpp')
    cpps += [bld.path.find_or_declare("src/YodelCodec.cpp")]

    # for tmpl in 'ctxsml states messages json_messages'.split():
    #     bld(source=f"examples/{ns}-ctxsml.jsonnet",
    #         template=f"templates/{tmpl}.hpp.j2",
    #         target=f"{ns}/{tmpl}.hpp")

    # bld(source=f"examples/{ns}-ctxsml.jsonnet",
    #     template="templates/ctxsml.dot.j2",
    #     target=f"{ns}-ctxsml.dot")

    # bld(source=f"{ns}-ctxsml.dot")


    bld.shlib(features="cxx",
              includes='. inc build',
              source = cpps,
              target = APPNAME.lower(),
              use='ZMQ',
              uselib_store=APPNAME.upper())
    
    rpath = [bld.env["PREFIX"] + '/lib', bld.path.find_or_declare(bld.out_dir)]

    bld.program(features="cxx",
                source="test/test_YodelCodec.cpp",
                target="test/test_YodelCodec",
                includes='. inc build',
                rpath=rpath,
                use='MOO ZMQ moo')
