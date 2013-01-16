require 'models/blueprints/corridor_navigation/tasks'
require 'models/blueprints/pose'
require 'models/blueprints/control'
using_task_library 'trajectory_follower'
using_task_library 'corridor_navigation'

module Rock
    module CorridorNavigation
        # Implementation of a corridor following behaviour
        #
        # The corridor this composition follows must be represented as a
        # SingleCorridor instance that is a parent of this task, i.e. one must
        # do
        #
        #   corridor = SingleCorridor.new
        #   corridor.corridor = the_corridor
        #   corridor.depends_on(Following.use(...))
        #
        class Following < Syskit::Composition
            add Base::PoseSrv, :as => 'pose'
            add(Base::ControlLoop, :as => 'control').
                use('pose' => pose_child, 'controller' => TrajectoryFollower::Task)
            add_main_task(CorridorNavigation::FollowingTask, :as => 'follower')
            connect follower_child => control_child
            connect pose_child => follower_child

            argument :target_heading, :default => nil
            argument :monitor_pose, :default => false

            # This event is emitted if it seems that we are outside the
            # requested corridor
            event :pose_error
            forward :pose_error => :failed

            event :start do |context|
                corridor_tasks = plan.find_tasks(Corridors::SingleCorridor).
                    with_child(self).to_value_set
                if corridor_tasks.size > 1
                    raise ArgumentError, "following a sequence of corridors is not supported yet"
                elsif corridor_tasks.size == 1
                    @corridor = corridor_tasks.first.corridor
                else
                    raise "no corridor available to follow. A SingleCorridor task was expected to be parent of this CorridorFollowing task"
                end

                if defined?(super)
                    super(context)
                else emit :start
                end
            end

            on :start do |context|
                if monitor_pose
                    pose_reader = data_reader(pose_child.pose_samples_port)
                    poll do
                        # Look how far we are from the boundaries
                        if pose = pose_reader.read
                            d0 = @corridor.boundary_curves[0].distance_to(pose.position, 0, 0.01)
                            d1 = @corridor.boundary_curves[1].distance_to(pose.position, 0, 0.01)

                            error = Math.sqrt([pose.cov_position.data[0], pose.cov_position.data[4]].max)
                            start_d  = (@corridor.median_curve.start_point - pose.position).norm
                            target_d = (@corridor.median_curve.end_point - pose.position).norm
                            Robot.info "position error #{error}"
                            if d0 < error || d1 < error
                                if lifetime < 20
                                    Robot.info "lifetime < 20: ignoring position error #{error} is greater than distance to corridor boundaries #{d0} / #{d1}"
                                elsif start_d < 1
                                    Robot.info "start_d < 1: ignoring position error #{error} is greater than distance to corridor boundaries #{d0} / #{d1}"
                                elsif target_d < 1
                                    Robot.info "target_d < 1: ignoring position error #{error} is greater than distance to corridor boundaries #{d0} / #{d1}"
                                else
                                    Robot.info "position error #{error} is greater than distance to corridor boundaries #{d0} / #{d1}"
                                    emit :pose_error
                                end
                            end
                        end
                    end
                end
            end

            on :start do |context|
                follower_child.execute do
                    if target_heading
                        Robot.info "sending problem: target_heading=#{self.target_heading * 180 / Math::PI}"
                    else
                        Robot.info "sending problem: target_heading=NaN"
                    end
                    corridor_writer = data_reader(follower_child.problem_port)
                    problem = corridor_writer.new_sample
                    problem.desiredFinalHeading = self.target_heading || Base.unset
                    problem.corridor = @corridor
                    corridor_writer.write(problem)
                end
            end
        end
    end
end

