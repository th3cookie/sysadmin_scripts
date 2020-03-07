#!/usr/bin/env python3
# This script will parse the docker compose and print the services/ports to the MOTD. It will create this file if it doesn't exist as well.

import yaml

docker_file = 'docker-compose.yml'

with open(docker_file) as f:
    data = yaml.load(f, Loader=yaml.FullLoader)

newdict = {}

for service in data['services']:
    if service == 'mariadb':
        ports = data['services'][service]['ports'][0]['target']
        newdict[service] = str(ports)
    else:
        try:
            ports = data['services'][service]['ports'][0]
            newdict[service] = ports
        except KeyError:
            pass

full_motd = "Installed docker services and their respective ports:\n"

for key in newdict:
    val = newdict[key]
    full_motd += f"{key} -> {newdict[key].split(':')[0] if ':' in newdict[key] else val}\n"

with open("/etc/motd", "a+") as f:
    f.write(full_motd)