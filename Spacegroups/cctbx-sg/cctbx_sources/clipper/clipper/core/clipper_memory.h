/*! \file lib/clipper_memory.h
    Header file for clipper memory handlers
*/
//C Copyright (C) 2000-2004 Kevin Cowtan and University of York
//C Copyright (C) 2000-2005 Kevin Cowtan and University of York
//L
//L  This library is free software and is distributed under the terms
//L  and conditions of version 2.1 of the GNU Lesser General Public
//L  Licence (LGPL) with the following additional clause:
//L
//L     `You may also combine or link a "work that uses the Library" to
//L     produce a work containing portions of the Library, and distribute
//L     that work under terms of your choice, provided that you give
//L     prominent notice with each copy of the work that the specified
//L     version of the Library is used in it, and that you include or
//L     provide public access to the complete corresponding
//L     machine-readable source code for the Library including whatever
//L     changes were used in the work. (i.e. If you make changes to the
//L     Library you must distribute those, but you do not need to
//L     distribute source or object code to those portions of the work
//L     not covered by this licence.)'
//L
//L  Note that this clause grants an additional right and does not impose
//L  any additional restriction, and so does not affect compatibility
//L  with the GNU General Public Licence (GPL). If you wish to negotiate
//L  other terms, please contact the maintainer.
//L
//L  You can redistribute it and/or modify the library under the terms of
//L  the GNU Lesser General Public License as published by the Free Software
//L  Foundation; either version 2.1 of the License, or (at your option) any
//L  later version.
//L
//L  This library is distributed in the hope that it will be useful, but
//L  WITHOUT ANY WARRANTY; without even the implied warranty of
//L  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//L  Lesser General Public License for more details.
//L
//L  You should have received a copy of the CCP4 licence and/or GNU
//L  Lesser General Public License along with this library; if not, write
//L  to the CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
//L  The GNU Lesser General Public can also be obtained by writing to the
//L  Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
//L  MA 02111-1307 USA


#ifndef CLIPPER_MEMORY
#define CLIPPER_MEMORY


#include "clipper_message.h"
#include <vector>


namespace clipper
{

  //! Base class for properties of arbitrary types
  class Property_base
  {
  public:
    virtual Property_base* clone() const = 0;         //!< factory copy method
    virtual ~Property_base() {};                      //!< destructor
  };

  //! Template for a property holding an arbitrary type
  template<class T> class Property : public Property_base
  {
  public:
    //! constructor: takes contents
    explicit Property( const T& val ) { val_ = val; }
    ~Property() {}
    Property_base* clone() const { return new Property<T>( *this ); }
    const T& value() const { return val_; }   //!< return value of contents
  private:
    T val_;
  };

  //! Class for holding a list of labelled properties of arbitrary types
  /*! To add a property list to an object, derive it from this class,
    or include a member and mirror the methods. To add a property,
    simply call insert_property(label,property). Properties must be
    objects derived from clipper::Propert_base. Usually, you can just
    use the template form, clipper::Property<T>.

    To read a property which you know exists and is of a particular type, use:
    \code
    const T& obj = dynamic_cast<const Property<T>& >(list.get_property( label )).value();
    \endcode
    If you are unsure if a property is present, use the exists_property(label) method. If you are unsure of a property's type, dynamic cast a pointer and test for null. e.g.
    \code
    if ( !list.exists_property( label ) ) { error("No such property"); }
    const Property_base* ptr = &list.get_property( label );
    if ( dynamic_cast<const T*>(ptr) == NULL )  { error("Wrong type"); }
    const T& obj = *(dynamic_cast<const T*>(ptr));
    \endcode */
  class PropertyManager
  {
  public:
    PropertyManager() {}                            //!< null constructor
    PropertyManager( const PropertyManager& mgr );  //!< copy constructor
    PropertyManager& operator =( const PropertyManager& mgr );  //!< assign op
    ~PropertyManager();                             //!< destructor
    PropertyManager& copy( const PropertyManager& mgr );  //!< copy manager
    //! add a labelled property to the list
    bool set_property(const std::string& label, const Property_base& property);
    //! get a labelled property from the list
    const Property_base& get_property( const std::string& label ) const;
    bool exists_property(const std::string& label) const; //!< test for property
    bool delete_property(const std::string& label);       //!< delete property
  private:
    std::vector<std::pair<std::string,Property_base*> > property_;
  };


  //! Object Cache manager
  /*! The object cache is a tool for storing information which may
    appear several times. Examples include tables of information for
    spacegroups or crystallographic maps. When a new object is
    created, a check is first done to see if such an object already
    exists in the cache, in which case that copy is used. Otherwise a
    new copy is added to the cache.

    A cached object must implement:
     - a constructor from a type T
     - a method 'matches(T)' which tests if it constructed from that object
     - a 'format()' method, returning a string description of the contents
    The type T should be a compact unique description of the object.

    Referring to the cache returns an ObjectCache<T>::Reference to a
    cache object. This object performs reference counting, which is
    used for garbage collection.

    To retrieve the actual cached data, use the
    ObjectCache<T>::Reference::data() method. The data is held at a
    fixed memory location, therefore pointers to the data may be
    safely kept, as long as they are discarded as soon as the
    reference is discarded (at which point garbage collection may
    occur).

    Ideally this would be a class with static members only, but some
    compilers have trouble with static members of template classes. */
  template<class T> class ObjectCache
  {
  public:
    //! ObjectCache reference class
    class Reference
    {
    public:
      Reference()                         : obj_(NULL) {}
      Reference( std::pair<int,T>* obj )  : obj_(NULL) { ref( obj ); }
      Reference( const Reference& other ) : obj_(NULL) { ref( other.obj_ ); }
      ~Reference() { ref( NULL ); }
      Reference& operator =( const Reference& other )
	{ ref( other.obj_ ); return *this; }
      bool is_null() const { return obj_ == NULL; }
      const T& data() const { return obj_->second; }
    private:
      std::pair<int,T>* obj_;
      //! reference/dereference data
      void ref( std::pair<int,T>* obj )
	{ if ( !is_null() ) obj_->first--;
	  obj_ = obj;
	  if ( !is_null() ) obj_->first++; }
    };

    enum MODE { NORMAL, MINMEM, MAXMEM };  //!< garbage collection mode
    ObjectCache();   //!< constructor
    ~ObjectCache();  //!< destructor, can message on contents
    void set_mode( const MODE& mode );  //!< set garbage collection mode
    void debug() const;
    //! cache or return data by key
    template<class K> Reference cache( const K& key )
      {
	for ( int i = 0; i < cache_.size(); i++ )  // find existing data
	  if ( cache_[i]->second.matches(key) )
	    return Reference( cache_[i] );
	// optional garbage collection
      delloop:
	for ( int i = 0; i < cache_.size(); i++ )
	  if ( cache_[i]->first == 0 )
	    if ( mode_ == MINMEM ) {  // MINMEM: delete all unused items
	      delete cache_[i];
	      cache_.erase( cache_.begin() + i );
	      goto delloop;
	    } else if ( mode_ == NORMAL ) {  // NORMAL: replace unreferenced
	      cache_[i]->second = T(key);
	      return Reference( cache_[i] );
	    }
	// otherwise add new
	cache_.push_back( new std::pair<int,T>( 0, T(key) ) );
	return Reference( cache_.back() );
      }
  private:
    std::vector<std::pair<int,T>*> cache_;  //!< the cache ptrs
    MODE mode_;  //!< the garbage collection mode

    friend class ObjectCache<T>::Reference;
  };


  // template implementations

  template<class T> ObjectCache<T>::ObjectCache()
    { mode_ = NORMAL; }

  template<class T> ObjectCache<T>::~ObjectCache()
  {
    for ( int i = 0; i < cache_.size(); i++ ) {
      if ( cache_[i]->first != 0 ) {
	std::string num( "0000" );
	num[3] += cache_[i]->first % 10;
	num[2] += cache_[i]->first / 10 % 10;
	num[1] += cache_[i]->first / 100 % 10;
	num[0] += cache_[i]->first / 1000;
	Message::message( Message_warn( "ObjectCache: Leaked "+num+" refs to <"+cache_[i]->second.format()+">" ) );
      }
    }
  }

  /*! Garbage collection modes include:
     - ObjectCache<T>::NORMAL : Remove an old object only when a new object is required and an old object is no longer in use. (default)
     - ObjectCache<T>::MINMEM : Remove an old object as soon as it is no longer in use.
     - ObjectCache<T>::MAXMEM : Never remove old objects.
    The more memory hungry modes may improve performance for some
    problems where a new object may be created which was already used
    and destroyed before.
    \param mode The garbage collection mode. */
  template<class T> void ObjectCache<T>::set_mode( const MODE& mode )
    { mode_ = mode; }

  /*
  template<class T> template<class K>
    ObjectCache<T>::Reference ObjectCache<T>::cache<K>( const K& key )
  */

  template<class T> void ObjectCache<T>::debug() const
  {
    for ( int i = 0; i < cache_.size(); i++ )
      std::cout << "Cache pos: " << i << "\t   Refs: " << cache_[i]->first
		<< "\t" << cache_[i]->second.format() << "\n";
  }


} // namespace clipper

#endif
