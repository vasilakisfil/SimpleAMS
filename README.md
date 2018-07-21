# SimpleAMS
> "Simple things should be simple and complex things should be possible." Alan Kay.

If we want to interact with modern APIs we should start building modern, flexible libraries
that help developers to build such APIs. Modern Ruby serializers, as I always wanted them to be.

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
The gem's interface has been inspired by ActiveModel Serializers 0.9.2, 0.10.stable, jsonapi-rb and Ember Data.
However, **it has been built for POROs and does not relate to Rails in any case** other than
some nostalgia for the (advanced at that time) pre-0.10 ActiveModel Serialiers.


### Simple case

Usually you rarely need all the advanced options. Usually you will have something like that:

```ruby
class UserSerializer
  include SimpleAMS::DSL

  #specify the adapter, pass some options all the way down to the adapter
  adapter SimpleAMS::Adapters::JSONAPI, root: true

  #specify available attributes/fields
  attributes :id, :name, :email, :birth_date

  #specify available relations
  has_many :videos, :comments, :posts
  belongs_to :organization
  has_one :profile

  #specify some links
  link :feed, '/api/v1/me/feed'
  #links can also take other options, as specified by RFC 8288
  link :root, '/api/v1/', rel: :user
  #link values can be dynamic as well through lambdas
  link :posts, ->(obj) { "/api/v1/users/#{obj.id}/posts/" }, rel: :user
  #if you also need dynamic options, you can return an array from the lambda
  link :followers, ->(obj) { ["/api/v1/users/#{obj.id}/followers/", rel: obj.type] }

  #same with metas: can be static, dynamic and accept arbiratry options
  meta :environment, ->(obj) { Rails.env.to_s }

  #collection accepts exactly the same aforementioned interface
  #although you will rarely use it to full extend
  #here we use only links and meta
  collection do
    link :root, '/api/v1/', rel: :user

    meta :count, ->(collection) { collection.count }
  end

  #override an attribute
  def name
    "#{object.first_name} #{object.last_name}"
  end

  #override a relation
  def videos
    Videos.where(user_id: object.id).published
  end
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
* Through the DSL, powed with some syntactic sugar

In any case, we have the following options:

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
  relations: [
    [:belongs_to, :company, {
      serializer: CompanySerializer,
      fields: Company.column_names.map(&:to_sym)
      }
    ],
    [:has_many, :followers, {
      serializer: UserSerializer,
      fields: User.column_names.map(&:to_sym)
    ],
  ]
  #the serializer that should be used
  #makes sense to use it when initializing the Renderer
  serializer: UserSerializer,
  #can also be a lambda, in case of polymorphic records, ideal for ArrayRenderer
  serializer: ->(obj){ obj.employee? ? EmployeeSerializer : UserSerializer }
  #specifying the anderlying adapter. This cannot be a lambda in case of ArrayRenderer,
  #but can take some usefull options that are passed down straignt to the adapter class.
  adapter: SimpleAMS::Adapters::AMS, root: true
  #the links data
  links: {
    #can be a simple string
    root: '/api/v1'
    #a string with some options (relation and target attributes as defined by RFC8288
    #however, you can also pass adapter-specific attributes
    posts: "/api/v1/posts/", rel: :posts,
    #it can also be a lambda that takes the resource to be rendered as a param
    #when the lambda is called, it should return the array structure above
    self: ->(obj) { ["/api/v1/users/#{obj.id}", rel: :user] }
  },
  #the meta data, same as the links data (available in adapters even for sinlge records)
  meta: {
    type: ->(obj){ obj.employee? ? :employee : :user}
    #meta can take arbiratry options as well
    authorization: :oauth, type: :bearer_token
  },
  #collection parameters, used only in ArrayRenderer
  collection: {
    links: {
      root: '/api/v1'
    },
    metas: {
      pages: ->(obj) { [obj.pages, collection: true]},
      current_page: ->(obj) { [obj.current_page, collection: true] },
      previous_page: ->(obj) { [obj.previous_page, collection: true] },
      next_page: ->(obj) { [obj.next_page, collection: true] },
      max_per_page: 50,
    },
  }
  #exposing helpers that will be available inside the seriralizer
  expose: {
    #a class
    current_user: User.first
    #or a module
    helpers: CommonHelpers
  },
}
```

Now let those options be `OPTIONS`. These can be feeded to either the `SimpleAMS::Renderer`
or to the serializer class itself using the `with_options` class method. Let's see how:

```ruby
class UserSerializer
  include SimpleAMS::DSL

  with_options({ #you can pass the same options as above ;)
    primary_id: :id,
    #   ...
    #   ...
    #   ...
  })

  def name
    "#{object.first_name} #{object.last_name}"
  end

  def videos
    Videos.where(user_id: object.id).published
  end
end
```

The same options can be passed when calling the `Renderer`. `Renderer` can override
some properties that are unique, however in properties that return sets (like
attributes/fields, includes, links etc.), specified serializer options take precendence over
`Renderer` options.

```ruby
SimpleAMS::Renderer.new(user, {
  primary_id: :id,
  serializer: UserSerializer,
  #   ...
  #   ...
  #   ...
}).to_json

```
## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/vasilakisfil/foo.

## Why did I build this ?
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
Still though, I think it worthed the effort :)
