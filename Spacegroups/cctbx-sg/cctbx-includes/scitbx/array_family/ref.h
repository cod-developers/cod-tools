#ifndef SCITBX_ARRAY_FAMILY_REF_H
#define SCITBX_ARRAY_FAMILY_REF_H

#include <scitbx/array_family/error.h>
#include <scitbx/array_family/accessors/trivial.h>
#include <scitbx/array_family/detail/ref_helpers.h>
#include <algorithm>

namespace scitbx { namespace af {

  template <typename ElementType,
            typename AccessorType = trivial_accessor>
  class const_ref
  {
    public:
      SCITBX_ARRAY_FAMILY_TYPEDEFS

      typedef AccessorType accessor_type;
      typedef typename accessor_type::index_type index_type;
      typedef typename accessor_type::index_value_type index_value_type;

      const_ref() {}

      const_ref(const ElementType* begin, accessor_type const& accessor)
      : begin_(begin), accessor_(accessor)
      {
        init();
      }

      // convenience constructors
      const_ref(const ElementType* begin, index_value_type const& n0)
      : begin_(begin), accessor_(n0)
      {
        init();
      }

      const_ref(const ElementType* begin, index_value_type const& n0,
                                          index_value_type const& n1)
      : begin_(begin), accessor_(n0, n1)
      {
        init();
      }

      const_ref(const ElementType* begin, index_value_type const& n0,
                                          index_value_type const& n1,
                                          index_value_type const& n2)
      : begin_(begin), accessor_(n0, n1, n2)
      {
        init();
      }

      accessor_type const& accessor() const { return accessor_; }
      size_type size() const { return size_; }

      const ElementType* begin() const { return begin_; }
      const ElementType* end() const { return end_; }
      const_reverse_iterator rbegin() const {
        return const_reverse_iterator(end_);
      }
      const_reverse_iterator rend() const {
        return const_reverse_iterator(begin_);
      }
      ElementType const& front() const { return begin_[0]; }
      ElementType const& back() const { return end_[-1]; }

      ElementType const&
      operator[](size_type i) const { return begin_[i]; }

      ElementType const&
      at(size_type i) const
      {
        if (i >= size_) throw_range_error();
        return begin_[i];
      }

      const_ref<ElementType>
      as_1d() const
      {
        return const_ref<ElementType>(begin_, size_);
      }

      value_type const&
      operator()(index_type const& i) const
      {
        return begin_[accessor_(i)];
      }

      // Convenience operator()
      value_type const& operator()(index_value_type const& i0) const
      {
        return begin_[accessor_(i0)];
      }

      value_type const& operator()(index_value_type const& i0,
                                   index_value_type const& i1) const
      {
        return begin_[accessor_(i0, i1)];
      }

      value_type const& operator()(index_value_type const& i0,
                                   index_value_type const& i1,
                                   index_value_type const& i2) const
      {
        return begin_[accessor_(i0, i1, i2)];
      }

      bool all_eq(const_ref const& other) const;

      bool all_eq(ElementType const& other) const;

      bool all_ne(const_ref const& other) const;

      bool all_ne(ElementType const& other) const;

      bool all_lt(const_ref const& other) const;

      bool all_lt(ElementType const& other) const;

      bool all_gt(const_ref const& other) const;

      bool all_gt(ElementType const& other) const;

      bool all_le(const_ref const& other) const;

      bool all_le(ElementType const& other) const;

      bool all_ge(const_ref const& other) const;

      bool all_ge(ElementType const& other) const;

      bool
      all_approx_equal(
        const_ref const& other,
        ElementType const& tolerance) const;

      bool
      all_approx_equal(
        ElementType const& other,
        ElementType const& tolerance) const;

    protected:
      void
      init()
      {
        size_ = accessor_.size_1d();
        end_ = begin_ + size_;
      }

      const ElementType* begin_;
      accessor_type accessor_;
      size_type size_;
      const ElementType* end_;
  };

  template <typename ElementType,
            typename AccessorType = trivial_accessor>
  class ref : public const_ref<ElementType, AccessorType>
  {
    public:
      SCITBX_ARRAY_FAMILY_TYPEDEFS

      typedef const_ref<ElementType, AccessorType> base_class;
      typedef AccessorType accessor_type;
      typedef typename accessor_type::index_type index_type;
      typedef typename accessor_type::index_value_type index_value_type;

      ref() {}

      ref(ElementType* begin, accessor_type accessor)
      : base_class(begin, accessor)
      {}

      // convenience constructors
      ref(ElementType* begin, index_value_type const& n0)
      : base_class(begin, n0)
      {}

      ref(ElementType* begin, index_value_type const& n0,
                              index_value_type const& n1)
      : base_class(begin, n0, n1)
      {}

      ref(ElementType* begin, index_value_type const& n0,
                              index_value_type const& n1,
                              index_value_type const& n2)
      : base_class(begin, n0, n1, n2)
      {}

      ElementType*
      begin() const { return const_cast<ElementType*>(this->begin_); }

      ElementType*
      end() const { return const_cast<ElementType*>(this->end_); }

      reverse_iterator rbegin() const {
        return reverse_iterator(this->end_);
      }

      reverse_iterator rend() const {
        return reverse_iterator(this->begin_);
      }

      ElementType&
      front() const { return begin()[0]; }

      ElementType&
      back() const { return end()[-1]; }

      ElementType&
      operator[](size_type i) const { return begin()[i]; }

      ElementType&
      at(size_type i) const
      {
        if (i >= this->size_) throw_range_error();
        return begin()[i];
      }

      ref const&
      fill(ElementType const& x) const
      {
        std::fill(begin(), end(), x);
        return *this;
      }

      ref<ElementType>
      as_1d() const
      {
        return ref<ElementType>(this->begin(), this->size_);
      }

      value_type&
      operator()(index_type const& i) const
      {
        return begin()[this->accessor_(i)];
      }

      // Convenience operator()
      value_type&
      operator()(index_value_type const& i0) const
      {
        return begin()[this->accessor_(i0)];
      }

      value_type&
      operator()(index_value_type const& i0,
                 index_value_type const& i1) const
      {
        return begin()[this->accessor_(i0, i1)];
      }

      value_type&
      operator()(index_value_type const& i0,
                 index_value_type const& i1,
                 index_value_type const& i2) const
      {
        return begin()[this->accessor_(i0, i1, i2)];
      }
  };

  template <typename ArrayType>
  const_ref<typename ArrayType::value_type>
  make_const_ref(ArrayType const& a)
  {
    typedef typename ArrayType::value_type value_type;
    typedef const_ref<value_type> return_type;
    typedef typename return_type::accessor_type accessor_type;
    return return_type(
      (a.size() == 0 ? 0 : &(*(a.begin()))),
      accessor_type(a.size()));
  }

  template <typename ArrayType>
  ref<typename ArrayType::value_type>
  make_ref(ArrayType& a)
  {
    typedef typename ArrayType::value_type value_type;
    typedef ref<value_type> return_type;
    typedef typename return_type::accessor_type accessor_type;
    return return_type(
      (a.size() == 0 ? 0 : &(*(a.begin()))),
      accessor_type(a.size()));
  }

}} // namespace scitbx::af

#endif // SCITBX_ARRAY_FAMILY_REF_H
