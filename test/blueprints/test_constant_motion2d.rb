require 'syskit/test'

require 'models/blueprints/constant_motion2d'

describe Rock::UGVNav::ConstantMotion2D do
    it "should send a motion2d command based on its argument to its system child" do
        motion2d_consumer = stub_syskit_task_context_model 'Consumer' do
            input_port 'cmd', '/base/MotionCommand2D'
            provides Base::Motion2DControlledSystemSrv, :as => 'controlled_system'
        end
        stub_syskit_deployment_model(motion2d_consumer)
        test = Rock::UGVNav::ConstantMotion2D.use(motion2d_consumer).
            with_arguments(:translation => 10, :rotation => 20)
        toplevel = syskit_run_deployer(test)
        toplevel = syskit_start_component(toplevel)

        port = toplevel.system_child.orocos_task.cmd
        sample = assert_has_one_new_sample(port)
        assert_in_delta 10, sample.translation, 1e-5
        assert_in_delta 20, sample.rotation, 1e-5
    end
end
