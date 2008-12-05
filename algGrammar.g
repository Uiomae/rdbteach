grammar algGrammar;

// General grammar

prog
	: queryDef+
	;

queryDef
	: LINE_COMMENT
	| assignStat ';' NEWLINE
	| query ';' NEWLINE
	;

assignStat
	: relationName ('(' attributeList ')')? ':=' query
	;

relationName
	: ID
	;
	
attribute
	: ID
	;

attributeList
	: attribute (',' attribute)*
	;
	
constant 
	: (CHAR | FLOAT)
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
    : '%' ~('\n'|'\r')* NEWLINE
    ;

// Relational Algebra grammar

query	: expression
	;

expression
	: selectExpr
	| projectExpr
	| binaryExpr
	//| liteExpr
	;

selectExpr
	: 'select' condition '(' expression ')'
	;

condition
	: andCond ('or' condition)?
	;

andCond
	: relFormula ('and' andCond)?
	;

relFormula
	: operand RELATIONAL_OP operand
	| '(' condition ')'
	;

operand	: attribute
	| constant
	;

RELATIONAL_OP
	: '=' | '>' | '<' | '<>' | '>=' | '<='
	;

projectExpr
	: 'project' attributeList '(' expression ')'
	;

binaryExpr
	: liteExpr (binaryOp liteExpr)?
	;

liteExpr
	: '(' expression ')' | ID
	;

binaryOp
	: 'union' | 'njoin' | 'product' | 'difference' | 'intersect'
	;
