description = ""
requires =
"base
 base_quickcheck
 base_quickcheck.ppx_quickcheck.runtime
 bin_prot
 core
 fieldslib
 hardcaml
 ppx_assert.runtime-lib
 ppx_bench.runtime-lib
 ppx_compare.runtime-lib
 ppx_enumerate.runtime-lib
 ppx_expect.config
 ppx_expect.runtime
 ppx_hash.runtime-lib
 ppx_here.runtime-lib
 ppx_inline_test.config
 ppx_inline_test.runtime-lib
 ppx_log.syntax
 ppx_log.types
 ppx_module_timer.runtime
 ppx_sexp_conv.runtime-lib
 ppx_stable_witness.runtime
 ppx_string.runtime
 sexplib0
 typerep
 variantslib"
archive(byte) = "hcl.cma"
archive(native) = "hcl.cmxa"
plugin(byte) = "hcl.cma"
plugin(native) = "hcl.cmxs"
package "aes" (
  directory = "aes"
  description = ""
  requires =
  "HCL.utils
   base
   base_quickcheck
   base_quickcheck.ppx_quickcheck.runtime
   bin_prot
   core
   fieldslib
   hardcaml
   ppx_assert.runtime-lib
   ppx_bench.runtime-lib
   ppx_compare.runtime-lib
   ppx_enumerate.runtime-lib
   ppx_expect.config
   ppx_expect.runtime
   ppx_hardcaml.runtime
   ppx_hash.runtime-lib
   ppx_here.runtime-lib
   ppx_inline_test.config
   ppx_inline_test.runtime-lib
   ppx_log.syntax
   ppx_log.types
   ppx_module_timer.runtime
   ppx_sexp_conv.runtime-lib
   ppx_stable_witness.runtime
   ppx_string.runtime
   sexplib0
   typerep
   variantslib"
  archive(byte) = "aes.cma"
  archive(native) = "aes.cmxa"
  plugin(byte) = "aes.cma"
  plugin(native) = "aes.cmxs"
)
package "primitives" (
  directory = "primitives"
  description = ""
  requires =
  "HCL.utils
   base
   base_quickcheck
   base_quickcheck.ppx_quickcheck.runtime
   bin_prot
   core
   fieldslib
   hardcaml
   ppx_assert.runtime-lib
   ppx_bench.runtime-lib
   ppx_compare.runtime-lib
   ppx_enumerate.runtime-lib
   ppx_expect.config
   ppx_expect.runtime
   ppx_hash.runtime-lib
   ppx_here.runtime-lib
   ppx_inline_test.config
   ppx_inline_test.runtime-lib
   ppx_log.syntax
   ppx_log.types
   ppx_module_timer.runtime
   ppx_sexp_conv.runtime-lib
   ppx_stable_witness.runtime
   ppx_string.runtime
   sexplib0
   typerep
   variantslib"
  archive(byte) = "primitives.cma"
  archive(native) = "primitives.cmxa"
  plugin(byte) = "primitives.cma"
  plugin(native) = "primitives.cmxs"
)
package "utils" (
  directory = "utils"
  description = ""
  requires =
  "base
   base_quickcheck
   base_quickcheck.ppx_quickcheck.runtime
   bin_prot
   core
   fieldslib
   hardcaml
   ppx_assert.runtime-lib
   ppx_bench.runtime-lib
   ppx_compare.runtime-lib
   ppx_enumerate.runtime-lib
   ppx_expect.config
   ppx_expect.runtime
   ppx_hash.runtime-lib
   ppx_here.runtime-lib
   ppx_inline_test.config
   ppx_inline_test.runtime-lib
   ppx_log.syntax
   ppx_log.types
   ppx_module_timer.runtime
   ppx_sexp_conv.runtime-lib
   ppx_stable_witness.runtime
   ppx_string.runtime
   sexplib0
   typerep
   variantslib"
  archive(byte) = "utils.cma"
  archive(native) = "utils.cmxa"
  plugin(byte) = "utils.cma"
  plugin(native) = "utils.cmxs"
)