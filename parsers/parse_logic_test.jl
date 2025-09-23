include("parse_constraint.jl")
include("../STL/logic.jl")

# --------- Parser (assumes your types + parse_constraint are defined) ----------
mutable struct _PS
    s::String
    i::Int
end

_eof(ps::_PS) = ps.i > lastindex(ps.s)
function _skipws!(ps::_PS)
    while !_eof(ps) && isspace(ps.s[ps.i]); ps.i += 1; end
end
_peek(ps::_PS) = _eof(ps) ? '\0' : ps.s[ps.i]
function _consume!(ps::_PS, n::Int=1); ps.i = min(lastindex(ps.s)+1, ps.i + n); end

# word-bounded keyword (not/and/or/F/G)
function _match_kw!(ps::_PS, kw::AbstractString)
    _skipws!(ps)
    i0 = ps.i
    for c in kw
        if _eof(ps) || _peek(ps) != c; ps.i = i0; return false; end
        _consume!(ps,1)
    end
    if !_eof(ps)
        c = _peek(ps)
        if isletter(c) || isdigit(c) || c == '_'
            ps.i = i0
            return false
        end
    end
    return true
end

# match/peek exact string token (e.g., "<<", ">>", "[[", "]]")
function _match_str!(ps::_PS, t::AbstractString)
    _skipws!(ps)
    i0 = ps.i
    for c in t
        if _eof(ps) || _peek(ps) != c; ps.i = i0; return false; end
        _consume!(ps,1)
    end
    return true
end
function _peek_str(ps::_PS, t::AbstractString)
    i0 = ps.i
    ok = _match_str!(ps, t)
    ps.i = i0
    return ok
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
        if isletter(c) || isdigit(c) || c == '_'; _consume!(ps,1)
        else; break
        end
    end
    return ps.s[i0:ps.i-1]
end

# parse agents until the given closing token (">>" or "]]"), comma-separated
function _parse_agents_until!(ps::_PS, closing::AbstractString)
    _skipws!(ps)
    names = String[]
    buf = IOBuffer()
    while !_eof(ps) && !_peek_str(ps, closing)
        c = _peek(ps)
        if c == ','
            name = strip(String(take!(buf)))
            if !isempty(name); push!(names, name); end
            _consume!(ps,1)
        else
            write(buf, c); _consume!(ps,1)
        end
    end
    _match_str!(ps, closing) || error("Expected \"$closing\" to close agents list")
    lastn = strip(String(take!(buf)))
    if !isempty(lastn); push!(names, lastn); end

    syms = Symbol[]
    for n in names
        for part in split(n, r"\s+")
            if !isempty(part); push!(syms, Symbol(part)); end
        end
    end
    return Set(syms)
end

# read state atom chunk until top-level boundary (and/or/) or ')'
function _read_until_boundary!(ps::_PS)
    _skipws!(ps)
    i0 = ps.i
    depth = 0
    while !_eof(ps)
        # stop on top-level "and"/"or" or right paren
        if depth == 0 && (_match_kw!(ps, "and") || _match_kw!(ps, "or"))
            ps.i -= 0 # we've consumed; roll back to start of kw
            # undo: move back length of matched kw (but easier: reset and re-scan)
            # Simpler: back up to start by re-finding last word: we can just return chunk up to kw start.
            # Because we consumed, we need a reliable approach:
        end
        # Re-implement with peeking to avoid consumption:
        if depth == 0 && ( (_peek_word(ps, "and") || _peek_word(ps, "or")) ); break; end
        c = _peek(ps)
        if c == '('; depth += 1; _consume!(ps,1)
        elseif c == ')'
            if depth == 0; break
            else depth -= 1; _consume!(ps,1); end
        else; _consume!(ps,1)
        end
    end
    return strip(ps.s[i0:ps.i-1])
end

# helper to peek word-bounded keyword without consuming
function _peek_word(ps::_PS, kw::AbstractString)
    i0 = ps.i
    ok = _match_kw!(ps, kw)
    ps.i = i0
    return ok
end

const _IDENT_RE = r"^[A-Za-z_][A-Za-z0-9_]*$"

# -------- State formula (NOT > AND > OR) --------
_parse_state!(ps::_PS)::State_Formula = _parse_state_or!(ps)
function _parse_state_or!(ps::_PS)::State_Formula
    left = _parse_state_and!(ps)
    while _match_kw!(ps, "or")
        right = _parse_state_and!(ps)
        left = State_Or(left, right)
    end
    return left
end
function _parse_state_and!(ps::_PS)::State_Formula
    left = _parse_state_not!(ps)
    while _match_kw!(ps, "and")
        right = _parse_state_not!(ps)
        left = State_And(left, right)
    end
    return left
end
function _parse_state_not!(ps::_PS)::State_Formula
    if _match_kw!(ps, "not")
        return State_Not(_parse_state_not!(ps))
    else
        return _parse_state_atom!(ps)
    end
end

function _parse_state_atom!(ps::_PS)::State_Formula
    _skipws!(ps)
    if !_eof(ps) && _peek(ps) == '('
        _consume!(ps,1)
        inner = _parse_state!(ps)
        _skipws!(ps); _match_str!(ps, ")") || error("Expected ')'")
        return inner
    end
    if _match_kw!(ps, "true");  return State_Truth(true)  end
    if _match_kw!(ps, "false"); return State_Truth(false) end

    # Bare identifier => location, anything else => constraint via your parse_constraint(...)
    chunk = begin
        # re-implement boundary scan non-destructively
        _skipws!(ps)
        i0 = ps.i
        depth = 0
        while !_eof(ps)
            if depth == 0 && (_peek_word(ps, "and") || _peek_word(ps, "or") || _peek(ps) == ')'); break; end
            c = _peek(ps)
            if c == '('; depth += 1; _consume!(ps,1)
            elseif c == ')'
                if depth == 0; break; else depth -= 1; _consume!(ps,1) end
            else; _consume!(ps,1)
            end
        end
        strip(ps.s[i0:ps.i-1])
    end
    isempty(chunk) && error("Expected state atom")
    if occursin(_IDENT_RE, chunk)
        return State_Location(Symbol(chunk))
    else
        # Calls user's parse_constraint(::AbstractString)::Constraint
        return State_Constraint(parse_constraint(chunk))
    end
end

# -------- Strategy formula (NOT > AND > OR) --------
_parse_strategy!(ps::_PS)::Strategy_Formula = _parse_strategy_or!(ps)
function _parse_strategy_or!(ps::_PS)::Strategy_Formula
    left = _parse_strategy_and!(ps)
    while _match_kw!(ps, "or")
        right = _parse_strategy_and!(ps)
        left = Strategy_Or(left, right)
    end
    return left
end
function _parse_strategy_and!(ps::_PS)::Strategy_Formula
    left = _parse_strategy_not!(ps)
    while _match_kw!(ps, "and")
        right = _parse_strategy_not!(ps)
        left = Strategy_And(left, right)
    end
    return left
end
function _parse_strategy_not!(ps::_PS)::Strategy_Formula
    if _match_kw!(ps, "not")
        return Strategy_Not(_parse_strategy_not!(ps))
    else
        return _parse_strategy_atom!(ps)
    end
end

function _parse_strategy_atom!(ps::_PS)::Strategy_Formula
    _skipws!(ps)
    # parenthesized strategy
    if !_eof(ps) && _peek(ps) == '('
        _consume!(ps,1)
        inner = _parse_strategy!(ps)
        _skipws!(ps); _match_str!(ps, ")") || error("Expected ')'")
        return inner
    end

    # <<A>>F p / <<A>>G p
    if _match_str!(ps, "<<")
        agents = _parse_agents_until!(ps, ">>")
        _skipws!(ps)
        if _match_kw!(ps, "F")
            return Exist_Eventually(agents, _parse_state!(ps))
        elseif _match_kw!(ps, "G")
            return Exist_Always(agents, _parse_state!(ps))
        else
            error("Expected 'F' or 'G' after '<<A>>'")
        end
    end

    # [[A]]F p / [[A]]G p
    if _match_str!(ps, "[[")
        agents = _parse_agents_until!(ps, "]]")
        _skipws!(ps)
        if _match_kw!(ps, "F")
            return All_Eventually(agents, _parse_state!(ps))
        elseif _match_kw!(ps, "G")
            return All_Always(agents, _parse_state!(ps))
        else
            error("Expected 'F' or 'G' after '[[A]]'")
        end
    end

    # fallback: promote state formula to strategy
    return Strategy_to_State(_parse_state!(ps))
end

"""
    parse_logic(input::AbstractString) :: Strategy_Formula

Grammar:
  s ::= not s | s or s | s and s | s imply s | <<A>>F p | <<A>>G p | [[A]]F p | [[A]]G p | p
  p ::= loc | cons

- Agents A are comma-separated identifiers inside `<< >>` or `[[ ]]`, e.g. `<<a,b>>F (...)`.
- `loc` is a bare identifier; everything else is a `cons` parsed by your `parse_constraint`.
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
# parse_constraint(s) = Constraint(s)  # your real one here
f = parse_logic("<<a,b>>F (loc1 and x<=5)")

# Example usage (with a fake minimal struct/constructor for demo):
# struct Constraint; expr::String; end
# my_cons_parser(s) = Constraint(s)
g = parse_logic("<<a,b>>F (loc1 and x<=5 or not loc2)")
g0 = parse_logic("[[a,b]]F (loc1 and x<=5 && y<=3 or not loc2)")
g2 = parse_logic("x<=5 && y<=3 and <<a,b>>F (loc5 and x<=5 && y<=3 or not loc2)")
# g3 = parse_logic("x<=5 && y<=3 and <a,b>F (loc1 and x<=5 && y<=3 or not loc2) or not loc3", constraint_parser=parse_constraint)
# g4 = parse_logic("x<=5 && y<=3 and <a,b>F (loc1 and x<=5 && y<=3 or not loc3) or not [a]G loc3", constraint_parser=parse_constraint)

println(f)
println(g)
println(g0)
println(g2)
# println(g3)
# println(g4)
