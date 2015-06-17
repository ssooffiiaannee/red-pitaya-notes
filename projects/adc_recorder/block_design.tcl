# Create processing_system7
cell xilinx.com:ip:processing_system7:5.5 ps_0 {
  PCW_IMPORT_BOARD_PRESET cfg/red_pitaya.xml
  PCW_USE_S_AXI_HP0 1
} {
  M_AXI_GP0_ACLK ps_0/FCLK_CLK0
  S_AXI_HP0_ACLK ps_0/FCLK_CLK0
}

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {
  make_external {FIXED_IO, DDR}
  Master Disable
  Slave Disable
} [get_bd_cells ps_0]

# Create proc_sys_reset
cell xilinx.com:ip:proc_sys_reset:5.0 rst_0

# Create util_ds_buf
cell xilinx.com:ip:util_ds_buf:2.1 buf_0 {
  C_SIZE 2
  C_BUF_TYPE IBUFDS
} {
  IBUF_DS_P daisy_p_i
  IBUF_DS_N daisy_n_i
}

# Create util_ds_buf
cell xilinx.com:ip:util_ds_buf:2.1 buf_1 {
  C_SIZE 2
  C_BUF_TYPE OBUFDS
} {
  OBUF_DS_P daisy_p_o
  OBUF_DS_N daisy_n_o
}

# Create axis_red_pitaya_adc
cell pavel-demin:user:axis_red_pitaya_adc:1.0 adc_0 {} {
  adc_clk_p adc_clk_p_i
  adc_clk_n adc_clk_n_i
  adc_dat_a adc_dat_a_i
  adc_dat_b adc_dat_b_i
  adc_csn adc_csn_o
}

# Create c_counter_binary
cell xilinx.com:ip:c_counter_binary:12.0 cntr_0 {
  Output_Width 32
} {
  CLK adc_0/adc_clk
}

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_0 {
  DIN_WIDTH 32 DIN_FROM 26 DIN_TO 26 DOUT_WIDTH 1
} {
  Din cntr_0/Q
  Dout led_o
}

# Create axi_cfg_register
cell pavel-demin:user:axi_cfg_register:1.0 cfg_0 {
  CFG_DATA_WIDTH 64
  AXI_ADDR_WIDTH 32
  AXI_DATA_WIDTH 32
}

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {
  Master /ps_0/M_AXI_GP0
  Clk Auto
} [get_bd_intf_pins cfg_0/S_AXI]

set_property RANGE 4K [get_bd_addr_segs ps_0/Data/SEG_cfg_0_reg0]
set_property OFFSET 0x40000000 [get_bd_addr_segs ps_0/Data/SEG_cfg_0_reg0]

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_1 {
  DIN_WIDTH 64 DIN_FROM 0 DIN_TO 0 DOUT_WIDTH 1
} {
  Din cfg_0/cfg_data
}

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_2 {
  DIN_WIDTH 64 DIN_FROM 1 DIN_TO 1 DOUT_WIDTH 1
} {
  Din cfg_0/cfg_data
}

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_3 {
  DIN_WIDTH 64 DIN_FROM 63 DIN_TO 32 DOUT_WIDTH 32
} {
  Din cfg_0/cfg_data
}

# Create xlconstant
cell xilinx.com:ip:xlconstant:1.1 const_1

# Create axis_clock_converter
cell xilinx.com:ip:axis_clock_converter:1.1 fifo_0 {} {
  S_AXIS adc_0/M_AXIS
  s_axis_aclk adc_0/adc_clk
  s_axis_aresetn const_1/dout
  m_axis_aclk ps_0/FCLK_CLK0
  m_axis_aresetn slice_1/Dout
}

# Create axis_broadcaster
cell xilinx.com:ip:axis_broadcaster:1.1 bcast_0 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  M_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 4
  M_TDATA_NUM_BYTES 2
  M00_TDATA_REMAP {tdata[13:0],2'b00}
  M01_TDATA_REMAP {tdata[29:16],2'b00}
} {
  S_AXIS fifo_0/M_AXIS
  aclk ps_0/FCLK_CLK0
  aresetn rst_0/peripheral_aresetn
}

# Create cic_compiler
cell xilinx.com:ip:cic_compiler:4.0 cic_0 {
  INPUT_DATA_WIDTH.VALUE_SRC USER
  FILTER_TYPE Decimation
  NUMBER_OF_STAGES 6
  FIXED_OR_INITIAL_RATE 64
  INPUT_SAMPLE_FREQUENCY 125
  CLOCK_FREQUENCY 125
  INPUT_DATA_WIDTH 14
  QUANTIZATION Truncation
  OUTPUT_DATA_WIDTH 16
  USE_XTREME_DSP_SLICE true
} {
  S_AXIS_DATA bcast_0/M00_AXIS
  aclk ps_0/FCLK_CLK0
}

# Create cic_compiler
cell xilinx.com:ip:cic_compiler:4.0 cic_1 {
  INPUT_DATA_WIDTH.VALUE_SRC USER
  FILTER_TYPE Decimation
  NUMBER_OF_STAGES 6
  FIXED_OR_INITIAL_RATE 64
  INPUT_SAMPLE_FREQUENCY 125
  CLOCK_FREQUENCY 125
  INPUT_DATA_WIDTH 14
  QUANTIZATION Truncation
  OUTPUT_DATA_WIDTH 16
  USE_XTREME_DSP_SLICE true
} {
  S_AXIS_DATA bcast_0/M01_AXIS
  aclk ps_0/FCLK_CLK0
}

# Create axis_combiner
cell  xilinx.com:ip:axis_combiner:1.1 comb_0 {
  TDATA_NUM_BYTES.VALUE_SRC USER
  TDATA_NUM_BYTES 4
} {
  S00_AXIS cic_0/M_AXIS_DATA
  S01_AXIS cic_1/M_AXIS_DATA
  aclk ps_0/FCLK_CLK0
  aresetn rst_0/peripheral_aresetn
}

# Create fir_compiler
cell xilinx.com:ip:fir_compiler:7.2 fir_0 {
  DATA_WIDTH.VALUE_SRC USER
  DATA_WIDTH 16
  COEFFICIENTVECTOR {-1.64753028794138e-08, -4.72969860103254e-08, -7.81983994864729e-10, 3.09179315378013e-08, 1.8600476137934e-08, 3.27300695910419e-08, -6.27121813377163e-09, -1.52196115352429e-07, -8.30377969926702e-08, 3.14361841397898e-07, 3.05515872274853e-07, -4.73906648324436e-07, -7.13188274738437e-07, 5.47004771774003e-07, 1.33401100809314e-06, -4.13867548024707e-07, -2.14949555259695e-06, -6.77977800948474e-08, 3.07398932714553e-06, 1.0366230107463e-06, -3.94245232963009e-06, -2.59076839821521e-06, 4.51317323767107e-06, 4.74563996488482e-06, -4.49064349142054e-06, -7.3947777960083e-06, 3.57041197419745e-06, 1.02846684426837e-05, -1.50308472093842e-06, -1.30146997163052e-05, -1.8311731233767e-06, 1.50710364353895e-05, 6.3515248701083e-06, -1.58982472678568e-05, -1.17267343142635e-05, 1.50041199296265e-05, 1.73635115814309e-05, -1.20890304109726e-05, -2.24560062957254e-05, 7.16700059796055e-06, 2.60907689345942e-05, -6.64193032293714e-07, -2.74163749798938e-05, -6.54632074532538e-06, 2.5852558776971e-05, 1.31966582845397e-05, -2.13079073598636e-05, -1.77801135294917e-05, 1.43611952054032e-05, 1.88093817512436e-05, -6.35698021047062e-06, -1.51543007857966e-05, -6.31269475321274e-07, 6.41236246473726e-06, 4.00235076480002e-06, 6.75384652715119e-06, -1.00102812372645e-06, -2.23907547607786e-05, -1.07614170164429e-05, 3.72128949266483e-05, 3.26888314865614e-05, -4.68343172264928e-05, -6.46247522446593e-05, 4.62331324663801e-05, 0.000104353987875991, -3.05204178369922e-05, -0.000147387572103254, -4.12376672483791e-06, 0.000187096070793206, 5.94492160104715e-05, -0.000215270553995213, -0.000134242574203586, 0.000223115373945588, 0.000223732063932204, -0.000202601585158347, -0.000319473722277179, 0.000148023831554525, 0.000409856470754451, -5.75319241913947e-05, -0.00048128691789378, -6.56435551088113e-05, 0.000520005389882914, 0.000212559310978688, -0.000514378040456993, -0.000368824791639381, 0.000457257636791032, 0.00051572189965271, -0.000348325111720936, -0.000632574861580132, 0.000195575644936742, 0.000699853643923955, -1.5816811333843e-05, -0.000702875004558909, -0.000166267212059945, 0.000635554670416145, 0.000320646045613507, -0.000503596369030625, -0.000416023690327203, 0.000326453158345306, 0.00042516016658693, -0.000137454215410763, -0.000330867755122004, -1.83577770104995e-05, 0.000131884375290827, 8.88732824246191e-05, 0.000152320700965935, -2.19145324792827e-05, -0.000478845867687744, -0.000226130995959082, 0.000781165284659716, 0.000680083599509367, -0.000973297239795462, -0.00133684955123469, 0.000956951103249511, 0.00215724393391554, -0.000632647805407322, -0.00306094569410801, -8.63474252426424e-05, 0.00392560461099799, 0.00125840455441931, -0.00459097537930345, -0.00289777037472875, 0.00486843895178868, 0.00496041688761007, -0.00455566278421732, -0.0073332195556104, 0.00345548961533671, 0.00982788076765724, -0.0013975392826423, -0.0121803938743171, -0.00173944634676796, 0.0140556603140014, 0.00600554245501628, -0.0150585666700821, -0.0113645359721422, 0.0147416608531572, 0.0176785888467245, -0.0126130926725902, -0.0247012339350495, 0.00812796467212303, 0.0320712315374266, -0.000646259298618774, -0.0392988478933562, -0.0106852885932714, 0.0457163887873562, 0.0272344645510023, -0.0503010855018923, -0.0516879242105393, 0.0510032995068897, 0.0905252892059647, -0.0416077244968566, -0.163677972614864, -0.0107434888500177, 0.356350050991766, 0.554721342376512, 0.356350050991766, -0.0107434888500177, -0.163677972614864, -0.0416077244968565, 0.0905252892059646, 0.0510032995068897, -0.0516879242105392, -0.0503010855018923, 0.0272344645510023, 0.0457163887873562, -0.0106852885932714, -0.0392988478933562, -0.000646259298618766, 0.0320712315374266, 0.008127964672123, -0.0247012339350495, -0.0126130926725902, 0.0176785888467245, 0.0147416608531572, -0.0113645359721422, -0.0150585666700821, 0.00600554245501627, 0.0140556603140014, -0.00173944634676796, -0.0121803938743171, -0.0013975392826423, 0.00982788076765723, 0.00345548961533672, -0.0073332195556104, -0.00455566278421732, 0.00496041688761004, 0.00486843895178868, -0.00289777037472874, -0.00459097537930345, 0.00125840455441931, 0.003925604610998, -8.6347425242651e-05, -0.00306094569410801, -0.000632647805407327, 0.00215724393391554, 0.000956951103249513, -0.00133684955123469, -0.000973297239795458, 0.00068008359950937, 0.000781165284659718, -0.000226130995959085, -0.000478845867687734, -2.19145324792814e-05, 0.000152320700965923, 8.88732824246168e-05, 0.000131884375290828, -1.83577770104952e-05, -0.000330867755122008, -0.000137454215410769, 0.000425160166586931, 0.000326453158345309, -0.000416023690327193, -0.000503596369030629, 0.000320646045613497, 0.000635554670416148, -0.000166267212059939, -0.000702875004558908, -1.58168113338674e-05, 0.000699853643923955, 0.000195575644936758, -0.000632574861580132, -0.000348325111720941, 0.000515721899652708, 0.000457257636791035, -0.000368824791639379, -0.000514378040456997, 0.000212559310978687, 0.000520005389882915, -6.56435551088096e-05, -0.000481286917893776, -5.7531924191395e-05, 0.000409856470754451, 0.000148023831554525, -0.000319473722277176, -0.000202601585158348, 0.000223732063932204, 0.000223115373945587, -0.000134242574203588, -0.000215270553995212, 5.944921601047e-05, 0.000187096070793206, -4.12376672483805e-06, -0.000147387572103254, -3.05204178369924e-05, 0.000104353987875991, 4.62331324663777e-05, -6.46247522446589e-05, -4.68343172264921e-05, 3.26888314865612e-05, 3.72128949266458e-05, -1.07614170164428e-05, -2.23907547607785e-05, -1.0010281237264e-06, 6.7538465271515e-06, 4.00235076480007e-06, 6.41236246473652e-06, -6.31269475321259e-07, -1.5154300785797e-05, -6.35698021047036e-06, 1.88093817512439e-05, 1.43611952054029e-05, -1.77801135294911e-05, -2.13079073598635e-05, 1.31966582845395e-05, 2.58525587769708e-05, -6.54632074532428e-06, -2.74163749798938e-05, -6.64193032294061e-07, 2.60907689345942e-05, 7.16700059796085e-06, -2.24560062957254e-05, -1.20890304109726e-05, 1.7363511581431e-05, 1.50041199296266e-05, -1.17267343142635e-05, -1.58982472678571e-05, 6.3515248701082e-06, 1.50710364353894e-05, -1.83117312337678e-06, -1.30146997163053e-05, -1.50308472093845e-06, 1.02846684426836e-05, 3.57041197419745e-06, -7.39477779600816e-06, -4.49064349142055e-06, 4.74563996488478e-06, 4.51317323767109e-06, -2.59076839821518e-06, -3.94245232963005e-06, 1.03662301074629e-06, 3.07398932714552e-06, -6.77977800948646e-08, -2.14949555259695e-06, -4.13867548024735e-07, 1.33401100809314e-06, 5.47004771773993e-07, -7.13188274738437e-07, -4.73906648324394e-07, 3.05515872274853e-07, 3.14361841397861e-07, -8.30377969926656e-08, -1.5219611535243e-07, -6.27121813377245e-09, 3.27300695910341e-08, 1.86004761379317e-08, 3.0917931537805e-08, -7.81983994865244e-10, -4.72969860103212e-08, -1.64753028794135e-08}
  COEFFICIENT_WIDTH 16
  QUANTIZATION Quantize_Only
  BESTPRECISION true
  FILTER_TYPE Decimation
  DECIMATION_RATE 2
  NUMBER_PATHS 2
  RATESPECIFICATION Input_Sample_Period
  SAMPLEPERIOD 64
  OUTPUT_ROUNDING_MODE Truncate_LSBs
  OUTPUT_WIDTH 16
} {
  S_AXIS_DATA comb_0/M_AXIS
  aclk ps_0/FCLK_CLK0
}

# Create axis_packetizer
cell pavel-demin:user:axis_packetizer:1.0 pktzr_0 {
  AXIS_TDATA_WIDTH 32
  CNTR_WIDTH 32
  CONTINUOUS FALSE
} {
  S_AXIS fir_0/M_AXIS_DATA
  cfg_data slice_3/Dout
  aclk ps_0/FCLK_CLK0
  aresetn slice_1/Dout
}

# Create axis_dwidth_converter
cell xilinx.com:ip:axis_dwidth_converter:1.1 conv_0 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 4
  M_TDATA_NUM_BYTES 8
} {
  S_AXIS pktzr_0/M_AXIS
  aclk ps_0/FCLK_CLK0
  aresetn slice_2/Dout
}

# Create xlconstant
cell xilinx.com:ip:xlconstant:1.1 const_2 {
  CONST_WIDTH 32
  CONST_VAL 503316480
}

# Create axis_ram_writer
cell pavel-demin:user:axis_ram_writer:1.0 writer_0 {
  ADDR_WIDTH 22
} {
  S_AXIS conv_0/M_AXIS
  M_AXI ps_0/S_AXI_HP0
  cfg_data const_2/dout
  aclk ps_0/FCLK_CLK0
  aresetn slice_2/Dout
}

assign_bd_address [get_bd_addr_segs ps_0/S_AXI_HP0/HP0_DDR_LOWOCM]
