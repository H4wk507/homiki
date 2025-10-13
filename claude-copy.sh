#!/bin/sh


find "${1:-decompiled/}" -name "*.as" | while read -r file; do
   printf "// %s\n\n%s\n\n\n" "$file" "$(cat "$file")"
done | xclip -sel clip

