(*---------------------------------------------------------------------------
   Copyright (c) 2017 Anil Madhavapeddy. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open !Astring

open Datakit_ci
open Datakit_github
module DO = Docker_ops

module Builder = struct

  open Term.Infix

  let opam_repo = Repo.v ~user:"ocaml" ~repo:"opam-repository"
  let opam_repo_branch = "master"
  let opam_repo_remote = opam_repo, opam_repo_branch
  let primary_ocaml_version = "4.04.0"
  let compiler_variants = ["4.02.3";"4.03.0";"4.04.0_flambda"]

  let label = "opamRepo"
  let docker_t = DO.v ~logs ~label ~jobs:24 ()
  let opam_t = Opam_build.v ~logs ~label ~version:`V1
  let do_build = Opam_ops.distro_build ~opam_repo:opam_repo_remote ~opam_t ~docker_t

  let run_phases ?(extra_remotes=[]) () (target:Target.t) =
    let build ~distro ~ocaml_version =
      Opam_ops.packages_from_diff docker_t target >>= fun packages ->
      do_build ~typ:`Repo ~target ~extra_remotes ~packages ~distro ~ocaml_version () in
    (* phase 1 *)
    let ubuntu = build "ubuntu-16.04" primary_ocaml_version in
    let phase1 = ubuntu >>= fun _ -> Term.return () in
    (* phase 2 revdeps *)
    let pkg_revdeps =
      Term.without_logs ubuntu >>= fun img ->
      Opam_ops.packages_from_diff docker_t target >>= fun packages ->
      Opam_ops.build_revdeps docker_t packages img in
    let phase2 =
      Term_utils.after phase1 >>= fun () ->
      pkg_revdeps in
    (* phase 3 compiler variants *)
    let compiler_versions =
      List.map (fun oc ->
        let t = build "alpine-3.5" oc in
        ("OCaml "^oc), t
      ) compiler_variants in
    let phase3 =
      Term_utils.after phase2 >>= fun () ->
      Term.wait_for_all compiler_versions in
    (* phase 4 *)
    let debian = build "debian-stable" primary_ocaml_version in
    let ubuntu1604 = build "ubuntu-16.04" primary_ocaml_version in
    let centos7 = build "centos-7" primary_ocaml_version in
    let phase4 =
      Term_utils.after phase3 >>= fun () ->
      Term.wait_for_all [
        "Debian Stable", debian;
        "Ubuntu 16.04", ubuntu1604;
        "CentOS7", centos7 ] in
    (* phase 5 *)
    let debiant = build "debian-testing" primary_ocaml_version in
    let debianu = build "debian-unstable" primary_ocaml_version in
    let opensuse = build "opensuse-42.1" primary_ocaml_version in
    let fedora24 = build "fedora-24" primary_ocaml_version in
    let phase5 =
      Term_utils.after phase4 >>= fun () ->
      Term.wait_for_all [
        "Debian Testing", debiant;
        "Debian Unstable", debianu;
        "OpenSUSE 42.1", opensuse;
        "Fedora 24", fedora24 ]
    in
    let all_tests = 
      [ Term_utils.report ~order:1 ~label:"Build" phase1;
        Term_utils.report ~order:2 ~label:"Revdeps" phase2;
        Term_utils.report ~order:3 ~label:"Compilers" phase3;
        Term_utils.report ~order:4 ~label:"Common Distros" phase4;
        Term_utils.report ~order:5 ~label:"All Distros" phase5;
      ] in
    match Target.id target with
    |`PR _  -> all_tests
    | _ -> []

  let tests = [
    Config.project ~id:"ocaml/opam-repository" (run_phases ())
  ]
end

(* Command-line parsing *)

let web_config =
  Web.config
    ~name:"opam-repo-ci"
    ~can_read:ACL.(everyone)
    ~can_build:ACL.(github_org "mirage")
    ~state_repo:(Uri.of_string "https://github.com/ocaml/ocaml-ci.logs")
    ()

let () =
  run (Cmdliner.Term.pure (Config.v ~web_config ~projects:Builder.tests))

(*---------------------------------------------------------------------------
   Copyright (c) 2016 Anil Madhavapeddy
   Copyright (c) 2016 Thomas Leonard

   Permission to use, copy, modify, and/or distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  ---------------------------------------------------------------------------*)
