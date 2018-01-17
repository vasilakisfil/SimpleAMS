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

```ruby
SimpleAMS::Serializer.new(user, {
  primary_id: :id,
  type: :user,
  includes: [:posts, videos: [:comments]],
  fields: [:id, :name, posts: [:id, :text], videos: [:id, :title, comments: [:id, :text]]] #overrides includes when association is specified
  serializer: UserSerializer, # can also be a lambda, ideal for polymorphic records
  #serializer: ->(obj){ obj.type.employee? ? EmployeeSerializer : UserSerializer }
  adapter: [SimpleAMS::Adapters::AMS, options: { root: true }] #name can also accept the class itself, options are passed to the adapter
  #adapter: [name: MyAdapter, options: { link: false }} #name can also accept the class itself
  links: {
    self: ->(obj) { "/api/v1/users/#{obj.id}" }
    posts: [->(obj) { "/api/v1/users/#{obj.id}/posts/"}, options: {collection: true}]
  },
  meta: {
    type: :user
  },
  collection: {
    links: {
      root: '/api/v1'
    },
    meta: {
      pages: [->(obj) { obj.pages }, options: {collection: true}],
      current_page: [->(obj) { obj.current_page }, options: {collection: true}],
      previous_page: [->(obj) { obj.previous_page }, options: {collection: true}],
      next_page: [->(obj) { obj.next_page }, options: {collection: true}],
      max_per_page: 50,
    },
  }
  expose: { url_helpers: SimpleHelpers.new },
}).to_json

class UserSerializer
  include SimpleAMS::DSL

  with_options({ #you can pass the same options as above ;)
    primary_id: :id,
    adapter: {
      name: SimpleAMS::Adapters::AMS, options: {
        root: true, #arbiratry params targeted to adapter
      }
    },
    expose: { url_helpers: SimpleHelpers.new }
  })

  #but you can use instead this nice DSL which is included for free ;)
  adapter SimpleAMS::Adapters::AMS, options: {root: true}
  type :user
  primary_id :id

  attributes :id, :name, :email, :birth_date, :links

  has_many :videos, :comments, :posts
  belongs_to :organization
  has_one :profile, options: { #again same options (except adapter)
    includes: [:address],
    fields: [:id, :settings, address: {:country}}] #overrides includes when association is specified
    serializer: UserSerializer,
    adapter: {name: :ams, options: { root: true }}
    expose: { url_helpers: SimpleHelpers.new }
  }

  #override an attribute
  def name
    "#{object.first_name} #{object.last_name}"
  end

  link :root, '/api/v1/', options: {collection: true}
  link :self, ->(obj) { "/api/v1/users/#{obj.id}" }
  link :posts, ->(obj) { "/api/v1/users/#{obj.id}/posts/" }
end
```
+Explain the logic behind it (why allowed properties + injected properties instead of an if inside serializers).

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
