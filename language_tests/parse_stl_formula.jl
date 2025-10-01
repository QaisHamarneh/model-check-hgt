include("parse_constraint.jl")
include("../STL/logic.jl")


# --------- Parser ----------
# Pass your own constraint parser here; by default, we error if a constraint is encountered.
const _DEFAULT_CONS_PARSER = s -> error("Provide `constraint_parser` to parse constraint: \"$s\"")

mutable struct _PS
    s::String
    i::Int
end

# --- low-level helpers ---
_eof(ps::_PS) = ps.i > lastindex(ps.s)
function _skipws!(ps::_PS)
    while !_eof(ps) && isspace(ps.s[ps.i])
        ps.i += 1
    end
end
_peek(ps::_PS) = _eof(ps) ? '\0' : ps.s[ps.i]
function _consume!(ps::_PS, n::Int=1)
    ps.i = min(lastindex(ps.s)+1, ps.i + n)
end

# read an identifier [A-Za-z_][A-Za-z0-9_]*
function _read_ident!(ps::_PS)
    _skipws!(ps)
    i0 = ps.i
    if _eof(ps); return "" end
    c = _peek(ps)
    if !(isletter(c) || c == '_'); return "" end
    _consume!(ps, 1)
    while !_eof(ps)
        c = _peek(ps)
        if isletter(c) || isdigit(c) || c == '_'
            _consume!(ps, 1)
        else
            break
        end
    end
    return ps.s[i0:ps.i-1]
end

# match a specific symbol if present
function _match_char!(ps::_PS, ch::Char)
    _skipws!(ps)
    if !_eof(ps) && _peek(ps) == ch
        _consume!(ps, 1)
        return true
    end
    return false
end

# read keyword with word boundary
function _match_kw!(ps::_PS, kw::AbstractString)
    _skipws!(ps)
    i0 = ps.i
    for c in kw
        if _eof(ps) || _peek(ps) != c
            ps.i = i0
            return false
        end
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

# Peek if next non-ws chars start with a keyword
function _peek_kw(ps::_PS, kw::AbstractString)
    i0 = ps.i
    ok = _match_kw!(ps, kw)
    ps.i = i0
    return ok
end

# --- agents: parse inside < ... > or [ ... ] ---
function _parse_agents!(ps::_PS, closing::Char)
    _skipws!(ps)
    names = String[]
    buf = IOBuffer()
    while !_eof(ps) && _peek(ps) != closing
        c = _peek(ps)
        if c == ','
            name = strip(String(take!(buf)))
            if !isempty(name)
                push!(names, name)
            end
            _consume!(ps,1)
        else
            write(buf, c)
            _consume!(ps,1)
        end
    end
    if !_match_char!(ps, closing)
        error("Expected '$closing' to close agents list")
    end
    lastname = strip(String(take!(buf)))
    if !isempty(lastname)
        push!(names, lastname)
    end
    # split identifiers possibly separated by spaces
    syms = Symbol[]
    for n in names
        # allow spaces within: "a b" -> ["a","b"]
        for part in split(n, r"\s+")
            if !isempty(part)
                push!(syms, Symbol(part))
            end
        end
    end
    return Set(syms)
end

# --- constraint chunk: read until top-level boundary (or/or/)/EOF) with paren nesting ---
function _read_until_boundary!(ps::_PS)
    _skipws!(ps)
    i0 = ps.i
    depth = 0
    while !_eof(ps)
        # stop if at top-level 'and'/'or' (word-bounded) or ')'
        if depth == 0 && (_peek_kw(ps, "and") || _peek_kw(ps, "or"))
            break
        end
        c = _peek(ps)
        if c == '('
            depth += 1
            _consume!(ps,1)
        elseif c == ')'
            if depth == 0
                break
            else
                depth -= 1
                _consume!(ps,1)
            end
        else
            _consume!(ps,1)
        end
    end
    return strip(ps.s[i0:ps.i-1])
end

# Decide if a chunk is just a bare identifier
const _IDENT_RE = r"^[A-Za-z_][A-Za-z0-9_]*$"

# ---- State formula parsing: precedence NOT > AND > OR ----
function _parse_state!(ps::_PS, constraint_parser::Function)::State_Formula
    return _parse_state_or!(ps, constraint_parser)
end
function _parse_state_or!(ps::_PS, constraint_parser::Function)::State_Formula
    left = _parse_state_and!(ps, constraint_parser)
    while true
        if _match_kw!(ps, "or")
            right = _parse_state_and!(ps, constraint_parser)
            left = State_Or(left, right)
        else
            break
        end
    end
    return left
end
function _parse_state_and!(ps::_PS, constraint_parser::Function)::State_Formula
    left = _parse_state_not!(ps, constraint_parser)
    while true
        if _match_kw!(ps, "and")
            right = _parse_state_not!(ps, constraint_parser)
            left = State_And(left, right)
        else
            break
        end
    end
    return left
end
function _parse_state_not!(ps::_PS, constraint_parser::Function)::State_Formula
    if _match_kw!(ps, "not")
        return State_Not(_parse_state_not!(ps, constraint_parser))
    else
        return _parse_state_atom!(ps, constraint_parser)
    end
end

function _parse_state_atom!(ps::_PS, constraint_parser::Function)::State_Formula
    _skipws!(ps)
    if _match_char!(ps, '(')
        inner = _parse_state!(ps, constraint_parser)
        _skipws!(ps)
        _match_char!(ps, ')') || error("Expected ')'")
        return inner
    end
    # true/false
    if _match_kw!(ps, "true");  return State_Truth(true)  end
    if _match_kw!(ps, "false"); return State_Truth(false) end
    # either bare identifier (location) OR a constraint chunk
    chunk = _read_until_boundary!(ps)
    isempty(chunk) && error("Expected state atom")
    if occursin(_IDENT_RE, chunk)
        return State_Location(Symbol(chunk))
    else
        return State_Constraint(constraint_parser(chunk))
    end
end

# ---- Strategy formula parsing: precedence NOT > AND > OR ----
function _parse_strategy!(ps::_PS, constraint_parser::Function)::Strategy_Formula
    return _parse_strategy_or!(ps, constraint_parser)
end
function _parse_strategy_or!(ps::_PS, constraint_parser::Function)::Strategy_Formula
    left = _parse_strategy_and!(ps, constraint_parser)
    while true
        if _match_kw!(ps, "or")
            right = _parse_strategy_and!(ps, constraint_parser)
            left = Strategy_Or(left, right)
        else
            break
        end
    end
    return left
end
function _parse_strategy_and!(ps::_PS, constraint_parser::Function)::Strategy_Formula
    left = _parse_strategy_not!(ps, constraint_parser)
    while true
        if _match_kw!(ps, "and")
            right = _parse_strategy_not!(ps, constraint_parser)
            left = Strategy_And(left, right)
        else
            break
        end
    end
    return left
end
function _parse_strategy_not!(ps::_PS, constraint_parser::Function)::Strategy_Formula
    if _match_kw!(ps, "not")
        return Strategy_Not(_parse_strategy_not!(ps, constraint_parser))
    else
        return _parse_strategy_atom!(ps, constraint_parser)
    end
end

function _parse_strategy_atom!(ps::_PS, constraint_parser::Function)::Strategy_Formula
    _skipws!(ps)
    # parenthesized strategy
    if _match_char!(ps, '(')
        inner = _parse_strategy!(ps, constraint_parser)
        _skipws!(ps)
        _match_char!(ps, ')') || error("Expected ')'")
        return inner
    end
    # <A>F p / <A>G p
    if _match_char!(ps, '<')
        agents = _parse_agents!(ps, '>')
        _skipws!(ps)
        if _match_kw!(ps, "F")
            p = _parse_state!(ps, constraint_parser)
            return Exist_Eventually(agents, p)
        elseif _match_kw!(ps, "G")
            p = _parse_state!(ps, constraint_parser)
            return Exist_Always(agents, p)
        else
            error("Expected 'F' or 'G' after '<A>'")
        end
    end
    # [A]F p / [A]G p
    if _match_char!(ps, '[')
        agents = _parse_agents!(ps, ']')
        _skipws!(ps)
        if _match_kw!(ps, "F")
            p = _parse_state!(ps, constraint_parser)
            return All_Eventually(agents, p)
        elseif _match_kw!(ps, "G")
            p = _parse_state!(ps, constraint_parser)
            return All_Always(agents, p)
        else
            error("Expected 'F' or 'G' after '[A]'")
        end
    end
    # fallback: a state formula promoted to strategy via Strategy_to_State
    p = _parse_state!(ps, constraint_parser)
    return Strategy_to_State(p)
end

"""
    parse_logic(input::AbstractString; constraint_parser=_DEFAULT_CONS_PARSER) :: Strategy_Formula

Parse a strategy formula `s` per grammar:
  s ::= not s | s or s | s and s | <A>F p | <A>G p | [A]F p | [A]G p | p
  p ::= loc | cons | not p | p or p | p and p

- Agents A are comma-separated: e.g. `<a,b>F (x<=3 and y>0)`.
- `loc` is a bare identifier (e.g., `home`, `s1`).
- `cons` is any non-bare-identifier chunk (e.g., `x<=3`, `x+y<z`), parsed by `constraint_parser`.
"""
function parse_logic(input::AbstractString; constraint_parser::Function=_DEFAULT_CONS_PARSER)::Strategy_Formula
    ps = _PS(input, firstindex(input))
    out = _parse_strategy!(ps, constraint_parser)
    _skipws!(ps)
    if !_eof(ps)
        error("Unexpected trailing input at position $(ps.i): \"$(input[ps.i:end])\"")
    end
    return out
end

# ------------------- Examples -------------------
# Implement your own:
# parse_constraint(s::AbstractString)::Constraint = ...
#
# Example usage (with a fake minimal struct/constructor for demo):
# struct Constraint; expr::String; end
# my_cons_parser(s) = Constraint(s)
# f = parse_logic("<a,b>F (loc1 and x<=5 or not loc2)", constraint_parser=parse_constraint)
# g1 = parse_logic("<a,b>F (loc1 and x<=5 && y<=3 or not loc2)", constraint_parser=parse_constraint)
# g2 = parse_logic("x<=5 && y<=3 and <a,b>F (loc1 and x<=5 && y<=3 or not loc2)", constraint_parser=parse_constraint)
# g3 = parse_logic("x<=5 && y<=3 and <a,b>F (loc1 and x<=5 && y<=3 or not loc2) or not loc3", constraint_parser=parse_constraint)
g4 = parse_logic("x<=5 && y<=3 and <a,b>F (loc1 and x<=5 && y<=3 or not loc3) or not [a]G loc3", constraint_parser=parse_constraint)

# println(f)
# println(g1)
# println(g2)
# println(g3)
# println(g4)
