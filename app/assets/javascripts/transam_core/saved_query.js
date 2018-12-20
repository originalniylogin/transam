//
// Javascript for saved query
//

function SavedQuery() {
  var _selected_output_field_ids = {};
  var _selected_filter_field_ids = {};
  var _query_filters = {};

  this.getSelectedOutputFieldIds = function() {
    var field_ids = [];
    for(var c_id in _selected_output_field_ids) {
      field_ids = field_ids.concat(_selected_output_field_ids[c_id]); 
    }

    return field_ids;
  }

  this.getQueryFilterArray = function() {
    var filters = [];
    for(var field_id in _query_filters) {
      var filter_details = _query_filters[field_id];
      if(filter_details) {
        filters = filters.concat(filter_details); 
      }
    }

    return filters;
  }

  this.getSelectedOutputFieldIdsByCategory = function(category_id) {
    return _selected_output_field_ids[category_id] || [];
  }

  this.getSelectedFilterFieldIdsByCategory = function(category_id) {
    return _selected_filter_field_ids[category_id] || [];
  }

  this.setSelectedOutputFieldIdsByCategory = function(category_id, field_ids) {
    _selected_output_field_ids[category_id] = field_ids;
  }

  this.setSelectedFilterFieldIdsByCategory = function(category_id, field_ids) {
    _selected_filter_field_ids[category_id] = field_ids;
  }

  this.getFilterDetails = function(field_id) {
    return _query_filters[field_id];
  }

  this.setFilterDetails = function(field_id, filter_details) {
    _query_filters[field_id] = filter_details;
  }

  this.removeFilterDetails = function(field_id) {
    _query_filters[field_id] = null;
  }

  this.resetOutputColumns = function() {
    _selected_output_field_ids = {};
  }

  this.resetFilters = function() {
    _selected_filter_field_ids = {};
    _query_filters = {};
  }

  this.reset = function() {
    this.resetOutputColumns();
    this.resetFilters();
  }

  this.data = function() {
    var _data = {
      query_field_ids: this.getSelectedOutputFieldIds(),
      query_filters: this.getQueryFilterArray()
    };

    return _data;
  }
}