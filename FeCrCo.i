[Mesh]
  type = GeneratedMesh
  dim = 2
  elem_type = QUAD4
  nx = 100
  ny = 100
  xmax = 200
  ymax = 200
#  uniform_refine = 2
[]

[Variables] #c2 = Cr, c3 = Co
  [c2]
  []
  [w2]
  []
  [c3]
  []
  [w3]
  []

#  [disp_x]
#  []
#  [disp_y]
#  []
[]

[GlobalParams]
#  displacements = 'disp_x disp_y'
  block = 0
[]

[ICs]
  [c_CrIC]
    type = RandomIC
    variable = c2
    min = crmin
    max = crmax
  []

  [c_CoIC]
    type = RandomIC
    variable = c3
    min = comin
    max = comax
  []
[]

[BCs]
  [Periodic]
    [c_bcs]
      auto_direction = 'x y'
    []
  []
[]

[Kernels]
# Implementing Off-diagonal Onsager Matrix with Koyama 2004, Equation 8:
# (Example shown in: https://mooseframework.org/source/kernels/SplitCHWRes.html)
  [c2_res]
    type = SplitCHParsed
    variable = c2
    f_name = F_sum
    kappa_name = kappa_c
    w = w2
    args = 'c3'
  []

  [w22_res]
    type = SplitCHWRes
    variable = w2
    mob_name = M_22
  []

  [w23_res]
    type = SplitCHWRes
    variable = w2
    w = w3
    mob_name = M_23
  []

  [c3_res]
    type = SplitCHParsed
    variable = c3
    f_name = F_sum
    kappa_name = kappa_c
    w = w3
    args = 'c2'
  []

  [w33_res]
    type = SplitCHWRes
    variable = w3
    mob_name = M_33
  []

  [w32_res]
    type = SplitCHWRes
    variable = w3
    w = w2
    mob_name = M_23
  []

  [time_c2]
    type = CoupledTimeDerivative
    variable = w2
    v = c2
  []

  [time_c3]
    type = CoupledTimeDerivative
    variable = w3
    v = c3
  []

#  [TensorMechanics]
#    displacements = 'disp_x disp_y'
#  []
[]

[Materials]
# Koyama 2004, Table 1: kappa_c = 1.0e-14 (J*m^2/mol)
  [gradient_coef]
    type = GenericFunctionMaterial
    prop_names = 'kappa_c' #Mobility M_23 = M_32
    prop_values ='1.0e-14*6.24150934e+18*1e+09^2*1e-27'
  []

  [C_Fe]
    type = DerivativeParsedMaterial
    f_name = c1
    function = '1 - c2 - c3'
    args = 'c2 c3'
    derivative_order = 2
    outputs = exodus
  []

  [RT_clnc] # Koyama 2004, Second term of G^alpha_c (Equation 2 contribution of the free energy)
    type = DerivativeParsedMaterial
    f_name = RT_clnc
    constant_names = '     T    eV_J            d      R'
    constant_expressions ='TTT  6.24150934e+18  1e-27  8.31446261815324'
    material_property_names = 'c1(c2,c3)'
    function = 'eV_J*d*(R*T*(c1*log(c1)+c2*log(c2)+c3*log(c3)))'
    args = 'c2 c3'
    derivative_order = 2
    outputs = exodus
  []

  [heat_of_mixing] # Koyama 2004, Third term of G^alpha_c (Equation 2 contribution of the free energy)
    type = DerivativeParsedMaterial
    f_name = E_G
    constant_names = '     eV_J            d      T'
    constant_expressions ='6.24150934e+18  1e-27  TTT'
    material_property_names = 'c1(c2,c3)'
    function = 'eV_J*d*((20500 - 9.68*T)*c1*c2 + (-23669 + 103.9627*T - 12.7886*T*log(T))*c1*c3 + ((24357 - 19.797*T) - 2010*(c3 - c2))*c2*c3)'
    args = 'c2 c3'
    outputs = exodus
    derivative_order = 2
  []

  [magnetic_contribution_to_Gibbs] # Koyama 2004, Equation 2: ^mgG^alpha
    type = DerivativeParsedMaterial
    f_name = mg_G
    material_property_names = 'f_tau(c2,c3) c1(c2,c3)'
    constant_names = '     eV_J            d      T    R'
    constant_expressions ='6.24150934e+18  1e-27  TTT  8.31446261815324'
    function = 'eV_J*d*(R*T*log((2.22*c1 - 0.01*c2 + 1.35*c3 - 0.85*c1*c2 + (2.4127 + 0.2418*(c3-c1))*c1*c3)+1)*f_tau)' #f_tau Defined below
    args = 'c2 c3'
    outputs = exodus
    derivative_order = 2
  []

  [tau] # Koyama 2004, Equation 2: tau = T/Curie_Temperature
    type = DerivativeParsedMaterial
    f_name = tau
    material_property_names = 'c1(c2,c3)'
    function = 'TTT/(1043*c1 - 311.5*c2 + 1450*c3 + (1650 + 550*(c2-c1))*c1*c2 + 590*c1*c3)'
    args = 'c2 c3'
    outputs = exodus
    derivative_order = 2
  []

  [tau_function] # Koyama 2004, Equation 2: f(tau)
  # Koyama does not explicitly define f(tau)
  # Expression for f(tau) was obtained by Xiong 2012 (http://dx.doi.org/10.1016/j.calphad.2012.07.002), Equation 5
    type = DerivativeParsedMaterial
    f_name = f_tau
    constant_names = '     p    A'
    constant_expressions ='0.4  1.55828482003'
    function='if(tau<1.00000, 1-1/A*(79*tau^-1/(140*p)+474/497*(1/p-1)*(tau^3/6+tau^9/135+tau^15/600)), -1/A*(1/10*tau^-5+1/315*tau^-15+1/1500*tau^-25))'
    args = 'c2 c3'
    material_property_names = 'tau(c2,c3) c1(c2,c3)'
    derivative_order = 2
  []

  # Onsager coefficients: "Mobility_Lij":
  [Mobility_M22] # Koyama 2004, After Equation 8: L22
    type = DerivativeParsedMaterial
    f_name = M_22
    constant_names = '     nm_m   eV_J            d      T    R'
    constant_expressions ='1e+09  6.24150934e+18  1e-27  TTT  8.31446261815324'
    material_property_names = 'c1(c2,c3)'
    function = 'nm_m^2/eV_J/d*(c1*c2*(1.0e-4*exp(-294000/(8.31446261815324*TTT))) + (1-c2)^2*(2.0e-5*exp(-308000/(8.31446261815324*TTT))) + c2*c3*(1.0e-4*exp(-294000/(8.31446261815324*TTT))))*c2/(R*T)'
    args = 'c2 c3'
    derivative_order = 1
  []

  [Mobility_M23] # Koyama 2004, After Equation 8: L23
    type = DerivativeParsedMaterial
    f_name = M_23
    constant_names = '     nm_m   eV_J            d      T    R'
    constant_expressions ='1e+09  6.24150934e+18  1e-27  TTT  8.31446261815324'
    material_property_names = 'c1(c2,c3)'
    function = 'nm_m^2/eV_J/d*(c1*(1.0e-4*exp(-294000/(8.31446261815324*TTT))) - (1-c2)*(2.0e-5*exp(-308000/(8.31446261815324*TTT))) - (1-c3)*(1.0e-4*exp(-294000/(8.31446261815324*TTT))))*c2*c3/(R*T)'
    args = 'c2 c3'
    derivative_order = 1
  []

  [Mobility_M33] # Koyama 2004, After Equation 8: L33
    type = DerivativeParsedMaterial
    f_name = M_33
    #material_property_names = 'D_1  D_2  D_3'
    constant_names = '     nm_m   eV_J            d      T    R'
    constant_expressions ='1e+09  6.24150934e+18  1e-27  TTT  8.31446261815324'
    material_property_names = 'c1(c2,c3)'
    function = 'nm_m^2/eV_J/d*(c1*c3*(1.0e-4*exp(-294000/(8.31446261815324*TTT))) + c2*c3*(2.0e-5*exp(-308000/(8.31446261815324*TTT))) + (1-c3)^2*(1.0e-4*exp(-294000/(8.31446261815324*TTT))))*c3/(R*T)'
    args = 'c2 c3'
    derivative_order = 1
  []

  [F_system] # Total free energy of the system
    type = DerivativeSumMaterial
    f_name = F_sum
    sum_materials = 'mg_G RT_clnc E_G' #ElasticCr'
    args = 'c2 c3'
    derivative_order = 2
  []
[]

[Preconditioning]
  [coupled]
    type = SMP
    full = true
  []
[]

[Executioner]
  type = Transient
  solve_type = PJFNK
  automatic_scaling = true
  l_max_its = 30
  l_tol = 1e-6
  nl_max_its = 15
  nl_abs_tol = 1e-9
  end_time = 360000
  petsc_options_iname = '-pc_type -ksp_gmres_restart -sub_ksp_type
                         -sub_pc_type -pc_asm_overlap'
  petsc_options_value = 'asm      31                  preonly
                         ilu          2'
  [TimeStepper]
    type = IterationAdaptiveDT
    dt = 10
    cutback_factor = 0.8
    cutback_factor_at_failure = 0.5
    growth_factor = 1.5
    optimal_iterations = 7
  []
  [Adaptivity]
    coarsen_fraction = 0.1
    refine_fraction = 0.7
    max_h_level = 2
  []
[]

[Outputs]
  exodus = true
[]
