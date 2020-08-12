#!/usr/bin/env python3.8

import requests
import config
import sys
import subprocess
import syslog

try:
	assert sys.version_info >= (3, 7)
except AssertionError:
	print('You must run this script with at least python3.7.')
	sys.exit(1)

def printing(string):
	if debug:
		print(string)
	syslog.openlog(logoption=syslog.LOG_PID)
	syslog.syslog(string)

def make_put_request(url, headers, params):
	response = requests.put(url, headers = headers, json = params)

	if not response.ok:
		printing("Request failed. Cannot connect to Cloudflare API. bailing...")
		sys.exit(1)

	response_json = response.json()

	try:
		if not response_json['success']:
			printing("Cannot get DNS record/zone. bailing...")
			printing(f"JSON data from API response, useful for troubleshooting:\n{response_json}")
			sys.exit(1)
	except KeyError:
		printing("JSON data did not return as expected, please review the below JSON data to troubleshoot.")
		printing(response_json)

	return response_json

def make_get_request(url, headers, params):
	response = requests.get(url, headers = headers, params = params)

	if not response.ok:
		printing("Request failed. Cannot connect to Cloudflare API. bailing...")
		sys.exit(1)

	response_json = response.json()

	try:
		if not response_json['success']:
			printing("Cannot get DNS record/zone. bailing...")
			printing(f"JSON data from API response, useful for troubleshooting:\n{response_json}")
			sys.exit(1)
	except KeyError:
		printing(f"JSON data did not return as expected, please review the below JSON data to troubleshoot:\n{response_json}")

	return response_json

if __name__=="__main__":
	# Load keys from config.py
	# api_key = config.api_key
	auth_key = config.auth_key
	auth_email = config.auth_email
	domain = config.domain
	record = config.record
	full_record = f"{record}.{domain}"

	# Set debugging
	debug = False

	# Check if debugging flag set
	if len(sys.argv) == 2:
		if sys.argv[1] == '--debug':
			debug = True
			print("Debugging enabled...")
		else:
			print('Invalid argument was passed. Please run the script with no arguments or with "--debug" for debugging via stdout printing.')
			sys.exit(1)
	elif len(sys.argv) != 1:
		print('Invalid number of arguments were passed. Please run the script with no arguments or with "--debug" for debugging via stdout printing.')
		sys.exit(1)

	# Cloudflare API endpoint URL
	main_url = "https://api.cloudflare.com/client/v4/zones"
	headers = {'X-Auth-Email': auth_email, 'X-Auth-Key': auth_key}

	# Get Public IP
	proc = subprocess.run(
		['dig', '+short', 'myip.opendns.com', '@resolver1.opendns.com'],
		stdout=subprocess.PIPE,
		stderr=subprocess.PIPE,
		universal_newlines=True,
	)

	ip = proc.stdout.strip()

	if not ip:
		printing("No IP address was obtained on the system. Bailing...")
		sys.exit(1)
	
	# Get current zone
	# headers = {'X-Auth-Email': auth_email, 'X-Auth-Key': auth_key, 'Content-Type': 'application/json'}
	headers = {'X-Auth-Email': auth_email, 'X-Auth-Key': auth_key}
	get_zone_params = {'name': domain}
	get_zone_response_json = make_get_request(url = main_url, headers = headers, params = get_zone_params)
	zone_id = get_zone_response_json['result'][0]['id']
	get_zone_url = f"{main_url}/{zone_id}/dns_records"
	list_zone_params = {'name': full_record}
	list_zone_record_json = make_get_request(url = get_zone_url, headers = headers, params = list_zone_params)
	dns_record = list_zone_record_json["result"][0]["content"]
	dns_record_id = list_zone_record_json["result"][0]["id"]
	
	# Update DNS record if different from current WAN record.
	if ip != dns_record:
		printing("IP addresses are not the same. Updating...")
		put_zone_url = f"{main_url}/{zone_id}/dns_records/{dns_record_id}"
		put_zone_params = {"type": "A", "name": full_record, "content": ip, "ttl": '1', "proxied": 'false'}
		printing(f"Put Params: {put_zone_params}")
		printing(f"Put Zone URL: {put_zone_url}")
		
		put_dns_response_json = make_put_request(url = put_zone_url, headers = headers, params = put_zone_params)
		printing("Updated IP Address.")

	else:
		printing("IP address has not changed, nothing to do.")