#!/usr/bin/env python3.7

user = { 'admin': True, 'active': False, 'name': 'Kevin' }

if user['admin'] is True:
    print(f"(ADMIN) {user['name']}")
elif user['active'] is True:
    print(f"ACTIVE - {user['name']}")
elif user['admin'] is True and user['active'] is True:
    print(f"ACTIVE - (ADMIN) {user['name']}")

