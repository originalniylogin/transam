# most class and instance methods of assets acting as transam asset can be accessed from the TransamAsset model
# but there are some methods that are across all classes but acting as themselves (rev vehicle, facility, etc)
# so they inherit from TransamAssetRecord
class TransamAssetRecord < ActiveRecord::Base
  self.abstract_class = true

  # Returns true if the asset is of the specified class or has the specified class as
  # and ancestor (superclass).
  #
  # usage: a.type_of? type
  # where type can be one of:
  #    a symbol e.g :vehicle
  #    a class name eg Vehicle
  #    a string eg "vehicle"
  #
  def type_of?(type)
    begin
      self.class.ancestors.include?(type.to_s.classify.constantize)
    rescue
      false
    end
  end

  def to_param
    object_key
  end

  def to_s
    asset_tag
  end


  def transfer new_organization_id
    org = Organization.where(:id => new_organization_id).first

    transferred_asset = self.very_specific.copy false
    transferred_asset.object_key = nil

    transferred_asset.disposition_date = nil
    transferred_asset.in_service_date = nil
    transferred_asset.purchase_cost = nil
    transferred_asset.purchase_date = nil
    transferred_asset.purchased_new = false
    transferred_asset.title_ownership_organization_id = nil
    transferred_asset.other_title_ownership_organization = nil

    transferred_asset.organization = org
    transferred_asset.generate_object_key(:object_key)
    transferred_asset.asset_tag = transferred_asset.object_key

    transferred_asset.save(:validate => false)

    return transferred_asset
  end

end