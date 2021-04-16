FROM quay.io/ibmgaragecloud/cli-tools:v0.13.1-lite

COPY ./entrypoint.sh /action/entrypoint.sh
COPY ./scripts /action/scripts/

ENV HOME /home/devops
USER root

ENTRYPOINT ["/action/entrypoint.sh"]
