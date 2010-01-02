MACHINE=ta6le
VERSION=0.4.0
INSTALLBIN=/usr/bin
INSTALLLIB=/usr/lib/csv7.9.3/${MACHINE}/
PKG=goscher-${VERSION}-${MACHINE}

goscher.boot: 
	./build.ss

install: goscher.boot
	cp goscher.boot ${INSTALLLIB}
	ln -sf ${INSTALLBIN}/petite ${INSTALLBIN}/goscher

uninstall:
	rm -rf ${INSTALLBIN}/goscher
	rm -rf ${INSTALLLIB}/goscher.boot

package: goscher.boot Makefile.install README INSTALL LICENSE 
	mkdir ${PKG}
	cp Makefile.install ${PKG}/Makefile
	cp goscher.boot ${PKG}/
	cp README ${PKG}/
	cp INSTALL ${PKG}/
	cp LICENSE ${PKG}/
	mkdir ${PKG}/conf
	cp -R conf/extensions* ${PKG}/conf/
	cp -R conf/goscher.conf ${PKG}/conf/
	tar cvzf ${PKG}.tar.gz ${PKG}

source-package: 
	rm -rf goscher-source-${VERSION}
	mkdir -p goscher-source-${VERSION}
	cp -R BUGS INSTALL LICENSE Makefile Makefile.install README \
		TODO *.ss conf goscher-source-${VERSION}
	tar cvzf goscher-source-${VERSION}.tar.gz goscher-source-${VERSION}

clean: 
	rm -rf goscher.boot 
	rm -rf goscher-${VERSION}*
	rm -rf goscher-source*
