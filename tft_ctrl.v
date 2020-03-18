module tft_ctrl(
    clk9M,
    rst_n,
    data_in,
    
    hcnt,
    vcnt,
    tft_rgb,
    tft_hs,
    tft_vs,
    tft_clk,
    tft_de,
    tft_pwm
);

input clk9M;//系统时钟
input rst_n;//系统复位
input [15:0] data_in;//待显示数据

output [9:0] hcnt;//图像区行扫描地址
output [9:0] vcnt;//图像区场扫描地址
output [15:0] tft_rgb;//数据输出
output tft_hs;//行同步信号
output tft_vs;//场同步信号
output tft_clk;//像素时钟
output tft_de;//背光使能
output tft_pwm;//背光控制

reg [9:0] hcnt_r;//行扫描计数器
reg [9:0] vcnt_r;//场扫描计数器

wire dat_act;//图像数据有效标志信号

//TFT 行、场扫描时序参数表
parameter
	tft_hs_end = 10'd40,
	hdat_begin = 10'd42,
	hdat_end = 10'd522,
	hpixel_end = 10'd524,
	
	tft_vs_end = 10'd9,
	vdat_begin = 10'd11,
	vdat_end = 10'd283,
	vline_end = 10'd285;
	
//行扫描计数器
always@(posedge clk9M or negedge rst_n)
	if(!rst_n)
		hcnt_r <= 10'd0;
	else if(hcnt_r == hpixel_end)
		hcnt_r <= 10'd0;
	else
		hcnt_r <= hcnt_r + 1'b1;
		
//场扫描计数器
always@(posedge clk9M or negedge rst_n)
	if(!rst_n)
		vcnt_r <= 10'd0;
	else if(hcnt_r == hpixel_end)begin
		if(vcnt_r == vline_end)
			vcnt_r <= 10'd0;
		else 
			vcnt_r <= vcnt_r + 1'b1;
	end
	else
		vcnt_r <= vcnt_r;
		
//行同步设计，场同步设计
assign tft_hs = (hcnt_r > tft_hs_end)?1'b1:1'b0;
assign tft_vs = (vcnt_r > tft_vs_end)?1'b1:1'b0;

//数据输出状态设计
assign dat_act = ((hcnt_r >= hdat_begin) && (hcnt_r < hdat_end) && (vcnt_r >= vdat_begin) && (vcnt_r < vdat_end))?1'b1:1'b0;
assign tft_rgb = (dat_act)?data_in:16'd0;

//行、场扫描位置输出设计
assign hcnt = hcnt_r - hdat_begin;
assign vcnt = vcnt_r - vdat_begin;

//时钟、使能、控制设计
assign tft_clk = clk9M;
assign tft_de = dat_act;
assign tft_pwm = rst_n;

endmodule 