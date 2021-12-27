using FunctionalModels, FunctionalModels.Lib, ModelingToolkit, Symbolics

const t = FunctionalModels.t
FM = FunctionalModels
S = Symbolics

function MultiPhaseRC1()
    @named n1 = Voltage(zeros(3))
    @named n2 = Voltage(zeros(3))
    g = 0.0
    [
        :Vsrc => SineVoltage(n1, g; V = 1.0, f = 1.0, ang = [0.0, -2pi/3, 2pi/3])
        :R    => Resistor(n1, n2; R = 2.0)
        :C    => Capacitor(n2, g; C = 4.0)
    ]
end

@named n1 = Voltage(zeros(3))
@named n2 = Voltage(zeros(3))
ctx = FM.flatten(Resistor(n1, n2, R = 1.0))
# rc1  = sim(MultiPhaseRC1, 60.0)

@named v1 = Voltage()
@named v2 = Voltage()
ctx2 = FM.flatten(Resistor(v1, v2, R = 1.0))
# rc1  = sim(MultiPhaseRC1, 60.0)


function MultiPhaseRC2()
    @named n1 = Voltage(zeros(3))
    @named n2 = Voltage(zeros(3))
    g = 0.0
    [
        :Vsrc => SineVoltage.(n1, g; V = 1.0, f = 1.0, ang = [0.0, -2pi/3, 2pi/3])
        :R    => Resistor.(n1, n2; R = 2.0)
        :C    => Capacitor.(n2, g; C = 4.0)
    ]
end

# rc2  = sim(MultiPhaseRC2, 60.0)

