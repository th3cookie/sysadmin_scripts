#!/usr/bin/env python3.7

# Variables are assigned using the '=' assignment operator as follows:
my_str = "This is a simple string"

# We can print the value of the variable to the screen with:
print(my_str)

# Strings also work with assignment operators
stringConcat = 'pass' + 'word'
ha = 'Ha' * 4

"""
This is a
Triple Quoted String
"""

'''
This too
like OH EM GEE
'''

# You can add to the string:
my_str += " testing" # Would now output 'This is a simple string testing'

# We can then re-assign a value to the variable:
my_str = 1 # Would now output int 1.

# A function bound to an object is called a “method”. Here are some example methods that we can call on strings:

# Find() locates the first instance of a character (or string) in a string:
findS = "double".find('s') # This will return -1 Because it doesn't exist and can't give the location of it in the array representation of the characters
findU = "double".find('u') # This will return 2 Because 'u' is at array location 2 of the string
findBl = "double".find('bl') # This will return 3 Because 'bl' starts at array location 3 of the string

# .lower() method converts the string to lower case
"TeStInG".lower() # Will return 'testing'

# .upper() method converts the string to upper case
"TeStInG".upper() # Will return 'TESTING'

# Some escaped things as well:
print("Tab\tDelimited") # Will output -> Tab     Delimited
print("New\nLine") # Will output:
'''
New
Line
'''
print("Slash\\Character") # Will output -> Slash\Character
print("'Single' in Double") # Will output -> 'Single' in Double
print('"Double" in Single') # Will output -> "Double" in Single
print("\"Double\" in Double") # Will output -> "Double" in Double

# There are two main types of numbers that we’ll use in Python, int and float. These are int's:
2 + 2 # Addition
10 - 4 # Subtraction
3 * 9 # Multiplication
5 / 3 # Division
5 // 3 # Floor division, always returns a number without a remainder
8 % 3 # Modulo division, returns the remainder
2 ** 3 # Exponent (the power of)

# Converting data types
str(1.1) # Converts float to str '1.1'
int("10") # Converts str to int '10'
int(5.99999) #Converts float to int '5'
float("5.6") # Converts str to float '5.6'
float(5) # Converts int to float '5.0'

# Booleans are written as:
True
False

# Null or None is written as
None

#############
### Lists ###
#############

# A list is created in Python by using the square brackets ([, and ]) and separating the values by commas:
my_list = [1, 2, 3, 4, 5]

# To access the list value, call it's index as follows:
my_list[2] # Would return '3' from the list, i.e. the third value

# Additionally, we can access subsections of a list by “slicing” it. We provide the starting index and the ending index (the object at that index won’t be included):
my_list[0:2] # Returns -> [1, 2]
my_list[1:0] # Returns -> [2, 3, 4, 5]
my_list[:3] # Returns -> [1, 2, 3]
my_list[0::1] # Returns -> [1, 2, 3, 4, 5]
my_list[0::2] # Returns -> [1, 3, 5]

# Unlike strings which can’t be modified (you can’t change a character in a string), you can change a value in a list using the subscript:
my_list[0] = "a" # Outputs now -> ['a', 2, 3, 4, 5]

# You can use the .append() method to add to the end of th list:
my_list.append(6)
my_list.append(7) # Now outputs -> ['a', 2, 3, 4, 5, 6, 7]

# You can also concatenate lists:
my_list += [8, 9, 10] # Now outputs -> ['a', 2, 3, 4, 5, 6, 7, 8, 9, 10]

# Replacing 2 sized slice with length 3 list, inserts new element
my_list[3:5] = ['d', 'e', 'f'] # Now outputs -> ['a', 2, 3, 'd', 'e', 'f', 6, 7, 8, 9, 10]

# We can remove a section of a list by assigning an empty list to the slice:
my_list[4:] = [] # Now Outputs -> ['a', '2', '3', 'd']

# Removing items from a list based on value can be done using the .remove method:
my_list.remove('d') # Now outputs -> ['a', '2', '3']

# Items can also be removed from the end of a list using the pop() method:
my_list.pop() # Now outputs -> ['a', '2']

# We can also use the pop method to remove items at a specific index:
my_list.pop(0) # Now outputs -> ['2']

# len() function returns the number of items in an object
len(my_list) # Would return '1'

##############
### Tuples ###
##############

# Tuples are a fixed width, immutable sequence type. We create tuples using parenthesis ( and ) and at least one comma (,):
point = (2.0, 3.0)

# We can use tuples in some operations like concatenation, but we can’t change the original tuple that we created (notice the comma at the end):
point_3d = point + (4.0,)

# One interesting characterist of tuples is that we can unpack them into multiple variables at the same time:
x, y, z = point_3d # where x, y, z is assigned 2.0, 3.0, 4.0 respectively

# The time you’re most likely to see tuples will be when looking at a format string that’s compatible with Python 2:
print("My name is: %s %s" % ("Keith", "Thompson")) # This substitutes %s with the tuple values after % placeholder

####################
### Dictionaries ###
####################

# We create dictionary literals by using curly braces ({ and }), separating keys from values using colons (:), and separating key/value pairs using commas (,):
ages = { 'kevin': 59, 'alex': 29, 'bob': 40 }

# We can read a value from a dictionary by subscripting using the key:
ages['kevin'] # Outputs the value associated with 'kevin' -> 59

# Keys can be added or changed using subscripting and assignment
ages['kayla'] = 21 # Full Dict is now -> {'kevin': 59, 'alex': 29, 'bob': 40, 'kayla': 21}

# Items can be removed from a dictionary using the del statement or by using the pop method:
del ages['kevin']
# AND:
ages.pop('alex')

# To find out what Keys or values we have, you can use the values() and keys() methods:
ages.keys() # Would return -> dict_keys(['bob', 'kayla'])
list(ages.keys()) # Would return -> ['bob', 'kayla']
ages.values() # Would return -> dict_values([59, 40])
list(ages.values()) # Would return -> [59, 40]

# You can also create dictionary items using the dict() function (2 ways):
weights = dict(kevin=160, bob=240, kayla=135)
colors = dict([('kevin', 'blue'), ('bob', 'green'), ('kayla', 'red')])

########################
### if - elif - else ###
########################

a = 200
b = 33
if b > a:
    print("b is greater than a")
elif a == b:
    print("a and b are equal")
else:
    print("a is greater than b")

##################
### While Loop ###
##################

a, b = 0, 1
while a < 10:
    print(a)
    a, b = b, a+b

################
### For Loop ###
################

for i in range(5):
    print(i)

# Continue rejects all the remaining statements in the current iteration of the loop and moves the control back to the top of the loop (i.e. the loop continues)
# Break terminates the current loop and resumes execution at the next statement (i.e. the loop breaks)

# Another 'for loop' example that will only print 'green' because 'continue' returns it back to the loop, then break, breaks the loop
colours = ['blue', 'green', 'red', 'purple']
for colour in colours:
    if colour == 'blue':
        continue
    elif colour == 'red':
        break
    print(colour)

# Another 'for loop' example, except this one iterates dict items and tuples with a key-value pair. calling the items() method pulls both sets of data as the item, assigning them to name, age while looping.
ages = {'kevin': 59, 'bob': 40, 'kayla': 21}
for name, age in ages.items():
    print(f"Person Named: {name}")
    print(f"Age of: {age}")

##################################
### Shell Commands from Python ###
##################################

# Using the Subprocess Module -> https://docs.python.org/3/library/subprocess.html

import subprocess
proc = subprocess.run(
    ['ls', '-l'],
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
)

# proc would return -> CompletedProcess(args=['ls', '-l'], returncode=0, stdout=<The Successful Command>, stderr='b')

# To print the output of the command without byte literals
print(proc.stdout.decode())

# check=True allows for stderr printing
new_proc = subprocess.run(['cat', 'fake.txt'], check=True)




