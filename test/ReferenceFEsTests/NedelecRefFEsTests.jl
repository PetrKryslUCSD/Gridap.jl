module NedelecRefFEsTest

using Test
using Gridap.Polynomials
using Gridap.Fields
using Gridap.TensorValues
using Gridap.Fields: MockField
using Gridap.ReferenceFEs

p = QUAD
D = num_dims(QUAD)
et = Float64
order = 0

reffe = NedelecRefFE(et,p,order)
test_reference_fe(reffe)
@test num_terms(get_prebasis(reffe)) == 4
@test get_order(get_prebasis(reffe)) == 0
@test num_dofs(reffe) == 4

@test get_default_conformity(reffe) == CurlConformity()

p = QUAD
D = num_dims(QUAD)
et = Float64
order = 1

reffe = NedelecRefFE(et,p,order)
test_reference_fe(reffe)
@test num_terms(get_prebasis(reffe)) == 12
@test num_dofs(reffe) == 12
@test get_order(get_prebasis(reffe)) == 1

prebasis = get_prebasis(reffe)
dof_basis = get_dof_basis(reffe)

v = VectorValue(3.0,0.0)
field = MockField{D}(v)

cache = dof_cache(dof_basis,field)
r = evaluate_dof!(cache, dof_basis, field)
test_dof(dof_basis,field,r)

cache = dof_cache(dof_basis,prebasis)
r = evaluate_dof!(cache, dof_basis, prebasis)
test_dof(dof_basis,prebasis,r)

end # module
