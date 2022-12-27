const ShaclcParser = require('./ShaclcParser').Parser;
const N3 = require('n3');

class Parser {
  constructor() {
  }

  parse(str, allowEscapeSyntax) {
    this._parser = new ShaclcParser();
    this._parser.Parser.factory = N3.DataFactory;
    this._parser.Parser.base = N3.DataFactory.namedNode('urn:x-base:default')
    this._parser.Parser.prefixes = {
      rdf: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
      rdfs: 'http://www.w3.org/2000/01/rdf-schema#',
      sh: 'http://www.w3.org/ns/shacl#',
      xsd: 'http://www.w3.org/2001/XMLSchema#'
    }

    const arr = []
    this._parser.Parser.onQuad = (quad) => { arr.push(quad) };
    try {
      this._parser.parse(str);
    } catch (e) {
      if (e.hash.text === '//' && e.hash.loc.first_column === 0 && e.hash.loc.last_column === 1 && allowEscapeSyntax === true) {
        const remainingLines = str.split('\n')
        const text = remainingLines.slice(e.hash.line + 1).join('\n')

        return {
          quads: arr,
          mediaType: remainingLines[e.hash.line].slice(2, -2).trim(),
          text,
          prefixes: this._parser.Parser.prefixes
        }
      }
      throw e;
    }
    return arr;
  }
}

module.exports.Parser = Parser;

module.exports.parse = function parse(str) {
  const parser = new Parser();
  return parser.parse(str)
}

module.exports.extendedParse = function extendedParse(str) {
  const parser = new Parser();
  const res = parser.parse(str, true);

  if (Array.isArray(res))
    return res;

  const added = (new N3.Parser({ mediaType: res.mediaType })).parse(res.text);

  console.log(`performing extended parse on\n[${res.text}]`, 'adding', added)

  return [
    ...res.quads,
    ...added
  ]
}
