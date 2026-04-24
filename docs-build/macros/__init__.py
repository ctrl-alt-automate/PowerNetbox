"""mkdocs-macros entrypoint. The since_badge logic is applied via hooks.py;
this module registers unused macros to satisfy the mkdocs-macros plugin contract.

The homepage macros (cmdlet_count, latest_release, compat_table) are invoked
from docs/index.md via `{{ fn() }}` syntax under `render_macros: true`."""

from .homepage import register_homepage
from .since_badge import register_since_badge


def define_env(env):
    register_since_badge(env)
    register_homepage(env)
