
.PHONY : clean


bin/make_superNt : make_superNt.cr
	@echo "Making ./bin/$< ..."
	@mkdir -p ./bin
	@crystal build $< -o $@ --release


clean :
	@rm -f bin/*

