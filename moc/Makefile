all: test_demo

demo_config.json: demo_config.jsonnet
	moo compile -P model.avro $< > $@

demo_config.hpp: demo_config.json 
	$(HOME)/opt/avro/bin/avrogencpp -n moc -i $< -o $@

demo_config_nljs.hpp: demo_config.jsonnet avro_nljs.hpp.j2 
	moo render -P model.nljs $^ > $@

test_demo: test_demo.cpp demo_config.hpp demo_config_nljs.hpp
	g++ -Wall -o $@ $< -I ../inc -I. -I$(HOME)/opt/avro/include -L$(HOME)/opt/avro/lib -lavrocpp


clean:
	rm -f demo_config.json demo_config.hpp demo_config_nljs.hpp test_demo
