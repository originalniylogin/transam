#------------------------------------------------------------------------------
#
# Asset
#
# Base class for all assets. This class represents a generic asset, subclasses represent concrete
# asset types.
#
#------------------------------------------------------------------------------
class Asset < ActiveRecord::Base

  # Enable auditing of this model type
  has_paper_trail

  # Include the unique key mixin
  include UniqueKey

  #------------------------------------------------------------------------------
  # Overrides
  #------------------------------------------------------------------------------
  
  #require rails to use the asset key as the restful parameter. All URLS will be of the form
  # /inventory/{object_key}/...
  def to_param
    object_key
  end
  
  #------------------------------------------------------------------------------
  # Callbacks
  #------------------------------------------------------------------------------
  after_initialize  :set_defaults

  # Always generate a unique asset key before saving to the database
  before_validation(:on => :create) do
    generate_unique_key(:object_key)
  end
       
  #------------------------------------------------------------------------------
  # Associations common to all asset types
  #------------------------------------------------------------------------------

  # each asset belongs to a single organization
  belongs_to :organization        
  # each asset has a single asset type
  belongs_to :asset_type          
  # each asset has a single asset subtype
  belongs_to :asset_subtype       
  
  # each asset belongs to a single manufacturer and has a single model 
  belongs_to :manufacturer
  belongs_to :manufacturer_model
  
  # Each asset has zero or more asset events. These are all events regardless of event type
  has_many   :asset_events        

  # each asset has zero or more condition updates
  has_many   :condition_updates, -> {where :asset_event_type_id => ConditionUpdateEvent.asset_event_type.id }, :class_name => "ConditionUpdateEvent" 

  # each asset has zero or more service status updates
  has_many   :service_status_updates, -> {where :asset_event_type_id => ServiceStatusUpdateEvent.asset_event_type.id }, :class_name => "ServiceStatusUpdateEvent" 

  # each asset has zero or more disposition updates
  has_many   :disposition_updates, -> {where :asset_event_type_id => DispositionUpdateEvent.asset_event_type.id }, :class_name => "DispositionUpdateEvent"
  
  # Each asset has zero or more attachments 
  has_many   :attachments
    
  # Each asset can be associated with 0 or more districts
  has_and_belongs_to_many :districts

  # Each asset was created and updated by a user
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by_id"
  belongs_to :updator, :class_name => "User", :foreign_key => "updated_by_id"
  
  # Accessors for associations
  #attr_accessible :organization_id, :asset_type_id, :asset_subtype_id, :created_by_id, :updated_by_id

  # Validations on associations
  validates     :organization_id,     :presence => true
  validates     :asset_type_id,       :presence => true
  validates     :asset_subtype_id,    :presence => true
  validates     :created_by_id,       :presence => true
  validates_numericality_of :manufacture_year,    :only_integer => :true,   :greater_than_or_equal_to => 1900
    
  #------------------------------------------------------------------------------
  # Attributes common to all asset types
  #------------------------------------------------------------------------------
  
  # A unique string key generated by TransAM to uniquely identify an asset externally 
  #attr_accessible :object_key
  # An identiifier for the asset assigned by the user. Interoperable key used to tie the asset
  # to other business systems.
  #attr_accessible :asset_tag
  
  # Validations on core attributes
  validates       :object_key,        :presence => true, :uniqueness => true
  validates       :asset_tag,         :presence => true

  #------------------------------------------------------------------------------
  # Attributes that are used to cache asset condition information.
  # This set of attributes are updated when the asset condirtion or disposition is
  # updated. Used for reporting only.
  #------------------------------------------------------------------------------
                 
  # The last reported condition type for the asset                                                              
  belongs_to      :reported_condition_type,   :class_name => "ConditionType",   :foreign_key => :reported_condition_type_id

  # The last estimated condition type for the asset                                                              
  belongs_to      :estimated_condition_type,  :class_name => "ConditionType",   :foreign_key => :estimated_condition_type_id

  # The disposition type for the asset. Null if the asset is still operational                                                             
  belongs_to      :disposition_type

  # The last reported disposition type for the asset                                                              
  belongs_to      :service_status_type

  #------------------------------------------------------------------------------
  # Scopes
  #------------------------------------------------------------------------------
            
  # generic search scope
  scope :search_query, lambda {|organization, search_text| {:conditions => [Asset.get_search_query_string(Asset.new.searchable_fields), {:organization_id => organization.id, :search => search_text }]}}  

  #------------------------------------------------------------------------------
  # Lists. These lists are used by derived classes to make up lists of attributes
  # that can be used for operations like full text search etc. Each derived class
  # can add their own fields to the list
  #------------------------------------------------------------------------------
        
  # List of fields which can be searched using a simple text-based search
  SEARCHABLE_FIELDS = [
    'object_key',
    'asset_tag',
    'manufacture_year',
    'notes'
  ] 
          
  # List of fields that should be nilled when a copy is made
  CLEANSABLE_FIELDS = [
    'object_key',
    'asset_tag',
    'policy_replacement_year',
    'estimated_replacement_year',
    'estimated_replacement_cost',
    'in_backlog',
    'replacement_cost',
    'reported_condition_type_id',
    'reported_condition_rating',
    'reported_condition_date',
    'estimated_condition_type_id',
    'estimated_condition_rating',
    'service_status_type_id',
    'disposition_date',
    'disposition_date',
    'notes'
  ]
  
  # List of hash parameters allowed by the controller
  FORM_PARAMS = [
    :object_key,
    :organization_id, 
    :asset_type_id, 
    :asset_subtype_id, 
    :asset_tag,
    :manufacturer_id,
    :manufacturer_model_id,
    :manufacture_year,
    :notes,
    :policy_replacement_year,
    :estimated_replacement_year,
    :estimated_replacement_cost,
    :in_backlog,
    :reported_condition_type_id,
    :reported_condition_rating,
    :reported_condition_date,
    :estimated_condition_type_id,
    :estimated_condition_rating,
    :service_status_type_id,
    :service_status_date,
    :disposition_date, 
    :disposition_type_id,
    :disposition_type_id,
    :disposition_type_id,
    :created_by_id,
    :updated_by_id    
  ]
  
  #------------------------------------------------------------------------------
  #
  # Class Methods
  #
  #------------------------------------------------------------------------------
    
  def self.allowable_params
    FORM_PARAMS
  end
    
  # Factory method to return a strongly typed subclass of a new asset
  # based on the asset subtype
  def self.new_asset(asset_subtype)
    
    asset_class_name = asset_subtype.asset_type.class_name
    asset = asset_class_name.constantize.new({:asset_subtype_id => asset_subtype.id})
    return asset

  end

  # Returns a typed version of an asset. Every asset has a type and this will
  # return a specific asset type based on the AssetType attribute
  def self.get_typed_asset(asset)
    if asset
      class_name = asset.asset_type.class_name
      klass = Object.const_get class_name
      o = klass.find(asset.id)
      return o
    end
  end

  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------

  # Returns the initial cost of the asset. Derived classes should override this to 
  # handle asset-class specific caluclations where needed
  def cost
    # get a typed version of the asset and return its value
    asset = is_typed? ? self : Asset.get_typed_asset(self)
    return asset.cost unless asset.nil?
  end    
  
  # returns true if the asset instance is strongly typed, i.e., a concrete class
  # false otherwise.
  # true
  def is_typed?
    self.class.to_s == asset_type.class_name
  end
  
  # default name for an asset
  # sub classes should override this with a class-specific name
  def name
    return asset_subtype.name
  end

  # returns true if this instance can be geo_located. Always false for base class
  def geo_locatable?
    false
  end
    
  # return the number of years since the asset was manufactured. It can't be less than 0
  def age(on_date=Date.today)
    [on_date.year - manufacture_year, 0].max
  end
      
  # returns the date the asset was put into service. This date will be dependent on the asset type
  # so we always refer to the concrete class to determine the appropriate date to start the asset
  # service tracking
  def in_service_date
    # get a typed version of the asset and return its value
    asset = is_typed? ? self : Asset.get_typed_asset(self)
    return asset.in_service_date unless asset.nil?
  end    
  
  # returns the list of events associated with this asset order be date, earliest first
  def history
    asset_events
  end  
      
  # returns the the organizations's policy that governs the replacement of this asset. This needs to upcast
  # the organization type to a class that owns assets
  def policy
    org = Organization.get_typed_organization(organization)
    return org.get_policy
  end
    
  # Record that the asset has been disposed. This updates the dispostion date and the disposition_type attributes
  def record_disposition
    Rails.logger.info "Recording final disposition for asset = #{object_key}"
    unless new_record?
      unless disposition_updates.empty?
        event = disposition_updates.last
        disposition_date = event.event_date
        disposition_type = event.dispostion_type
        save
        reload
      end
    end
  end

  # Forces an update of an assets service status. This performs an update on the record
  def update_service_status
    Rails.logger.info "Updating service status for asset = #{object_key}"

    # can't do this if it is a new record as none of the IDs would be set
    unless new_record?
      unless service_status_updates.empty?
        event = service_status_updates.last
        service_status_date = event.event_date
        service_status_type = event.service_status_type
        save
        reload
      end
    end
  end
  
  # Forces an update of an assets condition. This performs an update on the record. If a policy is passed
  # that policy is used to update the asset otherwise the default policy is used
  def update_condition(policy = nil)
    # can't do this if it is a new record as none of the IDs would be set
    unless new_record?
      update_asset_state(policy)
      reload
    end
  end
  
  # Creates a duplicate that has all asset-specific attributes nilled
  def copy(cleanse = true)
    a = dup
    a.cleanse if cleanse
    a
  end

  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected
  
  # nils out all fields identified to be cleansed
  def cleanse
    cleansable_fields.each do |field|
      self[field] = nil
    end
  end

  # This is called before each save so no errors should be generated but we need to complete as many
  # updates as possible
  def update_asset_state
    Rails.logger.info "Updating condition for asset = #{object_key}"

    # Make sure we are working with a concrete asset class
    asset = is_typed? ? self : Asset.get_typed_asset(self)
    
    # Get the policy to use
    policy = policy.nil? ? asset.policy : policy
    
    # exit if we can find a policy to work on
    if policy.nil?
      Rails.logger.warn "Can't find a policy for asset = #{object_key}"
      return
    end
    
    # returns the year in which the asset should be replaced based on the policy and asset
    # characteristics
    begin
      # see what metric we are using to determine the service life of the asset
      class_name = policy.service_life_calculation_type.class_name
      asset.policy_replacement_year = calculate(asset, policy, class_name) 
    rescue Exception => e
      Rails.logger.info e.message  
    end  

    # Estimate the year that the asset will need replacing
    begin
      class_name = policy.condition_estimation_type.class_name
      asset.estimated_replacement_year = calculate(asset, policy, class_name, 'last_servicable_year')
    rescue Exception => e
      Rails.logger.info e.message  
    end  

    # returns the cost for replacing the asset in the replacement year based on the policy
    begin
      class_name = policy.cost_calculation_type.class_name
      asset.estimated_replacement_cost = calculate(asset, policy, class_name)
    rescue Exception => e
      Rails.logger.info e.message  
    end  
    
    # determine if the asset is in backlog
    begin
      # Check to see if the asset should have been replaced before this year
      replacement_year = asset.policy_replacement_year
      asset.in_backlog = replacement_year < Date.today.year
    rescue Exception => e
      Rails.logger.info e.message  
    end  

    # Update the reported condition
    begin
      if asset.condition_updates.empty?
        asset.reported_condition_date = Date.today
        asset.reported_condition_rating = 0.0
        asset.reported_condition_type = ConditionType.find_by_name('Unknown')        
      else
        event = condition_updates.last
        asset.reported_condition_date = event.event_date
        asset.reported_condition_rating = event.assessed_rating
        asset.reported_condition_type = event.condition_type
      end
    rescue Exception => e
      Rails.logger.info e.message  
    end  

    # Update the estimated condition
    begin
      # see what metric we are using to estimate the condition of the asset
      class_name = policy.condition_estimation_type.class_name
      asset.estimated_condition_rating = calculate(asset, policy, class_name)
      asset.estimated_condition_type = ConditionType.from_rating(asset.estimated_condition_rating)
    rescue Exception => e
      Rails.logger.info e.message  
    end  
    
    # save changes to this asset
    asset.save    
  end

  def searchable_fields
    SEARCHABLE_FIELDS
  end
  
  def cleansable_fields
    CLEANSABLE_FIELDS
  end
  
  # Set resonable defaults for a new asset
  def set_defaults
    self.manufacture_year ||= 2000
  end    

  #------------------------------------------------------------------------------
  #
  # Private Methods
  #
  #------------------------------------------------------------------------------
  private

  # Calls a calculate method on a Calculator class to perform a condition or cost calculation
  # for the asset. The method name defaults to x.calculate(asset) but other methods
  # with the same signature can be passed in
  def calculate(asset, policy, class_name, target_method = 'calculate')
    begin
      Rails.logger.info "#{class_name}, #{target_method}"
      # create an instance of this class and call the method
      calculator_instance = class_name.constantize.new(policy)
      Rails.logger.info "Instance created #{calculator_instance}"
      method_object = calculator_instance.method(target_method) 
      Rails.logger.info "Instance method created #{method_object}"
      method_object.call(asset)
    rescue Exception => e
      Rails.logger.error e.message
      raise TransamException.new "#{class_name} calculation failed for asset #{asset.object_key} and policy #{policy.name}"
    end
  end

  # constructs a query string for a search
  def self.get_search_query_string(searchable_fields_list)
    
    query_str = []
        
    query_str << 'organization_id = :organization_id'
    
    first = true
    
    searchable_fields_list.each do |field|
      if first
        first = false
        query_str << ' AND ('
      else
        query_str << ' OR '
      end
      
      query_str << field
      query_str << ' LIKE :search'
    end
    query_str << ')' unless searchable_fields_list.empty?
    
    return query_str.join      
  end

end
