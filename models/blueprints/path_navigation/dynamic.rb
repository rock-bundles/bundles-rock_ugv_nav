require 'models/blueprints/control'
require 'models/blueprints/map_gen/map_generator_srv'
require 'models/blueprints/map_gen/pipeline_base'
using_task_library 'trajectory_follower'

module Rock
    module PathNavigation
        # Path navigation behaviour that expects a planner that continuously
        # updates the generated path
        class Dynamic < MapGen::PipelineBase
            # The target X position in the provided map
            #
            # It can be unset, in which case the target_position child must be given
            #
            # @return [Float
            argument :target_x, :default => nil
            # The target Y position in the provided map
            #
            # It can be unset, in which case the target_position child must be given
            #
            # @return [Float
            argument :target_y, :default => nil

            # The system's pose in the global map
            add Base::PoseSrv, :as => 'pose'
            # The target's pose in the global map
            #
            # If not given, the {#target_x} and {#target_y} arguments should be set
            add_optional TargetPositionSrv, :as => 'target_position'
            # The path planner
            add DynamicPathPlannerSrv, :as => 'planner'
            # The path following
            add(Base::ControlLoop, :as => 'path_follower').
                use('controller' => TrajectoryFollower::Task, 'pose' => pose_child)
            # The map generator
            overload map_source_child, MapGen::TraversabilitySrv

            event :start do |context|
                if !(target_x && target_y) && !find_child_from_role('target_position')
                    raise ArgumentError, "you must either provide the target_x/target_y arguments or give the target_position child"
                elsif target_x && target_y && find_child_from_role('target_position')
                    raise ArgumentError, "you cannot both give the target_position child and set the target_x and target_y arguments"
                end

                emit :start
            end

            map_source_child.connect_to  planner_child
            pose_child.connect_to        planner_child
            target_position_child.connect_to planner_child
            planner_child.connect_to path_follower_child

            script do
                writer = planner_child.target_pose_port.writer
                wait_any planner_child.start_event
                poll do
                    if target_x && target_y
                        pos = Types::Base::Position.new
                        pos.x = target_x
                        pos.y = target_y
                        pos.z = 0
                        writer.write pos
                    end
                end
            end
        end
    end
end

