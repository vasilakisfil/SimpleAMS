# SimpleAMS
> "Simple things should be simple and complex things should be possible." Alan Kay.

I had been thinking for many months now: *How difficult could it be to write a serializer gem?*
I have used other serializer gems and I always feel that the code is over complecated.

I want this gem to be
* super simple, easy to use, injectable API, clean code. Have you seen pundit? I want a pundit for serializing Ruby objects
* super flexible. Do you remember 0.9xx version of AMS? It was a joy to work with and you could do anything
* not to preassume much, embrace *clear clean explicit code*
* have AMS style as first class citizen (meaning: just attributes of hashes and arrays) and from that implement the rest serializers
* super clean code, sane metaprogramming
* excellent documentation
* tested
* expected behavior on the internals and how it works
* easy to override if needed pretty much anything

## Install
