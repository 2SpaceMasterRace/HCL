(lang dune 3.19)

(name HCL)

(generate_opam_files true)

(source
 (github 2SpaceMasterRace/HCL))

(authors "Hari Varsha V  <v.harivarsha@gmail.com>")

(maintainers "Hari Varsha V  <v.harivarsha@gmail.com>")

(license MIT)

(documentation https://ocamlstreet.gitbook.io/hardcaml-wiki/)

(package
 (name HCL)
 (synopsis "HCL is an open-source, plug-and-play cryptography library for the Arty and Nexys boards for Hardcaml")
 (description "Hardcaml Cryptography Library (HCL) is an open-source, plug-and-play cryptography library that brings Google Tink's philosophy of simplicity and safety to FPGA development using Jane Street's Hardcaml.")
 (depends 
   ocaml
   hardcaml
   hardcaml_waveterm
   ppx_hardcaml
   ppx_jane 
 )
 (tags
  ("Hardcaml" "Cryptography" "OCaml" "FPGA")))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
