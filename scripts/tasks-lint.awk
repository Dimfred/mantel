function fail(msg) {
  printf "docs-lint: %s:%d: %s\n", FILENAME, FNR, msg > "/dev/stderr"
  bad = 1
}

FNR == 1 { section = "" }

/^## / {
  section = substr($0, 4)
  if (section !~ /^(Blocked|Later|M[0-9]+ .+)$/) fail("unknown section: " $0)
  next
}

section == "Blocked" && FILENAME ~ /TASKS\.md$/ { blocked_text = blocked_text "\n" $0 }

/^- \[/ {
  if (section !~ /^M[0-9]+ /) { fail("task outside a milestone"); next }
  if ($0 !~ /^- \[[ x?!]\] T[0-9][0-9][0-9]+ ./) { fail("bad task line: " $0); next }

  st = substr($0, 4, 1)
  rest = substr($0, 7)
  match(rest, /^T[0-9]+/)
  id = substr(rest, 1, RLENGTH)
  title = substr(rest, RLENGTH + 2)

  if (id in seen) fail("duplicate " id ", first at " seen[id])
  seen[id] = FILENAME ":" FNR

  if (FILENAME ~ /TASKS-done\.md$/ && (st == " " || st == "!")) fail(id " is open but archived")
  if (st == "!") blocked[id] = FILENAME ":" FNR

  if (substr(title, 1, 1) != "[") next
  if (title !~ "^\\[[^]]+\\]\\(tasks/" id "-[a-z0-9-]+\\.md\\)$") { fail("bad link for " id ": " title); next }

  path = title
  sub(/^\[[^]]*\]\(/, "", path)
  sub(/\)$/, "", path)
  full = docs "/" path
  if ((getline line < full) < 0) fail("missing file " full)
  close(full)
}

END {
  for (id in blocked) {
    if (index(blocked_text, id) == 0) {
      printf "docs-lint: %s: %s is [!] but not under ## Blocked\n", blocked[id], id > "/dev/stderr"
      bad = 1
    }
  }
  exit bad
}
