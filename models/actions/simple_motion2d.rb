require 'models/blueprints/constant_motion2d'
require 'models/blueprints/motion_threshold_monitor'
module Rock
    module UGVNav
        # Set of actions that allow to move a motion2d-controlled system
        # step-by-step
        #
        # It is meant to be subclassed as to provide a 'platform' and
        # 'pose_provider' methods that return resp. the platform that should be
        # controlled (providing the Base::Motion2DControlledSystemSrv service)
        # and the reference pose (providing the Base::PoseSrv service)
        class SimpleMotion2D < Roby::Actions::Interface
            # Returns the motion2d-controlled system that should be used by the
            # step motions
            def platform
                raise NotImplementedError, "SimpleMotion2D should be subclassed and #platform and #pose_provider reimplemented in the subclass"
            end

            # Returns the motion2d-controlled system that should be used by the
            # step motions
            def pose_provider
                raise NotImplementedError, "SimpleMotion2D should be subclassed and #platform and #pose_provider reimplemented in the subclass"
            end

            describe('apply a static motion2d command until the system moved more than a given threshold').
                optional_arg('translation_speed', 'the required translation speed in meters/s', 0).
                optional_arg('rotation_speed', 'the required rotation speed in radians/s', 0).
                optional_arg('translation_threshold', 'the required motion in meters', nil).
                optional_arg('rotation_threshold', 'the required motion in radians', nil)
            def step_move(arguments = Hash.new)
                arguments = Kernel.validate_options arguments,
                    :translation_speed => 0,
                    :rotation_speed => 0,
                    :translation_threshold => nil,
                    :rotation_threshold => nil

                motion = ConstantMotion2D.
                    with_arguments(:translation => arguments[:translation_speed],
                                   :rotation => arguments[:rotation_speed]).
                    use('system' => platform)
                monitor = MotionThresholdMonitor.
                    with_arguments(:translation_threshold => arguments[:translation_threshold],
                                   :rotation_threshold => arguments[:rotation_threshold]).
                    use('pose' => pose_provider)

                root = StepMove.new
                motion  = root.depends_on(motion, :role => 'motion')
                monitor = root.depends_on(monitor, :role => 'monitor')
                monitor.triggered_event.forward_to root.success_event
                root
            end

            describe("moves one step in the forward/backward direction").
                required_arg('distance', 'the distance in meters').
                required_arg('speed', 'the speed in m/s (use negative to move backwards').
                returns(StepMove)
            def step_translation(arguments = Hash.new)
                arguments = Kernel.validate_options arguments, :distance, :speed
                step_move(:translation_speed => arguments[:speed], :translation_threshold => arguments[:distance])
            end

            describe("moves one step in rotation").
                required_arg('distance', 'the distance in radians').
                required_arg('speed', 'the speed in rad/s (positive turns counter-clockwise)').
                returns(StepMove)
            def step_rotation(arguments = Hash.new)
                arguments = Kernel.validate_options arguments, :distance, :speed
                step_move(:rotation_speed => arguments[:speed], :rotation_threshold => arguments[:distance])
            end
        end
    end
end


