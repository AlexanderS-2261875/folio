# Code samples

```swift
/// A tiny model.
struct Greeting: Sendable {
    let name: String
    func say() -> String { "Hello, \(name)!" }   // interpolation
}
let count = 42
```

```python
def fib(n: int) -> int:
    """Return the n-th Fibonacci number."""
    return n if n < 2 else fib(n - 1) + fib(n - 2)
```

```json
{ "name": "Folio", "version": 1, "dark": true, "tags": null }
```

```diff
- let old = "before"
+ let new = "after"
```

```bash
for f in *.md; do echo "Opening $f"; open -a Folio "$f"; done
```

```
plain block, no language
```
