## this demos some low level testing stuff.



all: test_demo.log test_demo2.log

demo_config.json: demo_config.jsonnet
	moo compile -P model.avro $< > $@
demo_app.json: demo_config.jsonnet
	moo compile -P app.avro $< > $@

%.hpp: %.json 
	$(AVROGENCPP) -n moc -i $< -o $@

demo_config_nljs.hpp: demo_config.jsonnet avro_nljs.hpp.j2 
	moo render -P model.nljs $^ > $@
demo_app_nljs.hpp: demo_config.jsonnet avro_nljs.hpp.j2 
	moo render -P app.nljs $^ > $@

test_%: test_%.cpp demo_config.hpp demo_config_nljs.hpp demo_app.hpp demo_app_nljs.hpp
	g++  -ggdb3 -std=c++17 -Wall -o $@ $< \
           -I ../inc -I. -I$(HOME)/opt/avro/include \
           -L$(HOME)/opt/avro/lib -lavrocpp \
           -Wl,-rpath=$(HOME)/opt/avro/lib

demo_config_node.json: demo_config.jsonnet
	moo compile -P objects.mynode $< > $@
demo_config_app.json: demo_config.jsonnet
	moo compile -P objects.mysource $< > $@
demo_config_objects.json: demo_config_node.json demo_config_app.json
	cat $^ > $@


test_demo.log: test_demo demo_config_objects.json 
	./test_demo demo_config_objects.json > $@
	cat $@
test_demo2.log: test_demo2 demo_config_objects.json 
	./test_demo2 demo_config_objects.json json > $@
	cat $@

clean:
	rm -f \
		demo_config.json demo_config_objects.json \
		demo_config_app.json demo_config_node.json \
		demo_app.json \
		demo_config.hpp demo_config_nljs.hpp \
		demo_app_nljs.hpp demo_app.hpp \
		test_demo test_demo2 \
		test_demo.log test_demo2.log
