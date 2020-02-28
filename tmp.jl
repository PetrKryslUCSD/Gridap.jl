module Tmp

using Gridap
using Gridap.Arrays
using Gridap.Geometry
using Gridap.FESpaces
using Gridap.ReferenceFEs
import Gridap: ∇
using LinearAlgebra: tr

# Analytical functions

u(x) = VectorValue( x[1]^2 + 2*x[2]^2, -x[1]^2 )
∇u(x) = TensorValue( 2*x[1], 4*x[2], -2*x[1], zero(x[1]) )
Δu(x) = VectorValue( 6, -2 )

p(x) = x[1] + 3*x[2]
∇p(x) = VectorValue(1,3)

s(x) = -Δu(x)
f(x) = -Δu(x) + ∇p(x)
g(x) = tr(∇u(x))

∇(::typeof(u)) = ∇u
∇(::typeof(p)) = ∇p

# Geometry + Integration

n = 20
mesh = (n,n)
domain = 2 .* (0,1,0,1) .- 1
order = 1
model = CartesianDiscreteModel(domain, mesh)

labels = get_face_labeling(model)
add_tag_from_tags!(labels,"dirichlet",[1,2,5])
add_tag_from_tags!(labels,"neumann",[6,7,8])

trian = Triangulation(model)

const R = 0.4

function is_in(coords)
  n = length(coords)
  x = (1/n)*sum(coords)
  d = x[1]^2 + x[2]^2 - R^2
  d < 0
end

oldcell_to_coods = get_cell_coordinates(trian)
oldcell_to_is_solid = collect1d(apply(is_in,oldcell_to_coods))
oldcell_to_is_fluid = Vector{Bool}(.! oldcell_to_is_solid)

trian_solid = RestrictedTriangulation(trian, oldcell_to_is_solid)
trian_fluid = RestrictedTriangulation(trian, oldcell_to_is_fluid)

order = 2

degree = 2*order
quad_solid = CellQuadrature(trian_solid,degree)
quad_fluid = CellQuadrature(trian_fluid,degree)

btrian = BoundaryTriangulation(model,labels,"neumann")
bdegree = 2*order
bquad = CellQuadrature(btrian,bdegree)
n = get_normal_vector(btrian)

# FESpaces

V = TestFESpace(
  model=model,
  valuetype=VectorValue{2,Float64},
  reffe=:QLagrangian,
  order=order,
  conformity =:H1,
  dirichlet_tags="dirichlet")

# TODO better user API
reffes = [PDiscRefFE(Float64,get_polytope(p),order-1) for p in get_reffes(trian_fluid)]
Q_fluid = DiscontinuousFESpace(reffes,trian_fluid)
Q = ExtendedFESpace(Q_fluid,trian_fluid)

U = TrialFESpace(V,u)
P = TrialFESpace(Q)

Y = MultiFieldFESpace([V,Q])
X = MultiFieldFESpace([U,P])

# FE problem

function a_solid(x,y)
  u,p = x
  v,q = y
  inner(∇(v),∇(u))
end

function l_solid(y)
  v,q = y
  v*s
end

function a_fluid(x,y)
  u,p = x
  v,q = y
  inner(∇(v),∇(u)) - (∇*v)*p + q*(∇*u)
end

function l_fluid(y)
  v,q = y
  v*f + q*g
end

function l_Γ_fluid(y)
  v,q = y
  v*(n*∇u) - (n*v)*p
end

t_Ω_solid = AffineFETerm(a_solid,l_solid,trian_solid,quad_solid)
t_Ω_fluid = AffineFETerm(a_fluid,l_fluid,trian_fluid,quad_fluid)
t_Γ_fluid = FESource(l_Γ_fluid,btrian,bquad)

op = AffineFEOperator(X,Y,t_Ω_solid,t_Ω_fluid,t_Γ_fluid)
uh, ph = solve(op)

# Visualization

ph_fluid = restrict(ph, trian_fluid)
writevtk(trian_fluid,"trian_fluid",cellfields=["ph"=>ph_fluid])
writevtk(trian,"trian", cellfields=["uh" => uh])

end # module
