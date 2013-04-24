module Rock
    # This module contains the standard map generation functionality in Rock
    module MapGen
    end
end

require 'models/blueprints/odometry'
require 'models/blueprints/map_gen/map_generator_srv'
require 'models/blueprints/map_gen/local_map'
require 'models/blueprints/map_gen/eslam'
require 'models/blueprints/map_gen/traversability_map'
