model-dump.txt : model.jsonnet dump.txt.j2 
	moo render -o $@ $^
clean:
	rm -f model-dump.txt
