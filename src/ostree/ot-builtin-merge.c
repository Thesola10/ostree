/*
 * Copyright (C) 2024 Karim Vergnes <me@thesola.io>
 *
 * SPDX-License-Identifier: LGPL-2.0+
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library. If not, see <https://www.gnu.org/licenses/>.
 *
 * Author: Karim Vergnes <me@thesola.io>
 */

#include "config.h"

#include "ostree.h"
#include "ot-builtins.h"
#include "otutil.h"

#include <gio/gunixoutputstream.h>

/* ATTENTION:
 * Please remember to update the bash-completion script (bash/ostree) and
 * man page (man/ostree-merge.xml) when changing the option list.
 */

static GOptionEntry options[] = {
  { NULL },
};

gboolean
ostree_builtin_merge (int argc, char **argv, OstreeCommandInvocation *invocation,
                      GCancellable *cancellable, GError **error)
{
  g_autoptr (GOptionContext) context = g_option_context_new ("COMMITA COMMITB");
  g_autoptr (OstreeRepo) repo = NULL;
  if (!ostree_option_context_parse (context, options, &argc, &argv, invocation, &repo, cancellable,
                                    error))
    return FALSE;

  if (argc != 3)
    {
      ot_util_usage_error (context, "Two COMMITs are required", error);
      return FALSE;
    }
  const char *rev_a = argv[1];
  const char *rev_b = argv[2];

  g_autoptr (GFile) root = NULL;
  if (!ostree_repo_read_commit (repo, rev_a, &root, NULL, NULL, error))
    return FALSE;
  else if (!ostree_repo_read_commit (repo, rev_b, &root, NULL, NULL, error))
    return FALSE;

  return TRUE;
}
