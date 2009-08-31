MACHINE=ta6li
VERSION=0.3
INSTALLBIN=/usr/bin
INSTALLLIB=/usr/lib/csv7.9.3/${MACHINE}/

goscher.boot: goscher.so goscher.hdr
	cat goscher.hdr goscher.so > goscher.boot

goscher.hdr: goscher.so
	echo '(make-boot-header "goscher.hdr" "petite.boot")' | scheme -q

goscher.so: goscher.ss modules.ss conf.ss
	echo '(compile-file "goscher")' | scheme -q

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

clean: 
	rm -rf goscher.so goscher.boot goscher.hdr
	rm -rf goscher-${VERSION}*
