/* Copyright (C) 2008 Atsushi Togo */
/* All rights reserved. */

/* This file is part of spglib. */

/* Redistribution and use in source and binary forms, with or without */
/* modification, are permitted provided that the following conditions */
/* are met: */

/* * Redistributions of source code must retain the above copyright */
/*   notice, this list of conditions and the following disclaimer. */

/* * Redistributions in binary form must reproduce the above copyright */
/*   notice, this list of conditions and the following disclaimer in */
/*   the documentation and/or other materials provided with the */
/*   distribution. */

/* * Neither the name of the phonopy project nor the names of its */
/*   contributors may be used to endorse or promote products derived */
/*   from this software without specific prior written permission. */

/* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS */
/* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT */
/* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS */
/* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE */
/* COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, */
/* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, */
/* BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; */
/* LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER */
/* CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT */
/* LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN */
/* ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE */
/* POSSIBILITY OF SUCH DAMAGE. */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "arithmetic.h"
#include "cell.h"
#include "debug.h"
#include "delaunay.h"
#include "kgrid.h"
#include "kpoint.h"
#include "mathfunc.h"
#include "niggli.h"
#include "pointgroup.h"
#include "spglib.h"
#include "primitive.h"
#include "refinement.h"
#include "spacegroup.h"
#include "spg_database.h"
#include "spin.h"
#include "symmetry.h"
#include "version.h"

#define REDUCE_RATE 0.9
#define NUM_ATTEMPT 10

/*-------*/
/* error */
/*-------*/
static SpglibError spglib_error_code = SPGLIB_SUCCESS;

typedef struct {
  SpglibError error;
  char *message;
} SpglibErrorMessage;

static SpglibErrorMessage spglib_error_message[] = {
  {SPGLIB_SUCCESS, "no error"},
  {SPGERR_SPACEGROUP_SEARCH_FAILED, "spacegroup search failed"},
  {SPGERR_CELL_STANDARDIZATION_FAILED, "cell standardization failed"},
  {SPGERR_SYMMETRY_OPERATION_SEARCH_FAILED, "symmetry operation search failed"},
  {SPGERR_ATOMS_TOO_CLOSE, "too close distance between atoms"},
  {SPGERR_POINTGROUP_NOT_FOUND, "pointgroup not found"},
  {SPGERR_NIGGLI_FAILED, "Niggli reduction failed"},
  {SPGERR_DELAUNAY_FAILED, "Delaunay reduction failed"},
  {SPGERR_ARRAY_SIZE_SHORTAGE, "array size shortage"},
  {SPGERR_NONE, ""},
};

/*---------*/
/* general */
/*---------*/
static SpglibDataset * get_dataset(SPGCONST double lattice[3][3],
                                   SPGCONST double position[][3],
                                   const int types[],
                                   const int num_atom,
                                   const int hall_number,
                                   const double symprec,
                                   const double angle_tolerance);
static int set_dataset(SpglibDataset * dataset,
                       const Cell * cell,
                       const Cell * primitive,
                       SPGCONST Spacegroup * spacegroup,
                       const int * mapping_table,
                       const double tolerance);
static int get_symmetry_from_dataset(int rotation[][3][3],
                                     double translation[][3],
                                     const int max_size,
                                     SPGCONST double lattice[3][3],
                                     SPGCONST double position[][3],
                                     const int types[],
                                     const int num_atom,
                                     const double symprec,
                                     const double angle_tolerance);
static int get_symmetry_with_collinear_spin(int rotation[][3][3],
                                            double translation[][3],
                                            int equivalent_atoms[],
                                            const int max_size,
                                            SPGCONST double lattice[3][3],
                                            SPGCONST double position[][3],
                                            const int types[],
                                            const double spins[],
                                            const int num_atom,
                                            const double symprec,
					    const double angle_tolerance);
static int get_multiplicity(SPGCONST double lattice[3][3],
                            SPGCONST double position[][3],
                            const int types[],
                            const int num_atom,
                            const double symprec,
			    const double angle_tolerance);
static int standardize_primitive(double lattice[3][3],
                                 double position[][3],
                                 int types[],
                                 const int num_atom,
                                 const double symprec,
                                 const double angle_tolerance);
static int standardize_cell(double lattice[3][3],
                            double position[][3],
                            int types[],
                            const int num_atom,
                            const double symprec,
                            const double angle_tolerance);
static int get_standardized_cell(double lattice[3][3],
                                 double position[][3],
                                 int types[],
                                 const int num_atom,
                                 const int to_primitive,
                                 const double symprec,
                                 const double angle_tolerance);
static Centering get_centering(int hall_number);
static void set_cell(double lattice[3][3],
                     double position[][3],
                     int types[],
                     Cell * cell);
static int get_international(char symbol[11],
                             SPGCONST double lattice[3][3],
                             SPGCONST double position[][3],
                             const int types[],
                             const int num_atom,
                             const double symprec,
			     const double angle_tolerance);
static int get_schoenflies(char symbol[7],
                           SPGCONST double lattice[3][3],
                           SPGCONST double position[][3],
                           const int types[], const int num_atom,
                           const double symprec,
                           const double angle_tolerance);

/*---------*/
/* kpoints */
/*---------*/
static int get_ir_reciprocal_mesh(int grid_address[][3],
                                  int map[],
                                  const int mesh[3],
                                  const int is_shift[3],
                                  const int is_time_reversal,
                                  SPGCONST double lattice[3][3],
                                  SPGCONST double position[][3],
                                  const int types[],
                                  const int num_atom,
                                  const double symprec,
                                  const double angle_tolerance);

static int get_stabilized_reciprocal_mesh(int grid_address[][3],
                                          int map[],
                                          const int mesh[3],
                                          const int is_shift[3],
                                          const int is_time_reversal,
                                          const int num_rot,
                                          SPGCONST int rotations[][3][3],
                                          const int num_q,
                                          SPGCONST double qpoints[][3]);

/*========*/
/* global */
/*========*/

/*-----------------------------------------*/
/* Version: spglib-[major].[minor].[micro] */
/*-----------------------------------------*/
int spg_get_major_version(void)
{
  spglib_error_code = SPGLIB_SUCCESS;
  return SPGLIB_MAJOR_VERSION;
}

int spg_get_minor_version(void)
{
  spglib_error_code = SPGLIB_SUCCESS;
  return SPGLIB_MINOR_VERSION;
}

int spg_get_micro_version(void)
{
  spglib_error_code = SPGLIB_SUCCESS;
  return SPGLIB_MICRO_VERSION;
}

/*-------*/
/* error */
/*-------*/
SpglibError spg_get_error_code(void)
{
  return spglib_error_code;
}

char * spg_get_error_message(SpglibError error)
{
  int i;

  for (i = 0; i < 100; i++) {
    if (SPGERR_NONE == spglib_error_message[i].error) {
      break;
    }

    if (error == spglib_error_message[i].error) {
      return spglib_error_message[i].message;
    }
  }

  return NULL;
}

/*---------*/
/* general */
/*---------*/
/* Return NULL if failed */
SpglibDataset * spg_get_dataset(SPGCONST double lattice[3][3],
                                SPGCONST double position[][3],
                                const int types[],
                                const int num_atom,
                                const double symprec)
{
  return get_dataset(lattice,
                     position,
                     types,
                     num_atom,
                     0,
                     symprec,
		     -1.0);
}

/* Return NULL if failed */
SpglibDataset * spgat_get_dataset(SPGCONST double lattice[3][3],
                                  SPGCONST double position[][3],
                                  const int types[],
                                  const int num_atom,
                                  const double symprec,
                                  const double angle_tolerance)
{
  return get_dataset(lattice,
                     position,
                     types,
                     num_atom,
                     0,
                     symprec,
		     angle_tolerance);
}

/* Return NULL if failed */
SpglibDataset * spg_get_dataset_with_hall_number(SPGCONST double lattice[3][3],
                                                 SPGCONST double position[][3],
                                                 const int types[],
                                                 const int num_atom,
                                                 const int hall_number,
                                                 const double symprec)
{
  return get_dataset(lattice,
                     position,
                     types,
                     num_atom,
                     hall_number,
                     symprec,
		     -1.0);
}

/* Return NULL if failed */
SpglibDataset *
spgat_get_dataset_with_hall_number(SPGCONST double lattice[3][3],
                                   SPGCONST double position[][3],
                                   const int types[],
                                   const int num_atom,
                                   const int hall_number,
                                   const double symprec,
                                   const double angle_tolerance)
{
  return get_dataset(lattice,
                     position,
                     types,
                     num_atom,
                     hall_number,
                     symprec,
		     angle_tolerance);
}

void spg_free_dataset(SpglibDataset *dataset)
{
  if (dataset->n_operations > 0) {
    free(dataset->rotations);
    dataset->rotations = NULL;
    free(dataset->translations);
    dataset->translations = NULL;
    dataset->n_operations = 0;
  }

  if (dataset->n_atoms > 0) {
    free(dataset->wyckoffs);
    dataset->wyckoffs = NULL;
    free(dataset->equivalent_atoms);
    dataset->equivalent_atoms = NULL;
    dataset->n_atoms = 0;
  }

  if (dataset->n_std_atoms > 0) {
    free(dataset->std_positions);
    dataset->std_positions = NULL;
    free(dataset->std_types);
    dataset->std_types = NULL;
    dataset->n_std_atoms = 0;
  }

  dataset->spacegroup_number = 0;
  dataset->hall_number = 0;
  strcpy(dataset->international_symbol, "");
  strcpy(dataset->hall_symbol, "");
  strcpy(dataset->choice, "");

  free(dataset);
  dataset = NULL;
}

/* Return 0 if failed */
int spg_get_symmetry(int rotation[][3][3],
                     double translation[][3],
                     const int max_size,
                     SPGCONST double lattice[3][3],
                     SPGCONST double position[][3],
                     const int types[],
                     const int num_atom,
                     const double symprec)
{
  return get_symmetry_from_dataset(rotation,
                                   translation,
                                   max_size,
                                   lattice,
                                   position,
                                   types,
                                   num_atom,
                                   symprec,
				   -1.0);
}

/* Return 0 if failed */
int spgat_get_symmetry(int rotation[][3][3],
                       double translation[][3],
                       const int max_size,
                       SPGCONST double lattice[3][3],
                       SPGCONST double position[][3],
                       const int types[],
                       const int num_atom,
                       const double symprec,
                       const double angle_tolerance)
{
  return get_symmetry_from_dataset(rotation,
                                   translation,
                                   max_size,
                                   lattice,
                                   position,
                                   types,
                                   num_atom,
                                   symprec,
				   angle_tolerance);
}

/* Return 0 if failed */
int spg_get_symmetry_with_collinear_spin(int rotation[][3][3],
                                         double translation[][3],
                                         int equivalent_atoms[],
                                         const int max_size,
                                         SPGCONST double lattice[3][3],
                                         SPGCONST double position[][3],
                                         const int types[],
                                         const double spins[],
                                         const int num_atom,
                                         const double symprec)
{
  return get_symmetry_with_collinear_spin(rotation,
                                          translation,
                                          equivalent_atoms,
                                          max_size,
                                          lattice,
                                          position,
                                          types,
                                          spins,
                                          num_atom,
                                          symprec,
					  -1.0);
}

/* Return 0 if failed */
int spgat_get_symmetry_with_collinear_spin(int rotation[][3][3],
                                           double translation[][3],
                                           int equivalent_atoms[],
                                           const int max_size,
                                           SPGCONST double lattice[3][3],
                                           SPGCONST double position[][3],
                                           const int types[],
                                           const double spins[],
                                           const int num_atom,
                                           const double symprec,
                                           const double angle_tolerance)
{
  return get_symmetry_with_collinear_spin(rotation,
                                          translation,
                                          equivalent_atoms,
                                          max_size,
                                          lattice,
                                          position,
                                          types,
                                          spins,
                                          num_atom,
                                          symprec,
					  angle_tolerance);
}

int spg_get_hall_number_from_symmetry(SPGCONST int rotation[][3][3],
                                      SPGCONST double translation[][3],
                                      const int num_operations,
                                      const double symprec)
{
  int i;
  Symmetry *symmetry;
  Symmetry *prim_symmetry;
  Spacegroup spacegroup;

  symmetry = NULL;
  prim_symmetry = NULL;

  symmetry = sym_alloc_symmetry(num_operations);
  for (i = 0; i < num_operations; i++) {
    mat_copy_matrix_i3(symmetry->rot[i], rotation[i]);
    mat_copy_vector_d3(symmetry->trans[i], translation[i]);
  }

  prim_symmetry = prm_get_primitive_symmetry(symmetry, symprec);
  spacegroup = spa_search_spacegroup_with_symmetry(prim_symmetry, symprec);

  if (spacegroup.hall_number) {
    spglib_error_code = SPGLIB_SUCCESS;
    return spacegroup.hall_number;
  } else {
    spglib_error_code = SPGERR_SPACEGROUP_SEARCH_FAILED;
    return 0;
  }
}

/* Return 0 if failed */
int spg_get_multiplicity(SPGCONST double lattice[3][3],
                         SPGCONST double position[][3],
                         const int types[],
                         const int num_atom,
                         const double symprec)
{
  return get_multiplicity(lattice,
                          position,
                          types,
                          num_atom,
                          symprec,
			  -1.0);
}

/* Return 0 if failed */
int spgat_get_multiplicity(SPGCONST double lattice[3][3],
                           SPGCONST double position[][3],
                           const int types[],
                           const int num_atom,
                           const double symprec,
                           const double angle_tolerance)
{
  return get_multiplicity(lattice,
                          position,
                          types,
                          num_atom,
                          symprec,
			  angle_tolerance);
}

/* Return 0 if failed */
int spg_get_international(char symbol[11],
                          SPGCONST double lattice[3][3],
                          SPGCONST double position[][3],
                          const int types[],
                          const int num_atom,
                          const double symprec)
{
  return get_international(symbol,
                           lattice,
                           position,
                           types,
                           num_atom,
                           symprec,
			   -1.0);
}

/* Return 0 if failed */
int spgat_get_international(char symbol[11],
                            SPGCONST double lattice[3][3],
                            SPGCONST double position[][3],
                            const int types[],
                            const int num_atom,
                            const double symprec,
                            const double angle_tolerance)
{
  return get_international(symbol,
                           lattice,
                           position,
                           types,
                           num_atom,
                           symprec,
			   angle_tolerance);
}

/* Return 0 if failed */
int spg_get_schoenflies(char symbol[7],
                        SPGCONST double lattice[3][3],
                        SPGCONST double position[][3],
                        const int types[],
                        const int num_atom,
                        const double symprec)
{
  return get_schoenflies(symbol,
                         lattice,
                         position,
                         types,
                         num_atom,
                         symprec,
			 -1.0);
}

/* Return 0 if failed */
int spgat_get_schoenflies(char symbol[7],
                          SPGCONST double lattice[3][3],
                          SPGCONST double position[][3],
                          const int types[],
                          const int num_atom,
                          const double symprec,
                          const double angle_tolerance)
{
  return get_schoenflies(symbol,
                         lattice,
                         position,
                         types,
                         num_atom,
                         symprec,
			 angle_tolerance);
}

/* Return 0 if failed */
int spg_get_pointgroup(char symbol[6],
                       int transform_mat[3][3],
                       SPGCONST int rotations[][3][3],
                       const int num_rotations)
{
  Pointgroup pointgroup;

  pointgroup = ptg_get_transformation_matrix(transform_mat,
                                             rotations,
                                             num_rotations);

  if (pointgroup.number == 0) {
    spglib_error_code = SPGERR_POINTGROUP_NOT_FOUND;
    return 0;
  }

  strcpy(symbol, pointgroup.symbol);

  spglib_error_code = SPGLIB_SUCCESS;
  return pointgroup.number;
}

/* Return 0 if failed */
int spg_get_symmetry_from_database(int rotations[192][3][3],
                                   double translations[192][3],
                                   const int hall_number)
{
  int i, size;
  Symmetry *symmetry;

  symmetry = NULL;

  if ((symmetry = spgdb_get_spacegroup_operations(hall_number)) == NULL) {
    goto err;
  }

  for (i = 0; i < symmetry->size; i++) {
    mat_copy_matrix_i3(rotations[i], symmetry->rot[i]);
    mat_copy_vector_d3(translations[i], symmetry->trans[i]);
  }
  size = symmetry->size;

  sym_free_symmetry(symmetry);
  symmetry = NULL;

  spglib_error_code = SPGLIB_SUCCESS;
  return size;

 err:
  spglib_error_code = SPGERR_SPACEGROUP_SEARCH_FAILED;
  return 0;
}

/* Return spglibtype.number = 0 if failed */
SpglibSpacegroupType spg_get_spacegroup_type(const int hall_number)
{
  SpglibSpacegroupType spglibtype;
  SpacegroupType spgtype;
  Pointgroup pointgroup;
  int arth_number;
  char arth_symbol[7];

  spglibtype.number = 0;
  strcpy(spglibtype.schoenflies, "");
  strcpy(spglibtype.hall_symbol, "");
  strcpy(spglibtype.choice, "");
  strcpy(spglibtype.international, "");
  strcpy(spglibtype.international_full, "");
  strcpy(spglibtype.international_short, "");
  strcpy(spglibtype.pointgroup_international, "");
  strcpy(spglibtype.pointgroup_schoenflies, "");
  spglibtype.arithmetic_crystal_class_number = 0;
  strcpy(spglibtype.arithmetic_crystal_class_symbol, "");

  if (0 < hall_number || hall_number < 531) {
    spgtype = spgdb_get_spacegroup_type(hall_number);
    spglibtype.number = spgtype.number;
    strcpy(spglibtype.schoenflies, spgtype.schoenflies);
    strcpy(spglibtype.hall_symbol, spgtype.hall_symbol);
    strcpy(spglibtype.choice, spgtype.choice);
    strcpy(spglibtype.international, spgtype.international);
    strcpy(spglibtype.international_full, spgtype.international_full);
    strcpy(spglibtype.international_short, spgtype.international_short);
    pointgroup = ptg_get_pointgroup(spgtype.pointgroup_number);
    strcpy(spglibtype.pointgroup_international, pointgroup.symbol);
    strcpy(spglibtype.pointgroup_schoenflies, pointgroup.schoenflies);
    arth_number = arth_get_symbol(arth_symbol, spgtype.number);
    spglibtype.arithmetic_crystal_class_number = arth_number;
    strcpy(spglibtype.arithmetic_crystal_class_symbol, arth_symbol);
    spglib_error_code = SPGLIB_SUCCESS;
  } else {
    spglib_error_code = SPGERR_SPACEGROUP_SEARCH_FAILED;
  }

  return spglibtype;
}

/* Return 0 if failed */
int spg_standardize_cell(double lattice[3][3],
                         double position[][3],
                         int types[],
                         const int num_atom,
                         const int to_primitive,
                         const int no_idealize,
                         const double symprec)
{
  return spgat_standardize_cell(lattice,
                                position,
                                types,
                                num_atom,
                                to_primitive,
                                no_idealize,
                                symprec,
                                -1.0);
}

/* Return 0 if failed */
int spgat_standardize_cell(double lattice[3][3],
                           double position[][3],
                           int types[],
                           const int num_atom,
                           const int to_primitive,
                           const int no_idealize,
                           const double symprec,
                           const double angle_tolerance)
{
  if (to_primitive) {
    if (no_idealize) {
      return get_standardized_cell(lattice,
                                   position,
                                   types,
                                   num_atom,
                                   1,
                                   symprec,
				   angle_tolerance);
    } else {
      return standardize_primitive(lattice,
                                   position,
                                   types,
                                   num_atom,
                                   symprec,
				   angle_tolerance);
    }
  } else {
    if (no_idealize) {
      return get_standardized_cell(lattice,
                                   position,
                                   types,
                                   num_atom,
                                   0,
                                   symprec,
				   angle_tolerance);
    } else {
      return standardize_cell(lattice,
                              position,
                              types,
                              num_atom,
                              symprec,
			      angle_tolerance);
    }
  }
}

/* Return 0 if failed */
int spg_find_primitive(double lattice[3][3],
                       double position[][3],
                       int types[],
                       const int num_atom,
                       const double symprec)
{
  return standardize_primitive(lattice,
                               position,
                               types,
                               num_atom,
                               symprec,
			       -1.0);
}

/* Return 0 if failed */
int spgat_find_primitive(double lattice[3][3],
                         double position[][3],
                         int types[],
                         const int num_atom,
                         const double symprec,
                         const double angle_tolerance)
{
  return standardize_primitive(lattice,
                               position,
                               types,
                               num_atom,
                               symprec,
			       angle_tolerance);
}

/* Return 0 if failed */
int spg_refine_cell(double lattice[3][3],
                    double position[][3],
                    int types[],
                    const int num_atom,
                    const double symprec)
{
  return standardize_cell(lattice,
                          position,
                          types,
                          num_atom,
                          symprec,
			  -1.0);
}

/* Return 0 if failed */
int spgat_refine_cell(double lattice[3][3],
                      double position[][3],
                      int types[],
                      const int num_atom,
                      const double symprec,
                      const double angle_tolerance)
{
  return standardize_cell(lattice,
                          position,
                          types,
                          num_atom,
                          symprec,
			  angle_tolerance);
}

int spg_delaunay_reduce(double lattice[3][3], const double symprec)
{
  int i, j, succeeded;
  double red_lattice[3][3];

  succeeded = del_delaunay_reduce(red_lattice, lattice, symprec);

  if (succeeded) {
    for (i = 0; i < 3; i++) {
      for (j = 0; j < 3; j++) {
        lattice[i][j] = red_lattice[i][j];
      }
    }
    spglib_error_code = SPGLIB_SUCCESS;
  } else {
    spglib_error_code = SPGERR_DELAUNAY_FAILED;
  }

  return succeeded;
}

/*---------*/
/* kpoints */
/*---------*/
int spg_get_grid_point_from_address(const int grid_address[3],
                                    const int mesh[3])
{
  int address_double[3];
  int is_shift[3];

  is_shift[0] = 0;
  is_shift[1] = 0;
  is_shift[2] = 0;
  kgd_get_grid_address_double_mesh(address_double,
                                   grid_address,
                                   mesh,
                                   is_shift);
  return kgd_get_grid_point_double_mesh(address_double, mesh);
}

int spg_get_ir_reciprocal_mesh(int grid_address[][3],
                               int map[],
                               const int mesh[3],
                               const int is_shift[3],
                               const int is_time_reversal,
                               SPGCONST double lattice[3][3],
                               SPGCONST double position[][3],
                               const int types[],
                               const int num_atom,
                               const double symprec)
{
  return get_ir_reciprocal_mesh(grid_address,
                                map,
                                mesh,
                                is_shift,
                                is_time_reversal,
                                lattice,
                                position,
                                types,
                                num_atom,
                                symprec,
				-1.0);
}

int spg_get_stabilized_reciprocal_mesh(int grid_address[][3],
                                       int map[],
                                       const int mesh[3],
                                       const int is_shift[3],
                                       const int is_time_reversal,
                                       const int num_rot,
                                       SPGCONST int rotations[][3][3],
                                       const int num_q,
                                       SPGCONST double qpoints[][3])
{
  return get_stabilized_reciprocal_mesh(grid_address,
                                        map,
                                        mesh,
                                        is_shift,
                                        is_time_reversal,
                                        num_rot,
                                        rotations,
                                        num_q,
                                        qpoints);
}

int spg_get_grid_points_by_rotations(int rot_grid_points[],
                                     const int address_orig[3],
                                     const int num_rot,
                                     SPGCONST int rot_reciprocal[][3][3],
                                     const int mesh[3],
                                     const int is_shift[3])
{
  int i;
  MatINT *rot;

  rot = NULL;

  if ((rot = mat_alloc_MatINT(num_rot)) == NULL) {
    return 0;
  }

  for (i = 0; i < num_rot; i++) {
    mat_copy_matrix_i3(rot->mat[i], rot_reciprocal[i]);
  }
  kpt_get_grid_points_by_rotations(rot_grid_points,
                                   address_orig,
                                   rot,
                                   mesh,
                                   is_shift);
  mat_free_MatINT(rot);
  rot = NULL;

  return 1;
}

int spg_get_BZ_grid_points_by_rotations(int rot_grid_points[],
                                        const int address_orig[3],
                                        const int num_rot,
                                        SPGCONST int rot_reciprocal[][3][3],
                                        const int mesh[3],
                                        const int is_shift[3],
                                        const int bz_map[])
{
  int i;
  MatINT *rot;

  rot = NULL;

  if ((rot = mat_alloc_MatINT(num_rot)) == NULL) {
    return 0;
  }

  for (i = 0; i < num_rot; i++) {
    mat_copy_matrix_i3(rot->mat[i], rot_reciprocal[i]);
  }
  kpt_get_BZ_grid_points_by_rotations(rot_grid_points,
                                      address_orig,
                                      rot,
                                      mesh,
                                      is_shift,
                                      bz_map);
  mat_free_MatINT(rot);
  rot = NULL;

  return 1;
}

int spg_relocate_BZ_grid_address(int bz_grid_address[][3],
                                 int bz_map[],
                                 SPGCONST int grid_address[][3],
                                 const int mesh[3],
                                 SPGCONST double rec_lattice[3][3],
                                 const int is_shift[3])
{
  return kpt_relocate_BZ_grid_address(bz_grid_address,
                                      bz_map,
                                      grid_address,
                                      mesh,
                                      rec_lattice,
                                      is_shift);
}

/*--------*/
/* Niggli */
/*--------*/
/* Return 0 if failed */
int spg_niggli_reduce(double lattice[3][3], const double symprec)
{
  int i, j, succeeded;
  double vals[9];

  for (i = 0; i < 3; i++) {
    for (j = 0; j < 3; j++) {
      vals[i * 3 + j] = lattice[i][j];
    }
  }

  succeeded = niggli_reduce(vals, symprec);

  if (succeeded) {
    for (i = 0; i < 3; i++) {
      for (j = 0; j < 3; j++) {
        lattice[i][j] = vals[i * 3 + j];
      }
    }
    spglib_error_code = SPGLIB_SUCCESS;
  } else {
    spglib_error_code = SPGERR_NIGGLI_FAILED;
  }

  return succeeded;
}




/*=======*/
/* local */
/*=======*/

/*---------*/
/* general */
/*---------*/
/* Return NULL if failed */
static SpglibDataset * get_dataset(SPGCONST double lattice[3][3],
                                   SPGCONST double position[][3],
                                   const int types[],
                                   const int num_atom,
                                   const int hall_number,
                                   const double symprec,
                                   const double angle_tolerance)
{
  int attempt;
  double tolerance;
  Spacegroup spacegroup;
  SpacegroupType spacegroup_type;
  SpglibDataset *dataset;
  Cell *cell;
  Primitive *primitive;

  spacegroup.number = 0;
  dataset = NULL;
  cell = NULL;
  primitive = NULL;

  if ((dataset = (SpglibDataset*) malloc(sizeof(SpglibDataset))) == NULL) {
    warning_print("spglib: Memory could not be allocated.");
    goto not_found;
  }

  dataset->spacegroup_number = 0;
  dataset->hall_number = 0;
  strcpy(dataset->international_symbol, "");
  strcpy(dataset->hall_symbol, "");
  strcpy(dataset->choice, "");
  dataset->origin_shift[0] = 0;
  dataset->origin_shift[1] = 0;
  dataset->origin_shift[2] = 0;
  dataset->n_atoms = 0;
  dataset->wyckoffs = NULL;
  dataset->equivalent_atoms = NULL;
  dataset->n_operations = 0;
  dataset->rotations = NULL;
  dataset->translations = NULL;
  dataset->n_std_atoms = 0;
  dataset->std_positions = NULL;
  dataset->std_types = NULL;
  /* dataset->pointgroup_number = 0; */
  strcpy(dataset->pointgroup_symbol, "");

  if ((cell = cel_alloc_cell(num_atom)) == NULL) {
    free(dataset);
    dataset = NULL;
    goto not_found;
  }

  cel_set_cell(cell, lattice, position, types);
  if (cel_any_overlap_with_same_type(cell, symprec)) {
    cel_free_cell(cell);
    cell = NULL;
    free(dataset);
    dataset = NULL;
    goto atoms_too_close;
  }

  tolerance = symprec;
  for (attempt = 0; attempt < NUM_ATTEMPT; attempt++) {
    if ((primitive = spa_get_spacegroup(&spacegroup,
					cell,
					tolerance,
					angle_tolerance))
        == NULL) {
      cel_free_cell(cell);
      cell = NULL;
      free(dataset);
      dataset = NULL;
      goto not_found;
    }

    if (spacegroup.number > 0) {
      /* With hall_number > 0, specific choice is searched. */
      if (hall_number > 0) {
        spacegroup_type = spgdb_get_spacegroup_type(hall_number);
        if (spacegroup.number == spacegroup_type.number) {
          spacegroup = spa_get_spacegroup_with_hall_number(primitive,
                                                           hall_number);
        } else {
          prm_free_primitive(primitive);
          primitive = NULL;
          goto err;
        }

        if (spacegroup.number == 0) {
          prm_free_primitive(primitive);
          primitive = NULL;
          goto err;
        }
      }

      if (spacegroup.number > 0) {
        if (set_dataset(dataset,
                        cell,
                        primitive->cell,
                        &spacegroup,
                        primitive->mapping_table,
                        primitive->tolerance)) {
          goto found;
        } else {
          tolerance *= REDUCE_RATE;
        }
      }
    }

    prm_free_primitive(primitive);
    primitive = NULL;
  }

 err:
  cel_free_cell(cell);
  cell = NULL;
  free(dataset);
  dataset = NULL;

 not_found:
  spglib_error_code = SPGERR_SPACEGROUP_SEARCH_FAILED;
  return NULL;

 atoms_too_close:
  spglib_error_code = SPGERR_ATOMS_TOO_CLOSE;
  return NULL;

 found:
  prm_free_primitive(primitive);
  primitive = NULL;
  cel_free_cell(cell);
  cell = NULL;

  spglib_error_code = SPGLIB_SUCCESS;
  return dataset;
}

/* Return 0 if failed */
static int set_dataset(SpglibDataset * dataset,
                       const Cell * cell,
                       const Cell * primitive,
                       SPGCONST Spacegroup * spacegroup,
                       const int * mapping_table,
                       const double tolerance)
{
  int i;
  double inv_lat[3][3];
  Cell *bravais;
  Symmetry *symmetry;
  Pointgroup pointgroup;

  bravais = NULL;
  symmetry = NULL;

  /* Spacegroup type, transformation matrix, origin shift */
  dataset->n_atoms = cell->size;
  dataset->spacegroup_number = spacegroup->number;
  dataset->hall_number = spacegroup->hall_number;
  strcpy(dataset->international_symbol, spacegroup->international_short);
  strcpy(dataset->hall_symbol, spacegroup->hall_symbol);
  strcpy(dataset->choice, spacegroup->choice);
  mat_inverse_matrix_d3(inv_lat, spacegroup->bravais_lattice, 0);
  mat_multiply_matrix_d3(dataset->transformation_matrix,
                         inv_lat,
                         cell->lattice);
  mat_copy_vector_d3(dataset->origin_shift, spacegroup->origin_shift);

  /* Symmetry operations */
  if ((symmetry = ref_get_refined_symmetry_operations(cell,
                                                      primitive,
                                                      spacegroup,
                                                      tolerance)) == NULL) {
    return 0;
  }

  dataset->n_operations = symmetry->size;

  if ((dataset->rotations =
       (int (*)[3][3]) malloc(sizeof(int[3][3]) * dataset->n_operations))
      == NULL) {
    warning_print("spglib: Memory could not be allocated.");
    goto err;
  }

  if ((dataset->translations =
       (double (*)[3]) malloc(sizeof(double[3]) * dataset->n_operations))
      == NULL) {
    warning_print("spglib: Memory could not be allocated.");
    goto err;
  }

  for (i = 0; i < symmetry->size; i++) {
    mat_copy_matrix_i3(dataset->rotations[i], symmetry->rot[i]);
    mat_copy_vector_d3(dataset->translations[i], symmetry->trans[i]);
  }

  /* Wyckoff positions */
  if ((dataset->wyckoffs = (int*) malloc(sizeof(int) * dataset->n_atoms))
      == NULL) {
    warning_print("spglib: Memory could not be allocated.");
    goto err;
  }

  if ((dataset->equivalent_atoms =
       (int*) malloc(sizeof(int) * dataset->n_atoms))
      == NULL) {
    warning_print("spglib: Memory could not be allocated.");
    goto err;
  }

  if ((bravais = ref_get_Wyckoff_positions(dataset->wyckoffs,
                                           dataset->equivalent_atoms,
                                           primitive,
                                           cell,
                                           spacegroup,
                                           symmetry,
                                           mapping_table,
                                           tolerance)) == NULL) {
    goto err;
  }

  dataset->n_std_atoms = bravais->size;
  mat_copy_matrix_d3(dataset->std_lattice, bravais->lattice);

  if ((dataset->std_positions =
       (double (*)[3]) malloc(sizeof(double[3]) * dataset->n_std_atoms))
      == NULL) {
    warning_print("spglib: Memory could not be allocated.");
    goto err;
  }

  if ((dataset->std_types = (int*) malloc(sizeof(int) * dataset->n_std_atoms))
      == NULL) {
    warning_print("spglib: Memory could not be allocated.");
    goto err;
  }

  for (i = 0; i < dataset->n_std_atoms; i++) {
    mat_copy_vector_d3(dataset->std_positions[i], bravais->position[i]);
    dataset->std_types[i] = bravais->types[i];
  }

  cel_free_cell(bravais);
  bravais = NULL;
  sym_free_symmetry(symmetry);
  symmetry = NULL;

  /* dataset->pointgroup_number = spacegroup->pointgroup_number; */
  pointgroup = ptg_get_pointgroup(spacegroup->pointgroup_number);
  strcpy(dataset->pointgroup_symbol, pointgroup.symbol);

  return 1;

 err:
  if (dataset->std_positions != NULL) {
    free(dataset->std_positions);
    dataset->std_positions = NULL;
  }
  if (bravais != NULL) {
    cel_free_cell(bravais);
    bravais = NULL;
  }
  if (dataset->equivalent_atoms != NULL) {
    free(dataset->equivalent_atoms);
    dataset->equivalent_atoms = NULL;
  }
  if (dataset->wyckoffs != NULL) {
    free(dataset->wyckoffs);
    dataset->wyckoffs = NULL;
  }
  if (dataset->translations != NULL) {
    free(dataset->translations);
    dataset->translations = NULL;
  }
  if (dataset->rotations != NULL) {
    free(dataset->rotations);
    dataset->rotations = NULL;
  }
  if (symmetry != NULL) {
    sym_free_symmetry(symmetry);
    symmetry = NULL;
  }

  return 0;
}

/* Return 0 if failed */
static int get_symmetry_from_dataset(int rotation[][3][3],
                                     double translation[][3],
                                     const int max_size,
                                     SPGCONST double lattice[3][3],
                                     SPGCONST double position[][3],
                                     const int types[],
                                     const int num_atom,
                                     const double symprec,
                                     const double angle_tolerance)
{
  int i, num_sym;
  SpglibDataset *dataset;

  num_sym = 0;
  dataset = NULL;

  if ((dataset = get_dataset(lattice,
                             position,
                             types,
                             num_atom,
                             0,
                             symprec,
			     angle_tolerance)) == NULL) {
    return 0;
  }

  if (dataset->n_operations > max_size) {
    fprintf(stderr,
            "spglib: Indicated max size(=%d) is less than number ", max_size);
    fprintf(stderr,
            "spglib: of symmetry operations(=%d).\n", dataset->n_operations);
    goto err;
  }

  num_sym = dataset->n_operations;
  for (i = 0; i < num_sym; i++) {
    mat_copy_matrix_i3(rotation[i], dataset->rotations[i]);
    mat_copy_vector_d3(translation[i], dataset->translations[i]);
  }

  spg_free_dataset(dataset);
  return num_sym;

 err:
  spg_free_dataset(dataset);
  spglib_error_code = SPGERR_ARRAY_SIZE_SHORTAGE;
  return 0;
}

/* Return 0 if failed */
static int get_symmetry_with_collinear_spin(int rotation[][3][3],
                                            double translation[][3],
                                            int equivalent_atoms[],
                                            const int max_size,
                                            SPGCONST double lattice[3][3],
                                            SPGCONST double position[][3],
                                            const int types[],
                                            const double spins[],
                                            const int num_atom,
                                            const double symprec,
                                            const double angle_tolerance)
{
  int i, size;
  Symmetry *symmetry, *sym_nonspin;
  Cell *cell;
  SpglibDataset *dataset;

  size = 0;
  symmetry = NULL;
  sym_nonspin = NULL;
  cell = NULL;
  dataset = NULL;

  if ((cell = cel_alloc_cell(num_atom)) == NULL) {
    goto err;
  }

  cel_set_cell(cell, lattice, position, types);

  if ((dataset = get_dataset(lattice,
                             position,
                             types,
                             num_atom,
                             0,
                             symprec,
			     angle_tolerance)) == NULL) {
    cel_free_cell(cell);
    cell = NULL;
    goto get_dataset_failed;
  }

  if ((sym_nonspin = sym_alloc_symmetry(dataset->n_operations)) == NULL) {
    spg_free_dataset(dataset);
    cel_free_cell(cell);
    cell = NULL;
    goto err;
  }

  for (i = 0; i < dataset->n_operations; i++) {
    mat_copy_matrix_i3(sym_nonspin->rot[i], dataset->rotations[i]);
    mat_copy_vector_d3(sym_nonspin->trans[i], dataset->translations[i]);
  }
  spg_free_dataset(dataset);

  if ((symmetry = spn_get_collinear_operations(equivalent_atoms,
                                               sym_nonspin,
                                               cell,
                                               spins,
                                               symprec)) == NULL) {
    sym_free_symmetry(sym_nonspin);
    sym_nonspin = NULL;
    cel_free_cell(cell);
    cell = NULL;
    goto err;
  }

  sym_free_symmetry(sym_nonspin);
  sym_nonspin = NULL;

  if (symmetry->size > max_size) {
    fprintf(stderr, "spglib: Indicated max size(=%d) is less than number ",
            max_size);
    fprintf(stderr, "spglib: of symmetry operations(=%d).\n", symmetry->size);
    goto ret;
  }

  for (i = 0; i < symmetry->size; i++) {
    mat_copy_matrix_i3(rotation[i], symmetry->rot[i]);
    mat_copy_vector_d3(translation[i], symmetry->trans[i]);
  }

  size = symmetry->size;

 ret:
  sym_free_symmetry(symmetry);
  symmetry = NULL;
  cel_free_cell(cell);
  cell = NULL;

  spglib_error_code = SPGLIB_SUCCESS;
  return size;

 err:
  spglib_error_code = SPGERR_SYMMETRY_OPERATION_SEARCH_FAILED;

 get_dataset_failed:
  return 0;
}

/* Return 0 if failed */
static int get_multiplicity(SPGCONST double lattice[3][3],
                            SPGCONST double position[][3],
                            const int types[],
                            const int num_atom,
                            const double symprec,
                            const double angle_tolerance)
{
  int size;
  SpglibDataset *dataset;

  size = 0;
  dataset = NULL;

  if ((dataset = get_dataset(lattice,
                             position,
                             types,
                             num_atom,
                             0,
                             symprec,
			     angle_tolerance)) == NULL) {
    return 0;
  }

  size = dataset->n_operations;
  spg_free_dataset(dataset);

  return size;
}

static int standardize_primitive(double lattice[3][3],
                                 double position[][3],
                                 int types[],
                                 const int num_atom,
                                 const double symprec,
                                 const double angle_tolerance)
{
  int num_prim_atom;
  Centering centering;
  SpglibDataset *dataset;
  Cell *primitive, *bravais;

  double identity[3][3] = {{ 1, 0, 0 },
                           { 0, 1, 0 },
                           { 0, 0, 1 }};

  num_prim_atom = 0;
  dataset = NULL;
  primitive = NULL;
  bravais = NULL;

  if ((dataset = get_dataset(lattice,
                             position,
                             types,
                             num_atom,
                             0,
                             symprec,
			     angle_tolerance)) == NULL) {
    return 0;
  }

  if ((centering = get_centering(dataset->hall_number)) == CENTERING_ERROR) {
    goto err;
  }

  if ((bravais = cel_alloc_cell(dataset->n_std_atoms)) == NULL) {
    spg_free_dataset(dataset);
    return 0;
  }

  cel_set_cell(bravais,
               dataset->std_lattice,
               dataset->std_positions,
               dataset->std_types);

  spg_free_dataset(dataset);

  primitive = spa_transform_to_primitive(bravais,
                                         identity,
                                         centering,
                                         symprec);
  cel_free_cell(bravais);
  bravais = NULL;

  if (primitive == NULL) {
    goto err;
  }

  set_cell(lattice, position, types, primitive);
  num_prim_atom = primitive->size;

  cel_free_cell(primitive);
  primitive = NULL;

  return num_prim_atom;

 err:
  spglib_error_code = SPGERR_CELL_STANDARDIZATION_FAILED;
  return 0;
}

static int standardize_cell(double lattice[3][3],
                            double position[][3],
                            int types[],
                            const int num_atom,
                            const double symprec,
                            const double angle_tolerance)
{
  int i, n_std_atoms;
  SpglibDataset *dataset;

  n_std_atoms = 0;
  dataset = NULL;

  if ((dataset = get_dataset(lattice,
                             position,
                             types,
                             num_atom,
                             0,
                             symprec,
			     angle_tolerance)) == NULL) {
    return 0;
  }

  n_std_atoms = dataset->n_std_atoms;

  mat_copy_matrix_d3(lattice, dataset->std_lattice);
  for (i = 0; i < dataset->n_std_atoms; i++) {
    types[i] = dataset->std_types[i];
    mat_copy_vector_d3(position[i], dataset->std_positions[i]);
  }

  spg_free_dataset(dataset);

  return n_std_atoms;
}

static int get_standardized_cell(double lattice[3][3],
                                 double position[][3],
                                 int types[],
                                 const int num_atom,
                                 const int to_primitive,
                                 const double symprec,
                                 const double angle_tolerance)
{
  int num_std_atom;
  SpglibDataset *dataset;
  Cell *std_cell, *cell;
  Centering centering;

  num_std_atom = 0;
  dataset = NULL;
  std_cell = NULL;
  cell = NULL;

  if ((dataset = get_dataset(lattice,
                             position,
                             types,
                             num_atom,
                             0,
                             symprec,
			     angle_tolerance)) == NULL) {
    goto err;
  }

  if (to_primitive) {
    if ((centering = get_centering(dataset->hall_number)) == CENTERING_ERROR) {
      goto err;
    }
  } else {
    centering = PRIMITIVE;
  }

  if ((cell = cel_alloc_cell(num_atom)) == NULL) {
    spg_free_dataset(dataset);
    goto err;
  }

  cel_set_cell(cell, lattice, position, types);
  std_cell = spa_transform_to_primitive(cell,
                                        dataset->transformation_matrix,
                                        centering,
                                        symprec);
  spg_free_dataset(dataset);
  cel_free_cell(cell);
  cell = NULL;

  if (std_cell == NULL) {
    goto err;
  }

  set_cell(lattice, position, types, std_cell);
  num_std_atom = std_cell->size;

  cel_free_cell(std_cell);
  std_cell = NULL;

  return num_std_atom;

 err:
  spglib_error_code = SPGERR_CELL_STANDARDIZATION_FAILED;
  return 0;
}

static void set_cell(double lattice[3][3],
                     double position[][3],
                     int types[],
                     Cell * cell)
{
  int i;

  mat_copy_matrix_d3(lattice, cell->lattice);
  for (i = 0; i < cell->size; i++) {
    types[i] = cell->types[i];
    mat_copy_vector_d3(position[i], cell->position[i]);
  }
}

static Centering get_centering(int hall_number)
{
  SpacegroupType spgtype;

  spgtype = spgdb_get_spacegroup_type(hall_number);

  return spgtype.centering;
}

static int get_international(char symbol[11],
                             SPGCONST double lattice[3][3],
                             SPGCONST double position[][3],
                             const int types[],
                             const int num_atom,
                             const double symprec,
			     const double angle_tolerance)
{
  Cell *cell;
  Primitive *primitive;
  Spacegroup spacegroup;

  cell = NULL;
  primitive = NULL;
  spacegroup.number = 0;

  if ((cell = cel_alloc_cell(num_atom)) == NULL) {
    goto err;
  }

  cel_set_cell(cell, lattice, position, types);

  if ((primitive = spa_get_spacegroup(&spacegroup,
				      cell,
				      symprec,
				      angle_tolerance)) == NULL) {
    cel_free_cell(cell);
    cell = NULL;
    goto err;
  }

  prm_free_primitive(primitive);
  primitive = NULL;
  cel_free_cell(cell);
  cell = NULL;

  if (spacegroup.number > 0) {
    strcpy(symbol, spacegroup.international_short);
  } else {
    goto err;
  }

  spglib_error_code = SPGLIB_SUCCESS;
  return spacegroup.number;

 err:
  spglib_error_code = SPGERR_SPACEGROUP_SEARCH_FAILED;
  return 0;
}

static int get_schoenflies(char symbol[7],
                           SPGCONST double lattice[3][3],
                           SPGCONST double position[][3],
                           const int types[],
                           const int num_atom,
                           const double symprec,
                           const double angle_tolerance)
{
  Cell *cell;
  Primitive *primitive;
  Spacegroup spacegroup;

  cell = NULL;
  primitive = NULL;
  spacegroup.number = 0;

  if ((cell = cel_alloc_cell(num_atom)) == NULL) {
    goto err;
  }

  cel_set_cell(cell, lattice, position, types);

  if ((primitive = spa_get_spacegroup(&spacegroup,
				      cell,
				      symprec,
				      angle_tolerance)) == NULL) {
    cel_free_cell(cell);
    cell = NULL;
    goto err;
  }

  prm_free_primitive(primitive);
  primitive = NULL;
  cel_free_cell(cell);
  cell = NULL;

  if (spacegroup.number > 0) {
    strcpy(symbol, spacegroup.schoenflies);
  } else {
    goto err;
  }

  spglib_error_code = SPGLIB_SUCCESS;
  return spacegroup.number;

 err:
  spglib_error_code = SPGERR_SPACEGROUP_SEARCH_FAILED;
  return 0;

}


/*---------*/
/* kpoints */
/*---------*/
static int get_ir_reciprocal_mesh(int grid_address[][3],
                                  int map[],
                                  const int mesh[3],
                                  const int is_shift[3],
                                  const int is_time_reversal,
                                  SPGCONST double lattice[3][3],
                                  SPGCONST double position[][3],
                                  const int types[],
                                  const int num_atom,
                                  const double symprec,
                                  const double angle_tolerance)
{
  SpglibDataset *dataset;
  int num_ir, i;
  MatINT *rotations, *rot_reciprocal;

  if ((dataset = get_dataset(lattice,
                             position,
                             types,
                             num_atom,
                             0,
                             symprec,
			     angle_tolerance)) == NULL) {
    return 0;
  }

  if ((rotations = mat_alloc_MatINT(dataset->n_operations)) == NULL) {
    spg_free_dataset(dataset);
    return 0;
  }

  for (i = 0; i < dataset->n_operations; i++) {
    mat_copy_matrix_i3(rotations->mat[i], dataset->rotations[i]);
  }
  rot_reciprocal = kpt_get_point_group_reciprocal(rotations, is_time_reversal);
  num_ir = kpt_get_irreducible_reciprocal_mesh(grid_address,
                                               map,
                                               mesh,
                                               is_shift,
                                               rot_reciprocal);
  mat_free_MatINT(rot_reciprocal);
  rot_reciprocal = NULL;
  mat_free_MatINT(rotations);
  rotations = NULL;
  spg_free_dataset(dataset);
  return num_ir;
}

static int get_stabilized_reciprocal_mesh(int grid_address[][3],
                                          int map[],
                                          const int mesh[3],
                                          const int is_shift[3],
                                          const int is_time_reversal,
                                          const int num_rot,
                                          SPGCONST int rotations[][3][3],
                                          const int num_q,
                                          SPGCONST double qpoints[][3])
{
  MatINT *rot_real;
  int i, num_ir;

  rot_real = NULL;

  if ((rot_real = mat_alloc_MatINT(num_rot)) == NULL) {
    return 0;
  }

  for (i = 0; i < num_rot; i++) {
    mat_copy_matrix_i3(rot_real->mat[i], rotations[i]);
  }

  num_ir = kpt_get_stabilized_reciprocal_mesh(grid_address,
                                              map,
                                              mesh,
                                              is_shift,
                                              is_time_reversal,
                                              rot_real,
                                              num_q,
                                              qpoints);

  mat_free_MatINT(rot_real);
  rot_real = NULL;

  return num_ir;
}
