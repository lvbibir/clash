#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import sys
from typing import Optional


PLACEHOLDER_SECRET = "123456"
PLACEHOLDER_PROVIDER_URL = "---"


def _leading_spaces(line: str) -> int:
    count = 0
    for ch in line:
        if ch == " ":
            count += 1
            continue
        break
    return count


def _looks_like_yaml_key(line: str) -> bool:
    if not line.strip() or re.match(r"^\s*#", line):
        return False
    return bool(re.match(r"^\s*[^\s#][^:]*:\s*", line))


def _proxy_providers_min_url_indent(lines: list[str]) -> Optional[int]:
    in_proxy_providers = False
    proxy_providers_indent = 0
    min_url_indent: Optional[int] = None

    for line in lines:
        if re.match(r"^\s*#", line) or not line.strip():
            continue

        if not in_proxy_providers:
            if re.match(r"^\s*proxy-providers:\s*$", line):
                in_proxy_providers = True
                proxy_providers_indent = _leading_spaces(line)
            continue

        indent = _leading_spaces(line)
        if indent <= proxy_providers_indent and _looks_like_yaml_key(line) and not re.match(
            r"^\s*proxy-providers:\s*$", line
        ):
            in_proxy_providers = False
            continue

        if indent > proxy_providers_indent and re.match(r"^\s*url:\s*", line):
            if min_url_indent is None or indent < min_url_indent:
                min_url_indent = indent

    return min_url_indent


def _transform_clean(text: str) -> str:
    parts: list[tuple[str, str]] = []
    for raw_line in text.splitlines(keepends=True):
        if raw_line.endswith("\r\n"):
            parts.append((raw_line[:-2], "\r\n"))
        elif raw_line.endswith("\n"):
            parts.append((raw_line[:-1], "\n"))
        else:
            parts.append((raw_line, ""))

    min_url_indent = _proxy_providers_min_url_indent([line for line, _ in parts])

    in_proxy_providers = False
    proxy_providers_indent = 0

    output: list[str] = []
    for line, line_ending in parts:
        if re.match(r"^\s*proxy-providers:\s*$", line):
            in_proxy_providers = True
            proxy_providers_indent = _leading_spaces(line)
            output.append(line + line_ending)
            continue

        if in_proxy_providers:
            indent = _leading_spaces(line)
            if indent <= proxy_providers_indent and _looks_like_yaml_key(line) and not re.match(
                r"^\s*proxy-providers:\s*$", line
            ):
                in_proxy_providers = False

        if re.match(r"^\s*#", line):
            if in_proxy_providers:
                m_url_comment = re.match(r"^(\s*#\s*)url:\s*(.*?)(\s+#.*)?\s*$", line)
                if m_url_comment:
                    prefix = m_url_comment.group(1)
                    comment = m_url_comment.group(3) or ""
                    output.append(f"{prefix}url: '{PLACEHOLDER_PROVIDER_URL}'{comment}{line_ending}")
                    continue

            m_secret_comment = re.match(r"^(\s*#\s*)secret:\s*(.*?)(\s+#.*)?\s*$", line)
            if m_secret_comment:
                prefix = m_secret_comment.group(1)
                comment = m_secret_comment.group(3) or ""
                output.append(f"{prefix}secret: {PLACEHOLDER_SECRET}{comment}{line_ending}")
                continue

            output.append(line + line_ending)
            continue

        if in_proxy_providers:
            line_indent = _leading_spaces(line)
            if min_url_indent is not None and line_indent == min_url_indent:
                m_url = re.match(r"^(\s*)url:\s*(.*?)(\s+#.*)?\s*$", line)
                if m_url:
                    indent_text = m_url.group(1)
                    comment = m_url.group(3) or ""
                    output.append(f"{indent_text}url: '{PLACEHOLDER_PROVIDER_URL}'{comment}{line_ending}")
                    continue

        m_secret = re.match(r"^(\s*)secret:\s*(.*?)(\s+#.*)?\s*$", line)
        if m_secret:
            indent = m_secret.group(1)
            comment = m_secret.group(3) or ""
            output.append(f"{indent}secret: {PLACEHOLDER_SECRET}{comment}{line_ending}")
            continue

        output.append(line + line_ending)

    return "".join(output)


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Git clean/smudge filter for mihomo.yaml secrets.")
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub.add_parser("clean", help="Redact secrets for git index (stdin -> stdout).")
    sub.add_parser("smudge", help="No-op (stdin -> stdout).")

    args = parser.parse_args(argv)

    if args.cmd == "clean":
        sys.stdout.write(_transform_clean(sys.stdin.read()))
        return 0

    if args.cmd == "smudge":
        sys.stdout.write(sys.stdin.read())
        return 0

    return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
