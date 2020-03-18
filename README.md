# 用 FPGA 驱动 TFT 屏显示图片

## 01. RGB 接口 TFT 屏扫描原理

> 色彩由 RGB 三基色组成，显示是用逐行扫描的方式解决。扫描从屏幕的左上方开始，从左到右，从上到下进行扫描，每扫完一行，电子束都回到屏幕的下一行左边的起始位置。在这期间，CRT 对电子束进行消隐。每行结束时，用行同步信号进行行同步；扫描完所有行，用场同步信号进行场同步，并使扫描回到屏幕的左上方。同时进行场消隐，预备下一场的扫描。 并且TFT 屏直接接受数字信号输入。

## 02. RGB 接口 TFT 屏时序分析

> 详情请看文件`AT043TN24.pdf`
>
> 480*272 分辨率显示扫描示意图：
>
> ![](C:\Users\Liang Chen\Desktop\TFT_img_prj\480_272.png)

## 03. RGB 接口 TFT 屏驱动设计

> 源文件`tft_ctrl.v`

### 3.1 TFT 屏驱动模块接口信息

<img src="C:\Users\Liang Chen\Desktop\TFT_img_prj\TFT驱动模块接口.png"  />

| port   | IO     | description |
| :----: | :----: | :----: |
| Clk9M  | I      | Clk9MHz     |
| Rst_n | I | 低电平复位 |
| data_in [15:0] | I | 待显示图片数据 |
| TFT_HS | O | 行同步信号 |
| TFT_VS | O | 场同步信号 |
| TFT_RGB [15:0] | O | 三原色数据输出RGB565 |
| hcount [9:0] | O | 图像区行扫描地址 |
| vcount [9:0] | O | 图像区场扫描地址 |
| TFT_PWM | O | 背光控制 |
| TFT_DE | O | 背光使能 |
| TFT_Clk | O | TFT像素时钟 |

### 3.2 TFT 行/场扫描时序参数化定义

```verilog
parameter
	tft_hs_end = 10'd40,
	hdat_begin = 10'd42,
	hdat_end = 10'd522,
	hpixel_end = 10'd524,
		
	tft_vs_end = 10'd9,
	vdat_begin = 10'd11,
	vdat_end = 10'd283,
	vline_end = 10'd285;
```

### 3.3 行扫描计数器

```verilog
reg [9:0]hcnt_r;
always@(posedge clk9M or negedge rst_n)
	if(!rst_n)
		hcnt_r <= 10'd0;
	else if(hcnt_r == hpixel_end)
		hcnt_r <= 10'd0;
	else
		hcnt_r <= hcnt_r + 1'b1;
```

### 3.4 场扫描计数器

```verilog
reg [9:0]vcnt_r;
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
```

### 3.5 行/场同步

```verilog
assign tft_hs = (hcnt_r > tft_hs_end)?1'b1:1'b0;
assign tft_vs = (vcnt_r > tft_vs_end)?1'b1:1'b0;
```

### 3.6 RGB数据输出

```verilog
wire dat_act;
assign dat_act = ((hcnt_r >= hdat_begin) && (hcnt_r < hdat_end) && (vcnt_r >= vdat_begin) && (vcnt_r < vdat_end))?1'b1:1'b0;
assign tft_rgb = (dat_act)?data_in:16'd0;
```

### 3.7 行/场扫描位置输出

```verilog
assign hcnt = hcnt_r - hdat_begin;
assign vcnt = vcnt_r - vdat_begin;
```

### 3.8 时钟/使能/控制输出

```verilog
assign tft_clk = clk9M;
assign tft_de = dat_act;
assign tft_pwm = rst_n;
```

## 04. 数据发送模块设计

> 源文件`imgdata_send.v`

### 4.1 ROM 存储图片数据

- 将`dog.bmp`图片转换成`dog.mif`文件

- 设置 ROM IP核存储 mif 数据

- 在设计中例化 ROM IP核

  ```verilog
  img_rom img_rom_u0(
  	.address(addr),
  	.clock(clk50M),
  	.q(img_data)
  ); 
  ```

### 4.2 设置间隔 0.5s 图片移动一次

```verilog
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
```

### 4.3 设置图片移动位置

```verilog
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
```

### 4.4 读取 ROM 图片数据

```verilog
assign img_act = (tft_de && (hcnt >= img_hbegin) && (hcnt < img_hbegin + IMG_H) && (vcnt >= img_vbegin) && (vcnt < img_vbegin + IMG_V))?1'b1:1'b0;

always@(posedge clk50M or negedge rst_n)
	if(!rst_n)
		addr <= 15'd0;
	else if(img_act)
        addr <= (hcnt - img_hbegin) + (vcnt - img_vbegin)*IMG_H; // !!!
	else
		addr <= 15'd0;

assign data_in = img_act?img_data:16'd0;
```

## 05. PLL IP核设置 Clk_9MHz

> 自行google

## 06. 顶层例化

> 源文件`tft_img_top.v`
>
> ![](C:\Users\Liang Chen\Desktop\TFT_img_prj\top.png)

## 07. 成果

> 编译，综合，分配引脚，生成 sof 文件，下载至开发板上看到以下现象：
>
> ![](C:\Users\Liang Chen\Desktop\TFT_img_prj\dog.gif)



