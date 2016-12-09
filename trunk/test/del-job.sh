#!/bin/sh
#
curl -XDELETE http://localhost:9507/rexec/jobs/$1 -v -H "Accept: application/hal+json" -u kevin
#