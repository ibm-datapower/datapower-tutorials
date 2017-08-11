FROM ibmcom/datapower:latest
ENV  DATAPOWER_ACCEPT_LICENSE=true \
     DATAPOWER_WORKER_THREADS=2 \
     DATAPOWER_INTERACTIVE=true

COPY src/drouter/config /drouter/config
COPY src/drouter/local /drouter/local
COPY src/start /start
COPY src/start.sh /start.sh

USER root
RUN  set-user drouter
USER drouter

EXPOSE 9443
CMD ["/start.sh"]
