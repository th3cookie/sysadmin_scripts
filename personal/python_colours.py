#!/usr/bin/env python3.6

#######################
### Colorama Method ###
#######################

# You can use this module to do it easier -> https://pypi.org/project/colorama/

from colorama import init
init()
# Do things
deinit()

from colorama import Fore, Back, Style
print(Fore.RED + 'some red text')
print(Back.GREEN + 'and with a green background')
print(Style.DIM + 'and in dim text')
print(Style.RESET_ALL)
print('back to normal now')

# …or simply by manually printing ANSI sequences from your own code:

print('\033[31m' + 'some red text')
print('\033[39m') # and reset to default color

#####################
### Manual Method ###
#####################

# Reference -> https://stackoverflow.com/questions/287871/how-to-print-colored-text-in-terminal-in-python

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

# To use this class, you can do something like (python 3.6 using string interpolation):
print(f"{bcolors.WARNING}Warning: No active frommets remain. Continue?{bcolors.ENDC}")
