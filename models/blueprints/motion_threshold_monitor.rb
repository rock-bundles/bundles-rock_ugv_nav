require 'models/blueprints/pose'

module Rock
    module UGVNav
        # This composition waits for the robot to move for a given amount
        # (translation and rotation) and emits success when it did
        #
        # It does not contain the actual motion code, only the monitoring. It
        # can be combined with a motion action in e.g. an action script with
        #
        #     action_script 'go_forward_10m' do
        #         move = task go_forward
        #         monitor = task MotionThresholdMonitor.use(pose_def).
        #               with_arguments(:translation_threshold => 10,
        #                              :rotation_threshold => nil)
        #         start move
        #         start monitor
        #         wait monitor.triggered_event
        #         emit success_event
        #     end
        #   
        class MotionThresholdMonitor < Syskit::Composition
            argument :translation_threshold
            argument :rotation_threshold

            event :triggered

            add Base::PoseSrv, :as => 'pose'

            attr_reader :initial_position
            attr_reader :initial_heading
            attr_reader :current_position
            attr_reader :current_heading

            on :triggered do |event|
                @initial_position = current_position
                @initial_heading = current_heading
            end

            script do
                pose_r = pose_child.pose_samples_port.reader
                poll do
                    if pose_sample = pose_r.read_new
                        @current_position = pose_sample.position
                        @current_heading  = pose_sample.orientation.yaw
                        @initial_position ||= current_position
                        @initial_heading  ||= current_heading
                        if translation_threshold && ((current_position - initial_position).norm > translation_threshold)
                            triggered_event.emit
                        elsif rotation_threshold && ((current_heading - initial_heading).abs > rotation_threshold)
                            triggered_event.emit
                        end
                    end
                end
            end
        end
    end
end

