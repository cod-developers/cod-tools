Tests the way looped categories with composite keys are handled. Currently
the _category_key.name attribute is incorrectly left as part of individual
data item definitions instead of relocating them to the definition of the
parent category.
