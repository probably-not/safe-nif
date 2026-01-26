# Erlang include path
ERLANG_PATH = $(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version)])])' -s init stop -noshell)
CFLAGS = -fPIC -I$(ERLANG_PATH)/include -O2 -Wall

# Platform detection
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
	LDFLAGS = -dynamiclib -undefined dynamic_lookup
else
	LDFLAGS = -shared
endif

# elixir_make convention: MIX_APP_PATH is set by elixir_make
PRIV_DIR = $(MIX_APP_PATH)/priv
NIF_SO = $(PRIV_DIR)/test_nif.so

.PHONY: all clean

all: $(NIF_SO)

$(NIF_SO): c_src/test_nif.c
	@mkdir -p $(PRIV_DIR)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<

clean:
	rm -f $(NIF_SO)