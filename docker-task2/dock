FROM python
ARG VENV_DIR=/venv
LABEL maintainer="Valera" \
os='Debian' \
 
ENV USER_ID=500 \
GROUP_ID=1000 \
USER_NAME=docker \
VENV_DIR=${VENV_DIR}
 
ADD ./object.tar.gz $VENV_DIR
 
USER ${USER_NAME}
 
RUN groupadd -r ${USER_NAME} -g ${GROUP_ID} && useradd -u ${USER_ID} -r -g ${GROUP_ID} ${USER_NAME}
RUN apt update && apt upgrade -y
RUN python3 -m venv $VENV_DIR && \
chown -R $USER_ID:$GROUP_ID $VENV_DIR
RUN apt-get clean && rm -rf / var/cache/apt/archives
RUN unzip $VENV_DIR/object.tar.gz
 
WORKDIR $VENV_DIR
EXPOSE 8080
 
ENTRYPOINT ./bin/python3 run.py --port 8080 --json-logging --access-log






FROM python:3.9.18-alpine3.18

LABEL maintainer="Valera" \
      os="Debian"

ARG VENV_DIR=/venv
ARG TARBALL_PATH=./object.tar.gz

ENV USER_ID=500
ENV GROUP_ID=1000
ENV USER_NAME=docker

ADD $TARBALL_PATH $VENV_DIR

RUN groupadd -r $USER_NAME -g $GROUP_ID && useradd -u $USER_ID -r -g $GROUP_ID $USER_NAME
USER $USER_NAME

RUN apt update && apt upgrade -y
RUN python3 -m venv $VENV_DIR && \
chown -R $USER_ID:$GROUP_ID $VENV_DIR
RUN apt-get clean && rm -rf / var/cache/apt/archives

RUN apt-get update && apt-get install -y \

 && rm -rf /var/lib/apt/lists/*


WORKDIR $VENV_DIR
EXPOSE 80

ENTRYPOINT ["./bin/python3", "run.py"]
CMD ["--port 80", "--json-logging", "--access-log"]