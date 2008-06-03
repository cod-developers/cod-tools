#ifndef SCITBX_HISTOGRAM_H
#define SCITBX_HISTOGRAM_H

#include <scitbx/array_family/shared.h>
#include <scitbx/array_family/ref_reductions.h>

namespace scitbx {

  //! Histogram of an array of scalar values.
  template <typename ValueType = double,
            typename CountType = long>
  class histogram
  {
    public:
      histogram() {}

      //! Computation of the histogram.
      template <typename DataType>
      histogram(
        af::const_ref<DataType> const& data,
        std::size_t n_slots=1000)
      :
        data_min_(0),
        data_max_(0),
        slot_width_(0),
        slots_(n_slots),
        n_out_of_slot_range_(0)
      {
        SCITBX_ASSERT(n_slots > 0);
        if (data.size() == 0) return;
        data_min_ = af::min(data);
        data_max_ = af::max(data);
        slot_width_ = (data_max_ - data_min_) / slots_.size();
        for(std::size_t i=0;i<data.size();i++) {
          assign_to_slot(static_cast<ValueType>(data[i] - data_min_));
        }
      }

      //! Histogram using user-defined data_min(), data_max().
      template <typename DataType>
      histogram(
        af::const_ref<DataType> const& data,
        DataType const& data_min,
        DataType const& data_max,
        std::size_t n_slots=1000,
        ValueType const& relative_tolerance=1.e-4)
      :
        data_min_(data_min),
        data_max_(data_max),
        slot_width_(0),
        slots_(n_slots),
        n_out_of_slot_range_(0)
      {
        SCITBX_ASSERT(data_max > data_min);
        SCITBX_ASSERT(n_slots > 0);
        if (data.size() == 0) return;
        slot_width_ = (data_max_ - data_min_) / slots_.size();
        assign_to_slots(data, relative_tolerance);
      }

      //! Histogram using slots of other.
      template <typename DataType>
      histogram(
        histogram const& other,
        af::const_ref<DataType> const& data,
        ValueType const& relative_tolerance=1.e-4)
      :
        data_min_(other.data_min_),
        data_max_(other.data_max_),
        slot_width_(other.slot_width_),
        slots_(other.slots_.size()),
        n_out_of_slot_range_(0)
      {
        assign_to_slots(data, relative_tolerance);
      }

      //! Minimum slot cutoff.
      ValueType
      data_min() const { return data_min_; }

      //! Maximum slot cutoff.
      ValueType
      data_max() const { return data_max_; }

      //! Slot width used in the determination of the histogram.
      ValueType
      slot_width() const { return slot_width_; }

      //! Direct access to the array of counts.
      af::shared<CountType>
      slots() const { return slots_; }

      //! Number of unaccounted data values.
      std::size_t
      n_out_of_slot_range() const { return n_out_of_slot_range_; }

      //! Determination of the cutoff value given a maximum number of points.
      ValueType
      get_cutoff(CountType const& max_points,
                 ValueType const& relative_tolerance=1.e-4) const
      {
        CountType cum = 0;
        std::size_t i = slots_.size();
        for (; i; i--) {
          cum += slots_[i-1];
          if (cum > max_points) break;
        }
        return data_min_ + i * slot_width_ + slot_width_ * relative_tolerance;
      }

    protected:
      void
      assign_to_slot(ValueType const& d)
      {
        std::size_t i_slot = 0;
        if (d != 0 && d >= slot_width_) {
              i_slot = static_cast<std::size_t>(d / slot_width_);
          if (i_slot >= slots_.size()) i_slot = slots_.size() - 1;
        }
        slots_[i_slot]++;
      }

      template <typename DataType>
      void
      assign_to_slots(
        af::const_ref<DataType> const& data,
        ValueType const& relative_tolerance)
      {
        ValueType width_tolerance = slot_width_ * relative_tolerance;
        for(std::size_t i=0;i<data.size();i++) {
          if (   data[i] < data_min_ - width_tolerance
              || data[i] > data_max_ + width_tolerance) {
            n_out_of_slot_range_++;
          }
          else {
            assign_to_slot(static_cast<ValueType>(data[i] - data_min_));
          }
        }
      }

      ValueType data_min_;
      ValueType data_max_;
      ValueType slot_width_;
      af::shared<CountType> slots_;
      std::size_t n_out_of_slot_range_;
  };

} // namespace scitbx

#endif // SCITBX_HISTOGRAM_H
