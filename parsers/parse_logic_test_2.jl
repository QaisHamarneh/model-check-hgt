include("parse_constraint.jl")
include("../STL/logic.jl")

# ---- Minimal lexer helpers ----
mutable struct _PS
    s::String
    i::Int
end

_eof(ps::_PS) = ps.i > lastindex(ps.s)
_peek(ps::_PS) = _eof(ps) ? '\0' : ps.s[ps.i]
function _consume!(ps::_PS, n::Int=1)
    ps.i = min(lastindex(ps.s)+1, ps.i + n)
end
function _skipws!(ps::_PS)
    while !_eof(ps) && isspace(ps.s[ps.i]); ps.i += 1; end
end

# word-bounded keyword (not/and/or/imply/F/G)
function _match_kw!(ps::_PS, kw::AbstractString)
    _skipws!(ps)
    i0 = ps.i
    for c in kw
        if _eof(ps) || _peek(ps) != c; ps.i = i0; return false; end
        _consume!(ps,1)
    end
    # word boundary
    if !_eof(ps)
        c = _peek(ps)
        if isletter(c) || isdigit(c) || c == '_'
            ps.i = i0
            return false
        end
    end
    return true
end
function _peek_kw(ps::_PS, kw::AbstractString)
    i0 = ps.i
    ok = _match_kw!(ps, kw)
    ps.i = i0
    return ok
end

# exact multi-char tokens (e.g., "<<", ">>", "[[", "]]", ")")
function _match_tok!(ps::_PS, t::AbstractString)
    _skipws!(ps)
    i0 = ps.i
    for c in t
        if _eof(ps) || _peek(ps) != c; ps.i = i0; return false; end
        _consume!(ps,1)
    end
    return true
end
function _expect_tok!(ps::_PS, t::AbstractString)
    _match_tok!(ps, t) || error("Expected token \"$t\"")
end

# identifier [A-Za-z_][A-Za-z0-9_]*
function _read_ident!(ps::_PS)
    _skipws!(ps)
    i0 = ps.i
    if _eof(ps); return "" end
    c = _peek(ps)
    if !(isletter(c) || c == '_'); return "" end
    _consume!(ps,1)
    while !_eof(ps)
        c = _peek(ps)
        if isletter(c) || isdigit(c) || c == '_'; _consume!(ps,1) else; break end
    end
    return ps.s[i0:ps.i-1]
end

# Parse agents inside << ... >> or [[ ... ]], comma/space separated
function _parse_agents_until!(ps::_PS, closing::AbstractString)
    names = String[]
    buf = IOBuffer()
    while !_eof(ps) && ! _match_tok!(_PS(ps.s, ps.i), closing)  # non-consuming peek
        c = _peek(ps)
        if c == ','
            name = strip(String(take!(buf))); if !isempty(name); push!(names, name); end
            _consume!(ps,1)
        else
            write(buf, c); _consume!(ps,1)
        end
    end
    _expect_tok!(ps, closing)
    lastn = strip(String(take!(buf))); if !isempty(lastn); push!(names, lastn); end
    syms = Symbol[]
    for n in names
        for part in split(n, r"\s+")
            if !isempty(part); push!(syms, Symbol(part)); end
        end
    end
    return Set(syms)
end

# Read a state-chunk until a top-level strategy boundary: and/or/imply/)/EOF
function _read_state_chunk!(ps::_PS)
    _skipws!(ps)
    i0 = ps.i
    s = ps.s
    j = ps.i
    depth = 0
    while j <= lastindex(s)
        c = s[j]
        if c == '('
            depth += 1; j = nextind(s, j)
        elseif c == ')'
            if depth == 0; break; else depth -= 1; j = nextind(s, j) end
        elseif isspace(c) && depth == 0
            # look ahead after whitespace for a strategy keyword
            ps2 = _PS(s, j)
            _skipws!(ps2)
            if _peek_kw(ps2, "and") || _peek_kw(ps2, "or") || _peek_kw(ps2, "imply")
                ps.i = j
                return strip(i0 < j ? s[i0:prevind(s, j)] : "")
            else
                j = nextind(s, j)
            end
        else
            j = nextind(s, j)
        end
    end
    ps.i = j
    return strip(i0 < j ? s[i0:prevind(s, j)] : "")
end

const _IDENT_RE = r"^[A-Za-z_][A-Za-z0-9_]*$"

# ---- State_Formula ----
function _parse_state!(ps::_PS)::State_Formula
    _skipws!(ps)
    # allow parentheses around a state (treated as part of constraint unless it's a bare ident)
    # special-cases true/false into State_Truth
    # otherwise: bare ident -> State_Location; else -> State_Constraint(parse_constraint(chunk))
    chunk = _read_state_chunk!(ps)
    isempty(chunk) && error("Expected a state formula")
    if chunk == "true";  return State_Truth(true)  end
    if chunk == "false"; return State_Truth(false) end
    if occursin(_IDENT_RE, chunk)
        return State_Location(Symbol(chunk))
    else
        return State_Constraint(parse_constraint(chunk))
    end
end

# ---- Strategy_Formula (precedence: not > and > or > imply (right-assoc)) ----
_parse_strategy!(ps::_PS)::Strategy_Formula = _parse_imply!(ps)

function _parse_imply!(ps::_PS)::Strategy_Formula
    left = _parse_or!(ps)
    if _match_kw!(ps, "imply")
        right = _parse_imply!(ps)  # right-associative
        return Strategy_Or(Strategy_Not(left), right)  # a -> b  ≡  ¬a ∨ b
    else
        return left
    end
end

function _parse_or!(ps::_PS)::Strategy_Formula
    left = _parse_and!(ps)
    while _match_kw!(ps, "or")
        right = _parse_and!(ps)
        left = Strategy_Or(left, right)
    end
    return left
end

function _parse_and!(ps::_PS)::Strategy_Formula
    left = _parse_unary!(ps)
    while _match_kw!(ps, "and")
        right = _parse_unary!(ps)
        left = Strategy_And(left, right)
    end
    return left
end

function _parse_unary!(ps::_PS)::Strategy_Formula
    if _match_kw!(ps, "not")
        return Strategy_Not(_parse_unary!(ps))
    end
    return _parse_atom!(ps)
end

function _parse_atom!(ps::_PS)::Strategy_Formula
    _skipws!(ps)
    # parenthesized strategy
    if _match_tok!(ps, "(")
        inner = _parse_strategy!(ps)
        _expect_tok!(ps, ")")
        return inner
    end
    # <<A>>F p / <<A>>G p
    if _match_tok!(ps, "<<")
        agents = _parse_agents_until!(ps, ">>")
        if     _match_kw!(ps, "F"); return Exist_Eventually(agents, _parse_state!(ps))
        elseif _match_kw!(ps, "G"); return Exist_Always(agents,    _parse_state!(ps))
        else error("Expected 'F' or 'G' after '<<A>>'"); end
    end
    # [[A]]F p / [[A]]G p
    if _match_tok!(ps, "[[")
        agents = _parse_agents_until!(ps, "]]")
        if     _match_kw!(ps, "F"); return All_Eventually(agents, _parse_state!(ps))
        elseif _match_kw!(ps, "G"); return All_Always(agents,    _parse_state!(ps))
        else error("Expected 'F' or 'G' after '[[A]]'"); end
    end
    # fallback: p  (location_name | constraint)
    return Strategy_to_State(_parse_state!(ps))
end

# ---- Public API ----
"""
    parse_logic(input::AbstractString) :: Strategy_Formula

Grammar:
  s ::= not s | s and s | s or s | s imply s | <<A>>F p | <<A>>G p | [[A]]F p | [[A]]G p | p
  p ::= location_name | constraint

Notes:
- Precedence: not > and > or > imply (right-assoc).
- Agents A are comma/space separated inside `<< >>` or `[[ ]]`.
- `location_name` is a bare identifier `[A-Za-z_][A-Za-z0-9_]*`.
- `true`/`false` are parsed as `State_Truth`.
- All other state chunks are passed to your `parse_constraint(::AbstractString)`.
"""
function parse_logic(input::AbstractString)::Strategy_Formula
    ps = _PS(input, firstindex(input))
    out = _parse_strategy!(ps)
    _skipws!(ps)
    if !_eof(ps)
        error("Unexpected trailing input at position $(ps.i): \"$(input[ps.i:end])\"")
    end
    return out
end


# struct Constraint; expr::String; end
# parse_constraint(s::AbstractString) = Constraint(s)

# parse: (a imply <<x,y>>F speed<=30) and [[x]]G true
ast = parse_logic("(a imply <<x,y>>F speed<=30) and [[x]]G true")
# g = parse_logic("<<a,b>>F (loc1 and x<=5 or not loc2)")
g0 = parse_logic("[[a,b]]F (loc1 and x<=5 and y<=3 or not loc2)")
g2 = parse_logic("x<=5 && y<=3 and <<a,b>>F (loc5 and x<=5 && y<=3 or not loc2)")

println(ast)
println(g)
println(g0)
println(g2)
