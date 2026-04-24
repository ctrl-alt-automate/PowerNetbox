"""MkDocs page-markdown hook: inject a 'Since vX.Y.Z' badge into platyPS-generated
reference pages, based on the AddedInVersion: line in the cmdlet's .NOTES block."""

from macros.since_badge import extract_since, render_since_admonition


def on_page_markdown(markdown, page, config, files):
    """Insert the Since badge right after the H1 heading of a reference page."""
    version = extract_since(markdown)
    if version is None:
        return markdown
    badge = render_since_admonition(version)
    lines = markdown.splitlines(keepends=True)
    for i, line in enumerate(lines):
        if line.startswith("# "):
            lines.insert(i + 1, "\n" + badge + "\n")
            return "".join(lines)
    return badge + "\n" + markdown
