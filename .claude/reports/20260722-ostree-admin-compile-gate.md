# Report: Gate `ostree admin` behind `--enable-ostree-admin`

Brief: `.claude/briefs/20260722-ostree-admin-compile-gate.md`

## Summary

Added a `--enable-ostree-admin` Autotools option that controls whether the
`ostree admin` subcommand and its supporting sources are compiled at all.

- **Build system is Autotools**, not Meson (confirmed via `configure.ac` /
  `Makefile*.am`; the only `meson.build` files in the tree belong to the
  `libglnx` submodule, which was explicitly out of scope per the user).
- `configure.ac`: added `AC_ARG_ENABLE(ostree-admin, ...)` with a
  platform-detected default — `yes` when `$host_os` matches `linux*`, `no`
  otherwise (per user decision; no explicit per-build opt-out needed).
  Wired to `AM_CONDITIONAL(BUILDOPT_OSTREE_ADMIN, ...)` for the Makefile and
  `AC_DEFINE([OSTREE_DISABLE_ADMIN], ...)` for C code, following the same
  pattern already used for `OSTREE_DISABLE_GPGME`. Added a summary line
  (`ostree admin subcommand: yes/no`) to the configure output.
- `Makefile-ostree.am`: moved `ot-builtin-admin.c` (the subcommand
  dispatcher) into the existing "Admin subcommand" source block and wrapped
  that whole block in `if BUILDOPT_OSTREE_ADMIN ... endif`.
- `src/ostree/ot-builtins.h` / `src/ostree/main.c`: guarded the `admin`
  prototype and command-table entry with `#ifndef OSTREE_DISABLE_ADMIN`. When
  disabled, `admin` is still registered in the command table but points at a
  small stub (`ostree_builtin_admin_disabled`) that reports a clear error —
  *"This build of ostree was compiled without \"ostree admin\" support
  (--enable-ostree-admin was not set)"* — rather than falling through to the
  generic "Unknown command" path or risking a link error.
- `README.md`: documented the flag and its default under "Building".

## Deviations / resolutions

- **Open question 1 (default value)**: resolved by the user as
  platform-detected (`linux*` → on, else → off), not an explicit
  per-build opt-out. Implemented via a `case "$host_os" in ...` check,
  gated behind an explicit `AC_CANONICAL_HOST` call (LT_INIT sets `$host_os`
  as a side effect, but calling it explicitly makes the dependency visible
  rather than incidental).
- **Open question 2 (libglnx gating)**: the user said not to gate any
  libglnx call sites and to only touch the main `ostree` repo, so that part
  of the brief was dropped entirely. Separately — and this wasn't quite the
  same question — I found that `ot-admin-functions.c`/`.h` (helpers like
  `ot_admin_checksum_version` and `ot_admin_sysroot_lock`) are called from
  `ot-dump.c` and `ot-main.c`, which are core CLI files, not admin-only. So
  those two files were deliberately **left out of the gate** — admin code is
  *not* entirely separate from the rest of the CLI by construction, but the
  shared surface is narrow and now-nonadmin-specific enough to stay
  unconditional. Excluding them would have broken the non-admin build.
- **Brief step 3's two suggested outcomes were in tension**: "fail with a
  clear error" vs. "simply not be registered" — the latter would actually
  produce the generic "Unknown command" message the brief says to avoid.
  Went with the clear-error stub instead, which satisfies the brief's
  literal preference and sidesteps the contradiction.
- **Deliverable "confirmation that the portable build with the flag off
  pulls in zero admin-only dependencies" — done by construction, not by a
  full cross build.** The main (non-libglnx) ostree tree hasn't been ported
  to MinGW yet (per repo history, only the `libglnx` submodule has a
  tentative port so far), so a full `pkgsCross.mingwW64` build of the whole
  tree isn't expected to succeed yet for reasons unrelated to this change.
  What was verified instead:
  - None of the gated admin sources are referenced by any
    `PKG_CHECK_MODULES`/`AC_ARG_WITH` dependency check in `configure.ac` —
    disabling the flag only removes source files from
    `ostree_SOURCES`, it can't add or remove a detected dependency.
  - Ran `autogen.sh` + `./configure` natively on Linux and confirmed the
    summary correctly reports `ostree admin subcommand: yes` (default-on
    path). Did not run the disabled path or a full `make`/cross build —
    left for the user to do themselves, per their request mid-session.
- **Man pages** (`Makefile-man.am`, `man/ostree-admin*.xml`) were left
  ungated. They're static docs processed by `xsltproc`, not compiled code,
  so they don't affect the "zero admin-only dependencies" goal, and gating
  them wasn't asked for.

## Open items

- No `make`/build verification of either configure path was run to
  completion in this session (native build was left for the user; MinGW
  build isn't expected to work yet regardless of this change).
- No test coverage was added for the disabled-admin CLI stub message.
