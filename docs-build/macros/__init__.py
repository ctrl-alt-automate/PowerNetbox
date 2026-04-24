"""mkdocs-macros entrypoint. The since_badge logic is applied via hooks.py;
this module only registers an (unused) macro to satisfy the mkdocs-macros plugin contract.
"""

from .since_badge import register_since_badge


def define_env(env):
    register_since_badge(env)
