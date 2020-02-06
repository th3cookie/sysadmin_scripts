#!/bin/bash

for i in {01..72}; do
    echo "Doing vmcp$i.digitalpacific.com.au..."
    ssh -T vmcp$i.digitalpacific.com.au 'df -h'
    RESERVE=$(ssh -T vmcp$i.digitalpacific.com.au 'partition_reserved_blocks show /')
    if [[ ! $RESERVE =~ 5% ]]; then
        echo -e "\n Reserve blocks:\n${RESERVE}"
    fi
    echo ""
done