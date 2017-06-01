
.PHONY : all clean scripts


all : bin/make_superNt scripts


bin/make_superNt : make_superNt.cr
	@echo "Making ./bin/$< ..."
	@mkdir -p ./bin
	@crystal build $< -o $@ --release


scripts :
	@chmod +x *.sh


clean :
	@rm -f bin/*

