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

  if (process.argv[2] && !file.includes(process.argv[2])) {
    continue;
  }

  console.log('run', file)

  const shaclc = fs.readFileSync(path.join(__dirname, 'valid', file)).toString();
  const ttl = fs.readFileSync(path.join(__dirname, 'valid', file.replace('.shaclc', '.ttl'))).toString();
  
  // const shaclcSet = new N3.Store((new Parser()).parse(shaclc));
  // const turtleSet = new N3.Store((new N3.Parser()).parse(ttl));

  // isomorphic(shaclcSet, turtleSet)

  // console.log
  console.log(
    (new Parser()).parse(shaclc)
  )

  if (!isomorphic((new Parser()).parse(shaclc), (new N3.Parser()).parse(ttl))) {
    console.log(file)
    
    const shaclcSet = new N3.Store((new Parser()).parse(shaclc));
    const turtleSet = new N3.Store((new N3.Parser()).parse(ttl).map(quad => {
      return N3.DataFactory.quad(
        quad.subject.termType === 'BlankNode' ? N3.DataFactory.blankNode(quad.subject.value.replace('n3-', 'g_')) : quad.subject,
        quad.predicate.termType === 'BlankNode' ? N3.DataFactory.blankNode(quad.predicate.value.replace('n3-', 'g_')) : quad.predicate,
        quad.object.termType === 'BlankNode' ? N3.DataFactory.blankNode(quad.object.value.replace('n3-', 'g_')) : quad.object,
      )
    }));
    const writer = new N3.Writer();

    for (const quad of shaclcSet) {
      

      const str = writer.quadsToString([
        quad
    ]);
      if (!turtleSet.has(quad)) {
        console.log(str)
      }
    }

    // const writer = new N3.Writer();

    const str = writer.quadsToString([
      ...shaclcSet
    ]);
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
    console.log(shaclc)
  }

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
  


// console.log(elems)
