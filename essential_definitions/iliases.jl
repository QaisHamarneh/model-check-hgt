using DataStructures

const Agent = Symbol
const Action = Symbol
const Variable = Symbol
const Valuation = OrderedDict{Variable, Float64}
const Decision = Pair{Agent, Action}
