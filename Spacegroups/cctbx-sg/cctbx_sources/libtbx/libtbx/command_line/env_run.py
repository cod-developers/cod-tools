import libtbx.load_env
import sys, os

def run():
  if (len(sys.argv) < 3):
    raise RuntimeError(
      "usage: libtbx.env_run MODULE_DIST path/to/command [arg ...]")
  try:
    cmd_root = os.environ[sys.argv[1]]
  except KeyError:
    raise RuntimeError('Environment variable "%s" not defined.' % sys.argv[1])
  args = []
  if (sys.argv[2].lower().endswith(".py")):
    args.append(sys.executable)
  args.append(os.path.normpath(os.path.join(cmd_root, sys.argv[2])))
  args.extend(sys.argv[3:])
  if (not os.path.isfile(args[0])):
    raise RuntimeError("No such file: %s" % args[0])
  if (not os.access(args[0], os.X_OK)):
    raise RuntimeError("Permission denied: %s" % args[0])
  sys.exit(os.spawnv(os.P_WAIT, args[0], args))

if (__name__ == "__main__"):
  run()
