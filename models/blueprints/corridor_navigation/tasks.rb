module CorridorPlanner
end
module CorridorNavigation
end
module Rock
    module CorridorNavigation
        include ::CorridorNavigation
        include ::CorridorPlanner
    end
end

