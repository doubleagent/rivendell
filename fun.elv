use dev/rivendell/test
use dev/rivendell/base
use math

fn listify {|@els|
  set @els = (base:check-pipe $els)
  put $els
}

fn first {|@els|
  set @els = (base:check-pipe $els)
  put $els[0]
}

fn second {|@els|
  set @els = (base:check-pipe $els)
  put $els[1]
}

fn end {|@els|
  set @els = (base:check-pipe $els)
  put $els[-1]
}

fn update {|coll k f @args|
  assoc $coll $k ($f $coll[$k] $@args) 
}

## Hard to believe this isn't a builtin
fn vals {|m|
  each {|k|
    put $m[$k]
  } [(keys $m)]
}

## This makes maps iterable
fn kvs {|m|
  each {|k|
    put [$k $m[$k]]
  } [(keys $m)]
}

fn get-in {|m @ks|
  set @ks = (base:check-pipe $ks)
  var fin = $true
  for k $ks {
    if (has-key $m $k) {
      set m = $m[$k]
    } else {
      set fin = $false
      break
    }
  }
  if $fin { put $m }
}

fn assoc-in {|m ks v|
  var c = (count $ks)

  if (not-eq (kind-of $m) map) {
    set m = [&]
  }

  if (== $c 1) {
    assoc $m $ks[0] $v
  } elif (> $c 1) {
    var k = $ks[0]
    if (has-key $m $k) {
      assoc $m $k (assoc-in $m[$k] (base:rest $ks) $v)
    } else {
      set m = (assoc $m $k [&])
      assoc $m $k (assoc-in $m[$k] (base:rest $ks) $v)
    }
  } else {
    put $m
  }
}

fn update-in {|m ks f|
  var c = (count $ks)

  if (== $c 1) {
    var k = $ks[0]
    if (has-key $m $k) {
      update $m $k $f
    } else {
      put $m
    }
  } elif (> $c 1) {
    var k = $ks[0]
    if (has-key $m $k) {
      assoc $m $k (update-in $m[$k] (base:rest $ks) $f)
    } else {
      put $m
    }
  } else {
    put $m
  }
}

fn destruct {|f|
  put {|x|
    $f (all $x)
  }
}

fn complement {|f|
  put {|@x|
    not ($f $@x)
  }
}

fn partial {|f @supplied|
  set @supplied = (base:check-pipe $supplied)
  put {|@args|
    set @args = (base:check-pipe $args)
    $f $@supplied $@args
  }
}

fn juxt {|@fns|
  set @fns = (base:check-pipe $fns)
  put {|@args|
    set @args = (base:check-pipe $args)
    for f $fns {
      $f $@args
    }
  }
}

fn constantly {|@xs|
  set @xs = (base:check-pipe $xs)
  put {|@_|
    put $@xs
  }
}

fn memoize {|f|
  var cache = [&]
  put {|@args|
    if (has-key $cache $args) {
      all $cache[$args]
    } else {
      var @res = ($f $@args)
      set cache = (assoc $cache $args $res)
      all $res
    }
  }
}

fn repeatedly {|n f|
  while (> $n 0) {
    $f
    set n = (base:dec $n)
  }
}

fn reduce {|f @arr|
  set @arr = (base:check-pipe $arr)
  var acc = $arr[0]
  for b $arr[1..] {
    set acc = ($f $acc $b)
  }
  put $acc
}

fn reduce-while {|pred f @arr|
  set @arr = (base:check-pipe $arr)
  var acc = $arr[0]
  for b $arr[1..] {
    if ($pred $acc $b) {
      set acc = ($f $acc $b)
    } else {
      break
    }
  }
  put $acc
}

fn reduce-when {|pred f @arr|
  set @arr = (base:check-pipe $arr)
  var acc = $arr[0]
  for b $arr[1..] {
    if ($pred $acc $b) {
      set acc = ($f $acc $b)
    }
  }
  put $acc
}

fn reduce-kv {|f @arr &idx=0|
  set @arr = (base:check-pipe $arr)
  var acc = $arr[0]
  var arr = $arr[1..]
  if (and (== (count $arr) 1) ^
          (base:is-map $arr[0])) {
    for k [(keys $@arr)] {
      set acc = ($f $acc $k $@arr[$k])
    }
  } else {
    var k = (num $idx)
    for v $arr {
      set acc = ($f $acc $k $v)
      set k = (base:inc $k)
    }
  }
  put $acc
}

fn reductions {|f @arr|
  set @arr = (base:check-pipe $arr)
  var acc = $arr[0]
  put $acc
  for b $arr[1..] {
    set acc = ($f $acc $b)
    put $acc
  }
}

fn comp {|@fns|
  set @fns = (base:check-pipe $fns)
  put {|@x|
    set @x = (base:check-pipe $x)
    all (reduce {|a b| put [($b $@a)]} $x $@fns)
  }
}

fn box {|f|
  comp $f $listify~
}

fn filter {|f @arr|
  set @arr = (base:check-pipe $arr)
  each {|x|
    var @res = ($f $x)
    if (> (count $res) 0) {
      if $@res {
        put $x
      }
    }
  } $arr
}

fn pfilter {|f @arr|
  set @arr = (base:check-pipe $arr)
  peach {|x|
    var @res = ($f $x)
    if (> (count $res) 0) {
      if $@res {
        put $x
      }
    }
  } $arr
}

fn remove {|f @arr|
  filter (complement $f) $@arr
}

fn premove {|f @arr|
  pfilter (complement $f) $@arr
}

fn into {|container @arr ^
  &keyfn=$base:first~ ^
  &valfn=$base:second~ ^
  &collision=$nil|

  set @arr = (base:check-pipe $arr)
  if (and (eq (kind-of $container) map) (eq $collision $nil)) {
    reduce {|a b|
      assoc $a ($keyfn $b) ($valfn $b)
    } $container $@arr
  } elif (eq (kind-of $container) map) {
    reduce {|a b|
      var k = ($keyfn $b)
      var v = ($valfn $b)
      if (has-key $a $k) {
        set v = ($collision $a[$k] $v)
      }
      assoc $a $k $v
    } $container $@arr
  } elif (eq (kind-of $container) list) {
    base:concat2 $container $arr
  }

}

fn merge {|@maps|
  set @maps = (base:check-pipe $maps)
  reduce {|a b|
    reduce-kv $assoc~ $a $b
  } [&] $@maps
}

fn merge-with {|f @maps|
  set @maps = (base:check-pipe $maps)
  reduce {|a b|
    reduce-kv {|a k v|
      if (has-key $a $k) {
        update $a $k $f $v
      } else {
        assoc $a $k $v
      }
    } $a $b
  } [&] $@maps
}

fn reverse {|@arr|
  set @arr = (base:check-pipe $arr)
  var i lim = 1 (base:inc (count $arr))
  while (< $i $lim) {
    put $arr[-$i]
    set i = (base:inc $i)
  }
}

fn distinct {|@args|
  set @args = (base:check-pipe $args)
  into [&] &keyfn=$put~ &valfn=(constantly $nil) $@args | keys (one)
}

fn unique {|@args &count=$false|
  var a
  set a @args = (base:check-pipe $args)
  if $count {
    var i = (num 1)
    for x $args {
      if (not-eq $x $a) {
        put [$i $a]
        set a i = $x 1
      } else {
        set i = (base:inc $i)
      }
    }
    put [$i (base:end $args)]
  } else {
    for x $args {
      if (not-eq $x $a) {
        put $a
        set a = $x
      }
    }
    put (base:end $args)
  }
}

fn replace {|smap coll|
  if (eq (kind-of $smap) list) {
    set smap = (reduce-kv $assoc~ [&] (all $smap))
  }

  if (eq (kind-of $coll) map) {
    set @coll = (kvs $coll)
  }

  each {|x|
    if (has-key $smap $x) {
      put $smap[$x]
    } else {
      put $x
    }
  } $coll
}

fn concat {|@lists|
  set @lists = (base:check-pipe $lists)
  reduce $base:concat2~ [] $@lists
}

fn min-key {|f @arr|
  set @arr = (base:check-pipe $arr)
  var m = (into [&] $@arr &keyfn=$f &valfn=$put~)
  keys $m | math:min (all) | put $m[(one)]
}

fn max-key {|f @arr|
  set @arr = (base:check-pipe $arr)
  var m = (into [&] $@arr &keyfn=$f &valfn=$put~)
  keys $m | math:max (all) | put $m[(one)]
}

fn some {|f @arr|
  set @arr = (base:check-pipe $arr)
  var res = []
  for a $arr {
    set @res = ($f $a)
    if (> (count $res) 0) {
      if $@res {
        break
      }
    }
  }
  put $@res
}

fn first-pred {|f @arr|
  set @arr = (base:check-pipe $arr)
  var res = []
  for a $arr {
    set @res = ($f $a)
    if (> (count $res) 0) {
      if $@res {
        put $a
        break
      }
    }
  }
}

fn not-every {|f @arr|
  some (complement $f) $@arr
}

fn every {|f @arr|
  not (not-every $f $@arr)
}

fn not-any {|f @arr|
  not (some $f $@arr)
}

fn keep {|f @arr &pred=(complement $base:is-nil~)|
  set @arr = (base:check-pipe $arr)
  each {|x|
    var @fx = ($f $x)
    if (> (count $fx) 0) {
      if ($pred $@fx) {
        put $@fx
      }
    }
  } $arr
}

fn pkeep {|f @arr &pred=(complement $base:is-nil~)|
  set @arr = (base:check-pipe $arr)
  peach {|x|
    var @fx = ($f $x)
    if (> (count $fx) 0) {
      if ($pred $@fx) {
        put $@fx
      }
    }
  } $arr
}

fn map {|f @arr &lists=$nil &els=$nil|
  set @arr = (base:check-pipe $arr)
  if (eq $lists $false) {
    each $f $arr
  } elif (eq $lists $true) {
    if $els {
      each {|i|
        each {|l|
          put $l[$i]
        } $arr | $f (all)
      } [(range $els)]
    } else {
      map $f $@arr &els=(each $count~ $arr | math:min (all)) &lists=$lists
    }
  } else {
    map $f $@arr &els=$els &lists=(every $base:is-list~ $@arr)
  }
}

fn pmap {|f @arr &lists=$nil &els=$nil|
  set @arr = (base:check-pipe $arr)
  if (eq $lists $false) {
    peach $f $arr
  } elif (eq $lists $true) {
    if $els {
      peach {|i|
        each {|l|
          put $l[$i]
        } $arr | $f (all)
      } [(range $els)]
    } else {
      pmap $f $@arr &els=(each $count~ $arr | math:min (all)) &lists=$lists
    }
  } else {
    pmap $f $@arr &els=$els &lists=(every $base:is-list~ $@arr)
  }
}

fn mapcat {|f @arr &lists=$nil &els=$nil|
  map $f $@arr &lists=$lists &els=$els | concat
}

fn map-indexed {|f @arr|
  set @arr = (base:check-pipe $arr)
  var els = (count $arr)
  map $f [(range $els)] $arr &lists=$true &els=$els
}

fn keep-indexed {|f @arr &pred=(complement $base:is-nil~)|
  map-indexed {|i x|
    var @fx = ($f $i $x)
    if (> (count $fx) 0) {
      if ($pred $@fx) {
        put $@fx
      }
    }
  } $@arr
}

fn interleave {|@lists|
  set @lists = (base:check-pipe $lists)
  map $put~ $@lists &lists=$true &els=(each $count~ $lists | math:min (all))
}

fn interpose {|sep @arr|
  set @arr = (base:check-pipe $arr)
  var c = (base:dec (count $arr))
  map $put~ $arr [(repeat $c $sep)] &lists=$true &els=$c
  put $arr[$c]
}

fn partition {|n @args &step=$nil &pad=$nil|
  set @args = (base:check-pipe $args)
  if (and (> $n 0) (or (not $step) (> $step 0))) {
    each {|i|
      var li = [(drop $i $args | take $n)]
      if (== $n (count $li)) {
        put $li
      } elif (not-eq $pad $nil) {
        base:append $li (take (- $n (count $li)) $pad)
      }
    } [(range (count $args) &step=(or $step $n))]
  }
}

fn partition-all {|n @args|
  partition $n $@args &pad=[]
}

fn zipmap {|ks vs|
  interleave $ks $vs | partition 2 | into [&]
}

fn rest {|@xs|
  drop 1 $xs
}

fn iterate {|f n seed|
  var i = 1
  put $seed
  while (< $i $n) {
    set seed = ($f $seed)
    set i = (base:inc $i)
    put $seed
  }
}

fn take-nth {|n @arr|
  set @arr = (base:check-pipe $arr)
  partition 1 &step=$n $@arr | each $all~
}

fn take-while {|f @arr|
  set @arr = (base:check-pipe $arr)
  var res
  for x $arr {
    set @res = ($f $x)
    if (and (> (count $res) 0) $@res) {
      put $x
    } else {
      break
    }
  }
}

fn drop-while {|f @arr|
  set @arr = (base:check-pipe $arr)
  var res
  var i = 0
  for x $arr {
    set @res = ($f $x)
    if (and (> (count $res) 0) $@res) {
      set i = (base:inc $i)
    } else {
      break
    }
  }
  all $arr[$i..]
}

fn drop-last {|n @arr|
  set @arr = (base:check-pipe $arr)
  take (- (count $arr) $n) $arr
}

fn butlast {|@arr|
  set @arr = (base:check-pipe $arr)
  drop-last 1 $@arr
}

fn group-by {|f @arr|
  set @arr = (base:check-pipe $arr)
  into [&] $@arr &keyfn=$f &valfn=(box $put~) &collision=$base:concat2~
}

fn frequencies {|@arr|
  set @arr = (base:check-pipe $arr)
  into [&] $@arr &keyfn=$put~ &valfn=(constantly (num 1)) &collision=$'+~'
}

fn map-invert {|m &lossy=$true|
  if $lossy {
    kvs $m | into [&] &keyfn=$base:second~ &valfn=$base:first~
  } else {
    kvs $m | into [&] &keyfn=$base:second~ &valfn=(box $base:first~) &collision=$base:concat2~
  }
}

fn rand-sample {|n @arr|
  set @arr = (base:check-pipe $arr)
  for x $arr {
    if (<= (rand) $n) {
      put $x
    }
  }
}

fn sample {|n @arr|
  set @arr = (base:check-pipe $arr)
  var rand-idx = (comp $base:second~ $count~ (partial $randint~ 0))
  var f = (comp (juxt $base:second~ $rand-idx) (juxt $base:get~ $base:pluck~))
  iterate (box $f) (base:inc $n) ['' $arr] | drop 1 | each $base:first~
}

fn shuffle {|@arr|
  set @arr = (base:check-pipe $arr)
  sample (count $arr) $@arr
}

fn union {|@lists|
  set @lists = (base:check-pipe $lists)
  concat $@lists | all (one) | distinct
}

fn difference {|l1 @lists|
  set @lists = (base:check-pipe $lists)
  union $@lists ^
  | reduce $dissoc~ (into [&] $@l1 &keyfn=$put~ &valfn=(constantly $nil)) (all) ^
  | keys (one)
}

fn disj {|l @els|
  set @els = (base:check-pipe $els)
  reduce $dissoc~ (into [&] $@l &keyfn=$put~ &valfn=(constantly $nil)) $@els | keys (one)
}

fn intersection {|@lists|
  set @lists = (base:check-pipe $lists)
  var m = (each (destruct $distinct~) $lists ^
    | frequencies ^
    | map-invert (one) &lossy=$false)

  var c = (count $lists)
  if (has-key $m $c) {
    all $m[$c]
  }
}

fn subset {|l1 l2|
  or (eq $l1 []) ^
     (and (not-eq $l2 []) ^
          (every (partial $has-key~ (into [&] $@l2 &keyfn=$put~ &valfn=(constantly $nil))) $@l1))
}

fn superset {|l1 l2|
  or (eq $l2 []) ^
     (and (not-eq $l1 []) ^
          (every (partial $has-key~ (into [&] $@l1 &keyfn=$put~ &valfn=(constantly $nil))) $@l2))
}

fn overlaps {|l1 l2|
  some (partial $has-key~ (into [&] $@l1 &keyfn=$put~ &valfn=(constantly $nil))) $@l2
}

fn select-keys {|m @ks|
  set @ks = (base:check-pipe $ks)
  reduce {|a b|
    if (has-key $m $b) {
      assoc $a $b $m[$b]
    } else {
      put $a
    }
  } [&] $@ks
}

fn rename-keys {|m kmap|
  merge ^
  (reduce $dissoc~ $m (keys $kmap)) ^
  (reduce-kv {|a k v|
      if (has-key $m $k) {
        assoc $a $v $m[$k]
      } else {
        put $m
      }
  } [&] $kmap)
}

fn index {|maps @ks|
  set @ks = (base:check-pipe $ks)
  group-by {|m| select-keys $m $@ks } (all $maps)
}

fn pivot {|@maps &from_row=name &to_row=name|
  set @maps = (base:check-pipe $maps)
  each {|nm|
    reduce {|a b|
      assoc $a $b[$from_row] $b[$nm]
    } [&$to_row=$nm] $@maps
  } [(each (comp {|m| dissoc $m $from_row} (box $keys~)) $maps | intersection)] # common cells
}

fn assert-equal-sets {|@expectation &fixtures=[&] &store=[&]|
  test:assert $expectation {|@reality|
    eq (into [&] $@expectation &keyfn=$put~ &valfn=(constantly $nil)) ^
       (into [&] $@reality &keyfn=$put~ &valfn=(constantly $nil))
  } &name=assert-differences-empty &fixtures=$fixtures &store=$store
}

fn assert-subset-of {|@expectation &fixtures=[&] &store=[&]|
  test:assert $expectation {|@reality|
    subset $reality $expectation
  } &name=assert-subset-of &fixtures=$fixtures &store=$store
}

fn assert-superset-of {|@expectation &fixtures=[&] &store=[&]|
  test:assert $expectation {|@reality|
    superset $reality $expectation
  } &name=assert-superset-of &fixtures=$fixtures &store=$store
}

var tests = [Fun.elv
  '# Misc. functions'
  [listify
   'Captures input and shoves it into a list.'
   (test:is-one [1 2 3])
   { put 1 2 3 | listify }
   { listify 1 2 3 }]

  [concat
   'A more generic version of `base:concat2`, which takes any number of lists'
   (test:is-one [1 2 3 4 5 6 7 8 9])
   { concat [1 2 3] [4 5 6] [7 8 9] }
   { put [1 2 3] [4 5 6] [7 8 9] | concat }]

  [first
   "Returns the first element"
   (test:is-one a)
   { first a b c }
   { put a b c | first }]

  [second
   "Returns the second element"
   (test:is-one b)
   { second a b c }
   { put a b c | second }]

  [end
   "Returns the last element"
   (test:is-one c)
   { end a b c }
   { put a b c | end }]

  [min-key/max-key
   "Returns the x for which `(f x)`, a number, is least, or most."
   "If there are multiple such xs, the last one is returned."
   (test:is-one (num 11))
   { min-key $math:sin~ (range 20) }

   (test:is-one (num 14))
   { max-key $math:sin~ (range 20) }]

  '# Statistics'
  [group-by
   'Returns a map of elements keyed by `(f x)`'
   (test:is-one [&(num 1)=[a] &(num 2)=[as aa] &(num 3)=[asd] &(num 4)=[asdf qwer]])
   { group-by $count~ a as asd aa asdf qwer }
   { put a as asd aa asdf qwer | group-by $count~ }

   (test:is-one [&a=[[&key=a &val=1] [&key=a &val=3]] &b=[[&key=b &val=1]]])
   { group-by {|m| put $m[key]} [&key=a &val=1] [&key=b &val=1] [&key=a &val=3]}]

  [frequencies
   'Returns a map of the number of times a thing appears'
   (test:is-one [&a=(num 3) &b=(num 3) &c=(num 2) &d=(num 1) ^
                 &h=(num 2) &r=(num 1) &s=(num 2) &u=(num 2)])
   { frequencies (each $all~ [abba acdc rush bush]) }
   { each $all~ [abba acdc rush bush] | frequencies }]

  [map-invert
   "Does what's on the tin"
   (test:is-one [&1=a &2=b &3=c])
   { map-invert [&a=1 &b=2 &c=3] }
   'Normally lossy.'
   (test:is-one [&1=c &2=b])
   { map-invert [&a=1 &b=2 &c=1] }
   'You can tell it not to be lossy, though.'
   (test:is-one [&1=[a c] &2=[b]])
   { map-invert [&a=1 &b=2 &c=1] &lossy=$false }]

  [rand-sample
   'Returns items from `@arr` with random probability of 0.0-1.0'
   (test:is-nothing)
   { rand-sample 0 (range 10) }
   (assert-subset-of (range 10))
   { rand-sample 0.5 (range 10) }
   (test:is-each (range 10))
   { rand-sample 1 (range 10) }
   { range 10 | rand-sample 1 }]

  [sample
   'Take n random samples from the input'
   (test:is-all (test:is-count 5) (assert-subset-of (range 10)))
   { sample 5 (range 10) }
   { range 10 | sample 5 }]

  [shuffle
   (test:is-all (test:is-count 10) (assert-equal-sets (range 10)))
   { shuffle (range 10) }
   { range 10 | shuffle }]

  '# Set functions'
  [union
   'Set theory union'
   (assert-equal-sets a b c d e f g h i)
   { union [a b c] [d b e f] [g e h i] }
   { put [a b c] [d b e f] [g e h i] | union }]

  [difference
   'Subtracts a bunch of sets from another'
   (assert-equal-sets b c)
   { difference [a b c] [a d e] }

   (assert-equal-sets c)
   { difference [a b c] [a d e] [b f g] }
   { put [a d e] [b f g] | difference [a b c] }]

  [disj
   'Like difference, but subtracts individual elements'
   (assert-equal-sets a b c f)
   { disj [a b c d e f g] d e g }
   { put d e g | disj [a b c d e f g] }]

  [intersection
   'Set theory intersection - returns only the items in all sets.'  
   (assert-equal-sets a b c)
   { intersection [a b c] }

   (assert-equal-sets b c)
   { intersection [a b c] [b c d] }
   { put [a b c] [b c d] | intersection }

   (assert-equal-sets c)
   { intersection [a b c] [b c d] [c d e] }]

  [subset
   'Predicate - returns true if l1 is a subset of l2.  False otherwise'
   (test:is-one $true)
   { subset [a b c] [d e f b a c]}
   (test:is-one $false)
   { subset [d e f b a c] [c b a]}]

  [superset
   'Predicate - returns true if l1 is a superset of l2.  False otherwise'
   (test:is-one $true)
   { superset [d e f b a c] [a b c]}
   (test:is-one $false)
   { superset [a b c] [d e f b a c]}]

  [overlaps
   'Predicate - returns true if l1 & l2 have a non-empty intersection.'
   (test:is-one $true)
   { overlaps [a b c d e f g] [e f g h i j k] }
   (test:is-one $false)
   { overlaps [a b c] [d e f] }]

  '# Map functions'
  [update
   'Updates a map element by applying a function to the value.'
   (test:is-one [&a=(num 2)])
   { update [&a=1] a $base:inc~ }
   { update [&a=0] a $'+~' 2 }
   { put 2 | update [&a=0] a $'+~' (one) }
   { put 1 1 | update [&a=0] a $'+~' (all) }

   'It works on lists, too.'
   (test:is-one [(num 2) 2 2])
   { update [1 2 2] 0 $base:inc~ }]

  [vals
   'sister fn to `keys`'
   (test:is-each 1 2 3)
   { vals [&a=1 &b=2 &c=3] }]

  [kvs
   'Given [&k1=v1 &k2=v2 ...], returns a sequence of [k1 v1] [k2 v2] ... '
   (test:is-each [a 1] [b 2] [c 3])
   { kvs [&a=1 &b=2 &c=3] }]

  [merge
   'Merges two or more maps.'
   (test:is-one [&a=1 &b=2 &c=3 &d=4])
   { merge [&a=1 &b=2] [&c=3] [&d=4] }
   { put [&a=1 &b=2] [&c=3] [&d=4] | merge }

   'Uses the last value if it sees overlaps. Pay attention to the `a` in this example.'
   (test:is-one [&a=3 &b=2 &c=4])
   { merge [&a=1 &b=2] [&a=3 &c=4] }

   'Works with zero-length input.'
   (test:is-one [&])
   { merge [&] }
   { merge [&] [&] }]

  [merge-with
   'Like merge, but takes a function which aggregates shared keys.'
   (test:is-one [&a=(num 4) &b=2 &c=4])
   { merge-with $'+~' [&a=1 &b=2] [&a=3 &c=4] }
   { put [&a=1 &b=2] [&a=3 &c=4] | merge-with $'+~' }
   { put $'+~' [&a=1 &b=2] [&a=3 &c=4] | merge-with (all) }]

  [select-keys
   'Returns a map with the requested keys.'
   (test:is-one [&a=1 &c=3])
   { select-keys [&a=1 &b=2 &c=3] a c }
   { put a c | select-keys [&a=1 &b=2 &c=3] }
   "It won't add keys which aren't there."
   { select-keys [&a=1 &b=2 &c=3] a c d e f g}
   "It also works with lists."
   (test:is-one [&0=1 &2=3])
   { select-keys [1 2 3] 0 0 2 }]

  [get-in
   'Returns nested elements.  Nonrecursive.'
   (test:is-one v)
   { get-in [&a=[&b=[&c=v]]] a b c }
   { put a b c | get-in [&a=[&b=[&c=v]]] }
   'Works with lists.'
   { get-in [0 1 [2 3 [4 v]]] 2 2 1 }
   'Returns nothing when not found.'
   (test:is-nothing)
   { get-in [&a=1 &b=2 &c=3] a b c }]

  [assoc-in
   'Nested assoc.  Recursive'
   (test:is-one [&a=[&b=[&c=v]]])
   { assoc-in [&] [a b c] v }
   { assoc-in [&a=1] [a b c] v }
   { assoc-in [&a=[&b=1]] [a b c] v }
   { assoc-in [&a=[&b=[&c=1]]] [a b c] v }
   (test:is-one [&a=[&b=[&c=v]] &b=2])
   { assoc-in [&a=1 &b=2] [a b c] v }]

  [update-in
   'Nested update. Recursive.'
   (test:is-one [&a=[&b=[&c=(num 2)]]])
   { update-in [&a=[&b=[&c=(num 1)]]] [a b c] $base:inc~ }
   'Returns the map unchanged if not found.'
   (test:is-one [&a=1 &b=2 &c=3])
   { update-in [&a=1 &b=2 &c=3] [a b c] $base:inc~ }]

  [rename-keys
   'Returns map `m` with the keys in kmap renamed to the vals in kmap'
   (test:is-one [&newa=1 &newb=2])
   { rename-keys [&a=1 &b=2] [&a=newa &b=newb] }
   "Won't produce key collisions"
   (test:is-one [&b=1 &a=2])
   { rename-keys [&a=1 &b=2] [&a=b &b=a] }]

  [index
   'returns a map with the maps grouped by the given keys'
   (test:is-one [&[&weight=1000]=[[&name=betsy &weight=1000] [&name=shyq &weight=1000]] &[&weight=756]=[[&name=jake &weight=756]]])
   { index [[&name=betsy &weight=1000] [&name=jake &weight=756] [&name=shyq &weight=1000]] weight }
   { put weight | index [[&name=betsy &weight=1000] [&name=jake &weight=756] [&name=shyq &weight=1000]] }]

  '# Function modifiers'
  [destruct
   'Works a bit like call, but returns a function.'
   "`+` doesn't work with a list..."
   (test:is-error)
   { + [1 2 3] }

   "But it does with `destruct`"
   (test:is-one (num 6))
   { (destruct $'+~') [1 2 3] }]

  [complement
   'Returns a function which negates the boolean result'
   (test:is-one $true)
   { base:is-odd 1 }
   { (complement $base:is-odd~) 2 }]

  [partial
   'Curries arguments to functions'
   (test:is-one (num 6))
   { + 1 2 3 }
   { (partial $'+~' 1) 2 3 }
   { (partial $'+~' 1 2) 3 }
   { put 2 3 | (partial $'+~' 1) }
   { put 1 | partial $'+~' | (one) 2 3 }]

  [juxt
   'Takes any number of functions and executes all of them on the input'
   (test:is-each (num 0) (num 2) $true $false)
   { (juxt $base:dec~ $base:inc~ $base:is-odd~ $base:is-even~ ) 1}
   { put 1 | (juxt $base:dec~ $base:inc~ $base:is-odd~ $base:is-even~ )}
   { put $base:dec~ $base:inc~ $base:is-odd~ $base:is-even~ | juxt | (one) 1}]

  [constantly
  'Takes `@xs`. Returns a function which takes any number of args, and returns `@xs`'
  'The builtin will throw an error if you give it input args.'
  (test:is-one a)
  { (constantly a) 1 2 3 }
  { put 1 2 3 | (constantly a) (all) }
  { put a | constantly | (one) 1 2 3 }

  (test:is-one [a b c])
  { (constantly [a b c]) 1 2 3 }

  (test:is-each a b c)
  { (constantly a b c) 1 2 3 }]

  [comp
   'Composes functions into a new fn.  Contrary to expectation, works left-to-right.'
   (test:is-one (num 30))
   { (comp (partial $'*~' 5) (partial $'+~' 5)) 5 }
   { put 5 | (comp (partial $'*~' 5) (partial $'+~' 5)) }
   { put (partial $'*~' 5) (partial $'+~' 5) | comp | (one) 5 }]

  [box
   'Returns a function which calls `listify` on the result.  The function must have parameters.'
   (test:is-one [1 2 3])
   { (box {|@xs| put $@xs}) 1 2 3 }
   { put 1 2 3 | (box {|@xs| put $@xs}) }
   { put {|@xs| put $@xs} | box (one) | (one) 1 2 3 }]

  [memoize
   'Caches function results so they return more quickly.  Function must be pure.'
   (test:is-fn)
   { memoize {|n| sleep 1; * $n 10} }
   'Here, `$fixtures[f]` is a long running function.'
   (test:is-count 2 &fixtures=[&f=(memoize {|n| sleep 1; * $n 10})])
   {|fixtures| time { $fixtures[f] 10 } | all }
   {|fixtures| time { $fixtures[f] 10 } | all }]

  [repeatedly
   'Takes a zero-arity function and runs it `n` times'
   (test:is-count 10)
   { repeatedly 10 { randint 1000 } }]

  '# Reduce & company'
  [reduce
   'Reduce does what you expect.'
   (test:is-one (num 6))
   { reduce $'+~' 1 2 3 }
   { put 1 2 3 | reduce $'+~' }
   { put $'+~' 1 2 3 | reduce (all) }

   "It's important to understand that `reduce` only returns scalar values."
   (test:is-one [0 1 2])
   { reduce $base:append~ [] 0 1 2 }
   (test:is-one [&a=1 &b=2])
   { reduce {|a b| assoc $a $@b} [&] [a 1] [b 2] }

   "You can get around this by using `box`.  `comp` is defined similarly, for instance."
   "A fun thing to try is `reductions` with the following test.  Just remove the call to `all`."
   (test:is-each 0 1 2 3 4 5)
   { all (reduce (box {|a b| each {|x| put $x } $a; put $b }) [] 0 1 2 3 4 5) }]

  [reduce-kv
   'Like reduce, but the provided function params look like `[accumulator key value]` instead of [accumulator value]'
   'Most easily understood on a map.  In this example we swap the keys and values.'
   (test:is-one [&1=a &2=c])
   { reduce-kv {|a k v| assoc $a $v $k} [&] [&a=1 &b=2 &c=2] }
   { put [&a=1 &b=2 &c=2] | reduce-kv {|a k v| assoc $a $v $k} [&] (one) }

   'Varargs are treated as an associative list, using the index as the key'
   (test:is-one [&(num 0)=a &(num 1)=b &(num 2)=c])
   { reduce-kv {|a k v| assoc $a $k $v} [&] a b c }
   { put a b c | reduce-kv {|a k v| assoc $a $k $v} [&] (all) }
   { put [&] a b c | reduce-kv {|a k v| assoc $a $k $v} }

   "`reduce-kv` doesn't have to return a map.  Here, we also specify a starting index."
   (test:is-one (num 14))
   { reduce-kv &idx=1 {|a k v| + $a (* $k $v)} 0 1 2 3}
   { put 0 1 2 3 | reduce-kv &idx=1 {|a k v| + $a (* $k $v)} }]

  [reductions
   'Essentially reduce, but it gives the intermediate values at each step'
   (test:is-each 1 (num 3) (num 6))
   { reductions $'+~' 1 2 3 }
   { put 1 2 3 | reductions $'+~' }
   { put $'+~' 1 2 3 | reductions (all)}]

  '# Filter & company'
  [filter
   'Filter does what you expect.  `pfilter` works in parallel.'
   (test:is-each (num 2) (num 4) (num 6) (num 8))
   { filter $base:is-even~ (range 1 10) }
   { range 1 10 | filter $base:is-even~ }

   "It treats empty resultsets as $false."
   { filter {|n| if (== (% $n 2) 0) { put $true }} (range 1 10) }

   "Same with `$nil`."
   { filter {|n| if (== (% $n 2) 0) { put $true } else { put $nil }} (range 1 10) }]

  [remove
   'Remove does what you expect.  `premove` works in parallel.'
   (test:is-each (num 2) (num 4) (num 6) (num 8))
   { remove $base:is-odd~ (range 1 10) }
   { range 1 10 | remove $base:is-odd~ }]

  '# "Array" operations'
  [into
   'Shoves some input into the appropriate container.'
   (test:is-one [1 2 3])
   { into [] 1 2 3 }
   { into [1] 2 3 }
   { put 1 2 3 | into [] }
   { put [] 1 2 3 | into (all) }

   'You can also shove into a map'
   (test:is-one [&a=1 &b=2 &c=3])
   { into [&] [a 1] [b 2] [c 3] }
   { into [&b=2] [a 1] [c 3] }
   { put [a 1] [b 2] [c 3] | into [&] }

   'Into takes optional arguments for getting keys/vals from the input.'
   (test:is-one [&s=0x73 &t=0x74 &u=0x75 &f=0x66])
   { use str; into [&] &keyfn=$put~ &valfn=$str:to-utf8-bytes~ (all stuff) }

   'Into also takes an optional argument for handling collisions.'
   (test:is-one [&s=[0x73] &t=[0x74] &u=[0x75] &f=[0x66 0x66]])
   { use str; into [&] &keyfn=$put~ &valfn=(box $str:to-utf8-bytes~) &collision=$base:concat2~ (all stuff) }]

  [reverse
   "Does what's on the tin."
   (test:is-each (num 5) (num 4) (num 3) (num 2) (num 1) (num 0))
   { reverse (range 6) }
   { range 6 | reverse }]

  [distinct
   "Returns a set of the elements in `@arr`."
   "Does not care about maintaining order."
   (assert-equal-sets 1 2 3 4 5)
   { distinct 1 2 2 3 3 3 4 4 4 4 5 5 5 5 5 }
   { distinct 1 2 3 2 3 3 4 4 5 5 5 4 4 5 5 }
   { put 1 2 2 3 3 3 4 4 4 4 5 5 5 5 5 | distinct }

   "It doesn't care about mathematical equality"
   (assert-equal-sets 1 1.0 (num 1) (num 1.0))
   { distinct 1 1.0 (num 1) (num 1.0) }]

  [unique
   "Like `uniq` but works with the data pipe."
   (test:is-each 1 2 3 4 5)
   { unique 1 2 2 3 3 3 4 4 4 4 5 5 5 5 5 }
   { put 1 2 2 3 3 3 4 4 4 4 5 5 5 5 5 | unique }

   'Includes an optional `count` parameter.'
   (test:is-each [(num 1) 1] [(num 2) 2] [(num 3) 3] [(num 4) 4] [(num 5) 5])
   { unique &count=$true 1 2 2 3 3 3 4 4 4 4 5 5 5 5 5 }
   { put 1 2 2 3 3 3 4 4 4 4 5 5 5 5 5 | unique &count=true }

   "It doesn't care about mathematical equality"
   (test:is-each 1 1.0 (num 1) (num 1.0))
   { unique 1 1.0 (num 1) (num 1.0) }]

  [replace
   'Returns an "array" with elements of `coll` replaced according to `smap`.'
   'Works with combinations of lists & maps.'
   (test:is-each zeroth second fourth zeroth)
   { replace [zeroth first second third fourth] [(num 0) (num 2) (num 4) (num 0)] }
   (test:is-each four two 3 four 5 6 two)
   { replace [&2=two &4=four] [4 2 3 4 5 6 2] }
   (test:is-one [&name=jack &postcode=wd12 &id=123])
   { replace [&[city london]=[postcode wd12]] [&name=jack &city=london &id=123] | into [&] }]

  [interleave
   'Returns an "array" of the first item in each list, then the second, etc.'
   (test:is-each a 1 b 2 c 3)
   { interleave [a b c] [1 2 3] }

   'Understands mismatched lengths'
   { interleave [a b c d] [1 2 3] }
   { interleave [a b c] [1 2 3 4] }]

  [interpose
   'Returns an "array" of the elements seperated by `sep`.'
   (test:is-one one)
   { interpose , one }
   (test:is-each one , two)
   { interpose , one two }
   (test:is-each one , two , three)
   { interpose , one two three }]

  [partition
   "partitions an "array" into lists of size n."
   (test:is-each [(num 0) (num 1) (num 2)] ^
                 [(num 3) (num 4) (num 5)] ^
                 [(num 6) (num 7) (num 8)] ^
                 [(num 9) (num 10) (num 11)])
   { partition 3 (range 12) }
   { range 12 | partition 3 }

   "Drops items which don't complete the specified list size."
   { range 14 | partition 3 }

   'Specify `&step=n` to specify a "starting point" for each partition.'
   (test:is-each [(num 0) (num 1) (num 2)] [(num 5) (num 6) (num 7)])
   { range 12 | partition 3 &step=5 }

   "`&step` can be < than the partition size."
   (test:is-each [(num 0) (num 1)] [(num 1) (num 2)] [(num 2) (num 3)])
   { range 4 | partition 2 &step=1}

   "When there are not enough items to fill the last partition, a pad can be supplied."
   (test:is-each [(num 0) (num 1) (num 2)] ^
                 [(num 3) (num 4) (num 5)] ^
                 [(num 6) (num 7) (num 8)] ^
                 [(num 9) (num 10) (num 11)] ^
                 [(num 12) (num 13) a])
   { range 14 | partition 3 &pad=[a] }

   "The size of the pad may exceed what is used."
   (test:is-each [(num 0) (num 1) (num 2)] ^
                 [(num 3) (num 4) (num 5)] ^
                 [(num 6) (num 7) (num 8)] ^
                 [(num 9) (num 10) (num 11)] ^
                 [(num 12) a b])
   { range 13 | partition 3 &pad=[a b] }

   "...or not."
   (test:is-each [(num 0) (num 1) (num 2)] ^
                 [(num 3) (num 4) (num 5)] ^
                 [(num 6) (num 7) (num 8)] ^
                 [(num 9) (num 10) (num 11)] ^
                 [(num 12)])
   { range 13 | partition 3 &pad=[] }]

  [partition-all
   'Convenience function for `partition` which supplies `&pad=[]`.'
   "Use when you don't want everything in the resultset."
   (test:is-each [(num 0) (num 1) (num 2)] ^
                 [(num 3) (num 4) (num 5)] ^
                 [(num 6) (num 7) (num 8)] ^
                 [(num 9) (num 10) (num 11)] ^
                 [(num 12)])
   { partition-all 3 (range 13) }
   { range 13 | partition-all 3 }]

  [iterate
   "Returns an array of `(f x), (f (f x)), (f (f (f x)) ...)`, up to the nth element."
   (test:is-each (num 1) (num 2) (num 3) (num 4) (num 5) (num 6) (num 7) (num 8) (num 9) (num 10))
   { iterate $base:inc~ 10 (num 1)}

   'My favorite example of iterate is to generate fibonacci numbers.  In increasingly functional style:'
   (test:is-each (num 1) (num 1) (num 2) (num 3) (num 5) (num 8) (num 13) (num 21) (num 34) (num 55))
   { iterate {|l| put [$l[1] (+ $l[0] $l[1])]} 10 [(num 1) (num 1)] | each $base:first~ }
   { iterate (destruct {|a b| put [$b (+ $a $b)]}) 10 [(num 1) (num 1)] | each $base:first~ }
   { iterate (box (destruct (juxt $second~ $'+~'))) 10 [(num 1) (num 1)] | each $base:first~ }]

  [take-nth
   "Emits every nth element."
   (test:is-each (num 0) (num 2) (num 4) (num 6) (num 8))
   { take-nth 2 (range 10) }
   { range 10 | take-nth 2 }]

  [take-while
   "Emits items until `(f x)` yields an empty or falsey value."
   (test:is-each (num 0) (num 1) (num 2) (num 3) (num 4))
   { take-while (complement (partial $'<=~' 5)) (range 10) }
   { range 10 | take-while {|n| < $n 5 } }
   { take-while {|n| if (< $n 5) { put $true } } (range 10) }]

  [drop-while
   "Emits items until `(f x)` yields a non-empty or truthy value."
   (test:is-each (num 5) (num 6) (num 7) (num 8) (num 9))
   { drop-while (complement (partial $'<=~' 5)) (range 10) }
   { range 10 | drop-while {|n| < $n 5 } }
   { drop-while {|n| if (< $n 5) { put $true } } (range 10) }]

  [drop-last
   'Drops the last n elements of `@arr`.'
   (test:is-each (num 0) (num 1) (num 2) (num 3) (num 4) (num 5) (num 6) (num 7))
   { drop-last 2 (range 10) }
   { range 10 | drop-last 2 }]

  [butlast
   'Drops the last element of `@arr`.'
   (test:is-each (num 0) (num 1) (num 2) (num 3) (num 4) (num 5) (num 6) (num 7) (num 8))
   { butlast (range 10) }
   { range 10 | butlast }]

  '# Predicate runners'
  [some
   "Returns the first truthy `(f x)`"
   "If f is a true predicate (takes an element, returns $true or $false), `some` tells you if at least one (any/some) x satisfies the predicate."
   'Opposite function is `not-any`'
   (test:is-one $true)
   { some (partial $'>~' 5) (range 10) }
   { range 10 | some (partial $'>~' 5) }]

  [first-pred
   "`some` is useful for lots of things, but you probably want one of the other functions."
   (test:is-one (num 2))
   { first-pred (comp $math:sin~ (partial $'<~' (num 0.9))) (range 10) }
   { range 10 | first-pred (comp $math:sin~ (partial $'<~' (num 0.9))) }]

  [every
   'returns true if each x satisfies the predicate.'
   (test:is-one $true)
   { range 20 | each $math:sin~ [(all)] | every {|n| <= -1 $n 1} }]

  [not-every
   'opposite of `every`.'
   'returns true if at least one x fails to satisfy the predicate.'
   (test:is-one $false)
   { range 20 | each $math:sin~ [(all)] | not-every {|n| <= -1 $n 1} }]

  [not-any
   'opposite of `some`.'
   'returns true if none of the elements satisfy the predicate'
   (test:is-one $true)
   { range 20 | each $math:sin~ [(all)] | not-any {|n| > $n 1} }]

  '# Map functions'
  [keep
   'Returns an "array" of non-empty & non-nil results of `(f x)`.  `pkeep` works in parallel.'
   (test:is-each (num 2) (num 4) (num 6) (num 8))
   { keep {|x| if (base:is-even $x) { put $x }} (range 1 10) }
   { keep {|x| if (base:is-even $x) { put $x } else { put $nil }} (range 1 10) }
   { range 1 10 | keep {|x| if (base:is-even $x) { put $x }} }

   'Additionally, you can specify your own predicate function instead.'
   (test:is-each (num 6) (num 12) (num 18) (num 24))
   { keep (partial $'*~' 3) (range 1 10) &pred=$base:is-even~ }]

  [map
   '`map` is a more powerful than `each`.  It works with "array" values and reads from the pipe.  `pmap` works in parallel.'
   (test:is-each (num 1) (num 2) (num 3) (num 4) (num 5))
   { map $base:inc~ (range 5) }
   { range 5 | map $base:inc~ }
   { each $base:inc~ [(range 5)] }

   "Unlike `each`, `map` understands what to do with multiple lists."
   (test:is-each (num 22) (num 26) (num 30))
   { map $'+~' [1 2 3] [4 5 6] [7 8 9] [10 11 12] }

   "It also understands mismatches"
   { map $'+~' [1 2 3] [4 5 6] [7 8 9] [10 11 12 13 14 15] }

   "If you can, supply the optional parameters for faster performance."
   "For most operations, `&lists=$false` is enough."
   (test:is-each (num 1) (num 2) (num 3) (num 4) (num 5))
   { map $base:inc~ (range 5) &lists=$false }

   "When working with lists, supply `&els` for faster performance."
   (test:is-each (num 22) (num 26) (num 30))
   { map $'+~' [1 2 3] [4 5 6] [7 8 9] [10 11 12] &lists=$true &els=3 }

   "`map` can still process multiple lists the way that `each` does.  Just set `&lists=$false`."
   (test:is-each 1 4 7)
   { each $base:first~ [[1 2 3] [4 5 6] [7 8 9]] }
   { map $base:first~ [1 2 3] [4 5 6] [7 8 9] &lists=$false }]

  [mapcat
   "Applies concat to the result of `(map f xs)`.  Here for convenience."
   (test:is-one [1 2 3 4 5 6 7 8 9])
   { mapcat (box (destruct $reverse~)) [3 2 1] [6 5 4] [9 8 7] &lists=$false }

   "Here's some shenanigans.  What does it mean?  You decide."
   (test:is-each [9 6 3 8 5 2 7 4 1])
   { mapcat (box $reverse~) [3 2 1] [6 5 4] [9 8 7] &els=(num 3) }]

  [map-indexed
   'Like map but the index is the first parameter'
   (test:is-each [(num 0) s] [(num 1) t] [(num 2) u] [(num 3) f] [(num 4) f])
   { map-indexed {|i x| put [$i $x]} (all stuff) }
   { all stuff | map-indexed {|i x| put [$i $x]} }]

  [zipmap
   'Returns a map with the keys mapped to the corresponding vals'
   (test:is-one [&a=1 &b=2 &c=3])
   { zipmap [a b c] [1 2 3] }

   'Understands mismatches'
   { zipmap [a b c d] [1 2 3] }
   { zipmap [a b c] [1 2 3 4] }]

  [keep-indexed
   'Returns all non-empty & non-nil results of `(f index item)`.'
   (test:is-each b d f)
   { keep-indexed {|i x| if (base:is-odd $i) { put $x } else { put $nil }} a b c d e f g }

   'Of course, this works just as well.'
   { map-indexed {|i x| if (base:is-odd $i) { put $x } } a b c d e f g }

   'And supply your own predicate.'
   (test:is-each [(num 1) b] [(num 3) d] [(num 5) f])
   { keep-indexed {|i x| put [$i $x]} a b c d e f g &pred=(comp $base:first~ $base:is-odd~) }]

  '# Table functions'
  [pivot
   'Tables are an "array" of maps with a non-empty intersection of keys.'
   'This function pivots them.'
   (test:is-each [&name=weight &daniel=1000 &david=800 &vincent=600] ^
                 [&name=height &daniel=900  &david=700 &vincent=500])
   { pivot [&name=daniel  &weight=1000 &height=900] ^
           [&name=david   &weight=800  &height=700] ^
           [&name=vincent &weight=600  &height=500] }
   { put [&name=daniel  &weight=1000 &height=900] ^
         [&name=david   &weight=800  &height=700] ^
         [&name=vincent &weight=600  &height=500] ^
     | pivot }
   'Pivoting adds a new column called `name` and also uses the `name` coumn to identify each row, but this is configurable.'
   (test:is-each [&bar=weight &daniel=1000 &david=800 &vincent=600] ^
                 [&bar=height &daniel=900  &david=700 &vincent=500])
   { pivot [&foo=daniel  &weight=1000 &height=900] ^
           [&foo=david   &weight=800  &height=700] ^
           [&foo=vincent &weight=600  &height=500] ^
           &from_row=foo &to_row=bar}]]
