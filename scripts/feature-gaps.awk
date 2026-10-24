FNR == NR { linked[$0] = 1; next }

!fenced && /^##+ / {
  n++
  title[n] = $0
  anchor[n] = md_anchor($0)
  level[n] = md_level($0)
}

END {
  for (i = n; i >= 1; i--) {
    covered[i] = (anchor[i] in linked)
    for (j = i + 1; j <= n && level[j] > level[i]; j++) {
      if (covered[j]) covered[i] = 1
    }
  }
  for (i = 1; i <= n; i++) {
    if (!covered[i]) print title[i] "  (#" anchor[i] ")"
  }
}
