import os
import glob
import json
import shutil

try:
    os.mkdir('./processed')
except OSError:
    print("'processed' directory already exists!")

receipts = glob.glob('./new/receipts-[0-9]*.json')
subtotal = 0.0

for path in receipts:
    with open(path) as f:
        content = json.load(f)
        subtotal += float(content['value'])
    # Splitting to return only the filename (i.e. -1 index), e.g. "./new/receipt-1.json".split('/') RETURNS an array => ['.', 'new', 'receipt-1.json'] as '/' being split character
    name = path.split("/")[-1]
    
    destination = f"./processed/{name}"
    shutil.move(path, destination)
    print(f"moved '{path}' to '{destination}'")

print("Receipt subtotal: $%.2f" % subtotal)