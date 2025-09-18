# module FOLParser

# export Term, Formula,
#        Var, Num, Fun, Neg, Add, Sub, Mul, Div, Pow,
#        Pred, Rel, Not, And, Or, Implies, Iff, ForAll, Exists, BoolConst,
#        parse_formula

############
# AST types
############

abstract type Term end
struct Var    <: Term; name::String end
struct Num    <: Term; value::Float64 end
struct Fun    <: Term; name::String; args::Vector{Term} end
struct Neg    <: Term; arg::Term end
struct Add    <: Term; left::Term; right::Term end
struct Sub    <: Term; left::Term; right::Term end
struct Mul    <: Term; left::Term; right::Term end
struct Div    <: Term; left::Term; right::Term end
struct Pow    <: Term; base::Term; exponent::Term end

abstract type Formula end
struct Pred    <: Formula; name::String; args::Vector{Term} end
struct Rel     <: Formula; op::Symbol; left::Term; right::Term end  # :eq,:ne,:lt,:le,:gt,:ge
struct Not     <: Formula; φ::Formula end
struct And     <: Formula; left::Formula; right::Formula end
struct Or      <: Formula; left::Formula; right::Formula end
struct Implies <: Formula; left::Formula; right::Formula end
struct Iff     <: Formula; left::Formula; right::Formula end
struct ForAll  <: Formula; vars::Vector{String}; body::Formula end
struct Exists  <: Formula; vars::Vector{String}; body::Formula end
struct BoolConst <: Formula; value::Bool end

############
# Tokenizer
############

struct Token
    kind::Symbol
    val::Any
    pos::Int
end

const RELOPS = Set([:EQ,:NE,:LT,:LE,:GT,:GE])

# Helpers for characters
_isidentstart(c::Char) = isletter(c) || c == '_'
_isidentchar(c::Char)  = isletter(c) || isdigit(c) || c == '_' || c == '\''

function _read_number(s::String, i::Int)
    j = i
    dot_seen = false
    while j <= lastindex(s)
        c = s[j]
        if c == '.' && !dot_seen
            dot_seen = true
            j = nextind(s, j)
        elseif isdigit(c)
            j = nextind(s, j)
        else
            break
        end
    end
    # optional exponent
    if j <= lastindex(s) && (s[j] == 'e' || s[j] == 'E')
        j2 = nextind(s, j)
        if j2 <= lastindex(s) && (s[j2] == '+' || s[j2] == '-')
            j3 = nextind(s, j2)
        else
            j3 = j2
        end
        hasexp = false
        while j3 <= lastindex(s) && isdigit(s[j3])
            hasexp = true
            j3 = nextind(s, j3)
        end
        j = hasexp ? j3 : j
    end
    text = String(s[i:prevind(s,j)])
    return Token(:NUMBER, parse(Float64, text), i), j
end

function tokenize(s::String)
    toks = Token[]
    i = firstindex(s)
    L = lastindex(s)

    nextch(k) = k <= L ? s[k] : '\0'

    while i <= L
        c = s[i]
        if isspace(c)
            i = nextind(s, i); continue
        end

        # Multi-char ops
        if c == '-' && nextch(nextind(s,i)) == '>'
            push!(toks, Token(:IMPLIES, "->", i))
            i = nextind(s, nextind(s,i)); continue
        elseif c == '<'
            i2 = nextind(s, i)
            if i2 <= L && s[i2] == '-' && nextind(s,i2) <= L && s[nextind(s,i2)] == '>'
                push!(toks, Token(:IFF, "<->", i))
                i = nextind(s, nextind(s, i2)); continue
            elseif i2 <= L && s[i2] == '='
                push!(toks, Token(:RELOP, :LE, i))
                i = nextind(s, i2); continue
            else
                push!(toks, Token(:RELOP, :LT, i))
                i = i2; continue
            end
        elseif c == '>' 
            i2 = nextind(s, i)
            if i2 <= L && s[i2] == '='
                push!(toks, Token(:RELOP, :GE, i))
                i = nextind(s, i2); continue
            else
                push!(toks, Token(:RELOP, :GT, i))
                i = i2; continue
            end
        elseif c == '='
            push!(toks, Token(:RELOP, :EQ, i))
            i = nextind(s, i); continue
        elseif c == '!' 
            i2 = nextind(s, i)
            if i2 <= L && s[i2] == '='
                push!(toks, Token(:RELOP, :NE, i))
                i = nextind(s, i2); continue
            else
                push!(toks, Token(:NOT, "!", i))
                i = i2; continue
            end
        end

        # Unicode single-char operators
        if c == '¬'
            push!(toks, Token(:NOT, "¬", i));  i = nextind(s, i); continue
        elseif c == '∧' || c == '&'
            push!(toks, Token(:AND, "∧", i));  i = nextind(s, i); continue
        elseif c == '∨' || c == '|'
            push!(toks, Token(:OR,  "∨", i));  i = nextind(s, i); continue
        elseif c == '→'
            push!(toks, Token(:IMPLIES, "→", i));  i = nextind(s, i); continue
        elseif c == '↔'
            push!(toks, Token(:IFF, "↔", i));  i = nextind(s, i); continue
        elseif c == '≤'
            push!(toks, Token(:RELOP, :LE, i));  i = nextind(s, i); continue
        elseif c == '≥'
            push!(toks, Token(:RELOP, :GE, i));  i = nextind(s, i); continue
        elseif c == '≠'
            push!(toks, Token(:RELOP, :NE, i));  i = nextind(s, i); continue
        elseif c == '⊤'
            push!(toks, Token(:BOOL, true, i)); i = nextind(s, i); continue
        elseif c == '⊥'
            push!(toks, Token(:BOOL, false, i)); i = nextind(s, i); continue
        end

        # Single-char punctuation / arithmetic
        if c == '('; push!(toks, Token(:LPAREN, "(", i)); i = nextind(s, i); continue; end
        if c == ')'; push!(toks, Token(:RPAREN, ")", i)); i = nextind(s, i); continue; end
        if c == ','; push!(toks, Token(:COMMA,  ",", i)); i = nextind(s, i); continue; end
        if c == '.'; push!(toks, Token(:DOT,    ".", i)); i = nextind(s, i); continue; end
        if c == ':'; push!(toks, Token(:COLON,  ":", i)); i = nextind(s, i); continue; end
        if c == '+'; push!(toks, Token(:PLUS,   "+", i)); i = nextind(s, i); continue; end
        if c == '-'; push!(toks, Token(:MINUS,  "-", i)); i = nextind(s, i); continue; end
        if c == '*'; push!(toks, Token(:STAR,   "*", i)); i = nextind(s, i); continue; end
        if c == '/'; push!(toks, Token(:SLASH,  "/", i)); i = nextind(s, i); continue; end
        if c == '^'; push!(toks, Token(:CARET,  "^", i)); i = nextind(s, i); continue; end

        # Numbers
        if isdigit(c) || (c == '.' && i < L && isdigit(s[nextind(s,i)]))
            tok, j = _read_number(s, i)
            push!(toks, tok)
            i = j; continue
        end

        # Identifiers / keywords
        if _isidentstart(c)
            j = i
            while j <= L && _isidentchar(s[j])
                j = nextind(s, j)
            end
            text = String(s[i:prevind(s, j)])
            lower = lowercase(text)
            if lower == "forall" || text == "∀"
                push!(toks, Token(:FORALL, text, i))
            elseif lower == "exists" || text == "∃"
                push!(toks, Token(:EXISTS, text, i))
            elseif lower == "and"
                push!(toks, Token(:AND, text, i))
            elseif lower == "or"
                push!(toks, Token(:OR, text, i))
            elseif lower == "not"
                push!(toks, Token(:NOT, text, i))
            elseif lower == "true"
                push!(toks, Token(:BOOL, true, i))
            elseif lower == "false"
                push!(toks, Token(:BOOL, false, i))
            else
                push!(toks, Token(:IDENT, text, i))
            end
            i = j; continue
        end

        error("Unexpected character '$(c)' at position $(i).")
    end

    push!(toks, Token(:EOF, nothing, L+1))
    return toks
end

############
# Parser
############

mutable struct Parser
    tokens::Vector{Token}
    pos::Int
end

peek(p::Parser) = p.tokens[p.pos]
peekkind(p::Parser) = peek(p).kind
function advance!(p::Parser)
    t = p.tokens[p.pos]
    p.pos += 1
    return t
end
function expect!(p::Parser, kind::Symbol)
    t = advance!(p)
    t.kind == kind || error("Expected $(kind) at $(t.pos), got $(t.kind).")
    return t
end
function accept!(p::Parser, kind::Symbol)
    if peekkind(p) == kind
        return advance!(p)
    end
    return nothing
end

# Entry
function parse_formula(s::String)::Formula
    p = Parser(tokenize(s), 1)
    φ = parse_quant_or_iff(p)
    peekkind(p) == :EOF || error("Unexpected trailing input at $(peek(p).pos).")
    return φ
end

############
# Grammar (with precedence)
#
# formula        := quantifier | iff
# quantifier     := (FORALL|EXISTS) varlist (DOT|COLON) formula
# varlist        := IDENT (COMMA IDENT)*
# iff            := impl ( (IFF) impl )*
# impl           := or   ( (IMPLIES) or )*
# or             := and  ( (OR) and )*
# and            := not  ( (AND) not )*
# not            := (NOT not) | atom
# atom           := BOOL
#                 | LPAREN formula RPAREN
#                 | comparison
#                 | predicate_app         # P(t1,...,tn)
#
# comparison     := term relop term
# predicate_app  := IDENT LPAREN [term (COMMA term)*] RPAREN
#
# term           := addsub
# addsub         := muldiv ( (PLUS|MINUS) muldiv )*
# muldiv         := power ( (STAR|SLASH) power )*
# power          := unary ( (CARET) unary )*         # right-assoc
# unary          := (MINUS unary) | primary
# primary        := NUMBER | IDENT funcall? | LPAREN term RPAREN
# funcall        := LPAREN [term (COMMA term)*] RPAREN
############

# Quantifier (highest)
function parse_quant_or_iff(p::Parser)::Formula
    if peekkind(p) == :FORALL
        advance!(p)
        vars = parse_varlist(p)
        (accept!(p, :DOT) !== nothing) || (accept!(p, :COLON) !== nothing) ||
            error("Expected '.' or ':' after variable list.")
        body = parse_quant_or_iff(p)
        return ForAll(vars, body)
    elseif peekkind(p) == :EXISTS
        advance!(p)
        vars = parse_varlist(p)
        (accept!(p, :DOT) !== nothing) || (accept!(p, :COLON) !== nothing) ||
            error("Expected '.' or ':' after variable list.")
        body = parse_quant_or_iff(p)
        return Exists(vars, body)
    else
        return parse_iff(p)
    end
end

function parse_varlist(p::Parser)
    vars = String[]
    first = expect!(p, :IDENT)
    push!(vars, String(first.val))
    while accept!(p, :COMMA) !== nothing
        id = expect!(p, :IDENT)
        push!(vars, String(id.val))
    end
    return vars
end

# IFF
function parse_iff(p::Parser)
    left = parse_impl(p)
    while peekkind(p) == :IFF
        advance!(p)
        right = parse_impl(p)
        left = Iff(left, right)
    end
    return left
end

# IMPLIES (right-assoc by re-association)
function parse_impl(p::Parser)
    parts = Formula[parse_or(p)]
    while peekkind(p) == :IMPLIES
        advance!(p)
        push!(parts, parse_or(p))
    end
    # chain a1 -> a2 -> a3 := a1 -> (a2 -> a3)
    result = parts[end]
    for i in (length(parts)-1):-1:1
        result = Implies(parts[i], result)
    end
    return result
end

# OR
function parse_or(p::Parser)
    left = parse_and(p)
    while peekkind(p) == :OR
        advance!(p)
        right = parse_and(p)
        left = Or(left, right)
    end
    return left
end

# AND
function parse_and(p::Parser)
    left = parse_not(p)
    while peekkind(p) == :AND
        advance!(p)
        right = parse_not(p)
        left = And(left, right)
    end
    return left
end

# NOT
function parse_not(p::Parser)
    if peekkind(p) == :NOT
        advance!(p)
        return Not(parse_not(p))
    else
        return parse_atom(p)
    end
end

# ATOM
function parse_atom(p::Parser)::Formula
    # Boolean constants
    if peekkind(p) == :BOOL
        v = advance!(p).val
        return BoolConst(v)
    end

    if accept!(p, :LPAREN) !== nothing
        φ = parse_quant_or_iff(p)
        expect!(p, :RPAREN)
        return φ
    end

    # decide between comparison or predicate application
    # Try: parse a term and see if a RELOP follows.
    savepos = p.pos
    t = try
        parse_term(p)
    catch err
        # restore and try predicate explicitly
        p.pos = savepos
        nothing
    end

    if t !== nothing && peekkind(p) == :RELOP
        op = advance!(p).val # Symbol
        rhs = parse_term(p)
        return Rel(op, t, rhs)
    elseif t !== nothing
        # If this is a Fun(...) and not followed by a relop, treat as predicate atom.
        if t isa Fun
            return Pred(t.name, (t::Fun).args)
        else
            error("Bare term where a formula was expected at position $(peek(p).pos). Use a comparison (e.g., t1 <= t2) or a predicate like P(x).")
        end
    end

    # Explicit predicate attempt: IDENT '(' args ')'
    if peekkind(p) == :IDENT
        # Lookahead: must be IDENT LPAREN ...
        name = String(advance!(p).val)
        if accept!(p, :LPAREN) === nothing
            error("Expected '(' after predicate name $name.")
        end
        args = Term[]
        if peekkind(p) != :RPAREN
            push!(args, parse_term(p))
            while accept!(p, :COMMA) !== nothing
                push!(args, parse_term(p))
            end
        end
        expect!(p, :RPAREN)
        return Pred(name, args)
    end

    error("Invalid atomic formula near position $(peek(p).pos).")
end

# TERMS

function parse_term(p::Parser)::Term
    return parse_addsub(p)
end

function parse_addsub(p::Parser)
    left = parse_muldiv(p)
    while true
        k = peekkind(p)
        if k == :PLUS
            advance!(p); right = parse_muldiv(p); left = Add(left, right)
        elseif k == :MINUS
            advance!(p); right = parse_muldiv(p); left = Sub(left, right)
        else
            break
        end
    end
    return left
end

function parse_muldiv(p::Parser)
    left = parse_power(p)
    while true
        k = peekkind(p)
        if k == :STAR
            advance!(p); right = parse_power(p); left = Mul(left, right)
        elseif k == :SLASH
            advance!(p); right = parse_power(p); left = Div(left, right)
        else
            break
        end
    end
    return left
end

function parse_power(p::Parser)
    # right-assoc: chain later
    parts = Term[parse_unary(p)]
    while peekkind(p) == :CARET
        advance!(p)
        push!(parts, parse_unary(p))
    end
    result = parts[end]
    for i in (length(parts)-1):-1:1
        result = Pow(parts[i], result)
    end
    return result
end

function parse_unary(p::Parser)
    if peekkind(p) == :MINUS
        advance!(p)
        return Neg(parse_unary(p))
    else
        return parse_primary(p)
    end
end

function parse_primary(p::Parser)
    k = peekkind(p)
    if k == :NUMBER
        return Num(advance!(p).val)
    elseif k == :IDENT
        name = String(advance!(p).val)
        # function application?
        if accept!(p, :LPAREN) !== nothing
            args = Term[]
            if peekkind(p) != :RPAREN
                push!(args, parse_term(p))
                while accept!(p, :COMMA) !== nothing
                    push!(args, parse_term(p))
                end
            end
            expect!(p, :RPAREN)
            return Fun(name, args)
        else
            return Var(name)
        end
    elseif k == :LPAREN
        advance!(p)
        t = parse_term(p)
        expect!(p, :RPAREN)
        return t
    else
        error("Expected a term at position $(peek(p).pos).")
    end
end

# end # module

# φ1 = parse_formula("forall x,y. (x^2 + y^2 >= 1) -> exists z. z > x and P(y)")
φ2 = parse_formula("∃x. ¬(x < 0) ∧ (f(x) = 0)")
# φ3 = parse_formula("forall x. (x >= 0 -> (∃y. y*y = x))")
φ4 = parse_formula("P(a,b) <-> (true or false)")

# println(φ1)
println(φ2)
# println(φ3)
println(φ4)