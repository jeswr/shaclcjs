const fs = require('fs');
const path = require('path');
const Parser = require('../lib').Parser;
const N3 = require('n3');
require('jest-rdf');

describe('Testing each conformance file', () => {
  it.each(
    fs.readdirSync(path.join(__dirname, 'valid')).filter(str => str.endsWith('.shaclc'))
  )('testing %s correctly parses', (file) => {
    
    const shaclc = fs.readFileSync(path.join(__dirname, 'valid', file)).toString();
    const ttl = fs.readFileSync(path.join(__dirname, 'valid', file.replace('.shaclc', '.ttl'))).toString();

    expect(
      (new Parser()).parse(shaclc)
    ).toBeRdfIsomorphic(
      (new N3.Parser()).parse(ttl)
    )
  });
});
