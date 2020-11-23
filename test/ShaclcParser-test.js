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

var parser = new ShaclcParser();

console.log(parser.parse(testFile));
console.log(parser.lexer)



// describe('A SHACLC parser', function() {
//     var parser = new ShaclcParser();


// })

