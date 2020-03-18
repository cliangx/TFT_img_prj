module tft_img_top(
	clk50M,
	rst_n,
	
	tft_rgb,
	tft_hs,
	tft_vs,
	tft_clk,
	tft_de,
	tft_pwm
);

	input clk50M;
	input rst_n;
	
	output [15:0] tft_rgb;
	output tft_hs;
	output tft_vs;
	output tft_clk;
	output tft_de;
	output tft_pwm;
	
	wire clk9M;
	wire [9:0] hcnt;
	wire [9:0] vcnt;
	wire [15:0] data_in;
	
	pll_clk9M pll_clk9M_u0(
		.areset(!rst_n),
		.inclk0(clk50M),
		.c0(clk9M)
	);
	
	tft_ctrl tft_ctrl_u0(
		.clk9M(clk9M),
		.rst_n(rst_n),
		.data_in(data_in),
		
		.hcnt(hcnt),
		.vcnt(vcnt),
		.tft_rgb(tft_rgb),
		.tft_hs(tft_hs),
		.tft_vs(tft_vs),
		.tft_clk(tft_clk),
		.tft_de(tft_de),
		.tft_pwm(tft_pwm)
	);
	
	imgdata_send imgdata_send_u0(
		.clk50M(clk50M),
		.rst_n(rst_n),
		.tft_de(tft_de),
		.hcnt(hcnt),
		.vcnt(vcnt),
		
		.data_in(data_in)
	);

endmodule 