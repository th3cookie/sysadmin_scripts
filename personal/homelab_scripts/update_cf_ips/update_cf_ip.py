#!/usr/bin/env python3.7

import json
import requests
import config
import sys
import subprocess

def make_post_request(data):
    response = requests.post(url, data = data)

    if not response.ok:
        print("Request failed. Cannot connect to Cloudflare API. bailing...")
        sys.exit(1)

    response_json = response.json()
    return response_json

if __name__=="__main__":
	# Load keys from config.py
	api_key = config.api_key
	auth_key = config.auth_key
	auth_email = config.auth_email

	# Cloudflare API endpoint URL
	url = "https://api.cloudflare.com/client/v4/zones/"

	# Get Public IP
	proc = subprocess.run(
		['dig', '+short', 'myip.opendns.com', '@resolver1.opendns.com'],
		stdout=subprocess.PIPE,
		stderr=subprocess.PIPE,
		universal_newlines=True,
	)

	ip = proc.stdout.strip()
	print(ip)
	
	'''
	Example adding DNS record:

	curl -X PUT "https://api.cloudflare.com/client/v4/zones/023e105f4ecef8ad9ca31a8372d0c353/dns_records/372e67954025e0ba6aaa6d586b9e0b59" \
     -H "X-Auth-Email: user@example.com" \
     -H "X-Auth-Key: XXXXXXXXXXXXXXXXXXXXX" \
     -H "Content-Type: application/json" \
     --data '{"type":"A","name":"example.com","content":"127.0.0.1","ttl":{},"proxied":false}'

	dns records to do:
	home
	 '''