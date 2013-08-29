require 'models/blueprints/map_gen/map_generator_srv'
using_task_library 'corridor_planner'
module Rock
    module MapGen
        class TraversabilityMap < Syskit::Composition
            add MLSSrv, :as => 'map_builder'
            add_main_task CorridorPlanner::Traversability, :as => 'traversability_builder'
            export traversability_builder_child.traversability_map_port
            map_builder_child.map_port.connect_to traversability_builder_child.mls_map_port
            provides TraversabilitySrv, :as => 'traversability_map'
        end
    end
end

