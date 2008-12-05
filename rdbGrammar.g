grammar rdbGrammar;

options {
	language = Perl5;
	}

prog
	: (relation tuple*)+
	;

tuple	: constants NEWLINE
	;

constants 
	: constant (',' constant)*
	;

relation
	: '@' ID '(' attributes ')' ':' identifiers NEWLINE
	;

attributes
	: attribute (',' attribute)* 
	;

attribute
	: ID '/' TYPENAME
	;

identifiers
	: ID (',' ID)*
	;
	
constant 
	: (CHAR | FLOAT)
	;

TYPENAME 
	: 'char' | 'numeric'
	;

ID : ('a'..'z'|'A'..'Z')('a'..'z'|'A'..'Z'|'0'..'9')*;
CHAR : '"' .* '"' | '\'' .* '\'';
//INT : '0'..'9'+;
FLOAT : '0'..'9'+ ('.' '0'..'9'+ (('e'|'E')'0'..'9'+)?)?;
	
NEWLINE : ('\r'? '\n')+;

WS  :  (' '|'\r'|'\t'|'\u000C'|'\n') {$channel=HIDDEN;}
    ;

COMMENT
    :   '/*' .* '*/' NEWLINE {$channel=HIDDEN;}
    ;
    
LINE_COMMENT
    : '%' ~('\n'|'\r')* '\r'? '\n' {$channel=HIDDEN;}
    ;
