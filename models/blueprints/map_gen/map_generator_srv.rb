module Rock
    module MapGen
        data_service_type 'MapGeneratorSrv' do
            output_port 'map', ro_ptr('std/vector</envire/BinaryEvent>')
        end
    end
end
