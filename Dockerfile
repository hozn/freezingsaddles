# BUILD
# =====

FROM python:2.7-jessie as buildstep
RUN apt-get install libmysqlclient-dev

RUN mkdir -p /build/wheels
RUN pip install --upgrade pip setuptools wheel

ADD requirements.txt /tmp/requirements.txt
RUN pip wheel -r /tmp/requirements.txt --no-binary MySQL-python --wheel-dir=/build/wheels

# DEPLOY
# =====

# FIXME: Extend from a smaller image ... but need to work out issues w/ MySQL binary .so files
# linking against libpython2.7.so.1.0 ...
# Or, maybe better, just use an ubuntu builder image ...

FROM python:2.7-jessie as deploystep

# This is an Ubuntu sources.list
# COPY resources/docker/sources.list /etc/apt/sources.list

RUN apt-get update \
  && apt-get install -y python2.7 python-pip libmysqlclient-dev vim-tiny --no-install-recommends \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /config
RUN mkdir -p /data

VOLUME /config
VOLUME /data

RUN pip install --upgrade pip setuptools wheel

# Place app source in container.
COPY . /app
WORKDIR /app

COPY --from=buildstep /build/wheels /tmp/wheels

RUN pip install /tmp/wheels/*

# Install app symlinks (this works better right now than python setup.py install,
# since there are some scripts that assume they are running from app directory.)
RUN python setup.py develop

EXPOSE 5000

ENV BAFS_SETTINGS=/config/settings.cfg

# There are lots of uses for this image, so we don't specify an entrypoint.
# Available commands are basically any of the scripts:
# bafs-init-db
# bafs-sync
# bafs-sync-detail
# bafs-sync-streams
# bafs-sync-photos
# bafs-sync-weather
# bafs-sync-athletes
# bafs-server

# ENTRYPOINT bafs-server