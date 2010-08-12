./cif_fix_statistics.log: inputs/cod/cif/checks/COD-check-authors.log inputs/cod/cif/checks/COD-check-bibliography.log inputs/cod/cif/checks/COD-check-formulae.log inputs/cod/cif/checks/COD-check-symmetry.log inputs/cod/cif/checks/cif-validate-series1.log inputs/cod/cif/checks/cif-validate-series2.log inputs/cod/cif/checks/cif-validate-series4.log inputs/cod/cif/checks/cif-validate-series5.log inputs/cod/cif/checks/cif-validate-series7.log inputs/cod/cif/checks/cif-validate-series8.log inputs/cod/cif/checks/cif-validate-series9.log inputs/cod/cif/checks/make.log
./outputs/cif_fix_statistics.dat: ./cif_fix_statistics.log
	@cd .; test -f ./outputs/cif_fix_statistics.dat || sh -xc './cif_fix_statistics.com > cif_fix_statistics.log 2>&1'
	@cd .; test -f ./outputs/cif_fix_statistics.dat && touch ./outputs/cif_fix_statistics.dat
CLEAN_FILES += ./outputs/cif_fix_statistics.dat
CLEAN_FILE_TARGETS += cleanfilecif_fix_statistics
cleanfilecif_fix_statistics:
	rm -f ./outputs/cif_fix_statistics.dat
CLEAN_TARGETS +=cleancif_fix_statistics
cleancif_fix_statistics: cleanfilecif_fix_statistics
	rm -f ./cif_fix_statistics.log
