module imgdata_send(
	clk50M,
	rst_n,
	tft_de,
	hcnt,
	vcnt,
	
	data_in
);

input clk50M;
input rst_n;
input tft_de;
input [9:0] hcnt;
input [9:0] vcnt;

output [15:0] data_in;

parameter
	IMG_H = 120,
	IMG_V = 120,
	
	TFT_H = 480,
	TFT_V = 272;
	
reg [9:0] img_hbegin;
reg [9:0] img_vbegin;

wire img_act;

reg [14:0] addr;
wire [15:0] img_data;

reg [24:0] cnt;
reg cnt_done;
reg [2:0] location;

img_rom img_rom_u0(
	.address(addr),
	.clock(clk50M),
	.q(img_data)
); 

assign img_act = (tft_de && (hcnt >= img_hbegin) && (hcnt < img_hbegin + IMG_H) && (vcnt >= img_vbegin) && (vcnt < img_vbegin + IMG_V))?1'b1:1'b0;

always@(posedge clk50M or negedge rst_n)
	if(!rst_n)
		addr <= 15'd0;
	else if(img_act)
		addr <= (hcnt - img_hbegin) + (vcnt - img_vbegin)*IMG_H;
	else
		addr <= 15'd0;

assign data_in = img_act?img_data:16'd0;

always@(posedge clk50M or negedge rst_n)
	if(!rst_n)begin
		cnt_done <= 1'b0;
		cnt <= 25'd0;
	end
	else if(cnt == 25'd24999999)begin
		cnt_done <= 1'b1;
		cnt <= 25'd0;
	end
	else begin
		cnt_done <= 1'b0;
		cnt <= cnt + 1'b1;
	end
	
always@(posedge clk50M or negedge rst_n)
	if(!rst_n)
		location <= 3'd0;
	else if(cnt_done)begin
		if(location == 3'd5)
			location <= 3'd0;
		else 
			location <= location + 1'b1;
	end
	else 
		location <= location;
		
always@(*)begin
	case(location)
		0: begin img_hbegin = 0; img_vbegin = 0; end
		1: begin img_hbegin = 120; img_vbegin = 0; end
		2: begin img_hbegin = 240; img_vbegin = 0; end
		3: begin img_hbegin = 240; img_vbegin = 120; end
		4: begin img_hbegin = 120; img_vbegin = 120; end
		5: begin img_hbegin = 0; img_vbegin = 120; end
		default: begin img_hbegin = 0; img_vbegin = 0; end 
	endcase
end

endmodule 