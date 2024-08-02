FROM ubuntu:jammy

COPY bomgar-jpt-*.bin ./

COPY <<__eof__  /etc/X11/xorg.conf
Section "Device"
    Identifier "dummy_videocard"
    Driver "dummy"
    Option "ConstantDPI" "true"
    VideoRam 512000
    #VideoRam 256000
    #VideoRam 192000
EndSection

Section "Monitor"
    Identifier "dummy_monitor"
    HorizSync 28.0-80.0
    VertRefresh 48.0-75.0

    #NOTE: the highest modes will not work without increasing the VideoRam for the dummy video card.

    # To create specific modeline - https://arachnoid.com/modelines/
    Modeline "5120x3200_60.00" 1420.39 5120 5560 6136 7152 3200 3201 3204 3310 -HSync +Vsync
    Modeline "3840x2880_60.00" 958.05 3840 4168 4600 5360 2880 2881 2884 2979 -HSync +Vsync
    Modeline "3840x2560_60.00" 849.05 3840 4168 4592 5344 2560 2561 2564 2648 -HSync +Vsync
    Modeline "3840x2048_60.00" 675.37 3840 4152 4576 5312 2048 2049 2052 2119 -HSync +Vsync
    Modeline "2048x2048_60.00" 360.06 2048 2216 2440 2832 2048 2049 2052 2119 -HSync +Vsync
    Modeline "2560x1600_60.00" 348.16 2560 2752 3032 3504 1600 1601 1604 1656 -HSync +Vsync
    Modeline "1920x1440_60.00" 234.59 1920 2064 2272 2624 1440 1441 1444 1490 -HSync +Vsync
    Modeline "1920x1200_60.00" 193.16 1920 2048 2256 2592 1200 1201 1204 1242 -HSync +Vsync
    Modeline "1920x1080_60.00" 172.80 1920 2040 2248 2576 1080 1081 1084 1118 -HSync +Vsync
    Modeline "1680x1050_60.00" 147.14 1680 1784 1968 2256 1050 1051 1054 1087 -HSync +Vsync
    Modeline "1600x1200_60.00" 160.96 1600 1704 1880 2160 1200 1201 1204 1242 -HSync +Vsync
    Modeline "1600x900_60.00" 119.00 1600 1696 1864 2128 900 901 904 932 -HSync +Vsync
    Modeline "1400x1050_60.00" 122.61 1400 1488 1640 1880 1050 1051 1054 1087 -HSync +Vsync
    Modeline "1440x900_60.00" 106.47 1440 1520 1672 1904 900 901 904 932 -HSync +Vsync
    Modeline "1368x768_60.00" 85.86 1368 1440 1584 1800 768 769 772 795 -HSync +Vsync
    Modeline "1280x1024_60.00" 108.88 1280 1360 1496 1712 1024 1025 1028 1060 -HSync +Vsync
    Modeline "1280x800_60.00" 83.46 1280 1344 1480 1680 800 801 804 828 -HSync +Vsync
    Modeline "1024x768_60.00" 64.11 1024 1080 1184 1344 768 769 772 795 -HSync +Vsync
    Modeline "1024x600_60.00" 48.96 1024 1064 1168 1312 600 601 604 622 -HSync +Vsync
    Modeline "800x600_60.00" 38.22 800 832 912 1024 600 601 604 622 -HSync +Vsync
    Modeline "320x200_60.00" 4.19 320 304 328 336 200 201 204 208 -HSync +Vsync
EndSection

Section "Screen"
    Identifier "dummy_screen"
    Device "dummy_videocard"
    Monitor "dummy_monitor"
    DefaultDepth 24
    SubSection "Display"
        Viewport 0 0
        Depth 24
        Modes "5120x3200_60.00" "3840x2880_60.00" "3840x2560_60.00" "3840x2048_60.00" "2048x2048_60.00" "2560x1600_60.00" "1920x1440_60.00" "1920x1200_60.00" "1920x1080_60.00" "1680x1050_60.00" "1600x1200_60.00" "1600x900_60.00" "1400x1050_60.00" "1440x900_60.00" "1368x768_60.00" "1280x1024_60.00" "1280x800_60.00" "1024x768_60.00" "1024x600_60.00" "800x600_60.00" "320x200_60.00"
        # Virtual 8192 4096
    EndSubSection
EndSection

Section "ServerLayout"
    Identifier   "dummy_layout"
    Screen       "dummy_screen"
EndSection
__eof__

# Config logging to stderr
COPY <<__eof__ /etc/blog.ini
[blog/0]
enabled=1
output=stderr
flush_interval=0
category.ALL=Warning
__eof__

COPY <<__eof__ /start.sh
#!/bin/bash
set -ex
/usr/bin/X :1 vt1 +extension GLX +extension RANDR +extension RENDER -noreset -novtswitch -nolisten tcp -background none -config /etc/X11/xorg.conf &
cat /.installer-name | xargs /jpt/bomgar-jpt --setup
/jpt/bomgar-jpt --restart-loop 1000 --service
__eof__

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV BT_VERBOSE_INSTALLER=1
ENV UNPACK_DIR=/tmp/jpt

# Save name for later
RUN echo /bomgar-jpt-* >> /.installer-name && \
    apt-get update && \
# jpt dependencies
    apt-get install -y curl libegl1 libglx0 libopengl0 libx11-6 libdbus-1-3 libfontconfig1 libfreetype6 libxkbcommon0 && \
    apt-get install -y libasound2 libxkbfile1 && \
    apt-get install -y libglib2.0-dev libnss3 libnspr4 libatk1.0-dev libatk-bridge2.0-dev libcups2-dev && \
    apt-get install -y libxcomposite-dev libxdamage-dev libxrandr-dev libpango1.0-dev libcairo2 libatspi2.0-dev && \
# web jump needs all this
    apt-get -y install xserver-xorg-video-dummy x11-apps x11-xserver-utils && \
\
    mkdir -p /tmp/.X11-unix && \
    chmod 777 /tmp/.X11-unix && \
# Set the locale
    apt-get install -y locales && \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen && \
# jpt user and unpack
    useradd -ms /bin/bash jpt && \
    head -n $(($(grep -an "^INSTALL" bomgar-jpt-* | head -1 | cut -f1 -d':') - 1)) bomgar-jpt-* | sed -e 's/"$abs_script" | tar/\/bomgar-jpt-* | tar/g' > /tmp/unpack && \
    chmod +x /tmp/unpack && \
    /tmp/unpack && \
    find /tmp -name install_after_unpack | xargs dirname | xargs -I{} mv {} /tmp/jpt && \
    cat /tmp/jpt/install_after_unpack | sed -e 's/--setup/--test/g' > /tmp/install_partial && \
    cp -f /tmp/install_partial /tmp/jpt/install_after_unpack && \
    /tmp/jpt/install_after_unpack --install-dir /jpt --user jpt && \
# finish setup
    chmod a+x /start.sh && \
# Clean up
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    rm -rf /tmp/jpt /bomgar-jpt-* /tmp/install_partial /tmp/unpack

# Jumpzone proxy configuration
COPY <<__eof__ /jpt/jumpzone.ini
[General]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; BeyondTrust Jump Zone Proxy Configuration ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; ALL configuration changes require a restart
; of the Jumpoint process/service/daemon

; * Enable the Jump Zone Proxy feature
; * Default is disabled.
enable_proxy=1

; * Allow HTTP GET requests through the proxy
; * to the BeyondTrust appliance.
; * Default is to not allow HTTP GET requests.
allow_http=1

; * Hostname or IP that resolves to this machine
; * Jump Clients will be deployed with and use
; * this information to connect back to this machine
; * Default hostname is detected using gethostname(2)
;proxy_host=myhost.local

; * Port number on this machine that should
; * listen for incoming Jump Client connections
; * Default port is 9555
;proxy_port=9555

; * Comma seperated IP addresses or CIDR subnets
; * that incoming connections should be restricted to.
; * Default is allow all connections.
; * Only one of allowOnlyIPs or denyOnlyIPs may be used.
;allowOnlyIPs=1.2.3.4,4.3.2.1/16

; * Comma seperated IP addresses or CIDR subnets
; * that should be denied incoming connections.
; * Default is allow all connections.
; * Only one of allowOnlyIPs or denyOnlyIPs may be used.
;denyOnlyIPs=1.2.3.4,4.3.2.1/16
__eof__

# swap user and run jpt directly
USER jpt
CMD [ "/start.sh" ]
