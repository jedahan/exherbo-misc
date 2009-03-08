all:	$(addsuffix .html,$(basename $(wildcard *.mkd)))
	@echo $?

%.html:	%.mkd
	@echo "Generating $@ ..."
	@maruku --html --output www/$@ $<

clean:
	rm -f {,*/}*.html
