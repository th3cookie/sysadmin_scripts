#!/usr/bin/env python3.8
# This script will parse the docker compose and print the services/ports to the MOTD. It will create this file if it doesn't exist as well.

import yaml
import os

print(yaml.__version__)

new_ports_dict = {}
vols_to_create = []
docker_file = 'docker-compose.yml'

def listVols(array):
    for volume in volumes:
        newvol = volume.replace("${USERDIR}", userdir).split(':')[0] if ':' in volume else volume.replace("${USERDIR}", userdir)
        vols_to_create.append(newvol)

# This will only grab your userdir if it's set as standard, i.e. /home/user
cwdarr = os.getcwd().split("/")
userdir = f"/{'/'.join(cwdarr[1:3])}"

with open(docker_file) as f:
    data = yaml.load(f, Loader=yaml.FullLoader)

for service in data['services']:
    if service == 'mariadb':
        ports = data['services'][service]['ports'][0]['target']
        new_ports_dict[service] = str(ports)
        volumes = data['services'][service]['volumes']
        listVols(volumes)
    else:
        try:
            ports = data['services'][service]['ports'][0]
            new_ports_dict[service] = ports
            volumes = data['services'][service]['volumes']
            listVols(volumes)
        except KeyError:
            pass

full_motd = "Installed docker services and their respective ports:\n"

for key in new_ports_dict:
    val = new_ports_dict[key]
    full_motd += f"{key} -> {new_ports_dict[key].split(':')[0] if ':' in new_ports_dict[key] else val}\n"

for vol in vols_to_create:
    if not os.path.exists(vol):
        try:
            os.mkdir(vol)
            print(f"Volume '{vol}' created successfully...")
        except OSError:
            print(f"Creation of the directory '{vol}' FAILED... Please check to see why it has failed, and remediate manually.")

with open("/etc/motd", "a+") as f:
    f.write(full_motd)