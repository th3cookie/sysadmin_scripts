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

	proc = subprocess.run(
		['ls', '-l'],
		stdout=subprocess.PIPE,
		stderr=subprocess.PIPE,
	)