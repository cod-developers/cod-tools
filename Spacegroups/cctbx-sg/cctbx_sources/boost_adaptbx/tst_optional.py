from libtbx.test_utils import Exception_expected
import boost.optional
import sys

def exercise(args):
  forever = "--forever" in args
  while True:
    assert boost.optional.exercise(None) == 42
    assert boost.optional.exercise(13) is None
    assert boost.optional.exercise(0) == 0
    assert boost.optional.exercise(1) == 3
    assert boost.optional.exercise(1.5) == 4
    try:
      boost.optional.exercise("")
    except Exception, e:
      assert str(e).splitlines()[2] == "did not match C++ signature:"
    else:
      raise Exception_expected
    exercise_wstring = getattr(boost.optional, "exercise_wstring", None)
    if (not forever): print "exercise_wstring:", exercise_wstring
    if (exercise_wstring is not None):
      assert boost.optional.exercise_wstring(u"abc") == u"abcabc"
    if (not forever): break
  print "OK"

if (__name__ == "__main__"):
  exercise(sys.argv[1:])
