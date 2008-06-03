#include <boost/python/module.hpp>
#include <boost/python/class.hpp>
#include <boost/python/def.hpp>
#include <boost/python/args.hpp>
#include <boost/python/list.hpp>

#include <scitbx/mat3.h>
#include <scitbx/constants.h>
#include <scitbx/array_family/ref.h>
#include <boost/shared_array.hpp>

#include <gltbx/error.h>

namespace gltbx { namespace util {

  namespace af = scitbx::af;

  template<typename T>
  struct gl_enum_type_of
  {};

  template<>
  struct gl_enum_type_of<GLfloat>
  {
    static const GLenum type = GL_FLOAT;
  };

  template<>
  struct gl_enum_type_of<GLdouble>
  {
    static const GLenum type = GL_DOUBLE;
  };


  inline
  void
  translate(scitbx::vec3<double> const& t)
  {
    glTranslated(t[0], t[1], t[2]);
  }

  template <typename ElementType>
  boost::python::list
  as_python_list(ElementType* elements, unsigned size)
  {
    boost::python::list result;
    for(unsigned i=0;i<size;i++) result.append(elements[i]);
    return result;
  }

  template <unsigned Size>
  struct gl_vector_as_python_list
  {
    static
    boost::python::list
    int_(GLenum pname)
    {
      GLint vector[Size];
      glGetIntegerv(pname, vector);
      return as_python_list(vector, Size);
    }

    static
    boost::python::list
    double_(GLenum pname)
    {
      GLdouble vector[Size];
      glGetDoublev(pname, vector);
      return as_python_list(vector, Size);
    }
  };

  inline
  boost::python::list
  get_gl_modelview_matrix()
  {
    return gl_vector_as_python_list<16>::double_(GL_MODELVIEW_MATRIX);
  }

  inline
  boost::python::list
  get_gl_projection_matrix()
  {
    return gl_vector_as_python_list<16>::double_(GL_PROJECTION_MATRIX);
  }

  inline
  boost::python::list
  get_gl_viewport()
  {
    return gl_vector_as_python_list<4>::int_(GL_VIEWPORT);
  }

  inline
  scitbx::mat3<double>
  extract_rotation_from_gl_matrix(GLdouble* m)
  {
    return scitbx::mat3<double>(
      m[0], m[4], m[8],
      m[1], m[5], m[9],
      m[2], m[6], m[10]);
  }

  inline
  scitbx::vec3<double>
  extract_translation_from_gl_matrix(GLdouble* m)
  {
    return scitbx::vec3<double>(m[12], m[13], m[14]);
  }

  inline
  scitbx::mat3<double>
  extract_rotation_from_gl_modelview_matrix()
  {
    GLdouble mvm[16];
    glGetDoublev(GL_MODELVIEW_MATRIX, mvm);
    return extract_rotation_from_gl_matrix(mvm);
  }

  inline
  scitbx::vec3<double>
  extract_translation_from_gl_modelview_matrix()
  {
    GLdouble mvm[16];
    glGetDoublev(GL_MODELVIEW_MATRIX, mvm);
    return extract_translation_from_gl_matrix(mvm);
  }

  inline
  scitbx::vec3<double>
  object_as_eye_coordinates(
    scitbx::vec3<double> const& object_coordinates)
  {
    GLdouble mvm[16];
    glGetDoublev(GL_MODELVIEW_MATRIX, mvm);
    return extract_rotation_from_gl_matrix(mvm) * object_coordinates
         + extract_translation_from_gl_matrix(mvm);
  }

  inline
  void
  translate_object(double eye_x, double eye_y, double eye_z)
  {
    GLdouble mvm[16];
    glGetDoublev(GL_MODELVIEW_MATRIX, mvm);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glTranslated(eye_x, eye_y, eye_z);
    glMultMatrixd(mvm);
  }

  inline
  void
  translate_object(scitbx::vec3<double> const& eye_vector)
  {
    translate_object(eye_vector[0], eye_vector[1], eye_vector[2]);
  }

  inline
  void
  translate_object(
    double s,
    double x,
    double y,
    double mousex,
    double mousey)
  {
    translate_object(s * (x - mousex), s * (mousey - y), 0.0);
  }

  inline
  void
  rotate_object_about_eye_x_and_y(
    double s,
    double xcenter,
    double ycenter,
    double zcenter,
    double x,
    double y,
    double mousex,
    double mousey)
  {
    GLdouble mvm[16];
    glGetDoublev(GL_MODELVIEW_MATRIX, mvm);
    scitbx::vec3<double> eye_center =
        extract_rotation_from_gl_matrix(mvm)
          * scitbx::vec3<double>(xcenter, ycenter, zcenter)
      + extract_translation_from_gl_matrix(mvm);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    translate(eye_center);
    glRotated((s * (y - mousey)), 1.0, 0.0, 0.0);
    glRotated((s * (x - mousex)), 0.0, 1.0, 0.0);
    translate(-eye_center);
    glMultMatrixd(mvm);
  }

  inline
  void
  rotate_object_about_eye_vector(
    double xcenter,
    double ycenter,
    double zcenter,
    double xvector,
    double yvector,
    double zvector,
    double angle)
  {
    GLdouble mvm[16];
    glGetDoublev(GL_MODELVIEW_MATRIX, mvm);
    scitbx::vec3<double> eye_center =
        extract_rotation_from_gl_matrix(mvm)
          * scitbx::vec3<double>(xcenter, ycenter, zcenter)
      + extract_translation_from_gl_matrix(mvm);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    translate(eye_center);
    glRotated(angle, xvector, yvector, zvector);
    translate(-eye_center);
    glMultMatrixd(mvm);
  }

  inline
  void
  TranslateScene(
    double s,
    double x,
    double y,
    double mousex,
    double mousey)
  {
    GLdouble mat[16];
    glGetDoublev(GL_MODELVIEW_MATRIX, mat);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glTranslated((s * (x - mousex)), (s * (mousey - y)), 0.0);
    glMultMatrixd(mat);
  }

  inline
  void
  RotateScene(
    double s,
    double xcenter,
    double ycenter,
    double zcenter,
    double x,
    double y,
    double mousex,
    double mousey)
  {
    GLdouble mat[16];
    glGetDoublev(GL_MODELVIEW_MATRIX, mat);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glTranslated(xcenter, ycenter, zcenter);
    glRotated((s * (y - mousey)), 1.0, 0.0, 0.0);
    glRotated((s * (x - mousex)), 0.0, 1.0, 0.0);
    glTranslated(-xcenter, -ycenter, -zcenter);
    glMultMatrixd(mat);
  }

  inline
  void
  RotateAboutVector(
    double xcenter,
    double ycenter,
    double zcenter,
    double xvector,
    double yvector,
    double zvector,
    double angle)
  {
    glMatrixMode(GL_MODELVIEW);
    GLdouble mat[16];
    glGetDoublev(GL_MODELVIEW_MATRIX, mat);
    glLoadIdentity();
    glTranslated(xcenter, ycenter, zcenter);
    glRotated(angle, xvector, yvector, zvector);
    glTranslated(-xcenter, -ycenter, -zcenter);
    glMultMatrixd(mat);
  }

  /// Array of vertices with the associated normals
  /** Implementated with OpenGL vertex arrays. Since OpenGL is a state machine,
  it means it is foolish to construct two such objects and interwin calls to
  draw_xxx
  */
  template<typename T>
  class vertex_array
  {
    public:
      typedef af::const_ref< scitbx::vec3<T> > input_type;
      typedef typename input_type::size_type input_type_size;
      typedef af::tiny<input_type_size,3> triangle;

      /// Construct an array from the given vertices and normals
      vertex_array(input_type const& vertices,
                   input_type const& normals)
        : vertices_(vertices), normals_(normals)
      {
        SCITBX_ASSERT(vertices.size() == normals.size())
                     (vertices.size())(normals.size());
        glVertexPointer(3, gl_enum_type_of<T>::type, 0, vertices.begin());
        glNormalPointer(gl_enum_type_of<T>::type, 0, normals.begin());
      }

      /** Draw the triangles: triangles[i] is a triplet of indices to look
      into the array vertices passed to the constructor */
      void draw_triangles(af::const_ref<triangle> const& triangles) {
        for(std::size_t i=0; i < triangles.size(); i++) {
          glBegin(GL_TRIANGLES);
          for(int j=0; j<3; j++) glArrayElement(triangles[i][j]);
          glEnd();
        }
      }
    private:
      input_type vertices_;
      input_type normals_;
  };

  //! Based on freeglut-2.4.0/src/freeglut_geometry.c
  /* Compute lookup table of cos and sin values forming a cirle
   *
   * Notes:
   *    It is the responsibility of the caller to free these tables
   *    The size of the table is (n+1) to form a connected loop
   *    The last entry is exactly the same as the first
   *    The sign of n can be flipped to get the reverse loop
   */
  struct CircleTable
  {
    boost::shared_array<double> memory;
    double* s;
    double* c;

    CircleTable(int n)
    {
      /* Table size, the sign of n flips the circle direction */
      unsigned size = std::abs(n);
      memory = boost::shared_array<double>(new double[2*(size+1)]);
      s = memory.get();
      c = s + (size+1);

      /* Determine the angle between samples */
      double angle = scitbx::constants::two_pi / (n == 0 ? 1 : n);

      /* Compute cos and sin around the circle */
      s[0] = 0;
      c[0] = 1;
      for (unsigned i=1; i<size; i++) {
        s[i] = std::sin(angle*i);
        c[i] = std::cos(angle*i);
      }

      /* Last sample is duplicate of the first */
      s[size] = 0;
      c[size] = 1;
    }
  };

  //! Based on freeglut-2.4.0/src/freeglut_geometry.c
  void
  SolidSphere(double radius, int slices, int stacks)
  {
    CircleTable ct1(-slices);
    CircleTable ct2(stacks*2);

    /* The top stack is covered with a triangle fan */
    double z0 = 1;
    double z1 = ct2.c[stacks > 0 ? 1 : 0];
    double r0 = 0;
    double r1 = ct2.s[stacks > 0 ? 1 : 0];
    glBegin(GL_TRIANGLE_FAN);
    glNormal3d(0,0,1);
    glVertex3d(0,0,radius);
    for (int j=slices; j>=0; j--) {
      glNormal3d(ct1.c[j]*r1,        ct1.s[j]*r1,        z1       );
      glVertex3d(ct1.c[j]*r1*radius, ct1.s[j]*r1*radius, z1*radius);
    }
    glEnd();

    /* Cover each stack with a quad strip, except the top and bottom stacks */
    for(int i=1; i<stacks-1; i++) {
      z0 = z1;
      z1 = ct2.c[i+1];
      r0 = r1;
      r1 = ct2.s[i+1];
      glBegin(GL_QUAD_STRIP);
      for(int j=0; j<=slices; j++) {
        glNormal3d(ct1.c[j]*r1,        ct1.s[j]*r1,        z1       );
        glVertex3d(ct1.c[j]*r1*radius, ct1.s[j]*r1*radius, z1*radius);
        glNormal3d(ct1.c[j]*r0,        ct1.s[j]*r0,        z0       );
        glVertex3d(ct1.c[j]*r0*radius, ct1.s[j]*r0*radius, z0*radius);
      }
      glEnd();
    }

    /* The bottom stack is covered with a triangle fan */
    z0 = z1;
    r0 = r1;
    glBegin(GL_TRIANGLE_FAN);
    glNormal3d(0,0,-1);
    glVertex3d(0,0,-radius);
    for (int j=0; j<=slices; j++) {
      glNormal3d(ct1.c[j]*r0,        ct1.s[j]*r0,        z0       );
      glVertex3d(ct1.c[j]*r0*radius, ct1.s[j]*r0*radius, z0*radius);
    }
    glEnd();
  }

  //! Based on freeglut-2.4.0/src/freeglut_geometry.c
  void
  WireSphere(double radius, int slices, int stacks)
  {
    CircleTable ct1(-slices);
    CircleTable ct2(stacks*2);

    /* Draw a line loop for each stack */
    for (int i=1; i<stacks; i++) {
      double z = ct2.c[i];
      double r = ct2.s[i];
      glBegin(GL_LINE_LOOP);
      for(int j=0; j<=slices; j++) {
        double x = ct1.c[j];
        double y = ct1.s[j];
        glNormal3d(x,y,z);
        glVertex3d(x*r*radius, y*r*radius, z*radius);
      }
      glEnd();
    }

    /* Draw a line loop for each slice */
    for (int i=0; i<slices; i++) {
      glBegin(GL_LINE_STRIP);
      for(int j=0; j<=stacks; j++) {
        double x = ct1.c[i] * ct2.s[j];
        double y = ct1.s[i] * ct2.s[j];
        double z = ct2.c[j];
        glNormal3d(x,y,z);
        glVertex3d(x*radius, y*radius, z*radius);
      }
      glEnd();
    }
  }

  template<typename T>
  struct vertex_array_wrapper
  {
    typedef vertex_array<T> wt;
    typedef typename wt::input_type const& inp_t;

    static void wrap(char* name) {
      using namespace boost::python;
      class_<wt>(name, no_init)
        .def(init<inp_t, inp_t>((
             arg_("vertices"),
             arg_("normals"))))
        .def("draw_triangles", &wt::draw_triangles)
      ;
    }
  };

  void
  init_module()
  {
    using namespace boost::python;
    def("handle_error", handle_error);
    def("get_gl_modelview_matrix", get_gl_modelview_matrix);
    def("get_gl_projection_matrix", get_gl_projection_matrix);
    def("get_gl_viewport", get_gl_viewport);
    def("extract_rotation_from_gl_modelview_matrix",
      extract_rotation_from_gl_modelview_matrix);
    def("object_as_eye_coordinates", object_as_eye_coordinates, (
      arg_("object_coordinates")));
    def("translate_object",
      (void(*)(double, double, double)) translate_object, (
        arg_("eye_x"),
        arg_("eye_y"),
        arg_("eye_z")));
    def("translate_object",
      (void(*)(scitbx::vec3<double> const&)) translate_object, (
        arg_("eye_vector")));
    def("translate_object",
      (void(*)(double, double, double, double, double)) translate_object, (
        arg_("s"),
        arg_("x"),
        arg_("y"),
        arg_("mousex"),
        arg_("mousey")));
    def("rotate_object_about_eye_x_and_y", rotate_object_about_eye_x_and_y, (
      arg_("s"),
      arg_("xcenter"),
      arg_("ycenter"),
      arg_("zcenter"),
      arg_("x"),
      arg_("y"),
      arg_("mousex"),
      arg_("mousey")));
    def("rotate_object_about_eye_vector", rotate_object_about_eye_vector, (
      arg_("xcenter"),
      arg_("ycenter"),
      arg_("zcenter"),
      arg_("xvector"),
      arg_("yvector"),
      arg_("zvector"),
      arg_("angle")));
    def("TranslateScene", TranslateScene, (
      arg_("s"),
      arg_("x"),
      arg_("y"),
      arg_("mousex"),
      arg_("mousey")));
    def("RotateScene", RotateScene, (
      arg_("s"),
      arg_("xcenter"),
      arg_("ycenter"),
      arg_("zcenter"),
      arg_("x"),
      arg_("y"),
      arg_("mousex"),
      arg_("mousey")));
    def("RotateAboutVector", RotateAboutVector, (
      arg_("xcenter"),
      arg_("ycenter"),
      arg_("zcenter"),
      arg_("xvector"),
      arg_("yvector"),
      arg_("zvector"),
      arg_("angle")));
    def("SolidSphere", SolidSphere, (
      arg_("radius"),
      arg_("slices"),
      arg_("stacks")));
    def("WireSphere", WireSphere, (
      arg_("radius"),
      arg_("slices"),
      arg_("stacks")));
    vertex_array_wrapper<GLdouble>::wrap("vertex_array");
  }

}} // namespace gltbx::util

BOOST_PYTHON_MODULE(gltbx_util_ext)
{
  gltbx::util::init_module();
}
