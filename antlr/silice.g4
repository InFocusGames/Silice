grammar silice;

/* ======== Lexer ======== */

fragment LETTER     : [a-zA-Z] ;
fragment LETTERU    : [a-zA-Z_] ;
fragment DIGIT      : [0-9] ;

BASETYPE            : 'int' | 'uint' ;

NUMBER              : DIGIT+ ;

TYPE                : BASETYPE DIGIT+;

GOTO                : 'goto' ;

AUTORUN             : 'autorun' ;

FILENAME            : '\'' (DIGIT|LETTERU|'.')* '\'' ;

REPEATCNT           : NUMBER 'x' ;

SUB                 : 'subroutine' ;

RETURN              : 'return' ;

CALL                : 'call' ;

BREAK               : 'break' ;

DELAYED             : 'delayed' ;

IDENTIFIER          : LETTER+ (DIGIT|LETTERU)* ;

CONSTANT            : '-'? DIGIT+ ('b'|'h'|'d') (DIGIT|[a-fA-Fxz])+ ;

REPEATID            : '__id' ;

AUTO                : '<:auto:>' ;

WHITESPACE          : (' ' | '\t') -> skip;

NEWLINE             : ('\r'? '\n' | '\r')+ -> skip ;

COMMENTBLOCK        : '/*' .*? '*/' -> skip ;

COMMENT             : '//' ~[\r\n]* NEWLINE -> skip ;

STATE               : IDENTIFIER ':' ;
NEXT                : '++:' ;

LARROW              : '<-' ;
RARROW              : '->' ;
LDEFINE             : '<:' ;
RDEFINE             : ':>' ;
BDEFINE             : '<:>';
ALWSASSIGN          : ':=' ;

STRING              : '"' ~[\r\n"]* '"' ;

/* ======== Parser ======== */

initValue           : NUMBER | CONSTANT ;

sclock              :  '@' IDENTIFIER ;
sreset              :  '!' IDENTIFIER ;
sautorun            :  AUTORUN ;

algModifier         : sclock | sreset | sautorun ;

algModifiers        : '<' (algModifier ',') * algModifier '>' ;

initList            : '{' (initValue ',')* initValue? '}';

declarationVar      : DELAYED? TYPE IDENTIFIER '=' initValue ;
declarationTable    : TYPE IDENTIFIER '[' NUMBER? ']' '=' (initList | STRING);
declarationModAlg   : modalg=IDENTIFIER name=IDENTIFIER algModifiers? ( '(' modalgBindingList ')' ) ?;
declaration         : declarationVar | declarationModAlg | declarationTable ; 

modalgBinding       : left=IDENTIFIER (LDEFINE | RDEFINE | BDEFINE) right=IDENTIFIER | AUTO;
modalgBindingList   : modalgBinding ',' modalgBindingList | modalgBinding | ;

expression_0        : expression_1 ('+' | '-' | '|' | '==' | '!=' | '<<' | '>>' | '<' | '>' | '<=' | '>=') expression_1 
                    | expression_0 ('+' | '-' | '|' | '==' | '!=' | '<<' | '>>' | '<' | '>' | '<=' | '>=') expression_1 
                    | expression_1;
expression_1        : unaryExpression ('*'|'&'|'^') unaryExpression | unaryExpression ;
unaryExpression     : ('-' | '&' | '|' | '~' | '!') atom | atom ;

ioAccess            : algo=IDENTIFIER '.' io=IDENTIFIER ;
bitAccess           : (ioAccess | tableAccess | IDENTIFIER) '[' first=expression_0 ',' num=NUMBER ']' ;
tableAccess         : (ioAccess | IDENTIFIER) '[' expression_0 ']' ;
access              : (ioAccess | tableAccess | bitAccess) ; 

atom                : CONSTANT 
                    | NUMBER 
                    | IDENTIFIER 
                    | REPEATID
                    | access
                    | '(' expression_0 ')' ;
                    
assignment          : IDENTIFIER  '=' expression_0
                    | access      '=' expression_0 ;

alwaysAssigned      : IDENTIFIER   ALWSASSIGN expression_0
                    | access       ALWSASSIGN expression_0
                    ;

alwaysAssignedList  : alwaysAssigned ';' alwaysAssignedList | ;

paramList           : IDENTIFIER ',' paramList 
                    | IDENTIFIER 
                    | IDENTIFIER '[' NUMBER ']' ',' paramList 
                    | IDENTIFIER '[' NUMBER ']'
                    | ;

algoAsyncCall       : IDENTIFIER LARROW '(' paramList ')' ;
algoJoin            : '(' paramList ')' LARROW IDENTIFIER ;
algoSyncCall        : algoJoin LARROW '(' paramList ')' ;

state               : STATE | NEXT ;
jump                : GOTO IDENTIFIER ;
subCall             : CALL IDENTIFIER ;
breakLoop           : BREAK ;

block               : '{' instructionList '}';
ifThen              : 'if' '(' expression_0 ')' if_block=block ;
ifThenElse          : 'if' '(' expression_0 ')' if_block=block 'else' else_block=block ;
whileLoop           : 'while' '(' expression_0 ')' while_block=block ;

instruction         : assignment 
                    | algoSyncCall
                    | algoAsyncCall
                    | algoJoin
                    | jump
                    | subCall
                    | breakLoop
                    ;

declarationList     : declaration ';' declarationList | ;

instructionList     : 
                      (instruction ';') + instructionList 
                    | repeatBlock instructionList
                    | state       instructionList
                    | ifThenElse  instructionList
                    | ifThen      instructionList
                    | whileLoop   instructionList
					| ;

subroutine          : SUB STATE instructionList RETURN ';' ;
subroutineList      : subroutine * ;
                    
declAndInstrList    : declarationList 
                      subroutineList 
                      alwaysAssignedList 
                      instructionList;

importv             : 'import' '(' FILENAME ')' ;

appendv             : 'append' '(' FILENAME ')' ;

repeatBlock         : REPEATCNT '{' instructionList '}' ;

inout               : 'inout' TYPE IDENTIFIER 
                    | 'inout' TYPE IDENTIFIER '[' NUMBER ']';
input               : 'input' TYPE IDENTIFIER 
                    | 'input' TYPE IDENTIFIER '[' NUMBER ']';
output              : 'output' TYPE IDENTIFIER
                    | 'output' TYPE IDENTIFIER '[' NUMBER ']';
inOrOut             :  input | output | inout ;
inOutList           :  (inOrOut ',') * inOrOut | ;

algorithm           : 'algorithm' IDENTIFIER '(' inOutList ')' algModifiers? '{' declAndInstrList '}' ;
algorithmList       :  (algorithm | importv | appendv) algorithmList | ;

root                : algorithmList ;
