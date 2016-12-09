#!/bin/sh
#
curl http://localhost:9507$1 -v -H "Accept: application/hal+json" -u kevin
#
