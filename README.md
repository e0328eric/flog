# flog
flog language for code golfing

## Grammar of flog
Although this is a compiled language, it is a stack based language. For example, the code `1 2+`
means that first, push `1` into the stack and `2` is pushed into the stack. And pop two values and
push the added value.

### Operators
#### Arithmetic
- `+` : Addition or string concatenation. `flog` does not allow implicit type conversion.
- `-` : Negation and subtraction. If one write `2-2-`, then the result is `4` because `2-(-2)=4`.
- `*` : Multiplication
- `/` : Euclidean Division.
- `%` : Euclidean Remainder. It is always true that `a = b * (a / b) + (a % b)` and `0 <= a % b < a`.
- `E` : Power. For example, the expression `2 3 4EE` is equal to `2^(3^4)`.
- `U` : Increment.
- `D` : Decrement.

#### Boolean Operators
- `!` : Boolean Not. In `flog`, everything is `true` value except `0`, `null`, `NaN`, empty
  string and float number whose absolute value is less than 1E-12.
- `=` : Equality. If two values are equal, then return `1`. Otherwise, return `0`.
- `<` : Less than.
- `>` : Greater than.

#### Stack Manipulation
- `$` : Duplicate (front). It need additional number. For example, `3$` means that duplicate value
    at the position 3 and push it into the stack. Here, the positoon of the very front of the stack
    is 0. `$` is just an abbreviation of `0$`.
- `#` : Duplicate (back). It need additional number. For example, `3#` means that duplicate value
    at the position 3 and push it into the stack. Here, the position of the very last of the stack
    is 0. `#` is just an abbreviation of `0#`.
- `@` : Rotate

#### I/O
- `,` : Push value into the print queue.
- `P` : Drain the print queue. `

#### Miscellaneous
- `A` : Assignment operator. For example, `Afoo` means that store a value at the top of the stack
    into a variable called `foo`. Here, the top element is popped.
- `C` : Same as `A` but it does not pop the stack.
- `?` : If statement.    `<Grammar>: ?{<conditional>}{<true stmt>}{<false stmt>}`
- `L` : Loop statement.  `<Grammar>: L{<conditional>}{<loop stmt>}`

## Example code
1. Hello, World
```
"Hello, World!",P
```

2. 99 bottles of beer
```
(,,P:"{} bottles of beer {}\n";):a;99L{#0>}{##"on the wall"a"\nTake one down, pass it around"aD}
```
