Test the way the 'calcformula' (compound summary formula) and
'cellformula' (unit cell summary formula) fields are calculated.
If the atomic coordinates consist entirely of CIF unknown values ('?'),
both fields should be treated as undefined. 

FIXME: currently, the '- ? -' value is returned instead of an undefined value.
