FROM ubuntu
RUN apt-get update && \
    apt-get install -y curl
ENV TIMEOUT=60 \
    CONTINUOUS=false
COPY src/ /
CMD [ "/usr/local/bin/curlrequest.sh" ]
