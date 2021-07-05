Using the CppCoro library on Ubuntu 20.04 LTS
=============================================

I wanted to try out the C++20 coroutines feature.

While they added `co_yield` etc. in C++20, they didn't standardize the Coroutines library in time for C++20 and this has been left as a task for C++23.

In the meantime, you can use the CppCoro library.

Coroutine support is not yet available in the 9.x version of `gcc` that's available on the current Ubuntu LTS version, i.e. 20.04.

So I decided to create the Docker setup, described below, to create an environment where the CppCoro and the latest version of `gcc` are available such that I can use them almost as conveniently as if they were installed locally.

Setup
-----

Install Docker and Docker Compose:

    $ sudo apt install docker-compose

Add yourself to the `docker` group so that you can use Docker:

    $ sudo usermod -aG docker $USER

Technically you don't have to log out and back in to pick up this group membership - you can do:

    $ newgrp docker

However, this creates a subshell and you're only a member of the `docker` group in this subshell. In the end, it's simpler to just logout and log back in.

The `docker-compose.yml` expects your UID and GID to be available as environment variables:

    $ export GID=$(id --group)

Your UID is already available as a variable, you just have to export it to make it an _environment_ variable:

    $ export UID

  560  docker image rm -f my-coro_hirsute-cplusplus:latest

Now, you can compile code that uses Andreas Buhr's fork of [CppCoro](https://github.com/andreasbuhr/cppcoro/blob/master/README.md#cppcoro---a-coroutine-library-for-c):

    $ docker-compose run hirsute-cplusplus g++-11 -fcoroutines example.cpp
    $ docker-compose run hirsute-cplusplus ./a.out

If you want to remove the image:

    $ docker image rm -f my-coro_hirsute-cplusplus:latest

It you want to clean up stopped containers and dangling images:

    $ docker system prune

Scripts
-------

Take a look at [`Dockerfile`](Dockerfile), [`build-cppcoro`](build-cppcoro) and [`docker-compose.yml`](docker-compose.yml) to see how everything works.

CppCoro fork
------------

All the initial development of CppCoro happened in the [lewissbaker/cppcoro](https://github.com/lewissbaker/cppcoro) repo. However, development there stopped in October 2020 as noted in issue [#170](https://github.com/lewissbaker/cppcoro/issues/170).

Andreas Buhr forked CppCoro and merged various PRs against the original repo that had been ignored.

The first main difference is all CppCoro headers pull in a header that essentially includes:

```c++
#include <coroutine>

namespace cppcoro {
  using std::coroutine_handle;
  using std::suspend_always;
  using std::noop_coroutine;
  using std::suspend_never;
}
```

So e.g. if you were pulling in the `generator` header, the first of the two includes here is no longer need:

```c++
#include <coroutine>
#include <cppcoro/generator.hpp>
```

And you can use `cppcoro::coroutine_handle` instead of having to determine whether to use `std::experimental::coroutine_handle` or `std::coroutine_handle` depending on the compiler environment.

The second main difference is that Andreas Buhr's fork uses `cmake` rather than `cake` to build everything.

Installed files
---------------

Running `make install` for CppCoro results in:

**1.** Various files ending up under `/usr/include/cppcoro`. You can see them all with:

```
$ docker-compose run hirsute-cplusplus ls -R /usr/include/cppcoro
```

**2.** The following files ending up under `/usr/lib/cmake/cppcoro`:

* `FindCoroutines.cmake`
* `cppcoroTargets.cmake`
* `cppcoroTargets-release.cmake`
* `cppcoroConfig.cmake`

**3.** The static library `libcppcoro.a` ending up under `/usr/lib`.
