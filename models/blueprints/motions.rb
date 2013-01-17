require 'models/blueprints/control'

module Rock
    module Motion
        # This represents the generation of a fixed command to a
        # Motion2DControlledSystem
        class Fixed2DMotion < Syskit::Composition
            argument :speed, :default => 0.0 # m/s
            argument :radius, :default => 1.0 # rad/s

            add Base::Motion2DControlledSystemSrv, :as => 'cmd'

            on :start do |event|
                @writer = data_writer(cmd_child.command_in_port)
                @cmd = Types::Base::MotionCommand2D.new
                @cmd.translation = speed
                @cmd.rotation = radius
            end

            poll do
                @transvel_writer.write(@cmd)
            end
        end
    end
end

