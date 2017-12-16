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
* allow inheritence mode for adapters to actually work by exposing a simple yet power interface to the adapter **and**
implementing a first class citizen adapter that splits responsibilities in small methods internally,
considered as _public_ API ready to be overrided at any time

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
  includes: [:posts, videos: [:comments]],
  fields: [:id, :name, posts: {:id, :text}, videos: {:id, :title, comments: {:id, :text}}] #overrides includes when association is specified
  serializer: UserSerializer, # can also be a lambda, ideal for polymorphic records
  #serializer: ->(obj){ obj.type.employee? ? EmployeeSerializer : UserSerializer }
  adapter: [:ams, options: { root: true }] #name can also accept the class itself, options are passed to the adapter
  #adapter: [name: MyAdapter, options: { link: false }} #name can also accept the class itself
  expose: { url_helpers: SimpleHelpers.new },
  links: {
    root: { value: '/api/v1/', collection: true }
    self: { value: ->(obj) { "/api/v1/users/#{obj.id}" } }
    posts: { value: ->(obj) { "/api/v1/users/#{obj.id}/posts/" } }
  }
}).to_json

class UserSerializer
  include SimpleAMS::DSL
=begin
  include SimpleAMS.with({ #you can pass the same options as above ;)
    primary_id: :id,
    adapter: {
      name: :ams, options: { #name can also accept the class itself
        root: true, id: :id, type: :user #arbiratry params targeted to adapter
      }
    },
    expose: { url_helpers: SimpleHelpers.new }
  })
=end
  adapter :ams, options: {root: true}
  primary_id :id

  #but you can use instead the nice DSL that is included ;)
  attributes :id, :name, :email, :birth_date, :links

  has_many :videos, :comments, :posts
  belongs_to :organization
  has_one :profile, {
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

  link :root, '/api/v1/', collection: true
  link :self, ->(obj) { "/api/v1/users/#{obj.id}" }
  link :posts, ->(obj) { "/api/v1/users/#{obj.id}/posts/" }
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/vasilakisfil/foo.
