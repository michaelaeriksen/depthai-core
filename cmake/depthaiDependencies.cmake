# Intentionally empty.
#
# Upstream resolves dependencies here with a mix of FetchContent and find_package.
# This fork resolves every dependency through find_package in source/CMakeLists.txt so that
# a package manager supplies them, and nothing is fetched from the network at configure time.
# The file is kept so that upstream includes of it continue to resolve.
