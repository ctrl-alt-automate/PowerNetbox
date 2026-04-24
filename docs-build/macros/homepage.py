"""Homepage macros: cmdlet count, latest release, compat table."""

import json
import re
import subprocess
from pathlib import Path


# Resolve PowerNetbox.psd1 relative to this file's location, not CWD.
# docs-build/macros/homepage.py -> docs-build/macros -> docs-build -> worktree root
PSD1_PATH = Path(__file__).parent.parent.parent / "PowerNetbox.psd1"


def _count_public_cmdlets() -> int:
    """Count Verb-NB* entries in the FunctionsToExport block of the psd1."""
    # utf-8-sig strips BOM if present
    content = PSD1_PATH.read_text(encoding="utf-8-sig")
    entries = re.findall(r"'([A-Z][a-z]+-NB[^']+)'", content)
    return len(entries)


def _fetch_latest_release() -> dict | None:
    """Call `gh api ...releases/latest` and return parsed JSON, or None on failure."""
    try:
        out = subprocess.check_output(
            ["gh", "api", "repos/ctrl-alt-automate/PowerNetbox/releases/latest"],
            text=True,
            stderr=subprocess.DEVNULL,
            timeout=30,
        )
        return json.loads(out)
    except Exception:
        return None


def register_homepage(env):
    """Register homepage macros with the mkdocs-macros env."""

    @env.macro
    def cmdlet_count() -> str:
        return str(_count_public_cmdlets())

    @env.macro
    def latest_release() -> str:
        release = _fetch_latest_release()
        if release is None:
            return "*(release info unavailable in this build context)*"

        tag = release["tag_name"]
        version = tag.lstrip("v")
        date = release["published_at"][:10]
        body_lines = release.get("body", "").splitlines()[:6]
        preview = "\n".join(body_lines)

        return (
            f"### [v{version}](release-notes/{version}.md) - {date}\n\n"
            f"{preview}\n\n"
            f"[Full changelog](release-notes/{version}.md)"
        )

    @env.macro
    def compat_table() -> str:
        """Hand-curated compatibility table. Update the truth in CLAUDE.md
        when PowerNetbox compat changes."""
        return (
            "| PowerNetbox | NetBox target | Also supports | PowerShell |\n"
            "|---|---|---|---|\n"
            "| 4.5.8.x | 4.5.8 | 4.3.7, 4.4.10 | 5.1+ / 7+ |"
        )
