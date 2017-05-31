FROM concourse/git-resource

RUN curl -L https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o /usr/bin/jq
RUN mv /opt/resource /opt/git-resource

ADD assets/ /opt/resource/
RUN chmod +x /opt/resource/*

