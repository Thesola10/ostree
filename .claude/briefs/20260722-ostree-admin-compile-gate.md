# Task: Gate `ostree admin` behind `--enable-ostree-admin`

## Context
Follow-on to `20260722-libgnonlnx-porting.md`. That brief cordoned off the
`ostree admin` deployment manager as out of scope for the portable core
(object storage + transfer). This brief makes that boundary a build-time
guarantee rather than just a scoping note: on non-Linux platforms there's no
reason to even compile deployment-management code that will never build or
run there.

## Goal
Add a `--enable-ostree-admin` configure/meson option (default reflects
current behavior on Linux; needs a decision — see open questions) that
controls whether the `ostree admin` subcommand and its supporting code are
built at all.

## Steps
1. Re-use the exclusion boundary identified in the porting brief/report —
   the same directories/files that were excluded from the libglnx call-site
   scan are the ones to gate here. Confirm that list still matches (the
   report from that task should have the final, verified list; don't
   re-derive from scratch if it's already documented there).
2. Determine what build system OSTree actually uses (Meson vs Autotools —
   check the repo, don't assume) and add the option there:
   - Meson: `option('enable-ostree-admin', type: 'boolean', value: true)` in
     `meson_options.txt`, wire into `meson.build` to conditionally include
     the admin sources/subcommand registration.
   - Autotools equivalent if that's what's in use.
3. Ensure the CLI itself reflects the flag — `ostree admin ...` should fail
   with a clear "not built with admin support" error (or simply not be
   registered as a subcommand at all) when compiled with the flag off,
   rather than a generic "unknown command" or, worse, a link error.
4. Confirm the flag can be set to off on the MinGW/portable build without
   pulling in any admin-only dependencies transitively (this is the actual
   point of the exercise — verify it, don't just assume the gate is clean).
5. Update build docs/README to mention the flag.

## Open questions
- **Default value**: `true` on Linux (preserve existing behavior for
  existing users/packagers) with the portable build explicitly passing
  `-Denable-ostree-admin=false`? Or should the default be platform-detected
  (on by default on Linux, off by default elsewhere)? Leaning toward
  explicit opt-out per-build rather than platform-sniffing in the build
  file, but worth deciding before implementation.
- Should this also gate any admin-only libglnx/libgnonlnx calls that were
  excluded from the stub scan, or is admin code entirely separate from the
  libgnonlnx surface by construction? Worth a quick check — if admin code
  happens to call something in the stubbed set, gating admin out could
  actually shrink the required stub surface further.

## Deliverable
- Build system changes (meson/autotools) adding the flag.
- CLI-level guard so the subcommand cleanly reports its own absence.
- Confirmation (build log or dependency check) that the portable build with
  the flag off pulls in zero admin-only dependencies.
- Doc update noting the flag and its default.
