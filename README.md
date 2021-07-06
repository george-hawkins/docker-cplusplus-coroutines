Using the CppCoro library on Ubuntu 20.04 LTS
=============================================

I wanted to try out the C++20 coroutines feature.

While they added `co_yield` etc. in C++20, they didn't standardize the Coroutines library in time for C++20 and this has been left as a task for C++23.

In the meantime, you can use the CppCoro library.

Coroutine support is not yet available in the 9.x version of `gcc` that's available on the current Ubuntu LTS version, i.e. 20.04.

So I decided to create the Docker setup, described below, to create an environment where the CppCoro and the latest version of `gcc` are available such that I can use them almost as conveniently as if they were installed locally.

Note: I use Andreas Buhr's fork of [CppCoro](https://github.com/andreasbuhr/cppcoro/blob/master/README.md#cppcoro---a-coroutine-library-for-c) (for reasons that are covered below).

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

You can build the necessary image up-front:

    $ docker-compose build

However, this isn't strictly necessary - if you don't explicitly build the image like this then it will be automatically built the first time it is needed.

Note: during build, you'll see warnings from `debconf` that it's `delaying package configuration, since apt-utils is not installed`. This is just a warning and getting things to a state where `debconf` doesn't complain involves more complexity than it's worth.

Using CppCoro
-------------

Now, you can compile and run code that uses CppCoro:

    $ docker-compose run hirsute-cplusplus g++-11 -fcoroutines example.cpp
    $ docker-compose run hirsute-cplusplus ./a.out

Take a look at [`example.cpp`](example.cpp), it's very simple and generates the first 30 elements in the Fibonacci sequence (though it doesn't include zero as the first element - for more on whether it should, see the Wikipedia [page](https://en.wikipedia.org/wiki/Fibonacci_number)).

Note: the code is cut from CppCoro test [`generator_tests.cpp`](https://github.com/andreasbuhr/cppcoro/blob/master/test/generator_tests.cpp).

Cleaning up
-----------

If you want to remove the image:

    $ docker image rmi -f docker-cplusplus-coroutines_hirsute-cplusplus

Note that image names are of the form `<project>_<service>` where the project name defaults to the containing directory name, i.e. `docker-cplusplus-coroutines` in this case. See the description of the project name in the Docker Compose [overview](https://docs.docker.com/compose/). You can control this with `container_name` in the `.yml` file but it's not recommended (see the Compose file [reference](https://docs.docker.com/compose/compose-file/compose-file-v3/)).

It you want to clean up stopped containers and dangling images:

    $ docker system prune

Scripts
-------

Take a look at [`Dockerfile`](Dockerfile), [`build-cppcoro`](build-cppcoro) and [`docker-compose.yml`](docker-compose.yml) to see how everything works.

I wanted files, e.g. `a.out`, that were created via Docker to have the same UID and GID as the current user (rather than belonging to `root`). This is achieved by making sure `UID` and `GID` are available as environment variables (as shown above), picking these up as `user` in `docker-compose.yml` and passing `UID` onto the `Dockerfile` as a `build-arg`. In the `Dockerfile`, you'll see that I explicitly create and `chown` the `WORKDIR` directory. I tried various other approaches (including setting `USER`) but this turned out to be the easiest and most flexible. It's actually valid to use a numeric UID with `chown` even if there's no corresponding user - the only reason I add a corresponding user (called `worker`) is because `git` fails if it can't map the UID to a user.

The `Dockerfile` uses the script `build-cppcoro` to clone, build and install the CppCoro library. Usually, I use `git:` URLs when cloning from GitHub. However, this is complicated when using Docker as it involves setting up fingerprint validation (as `ssh` is involved). So, instead I use a `https:` URL. I didn't find the build [instructions](https://github.com/andreasbuhr/cppcoro/blob/master/README.md#building) for building with `cmake` entirely clear and only worked things out by seeing how the [workflow](https://github.com/andreasbuhr/cppcoro/blob/master/.github/workflows/cmake.yml) for the relevant GitHub Action was doing things (after that the instructions became clearer and I could use them to modify things to get the setup I wanted).

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
