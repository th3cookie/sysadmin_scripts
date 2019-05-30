#!/usr/bin/env python3.7

user = [
    {'admin': True, 'active': True, 'name': 'Kevin'},
    {'admin': True, 'active': False, 'name': 'Bob'},
    {'admin': False, 'active': False, 'name': 'Sami'}
]
line = 1
for person in user:
    if person['admin'] and person['active']:
        print(f"{line} ACTIVE - (ADMIN) {person['name']}")
        line += 1
    elif person['admin']:
        print(f"{line} (ADMIN) {person['name']}")
        line += 1
    elif person['active']:
        print(f"{line} ACTIVE - {person['name']}")
        line += 1
