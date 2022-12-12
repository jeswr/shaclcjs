const fs = require('fs');
const path = require('path');
const Parser = require('../lib').Parser;
const N3 = require('n3');
const { isomorphic } = require('rdf-isomorphic');

const testFile = fs.readdirSync(path.join(__dirname, 'valid')).filter(str => str.endsWith('.shaclc'))
let i = 0;
for (const file of testFile) {
  if (process.argv[2] && !file.toLowerCase().includes(process.argv[2].toLowerCase())) {
    continue;
  }

  const shaclc = fs.readFileSync(path.join(__dirname, 'valid', file)).toString();
  const ttl = fs.readFileSync(path.join(__dirname, 'valid', file.replace('.shaclc', '.ttl'))).toString();

  const shaclcParser = new Parser();

  const parsedShaclc = shaclcParser.parse(shaclc)
  const parsedttl = (new N3.Parser()).parse(ttl);

  const writer = new N3.Writer();

  const shaclcSet = new N3.Store(parsedShaclc);
    const turtleSet = new N3.Store(parsedttl.map(quad => {
      return N3.DataFactory.quad(
        quad.subject.termType === 'BlankNode' ? N3.DataFactory.blankNode(quad.subject.value.replace('n3-', 'g_')) : quad.subject,
        quad.predicate.termType === 'BlankNode' ? N3.DataFactory.blankNode(quad.predicate.value.replace('n3-', 'g_')) : quad.predicate,
        quad.object.termType === 'BlankNode' ? N3.DataFactory.blankNode(quad.object.value.replace('n3-', 'g_')) : quad.object,
      )
    }));

  const str = writer.quadsToString([
    ...shaclcSet
  ]);

  
  if (!isomorphic(parsedShaclc, parsedttl)) {
    for (const quad of shaclcSet) {
      const str = writer.quadsToString([
        quad
    ]);
      if (!turtleSet.has(quad)) {
        console.log(str)
      }
    }

    const str2 = writer.quadsToString([
      ...turtleSet
    ]);
    console.log()
    console.log(str)
    console.log()
    console.log(str2)
    console.log()

    i++;

    console.log('='.repeat(10))
    console.log(shaclc)
    console.log('-'.repeat(10))
    console.log(
      prettyTurtle([
        ...shaclcSet
      ])
    )
    
    console.log('='.repeat(10))
  }

  console.log('='.repeat(10))
    console.log(shaclc)
    console.log('-'.repeat(10))
    console.log(
      prettyTurtle([
        ...shaclcSet
      ])
    )
    
    console.log('='.repeat(10))
}


console.log(`${testFile.length - i}/${testFile.length}`)
  
if (i > 0) {
  process.exit(1);
}

function prettyTurtle(quads) {
  const TYPE = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'
  let result = '';
  // TODO: Sort by length of prefix so best prefix gets picked
  const prefix = { 'http://example.org/test#': 'ext', 'http://example.org/': 'ex', 'http://www.w3.org/ns/shacl#': 'sh', 'http://www.w3.org/2002/07/owl#': 'owl', 'http://www.w3.org/1999/02/22-rdf-syntax-ns#': 'rdf', 'http://www.w3.org/2001/XMLSchema#': 'xsd' }
  const store =  new N3.Store(quads);
  const writer = new N3.Writer();

  const blankObjectsToEncode = [];

  const encodedBlanks = {}

  function fromPredicate(subject, indent = 1) {
    const types = store.getObjects(subject, N3.DataFactory.namedNode(TYPE));

      if (types.length > 0) {
        result += ' a ' + types.map(type => encodeObject(type)).join(', ')  + ' ;'
      }

      const predicates = store.getPredicates(subject).filter(predicate => !predicate.equals(N3.DataFactory.namedNode(TYPE)));

      for (const predicate of predicates) {
        let blankObjects = [];
        const nonBlankObjects = [];
        for (const object of store.getObjects(subject, predicate)) {
          if (object.termType === 'BlankNode') {
            if ([...store.match(null, null, object), ...store.match(null, object, null)].length > 1) {
              nonBlankObjects.push(object)
              if (!encodedBlanks[object.value]) {
                blankObjectsToEncode.push(object);
                encodedBlanks[object.value] = true
              }
              
            } else {
              blankObjects.push(object)
            }
          } else {
            nonBlankObjects.push(object)
          }
        }

        const listObjects = []

        const oStrings = [...nonBlankObjects.map(x => encodeObject(x)), ...listObjects]

        result += '\n' + '  '.repeat(indent) + encodePredicate(predicate) + ' ' + oStrings.join(', ')

        if (blankObjects.length > 0) {
          if (oStrings.length > 0) {
            result += ', '
          }

          let i = 0;
          
          for (const blank of blankObjects) {
            result += '['
            fromPredicate(blank, indent + 1)
            result += '\n' + '  '.repeat(indent) + ']'

            if (++i < blankObjects.length) {
              result += ', '
            }
          }

        }

        result += ' ;'
      }
  }

  function encodeSubject(subject) {
    if (subject.termType === 'NamedNode') {
      if (subject.value === TYPE) {
        return TYPE;
      }
      for (const key in prefix) {
        if (subject.value.startsWith(key)) {
          return prefix[key] + ':' + subject.value.slice(key.length)
        }
      }
    }
    return writer._encodeSubject(subject);
  }

  function encodePredicate(subject) {
    if (subject.termType === 'NamedNode') {
      if (subject.value === TYPE) {
        return TYPE;
      }
      for (const key in prefix) {
        if (subject.value.startsWith(key)) {
          return prefix[key] + ':' + subject.value.slice(key.length)
        }
      }
      for (const key in prefix) {
        if (subject.value.startsWith(key)) {
          return prefix[key] + ':' + subject.value.slice(key.length)
        }
      }
    }
    return writer._encodePredicate(subject);
  }

  function encodeObject(subject) {
    if (subject.termType === 'NamedNode') {
      if (subject.value === TYPE) {
        return TYPE;
      }
      for (const key in prefix) {
        if (subject.value.startsWith(key)) {
          return prefix[key] + ':' + subject.value.slice(key.length)
        }
      }
      for (const key in prefix) {
        if (subject.value.startsWith(key)) {
          return prefix[key] + ':' + subject.value.slice(key.length)
        }
      }
    }
    return writer._encodeObject(subject);
  }

  for (const subject of store.getSubjects()) {
    if (subject.termType === 'NamedNode') {
      result += encodeSubject(subject)
      
      fromPredicate(subject)

      result += '\n.\n\n'
    }
  }

  while (blankObjectsToEncode.length > 0) {
    const subject = blankObjectsToEncode.pop();

    result += encodeSubject(subject)
    fromPredicate(subject)
    result += '\n.\n\n'
  }

  return result;
}
