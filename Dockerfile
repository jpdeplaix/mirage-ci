FROM jpdeplaix/opam2-alpine
RUN sudo apk add --no-cache docker
RUN cd /home/opam/opam-repository && git pull origin master && opam update -uy
RUN opam install -y depext
ADD mirage-ci.opam /home/opam/tmp/mirage-ci.opam
RUN opam pin add -yn mirage-ci /home/opam/tmp
RUN opam depext -uvy mirage-ci
RUN opam install -vy --deps-only mirage-ci
RUN opam pin remove -n mirage-ci && sudo rm -r /home/opam/tmp
ADD . /home/opam/src
RUN sudo chown -R opam /home/opam/src
RUN opam pin add -vy mirage-ci /home/opam/src
ENV CONDUIT_TLS=native
ENV OCAMLRUNPARAM=b
USER root
CMD []
