.PHONY: clean purge

deps:
	@carton install --deployment

debian:
	@./dpkg-build.pl

clean:
	@rm -rf debuild

purge: clean
