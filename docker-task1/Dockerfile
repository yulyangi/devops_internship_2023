# the fastest way is to use "python:alpine" distribution
# without creating additional virtual env
# example:
# FROM python:3.9.18-alpine3.18
# WORKDIR /app
# COPY /path/to/source/code .
# RUN pip install --no-cache-dir -r requirements.txt
# EXPOSE 8080
# CMD ["python", "run.py", "--port 8080", "--json-logging", "--access-log"]
#######################################

# but we want to create virtual env
# use another linux distribution
FROM debian:bookworm-slim

# indentations for more readability
# use double quotes for value
# don't use "\" at the last line
LABEL maintainer="Valera" \
      os="Debian"

# first configure ARG and ENV
# use ARG only for building docker image, ENV as environment var
# also we can replace ARG passing --build-arg <varname>=<value> at build time
# not necessary use all ARGs in one layer
# to prevent any issus better to use group id equals user id 
# and value more then 1000
ARG USER_ID=1001
ARG GROUP_ID=1001
ARG USER_NAME=docker
ARG VENV_DIR=/venv
# better to use path to tar archive as var
ARG TARBALL_PATH=./object.tar.gz
# make bin files exucutable passing them to $PATH environment var
ENV PATH="$VENV_DIR/venv/bin:$PATH"

# extract tar archive 
ADD $TARBALL_PATH $VENV_DIR

# first create a user and a group
RUN groupadd -r $USER_NAME -g $GROUP_ID \
    && useradd -u $USER_ID -r -g $GROUP_ID $USER_NAME

# run apt-get to update system without any dependencies
# probably we don't need to upgrade system
# update and install python as one layer
# "apt-get clean" runs automatically on Debian or Ubuntu
# run "rm -rf /var/cache/apt/archives" not required 
# because "apt-get clean" removes archives from this dir
RUN apt-get update && apt-get install -y python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# move to workdir
WORKDIR $VENV_DIR

# then create python environment
RUN python3 -m venv $VENV_DIR \
    # make sure whether 'requirements.txt' is existed
    && ./bin/pip install --no-cache-dir -r requirements.txt \
    && chown -R $USER_ID:$GROUP_ID $VENV_DIR

# change to created user
USER $USER_NAME
EXPOSE 8080

# CMD is preferred form to run this command as a default command
# we are able to replace this command passing another command
# example: docker container run -it <image-name> bash
CMD ["./bin/python", "run.py", "--port 8080", "--json-logging", "--access-log"]