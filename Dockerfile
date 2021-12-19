FROM quay.io/ibmgaragecloud/cli-tools:v0.15

COPY ./entrypoint.sh /action/entrypoint.sh
COPY ./scripts /action/scripts/

ENV HOME /home/devops
USER root

ENTRYPOINT ["/action/entrypoint.sh"]
