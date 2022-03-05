use str
use re

fn make-assertion {
  |name f &fixtures=[&] &store=[&]|
  put [&name=$name &f=$f &fixtures=$fixtures &store=$store]
}

fn is-assertion {
  |form|
  and (eq (kind-of $form) map) ^
      has-key $form f ^
      (eq (kind-of $form[f]) fn)
}

fn call-test {
  |test-fn &fixtures=[&] &store=[&]|

  var test-args = $test-fn[arg-names]

  if (and (has-value $test-args fixtures) (has-value $test-args store)) {
    $test-fn $fixtures $store
  } elif (has-value $test-args store) {
    $test-fn $store
  } elif (has-value $test-args fixtures) {
    $test-fn $fixtures
  } else {
    $test-fn
  }
}

fn call-predicate {
  |predicate @reality &fixtures=[&] &store=[&]|

  var pred-opts = $predicate[opt-names]

  if (> (count $pred-opts) 0) {
    $predicate $@reality &fixtures=$fixtures &store=$store
  } else {
    $predicate $@reality
  }
}

fn assert {
  |expect predicate &fixtures=[&] &store=[&] &name=assert
   &docstring='base-level assertion.  avoid unless you need a predicate'
   &arglist=[[expect anything 'a function name (str), or the expected value']
             [predicate fn 'single-arity. might have optional fixtures & store']
             [fixtures list 'immutable list']
             [store list 'list which tests can persist changes to']]|
  make-assertion $name {
    |test-fn &store=[&]|

    var new-store = $store

    # call test
    var @reality = (var err = ?(call-test $test-fn &fixtures=$fixtures &store=$store))

    if (and (eq $err $ok) (has-value $test-fn[arg-names] store)) {
      if (< (count $reality) 2) {
        fail 'test '{$test-fn[body]}' took store but did not emit store.  response='{(to-string $reality)}
      } elif (not (eq (kind-of $reality[0]) map)) {
        fail 'test '{$test-fn[body]}' took store but did not emit store as a map.  response[0]='{(to-string $reality[0])}
      } else {
        set new-store @reality = $@reality
      }
    }

    # call predicate
    var bool @messages = (if (eq $err $ok) {
        call-predicate $predicate $@reality &fixtures=$fixtures &store=$new-store
      } else {
        call-predicate $predicate $err &fixtures=$fixtures &store=$new-store
    })

    put [&bool=$bool &expect=$expect &reality=$reality
         &test=$test-fn[body] &messages=$messages
         &store=$new-store]
  } &fixtures=$fixtures &store=$store
}

fn is {
  |expectation &fixtures=[&] &store=[&]|
  assert $expectation {|@reality| 
    and (== (count $reality) 1) ^
        (eq $expectation $@reality)
  } &name=is &fixtures=$fixtures &store=$store
}

fn is-each {
  |expectation &fixtures=[&] &store=[&]|
  assert $expectation {|@reality| 
    eq $expectation $reality
  } &name=is-each &fixtures=$fixtures &store=$store
}

fn is-error {
  |&fixtures=[&] &store=[&]|
  assert exception {|@reality| 
    and (== (count $reality) 1) ^
        (not-eq $@reality $ok) ^
        (eq (kind-of $@reality) exception)
  } &name=is-error &fixtures=$fixtures &store=$store
}

fn is-something {
  |&fixtures=[&] &store=[&]|
  assert something {|@reality|
    var @kinds = (each $kind-of~ $@reality)
    and (> (count $kinds) 0) ^
        (or (has-value $kinds list) ^
            (has-value $kinds map) ^
            (has-value $kinds fn) ^
            (has-value $kinds num) ^
            (has-value $kinds float64) ^
            (has-value $kinds string))
  } &name=is-something &fixtures=$fixtures &store=$store
}

fn is-list {
  |&fixtures=[&] &store=[&]|
  assert list {|@reality|
    and (== (count $reality) 1) ^
        (eq (kind-of $@reality) list)
  } &name=is-list &fixtures=$fixtures &store=$store
}

fn is-map {
  |&fixtures=[&] &store=[&]|
  assert map {|@reality|
    and (== (count $reality) 1) ^
        (eq (kind-of $@reality) map)
  } &name=is-map &fixtures=$fixtures &store=$store
}

fn is-coll {
  |&fixtures=[&] &store=[&]|
  assert collection {|@reality|
    and (== (count $reality) 1) ^
        (has-value [list map] (kind-of $@reality))
  } &name=is-coll &fixtures=$fixtures &store=$store
}

fn is-fn {
  |&fixtures=[&] &store=[&]|
  assert fn {|@reality|
    and (== (count $reality) 1) ^
        (eq (kind-of $@reality) fn)
  } &name=is-fn &fixtures=$fixtures &store=$store
}

fn is-num {
  |&fixtures=[&] &store=[&]|
  assert num {|@reality|
    and (== (count $reality) 1) ^
        (eq (kind-of $@reality) num)
  } &name=is-num &fixtures=$fixtures &store=$store
}

fn is-float {
  |&fixtures=[&] &store=[&]|
  assert float64 {|@reality|
    and (== (count $reality) 1) ^
        (eq (kind-of $@reality) float64)
  } &name=is-float &fixtures=$fixtures &store=$store
}

fn is-numeric {
  |&fixtures=[&] &store=[&]|
  assert number {|@reality|
    and (== (count $reality) 1) ^
        (has-value [num float64] (kind-of $@reality))
  } &name=is-numeric &fixtures=$fixtures &store=$store
}

fn is-string {
  |&fixtures=[&] &store=[&]|
  assert string {|@reality|
    and (== (count $reality) 1) ^
        (eq (kind-of $@reality) string)
  } &name=is-string &fixtures=$fixtures &store=$store
}

fn is-nil {
  |&fixtures=[&] &store=[&]|
  assert nil {|@reality|
    and (== (count $reality) 1) ^
        (eq (kind-of $@reality) nil)
  } &name=is-nil &fixtures=$fixtures &store=$store
}

fn test {
  |tests &break=break &docstring='test runner'|

  var test-elements subheader
  var subheaders = []
  var header @els = $@tests

  if (not-eq (kind-of $header) string) {
    fail 'missing header'
  }

  put $break
  put $header

  for el $els {

    var assertion

    if (eq (kind-of $el) string) {
      put $el
      continue
    }

    put $break

    set subheader @test-elements = $@el

    if (not-eq (kind-of $header) string) { 
      fail 'missing subheader'
    }

    put $subheader
    set subheaders = [$@subheaders $subheader]

    var store

    for tel $test-elements {
      if (eq (kind-of $tel) string) {
        put $tel
      } elif (is-assertion $tel) {
        set assertion = $tel
        set store = $assertion[store]
      } elif (eq (kind-of $tel) fn) {
        if (eq $assertion $nil) {
          fail 'no assertion set before '{$tel[def]}
        }
        var last-test = ($assertion[f] $tel &store=$store)
        set store = $last-test[store]
        assoc $last-test header $header
      } else {
        fail {$tel}' is invalid'
      }

    }

  }

  put $subheaders
}

fn format-test {
  |body style-fn|
  if (not (re:match \n $body)) {
    put [($style-fn $body)]
    return
  }
  var spaces = 0
  var @lines = (re:split \n $body | each {|s| str:trim $s ' '})
  for line $lines {
    if (re:match '^}.*' $line) { # ends with }
      set spaces = (- $spaces 2)
    }

    put [(styled (str:from-codepoints 0x2503) white bold)
      ' ' (repeat $spaces ' ' | str:join '')
    ($style-fn $line)]

    if (or (re:match '.*{$' $line) ^
      (re:match '.*\^$' $line) ^
    (re:match '.*{\ *\|[^\|]*\|$' $line)) {
      set spaces = (+ $spaces 2)
    }
  }
}

fn plain {
  |break @xs subheaders|
  var info-text = {|s| styled $s white }
  var header-text = {|s| styled $s white bold }
  var error-text = {|s| styled $s red }
  var error-text-code = {|s| styled $s red bold italic}
  var success-text = {|s| styled $s green }

  var break-length = (if (< 80 (tput cols)) { put 80 } else { tput cols })
  var break-text = (repeat $break-length (str:from-codepoints 0x2500) | str:join '')

  var testmeta

  for x $xs {
    if (eq $x $break) {
      echo $break-text
    } elif (and (eq (kind-of $x) string) (has-value $subheaders $x)) {
      echo ($header-text $x)
    } elif (eq (kind-of $x) map) {
      set testmeta = $x
      if $testmeta[bool] {
        format-test $testmeta[test] $success-text | each {|line| echo $@line}
      } else {
        var expect = (to-string $testmeta[expect])
        var reality = (to-string $testmeta[reality])
        echo
        format-test $testmeta[test] $error-text-code | each {|line| echo $@line}
        echo ($error-text 'EXPECTED: '{$expect})
        echo ($error-text '     GOT: '{$reality})
        echo
      }
    }
  }
}

fn err {
  |break @xs subheaders|
  var header-text = {|s| styled $s white bold underlined }
  var error-text = {|s| styled $s red }
  var error-text-code = {|s| styled $s red bold italic}
  var info-text = {|s| styled $s white italic }
  var info-code = {|s| styled $s white bold italic }

  var break-length = (if (< 80 (tput cols)) { put 80 } else { tput cols })
  var break-text = (repeat $break-length (str:from-codepoints 0x2500) | str:join '')

  var testmeta

  for x $xs {
    if (eq (kind-of $x) map) {
      set testmeta = $x
      if (not $testmeta[bool]) {
        var expect = (to-string $testmeta[expect])
        var reality = (to-string $testmeta[reality])

        echo
        echo ($header-text $testmeta[header])
        format-test $testmeta[test] $error-text-code | each {|line| echo $@line}
        echo ($error-text 'EXPECTED: '{$expect})
        echo ($error-text '     GOT: '{$reality})

        if (> (count $testmeta[store]) 0) {
          echo ($header-text STORE)
          echo ($info-code $testmeta[store])
        }

        if (> (count $testmeta[messages]) 0) {
          echo ($header-text MESSAGES)
          for msg $testmeta[messages] {
            echo ($info-text $msg)
          }
          echo
        }

        echo
        echo $break-text
      }
    }
  }

}

var tests = [Tests
             [make-assertion
              (is-map)
              { make-assertion foo { } }
              { make-assertion foo { } &fixtures=[&]}
              { make-assertion foo { } &store=[&]}
              { make-assertion foo { } &fixtures=[&] &store=[&]}]

             [is-assertion
              (assert assertion $is-assertion~)
              { make-assertion foo { put foo } }

              '`is-assertion` only cares about the presence of `f` key'
              { make-assertion foo { } | dissoc (all) fixtures | dissoc (all) store }

              'All other assertions satisfy the predicate'
              { assert foo { put $true } }
              { is foo }
              { is-each [foo bar] }
              { is-error }
              { is-something }
              { is-list }
              { is-map }
              { is-coll }
              { is-fn }
              { is-num }
              { is-float }
              { is-numeric }
              { is-string }
              { is-nil }]

             [helpers
              'These functions are useful if you are writing a low-level assertion like `assert`.  Your test function can be one of four forms, and `call-test` will dispatch based on argument-reflection.'
              'The following tests demonstrate that type of dispatch.'
              (is something)
              { call-test {|| put something} }

              (is foo)
              { call-test {|store| put $store[x]} &store=[&x=foo] }

              (is bar)
              { call-test {|fixtures| put $fixtures[x]} &fixtures=[&x=bar] }

              (is-each [foo bar])
              { call-test {|fixtures store| put $fixtures[x]; put $store[x]} &fixtures=[&x=foo] &store=[&x=bar] }

              '`call-test` expects fixtures before store.  This test errors because the input args are swapped.'
              (is-error)
              { call-test {|store fixtures| put $fixtures[a]; put $store[b]} &fixtures=[&a=a] &store=[&b=b] }

              '`call-predicate` accepts two forms.'
              (is $true)
              { call-predicate {|@reality| eq $@reality foo} foo }
              { call-predicate {|@reality &fixtures=[&] &store=[&]|
                                  == ($reality[0] $fixtures[x] $store[x]) -1
                               } $compare~ &fixtures=[&x=1] &store=[&x=2] }

              'Any other form will error'
              (is-error)
              { call-predicate {|@reality &store=[&]| eq $@reality foo} foo }
              { call-predicate {|@reality &fixtures=[&]| eq $@reality foo} foo }]

             [assert
              'assertions return the boolean result, the expected value, the values emmited from the test, the test body, any messages produced by the assertion, and the store (more on that later)'
              (is [&test='put foo ' &expect=foo &bool=$true &store=[&] &messages=[] &reality=[foo]])
              { (assert foo {|@x| eq $@x foo})[f] { put foo } }

              'The expected value can be the exact value you want, or it can be a description of what you are testing for'
              (is string-with-foo)
              { (assert string-with-foo {|@x| str:contains $@x foo})[f] { put '--foo--' } | put (all)[expect] }

              'if your predicate takes a store, then the predicate must emit the store first'
              (assert [&foo=bar] {|@result &store=[&] &fixtures=[&]| eq $store[foo] bar})
              {|store| assoc $store foo bar; put foo }

              (is-error)
              { test [mytest [subheader {|store| put foo} ]] }

              'The `store` must be returned as a map'
              { test [mytest [subheader {|store| put foo; put bar} ]] }

              ]]
