#!/usr/bin/env bash
# SessionStart: name any waiting handoff note (handoff skill) in one line of context.
dir="${CLAUDE_PROJECT_DIR:-$PWD}/.claude/handoffs"
shopt -s nullglob
notes=("$dir"/*.md)
((${#notes[@]})) || exit 0
#--- Names start with the date, so the glob's sorted order ends on the newest
newest=${notes[-1]}
title=$(sed -n '1s/^# *//p' "$newest")
echo "Handoff waiting: .claude/handoffs/${newest##*/} ($title)${notes[1]:+, plus $((${#notes[@]} - 1)) older}. If the user says continue, use the handoff skill with resume."
