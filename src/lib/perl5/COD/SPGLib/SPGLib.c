/*---------------------------------------------------------------------------*\
**$Author: andrius $
**$Date: 2015-12-15 15:18:29 +0200 (Tue, 15 Dec 2015) $ 
**$Revision: 247 $
**$URL: svn+ssh://saulius-grazulis.lt/home/saulius/svn-repositories/tests/spglib-perl/SPGLib.c $
\*---------------------------------------------------------------------------*/

/* exports: */
#include <SPGLib.h>

/* uses: */
#include <stdio.h>
#include <spacegroup.h>
#include <spglib.h>
#include <cell.h>
#include <version.h>
#include <XSUB.h>
#include <assert.h>

char *names[] = { "a", "b", "c", "alpha", "beta", "gamma", NULL };

void hv_put( HV * hash, char * key, SV * scalar ) {
    hv_store( hash, key, strlen(key), scalar, 0 );
}

SV* get_spacegroup( SV* cell_constant_ref, SV* atom_position_ref )
{
    Cell *cell = NULL;

    AV *cell_constants = (AV*)SvRV( cell_constant_ref );

    if( !cell_constants ) {
        fprintf( stderr, "%s(): ERROR, no cell constants given\n", __FUNCTION__ );
        return NULL;
    }

    SSize_t last = av_len( cell_constants );
    int i;
    printf( ">>> Cell constant array length = %d\n", last+1 );
    for( i = 0; i <= last; i ++ ) {
        SV **element = av_fetch( cell_constants, i, 0 );
        int value = SvIV( *element );
        printf( ">>> %s = %d\n", i < 6 ? names[i] : "?", value );
        
    }


    AV *atom_positions = (AV*)SvRV( atom_position_ref );

    if( !atom_positions ) {
        fprintf( stderr, "%s(): WARNING, atom positions are NULL\n", __FUNCTION__ );
        return NULL;
    }

    SSize_t natoms = av_len( atom_positions ) + 1;

    cell = cel_alloc_cell( natoms );
    assert( cell );

    printf( ">>> cell length = %d\n", cell->size );

    for( i = 0; i < natoms; i ++ ) {
        SV **element = av_fetch( atom_positions, i, 0 );
        AV *atom = (*element) ? (AV*)SvRV( *element ) : NULL;
        if( atom ) {
            printf( "%zd: atom array length = %d\n", i, (ssize_t)av_len( atom ));
            SV **sv_name = av_fetch( atom, 0, 0 );
            char *name = SvPV_nolen( *sv_name );
            SV **sv_type = av_fetch( atom, 1, 0 );
            int atom_type = SvIV( *sv_type );
            SV **sv_xcoord = av_fetch( atom, 2, 0 );
            double x = SvNV( *sv_xcoord );
            SV **sv_ycoord = av_fetch( atom, 3, 0 );
            double y = SvNV( *sv_xcoord );
            SV **sv_zcoord = av_fetch( atom, 4, 0 );
            double z = SvNV( *sv_zcoord );
            cell->types[i] = atom_type;
            cell->position[i][0] = x;
            cell->position[i][1] = y;
            cell->position[i][2] = z;
            printf( "%d: name = %s, type = %d, xyz = %f %f %f\n",
                    i, name, atom_type, x, y, z );
        }
    }

    cel_free_cell( cell );

    /* printf( ">>> %s() called\n", __FUNCTION__ ); */
    return NULL;
}

SV* get_sym_dataset( SV* lattice_ref, SV* atom_positions_ref, SV* types_ref,
                     SV* symprec )
{
    AV *lattice_av = (AV*)SvRV( lattice_ref );
    AV *atom_positions_av = (AV*)SvRV( atom_positions_ref );
    AV *types_av = (AV*)SvRV( types_ref );

    SSize_t natoms = av_len( atom_positions_av ) + 1;

    int i;
    int j;
    int k;

    SPGCONST double lattice[3][3];
    for( i = 0; i < 3; i++ ) {
        for( j = 0; j < 3; j++ ) {
            lattice[i][j] = SvNV( (SV*)
                                  *av_fetch( (AV*)
                                             SvRV( *av_fetch( lattice_av, 
                                                              i, 0 ) ),
                                             j, 0 ) );
        }
    }

    SPGCONST double positions[natoms][3];
    int types[natoms];
    for( i = 0; i < natoms; i++ ) {
        types[i] = SvIV( (SV*) *av_fetch( types_av, i, 0 ) );
        for( j = 0; j < 3; j++ ) {
            positions[i][j] = SvNV( (SV*)
                                    *av_fetch( (AV*)
                                               SvRV( *av_fetch( atom_positions_av, 
                                                                i, 0 ) ),
                                               j, 0 ) );
        }
    }

    SpglibDataset * dataset = spg_get_dataset( lattice, positions, types,
                                               natoms, SvNV( symprec ) );

    if( !dataset ) {
        return NULL;
    }

    AV *origin_shift = newAV();
    AV *transform_matrix = newAV();
    for( i = 0; i < 3; i++ ) {
        av_push( origin_shift, newSVnv( dataset->origin_shift[i] ) );
        AV *matrix_line = newAV();
        for( j = 0; j < 3; j++ ) {
            av_push( matrix_line,
                     newSVnv( dataset->transformation_matrix[i][j] ) );
        }
        av_push( transform_matrix, newRV_noinc((SV*) matrix_line ) );
    }

    AV *wyckoff = newAV();
    AV *equivalents = newAV();
    for( i = 0; i < dataset->n_atoms; i++ ) {
        av_push( wyckoff, newSViv( dataset->wyckoffs[i] ) );
        av_push( equivalents, newSViv( dataset->equivalent_atoms[i] ) );
    }

    AV *symops = newAV();
    for( k = 0; k < dataset->n_operations; k++ ) {
        AV *symop = newAV();
        for( i = 0; i < 3; i++ ) {
            AV *matrix_line = newAV();
            for( j = 0; j < 3; j++ ) {
                av_push( matrix_line,
                         newSVnv( dataset->rotations[k][i][j] ) );
            }
            av_push( matrix_line, newSVnv( dataset->translations[k][i] ) );
            av_push( symop, newRV_noinc((SV*) matrix_line ) );
        }
        AV *matrix_line = newAV();
        av_push( matrix_line, newSVnv( 0 ) );
        av_push( matrix_line, newSVnv( 0 ) );
        av_push( matrix_line, newSVnv( 0 ) );
        av_push( matrix_line, newSVnv( 1 ) );
        av_push( symop, newRV_noinc((SV*) matrix_line ) );
        av_push( symops, newRV_noinc((SV*) symop ) );
    }

    AV *std_lattice = newAV();
    for( i = 0; i < 3; i++ ) {
        AV *matrix_line = newAV();
        for( j = 0; j < 3; j++ ) {
            av_push( matrix_line,
                     newSVnv( dataset->std_lattice[i][j] ) );
        }
        av_push( std_lattice, newRV_noinc((SV*) matrix_line ) );
    }

    AV *std_positions = newAV();
    AV *std_types = newAV();
    for( k = 0; k < dataset->n_std_atoms; k++ ) {
        AV *matrix_line = newAV();
        for( i = 0; i < 3; i++ ) {
            av_push( matrix_line,
                     newSVnv( dataset->std_positions[k][i] ) );
        }
        av_push( std_positions, newRV_noinc((SV*) matrix_line ) );
        av_push( std_types, newSViv( dataset->std_types[k] ) );
    }

    HV *dataset_hv = newHV();
    hv_put( dataset_hv, "number",
            newSViv( dataset->spacegroup_number ) );
    hv_put( dataset_hv, "hall", newSVpv( dataset->hall_symbol, 0 ) );
    hv_put( dataset_hv, "international_symbol",
            newSVpv( dataset->international_symbol, 0 ) );
    hv_put( dataset_hv, "setting", newSVpv( dataset->setting, 0 ) );
    hv_put( dataset_hv, "transform_matrix",
            newRV_noinc((SV*) transform_matrix) );
    hv_put( dataset_hv, "origin_shift", newRV_noinc((SV*) origin_shift) );
    hv_put( dataset_hv, "wyckoff", newRV_noinc((SV*) wyckoff) );
    hv_put( dataset_hv, "equivalent_atoms",
            newRV_noinc((SV*) equivalents) );
    hv_put( dataset_hv, "symops", newRV_noinc((SV*) symops) );
    hv_put( dataset_hv, "std_lattice",
            newRV_noinc((SV*) std_lattice) );
    hv_put( dataset_hv, "std_types", newRV_noinc((SV*) std_types) );
    hv_put( dataset_hv, "std_positions",
            newRV_noinc((SV*) std_positions) );

    spg_free_dataset( dataset );

    return sv_2mortal(newRV_noinc((SV*) dataset_hv));
}

SV* spglib_version( void ) {
    return sv_2mortal( newSVpvf( "%i.%i.%i",
                                  SPGLIB_MAJOR_VERSION,
                                  SPGLIB_MINOR_VERSION,
                                  SPGLIB_MICRO_VERSION ) );
}
