`timescale 1ns/ 1ps

module vga_out
#(
 	//display image at pos
	parameter IMG_W = 200,  //ͼƬ�����ص����
	parameter IMG_H = 164,  //ͼƬ�����ص����
	parameter IMG_X = 0,
	parameter IMG_Y = 0
)
(
	input 	wire 		clk,
	input 	wire 		rest_n,
	output 	wire 		lcd_clk,
	output 	wire 		lcd_pwm,
	output 	wire 		lcd_hsync, 
	output 	wire 		lcd_vsync, 
	output 	wire 		lcd_de,
	output 	wire [10:0] hsync_cnt,
	output 	wire [10:0] vsync_cnt,
	output 	wire 		img_ack,
	output 	wire [15:0]	addr
	);
	
//640*480
localparam VGA_H = 640;  
localparam VGA_V = 480; 

localparam THB 	 = 160;
localparam TH 	 = VGA_H + THB;

localparam TVB   = 45;
localparam TV    = VGA_V + TVB;

reg [10:0] counter_hs;
reg [10:0] counter_vs;

reg [15:0] read_addr;             //��ͼƬ����rom��ַ   

reg [10:0] img_hbegin = 0;   //ͼƬ���Ͻǵ�һ�����ص���VGA����������
reg [10:0] img_vbegin = 0;   //ͼƬ���Ͻǵ�һ�����ص���VGA�ĳ�������

always@(posedge clk or negedge rest_n)
begin
	if(rest_n == 1'b0)
		counter_hs <= 0;
	else if(counter_hs == TH )
		counter_hs <= 0;
	else
		counter_hs <= counter_hs + 1;
end

always@(posedge clk or negedge rest_n)
begin
	if(rest_n == 1'b0)
		counter_vs <= 0;
	else if(counter_hs == TH && counter_vs == TV)				
		counter_vs <= 0;
	else if(counter_hs == TH && counter_vs != TV)
		counter_vs <= counter_vs + 1;
end

assign lcd_clk   = (rest_n == 1) ? clk  : 1'b0;
assign lcd_pwm   = (rest_n == 1) ? 1'b1 : 1'b0;
assign lcd_hsync = ( counter_hs >= 16 && counter_hs < 112 ) ? 1 : 0;
assign lcd_vsync = ( counter_vs >= 10 && counter_vs < 12 ) ? 1 : 0;
assign lcd_de    = ( counter_hs >= THB && counter_hs <= TH && counter_vs >= TVB  && counter_vs < TV) ? 1 : 0;
assign hsync_cnt = counter_hs;
assign vsync_cnt = counter_vs;

assign img_ack = lcd_de &&
((counter_hs - THB) >= IMG_X && (counter_hs - THB) < (IMG_X + IMG_W)) && 
((counter_vs - TVB) >= IMG_Y && (counter_vs - TVB) < (IMG_Y + IMG_H)) ? 1'b1 : 1'b0;
               
assign addr = read_addr;

always@(posedge clk or negedge rest_n)
 begin
	 if(!rest_n)
		 read_addr <= 16'd0;
	 else if(img_ack)
		 read_addr <= (counter_hs - IMG_X - THB) + (counter_vs - IMG_Y - TVB) * IMG_W;
	 else
		 read_addr <= 16'd0;  
 end

endmodule
