#!/bin/bash

/usr/local/bin/indexer --all

echo "Starting Sphinx"
/usr/local/bin/searchd --nodetach

