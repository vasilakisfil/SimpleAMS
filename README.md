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
* expected behavior on how the internals work
* easy to override if needed pretty much anything
* allow inheritence mode for adapters to actually work by exposing a simple yet power interface to the adapter **and**
implementing a first class citizen adapter that splits responsibilities in small methods internally,
considered as _public_ API ready to be overrided at any time

It turned out that writting a serializers gem is a bit more complex than what I initially thought.
However with initial well thought design, I managed to achieve my initial requirements and goals, mentioned above :)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'simple-ams'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install simple-ams

## Usage
The gem's API has been inspired by ActiveModel Serializers 0.9.2, 0.10.stable and jsonapi-rb.

### Simple case

Usually you rarely need all the advanced options. Usually you will have something like that:

```ruby
class UserSerializer
  include SimpleAMS::DSL

  adapter SimpleAMS::Adapters::AMS, options: {root: true}

  attributes :id, :name, :email, :birth_date

  has_many :videos, :comments, :posts
  belongs_to :organization
  has_one :profile

  link :root, '/api/v1/', options: {rel: :user}
  link :self, ->(obj) { "/api/v1/users/#{obj.id}" }
  link :posts, ->(obj) { "/api/v1/users/#{obj.id}/posts/" }

  #override an attribute
  def name
    "#{object.first_name} #{object.last_name}"
  end
```

Then you can just feed your serializer with data, along with some options:

```ruby
SimpleAMS::Renderer.new(user, fields: [:id, :name, :email], includes: [:videos]).to_json
```
`to_json` first calls `as_json`, which creates a ruby Hash and then `to_json` is called
on top of that hash.


# Advanced usage
The DSL in the previous example is just suntactic sugar. In the basis, there is a very powerful
hash-based DSL that can be used in 3 different places:

* When initializing the `SimpleAMS::Renderer` class to render the data using specific serializer, adapter and options.
* Inside a class that has the `SimpleAMS::DSL` included, using the `with_options({})` class method
* Through the DSL, although the syntax is slightly different

In each case we have the following options:

```ruby
{
  #the primary id of the record(s), used mostly by the underlying adapter (like JSONAPI)
  primary_id: :id,
  #the type of the record, used mostly by the underlying adapter (like JSONAPI)
  type: :user,
  #which relations should be included
  includes: [:posts, videos: [:comments]],
  #which fields for each relation should be included
  fields: [:id, :name, posts: [:id, :text], videos: [:id, :title, comments: [:id, :text]]] #overrides includes when association is specified
  #the serializer that should be used
  #makes sense to use it when initializing the Renderer
  serializer: UserSerializer,
  #can also be a lambda, in case of polymorphic records, ideal for ArrayRenderer
  serializer: ->(obj){ obj.employee? ? EmployeeSerializer : UserSerializer }
  #specifying the anderlying adapter. This cannot be a lambda in case of ArrayRenderer,
  #but can take some usefull options that are passed down straignt to the adapter class.
  adapter: [SimpleAMS::Adapters::AMS, options: { root: true }] #name can also accept the class itself, options are passed to the adapter
  #the links data
  links: {
    #can be a simple string
    root: '/api/v1'
    #a string with some options (relation and target attributes as defined by RFC8288
    #however, you can also pass adapter-specific attributes
    posts: "/api/v1/posts/", options: {rel: :posts}],
    #it can also be a lambda that takes the resource to be rendered as a param
    #when the lambda is called, it should return the array structure above
    self: ->(obj) { ["/api/v1/users/#{obj.id}", options: {rel: :user] }
  },
  #the meta data, same as the links data (available in adapters even for sinlge records)
  meta: {
    type: ->(obj){ obj.employee? ? :employee : :user}
  },
  #collection parameters, used only in ArrayRenderer
  collection: {
    links: {
      root: '/api/v1'
    },
    metas: {
      pages: [->(obj) { obj.pages }, options: {collection: true}],
      current_page: [->(obj) { obj.current_page }, options: {collection: true}],
      previous_page: [->(obj) { obj.previous_page }, options: {collection: true}],
      next_page: [->(obj) { obj.next_page }, options: {collection: true}],
      max_per_page: 50,
    },
  }
  #exposing helpers that will be available inside the seriralizer
  expose: {
    #a class
    url_helpers: SimpleHelpers.new
    #or a module
    helpers: SimpleHelpersModule
  },
}
```

Now let those options be `OPTIONS`. These can be feeded to either the `SimpleAMS::Renderer`
or to the serializer class itself using the `with_options` class method. Let's see how:

```ruby
class UserSerializer
  include SimpleAMS::DSL

  with_options( #you can pass the same options as above ;)
    OPTIONS
  )

  #override an attribute
  def name
    "#{object.first_name} #{object.last_name}"
  end
end
```

```ruby
SimpleAMS::Serializer.new(user, {
  expose: { url_helpers: SimpleHelpers },
}).to_json

```
## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/vasilakisfil/foo.

## TODO
+ add type param
+ finish options tests
+ review spec/support infrastructure
+ start document tests
