# shaclc-parse
A parser for files written with SHACL compact syntax

## Usage
```ts
import { parse } from 'shaclc-parse'

const quads = parse(`
BASE <http://example.org/basic-shape-with-targets>

PREFIX ex: <http://example.org/test#>

shape ex:TestShape -> ex:TestClass1 ex:TestClass2 {
	targetNode=ex:TestNode targetSubjectsOf=ex:subjectProperty targetObjectsOf=ex:objectProperty .
}
`)

```

## License
©2022–present
[Jesse Wright](https://github.com/jeswr),
[MIT License](https://github.com/jeswr/shaclcjs/blob/main/LICENSE).
