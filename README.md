# pidfile
Run an IO action protected by a pidfile.

    withPidFile path act

creates a pidfile at the specified `path`
containing the Process ID of the current process. Then `act` is run,
the pidfile is removed and the result of `act` returned wrapped in a
`Just`.

If the pidfile already exists, `act` is not run, and `Nothing` is returned.
Any other error while creating the pidfile results in an error.

If an exception is raised in `act`, the pidfile is removed before
the exception is propagated.

The pidfile is created with `O_CREAT` and `O_EXCL` flags to ensure that
an already existing pidfile is never accidentally overwitten.