%{
/*
    Grammar specification for a SHACL compact
    syntax parser.
    Several functions are from <https://github.com/RubenVerborgh/SPARQL.js/>
*/

  // Common namespaces and entities
  const RDF = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
      RDF_TYPE  = RDF + 'type',
      RDF_FIRST = RDF + 'first',
      RDF_REST  = RDF + 'rest',
      RDF_NIL   = RDF + 'nil',
      XSD = 'http://www.w3.org/2001/XMLSchema#',
      XSD_INTEGER  = XSD + 'integer',
      XSD_DECIMAL  = XSD + 'decimal',
      XSD_DOUBLE   = XSD + 'double',
      XSD_BOOLEAN  = XSD + 'boolean';
  var base = '', basePath = '', baseRoot = '', currentNodeShape, currentPropertyNode, nodeShapeStack = [];

    const SH = "http://www.w3.org/ns/shacl#";
    const OWL = "http://www.w3.org/2002/07/owl#";

    Parser.prefixes = {
      rdf: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
      rdfs: 'http://www.w3.org/2000/01/rdf-schema#',
      sh: SH,
      xsd: 'http://www.w3.org/2001/XMLSchema#'
    }

    // TODO: Make sure all SPARQL supported datatypes are here
    const datatypes = {
      [XSD_INTEGER]: true,
      [XSD_DECIMAL]: true,
      [XSD + 'float']: true,
      [XSD_DOUBLE]: true,
      [XSD + 'string']: true,
      [XSD_BOOLEAN]: true,
      [XSD + 'dateTime']: true,
      [XSD + 'nonPositiveInteger']: true,
      [XSD + 'negativeInteger']: true,
      [XSD + 'long']: true,
      [XSD + 'int']: true,
      [XSD + 'short']: true,
      [XSD + 'byte']: true,
      [XSD + 'nonNegativeInteger']: true,
      [XSD + 'unsignedLong']: true,
      [XSD + 'unsignedShort']: true,
      [XSD + 'unsignedByte']: true,
      [XSD + 'positiveInteger']: true,
      [RDF + 'langString']: true
    }

    function addList(elems) {
                        const list = head = blank();
                        let i = 0, l = elems.length;

                        if (l === 0) {
                          // TODO: see if this should be here 
                          Parser.factory.quad(
                            head, Parser.factory.namedNode(RDF_REST),  Parser.factory.namedNode(RDF_NIL)
                          )
                        }

                        elems.forEach(elem => {
                          Parser.onQuad(
                            Parser.factory.quad(
                              head, Parser.factory.namedNode(RDF_FIRST), elem
                            )
                          )

                          Parser.onQuad(
                            Parser.factory.quad(
                              head, Parser.factory.namedNode(RDF_REST),  head = ++i < l ? blank() : Parser.factory.namedNode(RDF_NIL)
                            )
                          )
                        })

                        return list;
                      }

  // Returns a lowercase version of the given string
  function lowercase(string) {
    return string.toLowerCase();
  }
  // Appends the item to the array and returns the array
  function appendTo(array, item) {
    return array.push(item), array;
  }
  // Appends the items to the array and returns the array
  function appendAllTo(array, items) {
    return array.push.apply(array, items), array;
  }
  // Extends a base object with properties of other objects
  function extend(base) {
    if (!base) base = {};
    for (var i = 1, l = arguments.length, arg; i < l && (arg = arguments[i] || {}); i++)
      for (var name in arg)
        base[name] = arg[name];
    return base;
  }
  // Creates an array that contains all items of the given arrays
  function unionAll() {
    var union = [];
    for (var i = 0, l = arguments.length; i < l; i++)
      union = union.concat.apply(union, arguments[i]);
    return union;
  }
  // Resolves an IRI against a base path
  function resolveIRI(iri) {
    // Strip off possible angular brackets
    if (iri[0] === '<')
      iri = iri.substring(1, iri.length - 1);
    // Return absolute IRIs unmodified
    if (/^[a-z]+:/.test(iri))
      return iri;
    if (!Parser.base)
      throw new Error('Cannot resolve relative IRI ' + iri + ' because no base IRI was set.');
    if (!base) {
      base = Parser.base;
      basePath = base.replace(/[^\/:]*$/, '');
      baseRoot = base.match(/^(?:[a-z]+:\/*)?[^\/]*/)[0];
    }
    switch (iri[0]) {
    // An empty relative IRI indicates the base IRI
    case undefined:
      return base;
    // Resolve relative fragment IRIs against the base IRI
    case '#':
      return base + iri;
    // Resolve relative query string IRIs by replacing the query string
    case '?':
      return base.replace(/(?:\?.*)?$/, iri);
    // Resolve root relative IRIs at the root of the base IRI
    case '/':
      return baseRoot + iri;
    // Resolve all other IRIs at the base IRI's path
    default:
      return basePath + iri;
    }
  }
  // If the item is a variable, ensures it starts with a question mark
  function toVar(variable) {
    if (variable) {
      var first = variable[0];
      if (first === '?' || first === '$') return Parser.factory.variable(variable.substr(1));
    }
    return variable;
  }
  // Creates an operation with the given name and arguments
  function operation(operatorName, args) {
    return { type: 'operation', operator: operatorName, args: args || [] };
  }
  // Creates an expression with the given type and attributes
  function expression(expr, attr) {
    var expression = { expression: expr === '*'? new Wildcard() : expr };
    if (attr)
      for (var a in attr)
        expression[a] = attr[a];
    return expression;
  }
  // Creates a path with the given type and items
  function path(type, items) {
    return { type: 'path', pathType: type, items: items };
  }
  // Transforms a list of operations types and arguments into a tree of operations
  function createOperationTree(initialExpression, operationList) {
    for (var i = 0, l = operationList.length, item; i < l && (item = operationList[i]); i++)
      initialExpression = operation(item[0], [initialExpression, item[1]]);
    return initialExpression;
  }
  // Group datasets by default and named
  function groupDatasets(fromClauses, groupName) {
    var defaults = [], named = [], l = fromClauses.length, fromClause, group = {};
    if (!l)
      return null;
    for (var i = 0; i < l && (fromClause = fromClauses[i]); i++)
      (fromClause.named ? named : defaults).push(fromClause.iri);
    group[groupName || 'from'] = { default: defaults, named: named };
    return group;
  }
  // Converts the string to a number
  function toInt(string) {
    return parseInt(string, 10);
  }
  // Transforms a possibly single group into its patterns
  function degroupSingle(group) {
    return group.type === 'group' && group.patterns.length === 1 ? group.patterns[0] : group;
  }
  // Creates a literal with the given value and type
  function createTypedLiteral(value, type) {
    if (type && type.termType !== 'NamedNode'){
      type = Parser.factory.namedNode(type);
    }
    return Parser.factory.literal(value, type);
  }
  // Creates a literal with the given value and language
  function createLangLiteral(value, lang) {
    return Parser.factory.literal(value, lang);
  }
  // Creates a triple with the given subject, predicate, and object
  function triple(subject, predicate, object) {
    var triple = {};
    if (subject   != null) triple.subject   = subject;
    if (predicate != null) triple.predicate = predicate;
    if (object    != null) triple.object    = object;
    return triple;
  }
  // Creates a new blank node
  function blank(name) {
    if (typeof name === 'string') {  // Only use name if a name is given
      if (name.startsWith('e_')) return Parser.factory.blankNode(name);
      return Parser.factory.blankNode('e_' + name);
    }
    return Parser.factory.blankNode('g_' + blankId++);
  };
  var blankId = 0;
  Parser._resetBlanks = function () { blankId = 0; }
  // Regular expression and replacement strings to escape strings
  var escapeSequence = /\\u([a-fA-F0-9]{4})|\\U([a-fA-F0-9]{8})|\\(.)/g,
      escapeReplacements = { '\\': '\\', "'": "'", '"': '"',
                             't': '\t', 'b': '\b', 'n': '\n', 'r': '\r', 'f': '\f' },
      fromCharCode = String.fromCharCode;
  // Translates escape codes in the string into their textual equivalent
  function unescapeString(string, trimLength) {
    string = string.substring(trimLength, string.length - trimLength);
    try {
      string = string.replace(escapeSequence, function (sequence, unicode4, unicode8, escapedChar) {
        var charCode;
        if (unicode4) {
          charCode = parseInt(unicode4, 16);
          if (isNaN(charCode)) throw new Error(); // can never happen (regex), but helps performance
          return fromCharCode(charCode);
        }
        else if (unicode8) {
          charCode = parseInt(unicode8, 16);
          if (isNaN(charCode)) throw new Error(); // can never happen (regex), but helps performance
          if (charCode < 0xFFFF) return fromCharCode(charCode);
          return fromCharCode(0xD800 + ((charCode -= 0x10000) >> 10), 0xDC00 + (charCode & 0x3FF));
        }
        else {
          var replacement = escapeReplacements[escapedChar];
          if (!replacement) throw new Error();
          return replacement;
        }
      });
    }
    catch (error) { return ''; }
    return string;
  }
  // Creates a list, collecting its (possibly blank) items and triples associated with those items
  function createList(objects) {
    var list = blank(), head = list, listItems = [], listTriples, triples = [];
    objects.forEach(function (o) { listItems.push(o.entity); appendAllTo(triples, o.triples); });
    // Build an RDF list out of the items
    for (var i = 0, j = 0, l = listItems.length, listTriples = Array(l * 2); i < l;)
      listTriples[j++] = triple(head, Parser.factory.namedNode(RDF_FIRST), listItems[i]),
      listTriples[j++] = triple(head, Parser.factory.namedNode(RDF_REST),  head = ++i < l ? blank() : Parser.factory.namedNode(RDF_NIL));
    // Return the list's identifier, its triples, and the triples associated with its items
    return { entity: list, triples: appendAllTo(listTriples, triples) };
  }
  // Creates a blank node identifier, collecting triples with that blank node as subject
  function createAnonymousObject(propertyList) {
    var entity = blank();
    return {
      entity: entity,
      triples: propertyList.map(function (t) { return extend(triple(entity), t); })
    };
  }
  // Collects all (possibly blank) objects, and triples that have them as subject
  function objectListToTriples(predicate, objectList, otherTriples) {
    var objects = [], triples = [];
    objectList.forEach(function (l) {
      objects.push(triple(null, predicate, l.entity));
      appendAllTo(triples, l.triples);
    });
    return unionAll(objects, otherTriples || [], triples);
  }
  // Simplifies groups by merging adjacent BGPs
  function mergeAdjacentBGPs(groups) {
    var merged = [], currentBgp;
    for (var i = 0, group; group = groups[i]; i++) {
      switch (group.type) {
        // Add a BGP's triples to the current BGP
        case 'bgp':
          if (group.triples.length) {
            if (!currentBgp)
              appendTo(merged, currentBgp = group);
            else
              appendAllTo(currentBgp.triples, group.triples);
          }
          break;
        // All other groups break up a BGP
        default:
          // Only add the group if its pattern is non-empty
          if (!group.patterns || group.patterns.length > 0) {
            appendTo(merged, group);
            currentBgp = null;
          }
      }
    }
    return merged;
  }
  // Return the id of an expression
  function getExpressionId(expression) {
    return expression.variable ? expression.variable.value : expression.value || expression.expression.value;
  }
  // Get all "aggregate"'s from an expression
  function getAggregatesOfExpression(expression) {
    if (!expression) {
      return [];
    }
    if (expression.type === 'aggregate') {
      return [expression];
    } else if (expression.type === "operation") {
      const aggregates = [];
      for (const arg of expression.args) {
        aggregates.push(...getAggregatesOfExpression(arg));
      }
      return aggregates;
    }
    return [];
  }
  // Get all variables used in an expression
  function getVariablesFromExpression(expression) {
    const variables = new Set();
    const visitExpression = function (expr) {
      if (!expr) { return; }
      if (expr.termType === "Variable") {
        variables.add(expr);
      } else if (expr.type === "operation") {
        expr.args.forEach(visitExpression);
      }
    };
    visitExpression(expression);
    return variables;
  }
  // Helper function to flatten arrays
  function flatten(input, depth = 1, stack = []) {
    for (const item of input) {
        if (depth > 0 && item instanceof Array) {
          flatten(item, depth - 1, stack);
        } else {
          stack.push(item);
        }
    }
    return stack;
  }
  function isVariable(term) {
    return term.termType === 'Variable';
  }
  function getBoundVarsFromGroupGraphPattern(pattern) {
    if (pattern.triples) {
      const boundVars = [];
      for (const triple of pattern.triples) {
        if (isVariable(triple.subject)) boundVars.push(triple.subject.value);
        if (isVariable(triple.predicate)) boundVars.push(triple.predicate.value);
        if (isVariable(triple.object)) boundVars.push(triple.object.value);
      }
      return boundVars;
    } else if (pattern.patterns) {
      const boundVars = [];
      for (const pat of pattern.patterns) {
        boundVars.push(...getBoundVarsFromGroupGraphPattern(pat));
      }
      return boundVars;
    }
    return [];
  }
  // Helper function to find duplicates in array
  function getDuplicatesInArray(array) {
    const sortedArray = array.slice().sort();
    const duplicates = [];
    for (let i = 0; i < sortedArray.length - 1; i++) {
      if (sortedArray[i + 1] == sortedArray[i]) {
        duplicates.push(sortedArray[i]);
      }
    }
    return duplicates;
  }
  function ensureSparqlStar(value) {
    if (!Parser.sparqlStar) {
      throw new Error('SPARQL* support is not enabled');
    }
    return value;
  }
%}

%lex

PASS                    [ \t\r\n]+ -> skip
COMMENT                 '#' ~[\r\n]* -> skip

IRIREF                  '<' (~[^=<>\"\{\}\|\^`\\\u0000-\u0020] | {UCHAR})* '>'
PNAME_NS                {PN_PREFIX}? ':'
PNAME_LN                {PNAME_NS} {PN_LOCAL}
ATPNAME_NS              '@' {PN_PREFIX}? ':'
ATPNAME_LN              '@' {PNAME_NS} {PN_LOCAL}
LANGTAG                 '@' [a-zA-Z]+ ('-' [a-zA-Z0-9]+)*
INTEGER                 [+-]?[0-9]+
DECIMAL                 [+-]?[0-9]*'.'[0-9]+
DOUBLE                  [+-]?([0-9]+ '.' [0-9]* {EXPONENT} | '.'? [0-9]+ {EXPONENT})
EXPONENT                [eE] [+-]? [0-9]+
STRING_LITERAL1         "'"(?:(?:[^\u0027\u005C\u000A\u000D])|{ECHAR})*"'"
STRING_LITERAL2         "\""(?:(?:[^\u0022\u005C\u000A\u000D])|{ECHAR})*'"'
STRING_LITERAL_LONG1    "'''"(?:(?:"'"|"''")?(?:[^'\\]|{ECHAR}))*"'''"
STRING_LITERAL_LONG2    "\"\"\""(?:(?:"\""|'""')?(?:[^\"\\]|{ECHAR}))*'"""'
UCHAR                   '\\u' {HEX} {HEX} {HEX} {HEX} | '\\U' {HEX} {HEX} {HEX} {HEX} {HEX} {HEX} {HEX} {HEX}
ECHAR                   '\\' [tbnrf\\\"\']
WS                      [\u0020\u0009\u000D\u000A]
PN_CHARS_BASE           [A-Z] | [a-z] | [\u00C0-\u00D6] | [\u00D8-\u00F6] | [\u00F8-\u02FF] | [\u0370-\u037D] | [\u037F-\u1FFF] | [\u200C-\u200D] | [\u2070-\u218F] | [\u2C00-\u2FEF] | [\u3001-\uD7FF] | [\uF900-\uFDCF] | [\uFDF0-\uFFFD]
PN_CHARS_U              {PN_CHARS_BASE} | '_'
PN_CHARS                {PN_CHARS_U} | '-' | [0-9] | [\u00B7] | [\u0300-\u036F] | [\u203F-\u2040]
PN_PREFIX               {PN_CHARS_BASE} (({PN_CHARS} | '.')* {PN_CHARS})?
PN_LOCAL                ({PN_CHARS_U} | ':' | [0-9] | {PLX}) (({PN_CHARS} | '.' | ':' | {PLX})* ({PN_CHARS} | ':' | {PLX}))?
PLX                     {PERCENT} | {PN_LOCAL_ESC}
PERCENT                 '%' {HEX} {HEX}
HEX                     [0-9] | [A-F] | [a-f]
PN_LOCAL_ESC            '\\' ('_' | '~' | '.' | '-' | '!' | '$' | '&' | '\'' | '(' | ')' | '*' | '+' | ',' | ';' | '=' | '/' | '?' | '#' | '@' | '%')

NODEKIND                'BlankNode' | 'IRI' | 'Literal' | 'BlankNodeOrIRI' | 'BlankNodeOrLiteral' | 'IRIOrLiteral'
TARGET                  'targetNode' | 'targetObjectsOf' | 'targetSubjectsOf' 
PARAM                   'deactivated' | 'severity' | 'message' | 'class' | 'datatype' | 'nodeKind' | 'minExclusive' | 'minInclusive' | 'maxExclusive' | 'maxInclusive' | 'minLength' | 'maxLength' | 'pattern' | 'flags' | 'languageIn' | 'uniqueLang' | 'equals' | 'disjoint' | 'lessThan' | 'lessThanOrEquals' | 'qualifiedValueShape' | 'qualifiedMinCount' | 'qualifiedMaxCount' | 'qualifiedValueShapesDisjoint' | 'closed' | 'ignoredProperties' | 'hasValue' | 'in'

%options flex case-insensitive

%%

\s+|"#"[^\n\r]*         /* ignore */

"BASE"                  return 'KW_BASE'
"IMPORTS"               return 'KW_IMPORTS'
"PREFIX"                return 'KW_PREFIX'

"shapeClass"            return 'KW_SHAPE_CLASS'
"shape"                 return 'KW_SHAPE'

'true'                  return 'KW_TRUE'
'false'                 return 'KW_FALSE'

{NODEKIND}              return 'NODEKIND'
{TARGET}                return 'TARGET'
{PARAM}                 return 'PARAM'

{PASS}                  return 'PASS'
{COMMENT}               return 'COMMENT'

{IRIREF}                return 'IRIREF'
{PNAME_NS}              return 'PNAME_NS'
{PNAME_LN}              return 'PNAME_LN'
{ATPNAME_NS}            return 'ATPNAME_NS'
{ATPNAME_LN}            return 'ATPNAME_LN'
{LANGTAG}               return 'LANGTAG'
{INTEGER}               return 'INTEGER'
{DECIMAL}               return 'DECIMAL'
{DOUBLE}                return 'DOUBLE'
{EXPONENT}              return 'EXPONENT'
{STRING_LITERAL1}       return 'STRING_LITERAL1'
{STRING_LITERAL2}       return 'STRING_LITERAL2'
{STRING_LITERAL_LONG1}  return 'STRING_LITERAL_LONG1'
{STRING_LITERAL_LONG2}  return 'STRING_LITERAL_LONG2'

"->"                    return '->'
".."                    return '..'

"}"                     return '}'
"{"                     return '{'
"("                     return '('
")"                     return ')'
"["                     return '['
"]"                     return ']'

"?"                     return '?'
"*"                     return '*'
"+"                     return '+'

"|"                     return '|'
"^^"                    return '^^'
"."                     return '.'
"!"                     return '!'

"/"                     return '/'
"="                     return '='

<<EOF>>                 return 'EOF'

/lex

%ebnf

%start shaclDoc

%%

shaclDoc            : directive* (nodeShape|shapeClass)* EOF;

directive           : baseDecl | importsDecl | prefixDecl ;
baseDecl            : KW_BASE  IRIREF 
                    {
                      console.log('base decl', $1, $2)
                      Parser.base = Parser.factory.namedNode($2.slice(1, -1));
                      Parser.onQuad(
                        Parser.factory.quad(
                          Parser.base,
                          Parser.factory.namedNode(RDF_TYPE),
                          Parser.factory.namedNode(OWL + 'Ontology')
                        )
                      )
                    }
                    ;
importsDecl         : KW_IMPORTS IRIREF
                    {
                      console.log('imports decl', $1, $2)
                      Parser.onQuad(
                        Parser.factory.quad(
                          Parser.base,
                          Parser.factory.namedNode(OWL + 'imports'),
                          Parser.factory.namedNode($2.slice(1, -1))
                        )
                      )
                    }
                    ;
prefixDecl          : KW_PREFIX PNAME_NS IRIREF 
                    {
                        console.log('prexi decl', $1, $2)
                        // if (!Parser.prefixes) Parser.prefixes = {
                        //   rdf: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
                        //   rdfs: 'http://www.w3.org/2000/01/rdf-schema#',
                        //   sh: 'http://www.w3.org/ns/shacl#',
                        //   xsd: 'http://www.w3.org/2001/XMLSchema#'
                        // };
                        $2 = $2.substr(0, $2.length - 1);
                        $3 = resolveIRI($3);
                        Parser.prefixes[$2] = $3;
                    }
                    ;

nodeShapeIri        : iri
                    {
                      console.log('nodeshape irir', $1)
                      // console.log('iri is', $1)
                      currentNodeShape = $1
                    }
                    ;

nodeShape           : KW_SHAPE nodeShapeIri targetClass? nodeShapeBody
                    {
                      Parser.onQuad(
                        Parser.factory.quad(
                          currentNodeShape,
                          Parser.factory.namedNode(RDF_TYPE),
                          Parser.factory.namedNode(SH + 'NodeShape')
                        )
                      )

                      if ($3) {
                        for (const node of $3) {
                          Parser.onQuad(
                            Parser.factory.quad(
                            currentNodeShape,
                            Parser.factory.namedNode(SH + 'targetClass'),
                            node
                          )
                        )  
                        }
                      }
                      
                      // console.log($2, $3, $4)
                    }
                    ;
shapeClass          : KW_SHAPE_CLASS iri nodeShapeBody
                    {
                      console.log('shape class', $2)
                    }
                    ;

startNodeShape      : '{'
                    {
                      console.log('start node shape')
                      if (nodeShapeStack.length === 0) {
                        nodeShapeStack.push(currentNodeShape);
                      } else {
                        // nodeShapeStack.push(currentNodeShape = blank());
                        Parser.onQuad(
                          Parser.factory.quad(
                            // In the grammar a path signals the start of a new property declaration
                            currentPropertyNode,
                            Parser.factory.namedNode(SH + 'node'),
                            currentNodeShape = blank(),
                          )
                        )
                        nodeShapeStack.push(currentNodeShape);
                      }
                      
                      
                      // TODO: Push a new nodeShape blankNode here when we are on a nested shape
                      // and mint a sh:node triple
                      // console.log('>'.repeat(10))
                    }
                    ;

endNodeShape        : '}'
                    {
                      console.log('end node shape')
                      if (nodeShapeStack.length > 0) {
                        currentNodeShape = nodeShapeStack.pop();
                      }
                      
                      
                      // TODO: Pop the new nodeShape blankNode here
                      // console.log('<'.repeat(10))
                    }
                    ;

nodeShapeBody       : startNodeShape constraint* endNodeShape
                    {
                      console.log('node shape body')
                    }
                    ;
targetClass         : '->' iri+
                    {
                      console.log('target class')
                      $$ = $2
                    };

constraint          : ( nodeOr+ | propertyShape ) '.' 
                    {
                      console.log('contraint')
                    }
                    ;

orNotComponent      : '|' nodeNot -> $2
                    ;

nodeOr              : nodeNot
                    {
                      console.log('ndoe not')
                    }
                    | nodeNot orNotComponent+
                    {
                      Parser.onQuad(
                        Parser.factory.quad(
                          $$ = blank(),
                          Parser.factory.namedNode(SH + $1),
                          addList([$1, ...$2])
                        )
                      )
                    }
                    ;
nodeNot             : nodeValue
                    | negation nodeValue
                    {
                      Parser.onQuad(
                        Parser.factory.quad(
                          $$ = blank(),
                          Parser.factory.namedNode(SH + 'not'),
                          $1
                        )
                      )
                    }
                    ;
nodeValue           : nodeParam '=' iriOrLiteralOrArray
                    {
                      console.log('node value')
                      Parser.onQuad(
                        Parser.factory.quad(
                          currentNodeShape,
                          Parser.factory.namedNode(SH + $1),
                          $3
                        )
                      )
                      
                      
                      
                      
                      
                      // Parser.factory.namedNode(SH + $1)
                      
                      // console.log('node param', $1)
                    }
                    ;

propertyShape       : path ( propertyCount | propertyOr )*
                    {
                      console.log('property shape', $1, $2)
                    }
                    ;

propertyOrComponent : '|' propertyNot -> $2
                    ;

propertyOr          : propertyNot
                    {
                      console.log('property not [1]', $1)
                      $$ = $1
                    }
                    | propertyNot propertyOrComponent+ 
                    {
                      Parser.onQuad(
                        Parser.factory.quad(
                          $$ = blank(),
                          Parser.factory.namedNode(SH + 'or'),
                          addList([$1, ...$2])
                        )
                      )
                    }
                    ;


propertyNot         : propertyAtom
                    {
                      console.log('rpoeprty not')
                      $$ = $1
                    }
                    | negation propertyAtom
                    {
                      Parser.onQuad(
                        Parser.factory.quad(
                          $$ = blank(),
                          Parser.factory.namedNode(SH + 'not'),
                          $2
                        )
                      )
                    }
                    ;



propertyAtom        : propertyType
                    {
                      console.log('proeprty type', $1)
                      $$ = $1
                    }
                    | nodeKind
                    {
                      console.log('node kind')
                    }
                    | shapeRef
                    {
                      console.log('shape ref')
                    }
                    | propertyValue
                    {
                      console.log('proeprty value')
                    }
                    | nodeShapeBody 
                    {
                      console.log('node shape body')
                    }
                    ;
propertyCount       : '[' propertyMinCount '..' propertyMaxCount ']' ;
propertyMinCount    : INTEGER
                    {
                      if ($1 > 0)
                        Parser.onQuad(
                          Parser.factory.quad(
                            currentPropertyNode,
                            Parser.factory.namedNode(SH + 'minCount'),
                            createTypedLiteral($1, XSD_INTEGER)
                          )
                        )
                    }
                    ;
propertyMaxCount    : INTEGER
                    {
                      Parser.onQuad(
                        Parser.factory.quad(
                          currentPropertyNode,
                          Parser.factory.namedNode(SH + 'maxCount'),
                          createTypedLiteral($1, XSD_INTEGER)
                        )
                      )
                    }
                    | '*'
                    ;
propertyType        : iri
                    {
                      console.log('property type')
                      // datatypes[$1.value]
                      
                      // TODO: See if the problem of datatype is occuring here
                      // NOTE: This *is* the clase of the shapeRef class problem
                      Parser.onQuad(
                        Parser.factory.quad(
                          currentPropertyNode,
                          Parser.factory.namedNode(SH + (datatypes[$1.value] ? 'datatype' : 'class')),
                          $1
                        )
                      )
                      // console.log('property', $1)
                    }
                    ;
nodeKind            : NODEKIND
                    {
                      Parser.onQuad(
                        Parser.factory.quad(
                          currentPropertyNode,
                          Parser.factory.namedNode(SH + 'nodeKind'),
                          Parser.factory.namedNode(SH + $1),
                        )
                      )
                    }
                    ;
shapeRef            : ATPNAME_LN
                    {
                      console.log('shaperef1', $1)
                      
                      const ind = $1.indexOf(':');

                      Parser.onQuad(
                        Parser.factory.quad(
                          currentPropertyNode,
                          Parser.factory.namedNode(SH + 'node'),
                          // TODO: See if we should be doing resolve iri here
                          Parser.factory.namedNode(Parser.prefixes[$1.slice(1, ind)] + $1.slice(ind + 1)),
                        )
                      )

                      // TODO: See if we should be doing resolve iri here
                      // console.log('1', Parser.prefixes[$1.slice(1, ind)] + $1.slice(ind + 1))
                    }
                    | ATPNAME_NS
                    {
                      // console.log('shaperef2', $2)
                      Parser.onQuad(
                        Parser.factory.quad(
                          currentPropertyNode,
                          Parser.factory.namedNode(SH + 'node'),
                          // TODO: Add test for this
                          Parser.factory.namedNode(Parser.prefixes[$1.slice(1, $1.length - 1)]),
                        )
                      )
                    }
                    | '@' IRIREF
                    {
                      console.log('shaperef3', $3)
                      Parser.onQuad(
                        Parser.factory.quad(
                          currentPropertyNode,
                          Parser.factory.namedNode(SH + 'node'),
                          // TODO: Add test for this
                          Parser.factory.namedNode(resolveIRI($2)),
                        )
                      )
                    } //-> Parser.factory.namedNode(resolveIRI($2))
                    ;

propertyValue       : propertyParam '=' iriOrLiteralOrArray
                    {
                      console.log('properrt vallue')
                      Parser.onQuad(
                        Parser.factory.quad(
                          currentPropertyNode,
                          Parser.factory.namedNode(SH + $1),
                          $3
                        )
                      )
                    }
                    ;
negation            : '!' ;

path                : pathAlternative
                    {
                      
                      // currentPropertyNode = blank();
                      Parser.onQuad(
                        Parser.factory.quad(
                          // In the grammar a path signals the start of a new property declaration
                          currentNodeShape,
                          Parser.factory.namedNode(SH + 'property'),
                          currentPropertyNode = blank(),
                        )
                      )
                      
                      Parser.onQuad(
                        Parser.factory.quad(
                          // In the grammar a path signals the start of a new property declaration
                          currentPropertyNode,
                          Parser.factory.namedNode(SH + 'path'),
                          $1
                        )
                      )

                      // console.log(currentPropertyNode)
                    }
                    ;

additionalAlternative : '|' pathSequence -> $2
                      ;

pathAlternative     : pathSequence
                    | pathSequence additionalAlternative+
                    {
                      Parser.onQuad(
                        Parser.factory.quad(
                          $$ = blank(),
                          Parser.factory.namedNode(SH + 'alternativePath'),
                          addList([$1, ...$2])
                        )
                      )
                    }
                    ;

additionalSequence : '/' pathEltOrInverse -> $2
                    ;

pathSequence        : pathEltOrInverse
                    | pathEltOrInverse additionalSequence+
                    {
                      
                      
                      
                      $$ = addList([$1, ...$2])
                      
                      
                      // 
                      // console.log('seq')
                    }
                    // {
                    //   console.log('seq', $1, $2)
                    // }
                    ;
pathElt             : pathPrimary pathMod? 
                    {
                      if ($2) {
                        Parser.onQuad(
                        Parser.factory.quad(
                          $$ = blank(),
                          $2,
                          $1
                        )
                      )
                      } else {
                        $$ = $1
                      }
                    }
                    ;
pathEltOrInverse    : pathElt
                    | pathInverse pathElt 
                    {
                      Parser.onQuad(
                        Parser.factory.quad(
                          $$ = blank(),
                          Parser.factory.namedNode(SH + 'inversePath'),
                          $2
                        )
                      )
                    }
                    ;
pathInverse         : '^' ;
pathMod             : '?' -> Parser.factory.namedNode(SH + 'zeroOrOnePath')
                    | '*' -> Parser.factory.namedNode(SH + 'zeroOrMorePath')
                    | '+' -> Parser.factory.namedNode(SH + 'oneOrMorePath')
                    ;

pathPrimary         : iri
                    {
                      console.log('path primary', $1)
                    }
                    | '(' path ')'
                    {
                      console.log('path', $2)
                    }
                    // {
                    //   // console.log('path', $2)
                      
                    //   // TODO: Refactor this
                    //   // var list = head = blank();
                    //   // let i = 0, l = $2?.length;

                    //   // $2?.forEach(elem => {
                    //   //   Parser.onQuad(
                    //   //     Parser.factory.quad(
                    //   //       head, Parser.factory.namedNode(RDF_FIRST), elem
                    //   //     )
                    //   //   )

                    //   //   Parser.onQuad(
                    //   //     Parser.factory.quad(
                    //   //       head, Parser.factory.namedNode(RDF_REST),  head = ++i < l ? blank() : Parser.factory.namedNode(RDF_NIL)
                    //   //     )
                    //   //   )
                    //   // })

                    //   // $$ = list
                    // }
                    ;

iriOrLiteralOrArray : iriOrLiteral | array ;
iriOrLiteral        : iri | literal
                    { 
                      console.log('iri or literal', $1)
                      $$ = $1
                     }
                    ;

iri
    : IRIREF
    {
      console.log('iriref', $1)
      $$ = Parser.factory.namedNode(resolveIRI($1))
    }
    | PNAME_LN
    {
      console.log('pnameln', $1)
      var namePos = $1.indexOf(':'),
          prefix = $1.substr(0, namePos),
          expansion = Parser.prefixes[prefix];
      if (!expansion) throw new Error('Unknown prefix: ' + prefix);
      var uriString = resolveIRI(expansion + $1.substr(namePos + 1));
      // console.log(Parser)
      $$ = Parser.factory.namedNode(uriString);
    }
    | PNAME_NS
    {
      $1 = $1.substr(0, $1.length - 1);
      if (!($1 in Parser.prefixes)) throw new Error('Unknown prefix: ' + $1);
      var uriString = resolveIRI(Parser.prefixes[$1]);
      $$ = Parser.factory.namedNode(uriString);
    }
    ;

literal             : rdfLiteral
                    | numericLiteral
                    | booleanLiteral -> createTypedLiteral($1.toLowerCase(), XSD_BOOLEAN)
                    ;

booleanLiteral      : KW_TRUE | KW_FALSE ;

numericLiteral      : INTEGER -> createTypedLiteral($1, XSD_INTEGER)
                    | DECIMAL -> createTypedLiteral($1, XSD_DECIMAL)
                    | DOUBLE -> createTypedLiteral($1.toLowerCase(), XSD_DOUBLE)
                    ;

rdfLiteral       
    : string -> createTypedLiteral($1)
    // TODO: check this
    | string LANGTAG  -> createLangLiteral($1, lowercase($2.substr(1)))
    | string '^^' iri -> createTypedLiteral($1, $3)
    ;

datatype            : iri
                    {
                      console.log('datatype', $1)
                      $$ = $1
                    }
                    ;

string
    : STRING_LITERAL1 -> unescapeString($1, 1)
    | STRING_LITERAL2 -> unescapeString($1, 1)
    | STRING_LITERAL_LONG1 -> unescapeString($1, 3)
    | STRING_LITERAL_LONG2 -> unescapeString($1, 3)
    ;

array               : '[' iriOrLiteral* ']' -> addList($2)
                    ;

nodeParam           : TARGET | PARAM 
                    {
                      // $$ = $1
                      // console.log('node param', $1)
                    }
                    ;
propertyParam       : PARAM
                    {
                      // console.log('property param', $1, blank())
                    }
                    ;