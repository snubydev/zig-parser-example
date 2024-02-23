# ![(avatar)](https://avatars.githubusercontent.com/u/27973237?s=48&v=4)   Zig parser example

Parse a simple arithmetic expression with binary oprators and calculate result.

### Example    
given a string with math expression "500 * ( 13 + 8 ) * 10"    
parse and calculate the result?

### Usage
Install zig 0.11+ programming language from [ziglang.org](https://ziglang.org/learn/getting-started/#installing-zig)
```
$ zig build-exe main.zig

$ ./main "500 * ( 13 + 8 ) * 10"

```

### Tests
```
$ zig test test_main.zig

$ zig test test_parser.zig
```
### Links 
Inspired by Jonathan Blow ["Discussion with Casey Muratori about how easy precedence is..."](https://www.youtube.com/watch?v=fIPO4G42wYE) (youtube)

