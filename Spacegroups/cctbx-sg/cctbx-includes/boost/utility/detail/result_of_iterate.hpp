// Boost result_of library

//  Copyright Douglas Gregor 2004. Use, modification and
//  distribution is subject to the Boost Software License, Version
//  1.0. (See accompanying file LICENSE_1_0.txt or copy at
//  http://www.boost.org/LICENSE_1_0.txt)

// For more information, see http://www.boost.org/libs/utility
#if !defined(BOOST_PP_IS_ITERATING)
# error Boost result_of - do not include this file!
#endif

#if defined(BOOST_HAS_DECLTYPE)

// As of N2588, C++0x result_of only supports function call
// expressions of the form f(x). This precludes support for member
// function pointers, which are invoked with expressions of the form
// o->*f(x). This implementation supports both.
template<typename F BOOST_PP_COMMA_IF(BOOST_PP_ITERATION())
         BOOST_PP_ENUM_PARAMS(BOOST_PP_ITERATION(),typename T)>
struct result_of<F(BOOST_PP_ENUM_PARAMS(BOOST_PP_ITERATION(),T))>
    : mpl::if_<
          mpl::or_< is_pointer<F>, is_member_function_pointer<F> >
        , detail::result_of_impl<
              F, F(BOOST_PP_ENUM_PARAMS(BOOST_PP_ITERATION(),T)), false
          >
        , detail::result_of_decltype_impl<
              F(BOOST_PP_ENUM_PARAMS(BOOST_PP_ITERATION(),T))
          >
      >::type
{};

namespace detail {

# define BOOST_RESULT_OF_STATIC_MEMBERS(z, n, _) \
     static T ## n t ## n; \
  /**/

template<typename F BOOST_PP_COMMA_IF(BOOST_PP_ITERATION())
         BOOST_PP_ENUM_PARAMS(BOOST_PP_ITERATION(),typename T)>
class result_of_decltype_impl<F(BOOST_PP_ENUM_PARAMS(BOOST_PP_ITERATION(),T))>
{
  static F f;
  BOOST_PP_REPEAT(BOOST_PP_ITERATION(), BOOST_RESULT_OF_STATIC_MEMBERS, _)
public:
  typedef decltype(f(BOOST_PP_ENUM_PARAMS(BOOST_PP_ITERATION(),t))) type;
};

} // namespace detail 

#else // defined(BOOST_HAS_DECLTYPE)

// CWPro8 requires an argument in a function type specialization
#if BOOST_WORKAROUND(__MWERKS__, BOOST_TESTED_AT(0x3002)) && BOOST_PP_ITERATION() == 0
# define BOOST_RESULT_OF_ARGS void
#else
# define BOOST_RESULT_OF_ARGS BOOST_PP_ENUM_PARAMS(BOOST_PP_ITERATION(),T)
#endif

#if !BOOST_WORKAROUND(__BORLANDC__, BOOST_TESTED_AT(0x551))
template<typename F BOOST_PP_COMMA_IF(BOOST_PP_ITERATION())
         BOOST_PP_ENUM_PARAMS(BOOST_PP_ITERATION(),typename T)>
struct result_of<F(BOOST_RESULT_OF_ARGS)>
    : boost::detail::result_of_impl<F, F(BOOST_RESULT_OF_ARGS), (boost::detail::has_result_type<F>::value)> {};
#endif

#undef BOOST_RESULT_OF_ARGS

#endif // defined(BOOST_HAS_DECLTYPE)

#if BOOST_PP_ITERATION() >= 1 

namespace detail {

template<typename R,  typename FArgs BOOST_PP_COMMA_IF(BOOST_PP_ITERATION())
         BOOST_PP_ENUM_PARAMS(BOOST_PP_ITERATION(),typename T)>
struct result_of_impl<R (*)(BOOST_PP_ENUM_PARAMS(BOOST_PP_ITERATION(),T)), FArgs, false>
{
  typedef R type;
};

template<typename R,  typename FArgs BOOST_PP_COMMA_IF(BOOST_PP_ITERATION())
         BOOST_PP_ENUM_PARAMS(BOOST_PP_ITERATION(),typename T)>
struct result_of_impl<R (&)(BOOST_PP_ENUM_PARAMS(BOOST_PP_ITERATION(),T)), FArgs, false>
{
  typedef R type;
};

#if !BOOST_WORKAROUND(__BORLANDC__, BOOST_TESTED_AT(0x551))
template<typename R, typename FArgs BOOST_PP_COMMA_IF(BOOST_PP_ITERATION())
         BOOST_PP_ENUM_PARAMS(BOOST_PP_ITERATION(),typename T)>
struct result_of_impl<R (T0::*)
                     (BOOST_PP_ENUM_SHIFTED_PARAMS(BOOST_PP_ITERATION(),T)),
                 FArgs, false>
{
  typedef R type;
};

template<typename R, typename FArgs BOOST_PP_COMMA_IF(BOOST_PP_ITERATION())
         BOOST_PP_ENUM_PARAMS(BOOST_PP_ITERATION(),typename T)>
struct result_of_impl<R (T0::*)
                     (BOOST_PP_ENUM_SHIFTED_PARAMS(BOOST_PP_ITERATION(),T))
                     const,
                 FArgs, false>
{
  typedef R type;
};

template<typename R, typename FArgs BOOST_PP_COMMA_IF(BOOST_PP_ITERATION())
         BOOST_PP_ENUM_PARAMS(BOOST_PP_ITERATION(),typename T)>
struct result_of_impl<R (T0::*)
                     (BOOST_PP_ENUM_SHIFTED_PARAMS(BOOST_PP_ITERATION(),T))
                     volatile,
                 FArgs, false>
{
  typedef R type;
};

template<typename R, typename FArgs BOOST_PP_COMMA_IF(BOOST_PP_ITERATION())
         BOOST_PP_ENUM_PARAMS(BOOST_PP_ITERATION(),typename T)>
struct result_of_impl<R (T0::*)
                     (BOOST_PP_ENUM_SHIFTED_PARAMS(BOOST_PP_ITERATION(),T))
                     const volatile,
                 FArgs, false>
{
  typedef R type;
};
#endif

}
#endif
