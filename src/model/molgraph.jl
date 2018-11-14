#
# This file is a part of graphmol.jl
# Licensed under the MIT License http://opensource.org/licenses/MIT
#

export
    AbstractMolecule,
    AbstractMutableMolecule,
    Annotation,
    Molecule,
    MutableMolecule,
    nullmol,
    getatom,
    getbond,
    neighbors,
    neighborcount,
    degree,
    atomcount,
    bondcount,
    updateatom!,
    updatebond!,
    required_annotation

import ..Graph: neighbors, neighborcount


abstract type AbstractMolecule end
abstract type AbstractMutableMolecule <: AbstractMolecule end
abstract type Annotation end


struct MutableMolecule <: AbstractMutableMolecule
    graph::MutableUDGraph{Atom,Bond}
    annotation::Dict{Symbol, Annotation}
    attribute::Dict

    function MutableMolecule()
        new(MutableUDGraph{Atom,Bond}(), Dict(), Dict())
    end
end

function MutableMolecule(nodes::Vector{Atom}, edges::Vector{Bond})
    mol = MutableMolecule()
    for (i, a) in enumerate(nodes)
        updateatom!(mol, a, i)
    end
    for (i, b) in enumerate(edges)
        updatebond!(mol, b, i)
    end
    mol
end


struct Molecule <: AbstractMolecule
    graph::UDGraph{Atom,Bond}
    v::Dict{Symbol, Array}
    annotation::Dict{Symbol, Annotation}
    attribute::Dict
end

function Molecule(mol::MutableMolecule)
    Molecule(UDGraph(mol.graph), Dict(), mol.annotation, mol.attribute)
end

function Molecule(nodes::Vector{Atom}, edges::Vector{Bond})
    # do not use `fill`
    adj = [Dict() for i in 1:length(nodes)]
    for (i, e) in enumerate(edges)
        adj[e.u][e.v] = i
        adj[e.v][e.u] = i
    end
    graph = UDGraph{Atom,Bond}(nodes, edges, adj)
    Molecule(graph, Dict(), Dict(), Dict())
end


nullmol() = Molecule(Vector{Atom}[], Vector{Bond}[])


getatom(mol::AbstractMolecule, idx) = getnode(mol.graph, idx)

getbond(mol::AbstractMolecule, u, v) = getedge(mol.graph, u, v)
getbond(mol::AbstractMolecule, idx) = getedge(mol.graph, idx)

neighbors(mol::AbstractMolecule, idx) = neighbors(mol.graph, idx)

atomcount(mol::AbstractMolecule) = nodecount(mol.graph)
bondcount(mol::AbstractMolecule) = edgecount(mol.graph)

neighborcount(mol::AbstractMolecule, idx) = length(neighbors(mol.graph, idx))
degree = neighborcount

function updateatom!(mol::AbstractMutableMolecule, atom, idx)
    updatenode!(mol.graph, atom, idx)
end


function updatebond!(mol::AbstractMutableMolecule, bond, idx)
    updateedge!(mol.graph, bond, idx)
end

updatebond!(m::AbstractMutableMolecule, bond, u, v) = updatedge!(m.graph, bond, u, v)


function unlinkatom!(mol::AbstractMutableMolecule, idx)
    unlinknode!(mol.graph, idx)
end


function unlinkbond!(mol::AbstractMutableMolecule, idx)
    unlinkedge!(mol.graph, idx)
end

function unlinkbond!(mol::AbstractMutableMolecule, u, v)
    unlinkedge!(mol.graph, u, v)
end


function required_annotation(mol::AbstractMolecule, annot)
    if !(annot in keys(mol.annotation))
        throw(ErrorException("$(annot) is not available"))
    end
end
