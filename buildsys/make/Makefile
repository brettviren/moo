# The automatic dependency technique here is simplified from
# http://make.mad-scientist.net/papers/advanced-auto-dependency-generation/
all: model-dump.txt

model-dump.txt : model.jsonnet dump.txt.j2 model-dump.txt.d
	moo render-deps -t $@ -o model-dump.txt.d model.jsonnet dump.txt.j2
	moo render -o $@ model.jsonnet dump.txt.j2

model-dump.txt.d: ;

clean:
	rm -f model-dump.txt model-dump.txt.d

.PHONY: clean all

# The apparently-superfluous use of "wildcard" here prevents a warning
# on the first build that model-dump.txt.d doesn't exist
include $(wildcard model-dump.txt.d)
