function md_anchor(heading,    h) {
  h = heading
  sub(/^#+ +/, "", h)
  h = tolower(h)
  gsub(/[^a-z0-9 _-]/, "", h)
  gsub(/ /, "-", h)
  return h
}

function md_level(heading) {
  match(heading, /^#+/)
  return RLENGTH
}

/^```/ { fenced = !fenced }
