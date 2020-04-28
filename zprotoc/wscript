#!/usr/bin/env waf

APPNAME = 'moo'


def options(opt):
    opt.load('compiler_cxx')    

def configure(cfg):
    cfg.env.CXXFLAGS += ['-std=c++17', '-ggdb3',
                         '-Wall', '-Wpedantic', '-Werror']
    cfg.load('compiler_cxx')
    cfg.find_program('j2', var='J2', mandatory=True)
    cfg.find_program('jsonnet', var='JSONNET', mandatory=True)
    cfg.find_program('clang-format', var='CLANG_FORMAT', mandatory=True)
    p = dict(mandatory=True, args='--cflags --libs')
    cfg.check_cfg(package='libzmq', uselib_store='ZMQ', **p);

from waflib.Configure import conf
@conf
def codegen(bld, model):
    model_name = model.name.replace('.jsonnet','')
    model_json = bld.path.find_or_declare(model_name + '.json')
    model_dir = bld.bldnode.make_node(model_name)

    bld(rule='${JSONNET} -o ${TGT} ${SRC}',
        source=model,
        target=model_json)

    def codegen_tasks(ext):
        generated = list()
        for src in bld.path.ant_glob('templates/*.%s.j2'%ext):
            tgt = model_dir.find_or_declare(src.name.replace('.j2',''))
            generated.append(tgt)
            bld(rule='${J2} -o ${TGT} -f json ${SRC[0].abspath()} ${SRC[1].abspath()} && ${CLANG_FORMAT} -i ${TGT}',
                source = [src, model_json],
                target = tgt, shell=True)
        return generated

    headers = codegen_tasks("hpp")
    sources = bld.path.ant_glob('src/*.cpp');
    sources += codegen_tasks("cpp")

    bld.shlib(features='cxx', includes='inc build',
              source = sources, target=APPNAME.lower(),
              uselib_store=APPNAME.upper(), use='ZMQ')
    

def build(bld):

    for model in bld.path.ant_glob("models/*.jsonnet"):
        bld.codegen(model)
    
    
