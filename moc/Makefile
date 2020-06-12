AVROGENCPP := avrogencpp
AVROINC := -I$(HOME)/opt/avro/include
AVROLIB := -L$(HOME)/opt/avro/lib -lavrocpp -Wl,-rpath=$(HOME)/opt/avro/lib

namespace = moc

avro_json := node_avro.json demo_avro.json
avro_hpp = $(patsubst %.json,%.hpp,$(avro_json))
nljs_hpp := node_nljs.hpp demo_nljs.hpp
all_hpp = $(avro_hpp) $(nljs_hpp)


all: demo.log

# demo:AVRO schema and generate C++ 
%_avro.json: %.jsonnet 
	moo compile -P avro $< > $@
%_avro.hpp: %_avro.json
	$(AVROGENCPP) -n $(namespace) -i $< -o $@

# demo:NLJS generated C++ 
%_nljs.hpp: %.jsonnet avro_nljs.hpp.j2 
	moo render -P nljs $^ > $@

# demo:config generated configuration data
demo-config.json: demo.jsonnet
	moo compile --string -P demo.stream demo.jsonnet > demo-config.json


demo: demo.cpp $(all_hpp)
	g++  -ggdb3 -std=c++17 -Wall -o $@ $< \
           -I ../inc -I. $(AVROINC) $(AVROLIB)

demo.log: demo demo-config.json
	./demo demo-config.json > demo.log
	cat demo.log

clean:
	rm -f demo demo.log demo-config.json $(all_hpp)
