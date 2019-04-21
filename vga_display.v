`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// VGA verilog template
//////////////////////////////////////////////////////////////////////////////////
module vga_display(ClkPort, vga_h_sync, vga_v_sync, vgaRed, vga_r, vga_g, vga_b, Sw0, Sw1, btnL, btnR, btnU,
	St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar,
	An0, An1, An2, An3, Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,
	LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7);
	input ClkPort, Sw0, btnL, btnR, btnU, Sw0, Sw1;
	output St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar;
	output vga_h_sync, vga_v_sync, vgaRed, vga_r, vga_g, vga_b;
	output An0, An1, An2, An3, Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp;
	output LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7;
	reg vgaRed, vga_r, vga_g, vga_b;
	
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/*  LOCAL SIGNALS */
	wire	reset, start, ClkPort, board_clk, clk, button_clk;
	
	BUF BUF1 (board_clk, ClkPort); 	
	BUF BUF2 (reset, Sw0);
	BUF BUF3 (start, Sw1);
	
	reg [27:0]	DIV_CLK;
	always @ (posedge board_clk, posedge reset)  
	begin : CLOCK_DIVIDER
      if (reset)
			DIV_CLK <= 0;
      else
			DIV_CLK <= DIV_CLK + 1'b1;
	end	

	assign	button_clk = DIV_CLK[18];
	assign	clk = DIV_CLK[1];
	assign 	{St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar} = {5'b11111};
	
	wire inDisplayArea;
	wire [9:0] CounterX;
	wire [9:0] CounterY;

	hvsync_generator syncgen(.clk(clk), .reset(reset),.vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));
	
	/////////////////////////////////////////////////////////////////
	///////////////		VGA control starts here		/////////////////
	/////////////////////////////////////////////////////////////////
	reg [9:0] shipPos;
	
	reg [9:0] midTargetX;
	reg [9:0] midTargetY;
	reg [1:0] isLeftMid;
	reg [1:0] isHitMid;

	reg [9:0] topTargetX;
	reg [9:0] topTargetY;
	reg [1:0] isLeftTop;
	reg [1:0] isUpRightTop;
	reg [1:0] isUpLeftTop;
	reg [1:0] isHitTop;

	reg [9:0] bottomTargetX;
	reg [9:0] bottomTargetY;
	reg [1:0] isLeftBottom;
	reg [1:0] isUpRightBottom;
	reg [1:0] isUpLeftBottom;
	reg [1:0] isHitBottom;

	reg [1:0] shoot;
	reg [1:0] allHit;

	reg [9:0] positionShootY;
	reg [9:0] positionShootX;
	
	always @(posedge DIV_CLK[21])
		begin
			if(reset)
				begin
					shipPos<=400;

					midTargetX <= 200;
					midTargetY <= 250;
					isHitMid <= 0;
					isLeftMid <= 0;

					topTargetX <= 600;
					topTargetY <= 102;
					isHitTop <= 0;
					isLeftTop <= 1;
					isUpRightTop <= 0;
					isUpLeftTop <= 0;

					bottomTargetX <= 300;
					bottomTargetY <= 400;
					isHitBottom <= 0;
					isLeftBottom <= 1;
					isUpRightBottom <= 0;
					isUpLeftBottom <= 0;
					
					shoot <= 0;
					allHit <= 0;
				end
			//ship moves right
			else if(btnR && ~btnL)
				begin
					if(shipPos < 610)
						shipPos<=shipPos+5;
				end
			//ship moves left
			else if(btnL && ~btnR)
				begin
					if(shipPos > 30)
						shipPos<=shipPos-5;
				end
			//shoot from ship
			else if(btnU && ~btnL && ~btnR)
				begin
					//bullet isn't in session
					if(shoot == 0)
						begin
							shoot <= 1;
							positionShootY <= 435;
							positionShootX <= shipPos;
						end
				end
			//middle target isn't hit, keep moving back and forth
			if(isHitMid == 0)
				begin
					if(midTargetX > 614)
						isLeftMid <= 1;
					else if(midTargetX < 11)
						isLeftMid <= 0;

					if(isLeftMid == 1)
						midTargetX <= midTargetX - 2;
					else
						midTargetX <= midTargetX + 2;
				end
			//top target isn't hit, keep moving back and forth
			if(isHitTop == 0)
				begin
					if(topTargetX > 614)
						isLeftTop <= 1;
					else if(topTargetX < 11)
						isLeftTop <= 0;

					if(isLeftTop == 1)
						begin
							topTargetX <= topTargetX - 2;
						end
					else
						begin
							topTargetX <= topTargetX + 2;
						end
				end
					//top target isn't hit, keep moving back and forth
			if(isHitBottom == 0)
				begin
					if(bottomTargetX > 614)
						isLeftBottom <= 1;
					else if(bottomTargetX < 11)
						isLeftBottom <= 0;

					if(isLeftBottom == 1)
						begin
							bottomTargetX <= bottomTargetX - 2;
						end
					else
						begin
							bottomTargetX <= bottomTargetX + 2;
						end
				end
			//shoot bullet
			if(shoot == 1)
				begin
					//hit a target, stop target
					if(positionShootY < 10)
						shoot <= 0;
					else
						positionShootY <= positionShootY - 10;

					if(positionShootX >= (midTargetX - 10) && positionShootX <= (midTargetX + 10)
						 && positionShootY >= (midTargetY-10) && positionShootY <= (midTargetY+10))
						begin
							isHitMid <= 1;
							shoot <= 0;
							if((isHitTop == 1) && (isHitBottom == 1))
								allHit <= 1;
						end
					else if(positionShootX >= (topTargetX - 10) && positionShootX <= (topTargetX + 10)
						 && positionShootY >= (topTargetY-10) && positionShootY <= (topTargetY+10))
						begin
							isHitTop <= 1;
							shoot <= 0;
							if((isHitMid == 1) && (isHitBottom == 1))
								allHit <= 1;
						end
					else if(positionShootX >= (bottomTargetX - 10) && positionShootX <= (bottomTargetX + 10)
						 && positionShootY >= (bottomTargetY-10) && positionShootY <= (bottomTargetY+10))
						begin
							isHitBottom <= 1;
							shoot <= 0;
							if((isHitMid == 1) && (isHitTop == 1))
								allHit <= 1;
						end
				end
		end
	
	wire R = CounterX>=(shipPos-30) && CounterX<=(shipPos+30) && CounterY[9:6]==7;
	wire Red = (allHit == 0) ? 
				((isHitTop == 1) && (isHitBottom == 1)) ? 
					(CounterX>=(topTargetX-10) && CounterX<=(topTargetX+10) && CounterY >= (topTargetY-10) && CounterY<=(topTargetY+10))
						| (CounterX>=(bottomTargetX-10) && CounterX<=(bottomTargetX+10) && CounterY >= (bottomTargetY-10) && CounterY<=(bottomTargetY+10))
				: ((isHitTop == 1) && (isHitMid == 1)) ? 
					(CounterX>=(midTargetX-10) && CounterX<=(midTargetX+10) && CounterY >= (midTargetY-10) && CounterY<=(midTargetY+10))
						| (CounterX>=(topTargetX-10) && CounterX<=(topTargetX+10) && CounterY >= (topTargetY-10) && CounterY<=(topTargetY+10))
				: ((isHitBottom == 1) && (isHitMid == 1)) ? 
					(CounterX>=(midTargetX-10) && CounterX<=(midTargetX+10) && CounterY >= (midTargetY-10) && CounterY<=(midTargetY+10))
						| (CounterX>=(bottomTargetX-10) && CounterX<=(bottomTargetX+10) && CounterY >= (bottomTargetY-10) && CounterY<=(bottomTargetY+10))
				:(isHitTop == 1) ? 
					(CounterX>=(topTargetX-10) && CounterX<=(topTargetX+10) && CounterY >= (topTargetY-10) && CounterY<=(topTargetY+10))
				: (isHitMid == 1) ? 
					(CounterX>=(midTargetX-10) && CounterX<=(midTargetX+10) && CounterY >= (midTargetY-10) && CounterY<=(midTargetY+10))
				: (isHitBottom == 1) ? 
					(CounterX>=(bottomTargetX-10) && CounterX<=(bottomTargetX+10) && CounterY >= (bottomTargetY-10) && CounterY<=(bottomTargetY+10))
				: 0
			: (CounterX>=(midTargetX-10) && CounterX<=(midTargetX+10) && CounterY >= (midTargetY-10) && CounterY<=(midTargetY+10))
				| (CounterX>=(topTargetX-10) && CounterX<=(topTargetX+10) && CounterY >= (topTargetY-10) && CounterY<=(topTargetY+10))
				| (CounterX>=(bottomTargetX-10) && CounterX<=(bottomTargetX+10) && CounterY >= (bottomTargetY-10) && CounterY<=(bottomTargetY+10));
	wire G = (allHit == 0) ? 
				//top & middle are still active
				((isHitMid == 0) && (isHitTop == 0) && (isHitBottom == 0)) ? 
					(CounterX>=(midTargetX-10) && CounterX<=(midTargetX+10) && CounterY >= (midTargetY-10) && CounterY<=(midTargetY+10))
						| (CounterX>=(topTargetX-10) && CounterX<=(topTargetX+10) && CounterY >= (topTargetY-10) && CounterY<=(topTargetY+10))
						| (CounterX>=(bottomTargetX-10) && CounterX<=(bottomTargetX+10) && CounterY >= (bottomTargetY-10) && CounterY<=(bottomTargetY+10))
				: ((isHitTop == 0) && (isHitBottom == 0)) ? 
					(CounterX>=(topTargetX-10) && CounterX<=(topTargetX+10) && CounterY >= (topTargetY-10) && CounterY<=(topTargetY+10))
						| (CounterX>=(bottomTargetX-10) && CounterX<=(bottomTargetX+10) && CounterY >= (bottomTargetY-10) && CounterY<=(bottomTargetY+10))
				: ((isHitTop == 0) && (isHitMid == 0)) ? 
					(CounterX>=(midTargetX-10) && CounterX<=(midTargetX+10) && CounterY >= (midTargetY-10) && CounterY<=(midTargetY+10))
						| (CounterX>=(topTargetX-10) && CounterX<=(topTargetX+10) && CounterY >= (topTargetY-10) && CounterY<=(topTargetY+10))
				: ((isHitBottom == 0) && (isHitMid == 0)) ? 
					(CounterX>=(midTargetX-10) && CounterX<=(midTargetX+10) && CounterY >= (midTargetY-10) && CounterY<=(midTargetY+10))
						| (CounterX>=(bottomTargetX-10) && CounterX<=(bottomTargetX+10) && CounterY >= (bottomTargetY-10) && CounterY<=(bottomTargetY+10))
				: (isHitBottom == 0) ? 
					(CounterX>=(bottomTargetX-10) && CounterX<=(bottomTargetX+10) && CounterY >= (bottomTargetY-10) && CounterY<=(bottomTargetY+10))
				//only top
				: (isHitTop == 0) ? 
					(CounterX>=(topTargetX-10) && CounterX<=(topTargetX+10) && CounterY >= (topTargetY-10) && CounterY<=(topTargetY+10))
				//only middle
				: (isHitMid == 0) ? 
					(CounterX>=(midTargetX-10) && CounterX<=(midTargetX+10) && CounterY >= (midTargetY-10) && CounterY<=(midTargetY+10))
				: 0
			: 0;
	wire B = (shoot == 1) ? 
		(CounterY>=(positionShootY-5) && CounterY<=(positionShootY+5) && CounterX>=(positionShootX-3) && CounterX<=(positionShootX+3))
			| (CounterY >= (midTargetY-1) && CounterY<=(midTargetY+1)) | (CounterY >= (topTargetY-1) && CounterY<=(topTargetY+1)) 
			| (CounterY >= (bottomTargetY-1) && CounterY<=(bottomTargetY+1))
		: (CounterY >= (midTargetY-1) && CounterY<=(midTargetY+1)) | (CounterY >= (topTargetY-1) && CounterY<=(topTargetY+1)) 
			| (CounterY >= (bottomTargetY-1) && CounterY<=(bottomTargetY+1));
	
	always @(posedge clk)
	begin
		vga_r <= R & inDisplayArea;
		vgaRed <= Red & inDisplayArea;
		vga_g <= G & inDisplayArea;
		vga_b <= B & inDisplayArea;
	end
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  VGA control ends here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  LD control starts here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	`define QI 			2'b00
	`define QGAME_1 	2'b01
	`define QGAME_2 	2'b10
	`define QDONE 		2'b11
	
	reg [3:0] p2_score;
	reg [3:0] p1_score;
	reg [1:0] state;
	wire LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7;
	
	assign LD0 = (p1_score == 4'b1010);
	assign LD1 = (p2_score == 4'b1010);
	
	assign LD2 = start;
	assign LD4 = reset;
	
	assign LD3 = (state == `QI);
	assign LD5 = (state == `QGAME_1);	
	assign LD6 = (state == `QGAME_2);
	assign LD7 = (state == `QDONE);
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  LD control ends here 	 	////////////////////
	/////////////////////////////////////////////////////////////////
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  SSD control starts here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	reg 	[3:0]	SSD;
	wire 	[3:0]	SSD0, SSD1, SSD2, SSD3;
	wire 	[1:0] ssdscan_clk;
	
	assign SSD3 = 4'b1111;
	assign SSD2 = 4'b1111;
	assign SSD1 = 4'b1111;
	assign SSD0 = shipPos[3:0];
	
	// need a scan clk for the seven segment display 
	// 191Hz (50MHz / 2^18) works well
	assign ssdscan_clk = DIV_CLK[19:18];	
	assign An0	= !(~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 00
	assign An1	= !(~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 01
	assign An2	= !( (ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 10
	assign An3	= !( (ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 11
	
	always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
			2'b00:
					SSD = SSD0;
			2'b01:
					SSD = SSD1;
			2'b10:
					SSD = SSD2;
			2'b11:
					SSD = SSD3;
		endcase 
	end	

	// and finally convert SSD_num to ssd
	reg [6:0]  SSD_CATHODES;
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES, 1'b1};
	// Following is Hex-to-SSD conversion
	always @ (SSD) 
	begin : HEX_TO_SSD
		case (SSD)		
			4'b1111: SSD_CATHODES = 7'b1111111 ; //Nothing 
			4'b0000: SSD_CATHODES = 7'b0000001 ; //0
			4'b0001: SSD_CATHODES = 7'b1001111 ; //1
			4'b0010: SSD_CATHODES = 7'b0010010 ; //2
			4'b0011: SSD_CATHODES = 7'b0000110 ; //3
			4'b0100: SSD_CATHODES = 7'b1001100 ; //4
			4'b0101: SSD_CATHODES = 7'b0100100 ; //5
			4'b0110: SSD_CATHODES = 7'b0100000 ; //6
			4'b0111: SSD_CATHODES = 7'b0001111 ; //7
			4'b1000: SSD_CATHODES = 7'b0000000 ; //8
			4'b1001: SSD_CATHODES = 7'b0000100 ; //9
			4'b1010: SSD_CATHODES = 7'b0001000 ; //10 or A
			default: SSD_CATHODES = 7'bXXXXXXX ; // default is not needed as we covered all cases
		endcase
	end
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  SSD control ends here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
endmodule