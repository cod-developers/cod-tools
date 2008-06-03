#ifndef SCITBX_MATH_UTILS_H
#define SCITBX_MATH_UTILS_H

#include <cmath>

namespace scitbx { namespace math {

  template <typename NumType1, typename NumType2>
  inline
  NumType1&
  update_min(NumType1& m, NumType2 const& x)
  {
    if (m > x) m = x;
    return m;
  }

  template <typename NumType1, typename NumType2>
  inline
  NumType1&
  update_max(NumType1& m, NumType2 const& x)
  {
    if (m < x) m = x;
    return m;
  }

  template <typename FloatType>
  FloatType
  round(FloatType x, int n_digits=0)
  {
    // based on Python/bltinmodule.c: builtin_round()
    FloatType f = 1;
    int i = n_digits;
    if (i < 0) i = -i;
    while (--i >= 0) f *= 10;
    if (n_digits < 0) x /= f;
    else              x *= f;
    if (x >= 0) x = std::floor(x + 0.5);
    else        x = std::ceil(x - 0.5);
    if (n_digits < 0) x *= f;
    else              x /= f;
    return x;
  }

  template <typename FloatType,
            typename SignedIntType>
  struct float_int_conversions
  {
    static
    inline
    SignedIntType
    iround(FloatType const& x)
    {
      if (x < 0) return static_cast<SignedIntType>(x-0.5);
      return static_cast<SignedIntType>(x+.5);
    }

    static
    inline
    SignedIntType
    iceil(FloatType const& x) { return iround(std::ceil(x)); }

    static
    inline
    SignedIntType
    ifloor(FloatType const& x) { return iround(std::floor(x)); }

    static
    inline
    SignedIntType
    nearest_integer(FloatType const& x)
    {
      SignedIntType i = static_cast<SignedIntType>(x);
      FloatType dxi = x - static_cast<FloatType>(i);
      if (x >= 0) {
        if (dxi > 0.5) i++;
        else if (dxi == 0.5 && (i & 1)) i++;
      }
      else {
        if (x - static_cast<FloatType>(i) < -0.5) i--;
        else if (dxi == -0.5 && (i & 1)) i--;
      }
      return i;
    }
  };

  inline
  int
  iround(double x) { return float_int_conversions<double,int>::iround(x); }

  inline
  int
  iceil(double x) { return float_int_conversions<double,int>::iceil(x); }

  inline
  int
  ifloor(double x) { return float_int_conversions<double,int>::ifloor(x); }

  inline
  int
  nearest_integer(double x)
  {
    return float_int_conversions<double,int>::nearest_integer(x);
  }

  template <typename UnsignedIntType, typename SizeType>
  bool
  unsigned_product_leads_to_overflow(
    UnsignedIntType* a,
    SizeType n)
  {
    // The author (rwgk) is not certain if this implementation works
    // under all circumstances.
    UnsignedIntType p = a[0];
    for(SizeType i=1;i<n;i++) {
      UnsignedIntType pp = p;
      p *= a[i];
      if (p == 0) return false;
      if (p < pp) return true;
      if (p / a[i] != pp) return true;
      if (p - pp != pp * (a[i]-1)) return true;
    }
    return false;
  }

  /// Quotient and remainder of x/y for floating point x and y
  /** The static function divmod returns n,r such that:
        - n is the nearest integer to x/y
        - r = x - n*y
  */
  template<typename FloatType, typename SignedIntType>
  struct remainder_and_quotient {
    static inline
    std::pair<SignedIntType, FloatType>
    divmod(FloatType x, FloatType y) {
      SignedIntType quo
        = float_int_conversions<FloatType, SignedIntType>::nearest_integer(x/y);
      FloatType rem = x - quo*y;
      return std::make_pair(quo, rem);
    }
  };

  inline std::pair<int, double> divmod(double x, double y) {
    return remainder_and_quotient<double, int>::divmod(x,y);
  }


}} // namespace scitbx::math

#endif // SCITBX_MATH_UTILS_H
