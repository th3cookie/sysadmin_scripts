#!/bin/bash

for i in $(rpm -qa | LC_ALL=C sort); do
    rpm --setugids ${i}
done