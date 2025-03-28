""" Algebra of subobjects in a category.

This module defines the interface for subobjects as well as some generic
algorithm for computing subobjects using limits and colimits. Concrete instances
such as subsets (subobjects in Set or FinSet) and sub-C-sets (subobjects in
C-Set) are defined elsewhere.
"""
module Subobjects
export Subobject, ob, hom, SubOpAlgorithm, SubOpWithLimits,
  meet, ∧, join, ∨, top, ⊤, bottom, ⊥,
  implies, ⟹, subtract, \, negate, ¬, non, ~

import Base: \, ~
using AutoHashEquals
using StaticArrays: SVector

using ...GAT, ...Theories, ..Limits
import ...Theories: ob, hom, meet, ∧, join, ∨, top, ⊤, bottom, ⊥

# Theories
##########

""" Theory of lattice of subobjects in a coherent category, such as a pretopos.

The axioms are omitted since this theory is the same as the theory
[`Catlab.Theories.AlgebraicLattice`](@ref) except that the lattice elements are
dependent on another type. TODO: It should be possible to define a projection
morphism of GATs from `SubobjectLattice` to `AlgebraicLattice` that sends `Ob`
to the unit type.
"""
@signature SubobjectLattice{Ob,Sub} begin
  Ob::TYPE
  Sub(ob::X)::TYPE

  @op begin
    (∧) := meet
    (∨) := join
    (⊤) := top
    (⊥) := bottom
  end

  meet(A::Sub(X), B::Sub(X))::Sub(X) ⊣ (X::Ob)
  join(A::Sub(X), B::Sub(X))::Sub(X) ⊣ (X::Ob)
  top(X::Ob)::Sub(X)
  bottom(X::Ob)::Sub(X)
end

""" Theory of Heyting algebra of subobjects in a Heyting category, such as a
topos.
"""
@signature SubobjectHeytingAlgebra{Ob,Sub} <: SubobjectLattice{Ob,Sub} begin
  @op begin
    (⟹) := implies
    (¬) := negate
  end

  implies(A::Sub(X), B::Sub(X))::Sub(X) ⊣ (X::Ob)
  negate(A::Sub(X))::Sub(X) ⊣ (X::Ob)
end

""" Theory of bi-Heyting algebra of subobjects in a bi-Heyting topos, such as a
presheaf topos.
"""
@signature SubobjectBiHeytingAlgebra{Ob,Sub} <: SubobjectHeytingAlgebra{Ob,Sub} begin
  @op begin
    (\) := subtract
    (~) := non
  end

  subtract(A::Sub(X), B::Sub(X))::Sub(X) ⊣ (X::Ob)
  non(A::Sub(X))::Sub(X) ⊣ (X::Ob)
end

# Data types
############

""" Subobject in a category.

By definition, a subobject of an object ``X`` in a category is a monomorphism
into ``X``. This is the default representation of a subobject. Certain
categories may support additional representations. For example, if the category
has a subobject classifier ``Ω``, then subobjects of ``X`` are also morphisms
``X → Ω``.
"""
abstract type Subobject{Ob} end

# Default constructor for subobjects assumes a morphism representation.
Subobject(hom) = SubobjectHom(hom)

@auto_hash_equals struct SubobjectHom{Ob,Hom} <: Subobject{Ob}
  hom::Hom
  SubobjectHom(hom::Hom) where Hom = new{typeof(codom(hom)),Hom}(hom)
end

hom(sub::SubobjectHom) = sub.hom
ob(sub::SubobjectHom) = codom(hom(sub))

# Algorithms
############

""" Abstract type for algorithm to compute operation(s) on subobjects.
"""
abstract type SubOpAlgorithm end

""" Algorithm to compute subobject operations using limits and/or colimits.
"""
struct SubOpWithLimits <: SubOpAlgorithm end

""" Meet (intersection) of subobjects.
"""
function meet(A::Subobject, B::Subobject, ::SubOpWithLimits)
  meet(SVector(A,B), SubOpWithLimits())
end
function meet(As::AbstractVector{<:Subobject}, ::SubOpWithLimits)
  fs = map(hom, As)
  lim = pullback(fs)
  Subobject(compose(first(legs(lim)), first(fs))) # Arbitrarily use first leg.
end

""" Join (union) of subobjects.
"""
function join(A::Subobject, B::Subobject, ::SubOpWithLimits)
  join(SVector(A,B), SubOpWithLimits())
end
function join(As::AbstractVector{<:Subobject}, ::SubOpWithLimits)
  fs = map(hom, As)
  lim = pullback(fs)
  colim = pushout(legs(lim))
  Subobject(copair(colim, fs))
end

""" Top (full) subobject.
"""
top(X, ::SubOpWithLimits) = Subobject(id(X))

""" Bottom (empty) subobject.
"""
bottom(X::T, ::SubOpWithLimits) where T = Subobject(create(initial(T), X))

end
