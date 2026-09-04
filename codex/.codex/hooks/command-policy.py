#!/usr/bin/env python3

import json
import re
import sys


def deny(reason: str) -> None:
    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": reason,
            }
        },
        sys.stdout,
    )


event: dict[str, object] = json.load(sys.stdin)
tool_input: object = event.get("tool_input", {})
if not isinstance(tool_input, dict):
    raise SystemExit(0)

command: object = tool_input.get("command", "")
if not isinstance(command, str):
    raise SystemExit(0)

publish_commands: list[str] = re.findall(
    r"(?:^|(?:&&|\|\||;|\|)\s*)((?:[^;&|]*?/)?dart\s+pub\s+publish\b[^;&|]*)",
    command,
)

for publish_command in publish_commands:
    if not re.search(r"(?:^|\s)--dry-run(?:\s|$)", publish_command):
        deny("A real Dart package publication is not permitted. Use --dry-run.")
        raise SystemExit(0)
