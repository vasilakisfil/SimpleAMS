# SimpleAMS
> "Simple things should be simple and complex things should be possible." Alan Kay.

If we want to interact with modern APIs we should start building modern, flexible libraries
that help developers to build such APIs. Modern Ruby serializers, as I always wanted them to be.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'simple_ams'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install simple_ams

## Usage
The gem's interface has been inspired by ActiveModel Serializers 0.9.2, 0.10.stable, jsonapi-rb and Ember Data.
However, **it has been built for POROs, does not rely in any dependency and does not relate to Rails in any case** other than
some nostalgia for the (advanced at that time) pre-0.10 ActiveModel Serialiers.


### Simple case

You will rarely need all the advanced options. Usually you will have something like that:

```ruby
class UserSerializer
  include SimpleAMS::DSL

  #specify the adapter, pass some options all the way down to the adapter
  adapter SimpleAMS::Adapters::JSONAPI, root: true

  #specify available attributes/fields
  attributes :id, :name, :email, :birth_date

  #specify available relations
  has_one :profile, serializer: ProfileSerializer
  #belongs_to is just an alias to has_one
  belongs_to :organization, serializer: OrganizationSerializer
  has_many :videos, serializer: VideosSerializer
    #rarely used: if you need more options, you can pas a block
    #which adheres to the same DSL as described here
    #it goes to an option called `embedded`
    #essentially these options here should be used for linking current resource
    #with the relation (useful for JSONAPI for instance)
    generic :include_data, false
  end

  #specify some links
  link :feed, '/api/v1/me/feed'
  #links can also take other options, as specified by RFC 8288
  link :root, '/api/v1/', rel: :user
  #link values can be dynamic as well through lambdas
  #lambdas take arguments the object to be serialized and the instantiated serializer
  link :posts, ->(obj, s) { s.api_v1_user_followers_path(user_id: obj.id) }, rel: :user
  #if you also need dynamic options, you can return an array from the lambda
  link :followers, ->(obj, s) { ["/api/v1/users/#{obj.id}/followers/", rel: obj.type] }

  #same with metas: can be static, dynamic and accept arbitrary options
  meta :environment, ->(obj, s) { Rails.env.to_s }

  #same with form: can be static, dynamic and accept arbitrary options
  form :create, ->(obj, s) { User::CreateForm.for(obj) }

  #or if you need something quite generic (and probably adapter-related)
  #again it follows the same patterns as link
  generic :include_embedded_data, true, {only: :collection}

  #these are properties to the collection resource itself
  #AND NOT to each resource separately, when applied inside a collection..
  #It's a rarely used feature but definitely nice to have..
  collection do
    #collection accepts exactly the same aforementioned interface
    #here we use only links and meta
    link :root, '/api/v1/', rel: :user
    type :users
    meta :count, ->(collection, s) { collection.count }
  end

  #note that most probably the only thing that you will need here is the `type`,
  #so there is a shortcut if you just need to specify the collection name/type:
  #collection :users

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
The DSL in the previous example is just syntactic sugar. In the basis, there is a very powerful
hash-based DSL that can be used in 3 different places:

* When initializing the `SimpleAMS::Renderer` class to render the data using specific serializer, adapter and options.
* Inside a class that has the `SimpleAMS::DSL` included, using the `with_options({})` class method
* Through the DSL, powered with some syntactic sugar

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
  serializer: ->(obj, s){ obj.employee? ? EmployeeSerializer : UserSerializer }
  #specifying the underlying adapter. This cannot be a lambda in case of ArrayRenderer,
  #but can take some useful options that are passed down straight to the adapter class.
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
    self: ->(obj, s) { ["/api/v1/users/#{obj.id}", rel: :user] }
  },
  #the meta data, same as the links data (available in adapters even for single records)
  metas: {
    type: ->(obj, s){ obj.employee? ? :employee : :user}
    #meta can take arbitrary options as well
    authorization: :oauth, type: :bearer_token
  },
  #the form data, same as the links/metas data (available in adapters even for single records)
  forms: {
    update: ->(obj, s){ User::UpdateForm.for(obj)}
    follow: ->(obj, s){ User::FollowForm.for(obj)}
  },
  #collection parameters, used only in ArrayRenderer
  collection: {
    links: {
      root: '/api/v1'
    },
    metas: {
      pages: ->(obj, s) { [obj.pages, collection: true]},
      current_page: ->(obj, s) { [obj.current_page, collection: true] },
      previous_page: ->(obj, s) { [obj.previous_page, collection: true] },
      next_page: ->(obj, s) { [obj.next_page, collection: true] },
      max_per_page: 50,
    },
    #creating a resource goes in the collection route (users/), hence inside collection options ;)
    forms: {
      create: ->(obj){ User::CreateForm.for(obj)}
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

Now let those options be `OPTIONS`. These can be fed to either the `SimpleAMS::Renderer`
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
some properties, however in all properties that act as sets/arrays (like
attributes/fields, includes, links etc.), **specified serializer options take precedence** over
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
But reports are very welcome at https://github.com/vasilakisfil/SimpleAMS. Please add as much info as you can (serializer and Renderer input)
so that we can easily track down the bug.

Pull requests are also very welcome on GitHub at https://github.com/vasilakisfil/SimpleAMS.
However, to keep the code's sanity (AMS I am looking to you), **I will be very picky** on the code style and design,
to match (my) existing code characteristics.
Because at the end of the day, it's gonna be me who will maintain this thing.
