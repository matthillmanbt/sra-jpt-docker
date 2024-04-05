FROM ubuntu:jammy

COPY bomgar-jpt-*.bin ./

RUN apt-get update

# jpt dependencies
RUN apt-get install -y curl libegl1 libglx0 libopengl0 libx11-6 libdbus-1-3 libfontconfig1 libfreetype6 libxkbcommon0
RUN apt-get install -y libasound2 libxkbfile1

# Set the locale
RUN apt-get install -y locales
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Clean up APT
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Config logging to stderr
RUN echo $'[blog/common] \n\
enabled=1 \n\
 \n\
[blog/0] \n\
enabled=1 \n\
output=stderr \n\
flush_interval=0 \n\
category.ALL=Warning \n\
'>> /etc/blog.ini

# Swap to this for more verbose logging
# RUN echo $'[blog/common] \n\
# enabled=1 \n\
#  \n\
# [blog/0] \n\
# enabled=1 \n\
# output=stderr \n\
# flush_interval=0 \n\
# category.ALL=All \n\
# category.SOCK*=Info \n\
# category.NLS=Info \n\
# category.MRS*=Info \n\
# category.MSG_DSP=Info \n\
# '>> /etc/blog.ini

# jpt user
RUN useradd -ms /bin/bash jpt

# install
ENV BT_VERBOSE_INSTALLER 1
RUN sh bomgar-jpt-*.bin --install-dir /jpt --user jpt

# swap user and run jpt directly
USER jpt
CMD [ "/jpt/bomgar-jpt", "--restart-loop", "1000", "--service"]
