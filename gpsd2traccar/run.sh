#!/usr/bin/with-contenv bashio

# Get the device config
CONFIG_PATH="/data/options.json"
DEVICE=$(bashio::config 'device')
BAUDRATE=$(bashio::config 'baudrate' 9600)
GPSD_OPTIONS=$(bashio::config 'gpsd_options') 
GPSD_OPTIONS="${GPSD_OPTIONS} --nowait --readonly --listenany"
GPSD_SOCKET="-F /var/run/gpsd.sock"
CHARSIZE=$(bashio::config 'charsize' 8)
PARITY=$(bashio::config 'parity' false)
STOPBIT=$(bashio::config 'stopbit' 1)
CONTROL="clocal"
TRACCAR_URL=$(bashio::config 'traccar_url')
TRACCAR_DEVICEID=$(bashio::config 'traccar_deviceid')
GPSD_HOST=$(bashio::config 'gpsd_host')
GPSD_PORT=$(bashio::config 'gpsd_port')
HA_AUTH=false

echo "Device: ${DEVICE}"
echo "Baudrate: ${BAUDRATE}"
echo "GPSD Options: ${GPSD_OPTIONS}"
echo "Charsize: ${CHARSIZE}"
echo "Parity: ${PARITY}"
echo "Stopbit: ${STOPBIT}"
echo "Control: ${CONTROL}"
echo "Traccar URL: ${TRACCAR_URL}"
echo "Traccar Device ID: ${TRACCAR_DEVICEID}"
echo "GPSD Host: ${GPSD_HOST}"
echo "GPSD Port: ${GPSD_PORT}"

# Check if the device is a serial device or a network device
# If the GPSD_HOST is set, then it is a network device
# If the GPSD_HOST is not set, then it is a serial device
if [ -z "$GPSD_HOST" ]; then
  # stty expects -parenb to disable parity
  if [ "$PARITY" = false ]; then
    PARITY_CL="-parenb"
  elif [ "$PARITY" = true ]; then
    PARITY_CL="parenb"
  fi

  # stty expects -cstopb to set 1 stop bit per character, cstopb for 2
  if [ "$STOPBIT" -eq 1 ]; then
    STOPBIT_CL="-cstopb"
  elif [ "$STOPBIT" -eq 2 ]; then
    STOPBIT_CL="cstopb"
  fi


  # Serial setup
  #
  # For serial interfaces, options such as low_latency are recommended
  # Also, http://catb.org/gpsd/upstream-bugs.html#tiocmwait recommends
  #   setting the baudrate with stty
  # Uncomment the following lines if using a serial device:
  #

  echo "Setting up serial device with the following: ${DEVICE} ${BAUDRATE} cs${CHARSIZE} ${STOPBIT_CL} ${PARITY_CL} ${CONTROL}"
  /bin/stty -F ${DEVICE} raw ${BAUDRATE} cs${CHARSIZE} ${PARITY_CL} ${CONTROL} ${STOPBIT_CL}
  # /bin/setserial ${DEVICE} low_latency
else
  echo "Setting up network device with the following: ${DEVICE} ${GPSD_HOST} ${GPSD_PORT}"
  DEVICE="gpsd://${GPSD_HOST}:${GPSD_PORT}"
fi

GPSD_OPTIONS="${GPSD_OPTIONS} -s ${BAUDRATE} ${DEVICE}"

# Config file for gpsd server
#usage: gpsd [OPTIONS] device...
#
#  Options include:
#  -?, -h, --help            = help message
#  -b, --readonly            = bluetooth-safe: open data sources read-only
#  -D, --debug integer       = set debug level, default 0
#  -F, --sockfile sockfile   = specify control socket location, default none
#  -f, --framing FRAMING     = fix device framing to FRAMING (8N1, 8O1, etc.)
#  -G, --listenany           = make gpsd listen on INADDR_ANY
#  -l, --drivers             = list compiled in drivers, and exit.
#  -n, --nowait              = don't wait for client connects to poll GPS
#  -N, --foreground          = don't go into background
#  -P, --pidfile pidfile     = set file to record process ID
#  -p, --passive             = do not reconfigure the receiver automatically
#  -r, --badtime             = use GPS time even if no fix
#  -S, --port PORT           = set port for daemon, default 2947
#  -s, --speed SPEED         = fix device speed to SPEED, default none
#  -V, --version             = emit version and exit.

echo "Starting GPSD with device \"${DEVICE}\"..."
/usr/sbin/gpsd --version
/usr/sbin/gpsd ${GPSD_OPTIONS}

#echo "Checking device settings"
#/usr/bin/gpsctl

gpspipe -r | while read line; do
  curl --silent --get "$TRACCAR_URL" \
       --data-urlencode "id=$TRACCAR_DEVICEID" \
       --data-urlencode "nmea=$line"
done
