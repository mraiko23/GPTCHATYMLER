# Base class for all JSON-based models
require Rails.root.join('lib', 'json_model')

class ApplicationRecord < JsonModel
  # Base class for models
end
