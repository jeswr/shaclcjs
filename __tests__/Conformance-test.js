const fs = require('fs');
const path = require('path');
const Parser = require('../lib').Parser;
const parse = require('../lib').parse;
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

describe('Testing each extended conformance file', () => {
  it.each(
    fs.readdirSync(path.join(__dirname, 'extended')).filter(str => str.endsWith('.shaclc'))
  )('testing %s correctly parses when extended is enabled', (file) => {

    const shaclc = fs.readFileSync(path.join(__dirname, 'extended', file)).toString();
    const ttl = fs.readFileSync(path.join(__dirname, 'extended', file.replace('.shaclc', '.ttl'))).toString();

    const res = (new Parser()).parse(shaclc, { extendedSyntax: true });

    expect(res).toBeRdfIsomorphic((new N3.Parser()).parse(ttl))
    expect(res.prefixes).toEqual({
      rdf: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
      owl: 'http://www.w3.org/2002/07/owl#',
      rdfs: 'http://www.w3.org/2000/01/rdf-schema#',
      sh: 'http://www.w3.org/ns/shacl#',
      xsd: 'http://www.w3.org/2001/XMLSchema#',
      ex: 'http://example.org/test#'
    })

    expect(() => (new Parser()).parse(shaclc)).toThrowError();
  });
});

describe('Testing relative IRIs', () => {
  it('should use the provided baseIRI to resolve relative IRIs', () => {
    expect(parse(`
    PREFIX ex: <http://example.org/>

    shape <#MyShape> -> </MyClass> {
    }
    `, { baseIRI: 'http://www.jeswr.org/' })).toBeRdfIsomorphic([
      N3.DataFactory.quad(
        N3.DataFactory.namedNode('http://www.jeswr.org/#MyShape'),
        N3.DataFactory.namedNode('http://www.w3.org/ns/shacl#targetClass'),
        N3.DataFactory.namedNode('http://www.jeswr.org/MyClass'),
      ),
      N3.DataFactory.quad(
        N3.DataFactory.namedNode('http://www.jeswr.org/#MyShape'),
        N3.DataFactory.namedNode('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
        N3.DataFactory.namedNode('http://www.w3.org/ns/shacl#NodeShape'),
      ),
      N3.DataFactory.quad(
        N3.DataFactory.namedNode('http://www.jeswr.org/'),
        N3.DataFactory.namedNode('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
        N3.DataFactory.namedNode('http://www.w3.org/2002/07/owl#Ontology'),
      )
    ])
  });

  it('should use the provided baseIRI to resolve relative IRIs', () => {
    expect(parse(`
    PREFIX ex: <http://example.org/>

    shape <#MyShape> -> </MyClass> {
    }
    `, { baseIRI: 'http://www.jeswr.org/humanShape' })).toBeRdfIsomorphic([
      N3.DataFactory.quad(
        N3.DataFactory.namedNode('http://www.jeswr.org/humanShape#MyShape'),
        N3.DataFactory.namedNode('http://www.w3.org/ns/shacl#targetClass'),
        N3.DataFactory.namedNode('http://www.jeswr.org/MyClass'),
      ),
      N3.DataFactory.quad(
        N3.DataFactory.namedNode('http://www.jeswr.org/humanShape#MyShape'),
        N3.DataFactory.namedNode('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
        N3.DataFactory.namedNode('http://www.w3.org/ns/shacl#NodeShape'),
      ),
      N3.DataFactory.quad(
        N3.DataFactory.namedNode('http://www.jeswr.org/humanShape'),
        N3.DataFactory.namedNode('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
        N3.DataFactory.namedNode('http://www.w3.org/2002/07/owl#Ontology'),
      )
    ])
  });
});
