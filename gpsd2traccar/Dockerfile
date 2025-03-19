ARG BUILD_FROM
FROM $BUILD_FROM

# Execute during the build of the image
ARG TEMPIO_VERSION BUILD_ARCH

RUN apk add --no-cache gpsd gpsd-clients bash py3-pip py3-gpsd
# RUN pip install --break-system-packages gpsdclient ubxtool

# Copy data for add-on
COPY run.sh /

RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
