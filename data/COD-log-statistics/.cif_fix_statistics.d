./cif_fix_statistics.log: $(echo $(ls -1 inputs/cod/cif/checks/*.log | grep -v '/make'))
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
