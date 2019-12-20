For python, you need to create a virtualenv and import the modules using pip:

# before pip version 15.1.0
virtualenv --no-site-packages --distribute env && \
    source env/bin/activate && \
    pip install -r requirements.txt

# after deprecation of some arguments in pip version 15.1.0
virtualenv env && source env/bin/activate && pip install -r requirements.txt