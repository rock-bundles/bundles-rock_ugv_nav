require 'models/blueprints/control'
require 'models/blueprints/map_gen/map_generator_srv'
require 'models/blueprints/map_gen/pipeline_base'
require 'models/blueprints/planning'

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
            # @return [Float]
            argument :target_x, :default => nil
            # The target Y position in the provided map
            #
            # It can be unset, in which case the target_position child must be given
            #
            # @return [Float]
            argument :target_y, :default => nil
	    # The final precision that should be achieved in m, default is 0.5 m
	    argument :target_precision_in_m, :default => 0.5

	    # Trigger the timeout when entering the distance to the object
	    argument :timeout_trigger_radius_in_m, :default => 5

	    # A timeout to make sure the robot does not inifinitely try to achieve
	    # the final precision -- timeout start when entering the radius default it 2 min
	    argument :timeout_in_s, :default => 120

            # expose internal errors
            event :planning_failed
            event :execution_failed

	    # Target might be invalid due to
	    # setting goal in an obstacle, an obstacle being set on the goal,
	    # or the goal being set outside of the existing map
	    event :invalid_target
	    event :precision_timeout

            # The system's pose in the global map
            add Base::PoseSrv, :as => 'pose'
            # The target's pose in the global map
            #
            # If not given, the {#target_x} and {#target_y} arguments should be set
            add_optional TargetPositionSrv, :as => 'target_position'
            # The path planner
            add DynamicPathPlannerSrv, :as => 'planner'
            add Planning::TrajectoryExecutionSrv, :as => 'trajectory_execution'

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
            planner_child.connect_to trajectory_execution_child

            def self.instanciate(*args)
                root = super
                root.trajectory_execution_child.execution_failed_event.
                    forward_to root.execution_failed_event
                root.planner_child.planning_failed_event.
                    forward_to root.planning_failed_event
                root.planner_child.invalid_target_event.
                    forward_to root.invalid_target_event
                root
            end

	    @timeout = nil

            script do
		reader = pose_child.pose_samples_port.reader
                writer = planner_child.target_pose_port.writer
                wait_until_ready writer
                execute do
                    if target_x && target_y
                        pos = Types::Base::Position.new
                        pos.x = target_x
                        pos.y = target_y
                        pos.z = 0
                        writer.write pos
                    end
                end

		poll do
		    if pose = reader.read_new
			if !@timeout && (pose.position[0] - target_x)**2 + (pose.position[1] - target_y)**2 <= arguments[:timeout_trigger_radius_in_m]**2
			    Robot.info "Trigger radius entered: timeout from now: #{arguments[:timeout_in_s]}"
			    @timeout = Time.now 
			end

                        distance_error = (pose.position[0] - target_x)**2 + (pose.position[1] - target_y)**2 
			if distance_error <= arguments[:target_precision_in_m]**2
			    Robot.info "Target pose reached: #{Math.sqrt(distance_error)} m away from goal"
			    emit :success
			elsif @timeout && Time.now - @timeout > arguments[:timeout_in_s]
			    Robot.warn "Target pose precision timeout: still #{Math.sqrt(distance_error)} m away from goal"
			    emit :precision_timeout
			end
		    end
		end
            end
        end
    end
end

