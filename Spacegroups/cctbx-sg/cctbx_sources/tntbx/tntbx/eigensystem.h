#ifndef TNTBX_EIGENSYSTEM_H
#define TNTBX_EIGENSYSTEM_H

#include <tntbx/import_scitbx_af.h>
#include <scitbx/mat_ref.h>
#include <scitbx/sym_mat3.h>
#include <scitbx/array_family/versa.h>
#include <scitbx/array_family/shared.h>
#include <scitbx/array_family/accessors/c_grid.h>

#include <jama_eig.h>

namespace tntbx {

  // get_eigenvectors wrapper for JAMA getV
  af::versa<double, af::c_grid<2> >
    get_eigenvectors(
                     af::ref<double, af::c_grid<2> > const& square_matrix
                     )
    {
      unsigned nrows = square_matrix.accessor()[0];
      unsigned ncols = square_matrix.accessor()[1];

      SCITBX_ASSERT (nrows == ncols);

      af::versa<double, af::c_grid<2> > eigenvectors(square_matrix.accessor());
      TNT::Array2D<double> A(nrows, nrows, square_matrix.begin());
      JAMA::Eigenvalue<double> tnt_eigen(A);
      TNT::Array2D<double> V(nrows, nrows);
      tnt_eigen.getV(V);
      for(int i=0;i<nrows;i++)
        {
          for(int j=0;j<nrows;j++)
            {
              eigenvectors(nrows-j-1,i) = V[i][j];
            }
        }
      return eigenvectors;
    }
  // get_eigen_vectors

  //! Group of associated eigenvectors and eigenvalues.
  template <typename FloatType = double>
    class real
    {
      public:
      //! Default constructor.
      real() {}

      /*! \brief Determines the eigenvectors and eigenvalues of the
          real square matrix.
       */
      real(TNT::Array2D<FloatType> const& m);

      /*! \brief Determines the eigenvectors and eigenvalues of the
          real square matrix.
       */
      real(scitbx::mat_const_ref<FloatType> const& m);

      /*! \brief Determines the eigenvectors and eigenvalues of the
          real square matrix.
       */
      real(af::const_ref<FloatType, af::c_grid<2> > const& m);

      /*! \brief Determines the eigenvectors and eigenvalues of the
          real square matrix.
       */
      real(scitbx::sym_mat3<FloatType> const& m);

      //! The list of eigenvectors.
      af::versa<FloatType, af::c_grid<2> >
      vectors() const
      {
        unsigned nrows = square_matrix_.dim1();
        af::versa<FloatType, af::c_grid<2> > vectors_(af::c_grid<2>(
                                                                    nrows,
                                                                    nrows
                                                                    )
                                                      );
        TNT::Array2D<FloatType> v(nrows, nrows);
        tnt_eigensystem_.getV(v);
        for(int i=0;i<nrows;i++)
          {
            for(int j=0;j<nrows;j++)
              {
                vectors_(nrows-j-1,i) = v[i][j];
              }
          }
        return vectors_;
      }

      //! The eigenvalues.
      af::shared<FloatType>
      values() const
      {
        unsigned nrows = square_matrix_.dim1();
        af::shared<FloatType> values_(nrows);
        TNT::Array1D<FloatType> v(nrows);
        tnt_eigensystem_.getRealEigenvalues(v);
        for(int i=0;i<nrows;i++)
          {
            values_[nrows-i-1] = v[i];
          }
        return values_;
      }

    private:
      //af::shared<FloatType> values_;
      TNT::Array2D<FloatType> square_matrix_;
      mutable JAMA::Eigenvalue<FloatType> tnt_eigensystem_;

      void
      initialize(TNT::Array2D<FloatType> const& m);
    };
    // real class

    template <typename FloatType>
    real<FloatType>::real(
      TNT::Array2D<FloatType> const& m
      )
    {
      initialize(m);
    }

    template <typename FloatType>
    real<FloatType>::real(
       scitbx::mat_const_ref<FloatType> const& m
       )
    {
      unsigned nrows = m.accessor()[0];
      unsigned ncols = m.accessor()[1];

      SCITBX_ASSERT (m.is_square());

      TNT::Array2D<FloatType> a(nrows, nrows);
      for(int i=0;i<nrows;i++)
        {
          for(int j=0;j<nrows;j++)
            {
              a[i][j] = m(i,j);
            }
        }

      initialize(a);
    }

    template <typename FloatType>
    real<FloatType>::real(
      af::const_ref<FloatType, af::c_grid<2> > const& m
      )
    {
      unsigned nrows = m.accessor()[0];
      unsigned ncols = m.accessor()[1];

      SCITBX_ASSERT (nrows == ncols);

      TNT::Array2D<FloatType> a(nrows, nrows);
      for(int i=0;i<nrows;i++)
        {
          for(int j=0;j<nrows;j++)
            {
              a[i][j] = m(i,j);
            }
        }
      initialize(a);
    }

    template <typename FloatType>
    real<FloatType>::real(scitbx::sym_mat3<FloatType> const& m)
    {
      unsigned nrows = 3;
      TNT::Array2D<FloatType> a(nrows, nrows);
      for(int i=0;i<nrows;i++)
        {
          for(int j=0;j<nrows;j++)
            {
              a[i][j] = m(i,j);
            }
        }
      initialize(a);
    }

    template <typename FloatType>
    void
    real<FloatType>::initialize(
      TNT::Array2D<FloatType> const& m
      )
    {
      SCITBX_ASSERT(m.dim1() == m.dim2());
      square_matrix_=m;
      tnt_eigensystem_ = JAMA::Eigenvalue<FloatType>(m);
    }

} // namespace tntbx

#endif //TNTBX_EIGENSYSTEM_H
