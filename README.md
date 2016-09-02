# SimpleAMS
AMS made simple


> "Simple things should be simple and complex things should be possible." Alan Kay.

AMS has given me extreme frustration. I had been using successfully version 0.9xx for a couple of years. I could inject anything I want. I loved it. I had written a nice tutorial using that version.

However 0.1x version has been really bad. To be clear: folks behind it are awesome, working a lot of hours in something that doesn't make any money for them, open source that is. I am not criticizing them but the overall result. Sometimes things go south and you can't blame the people behind it. Although I feel the initial design was quite faulty and team changed at some point, some key people left, other joined trying to keep the initial design but complexitiy arose a LOT.

I have been using this gem since September 2015. 12 months later it's still unstable, very complex, key decisions taken by the gem, very unflexible, all in all somethng that I really don't want to work with.

* everytime I could see a bug or a wrong key decision I would jump straight in the code to monkey patch it with the goal to send a pull request. However the code is super complex, reminds me devise code: you can't override pretty much anything if you need custom behavior because you really don't know what's going on. I am not a beginner ruby, I have some years of experience in Ruby but still I hade many WTF moments when reading the code. To be clear: the code line by line was probably excellent. However the whole thing, the big picture, was super complex, I couldn't figure out a thing, making it impossible to be *confident* for my overrides in the code. This made me reluctant to send a pull request. But when I did the team was reluctant to merge because (I think) they weren't confident for the code or (mostly) the decisions, that it won't break anything. Some of my PR merged, some were abandoned by me (because I just couldn't do it given my free time)
* sparse, old documentation
* wrong decisions: Namely the gem made jsonapi as first citizen. That's wrong and has affected pretty much everything in the code.
* super complex. I understand that it tries to provide you with as much as possible options but unfortunately it fails.
* very complex API, giving you many options which is confusing. From my experience in a Rails shop, giving many different options to a client is worse than giving 1 nice option that is flexible.

Being something simple doesn't mean that it can't be used for building complex structures.

I had been thinking months before about this: *how difficult could it be to write a serializer gem?* I have used other serializers as well and I don't think it's a rocket science.

I want this gem to be
* super simple, easy to use, injectable API, clean code. Have you seen pundit? I want a pundit for serializing
* super flexible. Do you remember 0.9xx version? It was a joy to work with and you could do anything
* not to preassume much, embrace *clear clean explicit code*
* have AMS style as first class citizen (meaning: just attributes of hashes and arrays). From that implement the rest serializers
* super clean code, no smarty complex meta thingies
* excellent documentation
* tested
* expected behavior on the internals and how it works
* easy to override if needed pretty much anything
