require 'rock/models/blueprints/control'
require 'rock_ugv_nav/models/blueprints/map_gen/map_generator_srv'
using_task_library 'trajectory_follower'

module Rock
    module PathNavigation
        # Path navigation behaviour that expects a planner that continuously
        # updates the generated path
        class Dynamic < Syskit::Composition
            # The target X position in the provided map
            #
            # It can be unset, in which case the target_pose child must be given
            #
            # @return [Float
            argument :target_x, :default => nil
            # The target Y position in the provided map
            #
            # It can be unset, in which case the target_pose child must be given
            #
            # @return [Float
            argument :target_y, :default => nil

            # The system's pose in the global map
            add Base::PoseSrv, :as => 'pose'
            # The target's pose in the global map
            #
            # If not given, the {#target_x} and {#target_y} arguments should be set
            add_optional Base::PoseSrv, :as => 'target_pose'
            # The path planner
            add DynamicPathPlannerSrv, :as => 'planner'
            # The path following
            add(Base::ControlLoop, :as => 'path_follower').
                use('controller' => TrajectoryFollower::Task, 'pose' => pose_child)
            # The map generator
            add Rock::MapGen::TraversabilitySrv, :as => 'traversability_mapping'

            event :start do |context|
                if !(target_x && target_y) && !find_child_from_role(target_pose_child)
                    raise ArgumentError, "you must either provide the target_x/target_y arguments or give the target_pose child"
                elsif target_x && target_y && find_child_from_role(target_pose_child)
                    raise ArgumentError, "you cannot both give the target_pose child and set the target_x and target_y arguments"
                end

                emit :start
            end

            traversability_mapping_child.map_port.connect_to planner_child
            pose_child.pose_samples_port.connect_to        planner_child.robot_pose_port
            target_pose_child.pose_samples_port.connect_to planner_child.target_pose_port
            planner_child.connect_to path_follower_child

            script do
                writer = planner_child.target_pose_port.writer
                wait_any planner_child.start_event
                poll do
                    if target_x && target_y
                        rbs = Types::Base::Samples::RigidBodyState.invalid
                        rbs.position.x = target_x
                        rbs.position.y = target_y
                        writer.write rbs
                    end
                end
            end
        end
    end
end

