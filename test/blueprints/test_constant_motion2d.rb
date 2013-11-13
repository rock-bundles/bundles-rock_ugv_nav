require 'syskit/test'

require 'models/blueprints/constant_motion2d'

describe Rock::UGVNav::ConstantMotion2D do
    it "should send a motion2d command based on its argument to its system child" do
        toplevel = stub_deploy_and_start_composition(
            Rock::UGVNav::ConstantMotion2D.
                with_arguments(:translation => 10, :rotation => 20))

        sample = assert_has_one_new_sample(toplevel.system_child.command_in_port)
        assert_in_delta 10, sample.translation, 1e-5
        assert_in_delta 20, sample.rotation, 1e-5
    end
end
