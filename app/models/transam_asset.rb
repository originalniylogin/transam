class TransamAsset < ApplicationRecord

  include TransamObjectKey

  actable as: :transam_assetible

  belongs_to  :organization, :class_name => 'TransitOperator'
  belongs_to  :asset_subtype
  belongs_to  :manufacturer
  belongs_to  :manufacturer_model
  belongs_to  :vendor
  belongs_to  :operator, :class_name => 'Organization'
  belongs_to  :title_ownership_organization, :class_name => 'Organization'
  belongs_to  :lienholder, :class_name => 'Organization'

  has_and_belongs_to_many     :asset_groups, join_table: :asset_groups_assets, foreign_key: :transam_asset_id

  FORM_PARAMS = [
      :organization_id,
      :asset_subtype_id,
      :asset_tag,
      :external_id,
      :description,
      :manufacturer_id,
      :other_manufacturer,
      :manufacturer_model_id,
      :other_manufacturer_model,
      :manufacture_year,
      :purchase_cost,
      :purchase_date,
      :purchased_new,
      :in_service_date,
      :vendor_id,
      :other_vendor,
      :operator_id,
      :other_operator,
      :title_number,
      :title_ownership_organization_id,
      :other_titel_ownership_organization,
      :lienholder_id,
      :other_lienholder
  ]

  # Factory method to return a strongly typed subclass of a new asset
  # based on the asset_base_class_name
  def self.new_asset(asset_base_class_name, params={})

    asset_class_name = asset_base_class_name.class_name
    asset = asset_class_name.constantize.new(params)
    return asset

  end

  def self.allowable_params



    klass = self.all
    a = FORM_PARAMS
    assoc = klass.column_names.select{|col| col.end_with? 'ible_type'}.first
    assoc_arr = Hash.new
    assoc_arr[assoc] = nil
    t = klass.distinct.where.not(assoc_arr).pluck(assoc)

    while t.count == 1
      id_col = assoc[0..-6] + '_id'
      klass = t.first.constantize
      a << klass::FORM_PARAMS
      klass = klass.where(id: klass.pluck(id_col))
      assoc = klass.column_names.select{|col| col.end_with? 'ible_type'}.first
      assoc_arr = Hash.new
      assoc_arr[assoc] = nil
      t = klass.distinct.where.not(assoc_arr).pluck(assoc)
    end

    return a.flatten
  end

  def self.very_specific
    klass = self.all
    assoc = klass.column_names.select{|col| col.end_with? 'ible_type'}.first
    assoc_arr = Hash.new
    assoc_arr[assoc] = nil
    t = klass.distinct.where.not(assoc_arr).pluck(assoc)

    while t.count == 1
      id_col = assoc[0..-6] + '_id'
      klass = t.first.constantize.where(id: klass.pluck(id_col))
      assoc = klass.column_names.select{|col| col.end_with? 'ible_type'}.first
      assoc_arr = Hash.newev
      assoc_arr[assoc] = nil
      t = klass.distinct.where.not(assoc_arr).pluck(assoc)
    end

    return klass

  end

  def very_specific
    a = self.specific

    while a.try(:specific) != a
      a = a.specific
    end

    return a
  end

  def allowable_params
    arr = FORM_PARAMS
    a = self.specific

    while a.try(:specific) != a
      arr << a.class::FORM_PARAMS
      a = a.specific
    end

    return arr.flatten
  end

  def policy
    asset.organization.get_policy
  end

end
