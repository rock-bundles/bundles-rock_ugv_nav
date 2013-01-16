require 'models/blueprints/corridor_navigation/tasks'
require 'models/blueprints/corridor_navigation/servoing'

module Rock
    module CorridorNavigation
        # Extension of CorridorNavigation::Servoing to add the ability to always go
        # towards a point in a reference frame
        class Explore < Servoing
            # The target point
            # @return [Eigen::Vector3]
            argument :target
            # The threshold at which the target is considered as reached
            # @return [Numeric]
            argument :target_reached_threshold, :default => 1

            # This child provides the pose in which the target is expressed
            add Base::PoseSrv, :as => 'ref_pose'
            # TODO: be able to choose the same value for ref_pose and pose by default,
            # e.g.
            #
            #   use 'pose' => ref_pose_child
            overload('servoing', CorridorNavigation::ServoingTask).
                with_arguments(:initial_heading => nil)

            # Data reader connected to the pose port of the reference_pose child (i.e.
            # the reference pose in which the target point is expressed)
            attr_reader :ref_pose_reader
            # Data reader connected to the pose port of the pose child (i.e. the local
            # pose used by the corridor servoing)
            attr_reader :local_pose_reader

            # Event emitted when the target is reached
            event :target_reached
            forward :target_reached => :success

            on :start do |event|
                @ref_pose_reader = ref_pose_child.pose_samples_port.reader
                @local_pose_reader  = pose_child.pose_samples_port.reader
            end

            poll do
                return if !(ref = ref_pose_reader.read)
                return if !(local = local_pose_reader.read)

                direction = (target - ref.position)
                direction.z = 0
                if direction.norm < target_reached_threshold
                    emit :target_reached
                    return
                end

                # convert the reference heading to the heading in the frame used by
                # the servoing task
                ref_target_heading = Eigen::Vector3.UnitY.angle_to(direction)
                ref_cur_heading= Eigen::Vector3.UnitY.angle_to(ref.orientation * Eigen::Vector3.UnitY)
                local_cur_heading = Eigen::Vector3.UnitY.angle_to(local.orientation * Eigen::Vector3.UnitY)
                local_target_heading = ref_target_heading - (ref_cur_heading - local_cur_heading)

                if local_target_heading < 0
                    local_target_heading += 2* Math::PI
                elsif local_target_heading > 2* Math::PI
                    local_target_heading -= 2* Math::PI
                end
                direction_writer.write(local_target_heading)
            end
        end
    end
end

