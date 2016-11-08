FROM ubuntu
RUN apt-get update && \
    apt-get install -y curl
COPY src/ /
CMD [ "/usr/local/bin/curldriver.sh" ]
