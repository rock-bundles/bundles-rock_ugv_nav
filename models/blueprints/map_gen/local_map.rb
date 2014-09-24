#require 'models/blueprints/pose'
require 'models/blueprints/sensors'
using_task_library 'local_mapper'
module Rock
    module MapGen
        class LocalMap < Syskit::Composition
            add Base::LaserRangeFinderSrv, :as => 'laser'
            #add Base::PoseSrv, :as => 'pose'
            add(LocalMapper::Task, :as => 'generator')
            #    with_arguments(:initial_heading => nil)
            #pose_child.pose_samples_port.connect_to generator_child
            laser_child.connect_to generator_child.scan_samples_port
        end
    end
end

