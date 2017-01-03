(*---------------------------------------------------------------------------
   Copyright (c) 2016 Anil Madhavapeddy. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open !Astring
open Datakit_ci
open Datakit_github

module Remote = struct
  type t = {
    repo: Repo.t;
    commit: Commit.t;
    full_remote: bool;
  }

  let ( ++ ) x fn =
    match x with
    | 0 -> fn ()
    | r -> r

  let compare {repo; commit; full_remote} b =
    Repo.compare repo b.repo ++ fun () ->
    Commit.compare commit b.commit ++ fun () ->
    Pervasives.compare full_remote b.full_remote

  let pp ppf {repo; commit; full_remote } =
    Fmt.pf ppf "repo=%a commit=%a full_remote=%b"
      Repo.pp repo Commit.pp commit full_remote
end

module type V = sig
  val add_remotes : Remote.t list -> Dockerfile.t

  val set_opam_repo_rev : ?remote:Remote.t -> ?branch:string -> ?dst_branch:string -> string -> Dockerfile.t

  val base : ocaml_version:string -> distro:string -> Dockerfile.t

  val clone_src : user:string -> repo:string -> branch:string -> commit:string ->
      packages:string list -> Dockerfile.t
end

(* If remote is not ocaml/opam-repository, we need to fetch its refs *)
let set_origin =
  let open Dockerfile in
  function
  | Some {Remote.repo;commit;_} when repo.Repo.user <> "ocaml" || repo.Repo.repo <> "opam-repository" ->
     run "git remote set-url origin git://github.com/%s/%s" repo.Repo.user repo.Repo.repo
  | _ -> empty

module V1 = struct
  open !Dockerfile

  let add_remotes rs =
    let remotes_ref = ref 0 in
    List.map (fun {Remote.repo; commit; _} ->
     incr remotes_ref;
     run "opam remote add e%d https://github.com/%s.git#%s"
       !remotes_ref (Fmt.strf "%a" Repo.pp repo) (Commit.hash commit)
    ) rs |> fun remotes ->
    empty @@@ remotes

  let base ~ocaml_version ~distro =
    from ~tag:(distro^"_ocaml-"^ocaml_version) "ocaml/opam"

  let set_opam_repo_rev ?remote ?(branch="master") ?(dst_branch="cibranch") rev =
    workdir "/home/opam/opam-repository" @@
    set_origin remote @@
    run "git fetch origin %s:%s" branch dst_branch @@
    run "git checkout %s" rev

  let clone_src ~user ~repo ~branch ~commit ~packages =
    run "git clone git://github.com/%s/%s /home/opam/src" user repo @@
    workdir "/home/opam/src" @@
    run "git fetch origin %s:cibranch" branch @@
    run "git checkout %s" commit @@@
    List.map (run "opam pin add -n %s /home/opam/src") packages
end

module V2 = struct
  open !Dockerfile

  let add_remotes = V1.add_remotes
  let clone_src = V1.clone_src

  let set_opam_repo_rev ?remote ?(branch="master") ?(dst_branch="cibranch") rev =
    workdir "/home/opam/opam-repository" @@
    run "git checkout master" @@
    set_origin remote @@
    run "git fetch origin %s:%s" branch dst_branch @@
    run "git branch -D v2" @@
    run "git checkout -b v2 %s" rev @@
    run "opam admin upgrade-format" @@
    run "git add ." @@
    run "git commit -a -m 'upgrade format to opam2'"

  let base ~ocaml_version ~distro =
    from ~tag:(distro^"_ocaml-"^ocaml_version) "ocaml/opam-dev"

end

(*
let dfile_v1 ?(pins=[]) ?(remotes=[]) ~ocaml_version ~distro ~opam_repo_git_rev
  ~user ~repo ~branch ~commit ~packages () =
  let open V1 in
  let (@@) = Dockerfile.(@@) in
  base ~ocaml_version ~distro @@
  set_opam_repo_rev opam_repo_git_rev @@
  add_remotes remotes @@
  clone_src ~user ~repo ~branch ~commit ~packages ()

let dfile ?(pins=[]) ?(remotes=[]) ~ocaml_version ~distro ~opam_repo_git_rev (target:Target.t) =
  let open Term.Infix in
  let {Repo.user; repo} = Target.repo target in
  let branch =
    match Target.id target with
    | `PR pr -> Printf.sprintf "pull/%d/head" pr
    | `Ref r -> Fmt.strf "%a" Ref.pp_name r
  in
  Term.target target >>= fun target ->
  let packages = [] in
  let commit = Commit.hash (Target.head target) in
  let dfile = dfile_v1 ~pins ~remotes ~ocaml_version ~distro ~opam_repo_git_rev ~user ~repo ~branch ~commit ~packages () in
  Term.return dfile
*)

(*---------------------------------------------------------------------------
   Copyright (c) 2016 Anil Madhavapeddy

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

