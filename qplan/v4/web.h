#ifndef WEB_H
#define WEB_H

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

#include "qplan_context.h"
#include "tcp_io.h"

#define SA struct sockaddr
#define LISTENQ 1024
#define MAXLINE 1024

/* ----------------------------------------------------------------------------
 * Data structure
 */

typedef struct WebHandlerContext_ {
        QPlanContext *context;
        int connfd;
} WebHandlerContext;

/* ----------------------------------------------------------------------------
 * API
 */

void *web_routine(void *arg);

#endif
