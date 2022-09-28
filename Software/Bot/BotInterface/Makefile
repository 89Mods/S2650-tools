CC = gcc
LD = gcc

COGUTILS_DIR := concord/cog-utils
CORE_DIR     := concord/core
INCLUDE_DIR  := concord/include
GENCODECS_DIR  := concord/gencodecs
LIBDIR := concord/lib

CFLAGS  += -I$(INCLUDE_DIR) -I$(COGUTILS_DIR) -I$(CORE_DIR) \
           -I$(CORE_DIR)/third-party -I$(GENCODECS_DIR)     \
           -O1 -g -pthread -Wall $(XFLAGS)
LDFLAGS += -L$(LIBDIR) -lcurl -lncurses -lm -lpthread

all:    bashcord

OBJS=main.o

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

bashcord:       $(OBJS)
	$(LD) -o bot $^ -ldiscord $(LDFLAGS)

clean:
	rm -rf *.o bot

.PHONY: all echo clean
