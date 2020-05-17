[![Build Status](https://travis-ci.org/vasilakisfil/SimpleAMS.svg?branch=master)](https://travis-ci.org/vasilakisfil/SimpleAMS)

# SimpleAMS
> "Simple things should be simple and complex things should be possible." Alan Kay.

If we want to interact with modern APIs we should start building modern, flexible libraries
that help developers to build such APIs. Modern Ruby serializers, as I always wanted them to be.

You can find the core ideas, the reasoning behind the architecture, use cases
and examples [here](https://vasilakisfil.social/blog/2020/01/20/modern-ruby-serializers/).

## Table of contents

1. [Installation](#installation)
2. [Usage](#usage)
    * [Simple case](#simple-case)
        - [Rendering a resource](#rendering-a-resource)
        - [Rendering a collection](#rendering-a-collection)
    * [Serializer DSL](#serializer-dsl)
        - [fields directive](#fields-directive)
        - [Relations (has_many/has_one/belongs_to)](#relations-has_manyhas_onebelongs_to)
            * [relations are recursive](#relations-are-recursive)
            * [embedded content (again recursive)](#embedded-content-again-recursive)
            * [relation name/type](#relation-nametype)
        - [value-hashmap type of directives](#value-hashmap-type-of-directives)
            * [adapter](#adapter)
            * [primary_id](#primary_id)
            * [type](#type)
        - [name-value-hashmap type of directives](#name-value-hashmap-type-of-directives)
            * [link](#link)
            * [meta](#meta)
            * [form](#form)
            * [generic](#generic)
            * [group of link/meta/form/generic](#group-of-linksmetasformsgenerics)
        - [collection directive](#collection-directive)
    * [Rendering DSL](#rendering-dsl)
        - [includes vs relations](#includes-vs-relations)
        - [Rendering collections](#rendering-collections)
        - [Rendering options with values](#rendering-options-with-values)
        - [Exposing methods inside the serializer, like helpers](#exposing-methods-inside-the-serializer-like-helpers)
    * [Extended DSL show off](#extended-dsl-show-off)
3. [Development](#development)
4. [Contributing](#contributing)


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
The gem's interface has been inspired by ActiveModel Serializers 0.9.2,
0.10.stable, jsonapi-rb and Ember Data.
However, it has been built for POROs, **has zero dependencies** and does not
relate to Rails in any case other than some nostalgia for the (advanced at that
time) pre-0.10 ActiveModel Serialiers.

You can find the core ideas, the reasoning behind the architecture, use cases and examples [here](https://vasilakisfil.social/blog/2020/01/20/modern-ruby-serializers/).

### Simple case
You will rarely need all the advanced options. Usually you will have something like that:

```ruby
class UserSerializer
  include SimpleAMS::DSL

  #specify the adapter we want to use
  adapter SimpleAMS::Adapters::JSONAPI

  #specify the attributes we want to serialize from the given object
  attributes :id, :name, :email, :created_at, :role

  #specify the type of the resource
  type :user
  #specify the name of the collection
  collection :users

  #specify a relation. Here microposts serves as both a name of the collection
  #and the name of the method used to retrieve the values of the collection
  #from the given object
  has_many :microposts
end
```


#### Rendering a resource
Then you can just feed your serializer with data:

```ruby
SimpleAMS::Renderer.new(user).to_json
```
`to_json` first calls `as_json`, which creates a ruby Hash and then `to_json` is called
on top of that hash.

If you want to filter the available options (defined by the serializer) when you
instantiate the serializer, `Renderer` accepts an options hash. In there you can
throw pretty much the same DSL:

```ruby
SimpleAMS::Renderer.new(user, {
  serializer: UserSerializer, fields: [:id, :name, :email], includes: []
}).to_json
```

Here we say that we only want 3 specific fields, and no relations at all.


#### Rendering a collection
Rendering a collection is pretty similar, meaning that it reuses the same serializer
class, and accepts the same runtime options. The only difference is that you need
to call a different class.

```ruby
SimpleAMS::Renderer::Collection.new(users, {
  serializer: UserSerializer, fields: [:id, :email, :name], includes: []
}).to_json
```

### Serializer DSL
The serializer is a very robust, yet simple, with a hash-based internal
representation.

#### fields directive
Fields specify the attributes that the serializer will hold.
The values of each attribute is taken by the to-be serialized object,
unless the serializer has a method of the same name.

```ruby
fields :id, :name, :email, :created_at, :role
```


Using `attributes` is also valid, it’s just an [alias](https://github.com/vasilakisfil/SimpleAMS/blob/master/lib/simple_ams/dsl.rb#L130-L137) after all:

```ruby
attributes :id, :name, :email, :created_at, :role
```


Of course, any field can be overridden by defining a method of the same name
inside the serializer.
In there, you can have access to a method called object which holds the actual
resource to be serialized:

```ruby
def name
  "#{object.first_name} #{object.last_name}"
end
```


#### Relations (has_many/has_one/belongs_to)
These directives allows you to append relations in a resource.
`has_one` is just an alias of `belongs_to` since there is no real difference in
APIs (although internally and in adapters, SimpleAMS knows if you specified the
relation using`belongs_to` or `has_one`, making it future proof in case API specs
decide to support each one in a different way).

```ruby
has_many :microposts
```

Again, it can be overridden by defining a method of the same name:

```ruby
def microposts
  Post.where(user_id: object.id).order(:created_at, :desc).limit(10)
end
```

##### relations are recursive
The relations directives can take the same options as the rendering.

```ruby
#overriding the serializer
has_many :microposts, serializer: CustomPostsSerializer
#overriding the serializer and fields that should be included
has_many :microposts, serializer: CustomPostsSerializer, fields: [:content]
#overriding the serializer, fields and relations that should be included
has_many :microposts, serializer: CustomPostsSerializer, fields: [:content],
  includes: []
#overriding the serializer, fields, relations and links
has_many :microposts, serializer: CustomPostsSerializer, fields: [:content],
  includes: [], links: [:self]
```


When overriding from the relations directives (or when rendering in general) you
are able to override any directive defined in the serializer to acquire a subset
**but never a superset**.

##### embedded content (again recursive)
Sometimes, an annoying spec might define parts of a relation in the main body,
while parts of the relation somewhere else. For instance, JSON:API does that by
having some links in the main body and the rest in the included section.
That’s also possible if you pass a block in the relation directive:

```ruby
has_many :microposts, serializer: MicropostsSerializer, fields: [:content] do
  #these goes to a class named `Embedded`, attached to the relation
  link :self, ->(obj){ "/api/v1/users/#{obj.id}/relationships/microposts" }
  link :related, ->(obj){ ["/api/v1/users/1", rel: :user] }
end
```

Inside that block, you can pass any parameter the original DSL supports and will
be stored in an Embedded class under MicropostsSerializer.
Btw SimpleAMS is smart enough (one of the very few cases that acts like that) to
figure out that if a lambda returns something that’s not an array, then this must
be the value, while options are just empty.

##### relation name/type
Sometimes, we want to detach the relation’s name from the type. In the previous
example `microposts` is the relation name (whatever that means), while the type
is defined by the `MicropostsSerializer`, unless we override it, which can be
done either in the relation serializer itself, or when we use the relation from
the parent serializer:

```ruby
has_many :microposts, serializer: MicropostsSerializer, fields: [:content], type: :feed do
  link :self, ->(obj){ "/api/v1/users/#{obj.id}/relationships/microposts" }
  link :related, ->(obj){ ["/api/v1/users/1", rel: :user] }
end
```

Internally SimpleAMS, differentiates type from name, and usually type is
something that’s semantically stronger (like a relation type) than name.
You can even inject the name of the relation using the name option:

```ruby
has_many :microposts, serializer: MicropostsSerializer, fields: [:content], type: :feed, name: :posts do
  link :self, ->(obj){ "/api/v1/users/#{obj.id}/relationships/microposts" }
  link :related, ->(obj){ ["/api/v1/users/1", rel: :user] }
end
```

As I said, the name, which is usually the name of the attribute that includes
the relation in the JSON format, doesn’t really have any semantic meaning in
most specs. At least I haven’t seen any spec to depend on the root attribute
name of the relation. Instead it’s the type that’s important, because type is
what the [web linking RFC defines](https://tools.ietf.org/html/rfc8288#section-2).

#### value-hashmap type of directives
These are directives like adapter. They take a value, and optionally a hashmap,
which are options to be passed down straight to the adapter, hence they are adapter specific.
Such options are `primary_id`, `type` and `adapter`

For instance, for adapter it could be:
```ruby
adapter SimpleAMS::Adapters::JSONAPI, root: true
```

Of course, since we are talking about Ruby here, it would be a huge restriction
to not allow dynamic value/hashmap combination. Basically any such directive
can accept a lambda (generally anything that responds to `call`) and should
return an array where the first part is the value and (optionally) the second part is the
options. There is an argument that is passed down to the function/lambda, and
that’s the actual object. For instance, to support polymorphic resources you
can have the type dynamic:

```ruby
type ->(obj, s){ obj.employee? ? [:employee, {}] : [:user, {}]}
```

One of the very few times that SimpleAMS acts smart is inside the lambda, that
if you have only a value (not an Array), it will take that as the value, while
the options will be taken by the second argument, after the lambda. So the
above is equivalent with:

```ruby
type ->(obj, s){ obj.employee? ? :employee : :user}, {}
```

Note: you shouldn't use that in case of adapter, as that's the definition of UB :P


<details>
<summary id="adapter">adapter</summary>

Specifies the adapter to be used. The `adapter` method is the only one that does
not support lambda as it's value, as that would be the definition of undefined
behavior. If you want to support polymorphic collections, you should use the `type`
instead in combination with the `serializer`.

```ruby
#without options
adapter SimpleAMS::Adapters::JSONAPI
#with adapter-specific options
adapter SimpleAMS::Adapters::JSONAPI, {root: false}
```

Note that you can even specify your own adapter. Usually you will want to inherit
from an existing adapter (like `SimpleAMS::Adapters::AMS`), but that's not a
requirement. All you need is to duck type to 2 methods:
* `initialize(document, options = {})` be able to accept 2 arguments when your adapter
  is instantiated. The first one is a document, while the second one is the adapter-specific
  options (like the `{root: false}`.
* `as_json` method returns that returns the hash representation of the serialized result

The conversion of a Hash into raw JSON string is out of the scope of this library.
But you will probably want to use the fastest implementation possible like [oj](https://github.com/ohler55/oj).
</details>

<details>
<summary id="primary_id">primary_id</summary>

Specifies the `primary_id` to be used. There are many API specs that handle the
identifier of a resource in a different way than the rest of the attributes.
JSON:API is one of those.

```ruby
#without options
primary_id :id
#with adapter-specific options
adapter :id, {external: true}
#dynamic
adapter ->(obj, s) { [obj.class.primary_key, {}]}
```


</details>

<details>
<summary id="type">type</summary>

Specifies the `type` to be used. There are many API specs that handle the
type of a resource in a different way than the rest of the attributes.
JSON:API is one of those.

```ruby
#without options
type :user
#with adapter-specific options
type :user, {polymorphic: false}
#dynamic
type ->(obj, s){ obj.employee? ? [:employee, {}] : [:user, {}]}
```

</details>



#### name-value-hashmap type of directives
These are similar to the above, only that they also have an actual value, which
is converted to a representation through the adapter.
Such options are `link`, `meta`, `form` and the most generic directive `generic`.

For instance, think about a links. According to RFC [8288](https://tools.ietf.org/html/rfc8288#section-2), a link has

* a link context,
* a link relation type,
* a link target, and
* optionally, target attributes

Now, if we wanted to translate that to our serializers, a link could look like:
```ruby
link :feed, '/api/v1/me/feed', {style: :compact}
```

Here obviously the link context is the serializer itself, the link relation is
the feed, and the value is `/api/v1/me/feed`. Now you might say, feed should be
the name of the link which is different from the relation type.
The relation type could be `microposts`.
And actually, that’s the case for [JSONAPI v1.1](https://jsonapi.org/format/1.1/).
In that case, the feed should be treated barely as a name (whatever that means)
and relation type will be put inside the link options like:

```ruby
link :feed, '/api/v1/me/feed', {rel: :microposts, style: :compact}
```

Note however that this needs to be supported by the adapter you are using.

Similar to the case of value-hash directives, it is possible to have dynamic
value and options:

```ruby
#values can be dynamic through lambdas
#lambdas take arguments the object to be serialized and the instantiated serializer
link :feed, ->(obj, s) { [s.api_v1_user_feed_path(user_id: obj.id), {rel: :feed} }
#if the value inside the lambda is single (no array), the options will be taken from
#the second argument, after the lambda. So the above is equivelent to:
link :feed, ->(obj, s) { s.api_v1_user_feed_path(user_id: obj.id) }, rel: :feed
```

<details>
<summary id="link">link</summary>

Specifies a link to be used. There are many API specs that handle the links of a
resource in a special way (JSON:API is one of those).
You can specify multiple links, as long as each link name is unique.

```ruby
#specifying a link with without options
link :feed, "/api/v1/feed"
#specifying a link with options
link :feed, "/api/v1/feed", {rel: :feed, compact: true}
#values can be dynamic through lambdas
#lambdas take arguments the object to be serialized and the instantiated serializer
link :feed, ->(obj, s) { [s.api_v1_user_feed_path(user_id: obj.id), {rel: :feed, compact: true}] }
#if the value inside the lambda is single (no array), the options will be taken from
#the second argument, after the lambda. So the above is equivelent to:
link :feed, ->(obj, s) { s.api_v1_user_feed_path(user_id: obj.id) }, rel: :feed, compact: true
```

</details>

<details>
<summary id="meta">meta</summary>

Specifies a meta to be used. There are many API specs that handle the metas of a
resource in a special way (JSON:API is one of those).
You can specify multiple metas, as long as each link name is unique.

```ruby
#specifying a meta with without options
meta :total_count, 1
#specifying a meta with options
meta :total_count, 1, {compact: true}
#values can be dynamic through lambdas
#lambdas take arguments the object to be serialized and the instantiated serializer
#in this case an object is apparently a collection/array
meta :total_count, ->(obj, s) { [obj.count, {compact: true}] }
#if the value inside the lambda is single (no array), the options will be taken from
#the second argument, after the lambda. So the above is equivelent to:
meta :total_count, ->(obj, s) { obj.count }, {compact: true}
```

</details>

<details>
<summary id="form">form</summary>

Specifies a form to be used. Unfortunately, there are very few API specs that
handle forms (the [Ion hypermedia type](https://ionspec.org) is one of those).
You can specify multiple forms, as long as each link name is unique.

```ruby
#specifying a form with without options
form :upload, {method: :get, url: "/api/v1/submit"}
#specifying a form with options
form :upload, {method: :get, url: "/api/v1/submit"}, compact: true
#values can be dynamic through lambdas
#lambdas take arguments the object to be serialized and the instantiated serializer
form :upload, ->(obj, s) { [obj.class.upload_form_options, {compact: true}] }
#if the value inside the lambda is single (no array), the options will be taken from
#the second argument, after the lambda. So the above is equivelent to:
form :upload, ->(obj, s) { obj.class.upload_form_options }, {compact: true}
```

</details>

<details>
<summary id="generic">generic</summary>

Specifies a generic to be used. A generic is just a placeholder for extensions
that are unknown to SimpleAMS (but maybe they make a lot of sense to you ^_^)

```ruby
#specifying a generic with without options
generic :pagination, :extended
#specifying a form with options
generic :pagination, :extended, compact: false
#values can be dynamic through lambdas
#lambdas take arguments the object to be serialized and the instantiated serializer
generic :pagination, ->(obj, s) { [obj.class.pagination_type, {compact: false}] }
#if the value inside the lambda is single (no array), the options will be taken from
#the second argument, after the lambda. So the above is equivelent to:
generic :pagination, ->(obj, s) { obj.class.pagination_type }, {compact: false}
```

</details>

##### group of links/metas/forms/generics

Each of the aforementioned options comes with a plural form as well.
For instance, if we want to specify multiple `links` at the same time:

```ruby
links {
  self: ['/api/v1/me', {rel: :user}]
  feed: ['/api/v1/me/feed', {rel: :feed}]
}
```

or if we want to specify multiple `metas`:
```ruby
metas {
  total_count: ->(obj){ obj.count }
  pages: ->(obj){ obj.pages_count }
}
```

Same goes for `forms` and `generics`.

#### collection directive
SimpleAMS has a unique ability to allow you specify different options when you are
rendering a collection. In its most simple use case it specified the plural name
of the resource, used when rendering a collection:

```ruby
collection :users
```

It’s needed, if your adapter serializes the collection using a root element.
But it can do much more than that: it allows you to define directives on the
collection level. For instance, if you want to have a link that should be
applied **only** to the collection level and not to each resource of the collection,
then you need to define it inside the collection’s block:

```ruby
collection :users do
  link :self, "/api/v1/users"
end
```

Or if we also want to have the total count of the collection, that should go in
there actually:

```ruby
collection :users do
  link :self, "/api/v1/users"
  meta :count, ->(collection, s) { collection.count }
end
```

Again, inside that block you can define using the regular DSL, whatever you
would define in the resource level. It’s just yet another level of recursion
since, the same things that I show you here can be applied in the collection
level inside the block. For instance, in theory (and if the adapter supports
it), you can specify relations that apply only to the collection level:

```ruby
class UserSerializer
  include SimpleAMS::DSL

  adapter SimpleAMS::Adapters::JSONAPI

  attributes :id, :name, :email, :created_at, :role

  type :user
  collection :users do
    link :self, "/api/v1/users"
    meta :count, ->(collection, s) { collection.count }

    has_one :s3_uploader #whatever that means :P
  end

  has_many :microposts
end
```

### Rendering DSL
When rendering a resource, it should be straightforward:

```ruby
SimpleAMS::Renderer.new(user, { serializer: UserSerializer }).to_json
```

All you need is to specify a serializer. In the example above, the resulted
resource is a reflection of what is defined inside the serializer.
However, the serializer acts as a filtering mechanism, meaning that you can
override anything the serializer defines, given that the result creates a
**subset and not a superset** (any superset options will be ignored).

For instance, you can override the type during rendering:

```ruby
SimpleAMS::Renderer.new(user, {
  serializer: UserSerializer, type: :person
}).to_json
```
or you can override the relations, and specify that you don’t want to include
any relation defined in the serializer:

```ruby
SimpleAMS::Renderer.new(user, {
  serializer: UserSerializer, includes: []
}).to_json
```

or specify exactly what fields you want:

```ruby
SimpleAMS::Renderer.new(user, {
  serializer: UserSerializer, fields: [:id, :email, :name, :created_at]
}).to_json
```

or even specify the links subset that you want:

```ruby
SimpleAMS::Renderer.new(user, {
  serializer: UserSerializer, fields: [:id, :email, :name, :created_at],
  links: [:self, :comments, :posts]
}).to_json
```

and the list goes on.. basically the rendering DSL is identical

#### includes vs relations
There might be some confusion between `includes` and `relations`, so to clear things up:
* `includes`: specifies which relations you want to include, out of the available relations.
* `relations`: specifies the available relations, so it's not just an array of
  symbols, but rather full relation objects which are generated through the dsl.
  The raw representation of relations is an array of objects where each object
  is `[relation_type, name, options, embedded_options]`. Here
   `relation_type` is the type of the relation (`has_many`, `belongs_to` etc),
   `name` is the name of the relation (like users), `options`, any relation options,
   and `embedded_options` relevant to embedded options.

So when rendering, if you don't want any relations at all, the correct way is to
specify `includes: []`. In practice you can use `relations: []` as well, but that
will mean that the serializer has no relations at all (takes precedence over
`includes`). But that's not the correct way to do it. For instance, thing about
another scenario: you want to specify only one relation, the `feed` relation.
With `includes` you would have `includes: [:feed]`. With relations, you would
have to specify the relation at runtime (
`relations: [[:has_one, :feed, {serializer: FeedSerializer, fields: [:id, :content]}, {}]]`
) and then also specify that you only want that: `includes: [:feed]`.

In general, there is no reason why you should use `relations` at rendering time,
instead you should leave that to the serializer, and only specify the `includes`.

Btw you might have noticed `includes` only as a rendering option, but SimpleAMS
DSL is used all over the place, and actually it's a serializer option as well
(just that it's not very useful ^_^).


#### Rendering collections
Rendering a collection is similar, only that you need to call
`SimpleAMS::Renderer::Collection` instead of just `SimpleAMS::Renderer`:

```ruby
SimpleAMS::Renderer::Collection.new(users, {
  serializer: UserSerializer, fields: [:id, :email, :name, :created_at],
  links: [:self, :comments, :posts]
}).to_json
```

Note that even with collection, by default everything goes to the resource.
If you need to specify options for the collection itself, you need to use the
collection key. For instance, having some metas inside the collection:

```ruby
SimpleAMS::Renderer::Collection.new(users, {
  serializer: UserSerializer, fields: [:id, :email, :name, :created_at],
  links: [:self, :comments, :posts],
  collection: {
    metas: [:total_count]
  }
}).to_json
```

#### Rendering options with values
If you want to specify the actual values when rendering the resource, rather
than taking into account the serializer, you can inject a hashmap:

```ruby
SimpleAMS::Renderer::Collection.new(users, {
  serializer: UserSerializer, fields: [:id, :email, :name, :created_at],
  links: [:self, :comments, :posts],
  collection: {
    metas: {
      total_count: users.count,
  }
}).to_json
```

Of course, you can also pass a lambda there, but not sure what’s the point since
the lambda parameter is the resource that you already try to render so it’s not
going to give you anything more (and will be slower actually).

#### Exposing methods inside the serializer, like helpers
When rendering you can expose a couple of objects in the serializer:

```ruby
SimpleAMS::Renderer::Collection.new(users, {
  serializer: UserSerializer, fields: [:id, :email, :name, :created_at],
  #exposing helpers that will be available inside the serializer
  expose: {
    #a class
    current_user: User.first
    #or a module
    helpers: CommonHelpers
  },
}).to_json
```

The expose attribute is also available through DSL, although usually that’s not
very useful. Just wanted to mentions that there is actually parity on everything,
since everything has been built on the same building blocks :)

### Extended DSL show off
Here is an extended example of the DSL. It's not a real use case of course, but
shows what's possible with SimpleAMS and its powerful DSL.

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
      }
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
