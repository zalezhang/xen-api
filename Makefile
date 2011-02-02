ifdef B_BASE
include $(B_BASE)/common.mk
include $(B_BASE)/rpmbuild.mk
REPO=$(call gitloc,xen-api)
else
MY_OUTPUT_DIR ?= $(CURDIR)/output
MY_OBJ_DIR ?= $(CURDIR)/obj
REPO ?= $(CURDIR)

RPM_SPECSDIR?=/usr/src/redhat/SPECS
RPM_SRPMSDIR?=/usr/src/redhat/SRPMS
RPM_SOURCESDIR?=/usr/src/redhat/SOURCES
RPMBUILD?=rpmbuild
XEN_RELEASE?=unknown
endif

COMPILE_NATIVE=yes
COMPILE_BYTE=no # bytecode version does not build
export COMPILE_NATIVE COMPILE_BYTE

.PHONY: all
all: version
	omake phase1
	omake phase2
	omake lib-uninstall
	omake lib-install
	omake phase3

.PHONY: phase3
phase3:
	omake phase3

.PHONY: xapimon
xapimon:
	omake ocaml/xapimon/xapimon

.PHONY: stresstest
stresstest:
	omake ocaml/xapi/stresstest

.PHONY: cvm
cvm:
	omake ocaml/cvm/cvm

.PHONY: install
install:
	omake install

.PHONY: lib-install
lib-install:
	omake DESTDIR=$(DESTDIR) lib-install

.PHONY: lib-uninstall
lib-uninstall:
	omake DESTDIR=$(DESTDIR) lib-uninstall

.PHONY: sdk-install
sdk-install:
	omake sdk-install

.PHONY:patch
patch:
	omake patch

.PHONY: clean
clean:
	omake clean
	omake lib-uninstall
	rm -rf dist/staging
	rm -f .omakedb .omakedb.lock

.PHONY: otags
otags:
	otags -vi -r . -o tags

.PHONY: doc
doc: api-doc api-libs-doc

.PHONY: api-doc
api-doc: version
	omake phase1 phase2 # autogenerated files might be required
	omake doc

.PHONY: api-libs-doc
api-libs-doc:
	@(cd ../xen-api-libs 2> /dev/null && $(MAKE) doc) || \
	 (echo ">>> If you have a myclone of xen-api-libs, its documentation will be included. <<<")

.PHONY: version
version:
	printf "(* This file is autogenerated.  Grep for e17512ce-ba7c-11df-887b-0026b9799147 (random uuid) to see where it comes from. ;o) *) \n \
	let hg_id = \"$(shell git show-ref --head | grep -E ' HEAD$$' | cut -f 1 -d ' ')\" \n \
	let hostname = \"$(shell hostname)\" \n \
	let date = \"$(shell date -u +%Y-%m-%d)\" \n \
	let product_version = \"$(PRODUCT_VERSION)\" \n \
	let product_version_text = \"$(PRODUCT_VERSION_TEXT)\" \n \
	let product_version_text_short = \"$(PRODUCT_VERSION_TEXT_SHORT)\" \n \
	let product_brand = \"$(PRODUCT_BRAND)\" \n \
	let build_number = Util_inventory.lookup ~default:\"$(BUILD_NUMBER)\" \"BUILD_NUMBER\" \n" \
	> ocaml/util/version.ml

 .PHONY: clean
 clean:


.PHONY: srpm
srpm: 
	mkdir -p $(RPM_SOURCESDIR) $(RPM_SPECSDIR) $(RPM_SRPMSDIR)
	while ! [ -d .git ]; do cd ..; done; \
	git archive --prefix=xapi-0.2/ --format=tar HEAD | bzip2 -z > $(RPM_SOURCESDIR)/xapi-0.2.tar.bz2 # xen-api/Makefile
	make -C $(REPO) version
	rm -f $(RPM_SOURCESDIR)/xapi-version.patch
	(cd $(REPO); diff -u /dev/null ocaml/util/version.ml > $(RPM_SOURCESDIR)/xapi-version.patch) || true
	cp -f xapi.spec $(RPM_SPECSDIR)/
	chown root.root $(RPM_SPECSDIR)/xapi.spec
	$(RPMBUILD) -bs --nodeps $(RPM_SPECSDIR)/xapi.spec


.PHONY: build
build: all

