#/usr/bin/env python3.7

import argparse
import sys

# build parser

parser = argparse.ArgumentParser(description='Read a file in reverse')

# parse arguments

parser.add_argument('filename', help='the file to read')
parser.add_argument('-l', '--limit', type=int, help='the number of lines to read')
parser.add_argument('-v', '--version', action='version', version='%(prog)s 1.0')

args = parser.parse_args()

# read file, reverse contents and print

# Checking if filename exists and doing error handling with exit status 2
try:
    f = open(args.filename)
    limit = args.limit
except FileNotFoundError as err:
    print(f"Error: {err}")
    sys.exit(2)
else:
    # Opening the file with 'with' makes it easy.
    with f:

        # Returning a list containing each line as a list item
        lines = f.readlines()
        # Reversing the order of the list items
        lines.reverse()

        # If a limit option is set, it will limit the list items (lines)
        if args.limit:
            lines = lines[:limit]
        
        # Reversing the characters and stripping whitespace and /n.
        for line in lines:
            print(line.strip()[::-1])
