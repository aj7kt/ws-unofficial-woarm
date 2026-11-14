// Give LLVM libomp worker threads the same 16 MB stack the executables'
// main threads get (see the WIN32 --stack link options).
//
// With gfortran + libgomp on Windows the OpenMP workers inherited the
// executable's stack reserve. LLVM libomp defaults to 4 MB per worker,
// while flang also keeps more local data on the stack than gfortran did,
// so the OpenMP decoders could overflow. An explicit OMP_STACKSIZE or
// KMP_STACKSIZE in the environment still takes precedence.
//
// This file is linked directly into the executables (not via a static
// library) so that its static initializer is never discarded.

#include <cstdlib>
#include <omp.h>

namespace
{
  struct OmpWorkerStackSize
  {
    OmpWorkerStackSize ()
    {
      if (!std::getenv ("OMP_STACKSIZE") && !std::getenv ("KMP_STACKSIZE"))
        {
          kmp_set_stacksize_s (std::size_t {16} << 20);
        }
    }
  } const omp_worker_stack_size;
}
