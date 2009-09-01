MACHINE=ta6li
VERSION=0.3
INSTALLBIN=/usr/bin
INSTALLLIB=/usr/lib/csv7.9.3/${MACHINE}/

DEPS=../../srfi/private/include.chezscheme.sls \
	../../srfi/private/let-opt.sls \
	../../srfi/9/records.sls \
	../../srfi/39/parameters.chezscheme.sls \
	../../srfi/23/error.sls \
	../../srfi/14/char-sets.sls \
	../../srfi/14.sls \
	../../srfi/8/receive.sls \
	../../srfi/8.sls \
	../../srfi/13/strings.sls \
	../../srfi/13.sls \
	../../arcfide/extended-definitions.sls \
	../../riastradh/foof-loop/loop.sls \
	../../riastradh/foof-loop/nested.sls \
	../../riastradh/foof-loop.sls

goscher.boot: goscher.so goscher.hdr
	cat goscher.hdr goscher.so > goscher.boot

goscher.hdr: 
	echo '(make-boot-header "goscher.hdr" "petite.boot")' | scheme -q

goscher.so: ${DEPS} goscher.ss
	./build.ss goscher.so ${DEPS} goscher.ss

install: goscher.boot
	cp goscher.boot ${INSTALLLIB}
	ln -sf ${INSTALLBIN}/petite ${INSTALLBIN}/goscher

uninstall:
	rm -rf ${INSTALLBIN}/goscher
	rm -rf ${INSTALLLIB}/goscher.boot

package: goscher.boot Makefile README INSTALL LICENSE 
	mkdir goscher-${VERSION}
	cp Makefile.install goscher-${VERSION}/Makefile
	cp goscher.boot goscher-${VERSION}/
	cp README goscher-${VERSION}/
	cp INSTALL goscher-${VERSION}/
	cp LICENSE goscher-${VERSION}/
	mkdir goscher-${VERSION}/conf
	cp -R conf/extensions* goscher-${VERSION}/conf/
	cp -R conf/goscher.conf goscher-${VERSION}/conf/
	tar cvzf goscher-${VERSION}.tar.gz goscher-${VERSION}

source-package: 
	rm -rf goscher-source-${VERSION}
	mkdir -p goscher-source-${VERSION}
	cp -R BUGS INSTALL LICENSE Makefile Makefile.install README \
		TODO *.ss conf goscher-source-${VERSION}
	tar cvzf goscher-source-${VERSION}.tar.gz goscher-source-${VERSION}

clean: 
	rm -rf goscher.so goscher.boot goscher.hdr
	rm -rf goscher-${VERSION}*
