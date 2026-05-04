module top (
   inout MCU_SDA,
   output MCU_SCL
);

   driver mcu_driver (
      .SDA (MCU_SDA),
      .SCL (MCU_SCL)
   );

	
	control_unit(
		.clock(IOB_25b_G3),
		.reset_n(???),
		
		.encoder1_sda(???),
		.encoder1_scl(???),
		
		.encoder2_sda(???),
		.encoder2_scl(???),
		
		.chip_sda(IOB_31b),
		.chip_scl(IOB_29b),
	);
	
	
	
	
endmodule
