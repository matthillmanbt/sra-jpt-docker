FROM ubuntu:jammy

COPY bomgar-jpt-*.bin ./
# Save name for later
RUN echo /bomgar-jpt-* >> /.installer-name

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

ENV BT_VERBOSE_INSTALLER 1
RUN head -n $(($(grep -an "^INSTALL" bomgar-jpt-* | head -1 | cut -f1 -d':') - 1)) bomgar-jpt-* | sed -e 's/"$abs_script" | tar/\/bomgar-jpt-* | tar/g' > /tmp/unpack
RUN chmod +x /tmp/unpack
RUN /tmp/unpack
RUN find /tmp -name install_after_unpack | xargs dirname | xargs -I{} mv {} /tmp/jpt
RUN cat /tmp/jpt/install_after_unpack | sed -e 's/--setup/--test/g' > /tmp/install_partial
RUN cp -f /tmp/install_partial /tmp/jpt/install_after_unpack
ENV UNPACK_DIR /tmp/jpt
RUN /tmp/jpt/install_after_unpack --install-dir /jpt --user jpt

# Cleanup
RUN rm -rf /tmp/jpt /bomgar-jpt-* /tmp/install_partial /tmp/unpack

COPY jumpzone.ini /jpt/jumpzone.ini

# swap user and run jpt directly
USER jpt
CMD [ "sh", "-c", "cat /.installer-name | xargs /jpt/bomgar-jpt --setup && /jpt/bomgar-jpt --restart-loop 1000 --service"]
