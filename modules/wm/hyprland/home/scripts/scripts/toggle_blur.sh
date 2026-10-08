#!/usr/bin/env bash
if hyprctl getoption decoration.blur.enabled | grep -E "(int|bool): (1|true)" > /dev/null; then
    hyprctl eval 'hl.config({ decoration = { blur = { enabled = false } } })' > /dev/null
else
    hyprctl eval 'hl.config({ decoration = { blur = { enabled = true } } })' > /dev/null
fi
