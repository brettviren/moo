all: test_demo.log test_demo2.log

demo_config.json: demo_config.jsonnet
	moo compile -P model.avro $< > $@
demo_app.json: demo_config.jsonnet
	moo compile -P app.avro $< > $@

%.hpp: %.json 
	$(HOME)/opt/avro/bin/avrogencpp -n moc -i $< -o $@

demo_config_nljs.hpp: demo_config.jsonnet avro_nljs.hpp.j2 
	moo render -P model.nljs $^ > $@
demo_app_nljs.hpp: demo_config.jsonnet avro_nljs.hpp.j2 
	moo render -P app.nljs $^ > $@

test_%: test_%.cpp demo_config.hpp demo_config_nljs.hpp demo_app.hpp demo_app_nljs.hpp
	g++  -ggdb3 -std=c++17 -Wall -o $@ $< \
           -I ../inc -I. -I$(HOME)/opt/avro/include \
           -L$(HOME)/opt/avro/lib -lavrocpp \
           -Wl,-rpath=$(HOME)/opt/avro/lib

# Our actual configuration is presented as a stream of JSON objects.
# We simply concatenate the individual files.
# https://en.wikipedia.org/wiki/JSON_streaming#Concatenated_JSON


demo_config_node.json: demo_config.jsonnet
	moo compile -P objects.mynode $< > $@
demo_config_app.json: demo_config.jsonnet
	moo compile -P objects.mysource $< > $@
demo_config_objects.json: demo_config_node.json demo_config_app.json
	cat $^ > $@


%.log: % demo_config_objects.json 
	./$< > $@
	cat $@

clean:
	rm -f demo_config.json demo_config.hpp demo_config_nljs.hpp test_demo test_demo2
	rm -f demo_config_objects.json test_demo.log
	rm -f demo_app_nljs.hpp demo_app.hpp demo_app.json
	rm -f demo_config_app.json demo_config_node.json 
