const fs = require('fs');
const path = require('path');
const Parser = require('../lib').Parser;
const SParser = require('../lib/ShaclcParser').Parser;
const N3 = require('n3');
const { isomorphic } = require('rdf-isomorphic');
const { parser } = require('../lib/ShaclcParser');

const testFile = fs.readdirSync(path.join(__dirname, 'valid')).filter(str => str.endsWith('.shaclc'))
let i = 0;
for (const file of testFile) {
  // console.log(process.argv[2], !file.includes(process.argv[2]), process.argv[2] || !file.includes(process.argv[2]), file);
  // continue;
  // console.log(file)

  if (process.argv[2] && !file.toLowerCase().includes(process.argv[2].toLowerCase())) {
    continue;
  }

  // console.log('run', file)

  const shaclc = fs.readFileSync(path.join(__dirname, 'valid', file)).toString();
  const ttl = fs.readFileSync(path.join(__dirname, 'valid', file.replace('.shaclc', '.ttl'))).toString();
  
  // const shaclcSet = new N3.Store((new Parser()).parse(shaclc));
  // const turtleSet = new N3.Store((new N3.Parser()).parse(ttl));

  // isomorphic(shaclcSet, turtleSet)

  // console.log
  // console.log(
  //   (new Parser()).parse(shaclc)
  // )

  const shaclcParser = new Parser();
  // console.log(shaclcParser)
  // SParser._resetBlanks();
  // N3.Parser._resetBlankNodePrefix();

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
    // console.log('not isomprhic')
    // console.log(file)
    
    // const shaclcSet = new N3.Store(parsedShaclc);
    // const turtleSet = new N3.Store(parsedttl.map(quad => {
    //   return N3.DataFactory.quad(
    //     quad.subject.termType === 'BlankNode' ? N3.DataFactory.blankNode(quad.subject.value.replace('n3-', 'g_')) : quad.subject,
    //     quad.predicate.termType === 'BlankNode' ? N3.DataFactory.blankNode(quad.predicate.value.replace('n3-', 'g_')) : quad.predicate,
    //     quad.object.termType === 'BlankNode' ? N3.DataFactory.blankNode(quad.object.value.replace('n3-', 'g_')) : quad.object,
    //   )
    // }));
    // const writer = new N3.Writer();

    for (const quad of shaclcSet) {
      

      const str = writer.quadsToString([
        quad
    ]);
      if (!turtleSet.has(quad)) {
        console.log(str)
      }
    }

    // const writer = new N3.Writer();

    // const str = writer.quadsToString([
    //   ...shaclcSet
    // ]);
    const str2 = writer.quadsToString([
      ...turtleSet
    ]);
    console.log()
    console.log(str)
    console.log()
    console.log(str2)
    console.log()
    // console.log((new SParser()).lexer)

    // const lexer = (new SParser()).lexer;
    // lexer.setInput(shaclc)
    // lexer.begin()

    // for (let i = 0; i < 100; i++) {
      // console.log('pop', lexer.yy)
    // }
    // lexer.

    // console.log(SParser)
    // for (const key in new SParser().lexer) {
    //   console.log(key)
    // }

    // for (const quad of shaclcSet) {
    //   if (!turtleSet.has(quad))
    //     console.log(quad.subject, quad.predicate, quad.object)
    // }

    // console.log('boo')
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

  // console.log(shaclc)
  
  // if ((new Parser()).parse(shaclc).length !== (new N3.Parser()).parse(ttl).length) {
  //   i++;
  //   console.log(`[${(new N3.Parser()).parse(ttl).length} ${(new Parser()).parse(shaclc).length} ${file}]`,shaclc)
  //   if ((new N3.Parser()).parse(ttl).length - (new Parser()).parse(shaclc).length < 0) {
  //     // console.log(shaclc)
  //     // console.log(ttl)
  //     // console.log((new Parser()).parse(shaclc))
  //     // console.log((new N3.Parser()).parse(ttl))
  //   }
    
    
    
  //   // console.log(
  //   //   (new N3.Parser()).parse(ttl).length - (new Parser()).parse(shaclc).length
  //   // )
  // }

  
  
  
  // console.log('-'.repeat(30))
  // console.log('-'.repeat(30))
  // const parser = new Parser();
  // const quads = parser.parse(shaclc)
  // console.log(quads.length)
  // // console.log(shaclc)
  // console.log('-'.repeat(30))
  // const n3Parser = new Parser();
  // n3Parser.parse(ttl);
  // console.log(ttl)
}


console.log(`${testFile.length - i}/${testFile.length}`)
  
if (i > 0) {
  process.exit(1);
}

// console.log(elems)


// const fs = require('fs');
// const N3 = require('n3');
// const path = require('path')


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
        let blankObjects = [];
        const nonBlankObjects = [];
        // const listObjects = [];
        
        // console.log('objects are', store.getObjects(subject, predicate))
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

        blankObjects = blankObjects.filter((object) => {
          return true;
          console.log(object)
          let listElems = [];

          while (!object.equals(N3.DataFactory.namedNode('http://www.w3.org/1999/02/22-rdf-syntax-ns#nil'))) {
            const val = store.getObjects(object, N3.DataFactory.namedNode('http://www.w3.org/1999/02/22-rdf-syntax-ns#first'))
            const objects = store.getObjects(object, N3.DataFactory.namedNode('http://www.w3.org/1999/02/22-rdf-syntax-ns#rest'))
            if (objects.length !== 1 || val.length !== 1 || store.getPredicates(object) !== 2) {
              console.log(objects, val, store.getPredicates(object))
              console.log(objects.length !== 1, val.length !== 1, store.getPredicates(object) !== 2)
              return true;
            }
            object = objects[0]
            
            // TODO: Handle blank nodes in list by doing fromPredicate here
            listElems.push(encodeObject(val[0]))
          }
          
          listObjects.push('( ' + listElems.join(', ') + ')');
          return false;          
        })

        const oStrings = [...nonBlankObjects.map(x => encodeObject(x)), ...listObjects]

        
        
        // const nonBlankObjects = store.getObjects(subject, predicate).filter(x !== x.termType === 'BlankNode');



        // console.log(nonBlankObjects)
        result += '\n' + '  '.repeat(indent) + encodePredicate(predicate) + ' ' + oStrings.join(', ')

        if (blankObjects.length > 0) {
          if (oStrings.length > 0) {
            result += ', '
          }

          // result += '['

          let i = 0;
          
          for (const blank of blankObjects) {
            result += '['
            fromPredicate(blank, indent + 1)
            result += '\n' + '  '.repeat(indent) + ']'

            if (++i < blankObjects.length) {
              result += ', '
            }
          }

          // result += '\n' + '  '.repeat(indent) + ']'
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
    // console.log('encoding object', subject)
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
    // console.log('in while', subject)

    result += encodeSubject(subject)
    fromPredicate(subject)
    result += '\n.\n\n'
  }

  return result;
  console.log(store.getSubjects())
}
