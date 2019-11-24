`timescale 1ns/ 1ps

module camera_top
(
	input 	wire 		clk_24m,	//系统时钟
	input 	wire 		rst_n,		//复位
	//camera	
	input 	wire 		cam_pclk,	//像素时钟
	output 	wire 		cam_xclk,	//系统时钟
	input 	wire 		cam_href,	//行同
	input 	wire 		cam_vsync,	//帧同
	output 	wire 		cam_pwdn,	//模式
	output 	wire 		cam_rst,	//复位
	output 	wire 		cam_soic,	//SCCB
	inout 	wire 		cam_soid,	//SCCB
	input 	wire [7:0]	cam_data,	//
	//switches
	input wire [2:0] select,//1:gray 0:rgb;
	//buttons
	input wire [1:0] ch_threhold,
	//seg4
	output	wire [7:0] sm_seg,
	output	wire [3:0] sm_bit,
	//vga
	output 	reg [7:0] 	vga_r,
	output 	reg [7:0] 	vga_g,
	output 	reg [7:0] 	vga_b,
	output 	wire 		vga_clk,
	output 	wire 		vga_hsync,
	output 	wire 		vga_vsync

 );
	 
wire 		clk_lcd;
wire 		clk_cam;
wire 		clk_sccb;

wire        camera_wrreq;
wire        camera_wclk;
wire [15:0] camera_wrdat;
wire [19:0] camera_addr;

reg 		init_state;
wire 		init_ready;
wire 		sda_oe;
wire 		sda;
wire 		sda_in;
wire 		scl;
//switch
wire [1:0] color_select;
//picture
wire [7:0]	binary;
//button
wire [1:0] pulse;
//seg4
wire [7:0] threhold;

//lcd display
wire [10:0] hsync_cnt;
wire [10:0] vsync_cnt;
wire 		vga_rden;
wire [15:0]	vga_rddat;	//lcd read
wire [15:0]	vga_rdaddr;

assign cam_soid = (sda_oe == 1'b1) ? sda : 1'bz;
assign sda_in 	= cam_soid;
assign cam_soic = scl;
assign cam_pwdn = 1'b0;
assign cam_rst 	= rst_n;

assign color_select={select[2],select[1]};
/*
//vga rgb565 mode
always@(select[0] or vga_rden)
begin
	if(!select[0])
	begin
		vga_r[7:0] 	= vga_rden ? {binary[7]? { vga_rddat[15:11] , vga_rddat[13:11]}:8'hFF } : 8'h0;//
		vga_g[7:0] 	= vga_rden ? {binary[7]? { vga_rddat[10:5] , vga_rddat[6:5] }:8'hFF } : 8'h0;
		vga_b[7:0] 	= vga_rden ? {binary[7]? { vga_rddat[4:0] , vga_rddat[2:0]} :8'h00 } : 8'h0;
	end
	else
	begin
		vga_r[7:0] 	= vga_rden ? binary : 8'h00;
		vga_g[7:0] 	= vga_rden ? binary : 8'h00;
		vga_b[7:0] 	= vga_rden ? binary : 8'h00;
	end
end*/

reg [10:0] ini_h;
reg [10:0] ini_v;
reg box_enable;
wire get_inipoint;

wire top_box;
wire left_box;
wire right_box;
wire bottom_box;
wire box;

assign get_inipoint=(hsync_cnt>=154)&&(hsync_cnt<=11'd784)&&(vsync_cnt>=11'd35)&&(vsync_cnt<=11'd515)&&box_enable&&(!binary[7]);

always @(posedge clk_24m or negedge rst_n)//get initial_point
begin
	if(~rst_n)
	begin
		 box_enable= 0;
		 ini_h=0;
		 ini_v=0;
	end
	else
	begin
		if(get_inipoint)
		begin
			box_enable=1'b0;//only use the first target point
			ini_h=hsync_cnt-11'd15;
			ini_v=vsync_cnt-11'd10;
		end
		if(vsync_cnt>=11'd515)
		begin
			box_enable=1'b1;
		end
	end
end

assign top_box=(hsync_cnt>ini_h)&&(hsync_cnt<(ini_h+11'd56))&&(vsync_cnt>ini_v)&&(vsync_cnt<(ini_v+11'd3));
assign left_box=(vsync_cnt>ini_v)&&(vsync_cnt<(ini_v+11'd56))&&(hsync_cnt>ini_h)&&(hsync_cnt<(ini_h+11'd3));
assign right_box=(hsync_cnt>(ini_h+11'd53))&&(hsync_cnt<(ini_h+11'd56))&&(vsync_cnt>ini_v)&&(vsync_cnt<(ini_v+11'd56));
assign bottom_box=(hsync_cnt>ini_h)&&(hsync_cnt<(ini_h+11'd56))&&(vsync_cnt>(ini_v+11'd53))&&(vsync_cnt<(ini_v+11'd56));

assign box=top_box||left_box||right_box||bottom_box;//enable display box

always @(*)
begin
	if(!select[0])
	begin
		//if((hsync_cnt>ini_h&&hsync_cnt<(ini_h+11'd50)&&vsync_cnt>ini_v&&vsync_cnt<(ini_v+11'd3))||(vsync_cnt>ini_v&&vsync_cnt<(ini_v+11'd50)&&hsync_cnt>ini_h&&hsync_cnt<(ini_h+11'd3))||(hsync_cnt>ini_h&&hsync_cnt<(ini_h+11'd50)&&vsync_cnt>(ini_v+11'd50)&&vsync_cnt<(ini_v+11'd53))||(hsync_cnt>(ini_h+11'd50)&&hsync_cnt<(ini_h+11'd53)&&vsync_cnt>ini_v&&vsync_cnt<(ini_v+11'd50)))
		//if(hsync_cnt>200&&hsync_cnt<250&&vsync_cnt>250&&vsync_cnt<254)
		if(box)
		begin
			vga_r[7:0] 	= vga_rden ? 8'hff : 8'h00;
			vga_g[7:0] 	= vga_rden ? 8'hff : 8'h00;
			vga_b[7:0] 	= vga_rden ? 8'h00 : 8'h00;
		end
		else
		begin
			vga_r[7:0] 	= vga_rden ? {vga_rddat[15:11] , vga_rddat[13:11]} : 8'h0;//
			vga_g[7:0] 	= vga_rden ? {vga_rddat[10:5] , vga_rddat[6:5]} : 8'h0;
			vga_b[7:0] 	= vga_rden ? {vga_rddat[4:0] , vga_rddat[2:0]} : 8'h0;
		end
	end
	else
	begin
		vga_r[7:0] 	= vga_rden ? binary : 8'h00;
		vga_g[7:0] 	= vga_rden ? binary : 8'h00;
		vga_b[7:0] 	= vga_rden ? binary : 8'h00;
	end
end

wire vga_den;
wire vga_pwm;	//backlight,set to high

RGB565_to_binary u_RGB565_to_binary(
	.clk(clk_lcd),
	.rst_n(rst_n),
	.rgb(vga_rddat),
	.color_select(color_select),
	.plus(pulse[0]),
	.sub(pulse[1]),
	.threhold(threhold),
	.bin(binary)
	);

debounce u_debounce(
	.clk(clk_24m),
	.rst_n(rst_n),
	.key(ch_threhold),
	.key_pulse(pulse)
	);

seg4
#(
	.CNT_TIME ( 2400_000) //0.1s
)
u_seg4
( 
	.clk_24m(clk_24m),  
	.rst_n(rst_n),
	.num(threhold),
    .sm_seg(sm_seg),//output	wire [7:0] 
    .sm_bit(sm_bit)//output	wire [3:0] 
);

ip_pll u_pll(
	.refclk(clk_24m),		//24M
	.clk0_out(clk_lcd),		//25M,VGA clk
	.clk1_out(clk_cam),		//12m,for cam xclk
	.clk2_out(clk_sccb)		//4m,for sccb init
);

camera_init u_camera_init
(
	.clk(clk_sccb),
	.reset_n(rst_n),
	.ready(init_ready),
	.sda_oe(sda_oe),
	.sda(sda),
	.sda_in(sda_in),
	.scl(scl)
);
	
vga_out 
#(
	.IMG_W		(200		),
	.IMG_H		(162		),
	.IMG_X		(0			),
	.IMG_Y		(0			)
)
u_vga_sync
(
	.clk		(clk_lcd	),
	.rest_n		(rst_n		),
	.lcd_clk	(vga_clk	),
	.lcd_pwm	(vga_pwm	),
	.lcd_hsync	(vga_hsync	), 
	.lcd_vsync	(vga_vsync	), 
	.lcd_de		(vga_den	),
	.hsync_cnt	(hsync_cnt	),
	.vsync_cnt	(vsync_cnt	),
	.img_ack	(vga_rden	),
	.addr		(vga_rdaddr	)
);

camera_reader u_camera_reader
(
	.clk		(clk_cam		),
	.reset_n	(rst_n			),
	.csi_xclk	(cam_xclk		),
	.csi_pclk	(cam_pclk		),
	.csi_data	(cam_data		),
	.csi_vsync	(!cam_vsync		),
	.csi_hsync	(cam_href		),
	.data_out	(camera_wrdat	),
	.wrreq		(camera_wrreq	),
	.wrclk		(camera_wclk	),
	.wraddr		(camera_addr	)
);

img_cache u_img 
( 
	//write 45000*8
	.dia		(camera_wrdat	), 
	.addra		(camera_addr[15:0]	), 
	.cea		(camera_wrreq	), 
	.clka		(camera_wclk	), 
	.rsta		(!rst_n			), 
	//read 22500*16
	.dob		(vga_rddat		), 
	.addrb		(vga_rdaddr		), 
	.ceb		(vga_rden		),
	.clkb		(clk_lcd		), 
	.rstb		(!rst_n			)
);
	
endmodule
