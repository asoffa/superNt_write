
.PHONY : all clean scripts


all : bin/make_superNt bin/wipe scripts


bin/%: %.cr
	@echo 'Making `./$@`...'
	@mkdir -p ./bin
	@crystal build $< -o $@ --release


scripts :
	@chmod +x *.sh


clean :
	@rm -f bin/*

