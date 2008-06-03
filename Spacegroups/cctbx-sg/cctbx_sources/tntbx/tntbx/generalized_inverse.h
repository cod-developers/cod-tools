#ifndef TNTBX_GENERALIZED_INVERSE_H
#define TNTBX_GENERALIZED_INVERSE_H

#include <tntbx/import_scitbx_af.h>
#include <scitbx/array_family/ref.h>
#include <jama_svd.h>

namespace tntbx {

  // generalized_inverse wrapper based on JAMA SVD
  af::versa<double, af::c_grid<2> >
  generalized_inverse(
    af::const_ref<double, af::c_grid<2> > const& square_matrix)
  {
    unsigned nrows = square_matrix.accessor()[0];
    unsigned ncols = square_matrix.accessor()[1];

    SCITBX_ASSERT (nrows == ncols);

    af::versa<double, af::c_grid<2> > inverse(square_matrix.accessor());

    JAMA::SVD<double> tnt_svd(
      TNT::Array2D<double>(
        nrows, nrows, const_cast<double*>(square_matrix.begin())));
    TNT::Array2D<double> svd_u, svd_s, svd_v;
    tnt_svd.getU(svd_u);
    tnt_svd.getS(svd_s);
    tnt_svd.getV(svd_v);
    unsigned rank = tnt_svd.rank();

    for(int i=0;i<rank;i++)
      {
        svd_s[i][i] = 1/svd_s[i][i];
      }
    TNT::Array2D<double> tnt_inverse = matmult(svd_v, svd_s);
    double sum;
    // copy tnt inverse to versa array
    for(int i=0;i<nrows;i++)
      {
        for(int j=0;j<nrows;j++)
          {
            sum = 0;
            for(int k=0;k<nrows;k++)
              {
                sum += tnt_inverse[i][k] * svd_u[j][k];
              }
            inverse(i,j) = sum;
          }
      }
    return inverse;
  }

} // namespace tntbx

#endif // TNTBX_GENERALIZED_INVERSE_H
