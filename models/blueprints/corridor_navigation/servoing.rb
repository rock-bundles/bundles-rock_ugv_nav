require 'models/blueprints/corridor_navigation/tasks'
require 'models/blueprints/pose'
require 'models/blueprints/sensors'
require 'models/blueprints/control'
using_task_library 'trajectory_follower'
using_task_library 'corridor_navigation'

module Rock
    module CorridorNavigation
        # Integration of the local servoing behaviour
        #
        # It adds the ability to initialize the map in the servoing by providing it in
        # the initial_map argument
        class Servoing < Syskit::Composition
            # The initial map (if there is one). It must be a triplet [map, map_id,
            # map_pose] where
            #
            # map is the map as a marshalled envire environment
            # map_id the ID of the map in 'map'
            # map_pose is the current pose of the robot within this map
            argument :initial_map, :default => nil

            add Base::RelativePoseSrv, :as => 'pose'
            add Base::LaserRangeFinderSrv, :as => 'laser'
            add(Base::ControlLoop, :as => 'control').
                use(pose, 'controller' => TrajectoryFollower::Task)
            add_main_task(CorridorNavigation::ServoingTask, :as => 'servoing')
            pose_child.pose_samples_port.connect_to servoing_child.odometry_samples_port
            laser_child.connect_to servoing_child
            servoing_child.connect_to control_child

            # Event emitted if the initial_map argument is set to a non-nil value, once
            # the map is written to the corridor servoing
            event :initial_map_written

            on :start do
                if initial_map
                    map, map_pose, map_id = *initial_map
                    corridor_servoing_child.execute do
                        if !servoing_child.setMap_op(map, map_id, map_pose)
                            raise "Failed to set initial map"
                        end
                        emit :initial_map_written
                    end
                end
            end
        end
    end
end

