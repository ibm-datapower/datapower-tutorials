FROM ibmcom/datapower:beta

ENV  DATAPOWER_ACCEPT_LICENSE=true \
     DATAPOWER_WORKER_THREADS=2 \
     DATAPOWER_LOG_COLOR=false

EXPOSE 22 9090

COPY auto-startup.cfg /drouter/config/auto-startup.cfg
