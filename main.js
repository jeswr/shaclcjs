const fs = require('fs');
const N3 = require('n3');
const path = require('path')

const TYPE = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'

function prettyTurtle() {
  let result = '';
  // TODO: Sort by length of prefix so best prefix gets picked
  const prefix = { 'http://example.org/test#': 'ext', 'http://example.org/': 'ex', 'http://www.w3.org/ns/shacl#': 'ns', 'http://www.w3.org/2002/07/owl#': 'owl' }


  const ttl = fs.readFileSync(path.join(__dirname, 'test', 'valid', 'nestedShape.ttl')).toString();
  
  const store =  new N3.Store((new N3.Parser()).parse(ttl));
  const writer = new N3.Writer();

  const blankObjectsToEncode = [];

  function fromPredicate(subject, indent = 1) {
    // console.('\t'.repeat(indent))
    const types = store.getObjects(subject, N3.DataFactory.namedNode(TYPE));

      // let postFix = ''
      if (types.length > 0) {
        result += ' a ' + types.map(type => encodeObject(type)).join(', ')  + ' ;'
      }

      const predicates = store.getPredicates(subject).filter(predicate => !predicate.equals(N3.DataFactory.namedNode(TYPE)));

      // if (predicates.length === 0) {

      // }
      
      
      
      // console.log(writer._encodeSubject(subject), postFix, ';')
      for (const predicate of predicates) {
        const blankObjects = [];
        const nonBlankObjects = [];
        
        // console.log('objects are', store.getObjects(subject, predicate))
        for (const object of store.getObjects(subject, predicate)) {
          if (object.termType === 'BlankNode') {
            if ([...store.match(null, null, object), ...store.match(null, object, null)].length > 1) {
              nonBlankObjects.push(object)
              blankObjectsToEncode.push(object);
            } else {
              blankObjects.push(object)
            }
          } else {
            nonBlankObjects.push(object)
          }
        }

        
        
        // const nonBlankObjects = store.getObjects(subject, predicate).filter(x !== x.termType === 'BlankNode');



        console.log(nonBlankObjects)
        result += '\n' + '  '.repeat(indent) + encodePredicate(predicate) + ' ' + nonBlankObjects.map(x => encodeObject(x)).join(', ')

        if (blankObjects.length > 0) {
          if (nonBlankObjects.length > 0) {
            result += ', '
          }

          result += '['

          for (const blank of blankObjects) {
            fromPredicate(blank, indent + 1)
          }

          result += '\n' + '  '.repeat(indent) + ']'
        }

        result += ' ;'

        // const objects = store.getObjects(subject, predicate).filter(x !== x.termType === 'BlankNode')
        
        
        // result += 
        
        //+ store.getObjects(subject, predicate).map(object => writer._encodeObject(object)).join(', ')
        // if (!predicate.equals(N3.DataFactory.namedNode(TYPE)))
          // console.log('  ', writer._encodePredicate(predicate), store.getObjects(subject, predicate).map(object => writer._encodeObject(object)).join(', '), ';')
      }
      // result += ' .'
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
    console.log('encoding object', subject)
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

      // const types = store.getObjects(subject, N3.DataFactory.namedNode(TYPE));

      // let postFix = ''
      // if (types.length > 0) {
      //   postFix = 'a ' + types.map(type => writer._encodeObject(type)).join(', ')
      // }
      
      
      
      // console.log(writer._encodeSubject(subject), postFix, ';')
      // for (const predicate of store.getPredicates(subject)) {
      //   if (!predicate.equals(N3.DataFactory.namedNode(TYPE)))
      //     console.log('  ', writer._encodePredicate(predicate), store.getObjects(subject, predicate).map(object => writer._encodeObject(object)).join(', '), ';')
      // }


      // console.log() 
    }

    // return result;
  }

  while (blankObjectsToEncode.length > 0) {
    const subject = blankObjectsToEncode.pop();

    result += encodeSubject(subject)
    fromPredicate(subject)
    result += '\n.\n\n'
  }

  return result;
  console.log(store.getSubjects())
}

console.log(
  prettyTurtle()
)
