FROM phusion/baseimage

MAINTAINER Devin Ridgway

COPY . /root/src/ircbot/

WORKDIR /root/src/ircbot

RUN \
  # Install the DLang repo
  curl http://master.dl.sourceforge.net/project/d-apt/files/d-apt.list -o /etc/apt/sources.list.d/d-apt.list && \
  apt-get update && \
  apt-get -y --allow-unauthenticated install -y --reinstall d-apt-keyring && \

  # Now actually install everything
  apt-get install -y --no-install-recommends --allow-unauthenticated \
    dmd-bin \
    dub \
    libevent-dev \
    libssl-dev \ 
    && \
    
  # Build the program...
  dub build
  
  # Cleanup files...
  rm -rf .dub
  rm -rf source/
  rm -rf *.json
  rm -rf *.sdl

  # Remove what we no longer need
  apt-get uninstall \
    dmd-bin \
    dub \
    && \

  # Now clean out the apt-get cache
  apt-get autoclean && apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

CMD ["./irc_profanity_monitor"]