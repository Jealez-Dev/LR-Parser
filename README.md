# LR-Parser
Un Parser para lenguaje EBNF

ese Parser esta diseñado para el siguiente ENBF, basado en un lenguaje recursivos:

<Prog> ::= fun <id> (<ParForm>) dev (<ParForm>) = <Exp>
ffun
<id> ::= letter {letter}*
<ParForm>::= <id> : <id> {; <id> : <id>} *
<Exp> ::= <Const> | <id> | <Tupla> I <id> (<ParAct>) I
[<Exp>] l <Op> <Exp> I <Cond> I <DecLoc> I (<Exp>)
<ParAct> ::= <Exp> {, <Exp>}*
<Tupla> ::= (<Exp> {<Exp>}*)
<Op> ::= + | - | * | / | ^ | ⌐ | > | < | ≥ | ≤
<Const> ::= sintaxis habitual para constantes, ver clase
<Cond> ::= caso <Exp> → <Exp> {[] <Exp> → <Exp>}* fcaso
<DecLoc> ::= sea <id> = <Exp> {, <id> = <Exp>}* en <Exp>