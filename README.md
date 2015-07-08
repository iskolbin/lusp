# lusp
Scheme-like toy language implemented in Lua. Based on the
amazing Peter Norvig's page "(How to Write a (Lisp) Interpreter (in Python))"
http://www.norvig.com/lispy.html

Compatible with Lua 5.1, 5.2, LuaJIT

To run lusp-repl run Lua and type
```
#!lua
require('lusp'):repl()
```

Voila! Now you can start uber-lisp-hacking:)

```
#!lisp
lusp> (+ 12 30)
42
lusp> (define sqr (lambda (x) (* x x)))
lusp> (sqr 5)
25
```
