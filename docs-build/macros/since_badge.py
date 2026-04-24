"""Extract AddedInVersion and render a Material 'Since' admonition."""

import re
from typing import Optional

VERSION_PATTERN = re.compile(
    r"^##\s+NOTES\s*\n(?:.*\n)*?\s*AddedInVersion:\s+(?P<version>v?[\d.]+)",
    re.MULTILINE,
)


def extract_since(markdown: str) -> Optional[str]:
    """Return the version string from AddedInVersion line, or None."""
    match = VERSION_PATTERN.search(markdown)
    if match:
        return match.group("version")
    return None


def render_since_admonition(version: str) -> str:
    """Return the Material admonition markup for a Since badge."""
    return f'!!! info inline end "Since"\n    {version}\n'


def register_since_badge(env):
    """Register a since_badge macro for any page that explicitly invokes it."""

    @env.macro
    def since_badge(page_content: str) -> str:
        version = extract_since(page_content)
        if version is None:
            return ""
        return render_since_admonition(version)
