Tests the way CIF special values ('?', '.') affect the validation of various
data structures. Special CIF values should not taise a validation issue even
if the CIF special values is not placed in an appropriate container
(i.e. plain '?' value instead of a list). 
