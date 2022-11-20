const ShaclcParser = require('./ShaclcParser').Parser;
const N3 = require('n3');

// import { Parser as ShaclcParser } from './ShaclcParser';
// import { DataFactory } from 'n3';

class Parser {
  constructor() {
    this._parser = new ShaclcParser({ factory: N3.DataFactory });
    this._parser.Parser.factory = N3.DataFactory;
  }

  parse(str) {
      const arr = []
      this._parser.Parser.onQuad = (quad) => { arr.push(quad) };
      this._parser.parse(str);
      return arr;
  }
}

module.exports.Parser = Parser;
