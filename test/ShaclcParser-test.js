var ShaclcParser = require('../lib/ShaclcParser').Parser

const testFile = String.raw`BASE <http://example.com/ns>

IMPORTS <http://example.com/person-ontology>

PREFIX ex: <http://example.com/ns#>

shape ex:PersonShape -> ex:Person {
	closed=true ignoredProperties=[rdf:type] . 

	ex:ssn       xsd:string [0..1] pattern="^\\d{3}-\\d{2}-\\d{4}$" .
	ex:worksFor  IRI ex:Company [0..*] .
	ex:address   BlankNode [0..1] {
		ex:city xsd:string [1..1] .
		ex:postalCode xsd:integer|xsd:string [1..1] maxLength=5 .
	} .
}`

const { DataFactory, Parser } = require('n3');
// console.log(DataFactory)

var parser = new ShaclcParser({ factory: DataFactory });
parser.Parser.factory = DataFactory;

// console.log('hiii')

let i = 0;

parser.Parser.onQuad = (quad) => {
	console.log(quad.subject?.value, quad.predicate?.value, quad.object?.value)
	i++;
}

console.log(parser.parse(testFile));
// console.log(parser.lexer)

console.log(i)

const fs = require('fs');
const path = require('path')

const ttlParser = new Parser();

const quads = ttlParser.parse(
	fs.readFileSync(path.join(__dirname, 'shape.ttl')).toString()
)

console.log(quads.length)
// quads.forEach(quad => {
// 	console.log(quad.subject?.value, quad.predicate?.value, quad.object?.value)
// })

// describe('A SHACLC parser', function() {
//     var parser = new ShaclcParser();


// })

