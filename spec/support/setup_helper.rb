class SetupHelper
  def set_collection_allowed_options!
    define_collection_allowed!

    UserSerializer.collection do
      Helpers::RandomOptions.fields.each do |field|
        attribute(*field.as_input)
      end

      Helpers::RandomOptions.links.each do |link|
        link(*link.as_input)
      end

      Helpers::RandomOptions.metas.each do |meta|
        meta(*meta.as_input)
      end
    end
  end

  def set_resource_allowed_options!
    UserSerializer.attributes(*resource_allowed.fields)
    resource_allowed.links.each do |link|
      UserSerializer.link(*link.as_input)
    end
    resource_allowed.metas.each do |meta|
      UserSerializer.meta(*meta.as_input)
    end
    resource_allowed.relations.each do |relation|
      UserSerializer.send(relation.type, relation.name, relation.options)
    end
  end

  def collection_injected
    @collection_injected ||= OpenStruct.new({
      fields: Helpers.pick(Helpers::RandomOptions.fields.map(&:as_input)),
      links: Helpers.pick(Helpers::RandomOptions.links.map(&:as_input)),
      metas: Helpers.pick(Helpers::RandomOptions.metas.map(&:as_input))
    })
  end

  def resource_allowed
    @resource_allowed ||= OpenStruct.new({
      fields: User.model_attributes,
      links: Elements.links,
      metas: Elements.links,
      relations: User.relations
    })
  end

  def resource_injected
    @resource_injected ||= OpenStruct.new({
      fields: Helpers.pick(resource_allowed.fields),
      includes: Elements.includes,
      links: Helpers.pick(resource_allowed.links),
      metas: Helpers.pick(resource_allowed.metas)
    })
  end

  def injected_options
    @injected_options ||= Helpers.random_options(with: {
      fields: resource_injected.fields,
      includes: resource_injected.includes,
      links: resource_injected.links.map(&:as_input),
      metas: resource_injected.metas.map(&:as_input),
      serializer: UserSerializer,
      collection: {
        fields: collection_injected.fields,
        links: collection_injected.links,
        metas: collection_injected.metas
      }
    })
  end

  def expected_relations_count
    (resource_allowed.relations.map(&:name) & resource_injected.includes).count
  end

  private
  def define_collection_allowed!
    Helpers.define_singleton_for('RandomOptions', {
      fields: Elements.fields,
      links: Elements.links,
      metas: Elements.metas
    })
  end

end
