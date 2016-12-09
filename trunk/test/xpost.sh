#!/bin/sh
#
curl -XPOST http://localhost:9507/rexec/jobs/$1 -v -H "Accept: application/hal+json" -H "Content-Type: application/vnd.xas.rexec+json;version=1.0'" -u kevin -d "{\"action\":\"$2\"}"
#
