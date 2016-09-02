# SimpleAMS
AMS made simple


> "Simple things should be simple and complex things should be possible." Alan Kay.

AMS has given me extreme frustration. I had been using successfully version 0.9xx for a couple of years. I could inject anything I want. I loved it. I had written a nice tutorial using that version.

However 0.1x version has been really bad. To be clear: folks behind it are awesome, working a lot of hours in something that doesn't make any money for them, open source that is. I am not criticizing them but the overall result. Sometimes things go south and you can't blame the people behind it. Although I feel the initial design was quite faulty and team changed at some point, some key people left, other joined trying to keep the initial design but complexitiy arose a LOT.

I have been using this gem since September 2015. 12 months later it's still unstable, very complex, key decisions taken by the gem, very unflexible, all in all somethng that I really don't want to work with.

* the code is super complex, reminds me devise code: you can't override pretty much anything if you need custom behavior
* sparse, old documentation
* wrong decisions: Namely the gem made jsonapi as first citizen. That's wrong and has affected pretty much everything in the code.
* super complex. I understand that it tries to provide you with as much as possible options but unfortunately it fails. Being something simple doesn't mean that it can't be used for building complex structures.

I had been thinking months before about this: *how difficult could it be to write a serializer gem?* Well, here is my effort.

I want this gem to be
* super simple, easy to use. Have you seen pundit? I want a pundit for serializing
* super flexible. Do you remember 0.9xx version? It was a joy to work with and you could do anything
* not to preassume much, embrace *clear clean explicit code*
* have AMS style as first class citizen (meaning: just attributes of hashes and arrays)
* super clean code, no smarty complex meta thingies
* excellent documentation
* tested
* expected behavior
* easy to override pretty much anything
