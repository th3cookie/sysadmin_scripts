#!/usr/bin/env python3.8
# Script to create a new account and link it to our cloudflare partner account and enable railgun - Sami S - 27/05/2020

import json
import requests
import config
import sys

def make_post_request(data):
    response = requests.post(url, data = data)

    if not response.ok:
        print("Request failed. Cannot connect to Cloudflare API. bailing...")
        sys.exit(1)

    response_json = response.json()
    return response_json

def check_user_exists():
    data = {'act': 'user_lookup', 'host_key': api_key, 'unique_id': id}
    response_json = make_post_request(data)
    print(f"TROUBLESHOOTING!!!!\n{response_json}")

    user_exists = response_json['response']['user_exists']
    if user_exists != False:
        print("User already exists. Cannot proceed. bailing...")
        print(f"JSON data from API response, useful for troubleshooting:\n{response_json}")
        sys.exit(1)

def create_user():
    data = {'act': 'user_create', 'host_key': api_key, 'cloudflare_email': email, 'cloudflare_pass': password, 'unique_id': id}
    response_json = make_post_request(data)
    print(f"TROUBLESHOOTING!!!!\n{response_json}")

    if response_json['result'].lower() != "success":
        print("User Creation failed. Please contact a member of the operations team to investigate. bailing...")
        print(f"JSON data from API response, useful for troubleshooting:\n{response_json}")
        sys.exit(1)
    else:
        global user_key
        user_key = response_json['response']['user_key']

def full_zone_set():
    user_key = "8afbe6dea02407989af4dd4c97bb6e25"
    data = {'act': 'full_zone_set', 'host_key': api_key, 'user_key': user_key, 'zone_name': domain}
    response_json = make_post_request(data)
    print(f"TROUBLESHOOTING!!!!\n{response_json}")

    if response_json['response']['result'].lower() != "success":
        print("User Creation failed. Please contact a member of the operations team to investigate. bailing...")
        print(f"JSON data from API response, useful for troubleshooting:\n{response_json}")
        sys.exit(1)
    else:
        print("Success, full DNS zone created")
        print(response_json['response']['msg'])

if __name__=="__main__":
    # Load API Key from config.py
    api_key = config.api_key

    # Read user input
    email = input("Client Email: ")
    password = input("Password: ")
    domain = input("Domain: ")

    # Make a unique ID by stripping dots from domain name. This will make sure it's unique but we will do checks for this anyway later on to ensure
    id = domain.replace('.', '')

    # Cloudflare API endpoint URL
    url = "https://api.cloudflare.com/host-gw.html"

    # Test the ID is not in use first
    print(f"Checking if the ID \"{id}\" is in use before proceeding...")
    check_user_exists()
    print("Continuing as the user doesn't exist in our partner account yet.")

    # Create user in partner account
    print(f"Creating the cloudflare account with ID \"{id}\" within our partner account...")
    create_user()
    print(f"Success, account created with user key: {user_key}")

    # Setup the DNS zone
    print("Creating full DNS zone in Cloudflare for NS setup...")
    full_zone_set()
    print(f"Once the Nameservers have been updated, please contact a member of the operations team to enable railgun for the domain \"{domain}\".")