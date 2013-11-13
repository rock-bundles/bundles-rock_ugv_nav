require 'syskit/test'
require 'models/blueprints/motion_threshold_monitor'

describe Rock::UGVNav::MotionThresholdMonitor do
    attr_reader :rbs

    before do
        @rbs = Types::Base::Samples::RigidBodyState.invalid
        rbs.position = Eigen::Vector3.new(0, 0, 0)
        rbs.orientation = Eigen::Quaternion.Identity
    end

    def deploy_test_network(arguments)
        test = stub_deploy_and_start_composition(
            Rock::UGVNav::MotionThresholdMonitor.
                with_arguments(arguments))
        port = test.pose_child.pose_samples_port.to_orocos_port
        port.write rbs
        process_events
        return test, port
    end

    it "initializes the initial and current position/heading with the first sample" do
        cmp, port = deploy_test_network(:translation_threshold => 10, :rotation_threshold => nil)
        assert_equal rbs.position, cmp.initial_position, rbs.position
        assert_equal rbs.position, cmp.current_position, rbs.position
        assert_equal 0, cmp.initial_heading
        assert_equal 0, cmp.current_heading
    end

    it "emits triggered if the initial pose and next pose cross the translation threshold" do
        cmp, port = deploy_test_network(:translation_threshold => 10, :rotation_threshold => nil)
        rbs.position = Eigen::Vector3.new(-10, -10, 0)
        assert_event_emission cmp.triggered_event do
            port.write rbs
        end
    end

    it "ignores heading if the rotation threshold is nil" do
        cmp, port = deploy_test_network(:translation_threshold => 10, :rotation_threshold => nil)
        rbs.orientation = Eigen::Quaternion.from_angle_axis(2, Eigen::Vector3.UnitZ)
        process_events
        assert !cmp.triggered?
    end

    it "emits triggered if the initial heading and next heading cross the rotation threshold" do
        cmp, port = deploy_test_network(:translation_threshold => nil, :rotation_threshold => 1)
        rbs.orientation = Eigen::Quaternion.from_angle_axis(-1.1, Eigen::Vector3.UnitZ)
        assert_event_emission cmp.triggered_event do
            port.write rbs
        end
    end

    it "ignores position if the translation threshold is nil" do
        cmp, port = deploy_test_network(:translation_threshold => nil, :rotation_threshold => 1)
        rbs.position = Eigen::Vector3.new(-5, -5, 0)
        process_events
        assert !cmp.triggered?
    end
end

