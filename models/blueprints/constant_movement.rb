require 'models/blueprints/control'
module Rock
    module UGVNav
        # Generates a constant Motion2DCommand and outputs it to a
        # Motion2DControlledSystemSrv component
        class ConstantMovement < Syskit::Composition
            argument :translation, :default => 0
            argument :rotation, :default => 0
            add Base::Motion2DControlledSystemSrv, :as => 'system'

            on :start do
                @writer = system_child.command_in_port.writer
            end

            poll do
                writer.write(:translation => translation, :rotation => rotation)
            end
        end
    end
end

