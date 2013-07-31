include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = qplan
qplan_C_FILES = qplan.c tcp_io.c qplan_context.c web.c repl.c base64.c ws.c
qplan_LDFLAGS = -llua52 -lpthread -lreadline
qplan_CFLAGS = -I/usr/local/include/lua52
ADDITIONAL_TOOL_LIBS = -lssl -lcrypto -lm

include $(GNUSTEP_MAKEFILES)/tool.make
