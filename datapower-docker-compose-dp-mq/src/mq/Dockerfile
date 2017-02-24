FROM jefurbee/mq8
ENV LICENSE=accept \
    MQ_QMGR_NAME=TEST_GROW_QM_REQ
COPY config.mqsc /etc/mqm/
RUN useradd joedoe -G mqm && \
    echo joedoe:passw0rd | chpasswd

