#!/bin/bash

#BEGIN DEPEND------------------------------------------------------------------

INPUT_SCRIPT=scripts/cif_filter

#END DEPEND--------------------------------------------------------------------

echo data_test \
    | ${INPUT_SCRIPT} \
        --use-all \
        --bibliography <(cat <<END
<journal>Crystal Growth &amp; Design</journal>
<authors separator="|">Antis, S&#261;moninga| Mangusta, Apsukrioji</authors>
END
)
