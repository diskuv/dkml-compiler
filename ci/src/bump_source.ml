(* Copied from dkml-component-desktop. We really need this central. Where?
   Only problem is let url = ... statement.
   *)

let read_trimmed_first_line file =
  let ic = open_in file in
  Fun.protect
    ~finally:(fun () -> close_in ic)
    (fun () ->
      let first_line = input_line ic in
      String.trim first_line)

(** [dos2unix s] converts all CRLF sequences in [s] into LF. Assumes [s] is ASCII encoded. *)
let dos2unix s =
  let l = String.length s in
  String.to_seqi s
  (* Shrink [\r\n] into [\n] *)
  |> Seq.filter_map (function
       | i, '\r' when i + 1 < l && s.[i + 1] == '\n' -> None
       | _, c -> Some c)
  |> String.of_seq

let read_file_as_unix file =
  let ic = open_in_bin file in
  Fun.protect
    ~finally:(fun () -> close_in ic)
    (fun () ->
      let s = really_input_string ic (in_channel_length ic) in
      close_in ic;
      dos2unix s)

let replace_or_append_extra_source ~url ~checksum ~opam_source ~download_file =
  let dquot t = Re.(seq [ str "\""; t; str "\"" ]) in
  let regex =
    Re.compile
      Re.(
        seq
          [
            group
              (seq
                 [
                   bol;
                   word @@ str "extra-source";
                   rep space;
                   dquot (str download_file);
                   rep space;
                   str "{";
                   rep space;
                   str "src:";
                   rep space;
                 ]);
            dquot (shortest (rep notnl));
            group (seq [ rep space; str "checksum:"; rep space ]);
            dquot (shortest (rep notnl));
            group (seq [ rep space; str "}" ]);
          ])
  in
  let replaced =
    Re.replace regex
      ~f:(fun g ->
        let g1 = Re.Group.get g 1
        and g2 = Re.Group.get g 2
        and g3 = Re.Group.get g 3 in
        g1 ^ "\"" ^ url ^ "\"" ^ g2 ^ "\"sha256=" ^ checksum ^ "\"" ^ g3)
      opam_source
  in
  print_string replaced

let () =
  let anon (_ : string) = () in
  let opam_file = ref "" in
  let version_file = ref "" in
  let sha256_file = ref "" in
  let download_file = ref "" in
  let artifact = ref "" in
  Arg.parse
    Arg.
      [
        ( "--version-file",
          Set_string version_file,
          "The file containing the version number" );
        ( "--sha256-file",
          Set_string sha256_file,
          "The file containing the SHA-256 checksum" );
        ( "--opam-file",
          Set_string opam_file,
          "The .opam file (or .opam.template) which is copied to the standard \
           output, with any adjustment for the new version and checksum" );
        ( "--download-file",
          Set_string download_file,
          "The location of the file that will be downloaded during opam install"
        );
        ( "--artifact",
          Set_string artifact,
          "The artifact produced by the CI; ie. the basename of the GitLab \
           CI/CD package registry download URL" );
      ]
    anon "dkml-bump-source";
  if String.equal !opam_file "" then failwith "Missing --opam-file OPAMFILE";
  if String.equal !version_file "" then
    failwith "Missing --version-file VERSIONFILE";
  if String.equal !sha256_file "" then
    failwith "Missing --sha256-file CHECKSUMFILE";
  if String.equal !download_file "" then
    failwith "Missing --download-file DOWNLOADFILE";
  if String.equal !artifact "" then failwith "Missing --artifact ARTIFACT";

  let version = read_trimmed_first_line !version_file in
  let checksum = read_trimmed_first_line !sha256_file in
  let opam_source = read_file_as_unix !opam_file in
  let url =
    Printf.sprintf
      "https://github.com/diskuv/dkml-compiler/releases/download/%s/%s"
      version !artifact
  in
  replace_or_append_extra_source ~url ~checksum ~opam_source
    ~download_file:!download_file
