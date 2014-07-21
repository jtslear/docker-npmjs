# Version: 0.5.2 28-Feb-2014
FROM af9762e08e54
MAINTAINER Terin Stock <terinjokes@gmail.com>

ENV PATH /opt/node/bin/:$PATH

# Install curl
RUN apt-get clean
RUN apt-get install -y curl git

# Create the Datbase
RUN couchdb -b; sleep 5; curl -X PUT http://localhost:5984/registry; sleep 5; couchdb -d;
RUN couch
RUN echo <<EOF>> /usr/local/etc/couchdb/local.ini \
[couch_httpd_auth] \
public_fields = appdotnet, avatar, avatarMedium, avatarLarge, date, email, fields, freenode, fullname, github, homepage, name, roles, twitter, type, _id, _rev \
users_db_public = true \
[httpd] \
secure_rewrites = false \
[couchdb] \
delayed_commits = false \
EOF

# Setup nodejs
RUN mkdir -p /opt/node
RUN curl -L# http://nodejs.org/dist/v0.10.26/node-v0.10.26-linux-x64.tar.gz|tar -zx --strip 1 -C /opt/node

# Download npmjs project
RUN git clone https://github.com/npm/npm-registry-couchapp /opt/npmjs
RUN cd /opt/npmjs; git checkout v2.4.3
RUN cd /opt/npmjs && npm install


RUN /usr/local/bin/couchdb -b; sleep 5; cd /opt/npmjs && npm start \
  --npm-registry-couchapp:couch=http://admin:password@localhost:5984/registry; sleep 5; couchdb -d

RUN /usr/local/bin/couchdb -b; sleep 5; cd /opt/npmjs && npm run load \
  --npm-registry-couchapp:couch=http://admin:password@localhost:5984/registry; sleep 5; couchdb -d

RUN /usr/local/bin/couchdb -b; sleep 5; cd /opt/npmjs && npm run copy \
  --npm-registry-couchapp:couch=http://admin:password@localhost:5984/registry; sleep 5; couchdb -d

#RUN npm install couchapp@0.11.x -g
#RUN cd /opt/npmjs; npm link couchapp; npm install semver

# Configuring npmjs.org
#RUN cd /opt/npmjs; npm set _npmjs.org:couch=http://localhost:5984/registry
## Resolve isaacs/npmjs.org#98
#RUN cd /opt/npmjs; /usr/local/bin/couchdb -b; sleep 5; curl http://isaacs.iriscouch.com/registry/error%3A%20forbidden | curl -X PUT -d @- http://localhost:5984/registry/error%3A%20forbidden?new_edits=false; sleep 5; couchdb -d

# Install npm-delegate
RUN npm install -g kappa@0.14.x

# Start
ADD config/kappa.json.default /opt/npmjs/kappa.json.default
ADD scripts/startup.sh /root/startup.sh
CMD /root/startup.sh
