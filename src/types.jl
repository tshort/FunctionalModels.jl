
########################################
## Types
########################################

# typealias NumberOrUnknown{T} Union(AbstractArray, Number, Unknown{T})
typealias NumberOrUnknown{T} Union(AbstractArray, Number,
                                   RefUnknown{T}, Unknown{T})

## Generic
# typealias Signal NumberOrUnknown{DefaultUnknown}
typealias Signal Any


## Electrical
type UVoltage <: UnknownCategory
end
type UCurrent <: UnknownCategory
end

# Electrical node:
typealias ElectricalNode NumberOrUnknown{UVoltage}

# Main electrical types:
typealias Voltage Unknown{UVoltage}
typealias Current Unknown{UCurrent}


## Thermal
type UHeatPort <: UnknownCategory
end
type UTemperature <: UnknownCategory
end
type UHeatFlow <: UnknownCategory
end

# Thermal node:
typealias HeatPort NumberOrUnknown{UHeatPort}
typealias HeatFlow NumberOrUnknown{UHeatFlow}
typealias Temperature Unknown{UTemperature}


## Mechanical
type UAngle <: UnknownCategory
end
type UTorque <: UnknownCategory
end
typealias Angle Unknown{UAngle}
typealias Torque Unknown{UTorque}

# Mechanical node:
typealias Flange NumberOrUnknown{UAngle}

