require 'models/blueprints/map_gen/map_generator_srv'
using_task_library 'corridor_planner'
module Rock
    module MapGen
        class TraversabilityMap < Syskit::Composition
            add MapGeneratorSrv, :as => 'map_builder'
            add_main_task CorridorPlanner::Traversability, :as => 'traversability_builder'
            export traversability_builder.traversability_map
            map_builder_child.map_port => traversability_builder_child.map_port
        end
    end
end

