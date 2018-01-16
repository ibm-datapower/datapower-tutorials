FROM ibmcom/datapower:latest
ENV  DATAPOWER_ACCEPT_LICENSE=true \
     DATAPOWER_INTERACTIVE=true \
     DATAPOWER_FAST_STARTUP=true

COPY src/config /drouter/config
COPY src/local /drouter/local

USER root
RUN  set-user drouter
USER drouter

EXPOSE 8080
