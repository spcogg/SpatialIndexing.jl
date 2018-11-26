"""
Find `Leaf` in the `node` subtree by the `id` and `br` MBR of one of its `Elem`s.

Returns the tuple of `Leaf` and element position or `nothing`.
"""
function findleaf(node::Leaf{T,N}, reg::Region{T,N}, id::Any) where {T,N}
    for (i, el) in enumerate(children(node))
        if isequal_rtree(el, reg, id)
            return (node, i)
        end
    end
    return nothing
end

function findleaf(node::Branch{T,N,V}, reg::Region{T,N}, id::Any) where {T,N,V}
    for child in children(node)
        if contains(mbr(child), reg)
            res = findleaf(child, reg, id)
            if res !== nothing
                return res::Tuple{Leaf{T,N,V}, Int}
            end
        end
    end
    return nothing
end

findleaf(rtree::RTree{T,N}, reg::Region{T,N}, id::Any = nothing) where {T,N} =
    findleaf(rtree.root, reg, id)

# FIXME: currently isempty() doesn't allow specifying how
#        to treat overlapping elements (inside or not), currently treated as outside
"""
    isempty(tree::RTree, region::Region)

Check if there are `tree` elements inside `region`.
"""
Base.isempty(tree::RTree{T,N}, region::Region{T,N}) where {T,N} =
    _isempty(tree.root, region)

function _isempty(node::Node, region::Region{T,N}) where {T,N}
    isempty(node) && return true
    nodebr = mbr(node)
    if in(nodebr, region) # there are elements inside rect
        return false
    elseif intersects(nodebr, region) # there could be node elements inside region
        for child in children(node)
            if node isa Branch # should be optimized out at compile time
                _isempty(child, region) || return false
            elseif node isa Leaf
                in(mbr(child), region) && return false
            end
        end
    end
    return true
end

#=
TODO

struct RTreeRegionQueryIterator{T,N,K,TT,R} <: SpatialQuery{T,N,K}
    tree::TT
    region::R

    function RTreeRegionQueryIterator{T,N}(kind::QueryKind, tree::TT, region::R) where
        {T, N, TT <: RTree{T,N}, R <: Region{T,N}}
        new{T,N,kind,TT,R}(tree, region)
    end
end

contained_in(tree::RTree{T,N}, region::Region{T,N}) where {T,N} =
    RTreeRegionQueryIterator{T,N}(QueryContainedIn, tree, region)

intersects_with(tree::RTree{T,N}, region::Region{T,N}) where {T,N} =
    RTreeRegionQueryIterator{T,N}(QueryIntersectsWith, tree, region)

querytype(iter::RTreeRegionQueryIterator{<:Any,<:Any,K}) where K = K

isok(iter::TreeRegionQueryIterator{T,N}, node::Any) where {T,N} =
    intersects(iter.region, mbr(node))

isok(iter::RTreeRegionQueryIterator{<:Any,<:Any,QueryContainedIn}, el::Any) =
    contains(iter.region, mbr(node))

struct RTreeRegionQueryIteratorState{T,N,Y}
    subtree::Vector{Node{T,N}}
end

function next(iter::RTreeRegionQueryIterator{T,N},
              state::RTreeRegionQueryIteratorState{T, N})
    isempty(state.subtree) && return nothing
end

function Base.iterate(iter::RTreeRegionQueryIterator)
    # no root or doesn't intersect at all
    iter.tree.root !== nothing || !isok(iter, iter.tree.root) || return nothing
    subtree = push!(Vector{Node{T,N}}(), tree.root) # start with the root
    return iterate(iter, RTreeRegionQueryIteratorState(subtree))
end

function Base.iterate(iter::RTreeRegionQueryIterator{T,N},
                      state::RTreeRegionQueryIteratorState{T,N})
    isempty(state.subtree) && return nothing
    node = pop!(state.subtree)

    node = next(iter, state)
    if node === nothing
          return nothing
      else
          return (node, state)
      end
end
=#