"""
Replacement module for SortedOps testing the built-in union, intersect, and
setdiff methods.
"""
module SortedOpsBad

export sorted_union, sorted_intersect, sorted_setdiff

sorted_union(a,b)       = union(a,b)
sorted_intersect(a,b)   = intersect(a,b)
sorted_setdiff(a,b)     = setdiff(a,b)

end#module
