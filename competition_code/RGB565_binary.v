module RGB565_to_binary(
	input clk,
	input rst_n,
	input [15:0] rgb,
	input [1:0] color_select,
	input plus,
	input sub,
	output reg [7:0] threhold,
	output reg [7:0] bin
	);

	//reg [7:0] threhold;
	//reg restrain;

	reg [15:0] gray_r,gray_g,gray_b;
	reg [17:0] gray_temp;
	wire [7:0] r_in;
	wire [7:0] g_in;
	wire [7:0] b_in;

	assign r_in={rgb[15:11],rgb[13:11]};
	assign g_in={rgb[10:5],rgb[6:5]};
	assign b_in={rgb[4:0],rgb[2:0]};

	always@(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
		begin
			threhold=128;
			//restrain=96;
		end
		else
		begin
			if(plus)
			begin
				if(threhold<192)
				begin
					threhold=threhold+2;
				end
				else
				begin
					threhold=112;
				end
			end
			if(sub)
			begin
				if(threhold>112)
				begin
					threhold=threhold-2;
				end
				else
				begin
					threhold=192;
				end
			end
		end
	end

	always@(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
		begin
			bin=0;
			gray_r=0;
			gray_g=0;
			gray_b=0;
		end
		else
		begin
			case(color_select)
			2'b00:
			begin
				if(r_in>=threhold&&g_in<=96&&b_in<=96)
				begin
					bin=8'd0;
				end
				else
				begin
					bin=8'd255;
				end
			end
			2'b01:
			begin
				if(g_in>=threhold&&r_in<=112&&b_in<=112)
				begin
					bin=8'd0;
				end
				else
				begin
					bin=8'd255;
				end
			end
			2'b10:
			begin
				if(b_in>=threhold&&r_in<=96&&g_in<=96)
				begin
					bin=8'd0;
				end
				else
				begin
					bin=8'd255;
				end
			end
			2'b11:
			begin
				/*if(r_in>128&&g_in<=96&&b_in<=96)
				begin
					bin=8'd0;
				end
				else
				begin
					bin=8'd255;
				end8*/
				gray_r=(r_in<<6)+(r_in<<3)+(r_in<<2)+r_in;			//64+8+4+1=77
				gray_g=(g_in<<7)+(g_in<<4)+(g_in<<2)+(g_in<<1);		//128+16+4+2=150
				gray_b=(b_in<<4)+(b_in<<3)+(b_in<<2)+b_in;			//16+8+4+1=29
				gray_temp=gray_r+gray_g+gray_b;
				bin=gray_temp[17:10];
			end
			endcase
		end
	end
	
endmodule
