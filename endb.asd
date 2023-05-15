(defsystem "endb"
  :version "0.1.0"
  :author "Håkan Råberg <hakan.raberg@gmail.com>, Steven Deobald <steven@deobald.ca>"
  :license "AGPL-3.0-only"
  :homepage "https://www.endatabas.com/"
  :class :package-inferred-system
  :depends-on ("endb/core"
               "cffi"
               "cl-ppcre"
               "yacc"
               "local-time"
               "trivial-utf-8"
               "mmap"
               "archive"
               "fast-io"
               "trivial-gray-streams"
               "com.inuoe.jzon"
               "cl-hamt")
  :description "Endatabas"
  :pathname "src"
  :build-operation program-op
  :build-pathname "../target/endb"
  :entry-point "endb/core:main"
  :in-order-to ((test-op (test-op "endb-test"))))
