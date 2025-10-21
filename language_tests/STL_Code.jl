begin
	¬ = ! # \neg
	∧(a,b) = a && b # \wedge
	∨(a,b) = a || b # \vee
	⟹(p,q) = ¬p ∨ q	# \implies
	⟺(p,q) = (p ⟹ q) ∧ (q ⟹ p)	# \iff
end;

abstract type Formula end

const Interval = Union{UnitRange, Missing}

eventually = @formula 𝒰(xₜ->true, xₜ -> xₜ > 0) # alternate derived form
always = @formula ¬◊(¬(xₜ -> xₜ > 0))

begin
	∧(ϕ1::Formula, ϕ2::Formula) = xᵢ->ϕ1(xᵢ) ∧ ϕ2(xᵢ)
	∨(ϕ1::Formula, ϕ2::Formula) = xᵢ->ϕ1(xᵢ) ∨ ϕ2(xᵢ)
end

Base.map(ϕ::Formula, x::AbstractArray) = map(t->ϕ(x[t:end]), eachindex(x))

robustness(xₜ, ϕ::Formula; w=0) = w == 0 ? ρ(xₜ, ϕ) : ρ̃(xₜ, ϕ; w)

smooth_robustness = ρ̃

begin
	Base.@kwdef struct Atomic <: Formula
		value::Bool
		ρ_bound = value ? Inf : -Inf
	end

	(ϕ::Atomic)(x) = ϕ.value
	ρ(xₜ, ϕ::Atomic) = ϕ.ρ_bound
	ρ̃(xₜ, ϕ::Atomic; kwargs...) = ρ(xₜ, ϕ)
end

⊤ = @formula xₜ -> true
⊥ = @formula xₜ -> false

begin
	Base.@kwdef mutable struct AtomicFunction <: Formula
		f::Function # ℝⁿ → 𝔹
		ρ_max = Inf
	end

	(ϕ::AtomicFunction)(x) = map(xₜ->all(xₜ), ϕ.f(x))
	ρ(xₜ, ϕ::AtomicFunction) = xₜ ? ϕ.ρ_max : -ϕ.ρ_max
	ρ̃(xₜ, ϕ::AtomicFunction; kwargs...) = ρ(xₜ, ϕ)
end

begin
	mutable struct Predicate <: Formula
		μ::Function # ℝⁿ → ℝ
		c::Union{Real, Vector}
	end

	(ϕ::Predicate)(x) = map(xₜ->all(xₜ .> ϕ.c), ϕ.μ(x))
	ρ(x, ϕ::Predicate) = map(xₜ->xₜ - ϕ.c, ϕ.μ(x))
	ρ̃(x, ϕ::Predicate; kwargs...) = ρ(x, ϕ)
end

begin
	mutable struct FlippedPredicate <: Formula
		μ::Function # ℝⁿ → ℝ
		c::Union{Real, Vector}
	end

	(ϕ::FlippedPredicate)(x) = map(xₜ->all(xₜ .< ϕ.c), ϕ.μ(x))
	ρ(x, ϕ::FlippedPredicate) = map(xₜ->ϕ.c - xₜ, ϕ.μ(x))
	ρ̃(x, ϕ::FlippedPredicate; kwargs...) = ρ(x, ϕ)
end

begin
	mutable struct Negation <: Formula
		ϕ_inner::Formula
	end

	(ϕ::Negation)(x) = .¬ϕ.ϕ_inner(x)
	ρ(xₜ, ϕ::Negation) = -ρ(xₜ, ϕ.ϕ_inner)
	ρ̃(xₜ, ϕ::Negation; kwargs...) = -ρ̃(xₜ, ϕ.ϕ_inner; kwargs...)
end

begin
	mutable struct Conjunction <: Formula
		ϕ::Formula
		ψ::Formula
	end
	
	(q::Conjunction)(x) = all(q.ϕ(x) .∧ q.ψ(x))

	ρ(xₜ, q::Conjunction) = min.(ρ(xₜ, q.ϕ), ρ(xₜ, q.ψ))
	ρ̃(xₜ, q::Conjunction; w=W) = smoothmin.(ρ̃(xₜ, q.ϕ), ρ̃(xₜ, q.ψ); w)
end

begin
	mutable struct Disjunction <: Formula
		ϕ::Formula
		ψ::Formula
	end
	
	(q::Disjunction)(x) = any(q.ϕ(x) .∨ q.ψ(x))

	ρ(xₜ, q::Disjunction) = max.(ρ(xₜ, q.ϕ), ρ(xₜ, q.ψ))
	ρ̃(xₜ, q::Disjunction; w=W) = smoothmax.(ρ̃(xₜ, q.ϕ; w), ρ̃(xₜ, q.ψ; w); w)
end

begin
	mutable struct Implication <: Formula
		ϕ::Formula
		ψ::Formula
	end
	
	(q::Implication)(x) = q.ϕ(x) .⟹ q.ψ(x)

	ρ(xₜ, q::Implication) = max.(-ρ(xₜ, q.ϕ), ρ(xₜ, q.ψ))
	ρ̃(xₜ, q::Implication; w=W) = smoothmax.(-ρ̃(xₜ, q.ϕ; w), ρ̃(xₜ, q.ψ; w); w)
end

begin
	mutable struct Biconditional <: Formula
		ϕ::Formula
		ψ::Formula
	end
	
	(q::Biconditional)(x) = q.ϕ(x) .⟺ q.ψ(x)

	ρ(xₜ, q::Biconditional) =
		ρ(xₜ, Conjunction(Implication(q.ϕ, q.ψ), Implication(q.ψ, q.ϕ)))
	ρ̃(xₜ, q::Biconditional; w=W) =
		ρ̃(xₜ, Conjunction(Implication(q.ϕ, q.ψ), Implication(q.ψ, q.ϕ)); w)
end

const TemporalOperator = Union{Eventually, Always, Until}

get_interval(ϕ::Formula, x) = ismissing(ϕ.I) ? (1:length(x)) : ϕ.I

begin
	mutable struct Eventually <: Formula
		ϕ::Formula
		I::Interval
	end

	(◊::Eventually)(x) = any(◊.ϕ(x[t]) for t ∈ get_interval(◊, x))

	ρ(x, ◊::Eventually) = maximum(ρ(x[t′], ◊.ϕ) for t′ ∈ get_interval(◊, x))
	ρ̃(x, ◊::Eventually; w=W) = smoothmax(ρ̃(x[t′], ◊.ϕ; w) for t′∈get_interval(◊,x); w)
end

begin
	mutable struct Always <: Formula
		ϕ::Formula
		I::Interval
	end

	(□::Always)(x) = all(□.ϕ(x[t]) for t ∈ get_interval(□, x))

	ρ(x, □::Always) = minimum(ρ(x[t′], □.ϕ) for t′ ∈ get_interval(□, x))
	ρ̃(x, □::Always; w=W) = smoothmin(ρ̃(x[t′], □.ϕ; w) for t′ ∈ get_interval(□, x); w)
end

begin
	mutable struct Until <: Formula
		ϕ::Formula
		ψ::Formula
		I::Interval
	end

	function (𝒰::Until)(x)
		ϕ, ψ, I = 𝒰.ϕ, 𝒰.ψ, get_interval(𝒰, x)
		return any(ψ(x[i]) && all(ϕ(x[j]) for j ∈ I[1]:i-1) for i ∈ I)
	end

	function ρ(x, 𝒰::Until)
		ϕ, ψ, I = 𝒰.ϕ, 𝒰.ψ, get_interval(𝒰, x)
		return maximum(map(I) do t′
			ρ1 = ρ(x[t′], ψ)
			ρ2_trace = [ρ(x[t′′], ϕ) for t′′ ∈ 1:t′-1]
			ρ2 = isempty(ρ2_trace) ? 10e100 : minimum(ρ2_trace)
			min(ρ1, ρ2)
		end)
	end
	
	function ρ̃(x, 𝒰::Until; w=W)
		ϕ, ψ, I = 𝒰.ϕ, 𝒰.ψ, get_interval(𝒰, x)
		return smoothmax(map(I) do t′
			ρ̃1 = ρ̃(x[t′], ψ; w)
			ρ̃2_trace = [ρ̃(x[t′′], ϕ; w) for t′′ ∈ 1:t′-1]
			ρ̃2 = isempty(ρ̃2_trace) ? 10e100 : smoothmin(ρ̃2_trace; w)
			smoothmin([ρ̃1, ρ̃2]; w)
		end; w)
	end
end

global W = 1

function logsumexp(x)
	m = maximum(x)
	return m + log(sum(exp(xᵢ - m) for xᵢ in x))
end

function _smoothmin(x, w; stable=false)
	if stable
		xw = -x / w
		e = exp.(xw .- logsumexp(xw)) # used for numerical stability
		return sum(x .* e) / sum(e)
	else
		return sum(xᵢ*exp(-xᵢ/w) for xᵢ in x) / sum(exp(-xⱼ/w) for xⱼ in x)
	end
end

smoothmin(x; w=W) = w == 0 ?  minimum(x) : _smoothmin(x, w)
smoothmin(x1, x2; w=W) = smoothmin([x1,x2]; w=w)

function _smoothmax(x, w; stable=false)
	if stable
		xw = x / w
		e = exp.(xw .- logsumexp(xw)) # used for numerical stability
		return sum(x .* e) / sum(e)
	else
		return sum(xᵢ*exp(xᵢ/w) for xᵢ in x) / sum(exp(xⱼ/w) for xⱼ in x)
	end
end

smoothmax(x; w=W) = w == 0 ? maximum(x) : _smoothmax(x, w)
smoothmax(x1, x2; w=W) = smoothmax([x1,x2]; w=w)