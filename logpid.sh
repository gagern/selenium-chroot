#!/bin/sh
echo $$ > $1
shift
exec "$@"
