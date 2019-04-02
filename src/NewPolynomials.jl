module NewPolynomials

using Numa #@fverdugo to be eliminated
using Numa.Helpers
using Numa.FieldValues

"""
Abstract type representing a multivariate polynomial basis
with value of type T in a coordinate space of D dimensions
"""
abstract type MultivariatePolynomialBasis{D,T} end

Base.length(::MultivariatePolynomialBasis)::Int = @abstractmethod

"""
First axis of v for dofs, second for points
"""
evaluate!(::MultivariatePolynomialBasis{D,T},::AbstractVector{Point{D}},v::AbstractArray{T,2}) where {D,T} = @abstractmethod

"""
Same as evaluate! but allocates output
"""
function evaluate(self::MultivariatePolynomialBasis{D,T},points::AbstractArray{Point{D},1}) where {D,T}
  vals = Array{T,2}(undef,(length(self),length(points)))
  evaluate!(self,points,vals)
  vals
end

"""
Object that represents the gradient of the elements of a basis
"""
struct GradMultivariatePolynomialBasis{D,TG,T,B<:MultivariatePolynomialBasis{D,T}} <: MultivariatePolynomialBasis{D,TG}
  basis::B
end

"""
evaluate! overwritten for gradients of bases
"""
function evaluate(self::MultivariatePolynomialBasis{D,T},points::AbstractArray{Point{D},1}) where {D,T}
  vals = Array{T,2}(undef,(length(self),length(points)))
  evaluategradients!(self.basis,points,vals)
  vals
end

"""
Create a `GradMultivariatePolynomialBasis` object from a basis
`MultivariatePolynomialBasis`. The result is a
MultivariatePolynomialBasis{TG,D} where TG is a type whose rank is one unit
greater than the one of T
"""
function gradient(self::MultivariatePolynomialBasis{D,T}) where{D,T}
  TG = outer(Point{D},T)
  B = typeof(self)
  GradMultivariatePolynomialBasis{D,TG,T,B}(self)
end

Base.length(this::GradMultivariatePolynomialBasis)::Int = length(this.basis)

function gradient(::GradMultivariatePolynomialBasis{D,T,B} where{D,T,B})
 @error("Gradient of a gradient not available") end

const ∇ = gradient

Base.:*(::typeof(∇),f) = ∇(f)

"""
Abstract type representing a univariate polynomial basis in dimension one
"""
abstract type UnivariatePolynomialBasis <: MultivariatePolynomialBasis{1,ScalarValue} end

"""
Univariate monomial basis of a given `order`
"""
struct UnivariateMonomialBasis <: UnivariatePolynomialBasis
  order::Int64
end

Base.length(this::UnivariateMonomialBasis)::Int = this.order+1

"""
Alocate and evaluate an array with all the elements of the
a `UnivariateMonomialBasis` evaluated at a set of 1D points. The array axis are
first the basis polynomial index and next the point label
"""
function (this::UnivariateMonomialBasis)(points::AbstractVector{Point{1}})::Array{Float64,2}
  dbas = length(this)
  v = Array{Float64,2}(undef, dbas, length(points))
  evaluate!(this, points, v)
  return v
end

"""
Auxiliary function that does the same as evaluate but using a pre-allocated
array
"""
function evaluate!(this::UnivariateMonomialBasis,
  points::AbstractVector{Point{1}},v::AbstractArray{ScalarValue,2})
  for (j,p) in enumerate(points)
    for i in 1:length(this)
      v[i,j] = p[1]^(i-1)
    end
  end
end

"""
Compute the numder-th derivative of a monomial at a set of 1D points,
returning an array with first axis basis function label, second axis point label
"""
function derivative(this::UnivariateMonomialBasis,
  points::AbstractVector{Point{1}}; numd=1::Int)::Array{VectorValue{1},2}
  dbas = length(this)
  v = Array{VectorValue{1},2}(undef, dbas, length(points))
  for (j,p) ∈ enumerate(points)
    for i in 1:length(this)
      val = (i<=numd) ? 0.0 : prod([i-k-1 for k=0:numd-1])p[1]^(i-numd-1)
      v[i,j] = VectorValue{1}(val)
    end
  end
  return v
end






function evaluategradients!(this::UnivariateMonomialBasis,
  points::AbstractVector{Point{1}},v::AbstractArray{VectorValue{1},2})
  derivative(this, points)
  numd = 1
  for (j,p) ∈ enumerate(points)
    for i in 1:length(this)
      val = (i<=numd) ? 0.0 : prod([i-k-1 for k=0:numd-1])p[1]^(i-numd-1)
      v[i,j] = VectorValue{1}(val)
    end
  end
end









end # module NewPolynomials