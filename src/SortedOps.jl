"""
A collection of set routines for ordered data. Exported methods are
`sorted_union`, `sorted_intersection`, and `sorted_setdiff`. The expectation
is that the two input arrays will be in sorted order with no redundant elements.

The output of each of these methods will be a sorted array with no redundant
elements.
"""
module SortedOps

export   sorted_union, sorted_intersect, sorted_setdiff

function sorted_union(a::Vector{T}, b::Vector{T}) where T

   # Quick optimization for empty arrays
   length(a) == 0 && return b
   length(b) == 0 && return a

   # Pre-allocate for efficiency.
   z = T[]
   sizehint!(z, length(a) + length(b))

   # Index Pointers
   i = 1 # Pointer for a
   j = 1 # Pointer for b

   while true
      if a[i] < b[j]
         push!(z, a[i])
         i += 1
         i > length(a) && (append!(z, b[j:end]); break)
      elseif a[i] == b[j]
         push!(z, a[i])
         i += 1
         j += 1
         if i > length(a) && j > length(b)
            break
         elseif i > length(a)
            append!(z, b[j:end])
            break
         elseif j > length(b)
            append!(z, a[i:end])
            break
         end
      else
         push!(z, b[j])
         j += 1
         j > length(b) && (append!(z, a[i:end]); break)
      end
   end
   return z
end

function sorted_intersect(a::Vector{T}, b::Vector{T}) where T
   # Check for Empty Sets
   length(a) == 0 && return a
   length(b) == 0 && return b

   # Pre-allocate for efficiency
   z = T[]
   sizehint!(z, min(length(a), length(b)))

   # Index Pointers
   i = 1 # Pointer for a
   j = 1 # Pointer for b

   while true
      if a[i] < b[j]
         i += 1
         i > length(a) && break
      elseif a[i] == b[j]
         push!(z, a[i])
         i += 1
         j += 1
         (i > length(a) || j > length(b)) && break
      else
         j += 1
         j > length(b) && break
      end
   end

   return z
end

function sorted_setdiff(a::Vector{T}, b::Vector{T}) where T
   # Check Empty Sets
   length(a) == 0 && return a
   length(b) == 0 && return a

   # Pre-allocate for efficiency.
   z = T[]
   sizehint!(z, length(a))

   # Index Pointers
   i = 1 # Pointer for a
   j = 1 # Pointer for b
   while true
      if a[i] < b[j]
         push!(z, a[i])
         i += 1
         i > length(a) && break
      elseif a[i] == b[j]
         i += 1
         j += 1
         i > length(a) && break
         j > length(b) && (append!(z, a[i:end]); break)
      else
         j += 1
         j > length(b) && (append!(z, a[i:end]); break)
      end
   end

   return z
end

end#module
