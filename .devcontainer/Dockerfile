# --platform=XYZ must be in sync with devcontainer.json:runArgs
# FROM --platform=linux/386 debian:stable-slim
FROM debian:stable-slim

#   ca-certificates: git won't resolve https://ocaml.org without this
#   time: for DKML_BUILD_TRACE=ON in crossplatform-functions.sh
RUN apt update && apt-get -q install -y --no-install-recommends \
    build-essential gcc-multilib g++-multilib \
    ca-certificates git unzip \
    time

ADD https://dl.google.com/android/repository/android-ndk-r27b-linux.zip /android.zip
ENV ANDROID_NDK=/usr/local/lib/android/sdk/android-ndk-r27b
RUN install -d /usr/local/lib/android/sdk && \
    unzip /android.zip -d /usr/local/lib/android/sdk

# This is for ocamllsp/opam based editing inside vscode
RUN apt-get -q install -y --no-install-recommends curl bubblewrap && \
    bash -c "echo /usr/local/bin | sh <(curl -fsSL https://raw.githubusercontent.com/ocaml/opam/b81281400831b5b00e8c30be6d105e2e39e3c7f6/shell/install.sh)" && \
    OPAMYES=1 /usr/local/bin/opam init
ENV OPAMROOTISOK=1
RUN OPAMYES=1 opam install ocaml-lsp-server
