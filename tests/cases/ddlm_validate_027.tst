Check the way the alias ids are treated in the validated dictionary file.
The alias ids should not be copied as seperate hash entries and as a result
the validation messages should only be printed once per each save block.
