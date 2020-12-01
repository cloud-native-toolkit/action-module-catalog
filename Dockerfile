FROM quay.io/ibmgaragecloud/cli-tools:v0.9.0-lite

COPY ./entrypoint.sh /action/entrypoint.sh
COPY ./scripts /action/scripts/

ENTRYPOINT ["/action/entrypoint.sh"]
