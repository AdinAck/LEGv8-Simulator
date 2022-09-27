// Create your own language definition here
// You can safely look at other samples without losing modifications.
// Modifications are not saved on browser refresh/close though -- copy often!
return {
  // Set defaultToken to invalid to see what you do not tokenize yet
  // defaultToken: 'invalid',

  keywords: [
    'x0', 'x1', 'x2', 'x3', 'x4', // registers
    'x5', 'x6', 'x7', 'x8', 'x9',
    'x10', 'x11', 'x12', 'x13',
    'x14', 'x15', 'x16', 'x17',
    'x18', 'x19', 'x20', 'x21',
    'x22', 'x23', 'x24', 'x25',
    'x26', 'x27', 'x28', 'x29',
    'x30', 'xzr', 'ip1', 'ip2',
    'sp', 'fp', 'lr',
    'add', 'sub', 'addi', 'subi', 'adds', 'subs', 'addis', 'subis', // arithmetic instructions
    'ldur', 'stur', 'ldursw', 'sturw', 'ldurh', 'sturh', 'ldurb', 'sturb', 'ldxr', 'stxr', 'movz', 'movk', // data transfer
    'and', 'ands', 'orr', 'eor', 'andi', 'andis', 'orri', 'eori', 'lsl', 'lsr', // logical
    'cbz', 'cbnz', 'b', 'br', 'bl', // branching
    'eq', 'ne', 'hs', 'lo', 'hi', 'ls', 'ge', 'lt', 'gt', 'le', // condition codes
    'mov' // mov works as expected but is not mentioned in the documentation
  ],

  typeKeywords: [],

  operators: [],

  // we include these common regular expressions
  symbols:  /[=><!~?:&|+\-*\/\^%]+/,

  // C# style strings
  escapes: /\\(?:[abfnrtv\\"']|x[0-9A-Fa-f]{1,4}|u[0-9A-Fa-f]{4}|U[0-9A-Fa-f]{8})/,

  // The main tokenizer for our languages
  tokenizer: {
    root: [
      // identifiers and keywords
      [/[a-z_$][\w$]*/, { cases: { '@typeKeywords': 'keyword',
                                   '@keywords': 'keyword',
                                   '@default': 'identifier' } }],
      [/[A-Z][\w\$]*/, 'type.identifier' ],  // to show class names nicely

      // whitespace
      { include: '@whitespace' },

      // delimiters and operators
      [/[{}()\[\]]/, '@brackets'],
      [/[<>](?!@symbols)/, '@brackets'],
      [/@symbols/, { cases: { '@operators': 'operator',
                              '@default'  : '' } } ],

      // @ annotations.
      // As an example, we emit a debugging log message on these tokens.
      // Note: message are supressed during the first load -- change some lines to see them.
      [/@\s*[a-zA-Z_\$][\w\$]*/, { token: 'annotation', log: 'annotation token: $0' }],

      // numbers
      [/\d*\.\d+([eE][\-+]?\d+)?/, 'number.float'],
      [/0[xX][0-9a-fA-F]+/, 'number.hex'],
      [/\d+/, 'number'],

      // delimiter: after number because of .\d floats
      [/[;,.]/, 'delimiter'],

      // strings
      [/"([^"\\]|\\.)*$/, 'string.invalid' ],  // non-teminated string
      [/"/,  { token: 'string.quote', bracket: '@open', next: '@string' } ],

      // characters
      [/'[^\\']'/, 'string'],
      [/(')(@escapes)(')/, ['string','string.escape','string']],
      [/'/, 'string.invalid']
    ],

    comment: [
      [/[^\/*]+/, 'comment' ],
      [/\/\*/,    'comment', '@push' ],    // nested comment
      ["\\*/",    'comment', '@pop'  ],
      [/[\/*]/,   'comment' ]
    ],

    string: [
      [/[^\\"]+/,  'string'],
      [/@escapes/, 'string.escape'],
      [/\\./,      'string.escape.invalid'],
      [/"/,        { token: 'string.quote', bracket: '@close', next: '@pop' } ]
    ],

    whitespace: [
      [/[ \t\r\n]+/, 'white'],
      [/\/\*/,       'comment', '@comment' ],
      [/\/\/.*$/,    'comment'],
    ],
  },
};
