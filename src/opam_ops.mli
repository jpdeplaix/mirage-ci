(*---------------------------------------------------------------------------
   Copyright (c) 2016 Anil Madhavapeddy. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Datakit_ci.Term

val build_revdep : Docker_build.t -> Docker_build.image -> string -> Docker_build.image t

val build_revdeps : Docker_build.t -> Docker_build.image -> string -> unit t

val build_package : Docker_build.t -> Docker_build.image -> string -> Docker_build.image t

val build_packages : Docker_build.t -> Docker_build.image -> string list -> unit t

val revdeps : Docker_build.t -> Docker_run.t -> string list -> Docker_build.image -> unit t

val list_revdeps : Docker_run.t -> Docker_build.image -> string -> string t

val list_all_packages : Docker_run.t -> Docker_build.image -> string list t
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
