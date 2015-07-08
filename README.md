# lusp
Scheme-like toy language implemented in Lua. Based on the
amazing Peter Norvig's page "(How to Write a (Lisp) Interpreter (in Python))"
http://www.norvig.com/lispy.html.

Compatible with Lua 5.1, 5.2, LuaJIT.

To run lusp-repl run:
```
lua "repl.lua"
```
or run Lua and type:
```
require('lusp'):repl()
```

Voila! Now you can start uber-lisp-hacking:)

```
lusp> (+ 12 30)
42
lusp> (define sqr (lambda (x) (* x x)))
lusp> (sqr 5)
25
lusp> (define reduce (lambda (f l a) (if (null? l) a (reduce f (cdr l) (f (car l) a)))))
lusp> (reduce + (list 1 2 3) 0)
5
```
