#include <iostream>

#include <cppcoro/generator.hpp>

cppcoro::generator<const std::uint64_t> fib()
{
    std::uint64_t a = 0, b = 1;
    while (true)
    {
        co_yield b;
        b += std::exchange(a, b);
    }
}

int main()
{
	for (auto i : fib())
	{
		if (i > 1'000'000) {
			break;
		}
        std::cout << i << std::endl;
	}

    return 0;
}


