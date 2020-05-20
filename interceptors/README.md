Interceptors
============

Interceptors are intended for programs that run in the background while the main application of interest executes.
For example, optional tools like performance counter monitors can collect data about an application.

Interceptors implement two bash functions: `interceptor_start` and `interceptor_stop`.
When starting, interceptors must fork their own processes to the background and remember their PID(s).
When stopping, interceptors must kill their own processes cleanly (e.g., to ensure accurate results).

Some interceptors like PCM (`pcm.x`) support forking other applications (similar to `numactl` and `mpiexec`).
While this would probably be cleaner, more likely yield accurate results, and support cleaner failure scenarios, there are several reasons we cannot do this.

* Generality - not all interceptors might support forking child applications.
* Security - some interceptors require `root` privileges to execute, but we can't always (and probably never should) execute the primary applications as root.
* Environment - `sudo` and perhaps some interceptors do not easily (or---by configuration/design---ever) allow passing through all required environment configurations that applications of interest require (e.g., `PATH`, `LD_LIBRARY_PATH`).
