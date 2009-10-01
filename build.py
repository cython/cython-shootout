import sys, os, glob

makefile = open("Makefile", "w")
makefile.write("""

PYVERSION=%(major_version)s.%(minor_version)s
PYPREFIX=%(prefix)s
INCLUDES=-I$(PYPREFIX)/include/python$(PYVERSION)

""" % {
'prefix': sys.prefix,
'major_version': sys.version_info[0],
'minor_version': sys.version_info[1],
})

all = []
for pyx in glob.glob("*.pyx"):
    exe = os.path.splitext(pyx)[0]
    all.append(exe)
    if exe == 'pidigits_cython':
        extra_flags = "-lgmp -I%(prefix)s/include -L%(prefix)s/lib" % {'prefix': sys.prefix}
    else:
        extra_flags = ""
    makefile.write("""
    
%(exe)s.c: %(exe)s.pyx
\t@python -m cython -a --embed %(exe)s.pyx

%(exe)s: %(exe)s.c
\tgcc -O3 -o $@ $^ $(INCLUDES) -lpython$(PYVERSION) -lm %(extra_flags)s

""" % {
'exe': exe,
'extra_flags': extra_flags,
})

makefile.write("""

all: %(all)s

clean:
\t@echo Cleaning Demos/embed
\t@rm -f *~ *.o *.so core core.* *.c %(all)s

""" % {'all': ' '.join(all)})

makefile.close()

os.system('make all')
