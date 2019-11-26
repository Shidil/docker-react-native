FROM openjdk:8

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8
LABEL Description="This image provides a base Android development environment for React Native, and may be used to run tests."
LABEL MAINTAINER="Shidil Eringa <shidil@live.com>"

ARG NODEJS_VERSION=12.10.0
ARG NDK_VERSION=19c
ARG ANDROID_PLATFORM=28
ARG BUILD_TOOLS_VERSION=28.0.3
ARG SDK_VERSION=4333796

# Variables
ENV ANDROID_HOME="/opt/android"
ENV GRADLE_HOME="/usr/share/gradle"
ENV NODEJS_HOME="/nodejs"

ENV ANDROID_APIS="platforms;android-28"
ENV ANDROID_NDK=/opt/ndk/android-ndk-r$NDK_VERSION
ENV ANDROID_SDK_URL=https://dl.google.com/android/repository/sdk-tools-linux-${SDK_VERSION}.zip
ENV ANDROID_SUPPORT_LIBS="add-ons;addon-google_apis-google-23 extras;google;m2repository extras;android;m2repository platform-tools"
ENV ANDROID_BUILD_TOOLS_VERSION_28="build-tools;28.0.3"

ENV BABEL_DISABLE_CACHE=1

ENV PATH $PATH:$ANDROID_HOME/tools:$PATH:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/$ANDROID_BUILD_TOOLS_VERSION
ENV PATH=${PATH}:${ANDROID_NDK}
ENV PATH=${PATH}:$GRADLE_HOME/bin:$NODEJS_HOME/bin

WORKDIR /opt

# Gradle setup
RUN dpkg --add-architecture i386 && \
  apt-get -qq update && \
  apt-get -qq install -y wget curl gradle libncurses5:i386 libstdc++6:i386 zlib1g:i386


# download and unpack NDK
RUN curl -sS https://dl.google.com/android/repository/android-ndk-r$NDK_VERSION-linux-x86_64.zip -o /tmp/ndk.zip \
    && mkdir /opt/ndk \
    && unzip -q -d /opt/ndk /tmp/ndk.zip \
    && rm /tmp/ndk.zip

# Android SDK Install
RUN mkdir /root/.android && touch /root/.android/repositories.cfg
RUN curl -sS ${ANDROID_SDK_URL} -o /tmp/sdk.zip \
  && mkdir android \
  && unzip -q -d /opt/android /tmp/sdk.zip \
  && rm /tmp/sdk.zip \
  && chmod a+x -R $ANDROID_HOME \
  && chown -R root:root $ANDROID_HOME

# Android SDK Setup
RUN yes | sdkmanager --licenses && sdkmanager --update
RUN sdkmanager ${ANDROID_SUPPORT_LIBS} \
  && sdkmanager ${ANDROID_APIS} \
  && sdkmanager ${ANDROID_BUILD_TOOLS_VERSION_26}

# Install nodejs
RUN apt-get update -y && apt-get install --no-install-recommends -y -q curl python build-essential git ca-certificates && \
  mkdir /nodejs && \
  curl http://nodejs.org/dist/v${NODEJS_VERSION}/node-v${NODEJS_VERSION}-linux-x64.tar.gz | tar xvzf - -C /nodejs --strip-components=1 && \
  chown -R 1000 /nodejs

# install ncftp
RUN apt-get install ncftp

# Install yarn
RUN npm install --global yarn

# Clean up steps
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  apt-get autoremove -y && \
  apt-get clean

# Add 1000 user/group to get git working
RUN groupadd --gid 1000 node && \
  useradd --uid 1000 --gid node --shell /bin/bash --create-home /nodejs
