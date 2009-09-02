MACHINE=ta6le
VERSION=0.3
INSTALLBIN=/usr/bin
INSTALLLIB=/usr/lib/csv7.9.3/${MACHINE}/
PKG=goscher-${VERSION}-${MACHINE}

DEPS=../../srfi/private/include.chezscheme.sls ../../srfi/private/let-opt.sls ../../srfi/9/records.sls ../../srfi/39/parameters.chezscheme.sls ../../srfi/23/error.sls ../../srfi/14/char-sets.sls ../../srfi/14.sls ../../srfi/8/receive.sls ../../srfi/8.sls ../../srfi/13/strings.sls ../../srfi/13.sls ../../arcfide/extended-definitions.sls ../../riastradh/foof-loop/loop.sls ../../riastradh/foof-loop/nested.sls ../../riastradh/foof-loop.sls

FILES=include.chezscheme.sls let-opt.sls records.sls parameters.chezscheme.sls error.sls  char-sets.sls 14.sls receive.sls 8.sls strings.sls 13.sls extended-definitions.sls loop.sls nested.sls foof-loop.sls

goscher.boot: goscher.so goscher.hdr
	cat goscher.hdr goscher.so > goscher.boot

goscher.hdr: 
	echo '(make-boot-header "goscher.hdr" "petite.boot")' | scheme -q

goscher.so: ${DEPS} goscher.ss
	rm -rf build
	mkdir -p build
	cp ${DEPS} goscher.ss build/
	./build.ss goscher.so build/ ${FILES} goscher.ss

install: goscher.boot
	cp goscher.boot ${INSTALLLIB}
	ln -sf ${INSTALLBIN}/petite ${INSTALLBIN}/goscher

uninstall:
	rm -rf ${INSTALLBIN}/goscher
	rm -rf ${INSTALLLIB}/goscher.boot

package: goscher.boot Makefile README INSTALL LICENSE 
	mkdir ${PKG}
	cp Makefile.install ${PKG}/Makefile
	cp goscher.boot ${PKG}/
	cp README ${PKG}/
	cp INSTALL ${PKG/
	cp LICENSE ${PKG/
	mkdir ${PKG/conf
	cp -R conf/extensions* ${PKG/conf/
	cp -R conf/goscher.conf ${PKG}/conf/
	tar cvzf ${PKG}.tar.gz ${PKG}

source-package: 
	rm -rf goscher-source-${VERSION}
	mkdir -p goscher-source-${VERSION}
	cp -R BUGS INSTALL LICENSE Makefile Makefile.install README \
		TODO *.ss conf goscher-source-${VERSION}
	tar cvzf goscher-source-${VERSION}.tar.gz goscher-source-${VERSION}

clean: 
	rm -rf goscher.so goscher.boot goscher.hdr
	rm -rf goscher-${VERSION}*
	rm -rf build
	rm -rf goscher-source*
