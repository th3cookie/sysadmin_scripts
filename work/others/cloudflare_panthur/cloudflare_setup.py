#!/usr/bin/env python3.7
# Script to create a new account and link it to our cloudflare partner account - Sami S - 27/05/2020

import json
import requests
import config

if __name__=="__main__":
    # Load API Key from config.py
    api_key = config.api_key

    # Read user input
    email = input("Client Email: ")
    password = input("Password: ")
    domain = input("Domain: ")

    # Make a unique ID by stripping dots from domain name (but we will do checks for this anyway)
    id = domain.replace('.', '')

    # Cloudflare API endpoint URL
    url = "https://api.cloudflare.com/host-gw.html"

    # Test the ID is not in use first
    print(f"Testing if the ID \"{id}\" is in use before proceeding...")
    user_lookup_data = {'act': 'user_lookup', 'host_key': api_key, 'unique_id': id}
    response = requests.post(url, data = user_lookup_data)

    print(response)


    '''
    # Create user in partner account
    user_create_data = {'act': 'user_create', 'host_key': api_key, 'cloudflare_email': email, 'cloudflare_pass': password, 'unique_id': id}



    USER_KEY=

    grab user_key


    curl https://api.cloudflare.com/host-gw.html \
    -d "act=full_zone_set" \
    -d "host_key=${API_KEY}" \
    -d "user_key=CLIENT_KEY_FROM_ABOVE_CALL" \
    -d "zone_name=${DOMAIN}"
    '''