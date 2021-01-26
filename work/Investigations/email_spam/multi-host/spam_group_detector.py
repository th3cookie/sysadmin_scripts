#!/usr/bin/env python3.8

import os
import subprocess

cmd = "df -h"

with open('./hosts', 'r') as file:
	hosts = [line.strip() for line in file.readlines()]
	for host in hosts:
		command = subprocess.Popen(f"ssh {host} {cmd}", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()
		command_decoded = command[0].decode("utf-8")
		answer = [i for i in command_decoded.splitlines()]

for i in answer:
	print(i)
