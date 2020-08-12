# Prerequisites

- Cloudflare account already setup and auth_key available (login to grab this)
- Must be run with python 3.7 or newer
- DNS record that we will be updated must already exist. If it does not, please create it manually as this script is used only to update it. This DNS record must also be an A record.

# Setup

Copy the file 'config.py.example' to config.py:

```cp config.py.example config.py```

Fill in the relevant details in the config.py file

# Running the script

```python3.8 ./update_cf_ip.py```

If you want to enable debugging for verbose printing to stdout:

```python3.8 ./update_cf_ip.py --debug```