"""MkDocs page-markdown hook: inject a 'Since vX.Y.Z' badge into platyPS-generated
reference pages, based on the AddedInVersion: line in the cmdlet's .NOTES block."""

from macros.since_badge import extract_since, render_since_admonition


def on_page_markdown(markdown, page, config, files):
    """Insert the Since badge right after the H1 heading of a reference page.

    Also overrides edit_url for platyPS-generated cmdlet pages so the
    'Edit on GitHub' pencil points at the source .ps1 file instead of
    the generated .md (which is gitignored and does not exist in the repo).
    """
    # Override edit_url when the page has a 'source:' front matter key
    source = page.meta.get("source") if page.meta else None
    if source:
        repo_url = (config.get("repo_url") or "").rstrip("/")
        if repo_url:
            page.edit_url = f"{repo_url}/edit/dev/{source}"

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
