require 'models/blueprints/control'
module Rock
    module UGVNav
        # Generates a constant Motion2DCommand and outputs it to a
        # Motion2DControlledSystemSrv component
        class ConstantMotion2D < Syskit::Composition
            argument :translation, :default => 0
            argument :rotation, :default => 0
            add Base::Motion2DControlledSystemSrv, :as => 'system'

            script do
                cmd_w = system_child.command_in_port.writer
                poll do
                    cmd_w.write(:translation => translation, :rotation => rotation)
                end
            end
        end
    end
end

