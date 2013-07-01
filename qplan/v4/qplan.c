#include <err.h>
#include <errno.h>
#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <strings.h>
#include <unistd.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include "qplan_context.h"
#include "repl.h"
#include "web.h"

// TODO: Move this to a util file
void err_abort(int status, const char *message)
{
	fprintf(stderr, message);
	exit(status);
}


int main(int argc, char *argv[])
{
        int version;
	void *thread_result;
	long status;
        pthread_t repl_thread_id;
        pthread_t web_thread_id;
        pthread_mutex_t main_mutex = PTHREAD_MUTEX_INITIALIZER;


        /*
         * Make sure a version is specified
         */
        if (argc < 2) {
                printf("Usage: qplan <version>\n");
                return 1;
        }
        version = strtol(argv[1], NULL, 0);

        /*
         * Create lua states
         */
        lua_State *L_main = luaL_newstate();
        luaL_openlibs(L_main);

        /*
         * Load functionality into main lua state
         */
        lua_getglobal(L_main, "require");
        lua_pushstring(L_main, "app.shell_functions");
        if (lua_pcall(L_main, 1, 1, 0) != LUA_OK)
                luaL_error(L_main, "Problem requiring shell functions: %s",
                                lua_tostring(L_main, -1));

        /* Load version specified from commandline */
        lua_getglobal(L_main, "s");
        lua_pushnumber(L_main, version);
        if (lua_pcall(L_main, 1, 0, 0) != LUA_OK)
                luaL_error(L_main, "Problem calling lua function: %s",
                                lua_tostring(L_main, -1));

        lua_getglobal(L_main, "require");
        lua_pushstring(L_main, "modules.web");
        if (lua_pcall(L_main, 1, 1, 0) != LUA_OK)
                luaL_error(L_main, "Problem requiring shell functions: %s",
                                lua_tostring(L_main, -1));

        /*
         * Set up context
         */
        QPlanContext qplan_context;
        qplan_context.main_lua_state = L_main;
        qplan_context.main_mutex = &main_mutex;

	/* Create REPL thread */
	status = pthread_create(&repl_thread_id, NULL, repl_routine, (void *)&qplan_context);
	if (status != 0)
		err_abort(status, "Create repl thread");

        /* Create web server thread */
	status = pthread_create(&web_thread_id, NULL, web_routine, (void *)&qplan_context);
	if (status != 0)
		err_abort(status, "Create web thread");
	status = pthread_detach(web_thread_id);
	if (status != 0)
		err_abort(status, "Problem detaching web thread");


	/* Join REPL thread */
	status = pthread_join(repl_thread_id, &thread_result);
	if (status != 0)
		err_abort(status, "Join thread");

        lua_close(L_main);

	printf("We are most successfully done!\n");
	return 0;
}
