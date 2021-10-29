CROSS=Y

CROSSBINDIR_IS_Y=m68k-atari-mint-
CROSSBINDIR_IS_N=

CROSSBINDIR=$(CROSSBINDIR_IS_$(CROSS))

ifneq (yes,$(VERBOSE))
    Q=@
else
    Q=
endif


UNAME := $(shell uname)
ifeq ($(CROSS), Y)
ifeq ($(UNAME),Linux)
PREFIX=m68k-atari-mint
HATARI=hatari
else
PREFIX=m68k-atari-mint
HATARI=/usr/local/bin/hatari
endif
else
PREFIX=/usr
endif

DEPEND=depend

LIBCMINI=../libcmini
INCLUDE=-I$(LIBCMINI)/include -nostdlib
LIBS=-lcmini -nostdlib -lgcc
CC=$(PREFIX)/bin/gcc

CC=$(CROSSBINDIR)gcc
STRIP=$(CROSSBINDIR)strip
STACK=$(CROSSBINDIR)stack

APP=mist.ttp
TEST_APP=$(APP)

CFLAGS=\
	-Os\
	-g\
	-fomit-frame-pointer\
	-Wl,-Map,mapfile\
	-Wall

SRCDIR=sources
INCDIR=include
INCLUDE+=-I$(INCDIR)

CSRCS=\
	$(SRCDIR)/mist_viking.c

COBJS=$(patsubst $(SRCDIR)/%.o,%.o,$(patsubst %.c,%.o,$(CSRCS)))
AOBJS=$(patsubst $(SRCDIR)/%.o,%.o,$(patsubst %.S,%.o,$(ASRCS)))
OBJS=$(COBJS) $(AOBJS)

TRGTDIRS=. ./m68020-60 ./m5475 ./mshort ./m68020-60/mshort ./m5475/mshort
OBJDIRS=$(patsubst %,%/objs,$(TRGTDIRS))

#
# multilib flags. These must match m68k-atari-mint-gcc -print-multi-lib output
#
m68020-60/$(APP):CFLAGS += -m68020-60
m5475/$(APP):CFLAGS += -mcpu=5475
mshort/$(APP):CFLAGS += -mshort
m68020-60/mshort/$(APP): CFLAGS += -m68020-60 -mshort
m5475/mshort/$(APP): CFLAGS += -mcpu=5475 -mshort

ctest: $(TEST_APP)
all:$(patsubst %,%/$(APP),$(TRGTDIRS))
#
# generate pattern rules for multilib object files.
#
define CC_TEMPLATE
$(1)/objs/%.o:$(SRCDIR)/%.c
	$$(Q)echo "CC $$<"
	$$(Q)$(CC) $$(CFLAGS) $(INCLUDE) -c $$< -o $$@

$(1)/objs/%.o:$(SRCDIR)/%.S
	$$(Q)echo "CC $$<"
	$$(Q)$(CC) $$(CFLAGS) $(INCLUDE) -c $$< -o $$@

$(1)_OBJS=$(patsubst %,$(1)/objs/%,$(OBJS))
$(1)/$(APP): $$($(1)_OBJS)
	$$(Q)echo "CC $$@"
	$(CC) $$(CFLAGS) -o $$@ $(LIBCMINI)/build/crt0.o $$($(1)_OBJS) -L$(LIBCMINI)/build/$(1) $(LIBS)
	#$(STRIP) $$@
endef
$(foreach DIR,$(TRGTDIRS),$(eval $(call CC_TEMPLATE,$(DIR))))

$(DEPEND): $(ASRCS) $(CSRCS)
	-rm -f $(DEPEND)
	for d in $(TRGTDIRS);\
		do $(CC) $(CFLAGS) $(INCLUDE) -M $(ASRCS) $(CSRCS) | sed -e "s#^\(.*\).o:#$$d/objs/\1.o:#" >> $(DEPEND); \
    done


clean:
	@rm -f $(patsubst %,%/objs/*.o,$(TRGTDIRS)) $(patsubst %,%/$(APP),$(TRGTDIRS))
	@rm -f $(DEPEND) mapfile

.PHONY: printvars
printvars:
	@$(foreach V,$(.VARIABLES), $(if $(filter-out environment% default automatic, $(origin $V)),$(warning $V=$($V))))

ifneq (clean,$(MAKECMDGOALS))
-include $(DEPEND)
endif

test: $(TEST_APP)
	$(HATARI) --grab -w --tos ../emutos/etos512k.img \
	--machine falcon -s 14 --cpuclock 32 --cpulevel 3 --vdi true --vdi-planes 4 \
	--vdi-width 640 --vdi-height 480 -d . $(APP)

ftest: $(TEST_APP)
	$(HATARI) --grab -w --tos /usr/share/hatari/TOS404.IMG \
	--machine falcon --cpuclock 32 --cpulevel 3 \
	-d . $(APP)

sttest: $(TEST_APP)
	$(HATARI) --grab -w --tos "/usr/share/hatari/tos106de.img" \
	--machine st --cpuclock 32 --cpulevel 3  --vdi true --vdi-planes 4 \
	--vdi-width 640 --vdi-height 480 \
	-d . $(APP)
