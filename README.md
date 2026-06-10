# LR-Parser
Un Parser para lenguaje EBNF

ese Parser esta diseñado para el siguiente ENBF, basado en un lenguaje recursivos:

<Prog> ::= 'fun' <id> '(' <ParForm> ')' 'dev' '(' <ParForm> ')' '=' <Exp> 'ffun'

<ParForm> ::= <id> ':' <Tipo> { ';' <id> ':' <Tipo> } *

<Tipo> ::= 'int' | 'real' | 'bool' | 'char' | <id>

(* Expresión: niveles de precedencia *)
<Exp>      ::= <ExpRel>
<ExpRel>   ::= <ExpSuma> { <Op_Rel> <ExpSuma> }* | '¬' <ExpSuma>
<ExpSuma>  ::= <ExpMul> { <Op_Nivel1> <ExpMul> }*
<ExpMul>   ::= <ExpPot> { <Op_Nivel2> <ExpPot> }*
<ExpPot>   ::= <ExpAtom> [ <Op_Nivel3> <ExpPot> ]

(* Átomo: todas las expresiones básicas, sin operadores infijos *)
<ExpAtom> ::= <Const>
            | <fun_or_var>
            | <Tupla>
            | <Cond>
            | <DecLoc>
            | '(' <Exp> ')'

<fun_or_var> ::= <id> ['(' <ParAct> ')']

<ParAct> ::= <Exp> { ',' <Exp> } *

<Tupla> ::= '(' <Exp> ',' <Exp> { ',' <Exp> }* ')'              

(* Operadores: se completa la lista original *)
<Op> ::= <Op_Nivel1> | <Op_Nivel2> | <Op_Nivel3> | <Op_Rel>
<Op_Rel> ::=  '>' | '<' | '>=' | '<='
<Op_Nivel1> ::= '+' | '-'
<Op_Nivel2> ::= '*' | '/'
<Op_Nivel3> ::= '^'

(* Constantes: definición habitual según lo visto en clase *)
<Const> ::= <Entero> | <Real> | <Booleano> | <Caracter> | <Cadena>
<Entero> ::= ['-'] <dígito> { <dígito> }*
<Real> ::= ['-'] <dígito> { <dígito> }* '.' <dígito> { <dígito> }*
<Booleano> ::= 'true' | 'false'
<Caracter> ::= "'" (<letra> | <digito>) "'"
<Cadena> ::= '"' {<letra> | <digito>}* '"'

<Cond> ::= 'caso' <Exp> '→' <Exp> { '[]' <Exp> '→' <Exp> } * 'fcaso'

<DecLoc> ::= 'sea' <DefLocal> { ',' <DefLocal> }* 'en' <Exp>
<DefLocal> ::= <id> '=' <Exp>

(* Identificadores *)
<id> ::= <letra> { <letra> | <dígito> | '_' }*
<letra> ::= 'a' | 'b' | ... | 'z' | 'A' | ... | 'Z'
<dígito> ::= '0' | '1' | ... | '9'
