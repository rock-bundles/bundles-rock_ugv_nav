require 'syskit/test'
require 'models/actions/simple_motion2d'

describe Rock::UGVNav::SimpleMotion2D do
    attr_reader :interface
    attr_reader :rbs

    before do
        interface_m = Rock::UGVNav::SimpleMotion2D.new_submodel do
            attr_accessor :platform
            attr_accessor :pose_provider
        end
        @interface = interface_m.new(plan)
        @rbs = Types::Base::Samples::RigidBodyState.invalid
        rbs.position = Eigen::Vector3.new(0, 0, 0)
        rbs.orientation = Eigen::Quaternion.Identity
    end

    def generate_test_network
        interface.platform = stub_syskit_task_context_model 'Consumer' do
            input_port 'cmd', '/base/MotionCommand2D'
            provides Base::Motion2DControlledSystemSrv, :as => 'controlled_system'
        end
        stub_syskit_deployment_model(interface.platform)
        interface.pose_provider = stub_syskit_task_context_model 'PoseProvider' do
            output_port 'pose', '/base/samples/RigidBodyState'
            provides Base::PoseSrv, :as => 'pose'
        end
        stub_syskit_deployment_model(interface.pose_provider)
        root = yield
        plan.add_mission(root)
        syskit_start_component(root.motion_child)
        syskit_start_component(root.monitor_child)

        pose_port = root.monitor_child.pose_child.orocos_task.pose
        pose_port.write rbs
        cmd_port = root.motion_child.system_child.orocos_task.cmd
        process_events
        return root, pose_port, cmd_port
    end

    describe "#step_translation" do
        it "should write the specified command to the platform" do
            root, _, cmd_port = generate_test_network do
                interface.step_translation(:distance => 1, :speed => 0.1)
            end
            sample = assert_has_one_new_sample cmd_port
            assert_equal 0.1, sample.translation
            assert_equal 0, sample.rotation
        end
        it "should succeed when the pose is further than the specified distance from the start" do
            root, pose_port, _ = generate_test_network do
                interface.step_translation(:distance => 1, :speed => 0.1)
            end
            assert_event_emission root.success_event do
                rbs.position = Eigen::Vector3.new(2, 0, 0)
                pose_port.write rbs
            end
        end
    end

    describe "#step_rotation" do
        it "should write the specified command to the platform" do
            root, _, cmd_port = generate_test_network do
                interface.step_rotation(:distance => 1, :speed => 0.1)
            end
            sample = assert_has_one_new_sample cmd_port
            assert_equal 0, sample.translation
            assert_equal 0.1, sample.rotation
        end
        it "should succeed when the pose is further than the specified distance from the start" do
            root, pose_port, _ = generate_test_network do
                interface.step_rotation(:distance => 1, :speed => 0.1)
            end
            assert_event_emission root.success_event do
                rbs.orientation = Eigen::Quaternion.from_angle_axis(1.1, Eigen::Vector3.UnitZ)
                pose_port.write rbs
            end
        end
    end
end

