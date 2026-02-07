import re
from html.parser import HTMLParser


class _HeadingParser(HTMLParser):
    """Simple HTML parser that extracts heading tags (h1-h6)."""

    def __init__(self):
        super().__init__()
        self._current_tag = None
        self.headings = []

    def handle_starttag(self, tag, attrs):
        if tag in ("h1", "h2", "h3", "h4", "h5", "h6"):
            self._current_tag = tag
            self.headings.append({"tag": tag, "text": ""})

    def handle_endtag(self, tag):
        if tag == self._current_tag:
            self._current_tag = None

    def handle_data(self, data):
        if self._current_tag is not None:
            self.headings[-1]["text"] += data.strip()


class _MetaTagParser(HTMLParser):
    """Simple HTML parser that extracts <meta> tags with property and content attributes."""

    def __init__(self):
        super().__init__()
        self.meta_tags = {}

    def handle_starttag(self, tag, attrs):
        if tag == "meta":
            attrs_dict = dict(attrs)
            prop = attrs_dict.get("property", "")
            content = attrs_dict.get("content", "")
            if prop and content:
                self.meta_tags[prop] = content


def register(mcp):
    """Register all SEO tools with the MCP server."""

    @mcp.tool()
    def check_meta_title(title: str) -> dict:
        """Check a page's meta title tag for SEO best practices.

        Validates the title length against the recommended range of 30-60
        characters and provides actionable feedback.
        """
        length = len(title)
        min_len = 30
        max_len = 60

        if min_len <= length <= max_len:
            status = "good"
            recommendation = "Title length is within the recommended range."
        elif length < min_len:
            status = "warning"
            recommendation = (
                f"Title is too short ({length} chars). "
                f"Aim for {min_len}-{max_len} characters to improve click-through rates."
            )
        else:
            status = "warning"
            recommendation = (
                f"Title is too long ({length} chars). "
                f"Search engines may truncate it. Aim for {min_len}-{max_len} characters."
            )

        return {
            "title": title,
            "length": length,
            "min_recommended": min_len,
            "max_recommended": max_len,
            "status": status,
            "recommendation": recommendation,
        }

    @mcp.tool()
    def check_meta_description(description: str) -> dict:
        """Check a page's meta description tag for SEO best practices.

        Validates the description length against the recommended range of
        120-160 characters and provides actionable feedback.
        """
        length = len(description)
        min_len = 120
        max_len = 160

        if min_len <= length <= max_len:
            status = "good"
            recommendation = "Description length is within the recommended range."
        elif length < min_len:
            status = "warning"
            recommendation = (
                f"Description is too short ({length} chars). "
                f"Aim for {min_len}-{max_len} characters to maximize SERP real estate."
            )
        else:
            status = "warning"
            recommendation = (
                f"Description is too long ({length} chars). "
                f"Search engines may truncate it. Aim for {min_len}-{max_len} characters."
            )

        return {
            "description": description,
            "length": length,
            "min_recommended": min_len,
            "max_recommended": max_len,
            "status": status,
            "recommendation": recommendation,
        }

    @mcp.tool()
    def analyze_heading_structure(html: str) -> dict:
        """Analyze the heading tag structure (H1-H6) of an HTML document.

        Parses the provided HTML to extract all heading tags, checks whether
        there is exactly one H1 tag, and reports the full heading hierarchy.
        """
        parser = _HeadingParser()
        parser.feed(html)
        headings = parser.headings

        h1_count = sum(1 for h in headings if h["tag"] == "h1")

        if h1_count == 1:
            status = "good"
            recommendation = "Page has exactly one H1 tag, which is ideal for SEO."
        elif h1_count == 0:
            status = "warning"
            recommendation = (
                "No H1 tag found. Every page should have exactly one H1 tag "
                "that describes the primary topic."
            )
        else:
            status = "warning"
            recommendation = (
                f"Found {h1_count} H1 tags. Best practice is to have exactly one H1 "
                f"per page to clearly signal the main topic to search engines."
            )

        return {
            "headings": headings,
            "total_headings": len(headings),
            "h1_count": h1_count,
            "status": status,
            "recommendation": recommendation,
        }

    @mcp.tool()
    def check_open_graph_tags(html: str) -> dict:
        """Extract and validate Open Graph meta tags from an HTML document.

        Checks for the presence of og:title, og:description, og:image, and
        og:url, and reports which required tags are missing.
        """
        parser = _MetaTagParser()
        parser.feed(html)

        required_tags = ["og:title", "og:description", "og:image", "og:url"]
        found_tags = {}
        missing_tags = []

        for tag in required_tags:
            value = parser.meta_tags.get(tag)
            if value:
                found_tags[tag] = value
            else:
                missing_tags.append(tag)

        if not missing_tags:
            status = "good"
            recommendation = "All required Open Graph tags are present."
        else:
            status = "warning"
            recommendation = (
                f"Missing Open Graph tags: {', '.join(missing_tags)}. "
                f"These tags are important for rich previews when your page is shared on social media."
            )

        return {
            "found_tags": found_tags,
            "missing_tags": missing_tags,
            "status": status,
            "recommendation": recommendation,
        }

    @mcp.tool()
    def analyze_keyword_density(text: str, keyword: str) -> dict:
        """Analyze keyword density within a block of text.

        Calculates how many times the keyword appears in the text and its
        density as a percentage of total words. A density between 1-3% is
        generally recommended for SEO.
        """
        text_lower = text.lower()
        keyword_lower = keyword.lower().strip()

        words = text_lower.split()
        total_words = len(words)

        # Count occurrences of the keyword (may be multi-word)
        pattern = re.compile(re.escape(keyword_lower))
        matches = pattern.findall(text_lower)
        keyword_count = len(matches)

        keyword_word_count = len(keyword_lower.split())

        if total_words > 0:
            density = round((keyword_count * keyword_word_count / total_words) * 100, 2)
        else:
            density = 0.0

        min_density = 1.0
        max_density = 3.0

        if min_density <= density <= max_density:
            status = "good"
            recommendation = (
                f"Keyword density of {density}% is within the recommended "
                f"{min_density}-{max_density}% range."
            )
        elif density < min_density:
            status = "warning"
            recommendation = (
                f"Keyword density of {density}% is below the recommended "
                f"{min_density}-{max_density}% range. Consider naturally incorporating "
                f"the keyword more often."
            )
        else:
            status = "warning"
            recommendation = (
                f"Keyword density of {density}% is above the recommended "
                f"{min_density}-{max_density}% range. This may be seen as keyword stuffing "
                f"by search engines."
            )

        return {
            "keyword": keyword,
            "keyword_count": keyword_count,
            "total_words": total_words,
            "density_percent": density,
            "recommended_min_percent": min_density,
            "recommended_max_percent": max_density,
            "status": status,
            "recommendation": recommendation,
        }
