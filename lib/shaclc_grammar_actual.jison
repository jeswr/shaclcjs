%{
/*
    Grammar specification for a SHACL compact
    syntax parser
*/
%}

%lex

PASS                    [ \t\r\n]+ -> skip
COMMENT                 '#' ~[\r\n]* -> skip

IRIREF                  '<' (~[\u0000-\u0020=<>\"{}|^`\\] | {UCHAR})* '>'
PNAME_NS                {PN_PREFIX}? ':'
PNAME_LN                {PNAME_NS} {PN_LOCAL}
ATPNAME_NS              '@' {PN_PREFIX}? ':'
ATPNAME_LN              '@' {PNAME_NS} {PN_LOCAL}
LANGTAG                 '@' [a-zA-Z]+ ('-' [a-zA-Z0-9]+)*
INTEGER                 [+-]? [0-9]+
DECIMAL                 [+-]? [0-9]* '.' [0-9]+
DOUBLE                  [+-]? ([0-9]+ '.' [0-9]* {EXPONENT} | '.'? [0-9]+ {EXPONENT})
EXPONENT                [eE] [+-]? [0-9]+
STRING_LITERAL1         '\'' (~[\u0027\u005C\u000A\u000D] | {ECHAR} | {UCHAR})* '\''
STRING_LITERAL2         '"' (~[\u0022\u005C\u000A\u000D] | {ECHAR} | {UCHAR})* '"'
STRING_LITERAL_LONG1    '\'\'\'' (('\'' | '\'\'')? (~[\'\\] | {ECHAR} | {UCHAR}))* '\'\'\''
STRING_LITERAL_LONG2    '"""' (('"' | '""')? (~[\"\\] | {ECHAR} | {UCHAR}))* '"""'
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

"->"                    return '->'
"}"                     return '}'
"{"                     return '{'
"|"                     return '|'
"*"                     return '*'
"="                     return '='
"?"                     return '?'
"^^"                    return '^^'
"."                     return '.'
"["                     return '['
"]"                     return ']'
"/"                     return '/'
"+"                     return '+'
"("                     return  '('
")"                     return ')'
"!"                     return '!'

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
{UCHAR}                 return 'UCHAR'
{ECHAR}                 return 'ECHAR'
{WS}                    return 'WS'
{PN_CHARS_BASE}         return 'PN_CHARS_BASE'
{PN_CHARS_U}            return 'PN_CHARS_U'
{PN_CHARS}              return 'PN_CHARS'
{PN_LOCAL}              return 'PN_LOCAL'
{PLX}                   return 'PLX'
{PERCENT}               return 'PERCENT'
{HEX}                   return 'HEX'
{PN_LOCAL_ESC}          return 'PN_LOCAL_ESC'
<<EOF>>                 return 'EOF'

/lex

%ebnf

%start shaclDoc

%%

shaclDoc            : directive* (nodeShape|shapeClass)* EOF;

directive           : baseDecl | importsDecl | prefixDecl ;
baseDecl            : KW_BASE  IRIREF ;
importsDecl         : KW_IMPORTS IRIREF ;
prefixDecl          : KW_PREFIX PNAME_NS IRIREF ;

nodeShape           : KW_SHAPE iri targetClass? nodeShapeBody ;
shapeClass          : KW_SHAPE_CLASS iri nodeShapeBody ;
nodeShapeBody       : '{' constraint* '}';
targetClass         : '->' iri+ ;

constraint          : ( nodeOr+ | propertyShape ) '.' ;
nodeOr              : nodeNot ( '|' nodeNot) * ;
nodeNot             : negation? nodeValue ;
nodeValue           : nodeParam '=' iriOrLiteralOrArray ;

propertyShape       : path ( propertyCount | propertyOr )* ;
propertyOr          : propertyNot ( '|' propertyNot) * ;
propertyNot         : negation? propertyAtom ;
propertyAtom        : propertyType | nodeKind | shapeRef | propertyValue | nodeShapeBody ;
propertyCount       : '[' propertyMinCount '..' propertyMaxCount ']' ;
propertyMinCount    : INTEGER ;
propertyMaxCount    : (INTEGER | '*') ;
propertyType        : iri ;
nodeKind            : 'BlankNode' | 'IRI' | 'Literal' | 'BlankNodeOrIRI' | 'BlankNodeOrLiteral' | 'IRIOrLiteral' ;
shapeRef            : ATPNAME_LN | ATPNAME_NS | '@' IRIREF ;
propertyValue       : propertyParam '=' iriOrLiteralOrArray ;
negation            : '!' ;

path                : pathAlternative ;
pathAlternative     : pathSequence ( '|' pathSequence )* ;
pathSequence        : pathEltOrInverse ( '/' pathEltOrInverse )* ;
pathElt             : pathPrimary pathMod? ;
pathEltOrInverse    : pathElt | pathInverse pathElt ;
pathInverse         : '^' ;
pathMod             : '?' | '*' | '+' ;
pathPrimary         : iri | '(' path ')' ;

iriOrLiteralOrArray : iriOrLiteral | array ;
iriOrLiteral        : iri | literal ;

iri                 : IRIREF | prefixedName ;
prefixedName        : PNAME_LN | PNAME_NS ;

literal             : rdfLiteral | numericLiteral | booleanLiteral ;
booleanLiteral      : KW_TRUE | KW_FALSE ;
numericLiteral      : INTEGER | DECIMAL | DOUBLE ;
rdfLiteral          : string (LANGTAG | '^^' datatype)? ;
datatype            : iri ;
string              : STRING_LITERAL_LONG1 | STRING_LITERAL_LONG2 | STRING_LITERAL1 | STRING_LITERAL2 ;

array               : '[' iriOrLiteral* ']' ;

nodeParam           : 'targetNode' | 'targetObjectsOf' | 'targetSubjectsOf' |
                      'deactivated' | 'severity' | 'message' |
                      'class' | 'datatype' | 'nodeKind' |
                      'minExclusive' | 'minInclusive' | 'maxExclusive' | 'maxInclusive' |
                      'minLength' | 'maxLength' | 'pattern' | 'flags' | 'languageIn' |
                      'equals' | 'disjoint' |
                      'closed' | 'ignoredProperties' | 'hasValue' | 'in' ;

propertyParam       : 'deactivated' | 'severity' | 'message' |
                      'class' | 'datatype' | 'nodeKind' |
                      'minExclusive' | 'minInclusive' | 'maxExclusive' | 'maxInclusive' |
                      'minLength' | 'maxLength' | 'pattern' | 'flags' | 'languageIn' | 'uniqueLang' |
                      'equals' | 'disjoint' | 'lessThan' | 'lessThanOrEquals' |
                      'qualifiedValueShape' | 'qualifiedMinCount' | 'qualifiedMaxCount' | 'qualifiedValueShapesDisjoint' |
                      'closed' | 'ignoredProperties' | 'hasValue' | 'in' ;