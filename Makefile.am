NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	data \
	$(NULL)

INCLUDES = \
	$(DEPS_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = src/.vala.stamp

sbin_PROGRAMS = fso-abyss

fso_abyss_VALASOURCES = \
	src/consts.vala \
	src/server.vala \
	src/main.vala \
	$(NULL)

fso_abyss_SOURCES = \
	$(fso_abyss_VALASOURCES:.vala=.c) \
	\
	$(NULL)

src/.vala.stamp: $(fso_abyss_VALASOURCES)
	$(VALAC) -C --vapidir vapi \
	            --pkg posix \
	            --pkg dbus-glib-1 \
	            --pkg gsm0710mux-1.0 \
	            --save-temps \
	            --basedir $(top_srcdir) $^
	touch $@

fso_abyss_LDADD = \
	$(DEPS_LIBS) \
	$(NULL)

EXTRA_DIST = \
	MAINTAINERS \
	$(fso_abyss_VALASOURCES) \
	src/.vala.stamp \
	$(NULL)

CLEANFILES = \
	src/channel.? \
	src/serial.? \
	src/multiplexer.? \
	src/server.? \
	src/consts.? \
	src/main.? \
	src/.vala.stamp \
	$(NULL)

DISTCLEANFILES = \
	$(NULL)

MAINTAINERCLEANFILES = aclocal.m4 compile config.guess config.sub \
                       configure depcomp install-sh ltmain.sh     \
                       Makefile.in missing config.h.in            \
                       intltool-extract \
                       intltool-merge \
                       intltool-update \
                       mkinstalldirs \
                       src/*.c src/*.h *~ \
                       $(NULL)
