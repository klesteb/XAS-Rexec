#!/bin/sh
#
curl http://localhost:9507/rexec/logs/$1 -v -H "Accept: application/hal+json" -u kevin
#
