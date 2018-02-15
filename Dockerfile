FROM jpdeplaix/opam2-alpine
RUN sudo apk add --no-cache docker
RUN cd /home/opam/opam-repository && git pull origin master && opam update -uy
RUN opam install -y depext
RUN opam pin add -n redis git://github.com/0xffea/ocaml-redis.git
RUN opam pin add -n redis-lwt git://github.com/0xffea/ocaml-redis.git
RUN opam depext -uivy ppx_sexp_conv dockerfile-cmd datakit-ci datakit-client fpath asetmap bos cmdliner rresult sexplib ptime
ADD . /home/opam/src
RUN sudo chown -R opam /home/opam/src
RUN opam pin add -vy mirage-ci /home/opam/src
ENV CONDUIT_TLS=native
ENV OCAMLRUNPARAM=b
USER root
CMD []
