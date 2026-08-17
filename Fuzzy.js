.pragma library

function normalized(value) {
  return String(value === undefined || value === null ? "" : value).toLowerCase().trim()
}

// A compact subsequence scorer: exact/prefix matches win, then consecutive and
// word-boundary characters. A negative score means "not a match".
function score(query, candidate) {
  var q = normalized(query)
  var c = normalized(candidate)
  if (!q.length) return 0
  if (c === q) return 10000
  if (c.indexOf(q) === 0) return 8000 - c.length

  var qi = 0
  var total = 0
  var previous = -2
  for (var i = 0; i < c.length && qi < q.length; i++) {
    if (c[i] !== q[qi]) continue
    total += 10
    if (i === previous + 1) total += 15
    if (i === 0 || " -_/:".indexOf(c[i - 1]) >= 0) total += 20
    total -= i * 0.05
    previous = i
    qi++
  }
  return qi === q.length ? total - c.length * 0.01 : -1
}

function filter(query, rows) {
  var ranked = []
  for (var i = 0; i < rows.length; i++) {
    var row = rows[i]
    var haystack = String(row.id) + " " + String(row.name || "") + " " + String(row.monitor || "")
    var rank = score(query, haystack)
    if (rank >= 0) ranked.push({ row: row, rank: rank, order: i })
  }
  ranked.sort(function(a, b) {
    if (b.rank !== a.rank) return b.rank - a.rank
    return a.order - b.order
  })
  var result = []
  for (var j = 0; j < ranked.length; j++) result.push(ranked[j].row)
  return result
}
