require 'rock/models/blueprints/control'
require 'rock_ugv_nav/models/blueprints/map_gen/map_generator_srv'
using_task_library 'trajectory_follower'

module Rock
    module PathNavigation
        # Path navigation behaviour that expects a planner that continuously
        # updates the generated path
        class Dynamic < Syskit::Composition
            # The target pose in the global map
            #
            # It can be unset, in which case the target_pose child must be given
            argument :target, :default => nil

            # The system's pose in the global map
            add Base::PoseSrv, :as => 'pose'
            # The target's pose in the global map
            #
            # If not given, the 'target' argument should be set
            add_optional Base::PoseSrv, :as => 'target_pose'
            # The path planner
            add DynamicPathPlannerSrv, :as => 'planner'
            # The path following
            add(Base::ControlLoop, :as => 'path_follower').
                use('controller' => TrajectoryFollower::Task, 'pose' => pose_child)
            # The map generator
            add Rock::MapGen::TraversabilitySrv, :as => 'traversability_mapping'

            traversability_mapping_child.map_port.connect_to planner_child
            pose_child.pose_samples_port.connect_to        planner_child.robot_pose_port
            target_pose_child.pose_samples_port.connect_to planner_child.target_pose_port
            planner_child.connect_to path_follower_child
        end
    end
end

